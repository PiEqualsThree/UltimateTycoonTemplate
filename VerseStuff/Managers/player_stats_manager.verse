using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

var PlayerStatsMap : weak_map(player, player_stats) = map{}


player_stats_manager<public> := class:
    GetStats<public>(Player : player) : player_stats = 
        PlayerStatsMap[Player] or player_stats{}

    SaveTycoonStats(CustomPlayer : custom_player, Stats : player_stats)<suspends> : logic =
        var DidSave : logic = false
        race:
            Sleep(10.0)
            loop:
                if:
                    CustomPlayer.Player.IsActive[]
                    set PlayerStatsMap[CustomPlayer.Player] = Stats
                then:
                    set DidSave = true
                    break
                else:
                    Sleep(0.0)
        return DidSave

player_stats<public> := class<final><persistable>:
    LevelStats<public> : level_stats = level_stats{}
    CurrencyStats<public> : tycoon_currency_stats = tycoon_currency_stats{}
    PerkStats<public> : tycoon_perk_stats = tycoon_perk_stats{}
    CosmeticStats<public> : cosmetic_stats = cosmetic_stats{}
    BuildingStats<public> : tycoon_building_stats = tycoon_building_stats{}
    SeasonPassStats<public> : season_pass_stats = season_pass_stats{}
    PumpkinCarvingStats<public> : pumpkin_carving_stats = pumpkin_carving_stats{}

tycoon_currency_stats<public> := class<final><persistable>:
    Cash<public> : int = 100000
    Candy<public> : int = 10000
    Rebirths<public> : int = 0
    BlingBucks<public> : int = 0

tycoon_building_stats<public> := class<final><persistable>:
    CurrencyCollectorCash : int = 0
    PurchasedBuildingIDs : []int = array{}
    UnlockedBuildingIDs : []int = array{-1}
    UpgradableBuildingLevelMap : [int]int = map{}

level_stats<public> := class<final><persistable>:
    Level<public> : int = 0
    CurrentXP<public> : int = 0
    TotalXP<public> : int = 0

season_pass_stats<public> := class<final><persistable>:
    IsPremium<public> : logic = false
    # Claim Status: 0 => Locked, 1 => Unlocked, 2 => Claimed
    ClaimedFreeRewardIDs<public> : []int = array{}
    ClaimedPremiumRewardIDs<public> : []int = array{}

tycoon_perk_stats<public> := class<final><persistable>:
    SelectedPerksIDMap<public> : [int]int = map{}
    PerkLevelIDMap<public> : [int]int = map{}

cosmetic_stats<public> := class<final><persistable>:
    UnlockedAuraIDs : []int = array{0}
    UnlockedVehicleIDs : []int = array{0}
    UnlockedVFXCosmeticIDs : []int = array{}

pumpkin_carving_stats<public> := class<final><persistable>:
    UnlockedMaterialIDs : []int = array{0,1,2,3}
    UnlockedTopIDs : []int = array{0,1,2,3}
    UnlockedEyeIDs : []int = array{0,1,2,3}
    UnlockedMouthIDs : []int = array{0,1,2,3}



