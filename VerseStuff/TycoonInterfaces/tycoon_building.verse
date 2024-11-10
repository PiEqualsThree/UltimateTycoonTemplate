using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { Managers }
tycoon_building<public> := interface:
    UniqueBegin<public>()<suspends> : void 
    Init<public>(TycoonManager : tycoon_manager) : void 
    GetID<public>()<transacts> : int
    GetPassiveIncome<public>()<transacts> : passive_income

tycoon_cinematic<public> := class<concrete>:
    @editable       Cinematic : cinematic_sequence_device = cinematic_sequence_device{}
    @editable       HudDevice : hud_message_device = hud_message_device{}
    @editable       UnlockMapIndicator<public> : ?unlock_tycoon_map_indicator_component = false

    Play<public>(Owner : custom_player)<suspends> : void =
        Owner.FortCharacter.SetVulnerability(false)
        HudDevice.Show(Owner.Player)
        Cinematic.Play(Owner.Player)
        race:
            Cinematic.StoppedEvent.Await()
            Sleep(7.0)
        Owner.FortCharacter.SetVulnerability(true)

unlock_tycoon_cinematic_copmonent := class<concrete>:

unlock_tycoon_map_indicator_component<public> := class<concrete>:
    @editable       MapIndicator : map_indicator_device = map_indicator_device{}

    Activate<public>(CustomPlayer : custom_player) : void = MapIndicator.ActivateObjectivePulse(CustomPlayer.Player)
    Deactivate<public>(CustomPlayer : custom_player) : void = MapIndicator.DeactivateObjectivePulse(CustomPlayer.Player)

    