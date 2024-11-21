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
    @editable       PumpkinCarvingWorker<public> : pumpkin_carving_worker = pumpkin_carving_worker{}
    @editable       PumpkinCollectionManager<public> : pumpkin_collection_manager = pumpkin_collection_manager{}
    @editable       PumpkinCollectionFarmer<public> : pumpkin_collection_farmer = pumpkin_collection_farmer{}
    @editable       TycoonCinematic : ?tycoon_cinematic = false

    BuildingResetEvent : event() = event(){}
    BuildingPurchasedEvent : event() = event(){}

    var CurrentLevel : int = 0
    var DefaultContainerPropTransform : transform = transform{}
    var PurchaseStatus : purchase_status = purchase_status.Locked

    # Run once per game start
    UniqueBegin<override>() : void =
        for ( Data : UpgradeData) do Data.UniqueBegin()
        spawn{ PumpkinCarvingManager.UniqueBegin() }
        PumpkinCollectionFarmer.UniqueBegin()
        PumpkinCarvingWorker.UniqueBegin()
        
    Init<override>(TycoonManager : tycoon_manager) : void =
        PumpkinCarvingManager.Init(TycoonManager)
        for ( Data : UpgradeData) do Data.HidePurchaseButton(?PlayAnimations := false )
        for ( Data : UpgradeData) do Data.HideContainerProp(?PlayAnimations := false )
            
    Reset<override>() : void =
        set PurchaseStatus = purchase_status.Locked
        PumpkinCarvingManager.Reset()
        PumpkinCollectionFarmer.Reset()
        ResetEvent().Signal()
        
    Unlock<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void =
        if ( PurchaseStatus = purchase_status.Locked, Data := UpgradeData[0]):
            set PurchaseStatus = purchase_status.Unlocked
            Data.ShowPurchaseButton(?PlayAnimations := PlayAnimations)

    Upgrade<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void = 
        if ( CurrentLevel = 0, TycoonManager := Owner.MaybeTycoonManager?):
            spawn{ PumpkinCarvingManager.LoadData(Owner, TycoonManager, TycoonManager.PlayerStatsManager.GetStats(Owner.Player)) }
            spawn{ PumpkinCollectionManager.LoadData(Owner, TycoonManager, PumpkinCarvingManager)}
            if ( PlayAnimations?, Cinematic := TycoonCinematic?) then spawn{ Cinematic.Play(Owner)}
            if ( Data := UpgradeData[0]):
                Data.HidePurchaseButton(?PlayAnimations := PlayAnimations)
                Data.ShowContainerProp(?PlayAnimations := PlayAnimations)
            if ( Data := UpgradeData[1]):
                Data.ShowPurchaseButton()

        else if ( CurrentLevel = 1):
            PumpkinCollectionFarmer.Init(PumpkinCarvingManager)
            if ( Data := UpgradeData[1]):
                Data.HidePurchaseButton(?PlayAnimations := PlayAnimations)
                Data.ShowContainerProp(?PlayAnimations := PlayAnimations)
            if ( Data := UpgradeData[2]):
                Data.ShowPurchaseButton()
        
        else if ( CurrentLevel = 2, TycoonManager := Owner.MaybeTycoonManager?):
            PumpkinCarvingWorker.Init(Owner, TycoonManager, PumpkinCarvingManager)
            if ( Data := UpgradeData[1]):
                Data.HidePurchaseButton(?PlayAnimations := PlayAnimations)
                Data.ShowContainerProp(?PlayAnimations := PlayAnimations)

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
    