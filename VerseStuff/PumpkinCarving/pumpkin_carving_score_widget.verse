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
using { Managers }
using { UIStuff.PumpkinCarvingUI}

pumpkin_carving_score_widget<public> := class:
    ResetEvent : event() = event(){}
    Canvas : canvas = canvas{}

    var RootWidget : widget = overlay{}
    var StarTextureBlocks : []texture_block = array{}
    var ScoreTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFFFFFFF")}
    var CashTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFFFFFFF")}
    var CandyTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFFFFFFF")}
    var ClaimButton : text_button_base = button_quiet{}

    UniqueBegin<public>() : void =
        set RootWidget = CreateUI()
        Canvas.AddWidget(
            canvas_slot:
                Widget := RootWidget
                Anchors := anchors{Minimum := vector2{ X := 1.0, Y := 0.5}, Maximum := vector2{ X := 1.0, Y := 0.5}}
                Alignment := vector2{ X := 1.0, Y := 0.5}
                Offsets := margin{Left := -200.0}
        )

    Display<public>(Owner : custom_player, PumpkinCarvingManager : pumpkin_carving_manager, Result : pumpkin_carving_score_result)<suspends> : void =
        defer{Remove(Owner)}
        if ( PlayerUI := GetPlayerUI[Owner.Player]):
            PlayerUI.AddWidget(Canvas, player_ui_slot{InputMode := ui_input_mode.All})
            RootWidget.SetVisibility(widget_visibility.Visible)
            race:
                ResetEvent.Await()
                ClaimButton.OnClick().Await()
                Owner.FortCharacter.EliminatedEvent().Await()
                AnimateScore(Owner, PumpkinCarvingManager, Result)
        else:
            Print("Unable to add score widget!")

    Remove<public>(Owner : custom_player) : void =
        if ( PlayerUI := GetPlayerUI[Owner.Player]):
            PlayerUI.RemoveWidget(Canvas)
            RootWidget.SetVisibility(widget_visibility.Hidden)
            ScoreTextBlock.SetText(StubMessage)
            CashTextBlock.SetText(StubMessage)
            CandyTextBlock.SetText(StubMessage)

    AnimateScore(Owner : custom_player, PumpkinCarvingManager : pumpkin_carving_manager, Result : pumpkin_carving_score_result)<suspends> : void =
        Stars := Floor(Result.Score / 20) or 1
        for ( Index->StarTextureBlock : StarTextureBlocks) do StarTextureBlock.SetImage(T_Score_Screen_Star_Grey)
        <# Animate 20s #>
        for ( I := 0..Stars-1, StarTextureBlock := StarTextureBlocks[I]):
            for ( J := 1..20):
                ScoreTextBlock.SetText(StringToMessage("{I * 20 + J}%"))
                Sleep(0.0)
            StarTextureBlock.SetImage(T_Score_Screen_Star_Gold)
            if ( Audio := PumpkinCarvingManager.ScoreStarAudios[I]) then Audio.Play(Owner.Player)
        for ( I := (20 * Stars)..Result.Score):
            ScoreTextBlock.SetText(StringToMessage("{I}%"))
            Sleep(0.0)
        ScoreTextBlock.SetText(StringToMessage("{Result.Score}%"))

        for ( I := 1..20):
            Alpha := (1.0 * I ) / 20.0
            CashAmount := Lerp(0.0, 1.0 * Result.CashGain, Alpha)
            CandyAmount := Lerp(0.0, 1.0 * Result.CandyGain, Alpha)
            CashTextBlock.SetText(StringToMessage("{FormatNumber(Ceil[CashAmount] or 1)}"))
            CandyTextBlock.SetText(StringToMessage("{FormatNumber(Ceil[CandyAmount] or 1)}"))
            Sleep(0.0)
        PumpkinCarvingManager.ScoreResultAudio.Play(Owner.Player)
        CashTextBlock.SetText(StringToMessage("{FormatNumber(Result.CashGain)}"))
        CandyTextBlock.SetText(StringToMessage("{FormatNumber(Result.CandyGain)}"))
        Sleep(6.0)

    CreateUI() : widget = 
        StarStackBoxSlots := for ( I := 0..4):
            TextureBlock := texture_block{DefaultImage := T_Score_Screen_Star_Grey, DefaultDesiredSize := vector2{ X := 70.0, Y := 70.0}}
            set StarTextureBlocks = StarTextureBlocks + array{TextureBlock}
            stack_box_slot{ Widget := TextureBlock, Padding := margin{Left := 5.0, Right := 5.0}}
        overlay:
            Slots := array:
                overlay_slot: <# Overlay Image #>
                    Widget := texture_block{DefaultImage := T_Score_Screen_Overlay, DefaultDesiredSize := vector2{ X := 512.0, Y := 512.0}}
                overlay_slot: <# Main Thing #>
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Top := 50.0}
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := array:
                            stack_box_slot: <# Star images #>
                                VerticalAlignment := vertical_alignment.Top
                                Padding := margin{Bottom := 75.0}
                                Widget := stack_box:
                                    Orientation := orientation.Horizontal
                                    Slots := StarStackBoxSlots
                            stack_box_slot: <# Score #>
                                VerticalAlignment := vertical_alignment.Top
                                Padding := margin{Bottom := 83.0}
                                Widget := ScoreTextBlock
                            stack_box_slot: <# Cash Gained #>
                                VerticalAlignment := vertical_alignment.Top
                                Padding := margin{Bottom := 50.0}
                                Widget := CashTextBlock

                            stack_box_slot: <# Candy Gained #>
                                VerticalAlignment := vertical_alignment.Top
                                Padding := margin{Bottom := 20.0}
                                Widget := CandyTextBlock
                            stack_box_slot: <# Claim Button #>
                                VerticalAlignment := vertical_alignment.Bottom
                                Padding := margin{Bottom := -100.0}
                                Widget := overlay:
                                    Slots := array:
                                        overlay_slot:
                                            Widget := texture_block{DefaultImage := T_Score_Screen_Claim_Button, DefaultDesiredSize := vector2{ X := 512.0, Y := 128.0}}
                                        overlay_slot:
                                            Widget := ClaimButton
                                            HorizontalAlignment := horizontal_alignment.Fill
                                            VerticalAlignment := vertical_alignment.Fill
                                            Padding := margin{Left := 100.0, Top := 30.0, Right := 100.0, Bottom := 30.0}
          
    Show<public>() : void = RootWidget.SetVisibility(widget_visibility.Visible)
    Hide<public>() : void = RootWidget.SetVisibility(widget_visibility.Hidden)

    GetRootWidget<public>() : widget = RootWidget

    Reset<public>() : void =
        ResetEvent.Signal()