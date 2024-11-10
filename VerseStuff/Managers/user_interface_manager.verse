using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { TycoonInterfaces }

using { UIStuff }
using { UIStuff.CurrencyUI }
using { UIStuff.CosmeticsUI }

user_interface_manager<public> := class<concrete>:


    Init<public>(PlayerManager : player_manager) : void =
        spawn{ Update(PlayerManager)}

    Update(PlayerManager : player_manager)<suspends> : void =
        {}

    UpdateCurrencyUI(CustomPlayer : custom_player, CurrencyType : currency_type) : void =
        case(CurrencyType):
            currency_type.Cash => CustomPlayer.CurrencyWidgets.CashTextBlock.SetText(StringToMessage("${FormatNumber(CustomPlayer.Cash)}"))
            currency_type.Candy => CustomPlayer.CurrencyWidgets.SubscribersTextBlock.SetText(StringToMessage(FormatNumber(CustomPlayer.Candy)))
            currency_type.BlingBucks => CustomPlayer.CurrencyWidgets.BlingBucksTextBlock.SetText(StringToMessage(FormatNumber(CustomPlayer.BlingBucks)))

    DisplayIncomeGain<public>(CustomPlayer : custom_player, CurrencyTransaction : currency_transaction, ?AdditionalText : string = "", ?TextColor : color = NamedColors.White) : void =
        CustomPlayer.GetIncomeStreamWidgets().AddIncomeStream(CurrencyTransaction, ?AdditionalText := AdditionalText, ?TextColor := TextColor)

player_currency_widgets<public> := class(resetable):
    WidgetResetEvent : event() = event(){}

    CashTextBlock : text_block = text_block{DefaultTextColor := NamedColors.White}
    SubscribersTextBlock : text_block = text_block{DefaultTextColor := NamedColors.White}
    BlingBucksTextBlock : text_block = text_block{DefaultTextColor := NamedColors.Gold}
    RebirthsTextBlock : text_block = text_block{DefaultTextColor := NamedColors.White}

    CurrencyMultiplierTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFEE00FF")}
    CurrencyMultiplierTextureBlock : texture_block = texture_block{DefaultImage := CurrencyUI.CurrencyMultiplier, DefaultDesiredSize := vector2{ X := 256.0, Y := 64.0}}
    

    var RootWidget : widget = overlay{}

    UniqueBegin<public>() : void =
        set RootWidget = stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                stack_box_slot: <# Cash UI #>
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Bottom := 10.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := texture_block{DefaultImage := CurrencyUI.T_Currency_Cash, DefaultDesiredSize := vector2{X := 256.0, Y := 64.0}}
                            overlay_slot:
                                Widget := CashTextBlock
                                HorizontalAlignment := horizontal_alignment.Left
                                VerticalAlignment := vertical_alignment.Center
                                Padding := margin{ Left := 75.0}
                stack_box_slot: <# Candy UI #>
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Bottom := 10.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := texture_block{DefaultImage := CurrencyUI.T_Currency_Candy, DefaultDesiredSize := vector2{X := 256.0, Y := 64.0}}
                            overlay_slot:
                                Widget := SubscribersTextBlock
                                HorizontalAlignment := horizontal_alignment.Left
                                VerticalAlignment := vertical_alignment.Center
                                Padding := margin{ Left := 75.0}    

                stack_box_slot: <# Bling Bucks UI #>
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Bottom := 10.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := texture_block{DefaultImage := CurrencyUI.BlingBucks, DefaultDesiredSize := vector2{X := 256.0, Y := 64.0}}
                            overlay_slot:
                                Widget := BlingBucksTextBlock
                                HorizontalAlignment := horizontal_alignment.Left
                                VerticalAlignment := vertical_alignment.Center
                                Padding := margin{ Left := 75.0}
                stack_box_slot: <# Rebirth UI #>
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Bottom := 10.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := texture_block{DefaultImage := CurrencyUI.T_Currency_Overlay_Rebirths, DefaultDesiredSize := vector2{X := 256.0, Y := 64.0}}
                            overlay_slot:
                                Widget := RebirthsTextBlock
                                HorizontalAlignment := horizontal_alignment.Left
                                VerticalAlignment := vertical_alignment.Center
                                Padding := margin{ Left := 75.0}
                stack_box_slot: <# Multiplier UI #>
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Bottom := 10.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := CurrencyMultiplierTextureBlock
                            overlay_slot:
                                Widget := CurrencyMultiplierTextBlock

    Init<public>(Owner : custom_player, PlayerStats : player_stats) : void =
        CashTextBlock.SetText(StringToMessage("${FormatNumber(Owner.Cash)}"))
        SubscribersTextBlock.SetText(StringToMessage("{FormatNumber(Owner.Candy)}"))
        BlingBucksTextBlock.SetText(StringToMessage("{FormatNumber(Owner.BlingBucks)}"))
        RebirthsTextBlock.SetText(StringToMessage("{Owner.Rebirths}"))
        if ( Owner.Rebirths > 0):
            Boost := Min(Owner.Rebirths * 20, 300)
            CurrencyMultiplierTextBlock.SetText(StringToMessage("+{Boost}%"))
            CurrencyMultiplierTextBlock.SetVisibility(widget_visibility.Visible)
            CurrencyMultiplierTextureBlock.SetVisibility(widget_visibility.Visible)
            
        else:
            CurrencyMultiplierTextBlock.SetText(StringToMessage("+0%"))
            CurrencyMultiplierTextBlock.SetVisibility(widget_visibility.Hidden)
            CurrencyMultiplierTextureBlock.SetVisibility(widget_visibility.Hidden)
            

    Reset<override>() : void =
        CashTextBlock.SetText(StringToMessage("$0"))
        SubscribersTextBlock.SetText(StringToMessage("0"))
        BlingBucksTextBlock.SetText(StringToMessage("0"))
        RebirthsTextBlock.SetText(StringToMessage("0"))

    GetRootWidget<public>()<transacts> : widget = RootWidget
    ResetEvent<override>() : event() = WidgetResetEvent

player_income_stream_widgets<public> := class:
    IncomeStreamAddedEvent : event(currency_transaction) = event(currency_transaction){}

    TotalIncomeTextureBlock : texture_block = texture_block{DefaultImage := T_Place_Holder, DefaultDesiredSize := vector2{ X := 45.0, Y := 45.0}}
    TotalIncomeTextBlock : text_block = text_block{DefaultTextColor := NamedColors.White, DefaultShadowOffset := option{vector2{ X := 3.0, Y := 3.0}}, DefaultShadowOpacity := 1.0}
    TotalIncomeColorBlock : color_block = color_block{DefaultColor := color{}}
    var TotalIncomeOverlay : overlay = overlay{}

    var CurrentCurrencyTransaction : ?currency_transaction = false
    var IncomeWidgets : []custom_income_widget = array{}
    var RootWidget : widget = overlay{}
    
    UniqueBegin<public>(Owner : custom_player) : void =
        set TotalIncomeOverlay = overlay:
            Slots := array:
                overlay_slot:
                    Widget := TotalIncomeColorBlock
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                overlay_slot:
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Left := 10.0, Top := 5.0, Right := 10.0, Bottom := 5.0}
                    Widget := stack_box:
                        Orientation := orientation.Horizontal
                        Slots := array:
                            stack_box_slot:
                                Widget := TotalIncomeTextureBlock
                            stack_box_slot:
                                Widget := TotalIncomeTextBlock

        set RootWidget = overlay:
            Slots := array:
                overlay_slot:
                    Widget := color_block{DefaultDesiredSize := vector2{ X := 400.0, Y := 400.0}, DefaultOpacity := 0.0}
                overlay_slot:
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Bottom
                    Padding := margin{Bottom := 150.0}
                    Widget := TotalIncomeOverlay                     
        Owner.GetCanvas().AddWidget(
            canvas_slot:
                Widget := RootWidget
                Anchors := anchors{Minimum := vector2{ X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
                Alignment := vector2{ X := 0.5, Y := 1.0}
                Offsets := margin{Top := 250.0, Left := 300.0}
                ZOrder := 10
        )
        TotalIncomeOverlay.SetVisibility(widget_visibility.Hidden)

    CreateIncomeWidget<public>() : custom_income_widget =
        NewWidget := custom_income_widget{}
        NewWidget.Init()
        return NewWidget
        
    AddIncomeWidget<public>(IncomeWidget : custom_income_widget) : void =
        set IncomeWidgets = IncomeWidgets + array{IncomeWidget}
        if ( Overlay := overlay[RootWidget]):
            Overlay.AddWidget(
                overlay_slot:
                    Widget := IncomeWidget.GetRootWidget()
                    Padding := margin{Top := 25.0}
                    VerticalAlignment := vertical_alignment.Top
                    HorizontalAlignment := horizontal_alignment.Left
            )
            IncomeWidget.RootWidget.SetVisibility(widget_visibility.Hidden)
            Print("Created new income widget: Total {IncomeWidgets.Length}")

    GetAvailableIncomeWidget<public>()<transacts><decides> : custom_income_widget =
        var AvailableIncomeWidget : ?custom_income_widget = false
        var IsWidgetFound : logic = false
        for ( Widget : IncomeWidgets, not IsWidgetFound?):
            if ( not Widget.IsMoving?):
                set AvailableIncomeWidget = option{Widget}
                set IsWidgetFound = true
        AvailableIncomeWidget?

    AddIncomeStream<public>(CurrencyTransaction : currency_transaction, ?AdditionalText : string, ?TextColor : color = NamedColors.White) : void =
        var IncomeWidget : ?custom_income_widget = false
        if ( Transaction := CurrentCurrencyTransaction?):
            <# Add to stream #>
            set CurrentCurrencyTransaction = option{CurrencyTransaction}
            IncomeStreamAddedEvent.Signal(CurrencyTransaction)
        else:
            <# Begin the Stream #>
            set CurrentCurrencyTransaction = option{CurrencyTransaction}
            spawn{UpdateIncomeStream(CurrencyTransaction)}
           
        if ( Widget := GetAvailableIncomeWidget[]):
            set IncomeWidget = option{Widget}
        else:
            NewWidget := CreateIncomeWidget()
            AddIncomeWidget(NewWidget)
            set IncomeWidget = option{NewWidget}

        if ( Widget := IncomeWidget?):
            Widget.TextBlock.SetTextColor(TextColor)
            Widget.SetWidgetText("+ {FormatNumber(CurrencyTransaction.Amount)}{AdditionalText}")
            case(CurrencyTransaction.Type):
                currency_type.Cash => Widget.SetWidgetImage(T_Icon_Cash)
                currency_type.Candy => Widget.SetWidgetImage(T_Icon_Candy)
                _ => 0
            spawn{Widget.Move(100.0, vector2{ X := 45.0, Y := 45.0}, CurrencyTransaction.Amount)}

    UpdateIncomeStream(StartingCurrencyTransaction : currency_transaction)<suspends> : void =
        <# First time #>
        var CurrentTotal : int = 0 
        var CurrentCurrencyType : currency_type = StartingCurrencyTransaction.Type
        var NewTotal : int = StartingCurrencyTransaction.Amount

        TotalIncomeTextBlock.SetTextOpacity(1.0)
        TotalIncomeTextBlock.SetShadowOpacity(1.0)
        TotalIncomeColorBlock.SetOpacity(0.6)
        TotalIncomeOverlay.SetVisibility(widget_visibility.Visible)
        case(CurrentCurrencyType):
            currency_type.Cash => TotalIncomeTextureBlock.SetImage(T_Icon_Cash)
            currency_type.Candy => TotalIncomeTextureBlock.SetImage(T_Icon_Candy)
            _ => Print("Unkown income type!")
        UpdateCurrencyTotal(0, NewTotal)
        loop:
            race:
                block:
                    Transaction := IncomeStreamAddedEvent.Await()
                    TotalIncomeTextBlock.SetTextOpacity(1.0)
                    TotalIncomeTextBlock.SetShadowOpacity(1.0)
                    TotalIncomeColorBlock.SetOpacity(0.6)
                    TotalIncomeOverlay.SetVisibility(widget_visibility.Visible)
                    if ( Transaction.Type = CurrentCurrencyType):
                        set CurrentTotal = NewTotal
                        set NewTotal = CurrentTotal + Transaction.Amount
                    else:
                        set CurrentTotal = 0
                        set NewTotal = Transaction.Amount
                        set CurrentCurrencyType = Transaction.Type
                        case(CurrentCurrencyType):
                            currency_type.Cash => TotalIncomeTextureBlock.SetImage(T_Icon_Cash)
                            currency_type.Candy => TotalIncomeTextureBlock.SetImage(T_Icon_Candy)
                            _ => Print("Unkown income stream!")
                block:
                    Sleep(2.0)
                    FadeOutTotalWidget()
                    set CurrentCurrencyTransaction = false
                    TotalIncomeOverlay.SetVisibility(widget_visibility.Hidden)
                    return
            spawn{UpdateCurrencyTotal(CurrentTotal, NewTotal)}         
        
    UpdateCurrencyTotal(Start : int, Target : int)<suspends> : void =
        Intervals : int = 7
        IntervalsF : float = 1.0 * Intervals
        TotalIncomeTextBlock.SetText(StringToMessage("+ {FormatNumber(Start)}"))
        race:
            IncomeStreamAddedEvent.Await()
            for ( I := 1..Intervals):
                Alpha := (1.0 * I) / IntervalsF
                Amount := Clamp(Ceil[Lerp(1.0 * Start, 1.0 * Target, Alpha)] or Target, Start, Target)
                TotalIncomeTextBlock.SetText(StringToMessage("+ {FormatNumber(Amount)}"))
                Sleep(0.0)

    FadeOutTotalWidget()<suspends> : void =
        Intervals := 40
        IntervalsF := 1.0 * Intervals
        race:
            IncomeStreamAddedEvent.Await()
            for ( I := 1..Intervals):
                Alpha := (1.0 * I) / IntervalsF
                ColorOpacity := clamped_float[Lerp(0.6, 0.0, Alpha)] or 0.0
                TotalIncomeTextBlock.SetTextOpacity(clamped_float[1.0 - Alpha] or 0.0)
                TotalIncomeTextBlock.SetShadowOpacity(clamped_float[1.0 - Alpha] or 0.0)
                TotalIncomeColorBlock.SetOpacity(ColorOpacity)
                Sleep(0.0)





    

