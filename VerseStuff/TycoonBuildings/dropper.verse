using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { TycoonAnimations }
using { VerseStuff.TycoonInterfaces }
using { VerseStuff.Managers }

dropper<public> := class<concrete>(tycoon_building, upgradable, resetable):
    @editable       ID : int = -1
    @editable       Conveyor : upgradable_building = upgradable_building{}
    @editable       Droppers : []upgradable_dropper_building = array{}
    @editable       TycoonCinematic : ?tycoon_cinematic = false

    BuildingResetEvent : event() = event(){}

    var CurrentLevel : int = 0
    var IsDropperUnlocked<public> : logic = false

    # Run once per game start
    UniqueBegin<override>() : void =
        Conveyor.UniqueBegin()
        TotalDistance := 500.0
        XYZDirection := Droppers[1].GetDropperProp().GetTransform().Translation - Droppers[0].GetDropperProp().GetTransform().Translation or vector3{}
        XYDirection := vector3{ X := XYZDirection.X, Y := XYZDirection.Y, Z := 0.0}.MakeUnitVector[] or vector3{}
        for ( Index->Dropper : Droppers):
            Dropper.UniqueBegin()

    Init<override>(TycoonManager : tycoon_manager) : void =
        Conveyor.Init(TycoonManager)
        for ( Building : Droppers) do Building.Init(TycoonManager)

    Reset<override>() : void =
        ResetEvent().Signal()
        set CurrentLevel = 0
        set IsDropperUnlocked = false
        Conveyor.Reset()
        for ( Building : Droppers) do Building.Reset()
       
    Unlock<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void =
        set IsDropperUnlocked = true
        Conveyor.Unlock(Owner, ?PlayAnimations := PlayAnimations)

    Upgrade<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void = 
        set IsDropperUnlocked = true
        set CurrentLevel = CurrentLevel + 1
        if ( CurrentLevel = 1, StartingDropper := Droppers[0]):
            Conveyor.Purchase(Owner, ?PlayAnimations := PlayAnimations) 
            StartingDropper.Unlock(Owner, ?PlayAnimations := PlayAnimations)
        if ( PurchasedDropper := Droppers[CurrentLevel - 2]):
            PurchasedDropper.Purchase(Owner, ?PlayAnimations := PlayAnimations)
            if ( NextDropper := Droppers[CurrentLevel - 1]):
                NextDropper.Unlock(Owner, ?PlayAnimations := PlayAnimations)
            else:
                Print("Dropper maxed out!")

    ResetEvent<override>() : event() = BuildingResetEvent
    GetCurrentUpgradePrice<override>()<transacts><decides> : int = case(CurrentLevel) { 0 => Conveyor.GetPrice(); _ => Droppers[CurrentLevel - 1].GetPrice()}
    GetCurrentUpgradeButton<override>()<transacts><decides> : creative_prop = case(CurrentLevel) { 0 => Conveyor.GetPurchaseButton(); _ => Droppers[CurrentLevel - 1].GetPurchaseButton()}
    GetCurrentUpgradeCurrencyType<override>()<transacts><decides> : currency_type = case(CurrentLevel) { 0 => Conveyor.GetPurchaseCurrencyType(); _ => Droppers[CurrentLevel - 1].GetPurchaseCurrencyType ()}
    GetMaxLevel<override>()<transacts> : int = 5
    GetCurrentLevel<override>()<transacts> : int = CurrentLevel
    GetPassiveIncome<override>()<transacts> : passive_income = case(CurrentLevel) { 1 => Conveyor.GetPassiveIncome(); _ => Droppers[CurrentLevel - 2].GetPassiveIncome() or passive_income{}}
    GetUnlockedBulidingIDs<override>()<transacts> : []int = case(CurrentLevel) { 1 => Conveyor.GetNextBuildingUnlockIDs(); _ => Droppers[CurrentLevel - 2].GetNextBuildingUnlockIDs() or array{}}
    GetID<override>()<transacts> : int = ID
    IsUnlocked<override>()<transacts><decides> : void = IsDropperUnlocked?
