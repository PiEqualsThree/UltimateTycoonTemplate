using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { VerseStuff.Managers }
using { VerseStuff.TycoonInterfaces }
using { TycoonAnimations }

global_game_start_manager := class<concrete>:
    @editable       GameStartTimer : timer_device = timer_device{}
    @editable       GameStartBarrier : barrier_device = barrier_device{}
    @editable       BaseTeleporters : []teleporter_device = array{}

    Init(GameManager : game_manager) : void=
        spawn{DoGameStartCountdown(GameManager)}

    DoGameStartCountdown(GameManager : game_manager)<suspends> : void =
        GameStartTimer.Start()
        for ( CustomPlayer : GameManager.PlayerManager.GetCustomPlayers()) do CustomPlayer.FortCharacter.SetVulnerability(false)
        race:
            Sleep(11.0)
            GameStartTimer.SuccessEvent.Await()
        GameStartBarrier.Disable()
        Sleep(0.5)
        for ( Index->CustomPlayer : GameManager.PlayerManager.GetCustomPlayers(), BaseTeleporter := BaseTeleporters[Index]):
            CustomPlayer.FortCharacter.SetVulnerability(true)
            BaseTeleporter.Teleport(CustomPlayer.Player)
            Sleep(0.0)
        spawn{Update(GameManager)}

    Update(GameManager : game_manager)<suspends> : void =
        PlayerManager := GameManager.PlayerManager
        loop:
            CustomPlayer := PlayerManager.CustomPlayerAddedEvent.Await()
            InitCustomPlayer(GameManager, CustomPlayer)

    InitCustomPlayer(GameManager : game_manager, CustomPlayer : custom_player) : void =
        for ( Index->TycoonManager : GameManager.TycoonManagers, not TycoonManager.IsOccupied?, Teleporter := BaseTeleporters[Index]):
            Teleporter.Teleport(CustomPlayer.Player)
    