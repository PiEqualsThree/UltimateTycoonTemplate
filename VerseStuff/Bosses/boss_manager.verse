using { /Fortnite.com/AI }
using { NPCBehaviors }
using { Managers }

boss_manager<public> := interface:
    Init<public>(GlobalBossManager : global_boss_manager) : void
    InitBossFight<public>(GlobalBossManager : global_boss_manager)<suspends> : void
    
    EndBossFight<public>(GlobalBossManager : global_boss_manager)<suspends> : void
    GetMaxBossHealth<public>()<transacts> : float
    GetNPCBossBehavior<public>()<transacts><decides> : npc_boss_behavior
