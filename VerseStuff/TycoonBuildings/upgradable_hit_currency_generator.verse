using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Assets}
using { TycoonAnimations }
using { Materials }
using { VFXStuff }
using { VerseStuff.TycoonInterfaces }
using { VerseStuff.Managers}

upgradable_hit_currency_generator<public> := class<concrete>(tycoon_building, purchasable, resetable):
    @editable       ID : int = 0
    @editable       Price : int = 1
    @editable       PurchaseCurrencyType : currency_type = currency_type.Cash
    @editable       HitboxContainerProp : creative_prop = creative_prop{}
    @editable       BaseContainerProp : creative_prop = creative_prop{}
    @editable       ProgressBarProp : creative_prop = creative_prop{}
    @editable       PurchaseButton : creative_prop = creative_prop{}
    @editable       HitTrigger : trigger_device = trigger_device{}
    @editable       Billboard : billboard_device = billboard_device{}
    @editable       HitAudio : audio_player_device = audio_player_device{}
    @editable       UpgradeAudio : audio_player_device = audio_player_device{}
    @editable       UpgradableCurrencyInfo : []hitbox_currency_generation_info = array{}
    @editable       PassiveIncome : passive_income = passive_income{}
    @editable       NextBuildingUnlockIDs : []int = array{}
    @editable       UseBuildAnimation : logic = true
    @editable       TycoonCinematic : ?tycoon_cinematic = false

    HitEvent : event() = event(){}
    BuildingResetEvent : event() = event(){}

    var DefaultBaseContainerTransform : transform = transform{}
    var DefaultHitboxContainerTransform : transform = transform{}
    var DefaultProgressBarTransform : transform = transform{}
    var DefaultPurchaseButtonTransform : transform = transform{}
    var PurchaseStatus : purchase_status = purchase_status.Locked
    var CurrencyManager : currency_manager = currency_manager{}
    var AnimationKeyframes : []keyframe_delta = array{}
    var CurrentLevel : int = 1
    var CurrentCurrencyGenerationInfo : hitbox_currency_generation_info = hitbox_currency_generation_info{}
    var CurrentCurrencyGain : int = 0 
    var ProgressBarMaterial : M_Hitbox_Progress_material = M_Hitbox_Progress_material{}

    var UIManager : user_interface_manager = user_interface_manager{}
    # Run once per game start
    UniqueBegin<override>() : void =
        set DefaultBaseContainerTransform = BaseContainerProp.GetTransform()
        set DefaultHitboxContainerTransform = HitboxContainerProp.GetTransform()
        set DefaultProgressBarTransform = ProgressBarProp.GetTransform()
        set DefaultPurchaseButtonTransform = PurchaseButton.GetTransform()
        set AnimationKeyframes = CreateJellyAnimationKeyframes()
        if ( UpgradableCurrencyInfo[0].CurrencyType = currency_type.Cash):
            set ProgressBarMaterial.FillColor = MakeColorFromHex("89FF00FF")
            set ProgressBarMaterial.BackgroundColor = MakeColorFromHex("0B3100FF")
        if ( UpgradableCurrencyInfo[0].CurrencyType = currency_type.Candy):
            set ProgressBarMaterial.FillColor = MakeColorFromHex("FF5000FF")
            set ProgressBarMaterial.BackgroundColor = MakeColorFromHex("4F000BFF")
        ProgressBarProp.SetMaterial(ProgressBarMaterial)
           
    Init<override>(TycoonManager : tycoon_manager) : void =
        set CurrencyManager = TycoonManager.CurrencyManager
        set UIManager = TycoonManager.UIManager
        set ProgressBarMaterial.Progress = 0.0
        
        if:
            BaseContainerProp.TeleportTo[DefaultBaseContainerTransform.Translation - vector3{ Z := 3000.0}, DefaultBaseContainerTransform.Rotation] 
            HitboxContainerProp.TeleportTo[DefaultHitboxContainerTransform.Translation - vector3{ Z := 3000.0}, DefaultHitboxContainerTransform.Rotation]
            ProgressBarProp.TeleportTo[DefaultProgressBarTransform.Translation - vector3{ Z := 3000.0}, DefaultProgressBarTransform.Rotation]
            PurchaseButton.TeleportTo[DefaultPurchaseButtonTransform.Translation - vector3{ Z := 3000.0}, DefaultPurchaseButtonTransform.Rotation]
        if ( StarterCurrencyInfo := UpgradableCurrencyInfo[0], NextCurrencyInfo := UpgradableCurrencyInfo[1]):
            set CurrentCurrencyGenerationInfo = StarterCurrencyInfo
            case(CurrentCurrencyGenerationInfo.CurrencyType):
                currency_type.Cash => Billboard.SetText(StringToMessage("Lv. {CurrentLevel} (0/{NextCurrencyInfo.HitsRequired})\n+${FormatNumber(CurrentCurrencyGenerationInfo.CurrencyPerHit)}/Hit"))
                currency_type.Candy => Billboard.SetText(StringToMessage("Lv. {CurrentLevel} (0/{NextCurrencyInfo.HitsRequired})\n+{FormatNumber(CurrentCurrencyGenerationInfo.CurrencyPerHit)} Candy/Hit"))
                currency_type.BlingBucks => Print("Error??")
            Billboard.UpdateDisplay()

    Reset<override>() : void =
        ResetEvent().Signal()
        set CurrentLevel = 1
        set PurchaseStatus = purchase_status.Locked
        set CurrentCurrencyGenerationInfo = UpgradableCurrencyInfo[0] or hitbox_currency_generation_info{}
        if ( ProgressBarProp.TeleportTo[DefaultProgressBarTransform]) {}
        HitTrigger.Disable()
        Billboard.SetText(StringToMessage(""))
        Billboard.UpdateDisplay()

    Update(Owner : custom_player)<suspends> : void =
        set CurrentCurrencyGain = CurrencyManager.GetCustomPlayerCurrencyGain(Owner, CurrentCurrencyGenerationInfo.CurrencyPerHit)
        race:
            ResetEvent().Await()
            loop:
                AwaitUpgrade(Owner)
            loop: <# When trigger is hit #>
                MaybeAgent := HitTrigger.TriggeredEvent.Await()
                if ( Owner.Agent = MaybeAgent? ):
                    ResolveHit(Owner)
                    Sleep(0.0)
                    Sleep(0.0)
                    
            loop: <# Animate when hit if not already playing an animation #>
                HitEvent.Await()
                Animate()

    ResolveHit(Owner : custom_player) : void =
        Transaction := currency_transaction{Amount := CurrentCurrencyGain, Type := CurrentCurrencyGenerationInfo.CurrencyType}
        CurrencyManager.IncreaseCurrency(Owner, Transaction)
        UIManager.DisplayIncomeGain(Owner, Transaction)
        HitAudio.Play(Owner.Player)
        HitEvent.Signal()

    AwaitUpgrade(Owner : custom_player)<suspends> : void = 
        if ( HitsToUpgrade := UpgradableCurrencyInfo[CurrentLevel].HitsRequired ):
            DoUpgradeLoop(Owner, HitsToUpgrade)
        else:
            case(CurrentCurrencyGenerationInfo.CurrencyType):
                currency_type.Cash => Billboard.SetText(StringToMessage("Lv. MAX\n+${FormatNumber(CurrentCurrencyGenerationInfo.CurrencyPerHit)}/Hit"))
                currency_type.Candy => Billboard.SetText(StringToMessage("Lv. {CurrentLevel}\n+{FormatNumber(CurrentCurrencyGenerationInfo.CurrencyPerHit)} Candy/Hit"))
                _ => Print("???")
            Billboard.UpdateDisplay()
            Sleep(Inf)

    DoUpgradeLoop(Owner : custom_player, HitsToUpgrade : int)<suspends> : void =
        var CurrentHits : int = 0
        loop:
            HitEvent.Await()
            set CurrentHits = CurrentHits + 1
            case(CurrentCurrencyGenerationInfo.CurrencyType):
                currency_type.Cash => Billboard.SetText(StringToMessage("Lv. {CurrentLevel} ({CurrentHits}/{HitsToUpgrade})\n+${FormatNumber(CurrentCurrencyGenerationInfo.CurrencyPerHit)}/Hit"))
                currency_type.Candy => Billboard.SetText(StringToMessage("Lv. {CurrentLevel} ({CurrentHits}/{HitsToUpgrade})\n+{FormatNumber(CurrentCurrencyGenerationInfo.CurrencyPerHit)} Candy/Hit"))
                currency_type.BlingBucks => Print("Error??")
                
            Billboard.UpdateDisplay()
            set ProgressBarMaterial.Progress = (1.0 * CurrentHits) / (1.0 * HitsToUpgrade)
            if ( CurrentHits >= HitsToUpgrade):
                Upgrade(Owner)
                UpgradeAudio.Play(Owner.Player)
                break

    Upgrade(Owner : custom_player) : void =
        set CurrentLevel += 1
        set CurrentCurrencyGenerationInfo = UpgradableCurrencyInfo[CurrentLevel - 1] or CurrentCurrencyGenerationInfo
        set CurrentCurrencyGain = CurrencyManager.GetCustomPlayerCurrencyGain(Owner, CurrentCurrencyGenerationInfo.CurrencyPerHit)
        set ProgressBarMaterial.Progress = 0.0
        case(CurrentCurrencyGenerationInfo.CurrencyType):
            currency_type.Cash => Billboard.SetText(StringToMessage("Lv. {CurrentLevel} (0/{UpgradableCurrencyInfo[CurrentLevel].HitsRequired or 10})\n+${FormatNumber(CurrentCurrencyGain)}/Hit"))
            currency_type.Candy => Billboard.SetText(StringToMessage("Lv. {CurrentLevel} (0/{UpgradableCurrencyInfo[CurrentLevel].HitsRequired or 10})\n+{FormatNumber(CurrentCurrencyGain)} Candy/Hit"))
            currency_type.BlingBucks => Print("Error??")
            
        # SpawnHitboxUpgradeVFX(Self)
        Billboard.UpdateDisplay()

    Unlock<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void =
        if ( PurchaseStatus = purchase_status.Locked):
            set PurchaseStatus = purchase_status.Unlocked
            spawn { DoTycoonPopupAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}


    Purchase<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void = 
        if ( PurchaseStatus <> purchase_status.Purchased):
            set PurchaseStatus = purchase_status.Purchased   
            HitTrigger.Enable()
            spawn{ DoTycoonHideAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}
            spawn{ DoTycoonPopupAnimation(BaseContainerProp, DefaultBaseContainerTransform, ?PlayAnimations := PlayAnimations)}
            spawn{ DoTycoonPopupAnimation(HitboxContainerProp, DefaultHitboxContainerTransform, ?PlayAnimations := PlayAnimations)}
            spawn{ DoTycoonPopupAnimation(ProgressBarProp, DefaultProgressBarTransform, ?PlayAnimations := PlayAnimations)}
            spawn{ Update(Owner) }
            # if (PlayAnimations?):
            #     SpawnPurchaseVFX(Self, DefaultBaseContainerTransform.Translation)

    Animate()<suspends> : void =
        if ( AnimationController := HitboxContainerProp.GetAnimationController[]):
            AnimationController.SetAnimation(AnimationKeyframes, ?Mode := animation_mode.OneShot)
            AnimationController.Play()
            AnimationController.MovementCompleteEvent.Await()
    
    ResetEvent<override>() : event() = BuildingResetEvent
    GetNextBuildingUnlockIDs<override>()<transacts> : []int = ID > -1 and array{ ID + 1 } or array{} + NextBuildingUnlockIDs
    GetPurchaseCurrencyType<override>()<transacts> : currency_type = PurchaseCurrencyType
    GetPurchaseStatus<override>()<transacts> : purchase_status = PurchaseStatus
    GetPurchaseButton<override>()<transacts> : creative_prop = PurchaseButton
    GetPassiveIncome<override>()<transacts> : passive_income = PassiveIncome
    GetProgressBarTransform<public>()<transacts> : transform = DefaultProgressBarTransform
    GetPrice<override>()<transacts> : int = Price
    GetID<override>()<transacts> : int = ID

hitbox_currency_generation_info<public> := struct<concrete>:
    # @editable       Level : int = 1
    @editable       HitsRequired<public> : int = 0
    @editable       CurrencyPerHit<public> : int = 1
    @editable       CurrencyType<public> : currency_type = currency_type.Cash
    