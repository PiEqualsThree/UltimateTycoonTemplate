using { /Verse.org/Simulation }
using { VerseStuff.Managers}
using { VerseStuff.TycoonInterfaces}
using { VerseStuff.TycoonBuildings }
using { SeasonPass }

save_manager<public> := class:

    var PurchasedBuildingIDMap : [int]logic = map{}
    var UnlockedBuildingIDMap : [int]logic = map{}
    var PurchasedBuildingIDs : []int = array{}
    var UnlockedBuildingIDs : []int = array{}
    var UpgradableBuildingLevelMap : [int]int = map{}

    AddPurchasedBuilding(PurchasedTycoonBuilding : tycoon_building) : void =
        ID := PurchasedTycoonBuilding.GetID()
        if ( not PurchasedBuildingIDMap[ID], set PurchasedBuildingIDMap[ID] = true):
            set PurchasedBuildingIDs = PurchasedBuildingIDs + array{ PurchasedTycoonBuilding.GetID() }

    AddUnlockedBuilding(UnlockedTycoonBuilding : tycoon_building) : void =
        ID := UnlockedTycoonBuilding.GetID()
        if ( not UnlockedBuildingIDMap[ID], set UnlockedBuildingIDMap[ID] = true):
            set UnlockedBuildingIDs = UnlockedBuildingIDs + array{ ID }

    AddUpgradableBuilding(UpgradedTycoonBuilding : tycoon_building, NewLevel : int) : void =
        if ( set UpgradableBuildingLevelMap[UpgradedTycoonBuilding.GetID()] = NewLevel) {}

    RemoveUnlockedBuilding(TycoonBuilding : tycoon_building) : void =
        set UnlockedBuildingIDs = for ( ID : UnlockedBuildingIDs, TycoonBuilding.GetID() <> ID) do ID

    Reset() : void =
        set PurchasedBuildingIDs = array{}
        set UnlockedBuildingIDs = array{}
        set UpgradableBuildingLevelMap = map{}
        set PurchasedBuildingIDMap = map{}
        set UnlockedBuildingIDMap = map{}

    GetLevelStats(Owner : custom_player)<suspends> : level_stats =
        Sleep(0.0)
        level_stats:
            Level := Owner.TycoonLevel.CurrentLevel
            CurrentXP := Owner.TycoonLevel.CurrentLevelXP
            TotalXP := Owner.TycoonLevel.TotalXP
        
    GetBuildingStats(TycoonManager : tycoon_manager, ShouldResetTycoonStats : logic)<suspends> : tycoon_building_stats = 
        Sleep(0.0)
        tycoon_building_stats:
            CurrencyCollectorCash := not ShouldResetTycoonStats? and TycoonManager.CurrencyCollector.StoredCash or 0
            PurchasedBuildingIDs := not ShouldResetTycoonStats? and PurchasedBuildingIDs or array{}
            UnlockedBuildingIDs := not ShouldResetTycoonStats? and UnlockedBuildingIDs or array{-1}
            UpgradableBuildingLevelMap := not ShouldResetTycoonStats? and UpgradableBuildingLevelMap or map{}

    GetCurrencyStats(Owner : custom_player, ShouldResetCurrency : logic)<suspends> : tycoon_currency_stats =
        Sleep(0.0)
        tycoon_currency_stats:
            Cash := ShouldResetCurrency? and 0 or Owner.Cash
            Candy := not ShouldResetCurrency? and Owner.Candy or 0
            BlingBucks := Owner.BlingBucks
            Rebirths := Owner.Rebirths
        
    GetPerkStats(TycoonManager : tycoon_manager)<suspends> : tycoon_perk_stats = 
        Sleep(0.0)
        TycoonManager.PerksManager.GetStats()
            
    GetCosmeticStats(TycoonManager : tycoon_manager)<suspends> : cosmetic_stats =
        Sleep(0.0)
        TycoonManager.CosmeticsManager.GetStats()
            
    GetSeasonPassStats(TycoonManager : tycoon_manager)<suspends> : season_pass_stats = 
        Sleep(0.0)
        TycoonManager.SeasonPassBuilding.TycoonSeasonPass.GetStats()

    GetPumpkinCarvingStats(TycoonManager : tycoon_manager)<suspends> : pumpkin_carving_stats =
        Sleep(0.0)
        TycoonManager.PumpkinCarvingStation.PumpkinCarvingManager.GetStats()

    GetPlayerStats(Owner : custom_player, TycoonManager : tycoon_manager, ?ShouldResetTycoonStats : logic)<suspends> : player_stats =
        LevelStats := GetLevelStats(Owner)
        CurrencyStats := GetCurrencyStats(Owner, ShouldResetTycoonStats)
        PerkStats := GetPerkStats(TycoonManager)
        CosmeticStats := GetCosmeticStats(TycoonManager)
        BuildingStats := GetBuildingStats(TycoonManager, ShouldResetTycoonStats)
        SeasonPassStats := GetSeasonPassStats(TycoonManager)
        PumpkinCarvingStats := GetPumpkinCarvingStats(TycoonManager)
        player_stats:
            LevelStats := LevelStats
            CurrencyStats := CurrencyStats
            PerkStats := PerkStats
            CosmeticStats := CosmeticStats
            BuildingStats := BuildingStats
            SeasonPassStats := SeasonPassStats
            PumpkinCarvingStats := PumpkinCarvingStats

    IsBuildingPurchased(TycoonBuilding : tycoon_building)<transacts><decides> : void = PurchasedBuildingIDMap[TycoonBuilding.GetID()]
    IsBuildingUnlocked(TycoonBuilding : tycoon_building)<transacts><decides> : void = UnlockedBuildingIDMap[TycoonBuilding.GetID()]
    IsBuildingUpgraded(TycoonBuilding : tycoon_building)<transacts><decides> : void = UpgradableBuildingLevelMap[TycoonBuilding.GetID()]

    ValidateSaveFile<public>(PlayerStats : player_stats) : player_stats = 
        player_stats{}