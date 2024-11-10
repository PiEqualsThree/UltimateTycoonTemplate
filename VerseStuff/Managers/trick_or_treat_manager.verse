using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { TycoonInterfaces }
using { UIStuff}

trick_or_treat_manager<public> := class(resetable):

    CollabManagerResetEvent : event() = event(){}
    CollaboratedEvent : event(tuple(custom_player, collab_npc)) = event(tuple(custom_player, collab_npc)){}
    CollabEndedEvent<public> : event() = event(){}

    var CurrencyManager : currency_manager = currency_manager{}
    var MaybeSettings : ?collab_settings = false
    var ShouldDisplayTutorial : logic = true

    Init<public>(InCurrencyManager : currency_manager, InSettings : collab_settings) : void =
        set MaybeSettings = option{InSettings}
        set CurrencyManager = InCurrencyManager

    Reset<override>() : void =
        set ShouldDisplayTutorial = true
        ResetEvent().Signal()

    DisplayTutorial<public>(CustomPlayer : custom_player, Settings : collab_settings)<suspends> : void = 
        set ShouldDisplayTutorial = false
        Settings.TutorialPopup.Show(CustomPlayer.Player)
        race:
            Settings.TutorialPopup.DismissedEvent.Await()
            Settings.TutorialPopup.RespondingButtonEvent.Await()


    StartCollab<public>(Owner : custom_player)<suspends> : void =
        if ( Settings := MaybeSettings?):
            if ( ShouldDisplayTutorial?) then DisplayTutorial(Owner, Settings)
            Print("Began Trick or Treat!")
            for ( Collaborator : Settings.Collaborators) do Collaborator.CollabSwitch.TurnOn(Owner.Player)
            UI : collab_ui = collab_ui{}
            UI.Init()
            Owner.Canvas.AddWidget(
                canvas_slot:
                    Widget := UI.GetRootWidget()
                    Anchors := anchors{Minimum := vector2{ X := 0.5, Y := 0.0}, Maximum := vector2{X  := 0.5, Y := 0.0}}
                    Offsets := margin{ Top := 25.0}
                    Alignment := vector2{ X := 0.5, Y := 0.0}
            )
            spawn{ UpdateCollab(Owner, Settings, UI) }

    UpdateCollab(Owner : custom_player, Settings : collab_settings, UI : collab_ui)<suspends> : void =
        var TimeRemaining : float = Settings.CollabTime
        var CollaboratorMap : [collab_npc]logic = map{}
        var CollabCount : int = 0
        CollabFinishedEvent : event() = event(){}
        defer { CollabFinishedEvent.Signal()}
        for ( Collaborator : Settings.Collaborators) do spawn{ Collaborator.AwaitCollab(Owner, CollabFinishedEvent) }
        UI.CollabCountTextBlock.SetText(StringToMessage("{CollabCount}/{Settings.Collaborators.Length}"))
        UI.TimerTextBlock.SetText(StringToMessage("{FormatFloat(Max(TimeRemaining, 0.0), 1)}s"))
        race:
            ResetEvent().Await()
            loop:
                Sleep(0.1)
                set TimeRemaining -= 0.1
                UI.TimerTextBlock.SetText(StringToMessage("{FormatFloat(Max(TimeRemaining, 0.0), 1)}s"))
                if ( TimeRemaining <= 0.05) then  break

            loop:
                Tuple := CollaboratedEvent.Await()
                CollaboratorPlayer := Tuple(0)
                Collaborator := Tuple(1)
                
                if ( Owner = CollaboratorPlayer, not CollaboratorMap[Collaborator], set CollaboratorMap[Collaborator] = true):
                    Collaborator.CollabSwitch.TurnOff(Owner.Player)
                    CashGain := CurrencyManager.GetCustomPlayerCurrencyGain(Owner, 100 + Floor[Owner.Candy * (0.052 * (CollabCount + 1))] or 5)
                    CandyGain := CurrencyManager.GetCustomPlayerCurrencyGain(Owner, Min(25 + Floor[Owner.Candy * (0.007 * (CollabCount + 1))] or 5, 225000))
                    XPGain := 20 * (CollabCount + 1)
                    CashEarnings := currency_transaction{ Amount := CashGain, Type := currency_type.Cash}
                    CandyEarnings := currency_transaction{ Amount := CandyGain, Type := currency_type.Candy}
                    

                    Settings.CollabSuccessfulHud.SetText(StringToMessage("💵+${FormatNumber(CashGain)}\n🍬+{FormatNumber(CandyGain)} Candy"))
                    Settings.CollabSuccessfulHud.Show(Owner.Player)
                    CurrencyManager.IncreaseCurrency(Owner, CashEarnings)
                    CurrencyManager.IncreaseCurrency(Owner, CandyEarnings)
                    Owner.TycoonLevel.GrantXP(XPGain)
                    if ( Accolade := Settings.Accolades[GetRandomInt(0, Settings.Accolades.Length)]) then Accolade.Award(Owner.Player)
                    set CollabCount += 1
                    UI.CollabCountTextBlock.SetText(StringToMessage("{CollabCount}/{Settings.Collaborators.Length}"))
                    if ( CollabCount = Settings.Collaborators.Length) then break

        CollabFinishedEvent.Signal()
        CollabEndedEvent.Signal()
        Owner.Canvas.RemoveWidget(UI.GetRootWidget())
        for ( Collaborator : Settings.Collaborators) do Collaborator.CollabSwitch.TurnOff(Owner.Player)

    (Collab : collab_npc).AwaitCollab(Owner : custom_player, FinishedEvent : event())<suspends> : void =
        race:
            FinishedEvent.Await()
            loop:
                Agent := Collab.CollabVolume.AgentEntersEvent.Await()
                if ( Owner.Agent = Agent):
                    CollaboratedEvent.Signal(Owner, Collab)

    ResetEvent<override>() : event() = CollabManagerResetEvent

collab_ui := class:
    CollabCountTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFFF00FF"), DefaultShadowColor := MakeColorFromHex("413500FF"), DefaultShadowOffset := option{vector2{ X := 3.0, Y := 3.0}}, DefaultShadowOpacity := 1.0, DefaultJustification := text_justification.Right}
    TimerTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFFF00FF"), DefaultShadowColor := MakeColorFromHex("413500FF"), DefaultShadowOffset := option{vector2{ X := 3.0, Y := 3.0}}, DefaultShadowOpacity := 1.0, DefaultJustification := text_justification.Right}

    var RootWidget : widget = overlay{}

    Init() : void =  
        set RootWidget = overlay:
            Slots := array:
                overlay_slot:
                    Widget := texture_block{ DefaultImage := T_Place_Holder, DefaultDesiredSize := vector2{ X := 1024.0, Y := 128.0}}
                overlay_slot:
                    HorizontalAlignment := horizontal_alignment.Right
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{ Right := 35.0}
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := array:
                            stack_box_slot:
                                Widget := CollabCountTextBlock
                                HorizontalAlignment := horizontal_alignment.Right
                                VerticalAlignment := vertical_alignment.Center
                            stack_box_slot:
                                Widget := TimerTextBlock
                                HorizontalAlignment := horizontal_alignment.Right
                                VerticalAlignment := vertical_alignment.Center


    GetRootWidget() : widget = RootWidget

collab_npc := class<concrete><unique>:
    @editable       CollabSwitch : switch_device = switch_device{}
    @editable       CollabVolume : volume_device = volume_device{}

collab_settings<public> := class<concrete>:
    @editable       Collaborators : []collab_npc = array{}
    @editable       CollabSuccessfulHud : hud_message_device = hud_message_device{}
    @editable       TutorialPopup : popup_dialog_device = popup_dialog_device{}
    @editable       Accolades : []accolades_device = array{} 
    @editable       CollabTime : float = 30.0