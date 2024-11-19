using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

global_vault_manager := class<concrete>:
    @editable       Password : string = "97185"
    @editable       EnterButton : button_device = button_device{}
    @editable       ExitButton : button_device = button_device{}
    @editable       EnterTeleporter : teleporter_device = teleporter_device{}
    @editable       ExitTeleporter : teleporter_device = teleporter_device{}
    @editable       SuccessAudio : audio_player_device = audio_player_device{}
    @editable       ErrorAudio : audio_player_device = audio_player_device{}

    var CustomPlayerKeypadMap : [custom_player]custom_keypad = map{}

    Init(PlayerManager : player_manager) : void =
        spawn{Update(PlayerManager)}

    Update(PlayerManager : player_manager)<suspends> : void =
        sync:
            loop:
                Agent := EnterButton.InteractedWithEvent.Await()
                if ( CustomPlayer := PlayerManager.GetCustomPlayerFromAgent[Agent]):
                    spawn{CustomPlayer.AwaitKeypad(PlayerManager)}

            loop:
                Agent := ExitButton.InteractedWithEvent.Await()
                ExitTeleporter.Teleport(Agent)

            loop:
                LeavingCustomPlayer := PlayerManager.CustomPlayerRemovedEvent.Await()
                spawn{ HandleCustomPlayerLeave(LeavingCustomPlayer) }

    (CustomPlayer : custom_player).AwaitKeypad(PlayerManager : player_manager)<suspends> : void =
        var MaybeKeypad : ?custom_keypad = false
        if ( Keypad :=  CustomPlayerKeypadMap[CustomPlayer]):
            set MaybeKeypad = option{Keypad}
        else:
            NewKeypad := custom_keypad{Password := Password}
            NewKeypad.UniqueBegin()
            NewKeypad.Init(SuccessAudio, ErrorAudio)
            set MaybeKeypad = option{NewKeypad}
            if ( set CustomPlayerKeypadMap[CustomPlayer] = NewKeypad) {}

        if ( Keypad := MaybeKeypad?):
            Keypad.Display(CustomPlayer)
            race:
                Sleep(60.0)
                CustomPlayer.FortCharacter.EliminatedEvent().Await()
                Keypad.ExitEvent.Await()
                loop:
                    RemovedCustomPlayer := PlayerManager.CustomPlayerRemovedEvent.Await()
                    if ( CustomPlayer = RemovedCustomPlayer) then break
                
                block:
                    Keypad.SuccessEvent.Await()
                    EnterTeleporter.Teleport(CustomPlayer.Player)

            Keypad.Remove(CustomPlayer)
                
    HandleCustomPlayerLeave(CustomPlayer : custom_player)<suspends> : void =
        Sleep(0.0)
        if ( Keypad := CustomPlayerKeypadMap[CustomPlayer]) then Keypad.Reset()
        set CustomPlayerKeypadMap = CustomPlayerKeypadMap.RemoveKey(CustomPlayer)

            