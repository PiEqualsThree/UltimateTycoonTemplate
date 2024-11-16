using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { VerseStuff.TycoonInterfaces}
using { VerseStuff.Managers}
using { TycoonAnimations }
time_gift_box := class<concrete>(resetable):
    @editable       GiftBoxContainer : creative_prop = creative_prop{}
    @editable       BaseContainer : creative_prop = creative_prop{}
    @editable       Button : button_device = button_device{}
    @editable       ClaimAudio : audio_player_device = audio_player_device{}
    @editable       GiftReadyHudDevice : hud_message_device = hud_message_device{}
    @editable       Gifts : []tycoon_gift = array{}
    

    UI : gift_ui = gift_ui{}
    CurrencyGenerationEvent : event(currency_transaction) = event(currency_transaction){}
    TimeGiftBoxResetEvent : event() = event(){}
    var TimedGiftsMap : [int]tycoon_gift = map{}
    var GiftsReadyToClaim : int = 0

    var DefaultGiftBoxContainerTransform : transform = transform{}
    var DefaultBaseContainerTransform : transform = transform{}
    var AnimationKeyframes : []keyframe_delta = array{}

    UniqueBegin<public>() : void =
        set DefaultGiftBoxContainerTransform = GiftBoxContainer.GetTransform()
        set DefaultBaseContainerTransform = BaseContainer.GetTransform()
        set AnimationKeyframes = CreateKeyframes()
        UI.UniqueBegin(Gifts)
        Button.SetInteractionText(StringToMessage("Free Gifts!"))
        if:
            GiftBoxContainer.TeleportTo[DefaultGiftBoxContainerTransform.Translation - vector3{Z := 3000.0}, DefaultGiftBoxContainerTransform.Rotation]
            BaseContainer.TeleportTo[DefaultBaseContainerTransform.Translation - vector3{Z := 3000.0}, DefaultBaseContainerTransform.Rotation]

    Init(Owner : custom_player) : void =
        for ( Index->Gift : Gifts, set TimedGiftsMap[Index] = Gift) do Gift.Init() 
        for ( Index->Gift : TimedGiftsMap) { spawn{ Gift.AwaitReadyEvent(Owner, Index)}}
        UI.Init(Gifts)
        Button.Enable()
        spawn { DoTycoonPopupAnimation(GiftBoxContainer, DefaultGiftBoxContainerTransform, ?PlayAnimations := true)}
        spawn { DoTycoonPopupAnimation(BaseContainer, DefaultBaseContainerTransform, ?PlayAnimations := true)}
        spawn{ Update(Owner) }

    Reset<override>() : void =
        set GiftsReadyToClaim = 0
        set TimedGiftsMap = map{}
        Button.Disable()
        UI.Reset()
        if:
            GiftBoxContainer.TeleportTo[DefaultGiftBoxContainerTransform.Translation - vector3{Z := 3000.0}, DefaultGiftBoxContainerTransform.Rotation]
            BaseContainer.TeleportTo[DefaultBaseContainerTransform.Translation - vector3{Z := 3000.0}, DefaultBaseContainerTransform.Rotation]
        ResetEvent().Signal()
    
    Update(Owner : custom_player)<suspends> : void =
        var IsDisplayActive : logic = false
        race:
            ResetEvent().Await()
            UpdateAnimation()
            loop: <# Await Button interaction #>
                Agent := Button.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    set IsDisplayActive = true
                    UI.Display(Owner)
                    set IsDisplayActive = false

            loop: <# Await Gift Click event #>
                GiftIndex := UI.GiftButtonClickedEvent.Await()
                if ( Gift := Gifts[GiftIndex]):
                    case(Gift.GetCurrentClaimStatus()):
                        tycoon_gift_claim_status.Locked => Print("Gift {GiftIndex} is not ready yet!")
                        tycoon_gift_claim_status.Ready => ClaimGift(Owner, Gift, GiftIndex)
                        tycoon_gift_claim_status.Claimed => Print("Gift {GiftIndex} already claimed!")

            loop: <# Tick gift time #>
                Sleep(1.0)
                for ( Index->Gift : TimedGiftsMap) { Gift.Tick() }
                if ( IsDisplayActive? ) { UI.RefreshTimers(TimedGiftsMap) }   

        GiftReadyHudDevice.Hide(Owner.Player)

    ClaimGift(Owner : custom_player, Gift : tycoon_gift, GiftIndex : int) : void =     
        if ( CurrencyManager := Owner.MaybeTycoonManager?.CurrencyManager, UIManager := Owner.MaybeTycoonManager?.UIManager):
            RemoveGiftFromTimedGiftsMap(Gift)
            set GiftsReadyToClaim = GiftsReadyToClaim - 1
            UI.SetGiftAsClaimed(GiftIndex)
            UI.Remove(Owner)
            Gift.Claim()
            CashGain := CurrencyManager.GetCustomPlayerCurrencyGain(Owner, Gift.GetCashReward() )
            CandyGain := CurrencyManager.GetCustomPlayerCurrencyGain(Owner, Gift.GetCandyReward())
            CashTransaction := currency_transaction{Type := currency_type.Cash, Amount := CashGain}
            CandyTransaction := currency_transaction{Type := currency_type.Candy, Amount := CandyGain}
            CurrencyManager.IncreaseCurrency(Owner, CashTransaction)
            CurrencyManager.IncreaseCurrency(Owner, CandyTransaction)
            ClaimAudio.Play(Owner.Player)
            spawn{ DisplayCurrencyGain(Owner, UIManager, array{CashTransaction, CandyTransaction})}
            if ( GiftsReadyToClaim = 0) then GiftReadyHudDevice.Hide(Owner.Player)
            else: 
                GiftReadyHudDevice.SetText(StringToMessage("{GiftsReadyToClaim}"))
                GiftReadyHudDevice.Show(Owner.Player)

    DisplayCurrencyGain(Owner : custom_player, UIManager : user_interface_manager, Transactions : []currency_transaction)<suspends> : void =
        Sleep(0.25)
        for ( Index->Transaction : Transactions):
            UIManager.DisplayIncomeGain(Owner, Transaction, ?AdditionalText := " (Free Reward!)", ?TextColor := MakeColorFromHex("FDFF00FF"))
            Sleep(1.0)

    (Gift : tycoon_gift).AwaitReadyEvent(Owner : custom_player, GiftIndex : int)<suspends> : void =
        race:
            ResetEvent().Await()
            block:
                Gift.ReadyEvent.Await()
                set GiftsReadyToClaim += 1
                RemoveGiftFromTimedGiftsMap(Gift)
                GiftReadyHudDevice.SetText(StringToMessage("{GiftsReadyToClaim}"))
                GiftReadyHudDevice.Show(Owner.Player)
                UI.SetGiftAsClaimable(GiftIndex)
                        
    RemoveGiftFromTimedGiftsMap(GiftToRemove : tycoon_gift) : void =
        var NewMap : [int]tycoon_gift = map{}
        for:
            Index->TimedGift : TimedGiftsMap
            TimedGift <> GiftToRemove
            set NewMap[Index] = TimedGift
        do {}
        set TimedGiftsMap = NewMap

    CreateKeyframes() : []keyframe_delta =
        array:
            keyframe_delta { DeltaLocation := vector3{Z :=  15.0}, DeltaRotation := rotation{}, DeltaScale := vector3{X := 1.0, Y := 1.0, Z := 1.25}, Time := 0.15 }
            keyframe_delta { DeltaLocation := vector3{Z :=  15.0}, DeltaRotation := rotation{}, DeltaScale := vector3{X := 1.0, Y := 1.0, Z := 0.80}, Time := 0.15 }
            keyframe_delta { DeltaLocation := vector3{Z := -30.0}, DeltaRotation := rotation{}, DeltaScale := vector3{X := 1.0, Y := 1.0, Z := 1.00}, Time := 0.3 }
            keyframe_delta { DeltaLocation := vector3{          }, DeltaRotation := rotation{}, DeltaScale := vector3{X := 1.0, Y := 1.0, Z := 1.00}, Time := 1.0 }

    UpdateAnimation()<suspends> : void =
        Sleep(1.5)
        defer{ if ( AC := GiftBoxContainer.GetAnimationController[]) then AC.Stop()}
        if ( AC := GiftBoxContainer.GetAnimationController[]):
            AC.SetAnimation(AnimationKeyframes, ?Mode := animation_mode.Loop)
            AC.Play()
        Sleep(Inf)

    ResetEvent<override>() : event() = TimeGiftBoxResetEvent

using { UIStuff}
gift_ui := class:
    ExitButton : button_quiet = button_quiet{}
    GiftButtonClickedEvent : event(int) = event(int){}
    ResetEvent : event() = event(){}
    Canvas : canvas = canvas{}

    var RootWidget : widget = text_block{}
    var Buttons : []text_button_base = array{}
    
    UniqueBegin(Gifts : []tycoon_gift) : void =
        set Buttons = for ( Index->Gift : Gifts) { button_quiet { DefaultText := StringToMessage(FormatSecondsToHours(Gift.GetSeconds()))}}
        Row1 : stack_box_slot = CreateRow(for ( I := 0..2, Button := Buttons[I]) { Button }, margin{Bottom := 190.0})
        Row2 : stack_box_slot = CreateRow(for ( I := 3..5, Button := Buttons[I]) { Button }, margin{Bottom := 190.0})
        Row3 : stack_box_slot = CreateRow(for ( I := 6..8, Button := Buttons[I]) { Button }, margin{Bottom := 000.0})
        
        set RootWidget = overlay:
            Slots := array:
                overlay_slot: <# Gift UI Image #>
                    Widget := texture_block{DefaultImage := GiftUI.T_Free_Gifts, DefaultDesiredSize := vector2{ X := 1024.0, Y := 1024.0}}
                overlay_slot: <# Gift Claim buttons #>
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{ Left := 15.0, Top := 400.0}
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := array:
                            Row1
                            Row2
                            Row3

                overlay_slot: <# Exit Button #>
                    HorizontalAlignment := horizontal_alignment.Right
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Top := 45.0, Right := 100.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                HorizontalAlignment := horizontal_alignment.Center
                                VerticalAlignment := vertical_alignment.Center
                                Widget := texture_block{DefaultImage := GiftUI.T_Exit_Button, DefaultDesiredSize := vector2{X := 150.0, Y := 150.0}}
                            overlay_slot:
                                HorizontalAlignment := horizontal_alignment.Fill
                                VerticalAlignment := vertical_alignment.Fill
                                Widget := ExitButton

        Canvas.AddWidget(
            canvas_slot:
                Widget := RootWidget
                Anchors := anchors{ Minimum := vector2{ X := 0.5, Y := 0.5}, Maximum := vector2{ X := 0.5, Y := 0.5}}
                Alignment := vector2{ X := 0.5, Y := 0.5}
        )

    Init(Gifts : []tycoon_gift) : void =
        Print("Init time gift box!")
        for ( Index->Gift : Gifts, Button := Buttons[Index]):
            Button.SetText(StringToMessage(FormatSecondsToHours(Gift.GetSeconds())))
            spawn{ Button.AwaitClickEvent(Index) }

    Reset() : void =
        ResetEvent.Signal()
        for ( Button : Buttons) do Button.SetText(StringToMessage(""))

    Display(Owner : custom_player) : void =
        if ( PlayerUI := GetPlayerUI[Owner.Player]):
            PlayerUI.AddWidget(Canvas, player_ui_slot{InputMode := ui_input_mode.All})
            RootWidget.SetVisibility(widget_visibility.Visible)
            # race:
            #     ExitButton.OnClick().Await()
            #     GiftButtonClickedEvent.Await()
            

    Remove(Owner : custom_player) : void =
        if ( PlayerUI := GetPlayerUI[Owner.Player]):
            PlayerUI.RemoveWidget(Canvas)
            RootWidget.SetVisibility(widget_visibility.Hidden)

    RefreshTimers(Gifts : [int]tycoon_gift) : void =
        for ( ID->Gift : Gifts, Button := Buttons[ID]):
            Button.SetText(StringToMessage(FormatSecondsToHours(Gift.GetSeconds())))

    SetGiftAsClaimable(GiftIndex : int) : void = 
        if ( Button := Buttons[GiftIndex]):
            Button.SetText(StringToMessage("Claim!"))

    SetGiftAsClaimed(GiftIndex : int) : void =
        if ( Button := Buttons[GiftIndex]):
            Button.SetText(StringToMessage("✔"))

    (GiftButton : text_button_base).AwaitClickEvent(Index : int)<suspends> : void =
        race:
            ResetEvent.Await()
            loop:
                GiftButton.OnClick().Await()
                GiftButtonClickedEvent.Signal(Index)

    CreateRow(ButtonsArray : []text_button_base, Padding : margin) : stack_box_slot = 
        Slot1 := CreateRowSlot(ButtonsArray[0] or button_loud{}, horizontal_alignment.Left)
        Slot2 := CreateRowSlot(ButtonsArray[1] or button_loud{}, horizontal_alignment.Center)
        Slot3 := CreateRowSlot(ButtonsArray[2] or button_loud{}, horizontal_alignment.Right)
        stack_box_slot:
            VerticalAlignment := vertical_alignment.Top
            Padding := Padding
            Widget := overlay:
                Slots := array:
                    overlay_slot { Widget := color_block{DefaultDesiredSize := vector2{ X := 710.0}} }
                    Slot1
                    Slot2
                    Slot3

    CreateRowSlot(Button : text_button_base, HorizontalAlignment : horizontal_alignment) : overlay_slot =
        overlay_slot:
            HorizontalAlignment := HorizontalAlignment
            Widget := overlay:
                Slots := array:
                    overlay_slot:
                        Widget := color_block{DefaultDesiredSize := vector2{ X := 225.0}}
                    overlay_slot:
                        HorizontalAlignment := horizontal_alignment.Fill
                        VerticalAlignment := vertical_alignment.Fill
                        Widget := Button

tycoon_gift<public> := class<unique><concrete>(resetable):
    @editable       Time : tycoon_time = tycoon_time{}
    @editable       CashGained : int = 0
    @editable       CandyGained : int = 0

    GiftResetEvent : event() = event(){}

    var TimeInSeconds : int = 0
    var CurrentClaimStatus : tycoon_gift_claim_status = tycoon_gift_claim_status.Locked

    ReadyEvent<public> : event() = event(){}

    Init<public>() : void =
        set CurrentClaimStatus = tycoon_gift_claim_status.Locked
        set TimeInSeconds = Time.Hours * 3600 + Time.Minutes * 60 + Time.Seconds

    Reset<override>() : void =
        set CurrentClaimStatus = tycoon_gift_claim_status.Locked
        set TimeInSeconds = Time.Hours * 3600 + Time.Minutes * 60 + Time.Seconds

    Tick<public>() : void =
        set TimeInSeconds = TimeInSeconds - 1
        if ( TimeInSeconds <= 0):
            set TimeInSeconds = 0
            set CurrentClaimStatus = tycoon_gift_claim_status.Ready
            ReadyEvent.Signal()
            
    Claim<public>() : void = set CurrentClaimStatus = tycoon_gift_claim_status.Claimed

    GetSeconds<public>()<transacts> : int = TimeInSeconds
    GetCurrentClaimStatus<public>()<transacts> : tycoon_gift_claim_status = CurrentClaimStatus
    GetCashReward<public>()<transacts> : int = CashGained
    GetCandyReward<public>()<transacts> : int = CandyGained
    ResetEvent<override>() : event() = GiftResetEvent


tycoon_gift_claim_status<public> := enum:
    Locked
    Ready
    Claimed