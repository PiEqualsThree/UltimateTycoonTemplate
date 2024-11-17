using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Random }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { VerseStuff.Managers }
using { VerseStuff.TycoonInterfaces }
using { TycoonAnimations }

phone_manager<public> := class<concrete>(resetable):
    @editable       PopupDevice : popup_dialog_device = popup_dialog_device{}
    @editable       TeleportPopup : popup_dialog_device = popup_dialog_device{}
    @editable       RemoteManager : signal_remote_manager_device = signal_remote_manager_device{}
    @editable       CollabReadyHudDevice : hud_message_device = hud_message_device{}
    @editable       BaseTeleporter : teleporter_device = teleporter_device{}
    @editable       MazeTeleporter : teleporter_device = teleporter_device{}
    @editable       BossTeleporter : teleporter_device = teleporter_device{}
    @editable       CarnivalTeleporter : teleporter_device = teleporter_device{}
    

    CollabStartedEvent : event() = event(){}
    FreeCandyClaimedEvent : event() = event(){}
    PhoneResetEvent : event() = event(){}

    CollabManager : trick_or_treat_manager = trick_or_treat_manager{}

    CollabTimer : custom_timer = custom_timer{Mode := custom_timer_mode.Seconds}
    FreeCandyTimer : custom_timer = custom_timer{Mode := custom_timer_mode.Seconds}

    var CurrencyManager : currency_manager = currency_manager{}

    var DefaultContainerPropTransform : transform = transform{}
    var DefaultPurchaseButtonTransform : transform = transform{}

    var IsBuildingUnlocked<public> : logic = false
    var IsBuildingPurchased<public> : logic = false

    
    var IsCollabActive : logic = false
    var IsCollabOnCooldown : logic = false
    var IsFreeCandyClaimOnCooldown : logic = false

    UniqueBegin<public>() : void =
        CollabTimer.SetTime(150)
        FreeCandyTimer.SetTime(60)

    Init<public>(TycoonManager : tycoon_manager, CollabSettings : collab_settings) : void =
        set CurrencyManager = TycoonManager.CurrencyManager
        CollabManager.Init(CurrencyManager, CollabSettings)

    Reset<override>() : void = 
        ResetEvent().Signal()
        set IsCollabActive = false
        set IsCollabOnCooldown = false
        set IsFreeCandyClaimOnCooldown = false
        CollabTimer.Reset()
        FreeCandyTimer.Reset()
        CollabManager.Reset()

    Update<public>(Owner : custom_player, TycoonManager : tycoon_manager)<suspends> : void =
        CollabReadyHudDevice.Show(Owner.Player)
        race:
            PhoneResetEvent.Await()
            # We need 2 loops, because race sucks at cancelling nested async expressions, so using a loop then a race
            # would make the innermost race run until signal event again
            loop:
                Agent := RemoteManager.PrimarySignalEvent.Await()
                if ( Owner.Agent = Agent) then PopupDevice.Show(Agent)
            loop:
                Agent := RemoteManager.SecondarySignalEvent.Await()
                if ( Owner.Agent = Agent) then PopupDevice.Show(Agent)
            loop:
                Tuple := PopupDevice.RespondingButtonEvent.Await()
                case(Tuple(1)):
                    0 => 
                        Print("Teleport Option")
                        HandleTeleportOption(Owner)
                    1 => 
                        Print("Trick or Treat Option")
                        HandleCollabOption(Owner)
                    2 => 
                        Print("Free Candy")
                        HandleFreeCandyOption(Owner)
                        
                    _ => Print("Unkown option for hud popup")
            loop:
                PopupDevice.SetTitleText(StringToMessage(""))
                CollabManager.CollabEndedEvent.Await()
                CollabTimer.Reset()
                CollabTimer.Start()
                set IsCollabOnCooldown = true
                race:
                    ResetEvent().Await()
                    block:
                        CollabTimer.CompletedEvent.Await()
                        CollabReadyHudDevice.Show(Owner.Player)
                        set IsCollabOnCooldown = false
                    loop:
                        PopupDevice.SetTitleText(StringToMessage("Cooldown: {FormatSecondsToMinutes(CollabTimer.GetCurrentTime())}"))
                        Sleep(0.9)
                        
            loop:
                PopupDevice.SetDescriptionText(StringToMessage(""))
                FreeCandyClaimedEvent.Await()
                FreeCandyTimer.Reset()
                FreeCandyTimer.Start()
                set IsFreeCandyClaimOnCooldown = true
                race:
                    ResetEvent().Await()
                    block:
                        FreeCandyTimer.CompletedEvent.Await()
                        set IsFreeCandyClaimOnCooldown = false
                    loop:
                        PopupDevice.SetDescriptionText(StringToMessage("Cooldown: {FormatSecondsToMinutes(FreeCandyTimer.GetCurrentTime())}"))     
                        Sleep(0.9)
            
    HandleTeleportOption(Owner : custom_player)<suspends> : void =
        TeleportPopup.Show(Owner.Player)
        race:
            ResetEvent().Await()
            Owner.FortCharacter.EliminatedEvent().Await()
            loop:
                ResponseTuple := TeleportPopup.RespondingButtonEvent.Await()
                if ( Owner.Agent = ResponseTuple(0)):
                    case(ResponseTuple(1)):
                        0 => BaseTeleporter.Teleport(Owner.Agent)
                        1 => MazeTeleporter.Teleport(Owner.Agent)
                        2 => CarnivalTeleporter.Teleport(Owner.Agent)
                        3 => BossTeleporter.Teleport(Owner.Agent)
                        _ => Print("Unkown option")
                    break

    HandleCollabOption(Owner : custom_player)<suspends> : void =
        if ( not IsCollabActive? and not IsCollabOnCooldown?):
            CollabReadyHudDevice.Hide(Owner.Player)
            CollabManager.StartCollab(Owner) 

    HandleFreeCandyOption(Owner : custom_player)<suspends> : void =
        if ( not IsFreeCandyClaimOnCooldown?, UIManager := Owner.MaybeTycoonManager?.UIManager):
            CandyGain := CurrencyManager.GetCustomPlayerCurrencyGain(Owner, Floor[Max(Owner.Candy, 100) * 0.1] or 10)
            Transaction := currency_transaction{Type := currency_type.Candy, Amount := CandyGain}
            
            CurrencyManager.IncreaseCurrency(Owner, Transaction)
            UIManager.DisplayIncomeGain(Owner, Transaction, ?TextColor := MakeColorFromHex("FF9100FF"), ?AdditionalText := " (Free Candy!)")
            FreeCandyClaimedEvent.Signal()

    
    ResetEvent<override>() : event() = PhoneResetEvent

recording_ui := class:
