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
using { BossFights }
using { UIStuff }
using { NPCStuff}

red_spirit_follow_player_state<public> := class(red_spirit_boss_state):
    var SpeedMultiplier : float = 1.0
    var MaybeNextState : ?red_spirit_boss_state = false

    Init<override>(RedSpiritBossManager : red_spirit_boss_manager) : void =
        {}
            
    Update<override>(RedSpiritBossManager : red_spirit_boss_manager)<suspends> : void =
        if:
            BossFortCharacter := RedSpiritBossManager.NPCBehavior.GetAgent[].GetFortCharacter[]
            Navigatable := BossFortCharacter.GetNavigatable[]
            NearestCustomPlayer := RedSpiritBossManager.BossPlayerManager.GetNearestPlayer[BossFortCharacter]
        then:
            Target := MakeNavigationTarget(NearestCustomPlayer.Agent)
            <# Set speed multiplier #>
            Navigatable.SetMovementSpeedMultiplier(SpeedMultiplier)
            race:
                block:
                    Sleep(10.0)
                    set MaybeNextState = option{RedSpiritBossManager.IdleState}
                block:
                    Sleep(0.0)
                    Navigatable.NavigateTo(Target, ?ReachRadius := 150.0)   
                    set MaybeNextState = option{RedSpiritBossManager.ScytheAttackState}
            End(RedSpiritBossManager)
        else:
            Sleep(0.0)
            End(RedSpiritBossManager)


    End<override>(RedSpiritBossManager : red_spirit_boss_manager) : void =
        if ( TransitionState := MaybeNextState?):
            RedSpiritBossManager.ChangeState(TransitionState)
            set MaybeNextState = false
        else:
            RedSpiritBossManager.ChangeState(RedSpiritBossManager.IdleState)


    