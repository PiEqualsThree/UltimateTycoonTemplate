using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { UIStuff }

scoreboard_manager<public> := class:
    PlayerLeveledUpEvent : event() = event(){}
    PlayerAddedEvent : event(custom_player) = event(custom_player){}
    PlayerRemovedEvent : event(custom_player) = event(custom_player){}

    var CustomPlayerScoreboardWidgetMap : [custom_player]scoreboard_widget = map{}
    var ActiveCustomPlayers : []custom_player = array{}

    Init<public>(GameManager : game_manager) : void =
        for ( CustomPlayer : GameManager.PlayerManager.GetCustomPlayers()) do InitPlayer(CustomPlayer)
        for ( TycoonManager : GameManager.TycoonManagers) do spawn { AwaitTycoonClaim(TycoonManager)}
        spawn{Update(GameManager.PlayerManager)}
  
    InitPlayer<public>(CustomPlayer : custom_player) : void =
        if ( not ActiveCustomPlayers.Find[CustomPlayer]):
            set ActiveCustomPlayers = ActiveCustomPlayers + array{CustomPlayer}
            NewWidget := scoreboard_widget{}
            if ( set CustomPlayerScoreboardWidgetMap[CustomPlayer] = NewWidget):
                NewWidget.Init()
                CustomPlayer.GetCanvas().AddWidget(
                    canvas_slot:
                        Widget := NewWidget.GetRootWidget()
                        Anchors := anchors{Minimum := vector2{ X := 1.0, Y := 0.0}, Maximum := vector2{ X := 1.0, Y := 0.0}}
                        Alignment := vector2{ X := 1.0, Y := 0.0}
                        Offsets := margin{Left := -15.0, Top := 35.0}
                )
                PlayerAddedEvent.Signal(CustomPlayer)
            RefreshLeaderboardWidgets(ActiveCustomPlayers)
            spawn{CustomPlayer.AwaitLevelUp()}

    RemovePlayer<public>(CustomPlayer : custom_player) : void =
        if ( Widget := CustomPlayerScoreboardWidgetMap[CustomPlayer]) then CustomPlayer.GetCanvas().RemoveWidget(Widget.GetRootWidget())
        set ActiveCustomPlayers = for ( CPlayer : ActiveCustomPlayers, CPlayer <> CustomPlayer) do CPlayer
        set CustomPlayerScoreboardWidgetMap = CustomPlayerScoreboardWidgetMap.RemoveKey(CustomPlayer)
        PlayerRemovedEvent.Signal(CustomPlayer)

    (CustomPlayer : custom_player).AwaitLevelUp()<suspends> : void =
        race:
            loop:
                RemovedCustomPlayer := PlayerRemovedEvent.Await()
                if ( CustomPlayer = RemovedCustomPlayer) then break
            loop:
                CustomPlayer.TycoonLevel.LeveledUpEvent.Await()
                PlayerLeveledUpEvent.Signal()

    Update(PlayerManager : player_manager)<suspends> : void =
        sync:
            loop:
                race:
                    PlayerLeveledUpEvent.Await()
                    PlayerAddedEvent.Await()
                    PlayerRemovedEvent.Await()  

                SortedPlayers := MergeSort(ActiveCustomPlayers, CompareCustomPlayerLevel)
                for ( CustomPlayer : ActiveCustomPlayers):
                    if ( ScoreboardWidget := CustomPlayerScoreboardWidgetMap[CustomPlayer]):
                        ScoreboardWidget.Refresh(SortedPlayers)
                    else:
                        InitPlayer(CustomPlayer)
                       
            loop:
                CustomPlayer := PlayerManager.CustomPlayerAddedEvent.Await()
                InitPlayer(CustomPlayer)
            loop:
                CustomPlayer := PlayerManager.CustomPlayerRemovedEvent.Await()
                RemovePlayer(CustomPlayer)

    AwaitTycoonClaim(TycoonManager : tycoon_manager)<suspends> : void =
        TycoonManager.ClaimedEvent.Await()
        RefreshLeaderboardWidgets(ActiveCustomPlayers)

    RefreshLeaderboardWidgets(CustomPlayers : []custom_player) : void =
        SortedPlayers := MergeSort(CustomPlayers, CompareCustomPlayerLevel)
        for ( CustomPlayer : CustomPlayers, Widget := CustomPlayerScoreboardWidgetMap[CustomPlayer]):
            Widget.Refresh(SortedPlayers)
                            
    CompareCustomPlayerLevel(C1 : custom_player, C2 : custom_player)<transacts><decides> : custom_player = C1.TycoonLevel.GetLevel() > C2.TycoonLevel.GetLevel() and C1

scoreboard_widget := class:

    var RootWidget : widget = stack_box{Orientation := orientation.Vertical}
    var EntrySlots : []scoreboard_slot = array{}

    Init() : void =
        set EntrySlots = for ( I := 0..3, Image := ScoreboardSlotImages[I]):
            NewSlot := scoreboard_slot{}
            NewSlot.Init(Image, ?TextColor := I = 0 and MakeColorFromHex("FFE800FF") or NamedColors.White)
            NewSlot
        StackBoxSlots := for ( Slot : EntrySlots) do stack_box_slot{Widget := Slot.GetRootWidget(), HorizontalAlignment := horizontal_alignment.Left, VerticalAlignment := vertical_alignment.Top, Padding := margin{Bottom := 5.0}}
        set RootWidget = stack_box:
            Orientation := orientation.Vertical
            Slots := StackBoxSlots

    Refresh(SortedCustomPlayers : []custom_player) : void =
        for ( Index->CustomPlayer : SortedCustomPlayers, Slot := EntrySlots[Index]):
            Slot.SetText(AgentToMessage(CustomPlayer.Agent) + StringToMessage(": Lv.{CustomPlayer.TycoonLevel.GetLevel()}"))
            Slot.Show()
        for ( I := SortedCustomPlayers.Length..EntrySlots.Length - 1, Slot := EntrySlots[I]) do Slot.Hide()

    GetRootWidget()<transacts> : widget = RootWidget

scoreboard_slot := class:
    var RootWidget : widget = overlay{}
    TextBlock : text_block = text_block{DefaultTextColor := NamedColors.White}

    Init(Image : texture, ?TextColor : color = NamedColors.White) : void =
        TextBlock.SetTextColor(TextColor)
        set RootWidget = overlay:
            Slots := array:
                overlay_slot:
                    Widget := texture_block{DefaultImage := Image, DefaultDesiredSize := vector2{ X := 512.0, Y := 64.0}}
                    HorizontalAlignment := horizontal_alignment.Left
                overlay_slot:
                    Widget := TextBlock
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{ Left := 130.0}


    SetText(Text : message) : void = TextBlock.SetText(Text)
    Show() : void = RootWidget.SetVisibility(widget_visibility.Visible)
    Hide() : void = RootWidget.SetVisibility(widget_visibility.Hidden)

    GetRootWidget() : widget = RootWidget

ScoreboardSlotImages : []texture = array:
    ScoreboardUI.Scoreboard1st
    ScoreboardUI.Scoreboard2nd
    ScoreboardUI.Scoreboard3rd
    ScoreboardUI.Scoreboard4th    