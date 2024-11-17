using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Colors }
using { /Verse.org/Random }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Assets }
using { VerseStuff.Managers}
using { VFXStuff }
using { UIStuff }


tycoon_level<public> := class:
    UI : tycoon_level_ui = tycoon_level_ui{}
    ResetEvent : event() = event(){}
    XPGrantedEvent<public> : event(int) = event(int){}
    LeveledUpEvent<public> : event(int) = event(int){}
    Season : int = 1

    var TotalXP : int = 0
    var NextLevelXPRequired : int = 0
    var CurrentLevelXP : int = 0
    var CurrentLevel : int = 0
    var CurrentXPMultiplier : float = 1.0
    var Settings : tycoon_level_settings = tycoon_level_settings{}
    var PlayerStatsManager : player_stats_manager = player_stats_manager{}
    
    var MaybeOwner : ?custom_player = false
    UniqueBegin<public>(Owner : custom_player, TycoonLevelSettings : tycoon_level_settings) : void =
        set Settings = TycoonLevelSettings
        UI.UniqueBegin(Owner, Settings.AnimationHud, Settings.XPGrantedAudio, Settings.LevelUpAudio)


    Init<public>(Owner : custom_player, PlayerStats : player_stats) : void =
        Stats := PlayerStats.LevelStats
        set MaybeOwner = option{Owner}
        set CurrentLevel = Stats.Level
        set CurrentLevelXP = Stats.CurrentXP
        set TotalXP = Stats.TotalXP
        set NextLevelXPRequired = GetXPRequired(CurrentLevel + 1)
        # if ( Stats.Season <> Season): <# If new season, reset stats lol #>
        UI.Init(Owner, CurrentLevel, CurrentLevelXP, GetXPRequired(CurrentLevel + 1))
        spawn { Update(Owner) }

    Update(Owner : custom_player)<suspends> : void =
        race:
            ResetEvent.Await()
            loop:
                NewLevel := UI.LevelUpEvent.Await()
                LeveledUpEvent.Signal(NewLevel)
                Accolade := Settings.LevelUpAccolades[Min(Floor(NewLevel / 5), Settings.LevelUpAccolades.Length - 1)] or accolades_device{}
                spawn{Accolade.DelayAward(Owner.Agent)}


    (Accolade : accolades_device).DelayAward(Agent : agent)<suspends> : void =
        Sleep(5.0)
        Accolade.Award(Agent)

    GrantXP<public>(XP : int) : void =
        if ( XP <= 0) then return <# Do nothing if no xp is granted (idk why but still) #>
        GainedXP := Floor[XP * CurrentXPMultiplier] or XP
        set TotalXP += GainedXP
        # When xp gained is more than target xp (level up)
        if(CurrentLevelXP + GainedXP >= NextLevelXPRequired):
            var OverflowXP : int = (CurrentLevelXP + GainedXP) - NextLevelXPRequired
            # XP Gain Animation (full)
            AnimTime := Clamp(3.0 * ((1.0 * (NextLevelXPRequired - CurrentLevelXP)) / (1.0 * NextLevelXPRequired)), 0.25, 3.0)
            XPGainAnimation := tycoon_level_xp_gain_animation_component:
                CurrentLevel := CurrentLevel
                StartingXP := CurrentLevelXP
                EndingXP := NextLevelXPRequired
                TargetXP := NextLevelXPRequired
                Time := option{AnimTime}
            UI.PollAnimation(tycoon_level_animation{ XPGainAnimation := option{XPGainAnimation}})

            # Level UP Animation
            set CurrentLevelXP = 0
            set CurrentLevel = CurrentLevel + 1
            set NextLevelXPRequired = GetXPRequired(CurrentLevel + 1)
            
            LevelUpAnimation := tycoon_level_level_up_animation_component:
                Level := CurrentLevel
                TargetXP := NextLevelXPRequired
            
            UI.PollAnimation(tycoon_level_animation{LevelUpAnimation := option{LevelUpAnimation}})

            # Grant any remaining xp
            if ( OverflowXP > 0) then GrantXP(OverflowXP)
                
        # When XP isn't greater than or equal to target xp (just grant xp)
        else:
            PreviousXP := CurrentLevelXP
            set CurrentLevelXP = CurrentLevelXP + GainedXP
            AnimTime := Clamp(3.0 * ((1.0 * (CurrentLevelXP - PreviousXP)) / (1.0 * NextLevelXPRequired)), 0.25, 3.0)
            XPGainAnimation := tycoon_level_xp_gain_animation_component:
                CurrentLevel := CurrentLevel
                StartingXP := PreviousXP
                EndingXP := CurrentLevelXP
                TargetXP := NextLevelXPRequired
                Time := option{AnimTime}

            UI.PollAnimation(tycoon_level_animation{ XPGainAnimation := option{XPGainAnimation}})

    Reset() : void =
        ResetEvent.Signal()
        UI.Reset()

    GetXPRequired<public>(Level : int)<transacts> : int =  
        Index := 1.0 * Level
        RoundFactor := 500.0
        StepFactor := 750
        MaxXP := 50000
        if ( Level > 40) then return MaxXP
        500 + Min(Round[RoundFactor * Min(100000, Ceil[((1.0 * StepFactor * Index) + Pow(1.1415,Index) * (10 * Pow((1.0 + 0.04/1.0),Index)))/RoundFactor]) - RoundFactor] or StepFactor, MaxXP)
        
    SetXPMultiplier<public>( InMultiplier : float) : void = set CurrentXPMultiplier = InMultiplier

    GetCurrentXP<public>()<transacts> : int = CurrentLevelXP
    GetNextLevelXP<public>()<transacts> : int = NextLevelXPRequired

    GetLevel<public>()<transacts> : int = CurrentLevel
    GetStats<public>()<transacts> : level_stats = 
        level_stats:
            Level := CurrentLevel
            TotalXP := TotalXP
            CurrentXP := CurrentLevelXP

tycoon_level_ui := class:
    UIResetEvent : event() = event(){}
    TextColor : color = MakeColorFromHex("FFFFFFFF")
    LevelUpColor : color = MakeColorFromHex("FDFF00FF")
    ProgressColor : color = MakeColorFromHex("FFCA00FF")
    BackgroundColor : color = MakeColorFromHex("913200FF")

    ColorBlockProgress : color_block = color_block{DefaultDesiredSize := vector2{ X := 0.0, Y := 32.0}}
    ColorBlockLevelUp : color_block = color_block{}
    TextBlockLevel : text_block = text_block{DefaultTextColor := NamedColors.White}
    TextBlockXP : text_block = text_block{DefaultTextColor := NamedColors.White}

    AnimationQueue : tycoon_level_animation_queue = tycoon_level_animation_queue{}
    
    ProgressBarWidth : float = 492.0
    ProgressBarHeight : float = 32.0

    LevelUpEvent : event(int) = event(int){}

    var RootWidget : widget = text_block{}
    var AnimationHud : hud_message_device = hud_message_device{}
    var XPGainAudio : audio_player_device = audio_player_device{}
    var LevelUpAudio : audio_player_device = audio_player_device{}
    var MaybeOwner : ?custom_player = false

    #var IsXPGainDisplayed : logic = false

    PollAnimation<public>(HyperLevelAnimation : tycoon_level_animation) : void =
        AnimationQueue.Queue(HyperLevelAnimation)

    Update<private>()<suspends> : void =
        race:
            UIResetEvent.Await()
            loop:
                AnimationQueue.QueuedEvent.Await()
                loop:
                    MaybeAnimation := AnimationQueue.Dequeue()
                    if ( XPAnimation := MaybeAnimation?):
                        EvaluateAnimation(XPAnimation)
                    else:
                        break
                
    EvaluateAnimation<private>(HyperLevelAnimation : tycoon_level_animation)<suspends> : void =
        sync:
            Sleep(0.0) <# Min animation time #>
            if ( XPAnimation := HyperLevelAnimation.XPGainAnimation?, Owner := MaybeOwner?): <# XP Gain Animation #>
                
                TextBlockLevel.SetText(StringToMessage("Lv {XPAnimation.CurrentLevel}"))
                StartingXP := XPAnimation.StartingXP
                EndingXP := XPAnimation.EndingXP
                StartingProgressSize := ColorBlockProgress.GetDesiredSize()
                EndingProgressSize := vector2:
                    X := ProgressBarWidth * ((1.0 * XPAnimation.EndingXP) / (1.0 * XPAnimation.TargetXP))
                    Y := ProgressBarHeight

                if ( Time := XPAnimation.Time?):
                    XPGainAudio.Play(Owner.Player)
                    Intervals := Floor[Time / 0.05] or 5
                    IntervalsF := 1.0 * Intervals
                    AnimationHud.Show(Owner.Agent, StringToMessage("+{EndingXP - StartingXP} XP!"), ?DisplayTime := 2.25)
                    for ( I := 1..Intervals):
                        Alpha := (1.0 * I) / IntervalsF
                        # Animate Progress Bar 
                        LerpSize := Lerp(StartingProgressSize, EndingProgressSize, Alpha)
                        ColorBlockProgress.SetDesiredSize(LerpSize)

                        # Animate XP Text 
                        LerpNumber := Lerp(1.0 * StartingXP, 1.0 * EndingXP, Alpha)
                        TextBlockXP.SetText(StringToMessage("{Floor[LerpNumber] or 1}/{XPAnimation.TargetXP}"))
                        Sleep(0.0)
                
                ColorBlockProgress.SetDesiredSize(EndingProgressSize)
                TextBlockXP.SetText(StringToMessage("{EndingXP}/{XPAnimation.TargetXP}"))

            if ( LevelUpAnimation := HyperLevelAnimation.LevelUpAnimation?, Owner := MaybeOwner?): <# IDK #>
                Intervals : int = 20
                IntervalsF : float = 1.0 * Intervals
                StartingSize := vector2{ X := 0.0, Y := ProgressBarHeight}
                EndingSize := vector2{ X := ProgressBarWidth, Y := ProgressBarHeight}
                LevelUpAudio.Play(Owner.Player)
                LevelUpEvent.Signal(LevelUpAnimation.Level)
                for ( I := 1..Intervals): <# Fill up Level bar (gold) #>
                    Alpha := (1.0 * I) / IntervalsF
                    Size := Lerp(StartingSize, EndingSize, Alpha)
                    ColorBlockLevelUp.SetDesiredSize(Size)
                    Sleep(0.0)
                AnimationHud.Hide(Owner.Player)
                AnimationHud.Show(Owner.Player, StringToMessage("🌟Level Up!🌟"), ?DisplayTime := 5.0)
                ColorBlockProgress.SetDesiredSize(vector2{X := 0.0, Y := ProgressBarHeight})
                TextBlockLevel.SetTextColor(LevelUpColor)
                TextBlockXP.SetTextColor(LevelUpColor)
                TextBlockLevel.SetText(StringToMessage("Lv {LevelUpAnimation.Level}"))
                Sleep(2.5)
                
                for ( I := 0..15):
                    Alpha := (1.0 * I) / 15.0
                    Size := Lerp(EndingSize, StartingSize, Alpha)
                    ColorBlockLevelUp.SetDesiredSize(Size)
                    Sleep(0.0)

                TextBlockLevel.SetTextColor(TextColor)
                TextBlockXP.SetTextColor(TextColor)
                TextBlockXP.SetText(StringToMessage("0/{LevelUpAnimation.TargetXP}"))
                AnimationHud.Hide(Owner.Player)

    # DisplayXPGain(Owner : custom_player, XPGain : int, Time : float)<suspends> : void =
    #     AnimationHud.SetText(StringToMessage("+{XPGain} XP!"))
    #     AnimationHud.Show(Owner.Player, ?DisplayTime := Time)

    UniqueBegin(Owner : custom_player, InHudDevice : hud_message_device, XPGainAudioPlayer : audio_player_device, LevelUpAudioDevice : audio_player_device) : void =
        TextBlockXP.SetTextColor(TextColor)
        TextBlockLevel.SetTextColor(TextColor)
        ColorBlockLevelUp.SetColor(LevelUpColor)
        ColorBlockProgress.SetColor(ProgressColor)
        
        set AnimationHud = InHudDevice
        set XPGainAudio = XPGainAudioPlayer
        set LevelUpAudio = LevelUpAudioDevice
        set RootWidget = overlay:
            Slots := array:
                overlay_slot: <# Progress bar #>
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{ Left := 10.0, Top := 20.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot: <# Background Bar #>
                                Widget := color_block{DefaultDesiredSize := vector2{X := ProgressBarWidth, Y := ProgressBarHeight}, DefaultColor := BackgroundColor}
                                HorizontalAlignment := horizontal_alignment.Left
                            overlay_slot: <# Progress Bar #> 
                                Widget := ColorBlockProgress
                                HorizontalAlignment := horizontal_alignment.Left
                            overlay_slot: <# Level up bar #>
                                Widget := ColorBlockLevelUp
                                HorizontalAlignment := horizontal_alignment.Left

                overlay_slot: <# Overlay #>
                    Widget := texture_block:
                        DefaultImage := LevelUI.T_Tycoon_Level_Overlay
                        DefaultDesiredSize := vector2{ X := 512.0, Y := 128.0}

                overlay_slot: <# Level Text progress blocks #>
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{ Bottom := 12.0 }
                    Widget := overlay:
                        Slots := array:
                            overlay_slot: <# Level Text #>
                                HorizontalAlignment := horizontal_alignment.Left
                                VerticalAlignment := vertical_alignment.Center
                                Padding := margin{ Left := 20.0}
                                Widget := TextBlockLevel

                            overlay_slot: <# XP Text #>
                                HorizontalAlignment := horizontal_alignment.Right
                                VerticalAlignment := vertical_alignment.Center
                                Padding := margin{ Right := 20.0}
                                Widget := TextBlockXP
        RootWidget.SetVisibility(widget_visibility.Hidden)
        Owner.GetCanvas().AddWidget(
            canvas_slot:
                Widget := RootWidget
                Anchors := anchors{Minimum := vector2{ X := 0.5, Y := 1.0}, Maximum := vector2{ X := 0.5, Y := 1.0}}
                Alignment := vector2{ X := 0.5, Y := 1.0}
                Offsets := margin{Left := 75.0, Top := -50.0}
        )

    Init(Owner : custom_player, CurrentLevel : int, CurrentLevelXP : int, NextLevelXP : int ) : void = 
        set MaybeOwner = option{Owner}
        RootWidget.SetVisibility(widget_visibility.Visible)
        Percent := (1.0 * CurrentLevelXP) / Max((1.0 * NextLevelXP), 1.0)
        TextBlockLevel.SetText(StringToMessage("Lv {CurrentLevel}"))
        TextBlockXP.SetText(StringToMessage("XP: {CurrentLevelXP}/{NextLevelXP}"))
        ColorBlockProgress.SetDesiredSize(vector2{ X := ProgressBarWidth * Percent, Y := ProgressBarHeight})
        ColorBlockLevelUp.SetDesiredSize(vector2{ X := 0.0, Y := ProgressBarHeight})
        spawn{ Update() }
        
    Reset() : void =
        set MaybeOwner = false
        RootWidget.SetVisibility(widget_visibility.Hidden)
        UIResetEvent.Signal()
        AnimationQueue.Reset()
        ColorBlockProgress.SetDesiredSize(vector2{X := 0.0, Y := ProgressBarHeight})

    GetRootWidget()<transacts> : widget = RootWidget

tycoon_level_settings<public> := class<concrete>:
    AnimationHudToolTip<localizes> : message = "Hud Device used to singal xp grants and level up text"
    @editable { ToolTip := AnimationHudToolTip
        } AnimationHud : hud_message_device = hud_message_device{}

    XPGrantedAudioToolTip<localizes> : message = "Audio played when player gains xp"
    @editable { ToolTip := XPGrantedAudioToolTip
        } XPGrantedAudio : audio_player_device = audio_player_device{}

    LevelUpAudioToolTip<localizes> : message = "Audio played when level up animation begins"
    @editable { ToolTip := LevelUpAudioToolTip
        } LevelUpAudio : audio_player_device = audio_player_device{}   

    LevelUpToolTip<localizes> : message = "Array of accolades, every 5th level, increase the accolade used"
    @editable { ToolTip := LevelUpToolTip
        } LevelUpAccolades : []accolades_device = array{}        
        
    

tycoon_level_animation_queue := class:
    # May or may not return aniamtin progress later idk
    QueuedEvent : event() = event(){}
    DequeuedEvent : event() = event(){}

    var Array<private> : []tycoon_level_animation = array{}

    # Push animation progress to the end of the queue
    Queue( HyperLevelAnimation : tycoon_level_animation) : void = 
        set Array = Array + array{ HyperLevelAnimation}
        QueuedEvent.Signal()

    # Remove, and return the animation progress at the beginning of the queue
    Dequeue() : ?tycoon_level_animation = 
        var MaybeHyperLevelAnimation : ?tycoon_level_animation = false
        if ( FirstElement := Array[0]):
            <# Exclude the first element of the array, append the rest #>
            set Array = for ( I := 1..Array.Length - 1, Element := Array[I]) do Element
            set MaybeHyperLevelAnimation = option{FirstElement}
            DequeuedEvent.Signal()

        return MaybeHyperLevelAnimation

    Reset() : void =
        set Array = array{}

    GetSize()<transacts> : int = Array.Length

tycoon_level_animation<public> := struct:
    XPGainAnimation<public> : ?tycoon_level_xp_gain_animation_component = false
    LevelUpAnimation<public> : ?tycoon_level_level_up_animation_component = false

tycoon_level_xp_gain_animation_component<public> := struct:
    CurrentLevel<public> : int
    StartingXP<public> : int
    EndingXP<public> : int
    TargetXP<public> : int

    Time<public> : ?float

tycoon_level_level_up_animation_component<public> := struct:
    Level<public> : int
    TargetXP<public> : int
