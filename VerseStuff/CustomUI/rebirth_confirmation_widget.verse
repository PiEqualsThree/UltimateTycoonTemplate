using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { VerseStuff.Managers }
using { UIStuff.RebirthUI}
using { UIStuff.SeasonPassUI}

rebirth_confirmation_widget<public>:= class:
    RebirthAcceptedEvent<public> : event() = event(){}
    RebirthDeniedEvent<public> : event() = event(){}
    ResetEvent<public> : event() = event(){}

    RebirthCounterTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("F1D600FF")}
    AcceptButton : button_quiet = button_quiet{}
    DenyButton : button_quiet = button_quiet{}
    Canvas : canvas = canvas{}

    var RootWidget : widget = overlay{}
    var RewardWidgets : []rebirth_reward_slot_widget = array{}

    UniqueBegin<public>() : void =
        set RewardWidgets = for ( I := 0..4):
            NewWidget := rebirth_reward_slot_widget{}
            NewWidget.UniqueBegin()
            NewWidget
        set RootWidget = CreateUI()
        Canvas.AddWidget(canvas_slot{Widget := RootWidget, Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{ X := 0.5, Y := 0.5}}, Alignment := vector2{X := 0.5, Y := 0.5}})
        RootWidget.SetVisibility(widget_visibility.Hidden)

    Show<public>(CustomPlayer : custom_player, RewardData : []rebirth_reward_data) : void =
        UpdateRewards(RewardData)
        if ( PlayerUI := GetPlayerUI[CustomPlayer.Player]):
            PlayerUI.AddWidget(Canvas, player_ui_slot{InputMode := ui_input_mode.All})
            RebirthCounterTextBlock.SetText(StringToMessage("{CustomPlayer.Rebirths} -> {CustomPlayer.Rebirths + 1}"))
            RootWidget.SetVisibility(widget_visibility.Visible)
            spawn{AwaitEvents(CustomPlayer, RewardData)}

    AwaitEvents(CustomPlayer : custom_player, RewardData : []rebirth_reward_data)<suspends> : void =
        race:
            ResetEvent.Await()
            CustomPlayer.FortCharacter.EliminatedEvent().Await()
            UpdateAnimations(RewardData.Length)
            block:
                AcceptButton.OnClick().Await()
                RebirthAcceptedEvent.Signal()
            block:
                DenyButton.OnClick().Await()
                RebirthDeniedEvent.Signal()
        if ( PlayerUI := GetPlayerUI[CustomPlayer.Player]):
            PlayerUI.RemoveWidget(Canvas)
            RootWidget.SetVisibility(widget_visibility.Hidden)

    UpdateAnimations(ActiveWidgets : int)<suspends> : void =
        for ( Widget : RewardWidgets) do Widget.RewardImageTextureBlock.SetDesiredSize(vector2{ X := 150.0, Y := 150.0})
        DefaultSize := if ( TextureBlock := RewardWidgets[0].RewardImageTextureBlock) then TextureBlock.GetDesiredSize() else vector2{X := 150.0, Y := 150.0}
        TargetSize := vector2{ X := 200.0, Y := 200.0}
        Sleep(1.0)
        loop:
            for ( I := 0..ActiveWidgets - 1, Widget := RewardWidgets[I]):
                # Sleep(0.25)
                for ( J := 1..10):
                    Alpha := (1.0 * J) / 10.0
                    Widget.RewardImageTextureBlock.SetDesiredSize(Lerp(DefaultSize, TargetSize, (1.0 * J) / 10.0))
                    Sleep(0.0)
                for ( J := 1..10):
                    Alpha := (1.0 * J) / 10.0
                    Widget.RewardImageTextureBlock.SetDesiredSize(Lerp(TargetSize, DefaultSize, (1.0 * J) / 10.0))
                    Sleep(0.0)
            Sleep(3.0)
    CreateUI() : widget =
        RewardStackBoxSlots := for ( Widget : RewardWidgets) do stack_box_slot{Widget := Widget.GetRootWidget()}
        overlay:
            Slots := array:
                overlay_slot: <# Overlay Image #>
                    Widget := texture_block{DefaultImage := UIStuff.RebirthUI.T_Rebirth_Confirm_Screen, DefaultDesiredSize := vector2{ X := 1920.0, Y := 1080.0}}
                overlay_slot: <# Main reward slots #>
                    Padding := margin{Bottom := 10.0}
                    Widget := stack_box:
                        Orientation := orientation.Horizontal
                        Slots := RewardStackBoxSlots
                overlay_slot: <# Accept Button #>
                    VerticalAlignment := vertical_alignment.Bottom
                    Padding := margin{Right := 179.0, Bottom := 152.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := color_block{DefaultDesiredSize := vector2{ X := 315.0, Y := 70.0}, DefaultOpacity := 0.0}
                            overlay_slot:
                                Widget := AcceptButton
                                HorizontalAlignment := horizontal_alignment.Fill
                                VerticalAlignment := vertical_alignment.Fill
                overlay_slot: <# Deny Button #>
                    VerticalAlignment := vertical_alignment.Bottom
                    Padding := margin{Left := 179.0, Bottom := 152.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := color_block{DefaultDesiredSize := vector2{ X := 315.0, Y := 70.0}, DefaultOpacity := 0.0}
                            overlay_slot:
                                Widget := DenyButton
                                HorizontalAlignment := horizontal_alignment.Fill
                                VerticalAlignment := vertical_alignment.Fill
                overlay_slot:
                    Widget := RebirthCounterTextBlock
                    VerticalAlignment := vertical_alignment.Bottom
                    Padding := margin{Bottom := 275.0}

    UpdateRewards(RewardData : []rebirth_reward_data) : void =
        var CurrentVisibleWidgetIndex : int = 0
        for ( Index->Data : RewardData, Widget := RewardWidgets[Index]):
            set CurrentVisibleWidgetIndex = CurrentVisibleWidgetIndex + 1
            Widget.SetRewardInfo(Data.Name, Data.Image, ?TextColor := Data.TextColor)
            Widget.Show()
        for ( Index->Widget : RewardWidgets, Index >= CurrentVisibleWidgetIndex):
            Widget.Hide()

rebirth_reward_slot_widget := class:
    RewardImageTextureBlock : texture_block = texture_block{DefaultImage := T_Reward_Default, DefaultDesiredSize := vector2{ X := 150.0, Y := 150.0}}
    RewardNameTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex(""), DefaultShadowOffset := option{vector2{ X := 2.0, Y := 2.0}}, DefaultShadowOpacity := 1.0 }
    var RootWidget : widget = overlay{}

    UniqueBegin() : void = 
        set RootWidget = overlay:
            Slots := array:
                overlay_slot: <# Slot Image #>
                    Widget := texture_block{DefaultImage := T_Rebirth_Confirm_Screen_Reward_Slot, DefaultDesiredSize := vector2{ X := 210.0, Y := 225.0}}
                overlay_slot: <# Reward Image #>
                    Widget := RewardImageTextureBlock
                overlay_slot: <# Slot Name #>
                    VerticalAlignment := vertical_alignment.Bottom
                    Padding := margin{Bottom := -25.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := color_block{DefaultDesiredSize := vector2{ X := 240.0, Y := 32.0}, DefaultOpacity := 0.0}
                            overlay_slot:
                                Widget := RewardNameTextBlock

    Show() : void = RootWidget.SetVisibility(widget_visibility.Visible)
    Hide() : void = RootWidget.SetVisibility(widget_visibility.Collapsed)

    SetRewardInfo(Name : string, Image : texture, ?TextColor : color = NamedColors.White) : void =
        RewardImageTextureBlock.SetImage(Image)
        RewardNameTextBlock.SetText(StringToMessage("{Name}"))
        RewardNameTextBlock.SetTextColor(TextColor)

    GetRootWidget() : widget = RootWidget

 
