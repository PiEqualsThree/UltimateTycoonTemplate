using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Random }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { PumpkinCarving}
using { VerseStuff.Managers }
using { VerseStuff.TycoonInterfaces }
using { TycoonAnimations }
using { UIStuff}
using { UIStuff.PumpkinCarvingUI}
using { UIStuff.PumpkinCarvingUI.PumpkinEyes}
using { UIStuff.PumpkinCarvingUI.PumpkinMouths}
using { PumpkinStuff.PumpkinTops}

pumpkin_carving_manager<public> := class<concrete>:
    @editable       InteractButton : button_device = button_device{}
    @editable       Camera : gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}
    @editable       Shop : pumpkin_carving_components_shop = pumpkin_carving_components_shop{}

    @editable       CustomerReadyBeacon : beacon_device = beacon_device{}
    @editable       CustomerSpawnVFX : vfx_spawner_device = vfx_spawner_device{}
    @editable       CustomerDespawnVFX : vfx_spawner_device = vfx_spawner_device{}
    @editable       CustomerSatisfactionVFXDevices : []vfx_spawner_device = array{}
    @editable       CustomerCharacterDevices : []character_device = array{}

    @editable       ComponentChangeVFX : vfx_spawner_device = vfx_spawner_device{}
    @editable       PumpkinBase : creative_prop = creative_prop{}
    @editable       PumpkinTop : creative_prop = creative_prop{}
    @editable       EyeDecalAssets : []creative_prop_asset = array{}
    @editable       MouthDecalAssets : []creative_prop_asset = array{}
    
    PumpkinUI : pumpkin_carving_ui = pumpkin_carving_ui{}
    ResetEvent : event() = event(){}
    PumpkinCarvingBeginEvent : event() = event(){}
    PumpkinCarvingEndEvent : event() = event(){}
    
    var EyeDecals<public> : []creative_prop = array{}
    var MouthDecals<public> : []creative_prop = array{}
    var CurrentEyeDecal : ?creative_prop = false
    var CurrentMouthDecal : ?creative_prop = false

    var IsCustomerReady : logic = false
    var AllowComponentChange : logic = true
    var CurrentCharacterDevice : character_device = character_device{}
    var CurrentSatisfactionVFX : vfx_spawner_device = vfx_spawner_device{}

    var CurrentMetricTotalMap : [pumpkin_carving_metric]int = map{
        pumpkin_carving_metric.MetricA => 0
        pumpkin_carving_metric.MetricB => 0
        pumpkin_carving_metric.MetricC => 0
        pumpkin_carving_metric.MetricD => 0
        pumpkin_carving_metric.MetricE => 0
    }

    var UnlockedColorIDs<public> : []int = array{}
    var UnlockedTopIDs<public> : []int = array{}
    var UnlockedEyeIDs<public> : []int = array{}
    var UnlockedMouthIDs<public> : []int = array{}

    var SelectedColorID : int = 0
    var SelectedTopID : int = 0
    var SelectedEyesID : int = 0
    var SelectedMouthID : int = 0 
    
    UniqueBegin<public>()<suspends> : void =
        Shop.UniqueBegin()
        PumpkinUI.UniqueBegin()
        
        XForm := transform:
            Translation := PumpkinBase.GetTransform().Translation + vector3{Z := 25.0}
            Rotation := PumpkinBase.GetTransform().Rotation
            Scale := 0.45 * IdentityVector
        for ( Asset : EyeDecalAssets):
            SpawnResult := SpawnProp(Asset, XForm)
            if ( Prop := SpawnResult(0)?):
                Prop.Hide()
                set EyeDecals = EyeDecals + array{Prop}
        Sleep(0.0)
        for ( Asset : MouthDecalAssets):
            SpawnResult := SpawnProp(Asset, XForm)
            if ( Prop := SpawnResult(0)?):
                Prop.Hide()
                set MouthDecals = MouthDecals + array{Prop}
        
    Init<public>(TycoonManager : tycoon_manager) : void =
        for ( Device : CustomerCharacterDevices) do Device.Hide()
        for ( Decal : EyeDecals) do Decal.Hide()
        for ( Decal : MouthDecals) do Decal.Hide()
        PumpkinBase.Hide()
        PumpkinTop.Hide()
        Shop.Init()

    LoadData<public>(Owner : custom_player, TycoonManager : tycoon_manager, PlayerStats : player_stats)<suspends> : void =
        for ( ID : PlayerStats.PumpkinCarvingStats.UnlockedMaterialIDs) do UnlockColor(ID)
        for ( ID : PlayerStats.PumpkinCarvingStats.UnlockedTopIDs) do UnlockTop(ID)
        for ( ID : PlayerStats.PumpkinCarvingStats.UnlockedEyeIDs) do UnlockEyes(ID)
        for ( ID : PlayerStats.PumpkinCarvingStats.UnlockedMouthIDs) do UnlockMouth(ID)
        Sleep(0.0)
        for ( Device : CustomerCharacterDevices) do Device.Hide()
        Shop.LoadData(Owner, Self)
        spawn{Update(Owner)}

    Update(Owner : custom_player)<suspends> : void =
        Sleep(1.0)
        race:
            ResetEvent.Await()
            PollPumpkinCarvingEvents(Owner)
            loop: <# Spawn Customer Loop #>
                set IsCustomerReady = true
                set CurrentCharacterDevice = CustomerCharacterDevices[GetRandomInt(0, CustomerCharacterDevices.Length - 1)] or CurrentCharacterDevice   
                CustomerSpawnVFX.Restart()
                CustomerReadyBeacon.Enable()
                CurrentCharacterDevice.Show()
                CurrentCharacterDevice.PlayEmote()
                PumpkinCarvingEndEvent.Await()
                Sleep(3.0)    
                InteractButton.Enable() 

    PollPumpkinCarvingEvents(Owner : custom_player)<suspends> : void =
        loop:
            Agent := InteractButton.InteractedWithEvent.Await()
            if ( Owner.Agent = Agent, IsCustomerReady?):
                MetricWeightSheet := GenerateMetricWeightSheet()
                BeginPumpkinCarving(Owner)
                PollUIEvents(Owner, MetricWeightSheet)
                FinishPumpkinCarving(Owner)
                Owner.FortCharacter.Show()

    PollUIEvents(Owner : custom_player, MetricWeightSheet : [pumpkin_carving_metric]int)<suspends> : void =
        race:
            ResetEvent.Await()
            PumpkinUI.FinishButton.OnClick().Await()
            AwaitAndResolvePageButtonPress(Owner, 0)
            AwaitAndResolvePageButtonPress(Owner, 1)
            AwaitAndResolvePageButtonPress(Owner, 2)
            AwaitAndResolvePageButtonPress(Owner, 3)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 0)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 1)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 2)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 3)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 4)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 5)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 6)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 7)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 8)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 9)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 10)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 12)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 11)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 12)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 13)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 14)
            AwaitAndResolveComponentButtonPress(Owner, MetricWeightSheet, 15)

    AwaitAndResolveComponentButtonPress(Owner : custom_player, MetricWeightSheet : [pumpkin_carving_metric]int, ComponentIndex : int)<suspends> : void =
        Button := PumpkinUI.ComponentWidgets[ComponentIndex].SelectionButton or button_quiet{}
        loop:
            Button.OnClick().Await()
            if ( AllowComponentChange?):
                set AllowComponentChange = false
                ComponentChangeVFX.Restart()
                Sleep(0.25)
                case(PumpkinUI.CurrentComponentPageIndex):
                    0 => UpdateColorComponent(ComponentIndex)
                    1 => UpdateTopComponent(ComponentIndex)
                    2 => UpdateEyesComponent(ComponentIndex)
                    3 => UpdateMouthComponent(ComponentIndex)
                    _ => Print("Unkown Component Page")
                UpdateMetricTotalMap()
                DisplayCurrentScoreFeedback(MetricWeightSheet)
                Sleep(0.5)
                set AllowComponentChange = true

    AwaitAndResolvePageButtonPress(Owner : custom_player, PageIndex : int)<suspends> : void =
        Button := case(PageIndex) { 0 => PumpkinUI.ColorPageButton; 1 => PumpkinUI.TopPageButton; 2 => PumpkinUI.EyesPageButton; 3 => PumpkinUI.MouthPageButton; _ => button_quiet{}}
        ComponentIndicesArray := array{} <# TODO #>
        loop:
            Button.OnClick().Await()
            if ( PumpkinUI.CurrentComponentPageIndex <> PageIndex):
                PumpkinUI.UpdateComponentPage(Self, PageIndex)

    BeginPumpkinCarving(Owner : custom_player)<suspends> : void =
        set AllowComponentChange = true
        InteractButton.Disable()
        PumpkinBase.Show()
        PumpkinTop.Show()
        CustomerReadyBeacon.Disable()
        PumpkinUI.Display(Owner)
        PumpkinUI.UpdateComponentPage(Self, PumpkinUI.CurrentComponentPageIndex)
        UpdateColorComponent(SelectedColorID)
        UpdateTopComponent(SelectedTopID)
        UpdateEyesComponent(SelectedEyesID)
        UpdateMouthComponent(SelectedMouthID)
        UpdateMetricTotalMap()
        Camera.AddTo(Owner.Agent)
        Owner.FortCharacter.Hide()

    FinishPumpkinCarving(Owner : custom_player)<suspends> : void =
        PumpkinUI.Remove(Owner)
        Camera.RemoveFrom(Owner.Agent)
        set IsCustomerReady = false
        CurrentCharacterDevice.PlayEmote()
        Sleep(1.0)
        CustomerDespawnVFX.Restart()
        CustomerReadyBeacon.Disable()
        CurrentCharacterDevice.Hide()
        PumpkinCarvingEndEvent.Signal()
    
    UpdateColorComponent(ComponentIndex : int) : void =
        set SelectedColorID = ComponentIndex
        if ( Material := PumpkinMaterials[ComponentIndex]):
            PumpkinBase.SetMaterial(Material)

    UpdateTopComponent(ComponentIndex : int) : void =
        if ( Mesh := PumpkinTopMeshes[ComponentIndex]):
            Print("Setting mesh {ComponentIndex}!")
            set SelectedTopID = ComponentIndex
            PumpkinTop.SetMesh(Mesh)

    UpdateEyesComponent(ComponentIndex : int) : void =
        if ( CurrentDecal := CurrentEyeDecal?) then CurrentDecal.Hide()
        if ( Decal := EyeDecals[ComponentIndex]):
            set SelectedEyesID = ComponentIndex
            set CurrentEyeDecal = option{Decal}
            Decal.Show()
            
    UpdateMouthComponent(ComponentIndex : int) : void =
        if ( CurrentDecal := CurrentMouthDecal?) then CurrentDecal.Hide()
        if ( Decal := MouthDecals[ComponentIndex]):
            set SelectedMouthID = ComponentIndex
            set CurrentMouthDecal = option{Decal}
            Decal.Show()

    UpdateMetricTotalMap() : void =
        MetricATotal := (PumpkinColorMetricSheet[SelectedColorID][pumpkin_carving_metric.MetricA] + PumpkinTopMetricSheet[SelectedTopID][pumpkin_carving_metric.MetricA] + PumpkinEyesMetricSheet[SelectedEyesID][pumpkin_carving_metric.MetricA] + PumpkinMouthMetricSheet[SelectedMouthID][pumpkin_carving_metric.MetricA]) or 1
        MetricBTotal := (PumpkinColorMetricSheet[SelectedColorID][pumpkin_carving_metric.MetricB] + PumpkinTopMetricSheet[SelectedTopID][pumpkin_carving_metric.MetricB] + PumpkinEyesMetricSheet[SelectedEyesID][pumpkin_carving_metric.MetricB] + PumpkinMouthMetricSheet[SelectedMouthID][pumpkin_carving_metric.MetricB]) or 1
        MetricCTotal := (PumpkinColorMetricSheet[SelectedColorID][pumpkin_carving_metric.MetricC] + PumpkinTopMetricSheet[SelectedTopID][pumpkin_carving_metric.MetricC] + PumpkinEyesMetricSheet[SelectedEyesID][pumpkin_carving_metric.MetricC] + PumpkinMouthMetricSheet[SelectedMouthID][pumpkin_carving_metric.MetricC]) or 1
        MetricDTotal := (PumpkinColorMetricSheet[SelectedColorID][pumpkin_carving_metric.MetricD] + PumpkinTopMetricSheet[SelectedTopID][pumpkin_carving_metric.MetricD] + PumpkinEyesMetricSheet[SelectedEyesID][pumpkin_carving_metric.MetricD] + PumpkinMouthMetricSheet[SelectedMouthID][pumpkin_carving_metric.MetricD]) or 1
        MetricETotal := (PumpkinColorMetricSheet[SelectedColorID][pumpkin_carving_metric.MetricE] + PumpkinTopMetricSheet[SelectedTopID][pumpkin_carving_metric.MetricE] + PumpkinEyesMetricSheet[SelectedEyesID][pumpkin_carving_metric.MetricE] + PumpkinMouthMetricSheet[SelectedMouthID][pumpkin_carving_metric.MetricE]) or 1
        set CurrentMetricTotalMap = map:
            pumpkin_carving_metric.MetricA => MetricATotal
            pumpkin_carving_metric.MetricB => MetricBTotal
            pumpkin_carving_metric.MetricC => MetricCTotal
            pumpkin_carving_metric.MetricD => MetricDTotal
            pumpkin_carving_metric.MetricE => MetricETotal

    DisplayCurrentScoreFeedback(MetricWeightSheet : [pumpkin_carving_metric]int)<suspends> : void =
        CurrentScore := CalculatePumpkinCarvingScore(CurrentMetricTotalMap, MetricWeightSheet)
        Satisfaction := (Ceil(CurrentScore / 10) - 1) or 0
        Print("Satifaction: {Satisfaction}")
        CurrentSatisfactionVFX.Disable()
        set CurrentSatisfactionVFX = CustomerSatisfactionVFXDevices[Satisfaction] or CurrentSatisfactionVFX
        Sleep(0.1)
        CurrentSatisfactionVFX.Restart()
    # Unlock Methods
    UnlockColor<public>(ID : int) : void =
        if ( not UnlockedColorIDs.Find[ID]):
            set UnlockedColorIDs = UnlockedColorIDs + array{ID}
            set UnlockedColorIDs = SortBy(UnlockedColorIDs, IntCompare)

    UnlockTop<public>(ID : int) : void =
        if ( not UnlockedTopIDs.Find[ID]):
            set UnlockedTopIDs = UnlockedTopIDs + array{ID}
            set UnlockedTopIDs = SortBy(UnlockedTopIDs, IntCompare)

    UnlockEyes<public>(ID : int) : void =
        if ( not UnlockedEyeIDs.Find[ID]):
            set UnlockedEyeIDs = UnlockedEyeIDs + array{ID}
            set UnlockedEyeIDs = SortBy(UnlockedEyeIDs, IntCompare)

    UnlockMouth<public>(ID : int) : void =
        if ( not UnlockedMouthIDs.Find[ID]):
            set UnlockedMouthIDs = UnlockedMouthIDs + array{ID}
            set UnlockedMouthIDs = SortBy(UnlockedMouthIDs, IntCompare)

    GetStats()<transacts> : pumpkin_carving_stats =
        pumpkin_carving_stats:
            UnlockedMaterialIDs := UnlockedColorIDs
            UnlockedTopIDs := UnlockedTopIDs
            UnlockedEyeIDs := UnlockedEyeIDs
            UnlockedMouthIDs := UnlockedMouthIDs
    Reset<public>() : void =
        set UnlockedColorIDs = array{}
        set UnlockedTopIDs = array{}
        set UnlockedEyeIDs = array{}
        set UnlockedMouthIDs = array{}
        set SelectedColorID = 0
        set SelectedTopID = 0
        set SelectedEyesID = 0
        set SelectedMouthID = 0 
        for ( Device : CustomerCharacterDevices) do Device.Hide()
        for ( Decal : EyeDecals) do Decal.Hide()
        for ( Decal : MouthDecals) do Decal.Hide()
        PumpkinBase.Hide()
        PumpkinTop.Hide()
        ResetEvent.Signal()
      
pumpkin_carving_ui := class:
    Canvas : canvas = canvas{}
    ColorPageButton : button_quiet = button_quiet{}
    TopPageButton : button_quiet = button_quiet{}
    EyesPageButton : button_quiet = button_quiet{}
    MouthPageButton : button_quiet = button_quiet{}
    
    FinishButton : button_quiet = button_quiet{}
    PageTextureBlock : texture_block = texture_block{DefaultImage := T_Pumpkin_Carving_Page_Text_Color, DefaultDesiredSize := vector2{ X := 512.0, Y := 64.0}}

    var CurrentComponentPageIndex<public> : int = 0

    var ComponentWidgets : []pumpkin_carving_component_widget = array{}
    var RootWidget : widget = overlay{}

    UniqueBegin() : void = 
        set ComponentWidgets = for ( I := 0..15):
            NewWidget := pumpkin_carving_component_widget{}
            NewWidget.UniqueBegin()
            NewWidget
        set RootWidget = CreateUI()
        Canvas.AddWidget(canvas_slot{Widget := RootWidget})

    Init() : void =
        {}

    Display(Owner : custom_player) : void =
        if ( PlayerUI := GetPlayerUI[Owner.Player]):
            PlayerUI.AddWidget(Canvas, player_ui_slot{InputMode := ui_input_mode.All})

    Remove(Owner : custom_player) : void =
        if ( PlayerUI := GetPlayerUI[Owner.Player]):
            PlayerUI.RemoveWidget(Canvas)

    UpdateComponentPage(PumpkinCarvingManager : pumpkin_carving_manager, PageIndex : int) : void =
        set CurrentComponentPageIndex = PageIndex
        var UnlockedComponentIndices : []int = array{}
        var ImagesArray : []texture = array{}
        case(PageIndex):
            0 => 
                set UnlockedComponentIndices = PumpkinCarvingManager.UnlockedColorIDs
                set ImagesArray = PumpkinColorComponentImages
                PageTextureBlock.SetImage(T_Pumpkin_Carving_Page_Text_Color)
            1 =>
                set UnlockedComponentIndices = PumpkinCarvingManager.UnlockedTopIDs
                set ImagesArray = PumpkinTopComponentImages
                PageTextureBlock.SetImage(T_Pumpkin_Carving_Page_Text_Hat)
            2 =>
                set UnlockedComponentIndices = PumpkinCarvingManager.UnlockedEyeIDs
                set ImagesArray = PumpkinEyesComponentImages
                PageTextureBlock.SetImage(T_Pumpkin_Carving_Page_Text_Eyes)
            3 =>
                set UnlockedComponentIndices = PumpkinCarvingManager.UnlockedMouthIDs
                set ImagesArray = PumpkinMouthComponentImages
                PageTextureBlock.SetImage(T_Pumpkin_Carving_Page_Text_Mouth)
            _ => Print("Unkown Component Index {PageIndex}")

        for ( Index -> ID : UnlockedComponentIndices, Image := ImagesArray[ID], ComponentWidget := ComponentWidgets[Index]):
            ComponentWidget.SetImage(Image)
            ComponentWidget.Show()
        for ( I := UnlockedComponentIndices.Length..15, Widget := ComponentWidgets[I]) do Widget.Hide()

    Reset() : void =
        set CurrentComponentPageIndex = 0

    CreateUI() : widget = 
        TempButtons := array{ColorPageButton, TopPageButton, EyesPageButton, MouthPageButton}
        NavigationMenuStackBoxSlots := for ( Button : TempButtons ) do stack_box_slot:
            VerticalAlignment := vertical_alignment.Top
            Padding := margin{Bottom := 45.0}
            Widget := overlay:
                Slots := array:
                    overlay_slot:
                        Widget := color_block{DefaultDesiredSize := vector2{ X := 140.0, Y := 140.0}, DefaultOpacity := 0.0}
                    overlay_slot:
                        HorizontalAlignment := horizontal_alignment.Fill
                        VerticalAlignment := vertical_alignment.Fill
                        Widget := Button

        Row1 := for ( I := 0..3, ComponentWidget := ComponentWidgets[I]) do stack_box_slot{Widget := ComponentWidget.GetRootWidget(), HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Right := Mod[I, 4] <> 3 and 45.0 or 0.0}}
        Row2 := for ( I := 4..7, ComponentWidget := ComponentWidgets[I]) do stack_box_slot{Widget := ComponentWidget.GetRootWidget(), HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Right := Mod[I, 4] <> 3 and 45.0 or 0.0}}
        Row3 := for ( I := 8..11, ComponentWidget := ComponentWidgets[I]) do stack_box_slot{Widget := ComponentWidget.GetRootWidget(), HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Right := Mod[I, 4] <> 3 and 45.0 or 0.0}}
        Row4 := for ( I := 12..15, ComponentWidget := ComponentWidgets[I]) do stack_box_slot{Widget := ComponentWidget.GetRootWidget(), HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Right := Mod[I, 4] <> 3 and 45.0 or 0.0}}

        overlay:
            Slots := array:
                overlay_slot: <# Overlay #>
                    Widget := texture_block{DefaultImage := T_Pumpkin_Carving_Overlay, DefaultDesiredSize := vector2{ X := 1920.0, Y := 1080.0}}
                overlay_slot: <# Navigation Buttons #>
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Left := 950.0, Top := 170.0}
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := NavigationMenuStackBoxSlots
                overlay_slot: <# Main Stack Box #>
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Left := 1175.0, Top := 100.0}
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := array:
                            stack_box_slot:
                                Widget := PageTextureBlock
                                Padding := margin{Bottom := 45.0}
                                VerticalAlignment := vertical_alignment.Top

                            stack_box_slot:
                                Widget := stack_box{Orientation := orientation.Horizontal, Slots := Row1}
                                Padding := margin{ Bottom := 45.0 }
                                VerticalAlignment := vertical_alignment.Top
                                
                            stack_box_slot:
                                Widget := stack_box{Orientation := orientation.Horizontal, Slots := Row2}
                                Padding := margin{ Bottom := 45.0 }
                                VerticalAlignment := vertical_alignment.Top
                            stack_box_slot:
                                Widget := stack_box{Orientation := orientation.Horizontal, Slots := Row3}
                                Padding := margin{ Bottom := 45.0 }
                                VerticalAlignment := vertical_alignment.Top
                            stack_box_slot:
                                Widget := stack_box{Orientation := orientation.Horizontal, Slots := Row4}
                                Padding := margin{ Bottom := 45.0 }
                                VerticalAlignment := vertical_alignment.Top

                overlay_slot: <# Finish Button #>
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Left := 1260.0, Top := 985.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := color_block{DefaultDesiredSize := vector2{ X := 485.0, Y := 80.0}, DefaultOpacity := 0.0}
                            overlay_slot:
                                Widget := FinishButton
                                HorizontalAlignment := horizontal_alignment.Fill
                                VerticalAlignment := vertical_alignment.Fill


pumpkin_carving_component_widget := class:
    SelectionButton<public> : button_quiet = button_quiet{}
    ComponentTextureBlock : texture_block = texture_block{DefaultImage := T_Pumpkin_Eyes_1_1, DefaultDesiredSize := vector2{ X := 128.0, Y := 128.0}}
    
    var RootWidget : widget = overlay{}

    UniqueBegin() : void =
        set RootWidget = overlay:
            Slots := array:
                overlay_slot:
                    Widget := texture_block{DefaultImage := T_Pumpkin_Carving_Component_Overlay, DefaultDesiredSize := vector2{ X := 128.0, Y := 128.0}}
                overlay_slot:
                    Widget := ComponentTextureBlock
                overlay_slot:
                    Widget := SelectionButton
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill

    SetImage<public>(Image : texture) : void = ComponentTextureBlock.SetImage(Image)
    Show<public>() : void = RootWidget.SetVisibility(widget_visibility.Visible)
    Hide<public>() : void = RootWidget.SetVisibility(widget_visibility.Hidden)
    GetRootWidget()<transacts> : widget = RootWidget

pumpkin_carving_score_screen_ui := class:
    ResetEvent : event() = event(){}
    var RootWidget : widget = overlay{}

    UniqueBegin() : void =
        {}

using { PumpkinStuff.PumpkinMaterials}
PumpkinTopMeshes<public> : []mesh = array:
    SM_Pumpkin_Top_Stem_1
    SM_Pumpkin_Top_Stem_2
    SM_Pumpkin_Top_Stem_3
    SM_Pumpkin_Top_Stem_4
    SM_Pumpkin_Top_Stem_5
    SM_Pumpkin_Top_Soda_Hat
    SM_Pumpkin_Top_Miner_Hat
    SM_Pumpkin_Top_Witch_Hat
    SM_Pumpkin_Top_Santa_Hat
    SM_Pumpkin_Top_Candle_Hat
    SM_Pumpkin_Top_Spider
    SM_Pumpkin_Top_Crown
    SM_Pumpkin_Top_Lamp_Post
    SM_Pumpkin_Top_Stem_Gold
    SM_Pumpkin_Top_TV
    SM_Pumpkin_Top_Toilet

PumpkinMaterials<public> : []material = array:
    MI_Pumpkin_Basic_Orange
    MI_Pumpkin_Basic_Black
    MI_Pumpkin_Basic_White

PumpkinColorComponentImages<public> : []texture = array:
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder
    T_Place_Holder

using { UIStuff.PumpkinCarvingUI.PumpkinTops}
PumpkinTopComponentImages<public> : []texture = array:
    T_Pumpkin_Top_Stem_1
    T_Pumpkin_Top_Stem_2
    T_Pumpkin_Top_Stem_3
    T_Pumpkin_Top_Stem_4
    T_Pumpkin_Top_Stem_5
    T_Pumpkin_Top_Soda_Hat
    T_Pumpkin_Top_Miner_Hat
    T_Pumpkin_Top_Witch_Hat
    T_Pumpkin_Top_Santa_Hat
    T_Pumpkin_Top_Candles
    T_Pumpkin_Top_Spider
    T_Pumpkin_Top_Crown
    T_Pumpkin_Top_Lamp_Post
    T_Pumpkin_Top_Stem_Gold
    T_Pumpkin_Top_TV
    T_Pumpkin_Top_Toilet

PumpkinEyesComponentImages<public> : []texture = array:
    T_Pumpkin_Eyes_4_1
    T_Pumpkin_Eyes_4_2
    T_Pumpkin_Eyes_4_3
    T_Pumpkin_Eyes_4_4
    T_Pumpkin_Eyes_2_1
    T_Pumpkin_Eyes_2_2
    T_Pumpkin_Eyes_2_3
    T_Pumpkin_Eyes_2_4
    T_Pumpkin_Eyes_3_1
    T_Pumpkin_Eyes_3_2
    T_Pumpkin_Eyes_3_3
    T_Pumpkin_Eyes_3_4
    T_Pumpkin_Eyes_1_1
    T_Pumpkin_Eyes_1_2
    T_Pumpkin_Eyes_1_3
    T_Pumpkin_Eyes_1_4

PumpkinMouthComponentImages<public> : []texture = array:
    T_Pumpkin_Mouth_4_1
    T_Pumpkin_Mouth_4_2
    T_Pumpkin_Mouth_4_3
    T_Pumpkin_Mouth_4_4
    T_Pumpkin_Mouth_2_1
    T_Pumpkin_Mouth_2_2
    T_Pumpkin_Mouth_2_3
    T_Pumpkin_Mouth_2_4
    T_Pumpkin_Mouth_3_1
    T_Pumpkin_Mouth_3_2
    T_Pumpkin_Mouth_3_3
    T_Pumpkin_Mouth_3_4
    T_Pumpkin_Mouth_1_1
    T_Pumpkin_Mouth_1_2
    T_Pumpkin_Mouth_1_3
    T_Pumpkin_Mouth_1_4

