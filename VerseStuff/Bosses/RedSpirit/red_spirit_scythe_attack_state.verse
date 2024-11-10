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

red_spirit_scythe_attack_state<public> := class(red_spirit_boss_state):

    Init<override>(RedSpiritBossManager : red_spirit_boss_manager) : void =
        if:
            BossFortCharacter := RedSpiritBossManager.NPCBehavior.GetAgent[].GetFortCharacter[]
            AC := BossFortCharacter.GetPlayAnimationController[]
            RedSpiritBossManager.ScytheProp.TeleportTo[BossFortCharacter.GetTransform().Translation - vector3{Z := 125.0}, BossFortCharacter.GetTransform().Rotation]
        then:
            AC.Play(BossFights.RedSpirit.Red_Spirit_Animation_Taunt)

    Update<override>(RedSpiritBossManager : red_spirit_boss_manager)<suspends> : void =
        if ( BossFortCharacter := RedSpiritBossManager.NPCBehavior.GetAgent[].GetFortCharacter[]):
            RedSpiritBossManager.ScytheProp.MoveTo(BossFortCharacter.GetTransform().Translation, RedSpiritBossManager.ScytheProp.GetTransform().Rotation, 1.0)
            Sleep(0.75)
            branch:
                loop:
                    TargetAgent := RedSpiritBossManager.ScytheVolume.AgentEntersEvent.Await()
                    if ( Fort := TargetAgent.GetFortCharacter[] ) then Fort.Damage(75.0)
            if ( PropAC := RedSpiritBossManager.ScytheProp.GetAnimationController[]):
                Keyframes := array:
                    keyframe_delta{DeltaLocation := vector3{}, DeltaRotation := MakeRotationFromYawPitchRollDegrees(-175.0, 0.0, 0.0), Time := 0.25}
                    keyframe_delta{DeltaLocation := vector3{}, DeltaRotation := MakeRotationFromYawPitchRollDegrees(-175.0, 0.0, 0.0), Time := 0.25}
                PropAC.SetAnimation(Keyframes, ?Mode := animation_mode.OneShot)
                PropAC.Play()
                PropAC.MovementCompleteEvent.Await()
            End(RedSpiritBossManager)

    End<override>(RedSpiritBossManager : red_spirit_boss_manager) : void =
        if ( RedSpiritBossManager.ScytheProp.TeleportTo[vector3{} - vector3{X := 10000.0, Z := 3000.0}, rotation{}] ) {}
        RedSpiritBossManager.ChangeState(RedSpiritBossManager.IdleState)
