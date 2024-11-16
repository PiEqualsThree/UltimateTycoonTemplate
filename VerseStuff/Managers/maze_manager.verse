using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }


maze_manager<public> := class(creative_device):
    @editable       MazeEntranceTeleporter : teleporter_device = teleporter_device{}
    @editable       MazeEntranceVolume : volume_device = volume_device{}
    @editable       MazeExitButton : button_device = button_device{}
    @editable       MazeBarrier : barrier_device = barrier_device{}
    @editable       MazeBeacon : beacon_device = beacon_device{}
    @editable       CooldownTimer : timer_device = timer_device{}
    
    @editable       MazeTeleporters : []teleporter_device = array{}
    @editable       SmallCollectibles : []collectible_object_device = array{}
    @editable       MediumCollectibles : []collectible_object_device = array{}
    @editable       LargeCollectibles : []collectible_object_device = array{}
    @editable       ExtraLargeCollectibles : []collectible_object_device = array{}
    @editable       ZombieSpawners : []creature_spawner_device = array{}

    MazeTimeDeciseconds : int = 50 * 10
    PlayerRemovedEvent : event(custom_player) = event(custom_player){}
    MazeCompletedEvent : event(custom_player) = event(custom_player){}
    CollectibleCollectedEvent : event(collectible_collected_result) = event(collectible_collected_result){}
    ZombieEliminatedEvent : event(zombie_elimination_result) = event(zombie_elimination_result){}

    var CurrencyManager : currency_manager = currency_manager{}
    var UIManager : user_interface_manager = user_interface_manager{}
    var CustomPlayerUIMap : [custom_player]maze_ui = map{}

    Init(InCurrencyManager : currency_manager, InUIManager : user_interface_manager)<suspends> : void =
        set CurrencyManager = InCurrencyManager
        set UIManager = InUIManager
        for ( SmallCollectible : SmallCollectibles) do SmallCollectible.CollectedEvent.Subscribe(OnSmallCollectibleCollected)
        Sleep(0.0)
        for ( MediumCollectible : MediumCollectibles) do MediumCollectible.CollectedEvent.Subscribe(OnMediumCollectibleCollected)
        Sleep(0.0)
        for ( LargeCollectible : LargeCollectibles) do LargeCollectible.CollectedEvent.Subscribe(OnLargeCollectibleCollected)
        Sleep(0.0)
        for ( ExtraLargeCollectible : ExtraLargeCollectibles) do ExtraLargeCollectible.CollectedEvent.Subscribe(OnExtraLargeCollectibleCollected)
        for ( Spawner : ZombieSpawners) do Spawner.EliminatedEvent.Subscribe(OnZombieEliminated)

    InitPlayer(CustomPlayer : custom_player, TycoonManager : tycoon_manager) : void =
        MazeBarrier.AddToIgnoreList(CustomPlayer.Player)
        MazeBeacon.AddToShowList(CustomPlayer.Player)
        if ( not CustomPlayerUIMap[CustomPlayer]):
            NewUI := maze_ui{}
            NewUI.UniqueBegin()
            if ( set CustomPlayerUIMap[CustomPlayer] = NewUI):
                CustomPlayer.GetCanvas().AddWidget(NewUI.GetCanvasSlot())
                NewUI.Hide()
        spawn{ PollPlayerEvents(CustomPlayer, TycoonManager)}

    RemovePlayer(CustomPlayer : custom_player) : void =
        PlayerRemovedEvent.Signal(CustomPlayer)

    RemovePlayerUI(CustomPlayer : custom_player) : void =
        set CustomPlayerUIMap = CustomPlayerUIMap.RemoveKey(CustomPlayer)

    PollPlayerEvents(CustomPlayer : custom_player, TycoonManager : tycoon_manager)<suspends> : void =
        race:
            loop:
                RemovedCustomPlayer := PlayerRemovedEvent.Await()
                if ( CustomPlayer = RemovedCustomPlayer) then break
            PollMazeEntranceEvents(CustomPlayer, TycoonManager)
            
    PollMazeEntranceEvents(CustomPlayer : custom_player, TycoonManager : tycoon_manager)<suspends> : void =
        loop:
            MazeBarrier.AddToIgnoreList(CustomPlayer.Player)
            MazeBeacon.AddToShowList(CustomPlayer.Player)
            Agent := MazeEntranceVolume.AgentEntersEvent.Await()
            if ( CustomPlayer.Agent = Agent, UI := CustomPlayerUIMap[CustomPlayer]):
                MazeBeacon.RemoveFromShowList(CustomPlayer.Player)
                BeginMazeMinigame(CustomPlayer, TycoonManager, UI)
                CompletionResult := PlayMazeMinigame(CustomPlayer, TycoonManager, UI)
                EndMazeMinigame(CustomPlayer, TycoonManager, UI, CompletionResult)
                loop:
                    MaybeAgent := CooldownTimer.SuccessEvent.Await()
                    if ( CustomPlayer.Agent = MaybeAgent?):
                        break
            else:
                <# Not the player #>

    BeginMazeMinigame(CustomPlayer : custom_player, TycoonManager : tycoon_manager, UI : maze_ui)<suspends> : void =
        for ( Collectible : SmallCollectibles) do Collectible.Respawn(CustomPlayer.Agent)
        Sleep(0.0)
        for ( Collectible : MediumCollectibles) do Collectible.Respawn(CustomPlayer.Agent)
        Sleep(0.0)
        for ( Collectible : LargeCollectibles) do Collectible.Respawn(CustomPlayer.Agent)
        Sleep(0.0)
        for ( Collectible : ExtraLargeCollectibles) do Collectible.Respawn(CustomPlayer.Agent)
        Sleep(0.0)
        if ( Teleporter := MazeTeleporters[GetRandomInt(0, MazeTeleporters.Length - 1)]):
            Teleporter.Teleport(CustomPlayer.Agent)
            UI.Show()
            
    PlayMazeMinigame(CustomPlayer : custom_player, TycoonManager : tycoon_manager, UI : maze_ui)<suspends> : maze_completion_result =
        BaseCandyFactor := CustomPlayer.Candy * 0.005
        ZombieFactor := CustomPlayer.Candy * 0.0025
        Time := MazeTimeDeciseconds + GetRandomInt(10, 60)
        Timer := custom_timer{Mode := custom_timer_mode.Deciseconds}
        Timer.SetTime(Time)
        Timer.Start()
        var CollectedCash : int = 0
        var CollectedCandy : int = 0
        var DidFindExit : logic = false
        
        race:
            Timer.CompletedEvent.Await()
            CustomPlayer.FortCharacter.EliminatedEvent().Await()
            loop:
                CollectionResult := CollectibleCollectedEvent.Await()
                if ( CustomPlayer.Agent = CollectionResult.Agent):
                    set CollectedCash = CollectedCash + 4 * CollectionResult.Size + (Ceil[BaseCandyFactor * Pow(1.35, 1.0 * CollectionResult.Size)] or 1)
                    set CollectedCandy = CollectedCandy + 2 *  CollectionResult.Size + (Ceil[BaseCandyFactor * Pow(1.25, 1.0 * CollectionResult.Size)] or 1)
                    UI.UpdateCurrencyText(CollectedCash, CollectedCandy)
            # loop:
            #     Result := ZombieEliminatedEvent.Await()
            #     if ( CustomPlayer.Agent = Result.Agent):
            #         set CollectedCash = CollectedCash + 8 + (Ceil[2 * ZombieFactor] or 1)
            #         set CollectedCandy = CollectedCandy + 4 + (Ceil[ZombieFactor] or 1)
            #         UI.UpdateCurrencyText(CollectedCash, CollectedCandy)
            loop:
                Agent := MazeExitButton.InteractedWithEvent.Await()
                if ( CustomPlayer.Agent = Agent):
                    set DidFindExit = true
                    break
            loop:
                RemovedCustomPlayer := PlayerRemovedEvent.Await()
                if ( CustomPlayer = RemovedCustomPlayer) then break
            loop:
                Sleep(0.05)
                UI.UpdateTime(Timer.GetCurrentTime(), Time)
            
        return maze_completion_result:
            CollectedCash := CollectedCash
            CollectedCandy := CollectedCandy
            DidFindExit := DidFindExit

            
    EndMazeMinigame(CustomPlayer : custom_player, TycoonManager : tycoon_manager, UI : maze_ui, MazeCompletionResult : maze_completion_result)<suspends> : void =
        CashTransaction := currency_transaction{Amount := MazeCompletionResult.CollectedCash, Type := currency_type.Cash}
        CandyTransaction := currency_transaction{Amount := MazeCompletionResult.CollectedCandy, Type := currency_type.Candy}
        <# TODO: Show Results #>
        CooldownTimer.Start(CustomPlayer.Agent)
        MazeEntranceTeleporter.Teleport(CustomPlayer.Agent)
        MazeBarrier.RemoveFromIgnoreList(CustomPlayer.Agent)
        UI.Hide()

        CurrencyManager.IncreaseCurrency(CustomPlayer, CashTransaction)
        UIManager.DisplayIncomeGain(CustomPlayer, CashTransaction)
        if ( MazeCompletionResult.DidFindExit?):
            Sleep(1.0)
            CurrencyManager.IncreaseCurrency(CustomPlayer, CashTransaction)
            UIManager.DisplayIncomeGain(CustomPlayer, CashTransaction, ?AdditionalText := " (Exit Bonus)", ?TextColor := MakeColorFromHex("FDFF00FF"))

        Sleep(1.0)
        CurrencyManager.IncreaseCurrency(CustomPlayer, CandyTransaction)
        UIManager.DisplayIncomeGain(CustomPlayer, CandyTransaction)
        if ( MazeCompletionResult.DidFindExit?):
            Sleep(1.0)
            CurrencyManager.IncreaseCurrency(CustomPlayer, CandyTransaction)
            UIManager.DisplayIncomeGain(CustomPlayer, CandyTransaction, ?AdditionalText := " (Exit Bonus)", ?TextColor := MakeColorFromHex("FDFF00FF"))

    OnSmallCollectibleCollected(Agent : agent) : void = CollectibleCollectedEvent.Signal(collectible_collected_result{ Agent := Agent, Size := 1})
    OnMediumCollectibleCollected(Agent : agent) : void = CollectibleCollectedEvent.Signal(collectible_collected_result{ Agent := Agent, Size := 2})
    OnLargeCollectibleCollected(Agent : agent) : void = CollectibleCollectedEvent.Signal(collectible_collected_result{ Agent := Agent, Size := 3})
    OnExtraLargeCollectibleCollected(Agent : agent) : void = CollectibleCollectedEvent.Signal(collectible_collected_result{ Agent := Agent, Size := 4})
    OnZombieEliminated(Result : device_ai_interaction_result) : void =
        if ( EliminatingAgent := Result.Source?):
            ZombieEliminatedEvent.Signal(zombie_elimination_result{Agent := EliminatingAgent, ZombieWorth := 1})

collectible_collected_result := struct:
    Agent<public> : agent
    Size<public> : int

zombie_elimination_result := struct:
    Agent<public> : agent
    ZombieWorth<public> : int

maze_completion_result := struct:
    CollectedCash<public> : int
    CollectedCandy<public> : int
    DidFindExit<public> : logic

using { UIStuff }
using { UIStuff.MazeUI }
maze_ui := class:
    ProgressBarSize : vector2 = vector2{ X := 540.0, Y := 60.0}
    ProgressBarBackgroundColor : color = MakeColorFromHex("736E6BFF")
    ProgressBarForegroundColor : color = MakeColorFromHex("FFCE00FF")
    
    ProgressBarBackgroundColorBlock : color_block = color_block{}
    ProgressBarForegroundColorBlock : color_block = color_block{}
    
    CashTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFFFFFFF")}
    CandyTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFFFFFFF")}

    var RootWidget : widget = overlay{}

    UniqueBegin() : void =
        ProgressBarBackgroundColorBlock.SetDesiredSize(ProgressBarSize)
        ProgressBarForegroundColorBlock.SetDesiredSize(ProgressBarSize)
        ProgressBarBackgroundColorBlock.SetColor(ProgressBarBackgroundColor)
        ProgressBarForegroundColorBlock.SetColor(ProgressBarForegroundColor)
        set RootWidget = overlay:
            Slots := array:
                overlay_slot: <# Progress Bar #>
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Left := 295.0, Top := 75.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := ProgressBarBackgroundColorBlock
                                HorizontalAlignment := horizontal_alignment.Left
                            overlay_slot:
                                Widget := ProgressBarForegroundColorBlock
                                HorizontalAlignment := horizontal_alignment.Left
                overlay_slot: <# Image Overlay #>
                    Widget := texture_block{DefaultImage := T_Maze_Overlay, DefaultDesiredSize := vector2{ X := 1024.0, Y := 256.0}}
                    
                overlay_slot: <# Currency Counters #>
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Bottom
                    Padding := margin{ Left := 360.0, Bottom := 40.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := color_block{DefaultDesiredSize := vector2{ X := 480.0}}
                            overlay_slot:
                                Widget := CashTextBlock
                                HorizontalAlignment := horizontal_alignment.Left
                                
                            overlay_slot:
                                Widget := CandyTextBlock
                                Padding := margin{Left := 275.0}
                                HorizontalAlignment := horizontal_alignment.Left           
                                
    UpdateTime(CurrentDeciseconds : int, TotalDeciseconds : int) : void = 
        ProgressBarForegroundColorBlock.SetDesiredSize(Lerp(vector2{Y := ProgressBarSize.Y}, ProgressBarSize, (1.0 * CurrentDeciseconds) / (1.0 * TotalDeciseconds)))
    UpdateCurrencyText(CashAmount : int, CandyAmount : int) : void =
        CashTextBlock.SetText(StringToMessage("{FormatNumber(CashAmount)}"))
        CandyTextBlock.SetText(StringToMessage("{FormatNumber(CandyAmount)}"))

    Show() : void = RootWidget.SetVisibility(widget_visibility.Visible)      
    Hide() : void = RootWidget.SetVisibility(widget_visibility.Hidden)      
                            
    GetCanvasSlot()<transacts> : canvas_slot =
        canvas_slot:
            Widget := RootWidget
            Anchors := anchors{Minimum := vector2{ X := 0.5}, Maximum := vector2{ X := 0.5}}
            Alignment := vector2{ X := 0.5}
            Offsets := margin{Top := 25.0}


