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
    #@editable       ZombieManager : zombie_manager = zombie_manager{}
    #@editable       BossManager : boss_manager = boss_manager{}
    @editable       CosmeticsManager : cosmetics_manager = cosmetics_manager{}
    @editable       UIManager : user_interface_manager = user_interface_manager{}
    #@editable       VIPManager : vip_manager = vip_manager{}
    @editable       DefaultBlueprintAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable       TycoonLevelSettings : tycoon_level_settings = tycoon_level_settings{}
    @editable       CollabSettings<public> : collab_settings = collab_settings{}
    @editable       BossManager : global_boss_manager = global_boss_manager{}
    @editable       ZombieManager : zombie_global_manager = zombie_global_manager{}
    
    #ScoreboardManager : scoreboard_manager = scoreboard_manager{}
    CurrencyManager : currency_manager = currency_manager{}
    PlayerStatsManager : player_stats_manager = player_stats_manager{}

    # OnBegin<override>()<suspends>:void=
    #     if ( set GetDefaultBlueprintAsset[GetSession()] = DefaultBlueprintAsset) {}
    #     PlayerManager.Init(GetPlayspace())
    #     UIManager.Init(PlayerManager)
    #     CurrencyManager.Init(UIManager)
    #     MazeManager.Init(CurrencyManager, UIManager)
    #     BossManager.Init(CurrencyManager, PlayerManager)
    #  #   ScoreboardManager.Init(PlayerManager)
    #  #   CombatManager.Init(PlayerManager, CurrencyManager)
    #     ZombieManager.Init(PlayerManager, CurrencyManager, UIManager)
    #  #   BossManager.Init(CurrencyManager, PlayerManager)
    #  #   VIPManager.Init(PlayerManager)
    #     for ( CustomPlayer : PlayerManager.GetCustomPlayers()) do spawn { PollInitNewPlayer(CustomPlayer)}
    #     for ( TycoonManager : TycoonManagers) do spawn{  BeginTycoonManager(TycoonManager) }
    #     spawn{ Update()}

    # BeginTycoonManager(TycoonManager : tycoon_manager)<suspends> : void =
    #     TycoonManager.UniqueBegin(Self)
    #     # TycoonManager.Init(CurrencyManager, PlayerManager, PlayerStatsManager, UIManager, CosmeticsManager, MazeManager)
    #     TycoonManager.Init(Self)

    # Update()<suspends> : void =
    #     sync:
    #         Sleep(Inf)
    #         loop:
    #             CustomPlayer := PlayerManager.CustomPlayerAddedEvent.Await()
    #             spawn{PollInitNewPlayer(CustomPlayer)}
    #         loop:
    #             CustomPlayer := PlayerManager.CustomPlayerRemovedEvent.Await()
    #             MazeManager.RemovePlayer(CustomPlayer)
    #             MazeManager.RemovePlayerUI(CustomPlayer)
    # PollInitNewPlayer(CustomPlayer : custom_player)<suspends> : void =
    #     CustomPlayer.UniqueBegin(TycoonLevelSettings)