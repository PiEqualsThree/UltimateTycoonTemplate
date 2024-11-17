using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Vehicles }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary }
using { VerseStuff.TycoonInterfaces }
using { TycoonAnimations}
using { UIStuff }

global_pvp_manager<public> := class<concrete>:
    @editable       DefaultClassSelector : class_and_team_selector_device = class_and_team_selector_device{}
    @editable       PVPDisabledClassSelector : class_and_team_selector_device = class_and_team_selector_device{}
    @editable       PVPOnChannel : channel_device = channel_device{}
    @editable       PVPOffChannel : channel_device = channel_device{}

    var CustomPlayerPVPStateMap : [custom_player]logic = map{}

    Init(PlayerManager : player_manager) : void =
        for ( CustomPlayer : PlayerManager.GetCustomPlayers(), set CustomPlayerPVPStateMap[CustomPlayer] = true) {}
        spawn{Update(PlayerManager)}

    Update(PlayerManager : player_manager)<suspends> : void =
        sync:
            loop: <# Player turns on pvp #>
                MaybeAgent := PVPOnChannel.ReceivedTransmitEvent.Await()
                if:
                    Agent := MaybeAgent?
                    CustomPlayer := PlayerManager.GetCustomPlayerFromAgent[Agent]
                    set CustomPlayerPVPStateMap[CustomPlayer] = true
                then:
                    DefaultClassSelector.ChangeClass(Agent)
                    CustomPlayer.FortCharacter.SetVulnerability(true)
                
            loop: <# Player turns off pvp #>
                MaybeAgent := PVPOffChannel.ReceivedTransmitEvent.Await()
                if:
                    Agent := MaybeAgent?
                    CustomPlayer := PlayerManager.GetCustomPlayerFromAgent[Agent]
                    set CustomPlayerPVPStateMap[CustomPlayer] = false
                then:
                    PVPDisabledClassSelector.ChangeClass(Agent)
                    CustomPlayer.FortCharacter.SetVulnerability(false)

            loop: <# Player joins game #>
                JoiningCustomPlayer := PlayerManager.CustomPlayerAddedEvent.Await()
                if ( set CustomPlayerPVPStateMap[JoiningCustomPlayer] = true) {}

            loop: <# Player Leaves game #>
                LeavingCustomPlayer := PlayerManager.CustomPlayerRemovedEvent.Await()
                set CustomPlayerPVPStateMap = CustomPlayerPVPStateMap.RemoveKey(LeavingCustomPlayer)

    IsPVPEnabled<public>(CustomPlayer : custom_player)<transacts><decides> : void = CustomPlayerPVPStateMap[CustomPlayer]?