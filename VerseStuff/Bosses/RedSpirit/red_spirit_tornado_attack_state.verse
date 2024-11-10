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

red_spirit_tornado_attack_state<public> := class(red_spirit_boss_state):
    var IsTornadoActive : logic = false
    var TornadosToSpawn : int = 2
    var MaybeNextState : ?red_spirit_boss_state = false

    Init<override>(RedSpiritBossManager : red_spirit_boss_manager) : void =
        if ( not IsTornadoActive?, BossFortCharacter := RedSpiritBossManager.NPCBehavior.GetAgent[].GetFortCharacter[]):
            if ( AC := BossFortCharacter.GetPlayAnimationController[]) then AC.Play(BossFights.RedSpirit.Red_Spirit_Animation_Cast)
            set IsTornadoActive = true
            set MaybeNextState = option{RedSpiritBossManager.IdleState}
            set TornadosToSpawn = BossFortCharacter.GetHealth() <= BossFortCharacter.GetMaxHealth() * 0.5 and 4 or 2
            var CurrentSpawnOffset: vector3 = 300.0 * BossFortCharacter.GetTransform().Rotation.GetLocalForward()
            SpawnAngle := 2.0 * PiFloat / (1.0 * TornadosToSpawn) 
            SpawnSin := Sin(SpawnAngle)
            SpawnCos := Cos(SpawnAngle)
            Tornados := RedSpiritBossManager.TornadoProps
            BossPosition := BossFortCharacter.GetTransform().Translation
            
            for ( I := 0..TornadosToSpawn - 1, Tornado := RedSpiritBossManager.TornadoProps[I]):
                if ( Tornado.TeleportTo[BossPosition + CurrentSpawnOffset - vector3{Z := 600.0}, rotation{}]):
                    spawn{UpdateTornado(Tornado, BossPosition)}
                    set CurrentSpawnOffset = vector3:
                        X := CurrentSpawnOffset.X * SpawnCos - CurrentSpawnOffset.Y * SpawnSin
                        Y := CurrentSpawnOffset.X * SpawnSin + CurrentSpawnOffset.Y * SpawnCos 
                        Z := 0.0

    Update<override>(RedSpiritBossManager : red_spirit_boss_manager)<suspends> : void =
        Sleep(2.0)
        End(RedSpiritBossManager)

    End<override>(RedSpiritBossManager : red_spirit_boss_manager) : void =
        RedSpiritBossManager.ChangeState(RedSpiritBossManager.IdleState)

    UpdateTornado(TornadoProp : creative_prop, Center : vector3)<suspends> : void =
        Sleep(0.5)
        TornadoProp.MoveTo(TornadoProp.GetTransform().Translation + vector3{ Z := 400.0}, rotation{}, 1.2)
        Keyframes := TornadoProp.CreateCircularKeyframes(Center)
        if ( AC := TornadoProp.GetAnimationController[]):
            AC.SetAnimation(Keyframes, ?Mode := animation_mode.OneShot)
            AC.Play()
            AC.MovementCompleteEvent.Await()
            set IsTornadoActive = false
        if ( TornadoProp.TeleportTo[vector3{X := 10000.0, Z := -3000.0}, rotation{}]) {}

    (InProp : creative_prop).CreateCircularKeyframes(Center : vector3) : []keyframe_delta =
        SinVal := Sin(PiFloat * 0.175)
        CosVal := Cos(PiFloat * 0.175)
        DeltaRotation := MakeRotationFromYawPitchRollDegrees(75.0, 0.0, 0.0)
        var CurrentVector : vector3 = InProp.GetTransform().Translation - Center
        var Keyframes : []keyframe_delta = array{}
        for ( I := 1..31):
            RotatedVector := vector3:
                X := 1.07 * (CurrentVector.X * CosVal - CurrentVector.Y * SinVal)
                Y := 1.07 * (CurrentVector.X * SinVal + CurrentVector.Y * CosVal)
                Z := 0.0
            DeltaVector := RotatedVector - CurrentVector
            set Keyframes = Keyframes + array:
                keyframe_delta:
                    DeltaLocation := vector3{X := DeltaVector.X, Y := DeltaVector.Y, Z := 0.0}
                    DeltaRotation := DeltaRotation
                    Time := 0.37
            set CurrentVector = RotatedVector

        return Keyframes
