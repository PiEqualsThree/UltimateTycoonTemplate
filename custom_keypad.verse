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

custom_keypad<public> := class:
    var Password<public> : string
    KeypadWidget : keypad_widget = keypad_widget{}
    KeypadResetEvent : event() = event(){}
    SuccessEvent : event() = event(){}
    FailedEvent : event() = event(){}
    ExitEvent : event() = event(){}

    var CurrentCode : string = ""
    var IncorrectCodeAudio : audio_player_device = audio_player_device{}
    var CorrectCodeAudio : audio_player_device = audio_player_device{}

    UniqueBegin(?KeypadImage : texture = KeypadUI.KeypadGold, ?TextColor : color = MakeColorFromHex("865500FF")) : void =
        KeypadWidget.UniqueBegin(?KeypadTexture := KeypadImage, ?TextColor := TextColor)

    Init(InSuccessAudio : audio_player_device, InFailAudio : audio_player_device) : void =
        set CorrectCodeAudio = InSuccessAudio
        set IncorrectCodeAudio = InFailAudio
        KeypadWidget.SetText("")

    Reset<public>() : void =
        ResetEvent().Signal()
        KeypadWidget.Reset()
        set CurrentCode = ""

    SetPassword<public>(InPassword : string) : void = set Password = InPassword

    Display(CustomPlayer : custom_player) : void =
        set CurrentCode = ""
        KeypadWidget.SetText(CurrentCode)
        if ( PlayerUI := GetPlayerUI[CustomPlayer.Player]):
            PlayerUI.AddWidget(KeypadWidget.Canvas, player_ui_slot{InputMode := ui_input_mode.All})
            spawn{ AwaitInput(CustomPlayer) }

    Remove<public>(CustomPlayer : custom_player) : void =
        if ( PlayerUI := GetPlayerUI[CustomPlayer.Player]):
            PlayerUI.RemoveWidget(KeypadWidget.Canvas)

    AwaitInput(CustomPlayer : custom_player)<suspends> : void =
        race:
            ResetEvent().Await()
            CustomPlayer.FortCharacter.EliminatedEvent().Await()
            block:
                KeypadWidget.ExitButtonClickedEvent.Await()
                ExitEvent.Signal()
            loop:
                KeyPressed := KeypadWidget.NumberButtonClickedEvent.Await()
                if ( CurrentCode.Length < Password.Length):
                    set CurrentCode += "{KeyPressed}"
                    KeypadWidget.SetText(CurrentCode)
            loop:
                KeypadWidget.ClearButtonClickedEvent.Await()
                if (CurrentCode.Length > 0):
                    set CurrentCode = for ( I := 0..CurrentCode.Length - 2, Char := CurrentCode[I]) do Char
                    KeypadWidget.SetText(CurrentCode)
            loop:
                KeypadWidget.ConfirmButtonClickedEvent.Await()
                if ( CurrentCode = Password):
                    CorrectCodeAudio.Play(CustomPlayer.Player)
                    SuccessEvent.Signal()
                    break
                else:
                    IncorrectCodeAudio.Play(CustomPlayer.Player)
                    FailedEvent.Signal()
            
    ResetEvent<public>() : event() = KeypadResetEvent
    GetWidget<public>()<transacts> : keypad_widget = KeypadWidget
    
keypad_widget<public> := class:
    Canvas : canvas = canvas{}
    WidgetResetEvent : event() = event(){}
    NumberButtonClickedEvent : event(int) = event(int){}
    ClearButtonClickedEvent : event() = event(){}
    ConfirmButtonClickedEvent : event() = event(){}
    ExitButtonClickedEvent : event() = event(){}

    ClearButton : button_quiet = button_quiet{}
    ConfirmButton : button_quiet = button_quiet{}
    ExitButton : button_quiet = button_quiet{}
    CurrentCodeText : text_block = text_block{DefaultTextColor := MakeColorFromHex("865602FF")}

    var NumberButtons : []button_quiet = array{}
    var RootWidget : widget = overlay{}

    UniqueBegin<public>(?KeypadTexture : texture = KeypadUI.KeypadGold, ?TextColor : color = NamedColors.White) : void = 
        set NumberButtons = for ( I := 0..9) do button_quiet{}
        CurrentCodeText.SetTextColor(TextColor)
        R1Buttons := for ( I := 1..3, Button := NumberButtons[I]) do Button
        R2Buttons := for ( I := 4..6, Button := NumberButtons[I]) do Button
        R3Buttons := for ( I := 7..9, Button := NumberButtons[I]) do Button
        R4Buttons := if ( Zero := NumberButtons[0]) then array{Zero, ClearButton, ConfirmButton} else array{}
        for ( Index->Button : NumberButtons) do spawn { Button.AwaitClick(Index)}
        ClearButton.OnClick().Subscribe(OnClearButtonPress)
        ConfirmButton.OnClick().Subscribe(OnConfirmButtonPress)
        ExitButton.OnClick().Subscribe(OnExitButtonPress)
        set RootWidget = overlay:
            Slots := array:
                overlay_slot: <# Keypad image #>
                    Widget := texture_block{DefaultDesiredSize := vector2{ X := 512.0, Y := 1024.0}, DefaultImage := KeypadUI.KeypadGold}
                overlay_slot: <# Button Rows #>
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{ Left := 27.0, Top := 225.0}
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := array:
                            CreateButtonRowStackBoxSlot(R1Buttons)
                            CreateButtonRowStackBoxSlot(R2Buttons)
                            CreateButtonRowStackBoxSlot(R3Buttons)
                            CreateButtonRowStackBoxSlot(R4Buttons)
                overlay_slot: <# Exit Button #>
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Bottom
                    Padding := margin{ Bottom := 25.0 }
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := color_block{DefaultDesiredSize := vector2{X := 512.0, Y := 128.0}, DefaultOpacity := 0.0}
                            overlay_slot:
                                Widget := ExitButton
                                HorizontalAlignment := horizontal_alignment.Fill
                                VerticalAlignment := vertical_alignment.Fill
                overlay_slot: <# Code text block #>
                    Widget := CurrentCodeText
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{ Top := 105.0}
                    
        Canvas.AddWidget(
            canvas_slot:
                Widget := RootWidget
                Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{ X := 0.5, Y := 0.5}}
                Alignment := vector2{ X := 0.5, Y := 0.5}
                SizeToContent := true
        )

    Reset<public>() : void =
        ResetEvent().Signal()
        SetText("")

    SetText<public>(Text : string) : void = CurrentCodeText.SetText(StringToMessage(Text))

    OnClearButtonPress(Message : widget_message) : void = ClearButtonClickedEvent.Signal()
    OnConfirmButtonPress(Message : widget_message) : void = ConfirmButtonClickedEvent.Signal()
    OnExitButtonPress(Message : widget_message) : void = ExitButtonClickedEvent.Signal()
    (NumberButton : button_quiet).AwaitClick(Number : int)<suspends> : void =
        loop:
            NumberButton.OnClick().Await()
            NumberButtonClickedEvent.Signal(Number)

    CreateButtonRowStackBoxSlot(Buttons : []button_quiet) : stack_box_slot =
        Slots := for ( Button : Buttons):
            stack_box_slot:
                HorizontalAlignment := horizontal_alignment.Left
                VerticalAlignment := vertical_alignment.Top
                Padding := margin{Right := 35.0}
                Widget := overlay:
                    Slots := array:
                        overlay_slot:
                            Widget := color_block{DefaultDesiredSize := vector2{ X := 128.0, Y := 128.0}, DefaultOpacity := 0.0}
                        overlay_slot:
                            Widget := Button
                            HorizontalAlignment := horizontal_alignment.Fill
                            VerticalAlignment := vertical_alignment.Fill
        return stack_box_slot:
            HorizontalAlignment := horizontal_alignment.Left
            VerticalAlignment := vertical_alignment.Top
            Padding := margin{ Bottom := 30.0}
            Widget := stack_box:
                Orientation := orientation.Horizontal
                Slots := Slots
                
    ResetEvent<public>() : event() = WidgetResetEvent
    GetCanvas<public>()<transacts> : canvas = Canvas
