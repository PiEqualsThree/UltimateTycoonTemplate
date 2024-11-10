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
        
    GetBuildingStats()<suspends> : tycoon_building_stats = 
        Sleep(0.0)
        tycoon_building_stats:
            PurchasedBuildingIDs := PurchasedBuildingIDs
            UnlockedBuildingIDs := UnlockedBuildingIDs
            UpgradableBuildingLevelMap := UpgradableBuildingLevelMap

    GetCurrencyStats(Owner : custom_player)<suspends> : tycoon_currency_stats =
        Sleep(0.0)
        tycoon_currency_stats:
            Cash := Owner.Cash
            Candy := Owner.Candy
            BlingBucks := Owner.BlingBucks
            Rebirths := Owner.Rebirths
        
    GetPerkStats(TycoonManager : tycoon_manager)<suspends> : tycoon_perk_stats = 
        Sleep(0.0)
        TycoonManager.PerksManager.GetStats()
            
    # TODO Rework cosmetic manager lol
    GetCosmeticStats(Owner : custom_player)<suspends> : cosmetic_stats =
        cosmetic_stats{}

    GetSeasonPassStats(TycoonManager : tycoon_manager)<suspends> : season_pass_stats = 
        TycoonManager.SeasonPassBuilding.TycoonSeasonPass.GetStats()

    # TODO
    GetPumpkinCarvingStats()<suspends> : pumpkin_carving_stats =
        Sleep(0.0)
        pumpkin_carving_stats{}

    GetPlayerStats(Owner : custom_player, TycoonManager : tycoon_manager)<suspends> : player_stats =
        LevelStats := GetLevelStats(Owner)
        CurrencyStats := GetCurrencyStats(Owner)
        PerkStats := GetPerkStats(TycoonManager)
        CosmeticStats := GetCosmeticStats(Owner)
        BuildingStats := GetBuildingStats()
        SeasonPassStats := GetSeasonPassStats(TycoonManager)
        PumpkinCarvingStats := GetPumpkinCarvingStats()
        player_stats:
            LevelStats := LevelStats
            CurrencyStats := CurrencyStats
            PerkStats := PerkStats
            CosmeticStats := CosmeticStats
            BuildingStats := BuildingStats
            SeasonPassStats := SeasonPassStats
            PumpkinCarvingStats := PumpkinCarvingStats

    ValidatePlayerState<public>() : player_stats = 
        player_stats{}