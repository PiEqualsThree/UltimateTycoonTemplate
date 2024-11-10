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

season_pass_ui<public> := class:

    Canvas : canvas = canvas{}
    UIResetEvent : event() = event(){}

    ExitButton : button_quiet = button_quiet{}
    BackPageButton : button_quiet = button_quiet{}
    NextPageButton : button_quiet = button_quiet{}
    NextLevelTextBlock : text_block = text_block{DefaultTextColor := NamedColors.White}

    ActivatePremiumTextureBlock : texture_block = texture_block{DefaultImage := SeasonPassUI.T_Button_Activate_Premium, DefaultDesiredSize := vector2{ X := 512.0, Y := 128.0}}
    ActivatePremiumButton : text_button_base = button_quiet{}
    XPWidget : season_pass_xp_widget = season_pass_xp_widget{}
    
    var CurrentPage : int = 1
    var RootWidget : widget = overlay{}
    var FreeRewardWidgets : []season_pass_reward_widget = array{}
    var PremiumRewardWidgets : []season_pass_reward_widget = array{}
    var TierLevelWidgets : []season_pass_tier_level_widget = array{}

    UniqueBegin<public>()<suspends> : void =
        XPWidget.UniqueBegin()
        for ( I := 0..3):
            FreeWidget := season_pass_reward_widget{}
            PremiumWidget := season_pass_reward_widget{}
            TierLevelWidget := season_pass_tier_level_widget{}
            FreeWidget.UniqueBegin(SeasonPassUI.T_Reward_Overlay_Free, MakeColorFromHex("3C3D3CFF"))
            PremiumWidget.UniqueBegin(SeasonPassUI.T_Reward_Overlay_Premium, MakeColorFromHex("563C05FF"))
            TierLevelWidget.UniqueBegin()
            set FreeRewardWidgets = FreeRewardWidgets + array{FreeWidget}
            set PremiumRewardWidgets = PremiumRewardWidgets + array{PremiumWidget}
            set TierLevelWidgets = TierLevelWidgets + array{TierLevelWidget}
            Sleep(0.0)

        set RootWidget = CreateRootWidget()
        Canvas.AddWidget( canvas_slot { Widget := RootWidget })

    Init<public>() : void = 
        XPWidget.SetProgress(0, 1000)
        NextLevelTextBlock.SetText(StringToMessage("{1}"))
        for ( Widget : FreeRewardWidgets) do Widget.Init()
        for ( Widget : PremiumRewardWidgets) do Widget.Init()

    Display(Owner : custom_player, Pass : season_pass) : void = 
        if ( PlayerUI := GetPlayerUI[Owner.Player]):
            PlayerUI.AddWidget(Canvas, player_ui_slot{InputMode := ui_input_mode.All})
            RefreshPage(Owner, Pass)
        
    Remove(Owner : custom_player) : void =
        if ( PlayerUI := GetPlayerUI[Owner.Player]):
            for ( Widget : PremiumRewardWidgets) do Widget.StopClaimAnimation()
            for ( Widget : FreeRewardWidgets) do Widget.StopClaimAnimation()
            PlayerUI.RemoveWidget(Canvas)
           
    # Refresh rewards on current page
    RefreshPage<public>(Owner : custom_player, Pass : season_pass) : void =
        profile("Refreshing battle pass page"){
        Offset := CurrentPage - 1
        Image := Pass.IsPremium? and SeasonPassUI.T_Button_Premium_Activated or SeasonPassUI.T_Button_Activate_Premium
        ActivatePremiumTextureBlock.SetImage(Image)
        XPWidget.SetProgress(Owner.TycoonLevel.CurrentLevelXP, Owner.TycoonLevel.NextLevelXPRequired)
        NextLevelTextBlock.SetText(StringToMessage("{Owner.TycoonLevel.GetLevel() + 1}"))
        for ( I := 0..3, PremiumWidget := PremiumRewardWidgets[I], FreeWidget := FreeRewardWidgets[I], TierLevelWidget := TierLevelWidgets[I]):
            MaybePremiumReward := option{ Pass.MaybePremiumRewards[I + Offset * 4]? }
            MaybeFreeReward := option{ Pass.MaybeFreeRewards[I + Offset * 4]? }

            PremiumWidget.UpdateRewardInfo(MaybePremiumReward, Pass.IsPremium)
            FreeWidget.UpdateRewardInfo(MaybeFreeReward, Pass.IsPremium)

            TierLevelWidget.SetLevel((option{(MaybePremiumReward? or MaybeFreeReward?) and Offset * 4 + (I + 1)}))
        }

    Reset() : void =
        set CurrentPage = 1
        for ( Widget : FreeRewardWidgets) do Widget.Reset()
        for ( Widget : PremiumRewardWidgets) do Widget.Reset()
        UIResetEvent.Signal()

    SetPage(Page : int) : void = set CurrentPage = Page
    GetCanvas<public>() : canvas = Canvas
    GetRootWidget<public>() : widget = RootWidget

    CreateRootWidget() : overlay = 
        PremiumSlots := for ( Widget : PremiumRewardWidgets) do stack_box_slot{Widget := Widget.GetRootWidget(), HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Right := 20.0}}
        FreeSlots := for ( Widget : FreeRewardWidgets) do stack_box_slot{Widget := Widget.GetRootWidget(), HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Right := 20.0}}
        LevelTierSlots := for ( Widget : TierLevelWidgets) do stack_box_slot{Widget := Widget.GetRootWidget(), HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Left := 96.0, Right := 116.0}}
        overlay:
            Slots := array:
                overlay_slot: <# XP Progress Widget #>
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Left := 235.0, Top := 235.0}
                    Widget := XPWidget.GetRootWidget()
                    
                overlay_slot: <# Overlay Image #>
                    Widget := texture_block{DefaultImage := SeasonPassUI.T_Season_Pass_Overlay, DefaultDesiredSize := vector2{ X := 1920.0, Y := 1080.0}}

                overlay_slot: <# Next Level Widget #>
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Left := 734.0, Top := 228.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := color_block{DefaultDesiredSize := vector2{ X := 64.0, Y := 64.0}, DefaultOpacity := 0.0}
                            overlay_slot:
                                Widget := NextLevelTextBlock

                overlay_slot: <# Main Rows #>
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Left := 600.0, Top := 360.0}
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := array: 
                            stack_box_slot: <# Premum Rewards #>
                                HorizontalAlignment := horizontal_alignment.Left
                                VerticalAlignment := vertical_alignment.Top
                                Padding := margin{Bottom := 45.0}
                                Widget := stack_box:
                                    Orientation := orientation.Horizontal
                                    Slots := PremiumSlots

                            stack_box_slot: <# Level tier widgets #>
                                HorizontalAlignment := horizontal_alignment.Left
                                VerticalAlignment := vertical_alignment.Top
                                Padding := margin{Bottom := 25.0}
                                Widget := stack_box:
                                    Orientation := orientation.Horizontal
                                    Slots := LevelTierSlots
                                
                            stack_box_slot: <# Free Rewards #>
                                HorizontalAlignment := horizontal_alignment.Left
                                VerticalAlignment := vertical_alignment.Top
                                Widget := stack_box:
                                    Orientation := orientation.Horizontal
                                    Slots := FreeSlots

                overlay_slot: <# Activate Premium Button #>
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{ Left := 1250.0, Top := 190.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := ActivatePremiumTextureBlock
                            overlay_slot:
                                Widget := ActivatePremiumButton
                                HorizontalAlignment := horizontal_alignment.Fill
                                VerticalAlignment := vertical_alignment.Fill
                                Padding := margin{Left := 75.0, Top := 25.0, Right := 75.0, Bottom := 25.0}

                overlay_slot: <# Exit Button #>
                    HorizontalAlignment := horizontal_alignment.Right
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Right := 140.0, Top := 75.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := texture_block{DefaultImage := SeasonPassUI.T_Exit_Button, DefaultDesiredSize := vector2{ X := 128.0, Y := 128.0}}
                            overlay_slot:
                                Widget := ExitButton
                                HorizontalAlignment := horizontal_alignment.Fill
                                VerticalAlignment := vertical_alignment.Fill
                                Padding := margin{Left := 10.0, Top := 10.0, Right := 10.0, Bottom := 10.0}


                overlay_slot: <# Back Page Button#>
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Left := 20.0, Top := 495.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot: <# Sizing purposes #>
                                Widget := color_block{DefaultDesiredSize := vector2{ X := 165.0, Y := 350.0 }, DefaultOpacity := 0.0}
                            overlay_slot: <# Previous Page Button #>
                                HorizontalAlignment := horizontal_alignment.Fill
                                VerticalAlignment := vertical_alignment.Fill
                                Widget := BackPageButton

                overlay_slot: <# Next Page Button#>
                    HorizontalAlignment := horizontal_alignment.Right
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Right := 20.0, Top := 495.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot: <# Sizing purposes #>
                                Widget := color_block{DefaultDesiredSize := vector2{ X := 165.0, Y := 350.0 }, DefaultOpacity := 0.0}
                            overlay_slot: <# Previous Page Button #>
                                HorizontalAlignment := horizontal_alignment.Fill
                                VerticalAlignment := vertical_alignment.Fill
                                Widget := NextPageButton
                      
<# Reward Widget #>
season_pass_reward_widget := class:
    RewardNameTextBlock : text_block = text_block{DefaultTextColor := NamedColors.White, DefaultOverflowPolicy := text_overflow_policy.Ellipsis}
    BackgroundTextureBlock : texture_block = texture_block{DefaultImage := SeasonPassUI.T_Reward_Overlay_Free, DefaultDesiredSize := vector2{ X := 256.0, Y := 256.0}}
    RewardTextureBlock : texture_block = texture_block{DefaultImage := SeasonPassUI.T_Reward_Default, DefaultDesiredSize := vector2{ X := 165.0, Y := 165.0}}
    ClaimTextureBlock : texture_block = texture_block{DefaultImage := SeasonPassUI.T_Button_Locked, DefaultDesiredSize := vector2{ X := 256.0, Y := 64.0}}
    ClaimButton : text_button_base = button_quiet{}

    WidgetResetEvent : event() = event(){}
    ClaimAnimationStartedEvent : event(color) = event(color){}
    ClaimAnimationStoppedEvent : event() = event(){}

    var RootWidget : widget = overlay{}

    UniqueBegin(BackgroundImage : texture, RewardTextColor : color) : void =
        RewardNameTextBlock.SetTextColor(RewardTextColor)
        BackgroundTextureBlock.SetImage(BackgroundImage)
        set RootWidget = overlay:
            Slots := array:
                overlay_slot:
                    Widget := BackgroundTextureBlock
                overlay_slot:
                    Widget := RewardTextureBlock
                overlay_slot:
                    VerticalAlignment := vertical_alignment.Bottom
                    Padding := margin{Bottom := -15.0}
                    Widget := overlay:
                        Slots := array:
                            overlay_slot:
                                Widget := ClaimTextureBlock
                            overlay_slot:
                                Widget := ClaimButton
                                HorizontalAlignment := horizontal_alignment.Fill
                                VerticalAlignment := vertical_alignment.Fill
                                Padding := margin{Left := 15.0, Right := 15.0}
                overlay_slot:
                    Widget := RewardNameTextBlock
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Top := 10.0}

    Init() : void = spawn{Update()}
                            
    UpdateRewardInfo(MaybeReward : ?season_pass_reward, IsPassPremium : logic) : void =
        if ( Reward := MaybeReward?):
            RewardTextureBlock.SetVisibility(widget_visibility.Visible)
            ClaimButton.SetVisibility(widget_visibility.Visible)
            RewardNameTextBlock.SetText(StringToMessage(Reward.GetName()))
            RewardTextureBlock.SetImage(Reward.GetImage())
            case(Reward.GetClaimStatus()):
                season_pass_reward_claim_status.Locked => <# Locked Reward #>
                    ClaimTextureBlock.SetImage(SeasonPassUI.T_Button_Locked)
                    BackgroundTextureBlock.SetTint(color{ R := 0.35, G := 0.35, B := 0.35})
                    RewardTextureBlock.SetTint(color{ R := 0.35, G := 0.35, B := 0.35})
                    ClaimAnimationStoppedEvent.Signal()

                season_pass_reward_claim_status.Unlocked => <# Unlocked Reward #>
                    ClaimTextureBlock.SetImage(SeasonPassUI.T_Button_Claim)
                    if ( Reward.GetTier() = reward_tier.Premium):
                        if ( IsPassPremium?):
                            RewardTextureBlock.SetTint(NamedColors.White)
                            ClaimAnimationStartedEvent.Signal(NamedColors.Red)
                        else:
                            ClaimAnimationStoppedEvent.Signal()
                            BackgroundTextureBlock.SetTint(color{ R := 0.35, G := 0.35, B := 0.35})
                            RewardTextureBlock.SetTint(color{ R := 0.35, G := 0.35, B := 0.35})
                    else:
                        RewardTextureBlock.SetTint(NamedColors.White)
                        ClaimAnimationStartedEvent.Signal(NamedColors.Blue)

                season_pass_reward_claim_status.Claimed =>  <# Claimed Reward #>
                    ClaimTextureBlock.SetImage(SeasonPassUI.T_Button_Claimed)
                    BackgroundTextureBlock.SetTint(NamedColors.White)
                    RewardTextureBlock.SetTint(NamedColors.White)
                    ClaimAnimationStoppedEvent.Signal()
                    
        else:
            RewardTextureBlock.SetVisibility(widget_visibility.Hidden)
            ClaimButton.SetVisibility(widget_visibility.Hidden)

    StopClaimAnimation() : void = ClaimAnimationStoppedEvent.Signal()

    Update()<suspends> : void =
        race:
            WidgetResetEvent.Await()
            PollClaimAnimationEvents()

    PollClaimAnimationEvents()<suspends> : void = 
        defer{BackgroundTextureBlock.SetTint(NamedColors.White)}
        Intervals := 30
        IntervalsF := Intervals * 1.0
        loop:
            TargetColor := ClaimAnimationStartedEvent.Await()
            race:
                ClaimAnimationStoppedEvent.Await()
                block:
                    var Interval : int = 0
                    var Delta : int = 1
                    loop:
                        Color := Lerp(NamedColors.White, TargetColor, 0.5 * (1.0 + Sin(3.0 * GetSimulationElapsedTime())))
                        BackgroundTextureBlock.SetTint(Color)
                        Sleep(0.0)
                        


    Reset() : void = 
        WidgetResetEvent.Signal()
        ClaimAnimationStoppedEvent.Signal()

    SetRewardBackgroundTint(Color : color) : void = BackgroundTextureBlock.SetTint(Color)
    SetRewardImageTint(Color : color) : void = RewardTextureBlock.SetTint(Color)

    SetRewardBackround(Image : texture) : void = BackgroundTextureBlock.SetImage(Image)
    SetRewardImage(Image : texture) : void = RewardTextureBlock.SetImage(Image)
    SetClaimImage(Image : texture) : void = ClaimTextureBlock.SetImage(Image)
    OnClaim() : void = ClaimTextureBlock.SetImage(SeasonPassUI.T_Button_Claimed)

    GetRootWidget() : widget = RootWidget

<# Player Level Widget #>
season_pass_tier_level_widget := class:
    TextBlock : text_block = text_block{DefaultTextColor := NamedColors.White}
    TextureBlock : texture_block = texture_block{DefaultImage := SeasonPassUI.T_Tier_Icon_Locked, DefaultDesiredSize := vector2{ X := 64.0, Y := 64.0}}
    var RootWidget : widget = overlay{}

    UniqueBegin() : void =
        set RootWidget = overlay:
            Slots := array:
                overlay_slot:
                    Widget := TextureBlock
                overlay_slot:
                    Widget := TextBlock
                    

    SetLevel<public>(MaybeLevel : ?int) : void = 
        if ( Level := MaybeLevel?):
            RootWidget.SetVisibility(widget_visibility.Visible)
            TextBlock.SetText(StringToMessage("{Level}"))
        else:
            RootWidget.SetVisibility(widget_visibility.Hidden)

    SetLockedStats<public>(IsLocked : logic) : void = TextureBlock.SetImage(IsLocked? and SeasonPassUI.T_Tier_Icon_Locked or SeasonPassUI.T_Tier_Icon_Unlocked)

    GetRootWidget<public>()<transacts> : widget = RootWidget

<# XP Progress Bar Widget #>
season_pass_xp_widget := class:
    TextBlock : text_block = text_block{DefaultTextColor := NamedColors.White}
    BackgroundColorBlock : color_block = color_block{DefaultDesiredSize := vector2{ X := 500.0, Y := 50.0}, DefaultColor := MakeColorFromHex("563C05FF")}
    ForegroundColorBlock : color_block = color_block{DefaultDesiredSize := vector2{ X := 0.0, Y := 50.0}, DefaultColor := MakeColorFromHex("FFCF38FF")}

    var RootWidget : widget = overlay{}

    UniqueBegin() : void =
        set RootWidget = overlay:
            Slots := array:
                overlay_slot:
                    HorizontalAlignment := horizontal_alignment.Left
                    Widget := BackgroundColorBlock
                overlay_slot:
                    HorizontalAlignment := horizontal_alignment.Left
                    Widget := ForegroundColorBlock
                overlay_slot:
                    Widget := TextBlock

    SetProgress(CurrentXP : int, TargetXP : int) : void =
        MaxSize := BackgroundColorBlock.GetDesiredSize()
        Percentage := Max((1.0 * CurrentXP) / (1.0 * TargetXP), 0.0)
        Size := vector2:
            X := MaxSize.X * Percentage
            Y := MaxSize.Y
        ForegroundColorBlock.SetDesiredSize(Size)
        TextBlock.SetText(StringToMessage("{CurrentXP} / {TargetXP}"))

    GetRootWidget() : widget = RootWidget