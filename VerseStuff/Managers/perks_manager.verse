using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { UIStuff }
using { Perks }

perks_manager<public> := class<concrete>:    
    @editable       LockerButton : button_device = button_device{}
    @editable       CashbackPerkSettings : cashback_perk_settings = cashback_perk_settings{}
    @editable       RefundPerkSettings : refund_perk_settings = refund_perk_settings{}
    @editable       ExtraXPPerkSettings : extra_xp_perk_settings = extra_xp_perk_settings{}

    ResetEvent : event() = event(){}
    RefundPerk : refund_perk = refund_perk{}
    CashbackPerk : cashback_perk = cashback_perk{}
    ExtraXPPerk : extra_xp_perk = extra_xp_perk{}
    PerksSelectionUI : perks_selection_ui = perks_selection_ui{}
    
    var TycoonPerks : []tycoon_perk = array{}
    # (Perk Slot, Perk ID), Perk ID (-1) = No Perk
    var SelectedPerksIDMap : [int]int = map{}
    var PerkLevelIDMap : [int]int = map{}

    UniqueBegin<public>() : void =
        set TycoonPerks = array{RefundPerk, CashbackPerk, ExtraXPPerk}
        for ( ID -> Perk : TycoonPerks, set PerkLevelIDMap[ID] = 0) {}
        for ( I := 0..1, set SelectedPerksIDMap[I] = -1 ) {}
        PerksSelectionUI.UniqueBegin()
        RefundPerk.UniqueBegin(RefundPerkSettings)
        CashbackPerk.UniqueBegin(CashbackPerkSettings)
        ExtraXPPerk.UniqueBegin(ExtraXPPerkSettings)

    Init<public>(TycoonManager : tycoon_manager) : void =
        for ( Perk : TycoonPerks) do Perk.Init(TycoonManager)

    SetPerkLevel<public>(PerkID : int, PerkLevel : int) : void = 
        if ( Perk := TycoonPerks[PerkID], set PerkLevelIDMap[PerkID] = PerkLevel):
            Perk.SetLevel(PerkLevel)

    LoadData<public>(Owner : custom_player, TycoonManager : tycoon_manager, PlayerStats : player_stats) : void =
        for ( ID -> Perk : TycoonPerks):
            if ( set PerkLevelIDMap[ID] = PlayerStats.PerkStats.PerkLevelIDMap[ID] or 0 ) {}
        for ( I := 0..1):
            if ( set SelectedPerksIDMap[I] = PlayerStats.PerkStats.SelectedPerksIDMap[I] or -1) {}
  
        for ( PerkIndex->PerkLevel : PerkLevelIDMap, Perk := TycoonPerks[PerkIndex]) do Perk.SetLevel(PerkLevel)
        for ( PerkSlot->PerkID : SelectedPerksIDMap, Perk := TycoonPerks[PerkID]) do Perk.Enable(Owner, TycoonManager)
        
        spawn{ Update(Owner, TycoonManager)}

    Update(Owner : custom_player, TycoonManager : tycoon_manager)<suspends> : void =
        race:
            ResetEvent.Await()
            loop:
                Agent := LockerButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    PerksSelectionUI.RefreshAvailablePerks(TycoonPerks)
                    PerksSelectionUI.RefreshActivePerks(SelectedPerksIDMap)
                    PerksSelectionUI.Display(Owner)
                    PollUIEvents(Owner)
                    PerksSelectionUI.Remove(Owner)

    EquipPerk(Owner : custom_player, PerkSlot : int, PerkID : int) : void =
        <# Don't do anything if perk is same as current perk in slot #>
        for ( SlotIndex->SlotPerkID : SelectedPerksIDMap, SlotPerkID = PerkID) do return
        <# Disable current perk #>
        if ( CurrentPreviousPerkID := SelectedPerksIDMap[PerkSlot], CurrentPerk := TycoonPerks[PerkID]):
            CurrentPerk.Disable()
        <# Activate new perk if it exists #>
        if ( NewPerk := TycoonPerks[PerkID], TycoonManager := Owner.MaybeTycoonManager?, set SelectedPerksIDMap[PerkSlot] = PerkID):
            NewPerk.Enable(Owner, TycoonManager)
        <# Set perk as empty (???) #>
        else:
            if ( set SelectedPerksIDMap[PerkSlot] = -1) {}
        PerksSelectionUI.RefreshActivePerks(SelectedPerksIDMap)  

    PollUIEvents(Owner : custom_player)<suspends> : void =
        race:
            Owner.FortCharacter.EliminatedEvent().Await()
            PerksSelectionUI.ExitButton.OnClick().Await()
            AwaitAndResolvePerkSelection(Owner, 0)
            AwaitAndResolvePerkSelection(Owner, 1)
            AwaitAndResolvePerkSelection(Owner, 2)
            AwaitAndResolveActivePerkToggle(Owner, 0)
            AwaitAndResolveActivePerkToggle(Owner, 1)

    AwaitAndResolvePerkSelection(Owner : custom_player, PerkSelectionWidgetIndex : int)<suspends> : void =
        Button := PerksSelectionUI.PerkSelectionWidgets[PerkSelectionWidgetIndex].SelectionButton or button_quiet{}
        loop:
            Button.OnClick().Await()
            PerkID := 3 * (PerksSelectionUI.CurrentPage - 1) + PerkSelectionWidgetIndex
            EquipPerk(Owner, PerksSelectionUI.FocusedActivePerkWidgetIndex, PerkID)

    AwaitAndResolveActivePerkToggle(Owner : custom_player, ActivePerkIndex : int)<suspends> : void =
        Button := PerksSelectionUI.ActivePerkWidgets[ActivePerkIndex].SelectionButton or button_quiet{}
        loop:
            Button.OnClick().Await()
            set PerksSelectionUI.FocusedActivePerkWidgetIndex = ActivePerkIndex
            PerksSelectionUI.RefreshActivePerks(SelectedPerksIDMap)
                
    GetStats<public>() : tycoon_perk_stats = 
        tycoon_perk_stats:
            SelectedPerksIDMap := SelectedPerksIDMap
            PerkLevelIDMap := PerkLevelIDMap

    Reset<public>() : void =
        LockerButton.Disable()

perks_selection_ui := class:
    Canvas : canvas = canvas{}
    ExitButton : button_quiet = button_quiet{}

    var PerkSelectionWidgets : []perk_selection_widget = array{}
    var ActivePerkWidgets : []active_perk_widget = array{}

    var RootWidget : widget = overlay{}
    var FocusedActivePerkWidgetIndex : int = 0
    var CurrentPage : int = 1

    UniqueBegin() : void =
        set ActivePerkWidgets = for ( I := 0..1):
            NewWidget := active_perk_widget{}
            NewWidget.UniqueBegin()
            NewWidget
        set PerkSelectionWidgets = for ( I := 0..2):
            NewWidget := perk_selection_widget{}
            NewWidget.UniqueBegin(vector2{ X := 490.0, Y := 490.0})
            NewWidget
        set RootWidget = CreateUI()
        Canvas.AddWidget(canvas_slot{Widget := RootWidget})

    Display(CustomPlayer : custom_player) : void =
        if ( PlayerUI := GetPlayerUI[CustomPlayer.Player]):
            PlayerUI.AddWidget(Canvas, player_ui_slot{InputMode := ui_input_mode.All})

    Remove(CustomPlayer : custom_player) : void =
        if ( PlayerUI := GetPlayerUI[CustomPlayer.Player]) then PlayerUI.RemoveWidget(Canvas)

    RefreshAvailablePerks(TycoonPerks : []tycoon_perk) : void =
        # UnlockedPerkIDs := for ( PerkID->PerkLevel : PerkLevelIDMap, PerkLevel > 0) do PerkID
        for ( I := 0..2, PerkID := 3 * (CurrentPage - 1) + I, PerkSelectionWidget := PerkSelectionWidgets[I]):
            PerkSelectionWidget.SetPerkInfo(option{TycoonPerks[PerkID]}, PerkID)

    RefreshActivePerks(SelectedPerksIDMap : [int]int) : void =
        for ( PerkSlot -> PerkID : SelectedPerksIDMap,  Widget := ActivePerkWidgets[PerkSlot]):
            IsFocused := PerkSlot = FocusedActivePerkWidgetIndex and true or false
            Widget.SetPerkIcon(option{PerkIcons[PerkID]})
            Widget.SetFocusedStatus(IsFocused)

    CreateUI() : overlay =
        PerkSelectionWidgetStackBoxSlots := for ( Index->Widget : PerkSelectionWidgets) do stack_box_slot{Widget := Widget.GetRootWidget(), Padding := Index = 1 and margin{Left := 15.0, Right := 15.0} or margin{}}
        ActivePerkWidgetStackBoxSlots := for ( Index->Widget : ActivePerkWidgets) do stack_box_slot{Widget := Widget.GetRootWidget(), HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Right := 20.0}}
        overlay:
            Slots := array:
                overlay_slot: <# Overlay Image #>
                    Widget := texture_block{DefaultImage := T_Perk_Selection_Overlay, DefaultDesiredSize := vector2{ X := 1920.0, Y := 1080.0}}
                overlay_slot: <# Selection Perks #>
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Top := 75.0}
                    Widget := stack_box:
                        Orientation := orientation.Horizontal
                        Slots := PerkSelectionWidgetStackBoxSlots
                overlay_slot: <# Active Perks #>
                    HorizontalAlignment := horizontal_alignment.Left
                    Padding := margin{ Left := 1055.0, Top := 225.0}
                    Widget := stack_box:
                        Orientation := orientation.Horizontal
                        Slots := ActivePerkWidgetStackBoxSlots
                overlay_slot: <# Exit Button (Done) #>
                    VerticalAlignment := vertical_alignment.Bottom
                    Padding := margin{Bottom := 35.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := color_block{DefaultDesiredSize := vector2{ X := 512.0, Y := 115.0}, DefaultOpacity := 0.0}
                            overlay_slot:
                                Widget := ExitButton 
                                HorizontalAlignment := horizontal_alignment.Fill
                                VerticalAlignment := vertical_alignment.Fill

    GetRootWidget()<transacts> : widget = RootWidget
    GetCanvas()<transacts> : canvas = Canvas

perk_selection_widget := class:
    SelectionButton : button_quiet = button_quiet{}
    PerkTextureBlock : texture_block = texture_block{DefaultImage := T_Place_Holder}
    PerkLevelTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FDFF00FF")}
    PerkDescriptionTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFFFFFFF")}
    
    var RootWidget : widget = overlay{}

    UniqueBegin(PerkTextureSize : vector2) : void =
        PerkTextureBlock.SetDesiredSize(PerkTextureSize)
        set RootWidget = overlay:
            Slots := array:
                overlay_slot: <# Overlay Image #>
                    Widget := PerkTextureBlock
                overlay_slot: <# Level and description #>
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Top := 105.0}
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := array:
                            stack_box_slot:
                                Widget := PerkLevelTextBlock
                            stack_box_slot:
                                Widget := PerkDescriptionTextBlock
                overlay_slot: <# Selection Button #>
                    VerticalAlignment := vertical_alignment.Bottom
                    Padding := margin{ Bottom := 15.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := color_block{DefaultDesiredSize := vector2{ X := 350.0, Y := 85.0}, DefaultOpacity := 0.0}
                            overlay_slot:
                                Widget := SelectionButton 
                                HorizontalAlignment := horizontal_alignment.Fill
                                VerticalAlignment := vertical_alignment.Fill 

    SetPerkInfo(MaybePerk : ?tycoon_perk, PerkID : int) : void =
        if ( Perk := MaybePerk?):
            RootWidget.SetVisibility(widget_visibility.Visible)
            
            PerkTextureBlock.SetImage(PerkSelectionImages[PerkID] or T_Place_Holder)
            if ( Perk.GetLevel() > 0): <# Normal perk behavior I guess lol#>
                SelectionButton.SetVisibility(widget_visibility.Visible)
                PerkLevelTextBlock.SetText(StringToMessage("Lv. {Perk.GetLevel()}"))
                PerkDescriptionTextBlock.SetText(StringToMessage(Perk.GetDescription()))
            else: <# Locked perk #>
                SelectionButton.SetVisibility(widget_visibility.Hidden)
                PerkLevelTextBlock.SetText(StringToMessage("Locked"))
                PerkDescriptionTextBlock.SetText(StringToMessage(""))         
        else:
            RootWidget.SetVisibility(widget_visibility.Hidden)
    SetPerkOverlay(Image : texture) : void = PerkTextureBlock.SetImage(Image)
    SetPerkLevel(Level : int) : void = PerkLevelTextBlock.SetText(StringToMessage("Lv. {Level}"))
    SetPerkDescription(Description : string) : void = PerkDescriptionTextBlock.SetText(StringToMessage("{Description}"))
    
    GetRootWidget() : widget = RootWidget

using { UIStuff.PerksUI}
active_perk_widget := class:
    SelectionButton : button_quiet = button_quiet{}
    PerkEquipOverlay : texture_block = texture_block{DefaultImage := T_Selected_Perk_Overlay}
    PerkTextureBlock : texture_block = texture_block{DefaultImage := T_Place_Holder}
    
    var RootWidget : widget = overlay{}

    UniqueBegin() : void =
        PerkEquipOverlay.SetDesiredSize(vector2{X := 128.0, Y := 128.0})
        PerkTextureBlock.SetDesiredSize(vector2{X := 110.0, Y := 110.0})
        set RootWidget = overlay:
            Slots := array:
                overlay_slot:
                    Widget := PerkEquipOverlay
                overlay_slot:
                    Widget := PerkTextureBlock
                overlay_slot:
                    Widget := SelectionButton
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill

    SetPerkIcon(MaybeImage : ?texture) : void = 
        if ( Image := MaybeImage?):
            PerkTextureBlock.SetVisibility(widget_visibility.Visible)
            PerkTextureBlock.SetImage(Image)
        else:
            PerkTextureBlock.SetVisibility(widget_visibility.Hidden)
    SetFocusedStatus(IsSelected : logic) : void =
        if ( IsSelected?):
            PerkEquipOverlay.SetTint(MakeColorFromHex("29FF00FF"))
            PerkTextureBlock.SetTint(MakeColorFromHex("FFEA00FF"))
        else:
            PerkEquipOverlay.SetTint(MakeColorFromHex("FFFFFFFF"))
            PerkTextureBlock.SetTint(MakeColorFromHex("C1C1C1FF"))
    GetRootWidget()<transacts> : widget = RootWidget

PerkIcons : []texture = array:
    T_Perk_Icon_Refund
    T_Perk_Icon_Cashback
    T_Perk_Icon_Supercharged

PerkSelectionImages : []texture = array:
    T_Perk_Overlay_Refund
    T_Perk_Overlay_Cashback
    T_Perk_Overlay_Supercharged