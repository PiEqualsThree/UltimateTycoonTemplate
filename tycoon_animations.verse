using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Assets}
using { VFXStuff }
using { VerseStuff.TycoonInterfaces}
using { VerseStuff.TycoonBuildings}

TycoonAnimations<public> := module:

    DoTycoonPopupAnimation<public>(Prop : creative_prop, TargetTransform : transform, ?PlayAnimations : logic)<suspends> : void =
        if ( PlayAnimations?):
            if:
                Prop.TeleportTo[TargetTransform.Translation - vector3{Z := 1200.0}, TargetTransform.Rotation]
                AnimationController := Prop.GetAnimationController[]
            then:
                Sleep(0.25)
                Keyframes := array:
                    keyframe_delta:
                        DeltaLocation := vector3{ Z := 1200.0}
                        DeltaRotation := rotation{}
                        Time := 0.65
                        Interpolation := InterpolationTypes.EaseOut
                AnimationController.SetAnimation(Keyframes, ?Mode := animation_mode.OneShot)
                AnimationController.Play()
                AnimationController.MovementCompleteEvent.Await()
        else:
            if ( Prop.TeleportTo[TargetTransform]) {}

    DoTycoonHideAnimation<public>(Prop : creative_prop, DefaultTransform : transform, ?PlayAnimations : logic)<suspends> : void =
        if ( PlayAnimations?):
            Prop.MoveTo(DefaultTransform.Translation - vector3{Z := 500.0}, Prop.GetTransform().Rotation, 0.5)
            if ( Prop.TeleportTo[DefaultTransform.Translation - vector3{Z := 2500.0}, DefaultTransform.Rotation ]) {}
        else:
            if ( Prop.TeleportTo[DefaultTransform.Translation - vector3{ Z := 3000.0},DefaultTransform.Rotation] ) {}

    CreateJellyAnimationKeyframes<public>() : []keyframe_delta =
        return array:
            keyframe_delta:
                DeltaLocation := vector3{}
                DeltaRotation := rotation{}
                DeltaScale := vector3{X := 1.1, Y := 1.1, Z := 1.0 / 1.2}
                Time := 0.1
            keyframe_delta:
                DeltaLocation := vector3{}
                DeltaRotation := rotation{}
                DeltaScale := vector3{X := 1.0 / 1.15, Y := 1.0 / 1.15, Z := 1.15 * 1.0 / (1.0 / 1.2)}
                Time := 0.1
            keyframe_delta:
                DeltaLocation := vector3{}
                DeltaRotation := rotation{}
                DeltaScale := vector3{X := 1.0 / (1.1 / 1.15), Y := 1.0 / (1.1 / 1.15), Z := 1.0 / 1.15}
                Time := 0.1

    SpawnPurchaseVFX<public>(Purchasable : purchasable, SpawnLocation : vector3) : void = {}
        #SpawnParticleSystem(PurchaseVFX.NS_Purchase, SpawnLocation + vector3{Z := 50.0})
    
    # SpawnHitboxUpgradeVFX<public>(UpgradableHitbox : upgradable_hit_currency_generator) : void =
    #     SpawnParticleSystem(HitboxUpgradeVFX.NS_HitboxUpgrade, UpgradableHitbox.GetProgressBarTransform().Translation)