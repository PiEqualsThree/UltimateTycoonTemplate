using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Vehicles }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /Fortnite.com/AI }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { VerseStuff.TycoonInterfaces }
using { Bosses }
using { Bosses.RedSpirit}
using { NPCBehaviors }
using { UIStuff }

global_boss_manager<public> := class(creative_device):
    @editable       CooldownTimer : timer_device = timer_device{}
    @editable       BossActiveTimer<public> : timer_device = timer_device{}
    @editable       BossAreaMutatorZone<public> : mutator_zone_device = mutator_zone_device{}
    @editable       BossReadyAudio : audio_player_device = audio_player_device{}
    @editable       BossReadyHud : hud_message_device = hud_message_device{}
    @editable       BossEnterVolume<public> : volume_device = volume_device{}
    @editable       BossEnterTeleporter : teleporter_device = teleporter_device{}
    @editable       OverworldTeleporter : teleporter_device = teleporter_device{}
    @editable       DefeatAccolades : accolades_device = accolades_device{}
    @editable       RedSpiritBossManager : ?red_spirit_boss_manager = false

    BossSpawnedEvent : event(agent) = event(agent){}
    BossFightEndedEvent : event() = event(){}

    BossFightPlayerManager<public> : boss_fight_player_manager = boss_fight_player_manager{}
    var CustomPlayerBossHPWidgetMap<public> : [custom_player]boss_hp_widget = map{}
    var CurrencyManager<public> : currency_manager = currency_manager{}
    var PlayerManager<public> : player_manager = player_manager{}
    var IsBossFightActive<public> : logic = false

    var MaybeCurrentBossManager : ?boss_manager = false

    var BossManagers : []boss_manager = array{}
    
    Init<public>(InCurrencyManager : currency_manager, InPlayerManager : player_manager) : void =
        Print("Init boss manager!")
        set CurrencyManager = InCurrencyManager
        set PlayerManager = InPlayerManager
        if ( RedSpiritManager := RedSpiritBossManager?) then set BossManagers = BossManagers + array{RedSpiritManager}
        for ( Manager : BossManagers) do Manager.Init(Self)
        BossFightPlayerManager.Init(Self)
        spawn{ Update()}
        
    Update()<suspends> : void =
        sync:
            loop:
                CooldownTimer.Reset()
                Sleep(0.5)
                CooldownTimer.Start()
                
                CooldownTimer.SuccessEvent.Await()
                BossReadyAudio.Play()
                BossReadyHud.Show()
                <# Choose a random boss fight #>
                ShuffledArray := Shuffle(BossManagers)
                if ( BossManager := ShuffledArray[0]):
                    BossManager.InitBossFight(Self)
                    BossActiveTimer.Start()
                    set MaybeCurrentBossManager = option{BossManager}
                    set IsBossFightActive = true

                    BossFightEndResult := PollBossFightEvents(BossManager)
                    HandleBossFightEnd(BossManager, BossFightEndResult)
                else:
                    Print("Boss fight error: No boss fight managers found!")
            loop:
                CustomPlayer := BossFightPlayerManager.CustomPlayerAddedEvent.Await()
                HandleCustomPlayerJoinBossFight(CustomPlayer)
            loop:
                CustomPlayer := BossFightPlayerManager.CustomPlayerRemovedEvent.Await()
                HandleCustomPlayerLeavesBossFight(CustomPlayer)

    PollBossFightEvents(BossManager : boss_manager)<suspends> : boss_fight_end_result =
        # For NPC Based bosses 
        if ( NPCBehavior := BossManager.GetNPCBossBehavior[], BossFortCharacter := NPCBehavior.GetAgent[].GetFortCharacter[]):
            race:
                block: <# Await timer runs out #>
                    BossActiveTimer.SuccessEvent.Await()
                    BossManager.EndBossFight(Self)
                    return boss_fight_end_result:
                        WasDefeated := false
                        DefeatingFortCharacter := false

                block: <# Await boss fight elmination #>
                    EliminationResult := BossFortCharacter.EliminatedEvent().Await()
                    return boss_fight_end_result:
                        WasDefeated := true
                        DefeatingFortCharacter := EliminationResult.EliminatingCharacter

                loop: <# Await damage event #>
                    BossFortCharacter.DamagedEvent().Await()
                    for ( CustomPlayer : BossFightPlayerManager.GetActiveCustomPlayers(), Widget := CustomPlayerBossHPWidgetMap[CustomPlayer]):
                        <# Earn money ??? #>
                        Widget.SetProgress(BossFortCharacter.GetHealth() / BossManager.GetMaxBossHealth())
                        Widget.SetHPText("{Ceil[BossFortCharacter.GetHealth()] or 1}/{Ceil[BossManager.GetMaxBossHealth()] or 1}")

        <# non npc bases bosses ??#>
        else if ( 0 = 0):
            
        return boss_fight_end_result{WasDefeated := false, DefeatingFortCharacter := false}

    HandleBossFightEnd(BossManager : boss_manager, BossFightEndResult : boss_fight_end_result)<suspends> : void =
        BossActiveTimer.Reset()
        BossManager.EndBossFight(Self)
        ActiveCustomPlayers := BossFightPlayerManager.GetActiveCustomPlayers()
        set IsBossFightActive = false
        for ( CustomPlayer->Widget : CustomPlayerBossHPWidgetMap) do Widget.Hide()
        for ( CustomPlayer : ActiveCustomPlayers):
            OverworldTeleporter.Teleport(CustomPlayer.Agent)
            HandleCustomPlayerLeavesBossFight(CustomPlayer)
        if ( BossFightEndResult.WasDefeated?):
            <# Give bonus rewards if boss fight was defeated #>
            for ( CustomPlayer : ActiveCustomPlayers):
                DefeatAccolades.Award(CustomPlayer.Agent)
            if (CustomDefeator := PlayerManager.GetCustomPlayerFromFortCharacter[BossFightEndResult.DefeatingFortCharacter?]):
                <# Give extra stuff to defeator #>
        else:
            <# Boss fight time ran out! #>
        Print("After end: {ActiveCustomPlayers.Length} player sin boss fight")

    HandleCustomPlayerJoinBossFight(CustomPlayer : custom_player) : void =
        BossEnterTeleporter.Teleport(CustomPlayer.Player)
        if ( Widget := CustomPlayerBossHPWidgetMap[CustomPlayer], BossManager := MaybeCurrentBossManager?):
            if ( NPCBehavior := BossManager.GetNPCBossBehavior[], BossFortCharacter := NPCBehavior.GetAgent[].GetFortCharacter[]):
                Widget.SetProgress(BossFortCharacter.GetHealth() / BossManager.GetMaxBossHealth())
                Widget.SetHPText("{Ceil[BossFortCharacter.GetHealth()] or 1}/{Ceil[BossManager.GetMaxBossHealth()] or 1}")
            else if ( 0 = 0): <# For non npc based bosses #>
            Widget.Show()
        else:
            NewWidget := boss_hp_widget{}
            if ( set CustomPlayerBossHPWidgetMap[CustomPlayer] = NewWidget):
                NewWidget.Init()
                NewWidget.Show()
                CustomPlayer.GetCanvas().AddWidget(NewWidget.GetCanvasSlot())
                
    HandleCustomPlayerLeavesBossFight(CustomPlayer : custom_player) : void =
        if ( Widget := CustomPlayerBossHPWidgetMap[CustomPlayer]):
            Widget.Hide()

boss_fight_end_result<public> := struct:
    WasDefeated : logic
    DefeatingFortCharacter : ?fort_character

boss_hp_widget<public> := class:
    BGColorBlock : color_block = color_block{DefaultDesiredSize := vector2{ X := 970.0, Y := 64.0}, DefaultColor := NamedColors.Black}
    FGColorBlock : color_block = color_block{DefaultDesiredSize := vector2{ X := 970.0, Y := 64.0}, DefaultColor := NamedColors.Red}
    HPTextBlock : text_block = text_block{DefaultTextColor := NamedColors.White}
    ProgressBarWidth : float = 970.0
    ProgressBarHeight : float = 64.0

    var RootWidget : overlay = overlay{}

    Init<public>() : void =
        set RootWidget = overlay:
            Slots := array:
                overlay_slot:
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Bottom
                    Padding := margin{Left := 28.0, Bottom := 15.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := BGColorBlock
                                HorizontalAlignment := horizontal_alignment.Left
                                VerticalAlignment := vertical_alignment.Bottom
                            overlay_slot:
                                Widget := FGColorBlock
                                HorizontalAlignment := horizontal_alignment.Left
                                VerticalAlignment := vertical_alignment.Bottom
                            overlay_slot:
                                Widget := HPTextBlock
                                Padding := margin{Top := 3.0}
                overlay_slot:
                    Widget := texture_block{DefaultImage := BossFightUI.T_Boss_Fight_Health_Bar, DefaultDesiredSize := vector2{ X := 1024.0, Y := 128.0}}         

    GetCanvasSlot<public>() : canvas_slot =
        canvas_slot:
            Widget := RootWidget
            Anchors := anchors{Minimum := vector2{ X := 0.5, Y := 0.0}, Maximum := vector2{ X := 0.5, Y := 0.0}}
            Alignment := vector2{X := 0.5, Y := 0.0}
            Offsets := margin{Top := 50.0}


    Show<public>() : void = RootWidget.SetVisibility(widget_visibility.Visible)
    Hide<public>() : void = RootWidget.SetVisibility(widget_visibility.Hidden)

    SetProgress<public>(Percentage : float) : void =
        FGColorBlock.SetDesiredSize(vector2{ X := ProgressBarWidth * Percentage, Y := ProgressBarHeight})

    SetHPText<public>(String : string) : void =
        HPTextBlock.SetText(StringToMessage(String))

    Remove<public>(CustomPlayer : custom_player) : void =
        CustomPlayer.GetCanvas().RemoveWidget(RootWidget)

    GetRootWidget<public>() : widget = overlay{}

