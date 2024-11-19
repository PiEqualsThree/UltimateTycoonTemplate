using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { PumpkinCarving }
using { TycoonAnimations }
using { VerseStuff.TycoonInterfaces }
using { Managers }

pumpkin_carving_station<public> := class<concrete>(tycoon_building, upgradable, resetable):
    @editable       ID : int = 0
    @editable       UpgradeData : []upgradable_building_data = array{}
    @editable       PumpkinCarvingManager<public> : pumpkin_carving_manager = pumpkin_carving_manager{}
    @editable       PumpkinCollectionManager<public> : pumpkin_collection_manager = pumpkin_collection_manager{}
    @editable       ContainerProp : creative_prop = creative_prop{}
    @editable       UseBuildAnimation : logic = true
    @editable       TycoonCinematic : ?tycoon_cinematic = false

    BuildingResetEvent : event() = event(){}
    BuildingPurchasedEvent : event() = event(){}

    var CurrentLevel : int = 0
    var DefaultContainerPropTransform : transform = transform{}
    var DefaultPurchaseButtonTransform : transform = transform{}
    var PurchaseStatus : purchase_status = purchase_status.Locked

    # Run once per game start
    UniqueBegin<override>() : void =
        set DefaultContainerPropTransform = ContainerProp.GetTransform()
        #set DefaultPurchaseButtonTransform = PurchaseButton.GetTransform()
        spawn{ PumpkinCarvingManager.UniqueBegin() }
        
    Init<override>(TycoonManager : tycoon_manager) : void =
        PumpkinCarvingManager.Init(TycoonManager)
        if ( DefaultContainerPropTransform.Translation.Z < -2000.0) then Print("Tycoon Building {ID} is already iniitialized")
        if:
            ContainerProp.TeleportTo[DefaultContainerPropTransform.Translation - vector3{ Z := 3000.0}, DefaultContainerPropTransform.Rotation]
            #PurchaseButton.TeleportTo[DefaultPurchaseButtonTransform.Translation - vector3{ Z := 3000.0}, DefaultPurchaseButtonTransform.Rotation]
        
    Reset<override>() : void =
        set PurchaseStatus = purchase_status.Locked
        PumpkinCarvingManager.Reset()
        ResetEvent().Signal()
        
    Unlock<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void =
        {}
        # if ( PurchaseStatus = purchase_status.Locked):
            # set PurchaseStatus = purchase_status.Unlocked
            # spawn { DoTycoonPopupAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}

    Upgrade<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void = 
        if ( CurrentLevel = 0, TycoonManager := Owner.MaybeTycoonManager?):
            spawn{ DoTycoonPopupAnimation(ContainerProp, DefaultContainerPropTransform, ?PlayAnimations := logic{PlayAnimations? and UseBuildAnimation?})}
            spawn{ PumpkinCarvingManager.LoadData(Owner, TycoonManager, TycoonManager.PlayerStatsManager.GetStats(Owner.Player)) }
            spawn{ PumpkinCollectionManager.LoadData(Owner, TycoonManager, PumpkinCarvingManager)}
            if ( PurchaseButton := UpgradeData[0].PurchaseButton) then spawn{ DoTycoonHideAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := logic{PlayAnimations? and UseBuildAnimation?})}
            if ( PlayAnimations?, Cinematic := TycoonCinematic?) then spawn{ Cinematic.Play(Owner)}

        else if ( CurrentLevel = 1):
            PumpkinCollectionManager.EnableAutoCollect()
            if ( PurchaseButton := UpgradeData[0].PurchaseButton) then spawn{ DoTycoonHideAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := logic{PlayAnimations? and UseBuildAnimation?})}
        set CurrentLevel = CurrentLevel + 1            
        BuildingPurchasedEvent.Signal()

    ResetEvent<override>() : event() = BuildingResetEvent
    GetPassiveIncome<override>()<transacts> : passive_income = UpgradeData[CurrentLevel - 1].PassiveIncome or passive_income{}
    GetUnlockedBulidingIDs<override>()<transacts> : []int = UpgradeData[CurrentLevel - 1].NextBuildingUnlockIDs or array{}
    GetCurrentUpgradeCurrencyType<override>()<transacts><decides> : currency_type = UpgradeData[CurrentLevel].PurchaseType
    GetCurrentUpgradeButton<override>()<transacts><decides> : creative_prop = UpgradeData[CurrentLevel].PurchaseButton
    GetCurrentUpgradePrice<override>()<transacts><decides> : int = UpgradeData[CurrentLevel].Price
    GetCurrentLevel<override>()<transacts> : int = CurrentLevel
    GetMaxLevel<override>()<transacts> : int = 2
    GetID<override>()<transacts> : int = ID
    IsUnlocked<override>()<transacts><decides> : void =  PurchaseStatus = purchase_status.Unlocked
    