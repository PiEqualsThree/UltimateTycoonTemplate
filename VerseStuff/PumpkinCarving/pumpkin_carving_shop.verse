using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Random }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
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
using { PumpkinStuff.PumpkinMaterials }

pumpkin_carving_shop<public> := class<concrete>:
    @editable       Button : button_device = button_device{}
    @editable       ShopContainer : creative_prop = creative_prop{}
    @editable       PurchaseSuccessAudio : audio_player_device = audio_player_device{}
    @editable       PurchaseErrorAudio : audio_player_device = audio_player_device{}
    @editable       PreviewCamera : gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}
    @editable       PumpkinTopProp : creative_prop = creative_prop{}
    @editable       PumpkinBaseProp : creative_prop = creative_prop{}

    ResetEvent : event() = event(){}
    ShopUI : pumpkin_carving_shop_ui = pumpkin_carving_shop_ui{}
    ComponentSwitchThrottleTime : float = 0.25

    var AvailableMaterialIDs : []int = array{}
    var AvailableTopIDs : []int = array{}
    var AvailableEyeIDs : []int = array{}
    var AvailableMouthIDs : []int = array{}

    var CurrentComponentPage : int = 0
    var CurrentComponentIndex : int = 0
    var AllowComponentChange :  logic = true
    var CurrentEyeDecal : ?creative_prop = false
    var CurrentMouthDecal : ?creative_prop = false

    var ThrottleComponentChange : logic = false

    var DefaultContainerTransform : transform = transform{}

    UniqueBegin<public>() : void =
        set DefaultContainerTransform = ShopContainer.GetTransform()
        ShopUI.UniqueBegin()

    Init<public>() : void =
        PumpkinTopProp.Hide()
        PumpkinBaseProp.Hide()
        ShopUI.Init()
        if ( Decal := CurrentEyeDecal?) then Decal.Hide()
        if ( Decal := CurrentMouthDecal?) then Decal.Hide()
        if ( ShopContainer.TeleportTo[DefaultContainerTransform.Translation - vector3{Z := 3000.0}, rotation{}]) {}
        set CurrentComponentPage = 0
        set CurrentComponentIndex = -1

    LoadData<public>(Owner : custom_player, PumpkinCarvingManager : pumpkin_carving_manager) : void =
        if ( ShopContainer.TeleportTo[DefaultContainerTransform]) {}
        UpdateAvailableMaterials(PumpkinCarvingManager)
        UpdateAvailableTops(PumpkinCarvingManager)
        UpdateAvailableMouths(PumpkinCarvingManager)
        UpdateAvailableEyes(PumpkinCarvingManager)
        spawn{Update(Owner, PumpkinCarvingManager)}

    Update(Owner : custom_player, PumpkinCarvingManager : pumpkin_carving_manager)<suspends> : void =
        race:
            ResetEvent.Await()
            AwaitButtonInteraction(Owner, PumpkinCarvingManager)

    AwaitButtonInteraction(Owner : custom_player, PumpkinCarvingManager : pumpkin_carving_manager)<suspends> : void =
        loop:
            Agent := Button.InteractedWithEvent.Await()
            if ( Owner.Agent = Agent, PageIndex := GetPageIndexWithAvailableComponents[CurrentComponentPage]):
                set ThrottleComponentChange = false
                UpdateAvailableMaterials(PumpkinCarvingManager)
                UpdateAvailableTops(PumpkinCarvingManager)
                UpdateAvailableMouths(PumpkinCarvingManager)
                UpdateAvailableEyes(PumpkinCarvingManager)
                ShopUI.UpdateComponentPage(Self, CurrentComponentPage)
                ShopUI.Display(Owner)      
                PreviewCamera.AddTo(Owner.Agent)
                PollUIEvents(Owner, PumpkinCarvingManager)
                ShopUI.Remove(Owner)
                PreviewCamera.RemoveFrom(Owner.Agent)

    PollUIEvents(Owner : custom_player, PumpkinCarvingManager : pumpkin_carving_manager)<suspends> : void=
        race:
            ResetEvent.Await()
            Owner.FortCharacter.EliminatedEvent().Await()
            ShopUI.FinishButton.OnClick().Await()
            AwaitAndResolvePurchaseButtonPress(Owner, PumpkinCarvingManager)
            AwaitAndResolvePageButtonPress(Owner, PumpkinCarvingManager, 0)
            AwaitAndResolvePageButtonPress(Owner, PumpkinCarvingManager, 1)
            AwaitAndResolvePageButtonPress(Owner, PumpkinCarvingManager, 2)
            AwaitAndResolvePageButtonPress(Owner, PumpkinCarvingManager, 3)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 0)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 1)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 2)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 3)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 4)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 5)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 6)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 7)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 8)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 9)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 10)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 11)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 12)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 13)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 14)
            AwaitAndResolveComponentButtonPress(Owner, PumpkinCarvingManager, 15)

    AwaitAndResolveComponentButtonPress(Owner : custom_player, PumpkinCarvingManager : pumpkin_carving_manager, ComponentIndex : int)<suspends> : void =
        ComponentButton := ShopUI.ComponentWidgets[ComponentIndex].PurchaseButton or button_quiet{}
        loop:
            ComponentButton.OnClick().Await()
            set CurrentComponentIndex = ComponentIndex
            if ( not ThrottleComponentChange?):
                set ThrottleComponentChange = true
                case(CurrentComponentPage):
                    0 => UpdateColorComponent(PumpkinCarvingManager, AvailableMaterialIDs[ComponentIndex] or -1)
                    1 => UpdateTopComponent(PumpkinCarvingManager, AvailableTopIDs[ComponentIndex] or -1)
                    2 => UpdateEyesComponent(PumpkinCarvingManager, AvailableEyeIDs[ComponentIndex] or -1)
                    3 => UpdateMouthComponent(PumpkinCarvingManager, AvailableMouthIDs[ComponentIndex] or -1)
                    _ => Print("Unkown Component Page")
                Sleep(ComponentSwitchThrottleTime)
                set ThrottleComponentChange = false

    AwaitAndResolvePageButtonPress(Owner : custom_player, PumpkinCarvingManager : pumpkin_carving_manager, PageIndex : int)<suspends> : void =
        PageButton := case(PageIndex) { 0 => ShopUI.ColorPageButton; 1 => ShopUI.TopPageButton; 2 => ShopUI.EyesPageButton; 3 => ShopUI.MouthPageButton; _ => button_quiet{}}
        # ComponentIndicesArray := array{} <# TODO #>
        loop:
            PageButton.OnClick().Await()
            if ( CurrentComponentPage <> PageIndex):
                set CurrentComponentPage = PageIndex
                set CurrentComponentIndex = 0
                ShopUI.UpdateComponentPage(Self, PageIndex)
                case(CurrentComponentPage):
                    0 => UpdateColorComponent(PumpkinCarvingManager, AvailableMaterialIDs[0] or -1)
                    1 => UpdateTopComponent(PumpkinCarvingManager, AvailableTopIDs[0] or -1)
                    2 => UpdateEyesComponent(PumpkinCarvingManager, AvailableEyeIDs[0] or -1)
                    3 => UpdateMouthComponent(PumpkinCarvingManager, AvailableMouthIDs[0] or -1)
                    _ => Print("Unkown Component Page")
        
    AwaitAndResolvePurchaseButtonPress(Owner : custom_player, PumpkinCarvingManager : pumpkin_carving_manager)<suspends> : void =
        if ( TycoonManager := Owner.MaybeTycoonManager?):
            CurrencyManager := TycoonManager.CurrencyManager
            loop:
                ShopUI.PurchaseButton.OnClick().Await()
                ComponentID := case(CurrentComponentPage):
                    0 => AvailableMaterialIDs[CurrentComponentIndex] or -1
                    1 => AvailableTopIDs[CurrentComponentIndex] or -1
                    2 => AvailableEyeIDs[CurrentComponentIndex] or -1
                    3 => AvailableMouthIDs[CurrentComponentIndex] or -1
                    _ => -1
                Price := GetComponentPrice(CurrentComponentPage, ComponentID)
                Transaction := currency_transaction{Amount := Price, Type := currency_type.BlingBucks}
                if ( Price > -1, CurrencyManager.ValidatePurchase[Owner, Transaction]):
                    CurrencyManager.DecreaseCurrency(Owner, Transaction)
                    PurchaseSuccessAudio.Play(Owner.Player)
                    case (CurrentComponentPage):
                        0 => PumpkinCarvingManager.UnlockColor(AvailableMaterialIDs[CurrentComponentIndex] or -1)
                        1 => PumpkinCarvingManager.UnlockTop(AvailableTopIDs[CurrentComponentIndex] or - 1)
                        2 => PumpkinCarvingManager.UnlockEyes(AvailableEyeIDs[CurrentComponentIndex] or -1)
                        3 => PumpkinCarvingManager.UnlockMouth(AvailableMouthIDs[CurrentComponentIndex] or -1)
                        _ => Print("Unkown component page index!")
                    set CurrentComponentIndex = -1
                    Sleep(1.0)
                    break
                        
                else:
                    PurchaseErrorAudio.Play(Owner.Player)

    
    RefreshComponentWidgets() : void =
        ComponentIDs := case(CurrentComponentPage):
            0 => AvailableMaterialIDs
            1 => AvailableTopIDs
            2 => AvailableEyeIDs
            3 => AvailableMouthIDs
            _ => array{}

    UpdateAvailableMaterials(PumpkinCarvingManager : pumpkin_carving_manager) : void =
        var NewArray : []int = array{}
        UnlockedIDsMap := ToMap(PumpkinCarvingManager.UnlockedColorIDs)
        for ( I := 0..15, not UnlockedIDsMap[I]) do set NewArray = NewArray + array{I}
        set AvailableMaterialIDs = NewArray

    UpdateAvailableTops(PumpkinCarvingManager : pumpkin_carving_manager) : void =
        var NewArray : []int = array{}
        UnlockedIDsMap := ToMap(PumpkinCarvingManager.UnlockedTopIDs)
        for ( I := 0..15, not UnlockedIDsMap[I]) do set NewArray = NewArray + array{I}
        set AvailableTopIDs = NewArray

    UpdateAvailableEyes(PumpkinCarvingManager : pumpkin_carving_manager) : void =
        var NewArray : []int = array{}
        UnlockedIDsMap := ToMap(PumpkinCarvingManager.UnlockedEyeIDs)
        for ( I := 0..15, not UnlockedIDsMap[I]) do set NewArray = NewArray + array{I}
        set AvailableEyeIDs = NewArray

    UpdateAvailableMouths(PumpkinCarvingManager : pumpkin_carving_manager) : void =
        var NewArray : []int = array{}
        UnlockedIDsMap := ToMap(PumpkinCarvingManager.UnlockedMouthIDs)
        for ( I := 0..15, not UnlockedIDsMap[I]) do set NewArray = NewArray + array{I}
        set AvailableMouthIDs = NewArray

    UpdateColorComponent(PumpkinManager : pumpkin_carving_manager, ComponentIndex : int) : void =
        if ( EyeDecal := CurrentEyeDecal?) then EyeDecal.Hide()
        if ( MouthDecal := CurrentMouthDecal?) then MouthDecal.Hide()
        if ( Material := PumpkinMaterialComponents[ComponentIndex]):
            PumpkinTopProp.Hide()
            PumpkinBaseProp.Show()
            PumpkinBaseProp.SetMaterial(Material)
        else:
            PumpkinBaseProp.Hide()

    UpdateTopComponent(PumpkinManager : pumpkin_carving_manager, ComponentIndex : int) : void =
        PumpkinBaseProp.SetMaterial(MI_Pumpkin_Basic_Orange)
        if ( EyeDecal := CurrentEyeDecal?) then EyeDecal.Hide()
        if ( MouthDecal := CurrentMouthDecal?) then MouthDecal.Hide()
        if ( Mesh := PumpkinTopMeshes[ComponentIndex]):
            Print("Setting mesh {ComponentIndex}!")
            PumpkinBaseProp.Hide()
            PumpkinTopProp.Show()
            PumpkinTopProp.SetMesh(Mesh)
        else:
            PumpkinTopProp.Hide()

    UpdateEyesComponent(PumpkinManager : pumpkin_carving_manager, ComponentIndex : int) : void =
        PumpkinTopProp.Hide()
        PumpkinBaseProp.Show()
        PumpkinBaseProp.SetMaterial(MI_Pumpkin_Basic_Orange)
        if ( EyeDecal := CurrentEyeDecal?) then EyeDecal.Hide()
        if ( MouthDecal := CurrentMouthDecal?) then MouthDecal.Hide()
        if ( Decal := PumpkinManager.EyeDecals[ComponentIndex], Decal.TeleportTo[PumpkinBaseProp.GetTransform().Translation + vector3{ Z := 25.0}, PumpkinBaseProp.GetTransform().Rotation]):
            set CurrentEyeDecal = option{Decal}
            Decal.Show()
        else:
            Print("No decals to show!")
            
    UpdateMouthComponent(PumpkinManager : pumpkin_carving_manager, ComponentIndex : int) : void =
        PumpkinTopProp.Hide()
        PumpkinBaseProp.Show()
        PumpkinBaseProp.SetMaterial(MI_Pumpkin_Basic_Orange)
        if ( EyeDecal := CurrentEyeDecal?) then EyeDecal.Hide()
        if ( MouthDecal := CurrentMouthDecal?) then MouthDecal.Hide()
        if ( Decal := PumpkinManager.MouthDecals[ComponentIndex], Decal.TeleportTo[PumpkinBaseProp.GetTransform().Translation + vector3{Z := 25.0}, PumpkinBaseProp.GetTransform().Rotation]):
            set CurrentMouthDecal = option{Decal}
            Decal.Show()
        else:
            Print("No mouth decals to show")

    GetPageIndexWithAvailableComponents(CurrentPageIndex : int)<transacts><decides> : int = 
        var AvailablePageIndex : ?int = false
        if ( not PageHasAvailableComponents[CurrentPageIndex]):
            var HasIndexBeenFound : logic = false
            for ( I := 0..3, I <> CurrentPageIndex, not HasIndexBeenFound?, PageHasAvailableComponents[I]):
                set AvailablePageIndex = option{I}
                set HasIndexBeenFound = true
            AvailablePageIndex?
        else:
            CurrentPageIndex

    PageHasAvailableComponents(PageIndex : int)<transacts><decides> : void =
        case(PageIndex):
            0 => AvailableMaterialIDs[0]
            1 => AvailableTopIDs[0]
            2 => AvailableEyeIDs[0]
            3 => AvailableMouthIDs[0]

    # Type Index: 0 = Material, 1 = Top, 2 = Eye, 3 = Mouth
    GetComponentPrice(ComponentTypeIndex : int, ComponentID : int) : int = 
        case(ComponentTypeIndex):
            0 => PumpkinMaterialPrices[ComponentID] or -1
            1 => PumpkinTopPrices[ComponentID] or -1
            2 => PumpkinEyePrices[ComponentID] or -1
            3 => PumpkinMouthPrices[ComponentID] or -1
            _ => -1
        
    Reset() : void =
        set AvailableMaterialIDs = array{}
        set AvailableTopIDs = array{}
        set AvailableEyeIDs = array{}
        set AvailableMouthIDs = array{}
        set AllowComponentChange = true
        set CurrentComponentPage = 0
        set CurrentComponentIndex = 0
        ResetEvent.Signal()

pumpkin_carving_shop_ui := class:
    Canvas : canvas = canvas{}
    ColorPageButton : button_quiet = button_quiet{}
    TopPageButton : button_quiet = button_quiet{}
    EyesPageButton : button_quiet = button_quiet{}
    MouthPageButton : button_quiet = button_quiet{}
    
    PurchaseButton : button_quiet = button_quiet{}
    FinishButton : button_quiet = button_quiet{}
    PageTextureBlock : texture_block = texture_block{DefaultImage := T_Pumpkin_Carving_Page_Text_Color, DefaultDesiredSize := vector2{ X := 512.0, Y := 64.0}}

    var ComponentWidgets : []pumpkin_carving_shop_component_slot_widget = array{}

    var RootWidget : widget = overlay{}

    UniqueBegin() : void = 
        set ComponentWidgets = for ( I := 0..15):
            NewWidget := pumpkin_carving_shop_component_slot_widget{}
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

    UpdateComponentPage(PumpkinCarvingShopManager : pumpkin_carving_shop, PageIndex : int) : void =
        var UnlockedComponentIndices : []int = array{}
        var ImagesArray : []texture = array{}
        case(PageIndex):
            0 => 
                set UnlockedComponentIndices = PumpkinCarvingShopManager.AvailableMaterialIDs
                set ImagesArray = PumpkinMaterialComponentImages
                PageTextureBlock.SetImage(T_Pumpkin_Carving_Page_Text_Color)
            1 =>
                set UnlockedComponentIndices = PumpkinCarvingShopManager.AvailableTopIDs
                set ImagesArray = PumpkinTopComponentImages
                PageTextureBlock.SetImage(T_Pumpkin_Carving_Page_Text_Hat)
            2 =>
                set UnlockedComponentIndices = PumpkinCarvingShopManager.AvailableEyeIDs
                set ImagesArray = PumpkinEyesComponentImages
                PageTextureBlock.SetImage(T_Pumpkin_Carving_Page_Text_Eyes)
            3 =>
                set UnlockedComponentIndices = PumpkinCarvingShopManager.AvailableMouthIDs
                set ImagesArray = PumpkinMouthComponentImages
                PageTextureBlock.SetImage(T_Pumpkin_Carving_Page_Text_Mouth)
            _ => Print("Unkown Component Index {PageIndex}")

        for ( Index -> ID : UnlockedComponentIndices, Image := ImagesArray[ID], ComponentWidget := ComponentWidgets[Index]):
            ComponentWidget.SetImage(Image)
            ComponentWidget.Show()
            ComponentWidget.SetPrice(PumpkinCarvingShopManager.GetComponentPrice(PageIndex, ID))
        for ( I := UnlockedComponentIndices.Length..15, Widget := ComponentWidgets[I]) do Widget.Hide()

    Reset() : void =
        {}

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
                    Widget := texture_block{DefaultImage := T_Pumpkin_Shop_Overlay, DefaultDesiredSize := vector2{ X := 1920.0, Y := 1080.0}}
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
                                
                overlay_slot: <# Purchase Button #>
                    VerticalAlignment := vertical_alignment.Bottom
                    HorizontalAlignment := horizontal_alignment.Left
                    Padding := margin{Left := 150.0, Bottom := 75.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := texture_block{DefaultImage := T_Pumpkin_Shop_Buy_Button, DefaultDesiredSize := vector2{ X := 650.0, Y := 175.0}}
                            overlay_slot:
                                Widget := PurchaseButton 
                                Padding := margin{Top := 15.0, Bottom := 15.0}
                                HorizontalAlignment := horizontal_alignment.Fill
                                VerticalAlignment := vertical_alignment.Fill

                overlay_slot: <# Exit Button #>
                    VerticalAlignment := vertical_alignment.Bottom
                    Padding := margin{Left := 540.0, Top := 15.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := color_block{DefaultDesiredSize := vector2{ X := 850.0, Y := 80.0}, DefaultOpacity := 0.0}
                            overlay_slot:
                                HorizontalAlignment := horizontal_alignment.Fill
                                Widget := button:
                                    Slot := button_slot:                    
                                        Widget := overlay:
                                            Slots := array:
                                                overlay_slot:
                                                    Widget := color_block{DefaultDesiredSize := vector2{ X := 490.0, Y := 84.0}, DefaultOpacity := 0.0}
                                                overlay_slot:
                                                    Widget := FinishButton
                                                    HorizontalAlignment := horizontal_alignment.Fill
                                                    VerticalAlignment := vertical_alignment.Fill

pumpkin_carving_shop_component_slot_widget := class:
    PurchaseButton<public> : button_quiet = button_quiet{}
    ComponentTextureBlock : texture_block = texture_block{DefaultImage := T_Pumpkin_Eyes_1_1, DefaultDesiredSize := vector2{ X := 128.0, Y := 128.0}}
    CurrencyTextureBlock : texture_block = texture_block{DefaultImage := UIStuff.CurrencyUI.T_Bling_Bucks, DefaultDesiredSize := vector2{ X := 32.0, Y := 32.0}}
    PriceTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFFFFFFF")}
    var RootWidget : widget = overlay{}

    UniqueBegin() : void =
        set RootWidget = overlay:
            Slots := array:
                overlay_slot: <# Overlay Thing #>
                    Widget := texture_block{DefaultImage := T_Pumpkin_Carving_Component_Overlay, DefaultDesiredSize := vector2{ X := 128.0, Y := 128.0}}
                overlay_slot: <# Image #>
                    Widget := ComponentTextureBlock
                overlay_slot: <# Purchase Button #>
                    Widget := PurchaseButton
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                overlay_slot: <# Price Tag #>
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Top := -40.0}
                    Widget := stack_box:
                        Orientation := orientation.Horizontal
                        Slots := array:
                            stack_box_slot:
                                Widget := CurrencyTextureBlock
                            stack_box_slot:
                                Widget := PriceTextBlock

    SetImage<public>(Image : texture) : void = ComponentTextureBlock.SetImage(Image)
    SetPrice<public>(Amount : int) : void = PriceTextBlock.SetText(StringToMessage("{FormatNumber(Amount)}"))
    Show<public>() : void = RootWidget.SetVisibility(widget_visibility.Visible)
    Hide<public>() : void = RootWidget.SetVisibility(widget_visibility.Hidden)
    GetRootWidget()<transacts> : widget = RootWidget

