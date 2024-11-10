using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Assets }
using { TycoonAnimations }
using { VFXStuff }
using { VerseStuff.TycoonInterfaces}
using { VerseStuff.Managers}

upgradable_building<public> := class<concrete>(purchasable, resetable):
    @editable       Price : int = 0
    @editable       UpgradeCurrencyType : currency_type = currency_type.Cash
    @editable       ContainerProp : creative_prop = creative_prop{}
    @editable       PurchaseButton : creative_prop = creative_prop{}
    @editable       PassiveIncome : passive_income = passive_income{}
    @editable       UseBuildAnimation : logic = true
    @editable       UnlockedBuildingIDs : []int = array{}

    BuildingResetEvent : event() = event(){}

    var DefaultContainerPropTransform : transform = transform{}
    var DefaultPurchaseButtonTransform : transform = transform{}

    var PurchaseStatus : purchase_status = purchase_status.Locked
    
    UniqueBegin<public>() : void =
        set DefaultContainerPropTransform = ContainerProp.GetTransform()
        set DefaultPurchaseButtonTransform = PurchaseButton.GetTransform()

    Init<public>(TycoonManager : tycoon_manager) : void =
        if:
            ContainerProp.TeleportTo[DefaultContainerPropTransform.Translation - vector3{ Z := 3000.0}, DefaultContainerPropTransform.Rotation]
            PurchaseButton.TeleportTo[DefaultPurchaseButtonTransform.Translation - vector3{ Z := 3000.0}, DefaultPurchaseButtonTransform.Rotation]
        
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
            spawn{ DoTycoonPopupAnimation(ContainerProp, DefaultContainerPropTransform, ?PlayAnimations := PlayAnimations)}
            if (PlayAnimations?):
                #SpawnPurchaseVFX(Self, DefaultContainerPropTransform.Translation)

  
    ResetEvent<override>() : event() = BuildingResetEvent
    GetNextBuildingUnlockIDs<override>()<transacts> : []int = UnlockedBuildingIDs
    GetPurchaseCurrencyType<override>()<transacts> : currency_type = UpgradeCurrencyType
    GetPurchaseStatus<override>()<transacts> : purchase_status = PurchaseStatus
    GetPurchaseButton<override>()<transacts> : creative_prop = PurchaseButton
    GetPassiveIncome<public>()<transacts> : passive_income = PassiveIncome
    GetPrice<override>()<transacts> : int = Price