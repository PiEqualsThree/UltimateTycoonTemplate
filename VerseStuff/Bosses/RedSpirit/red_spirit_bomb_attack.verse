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

red_spirit_bomb_attack_state<public> := class(red_spirit_boss_state):

    Init<override>(RedSpiritBossManager : red_spirit_boss_manager) : void =
        Print("Bomb attack state")
        RedSpiritBossManager.Explosive.Reset()
        
             
    Update<override>(RedSpiritBossManager : red_spirit_boss_manager)<suspends> : void =
        if:
            BossFortCharacter := RedSpiritBossManager.NPCBehavior.GetAgent[].GetFortCharacter[]
            BossFocusable := BossFortCharacter.GetFocusInterface[]
            TargetCustomPlayer := RedSpiritBossManager.BossPlayerManager.GetNearestPlayer[BossFortCharacter]
        then:
            race:
                Sleep(0.25)
                BossFocusable.MaintainFocus(TargetCustomPlayer.Agent)
            if ( AC := RedSpiritBossManager.NPCBehavior.GetAgent[].GetFortCharacter[].GetPlayAnimationController[]):
                AC.Play(BossFights.RedSpirit.Red_Spirit_Animation_Throw)
            SpawnLocation := 75.0 * BossFortCharacter.GetTransform().Rotation.GetLocalForward() + BossFortCharacter.GetTransform().Translation + vector3{Z := 75.0}
            SpawnTransform := transform:
                Translation := SpawnLocation
                Rotation := rotation{}
                Scale := IdentityVector * 0.05
            if ( RedSpiritBossManager.ExplosiveProp.TeleportTo[SpawnTransform]) {}
            # Make bomb bigger
            RedSpiritBossManager.ExplosiveProp.MoveTo(MakeScaledTransform(SpawnLocation, ?XScale := 6.5, ?YScale := 6.5, ?ZScale := 6.5), 1.0)
            ForwardVector := BossFortCharacter.GetTransform().Rotation.GetLocalForward()
            race:
                Sleep(5.0)
                RedSpiritBossManager.Explosive.ExplodedEvent.Await()
                block:
                    RedSpiritBossManager.ExplosiveProp.MoveTo(RedSpiritBossManager.ExplosiveProp.GetTransform().Translation + 2500.0 * ForwardVector, rotation{}, 1.25)
                    if ( Agent := BossFortCharacter.GetAgent[]):
                        RedSpiritBossManager.Explosive.Explode(Agent)

        End(RedSpiritBossManager)

    End<override>(RedSpiritBossManager : red_spirit_boss_manager) : void =
        if (RedSpiritBossManager.ExplosiveProp.TeleportTo[vector3{} - vector3{X := 10000.0, Z := 3000.0}, rotation{}] ) {}
        RedSpiritBossManager.ChangeState(RedSpiritBossManager.IdleState)