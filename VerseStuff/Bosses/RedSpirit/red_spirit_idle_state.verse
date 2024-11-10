using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Vehicles }
using { /Fortnite.com/Animation }
using { /Fortnite.com/Animation/PlayAnimation }
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
using { BossFights}
using { UIStuff }
using { NPCStuff}

red_spirit_idle_state<public> := class(red_spirit_boss_state):
    var NextState : red_spirit_boss_state = red_spirit_tornado_attack_state{}
    var IdleTime : float = 1.0

    Init<override>(RedSpiritBossManager : red_spirit_boss_manager) : void =
        if ( BossFortCharacter := RedSpiritBossManager.NPCBehavior.GetAgent[].GetFortCharacter[]):
            set NextState = Self
            set IdleTime = BossFortCharacter.GetHealth() <= BossFortCharacter.GetMaxHealth() * 0.5 and 0.3 or 1.0
            Print("Idling. . . ")

    Update<override>(RedSpiritBossManager : red_spirit_boss_manager)<suspends> : void =
        race:
            Sleep(IdleTime)
            if:
                BossFocusable := RedSpiritBossManager.GetNPCFocusable[]
                TargetCustomPlayer := RedSpiritBossManager.BossPlayerManager.GetNearestPlayer[RedSpiritBossManager.GetNPCFortCharacter[]]
                
            then:
                BossFocusable.MaintainFocus(TargetCustomPlayer.Agent)
            else:
                Sleep(Inf)
        if ( RedSpiritBossManager.BossPlayerManager.GetActiveCustomPlayers().Length > 0):
            case(GetRandomInt(0, 5)):
                0 => set NextState = Self
                1 => set NextState = RedSpiritBossManager.FollowPlayerState
                2 => set NextState = RedSpiritBossManager.TornadoAttackState
                2 => set NextState = RedSpiritBossManager.ScytheAttackState
                3 => set NextState = RedSpiritBossManager.BombAttackState
                4 => set NextState = RedSpiritBossManager.LavaWallAttackState
                _ => set NextState = Self
        else:
            Print("next state idle because no playres found!")
        End(RedSpiritBossManager)

    End<override>(RedSpiritBossManager : red_spirit_boss_manager) : void =
        RedSpiritBossManager.ChangeState(NextState)

    