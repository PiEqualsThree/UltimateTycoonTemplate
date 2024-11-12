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
using { UIStuff.PumpkinCarvingUI}
pumpkin_carving_score_widget<public> := class:
    ResetEvent : event() = event(){}

    var RootWidget : widget = overlay{}
    var StarTextureBlocks : []texture_block = array{}
    var ScoreTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFFFFFFF")}
    var CashTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFFFFFFF")}
    var CandyTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFFFFFFF")}
    var ClaimButton : text_button_base = button_quiet{}

    UniqueBegin<public>() : void =
        set RootWidget = CreateUI()

    Display<public>(Owner : custom_player, Result : pumpkin_carving_score_result)<suspends> : void =
        race:
            Sleep(10.0)
            ResetEvent.Await()
            ClaimButton.OnClick().Await()
            Owner.FortCharacter.EliminatedEvent().Await()
            AnimateScore(Result)

    AnimateScore(Result : pumpkin_carving_score_result)<suspends> : void =
        Stars := Floor(Result.Score / 5) or 1
        for ( Index->StarTextureBlock : StarTextureBlocks) do StarTextureBlock.SetImage(T_Score_Screen_Star_Grey)
        <# Animate 20s #>
        for ( I := 0..Stars-1, StarTextureBlock := StarTextureBlocks[I]):
            for ( J := 1..20):
                ScoreTextBlock.SetText(StringToMessage("{I * 20 + J}%"))
                Sleep(0.0)
            StarTextureBlock.SetImage(T_Score_Screen_Star_Gold)
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

        CashTextBlock.SetText(StringToMessage("{FormatNumber(Result.CashGain)}"))
        CandyTextBlock.SetText(StringToMessage("{FormatNumber(Result.CandyGain)}"))

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
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := array:
                            stack_box_slot: <# Star images #>
                                Widget := stack_box:
                                    Orientation := orientation.Horizontal
                                    Slots := StarStackBoxSlots
                            stack_box_slot:
                                Widget := ScoreTextBlock
                            stack_box_slot:
                                Widget := CashTextBlock
                            stack_box_slot:
                                Widget := CandyTextBlock
                            stack_box_slot:
                                Widget := overlay:
                                    Slots := array:
                                        overlay_slot:
                                            Widget := texture_block{DefaultImage := T_Score_Screen_Claim_Button, DefaultDesiredSize := vector2{ X := 512.0, Y := 128.0}}
                                        overlay_slot:
                                            Widget := ClaimButton
                                            HorizontalAlignment := horizontal_alignment.Fill
                                            VerticalAlignment := vertical_alignment.Fill
                                            Padding := margin{Left := 100.0, Top := 30.0, Right := 100.0, Bottom := 30.0}
        
    GetCanvasSlot() : canvas_slot = 
        canvas_slot:
            Widget := RootWidget
            Anchors := anchors{Minimum := vector2{ X := 1.0, Y := 0.5}, Maximum := vector2{ X := 1.0, Y := 0.5}}
            Alignment := vector2{ X := 1.0, Y := 0.5}
            Offsets := margin{Left := -200.0}

    Reset() : void =
        ResetEvent.Signal()