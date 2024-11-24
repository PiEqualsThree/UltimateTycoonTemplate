using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { TycoonAnimations }
using { VerseStuff.TycoonInterfaces}
using { VerseStuff.TycoonBuildings}
using { VerseStuff.Managers}

upgradable<public> := interface:
    Unlock<public>(Owner : custom_player , ?PlayAnimations : logic = true) : void 
    Upgrade<public>(Owner : custom_player , ?PlayAnimations : logic = true) : void
    GetCurrentUpgradeCurrencyType<public>()<transacts><decides> : currency_type
    GetCurrentUpgradePrice<public>()<transacts><decides> : int
    GetCurrentUpgradeButton<public>()<transacts><decides> : creative_prop
    GetCurrentLevel<public>()<transacts> : int
    GetMaxLevel<public>()<transacts> : int
    GetUnlockedBulidingIDs<public>()<transacts> : []int
    IsUnlocked<public>()<transacts><decides> : void
    
upgradable_building_data<public> := class<concrete>:
    @editable       Price<public> : int = 0
    @editable       PurchaseType<public> : currency_type = currency_type.Cash
    @editable       ContainerProp<public> : creative_prop = creative_prop{}
    @editable       PurchaseButton<public> : creative_prop = creative_prop{}
    @editable       NextBuildingUnlockIDs<public> : []int = array{}
    @editable       PassiveIncome<public> : passive_income = passive_income{}
    
    var DefaultPurchaseButtonTransform : transform = transform{}
    var DefaultContainerPropTransform : transform = transform{}

    UniqueBegin<public>() : void =
        set DefaultPurchaseButtonTransform = PurchaseButton.GetTransform()
        set DefaultContainerPropTransform = ContainerProp.GetTransform()

    ShowPurchaseButton<public>(?PlayAnimations : logic = true) : void =
        spawn{DoTycoonPopupAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}

    HidePurchaseButton<public>(?PlayAnimations : logic = true) : void =
        spawn{DoTycoonHideAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}

    ShowContainerProp<public>(?PlayAnimations : logic = true) : void =
        spawn{DoTycoonPopupAnimation(ContainerProp, DefaultContainerPropTransform, ?PlayAnimations := PlayAnimations)}

    HideContainerProp<public>(?PlayAnimations : logic = true) : void =
        spawn{DoTycoonHideAnimation(ContainerProp, DefaultContainerPropTransform, ?PlayAnimations := PlayAnimations)}
    