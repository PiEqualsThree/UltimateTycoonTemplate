using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Vehicles }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /Fortnite.com/AI }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { VerseStuff.TycoonInterfaces }
using { Managers }
using { NPCBehaviors }
using { UIStuff }

boss_fight_player_manager<public> := class:

    CustomPlayerAddedEvent<public> : event(custom_player) = event(custom_player){}
    CustomPlayerRemovedEvent<public> : event(custom_player) = event(custom_player){}

    var ActiveCustomPlayers : []custom_player = array{}
    var PlayerManager : player_manager = player_manager{}
    var BossMutatorZone : mutator_zone_device = mutator_zone_device{}
    var EnterVolume : volume_device = volume_device{}

    Init<public>(GlobalBossManager : global_boss_manager, PVPManager : global_pvp_manager) : void =
        set PlayerManager = GlobalBossManager.PlayerManager
        set BossMutatorZone = GlobalBossManager.BossAreaMutatorZone
        spawn{Update(GlobalBossManager, PVPManager)}

    Update(GlobalBossManager : global_boss_manager, PVPManager : global_pvp_manager)<suspends> : void =
        loop:
            Agent := GlobalBossManager.BossEnterVolume.AgentEntersEvent.Await()
            if:
                GlobalBossManager.IsBossFightActive?
                CustomPlayer := PlayerManager.GetCustomPlayerFromAgent[Agent]
                not ActiveCustomPlayers.Find[CustomPlayer]
            then:
                if ( PVPManager.IsPVPEnabled[CustomPlayer]):
                    set ActiveCustomPlayers = ActiveCustomPlayers + array{CustomPlayer}
                    CustomPlayerAddedEvent.Signal(CustomPlayer)
                    spawn{CustomPlayer.AwaitPlayerLeavesBossFight()}    
                else:
                    GlobalBossManager.BossEnterErrorHud.Show(CustomPlayer.Player)      
 
    (CustomPlayer : custom_player).AwaitPlayerLeavesBossFight()<suspends> : void =
        race:
            CustomPlayer.FortCharacter.EliminatedEvent().Await()
            loop:
                Sleep(15.0)
                if ( not BossMutatorZone.IsInVolume[CustomPlayer.Agent]) then break
            loop:
                LeavingCustomPlayer := PlayerManager.CustomPlayerRemovedEvent.Await()
                if ( CustomPlayer = LeavingCustomPlayer) then break
            loop:
                LeavingAgent := BossMutatorZone.AgentExitsEvent.Await()
                if ( CustomPlayer.Agent = LeavingAgent) then break
        set ActiveCustomPlayers = for ( CPlayer : ActiveCustomPlayers, CustomPlayer <> CPlayer) do CustomPlayer
        CustomPlayerRemovedEvent.Signal(CustomPlayer)
   
    GetNearestPlayer<public>(BossFortCharacter : fort_character)<transacts><decides> : custom_player =
        var NearestDistance : float = Inf
        var NearestCustomPlayer : ?custom_player = false
        for ( CustomPlayer : PlayerManager.GetCustomPlayers(), BossMutatorZone.IsInVolume[CustomPlayer.Agent]):
            if ( DistSqrd := DistanceSquaredXY(CustomPlayer.FortCharacter.GetTransform().Translation, BossFortCharacter.GetTransform().Translation) <= NearestDistance):
                set NearestDistance = DistSqrd
                set NearestCustomPlayer = option{CustomPlayer}
        NearestCustomPlayer?

    GetActiveCustomPlayers<public>()<transacts> : []custom_player = ActiveCustomPlayers


    