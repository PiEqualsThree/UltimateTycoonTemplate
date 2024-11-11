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
using { NPCBehaviors }
using { Managers }
using { UIStuff }

red_spirit_boss_manager<public> := class<concrete>(boss_manager):
    @editable       MaxHealth : float = 0.0
    @editable       NPCSpawner : npc_spawner_device = npc_spawner_device{}
    @editable       ExplosiveProp<public> : creative_prop = creative_prop{}
    @editable       Explosive<public> : explosive_device = explosive_device{}
    @editable       LavaWallProp<public> : creative_prop = creative_prop{}
    @editable       LavaWallVolume<public> : volume_device = volume_device{}
    @editable       ScytheProp<public> : creative_prop = creative_prop{}
    @editable       ScytheVolume<public> : volume_device = volume_device{}
    @editable       TornadoProps<public> : []creative_prop = array{}
    
    FightEndedEvent : event() = event(){}

    IdleState<public> : red_spirit_idle_state = red_spirit_idle_state{}
    BombAttackState<public> : red_spirit_bomb_attack_state = red_spirit_bomb_attack_state{}
    FollowPlayerState<public> : red_spirit_follow_player_state = red_spirit_follow_player_state{}
    ScytheAttackState<public> : red_spirit_scythe_attack_state = red_spirit_scythe_attack_state{}
    TornadoAttackState<public> : red_spirit_tornado_attack_state = red_spirit_tornado_attack_state{}
    LavaWallAttackState<public> : red_spirit_lava_wall_attack_state = red_spirit_lava_wall_attack_state{}

    var ActiveCustomPlayers : []custom_player = array{}
    var CurrentState : red_spirit_boss_state = red_spirit_idle_state{}
    var NPCBehavior : npc_boss_behavior = npc_boss_behavior{}
    var BossPlayerManager : boss_fight_player_manager = boss_fight_player_manager{}
    
    var CurrentBossHealth : float = 0.0
    
    Init<override>(GlobaBossManager : global_boss_manager) : void =
        set BossPlayerManager = GlobaBossManager.BossFightPlayerManager

    InitBossFight<override>(GlobalBossManager : global_boss_manager)<suspends> : void = 
        Print("Starting red spirit boss fight!")
        set CurrentState = IdleState  
        sync:
            block:
                Agent := NPCSpawner.SpawnedEvent.Await()
                if ( Behavior := Agent.GetNPCBehavior[], BossBehavior := npc_boss_behavior[Behavior], BossFortCharacter := BossBehavior.GetAgent[].GetFortCharacter[]):
                    set NPCBehavior = BossBehavior
                    BossFortCharacter.SetMaxHealth(MaxHealth)
                    BossFortCharacter.Heal(MaxHealth)
                    spawn{Update(GlobalBossManager, BossBehavior, BossFortCharacter)}
            block:
                Sleep(0.25) 
                NPCSpawner.Spawn()

    EndBossFight<override>(GlobalBossManager : global_boss_manager)<suspends> : void =
        FightEndedEvent.Signal()
        NPCSpawner.DespawnAll(false)

    Update(GlobalBossManager : global_boss_manager, BossBehavior : npc_boss_behavior, BossFortCharacter : fort_character)<suspends> : void =
        race:
            FightEndedEvent.Await()
            loop: <# Main state loop lol #>
                CurrentState.Init(Self)
                CurrentState.Update(Self)

    ChangeState<public>(NewState : red_spirit_boss_state) : void =
        set CurrentState = NewState

    GetMaxBossHealth<override>()<transacts> : float = MaxHealth
    GetNPCBossBehavior<override>()<transacts><decides> : npc_boss_behavior = NPCBehavior
    GetNPCFocusable()<transacts><decides> : focus_interface = NPCBehavior.GetAgent[].GetFortCharacter[].GetFocusInterface[]
    GetNPCNavigatable()<transacts><decides> : navigatable = NPCBehavior.GetAgent[].GetFortCharacter[].GetNavigatable[]
    GetNPCFortCharacter()<transacts><decides> : fort_character = NPCBehavior.GetAgent[].GetFortCharacter[]
    
    
red_spirit_boss_state<public> := interface:
    Init<public>(RedSpiritBossManager : red_spirit_boss_manager) : void 
    Update<public>(RedSpiritBossManager : red_spirit_boss_manager)<suspends> : void 
    End<public>(RedSpiritBossManager : red_spirit_boss_manager) : void 
            
    