using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { VerseStuff.Managers}
using { VerseStuff.TycoonInterfaces}
using { VerseStuff.TycoonBuildings}

var GetDefaultBlueprintAsset<public> : weak_map(session, creative_prop_asset) = map{}

game_manager<public> := class(creative_device):
    @editable       TycoonManagers : []tycoon_manager = array{}
    @editable       PlayerManager : player_manager = player_manager{}
    @editable       MazeManager : maze_manager = maze_manager{}
    @editable       CosmeticData : global_cosmetic_data = global_cosmetic_data{}
    @editable       UIManager : user_interface_manager = user_interface_manager{}
    @editable       DefaultBlueprintAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable       TycoonLevelSettings : tycoon_level_settings = tycoon_level_settings{}
    @editable       CollabSettings<public> : collab_settings = collab_settings{}
    @editable       SecretCollectibleSettings<public> : secret_collectible_settings = secret_collectible_settings{}
    @editable       BossManager : global_boss_manager = global_boss_manager{}
    @editable       ZombieManager : global_zombie_manager = global_zombie_manager{}
    @editable       CosmeticShop : global_cosmetic_shop = global_cosmetic_shop{}
    @editable       VaultManager : global_vault_manager = global_vault_manager{}
    @editable       VIPManager : global_vip_manager = global_vip_manager{}
    @editable       PVPManager : global_pvp_manager = global_pvp_manager{}
    
    ScoreboardManager : scoreboard_manager = scoreboard_manager{}
    CurrencyManager : currency_manager = currency_manager{}
    PlayerStatsManager : player_stats_manager = player_stats_manager{}

    OnBegin<override>()<suspends>:void=
        if ( set GetDefaultBlueprintAsset[GetSession()] = DefaultBlueprintAsset) {}
        PlayerManager.Init(GetPlayspace())
        UIManager.Init(PlayerManager)
        CurrencyManager.Init(UIManager)
        VIPManager.Init(PlayerManager)
        MazeManager.Init(CurrencyManager, UIManager)
        BossManager.Init(CurrencyManager, PlayerManager, UIManager, PVPManager)
        CosmeticShop.Init(PlayerManager, CurrencyManager)
        ScoreboardManager.Init(PlayerManager)
        ZombieManager.Init(PlayerManager, CurrencyManager, UIManager)
        ScoreboardManager.Init(PlayerManager)
        VaultManager.Init(PlayerManager)
        VIPManager.Init(PlayerManager)
        PVPManager.Init(PlayerManager)
        for ( CustomPlayer : PlayerManager.GetCustomPlayers()) do spawn { PollInitNewPlayer(CustomPlayer)}
        for ( TycoonManager : TycoonManagers) do spawn{  BeginTycoonManager(TycoonManager) }
        spawn{ Update()}

    BeginTycoonManager(TycoonManager : tycoon_manager)<suspends> : void =
        TycoonManager.UniqueBegin(Self)
        TycoonManager.Init(Self)

    Update()<suspends> : void =
        sync:
            Sleep(Inf)
            loop:
                CustomPlayer := PlayerManager.CustomPlayerAddedEvent.Await()
                spawn{PollInitNewPlayer(CustomPlayer)}
            loop:
                CustomPlayer := PlayerManager.CustomPlayerRemovedEvent.Await()
                MazeManager.RemovePlayer(CustomPlayer)
                MazeManager.RemovePlayerUI(CustomPlayer)
                
    PollInitNewPlayer(CustomPlayer : custom_player)<suspends> : void =
        CustomPlayer.UniqueBegin(TycoonLevelSettings)

