using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Assets }
using { TycoonAnimations }
using { VFXStuff }
using { VerseStuff.TycoonInterfaces}
using { VerseStuff.Managers}

upgradable_dropper_building<public> := class<concrete>(purchasable, resetable):
    @editable       Price : int = 0
    @editable       UpgradeCurrencyType : currency_type = currency_type.Cash
    @editable       DropperProp : creative_prop = creative_prop{}
    @editable       PropellerProp : creative_prop = creative_prop{}
    @editable       PurchaseButton : creative_prop = creative_prop{}
    @editable       PassiveIncome : passive_income = passive_income{}
    @editable       UnlockedBulidingIDs : []int = array{}
    @editable       UseBuildAnimation : logic = true

    BuildingResetEvent : event() = event(){}

    var DefaultDropperPropTransform : transform = transform{}
    var DefaultPropellerPropTransform : transform = transform{}
    var DefaultPurchaseButtonTransform : transform = transform{}
    
    var CurrencyTravelDirection : vector3 = vector3{}
    var CurrencyTravelDistance : float = 0.0

    var PurchaseStatus : purchase_status = purchase_status.Locked
    # var CurrencyProps : []creative_prop = array{}

    UniqueBegin<public>() : void =
        set DefaultDropperPropTransform = DropperProp.GetTransform()
        set DefaultPropellerPropTransform = PropellerProp.GetTransform()
        set DefaultPurchaseButtonTransform = PurchaseButton.GetTransform()
        # set CurrencyProps = for ( I := 0..1) do SpawnProp(GetDefaultBlueprintAsset[GetSession()] or DefaultCreativePropAsset, DropperProp.GetTransform().Translation, MakeRotation(CurrencyTravelDirection, 0.0))(0)? or creative_prop{}

    Init<public>(TycoonManager : tycoon_manager) : void =
        if:
            DropperProp.TeleportTo[DefaultDropperPropTransform.Translation - vector3{ Z := 3000.0}, DefaultDropperPropTransform.Rotation]
            PropellerProp.TeleportTo[DefaultPropellerPropTransform.Translation - vector3{ Z := 3000.0}, DefaultPropellerPropTransform.Rotation]
            PurchaseButton.TeleportTo[DefaultPurchaseButtonTransform.Translation - vector3{ Z := 3000.0}, DefaultPurchaseButtonTransform.Rotation]
        #for ( Prop : CurrencyProps) do Prop.Hide()

    Reset<override>() : void =
        set PurchaseStatus = purchase_status.Locked
        ResetEvent().Signal()

    Unlock<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void = 
        if ( PurchaseStatus = purchase_status.Locked):
            set PurchaseStatus = purchase_status.Unlocked
            spawn { DoTycoonPopupAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}
        
    Purchase<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void = 
        if ( PurchaseStatus <> purchase_status.Purchased):
            set PurchaseStatus = purchase_status.Purchased   
            spawn{ DoTycoonHideAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}
            spawn{ DoTycoonPopupAnimation(DropperProp, DefaultDropperPropTransform, ?PlayAnimations := PlayAnimations)}
            spawn{ DoTycoonPopupAnimation(PropellerProp, DefaultPropellerPropTransform, ?PlayAnimations := PlayAnimations)}
            spawn{ Update(Owner) }
            # if ( PlayAnimations?):
            #     SpawnPurchaseVFX(Self, DefaultDropperPropTransform.Translation - vector3{Z := 120.0}) 

    Update(Owner : custom_player)<suspends> : void=
        branch{ CreateAndPlayDropperAnimation() }
        
        ResetEvent().Await()
            
        #for ( CurrencyProp : CurrencyProps, CurrencyPropAC := CurrencyProp.GetAnimationController[]) do CurrencyPropAC.Stop()
        if ( DropperAC := DropperProp.GetAnimationController[], PropellerAC := PropellerProp.GetAnimationController[]):
            DropperAC.Stop()
            PropellerAC.Stop()

    CreateAndPlayDropperAnimation()<suspends> : void =
        # Wait for popup animations to begin animating stuff
        Print("Waiting for dropper build animations")
        sync:
            loop:
                Sleep(1.5)
                if ( DropperAC := DropperProp.GetAnimationController[].GetState() <> animation_controller_state.Playing) then break
            loop:
                Sleep(1.5)
                if ( PropellerAC := PropellerProp.GetAnimationController[].GetState() <> animation_controller_state.Playing) then break
        Print("Finished building, now animatig dropper!")
        
        DropperKeyframes := 
            for ( I := 0..3) { keyframe_delta{ DeltaLocation := vector3{Z := 1.0}, DeltaRotation := rotation{}, Time := 0.125}} + 
            for ( J := 0..3) do keyframe_delta{ DeltaLocation := vector3{Z := -1.0}, DeltaRotation := rotation{}, Time := 0.125}
        PropellerKeyframes := 
            for ( I := 0..3) { keyframe_delta{ DeltaLocation := vector3{Z := 1.0}, DeltaRotation := MakeRotationFromYawPitchRollDegrees(90.0, 0.0, 0.0), Time := 0.125}} +
            for ( I := 0..3) do keyframe_delta{ DeltaLocation := vector3{Z := -1.0}, DeltaRotation := MakeRotationFromYawPitchRollDegrees(90.0, 0.0, 0.0), Time := 0.125}

        if ( DropperAC := DropperProp.GetAnimationController[], PropellerAC := PropellerProp.GetAnimationController[]):
            DropperAC.SetAnimation(DropperKeyframes, ?Mode := animation_mode.Loop)
            PropellerAC.SetAnimation(PropellerKeyframes, ?Mode := animation_mode.Loop)
            DropperAC.Play()
            PropellerAC.Play()

    # CreateAndPlayCurrencyAnimation()<suspends> : void =
    #     Sleep(1.25)
    #     Rotation := MakeRotation(CurrencyTravelDirection, 0.0)
    #     #Rotation := (Axis := CurrencyTravelDirection.MakeUnitVector[]) and MakeRotation(Axis, 0.0) or DefaultDropperPropTransform.Rotation
    #     for ( Prop : CurrencyProps, Prop.TeleportTo[DefaultDropperPropTransform.Translation, Rotation]) {}
    #     Velocity := 90.0
    #     BounceDistance := 48.0
    #     Displacement := CurrencyTravelDirection * CurrencyTravelDistance
    #     DisplacementTime := CurrencyTravelDistance / Velocity
    #     BounceTime := BounceDistance / Velocity

    #     RemainingMoveTime := DisplacementTime - BounceTime
    #     RemainingDisplacement := Displacement - (CurrencyTravelDirection * BounceDistance)

    #     Keyframes : []keyframe_delta = array:
    #         keyframe_delta{ DeltaLocation := vector3{Z :=  -5.0}, DeltaRotation := rotation{}, Time := 0.2}
    #         keyframe_delta{ DeltaLocation := vector3{Z := -20.0}, DeltaRotation := rotation{}, Time := 0.2}
    #         keyframe_delta{ DeltaLocation := vector3{Z := -42.0}, DeltaRotation := rotation{}, Time := 0.2}
    #         keyframe_delta{ DeltaLocation := vector3{Z := -73.0}, DeltaRotation := rotation{}, Time := 0.2}
    #         keyframe_delta{ DeltaLocation := CurrencyTravelDirection * BounceDistance * 0.25 + vector3{Z :=  6.0}, DeltaRotation := rotation{}, Time := BounceTime * 0.25 }
    #         keyframe_delta{ DeltaLocation := CurrencyTravelDirection * BounceDistance * 0.25 + vector3{Z := -6.0}, DeltaRotation := rotation{}, Time := BounceTime * 0.25 }
    #         keyframe_delta{ DeltaLocation := CurrencyTravelDirection * BounceDistance * 0.25 + vector3{Z :=  2.0}, DeltaRotation := rotation{}, Time := BounceTime * 0.25 }
    #         keyframe_delta{ DeltaLocation := CurrencyTravelDirection * BounceDistance * 0.25 + vector3{Z := -2.0}, DeltaRotation := rotation{}, Time := BounceTime * 0.25 }
    #         keyframe_delta{ DeltaLocation := RemainingDisplacement, DeltaRotation := rotation{}, Time := RemainingMoveTime}
    #         keyframe_delta{ DeltaLocation := -Displacement + vector3{Z := 140.0}, DeltaRotation := rotation{}, Time := 0.005}

    #     for ( Prop : CurrencyProps, AC := Prop.GetAnimationController[]):
    #         Prop.Show()
    #         AC.SetAnimation(Keyframes, ?Mode := animation_mode.Loop)
    #         AC.Play()
    #         Sleep(3.2)
        

    ResetEvent<override>() : event() = BuildingResetEvent
    GetNextBuildingUnlockIDs<override>()<transacts> : []int = UnlockedBulidingIDs
    GetPurchaseCurrencyType<override>()<transacts> : currency_type = UpgradeCurrencyType
    GetPurchaseStatus<override>()<transacts> : purchase_status = PurchaseStatus
    GetPurchaseButton<override>()<transacts> : creative_prop = PurchaseButton
    GetPassiveIncome<public>()<transacts> : passive_income = PassiveIncome
    GetPrice<override>()<transacts> : int = Price
    GetDropperProp<public>()<transacts> : creative_prop = DropperProp
