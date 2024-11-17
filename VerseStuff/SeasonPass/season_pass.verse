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
using { Managers }
using { UIStuff }

season_pass<public> := class<concrete>:
    @editable       InteractButton : button_device = button_device{}
    @editable       PremiumRewards : []season_pass_reward = array{}
    @editable       FreeRewards : []season_pass_reward = array{}
    @editable       AudioSettings : season_pass_audio_settings = season_pass_audio_settings{}

    var MaybeFreeRewards : []?season_pass_reward = array{}
    var MaybePremiumRewards : []?season_pass_reward = array{}

    SeasonPassResetEvent : event() = event(){}
    UI : season_pass_ui = season_pass_ui{}
    PremiumKeypad : custom_keypad = custom_keypad{Password := "9091307"}

    var IsPremium : logic = false

    UniqueBegin<public>()<suspends> : void =
        PremiumKeypad.UniqueBegin(?TextColor := MakeColorFromHex("865500FF"))
        PremiumKeypad.GetWidget().GetCanvas().AddWidget(
            canvas_slot:
                Anchors := anchors{Minimum := vector2{ X := 1.0, Y := 0.0}, Maximum := vector2{ X := 1.0, Y := 0.0}}
                Alignment := vector2{ X := 1.0, Y := 0.0}
                Offsets := margin{Top := 70.0, Left := -150.0}
                SizeToContent := true
                Widget := stack_box:
                    Orientation := orientation.Vertical
                    Slots := array:
                        stack_box_slot{ Widget := texture_block{DefaultImage := SeasonPassUI.T_Discord_Banner    , DefaultDesiredSize := vector2{ X := 512.0, Y := 128.0}}, VerticalAlignment := vertical_alignment.Top, Padding := margin{Bottom := 25.0}}
                        stack_box_slot{ Widget := texture_block{DefaultImage := SeasonPassUI.T_Premium_Banner    , DefaultDesiredSize := vector2{ X := 512.0, Y := 128.0}}, VerticalAlignment := vertical_alignment.Top, Padding := margin{Bottom := 25.0}} 
        )
        Sleep(0.0)
        UI.UniqueBegin()
        Sleep(0.0)
        <# Init premium rewards optional array #>
        for ( Index->Reward : PremiumRewards):
            if ( Mod[Index, 5] = 0) then Sleep(0.0)
            if ( Reward.ItemReward? or Reward.AuraReward? or Reward.PerkReward? or Reward.BlingBucksReward? or Reward.CosmeticReward? or Reward.VehicleReward?):
                set MaybePremiumRewards = MaybePremiumRewards + array{option{Reward}}
                Reward.UniqueBegin(PremiumRewardImages[Index] or SeasonPassUI.T_Reward_Default, Index, reward_tier.Premium)
            else:
                NullReward : ?season_pass_reward = false
                set MaybePremiumRewards = MaybePremiumRewards + array{NullReward}
            
        <# Init free rewards optional array #>
        for ( Index->Reward : FreeRewards):
            if ( Mod[Index, 5] = 0) then Sleep(0.0)
            if ( Reward.ItemReward? or Reward.AuraReward? or Reward.PerkReward? or Reward.BlingBucksReward? or Reward.CosmeticReward? or Reward.VehicleReward?):
                set MaybeFreeRewards = MaybeFreeRewards + array{option{Reward}}
                Reward.UniqueBegin(FreeRewardImages[Index] or SeasonPassUI.T_Reward_Default, Index, reward_tier.Free)
            else:
                NullReward : ?season_pass_reward = false
                set MaybeFreeRewards = MaybeFreeRewards + array{NullReward}

    Init<public>()<suspends> : void =  
        for ( Index->MaybeReward : MaybeFreeRewards, Reward := MaybeReward?):
            if ( Mod[Index, 10] = 0) then Sleep(0.0)
            Reward.Init(Index)
        for ( Index->MaybeReward : MaybePremiumRewards, Reward := MaybeReward?):
            if ( Mod[Index, 10] = 0) then Sleep(0.0)
            Reward.Init(Index)
        PremiumKeypad.Init(audio_player_device{}, audio_player_device{})
        UI.Init()

    LoadData<public>(Owner : custom_player, TycoonManager : tycoon_manager, PlayerStats : player_stats)<suspends> : void =
        SeasonPassStats := PlayerStats.SeasonPassStats
        
        if ( SeasonPassStats.IsPremium? or Owner.Rebirths >= 10) then UpgradeToPremium()
        

        Print("Loading battle pass {Owner.TycoonLevel.GetLevel()} Levels unlocked!")
        for ( I := 1..Owner.TycoonLevel.GetLevel()):
            if ( FreeReward := MaybeFreeRewards[I - 1]?) then FreeReward.Unlock()
            if ( PremiumReward := MaybePremiumRewards[I - 1]?) then PremiumReward.Unlock()
            Sleep(0.0)
        for ( ID : SeasonPassStats.ClaimedFreeRewardIDs, Reward := MaybeFreeRewards[ID]?, not Reward.BlingBucksReward?):
            Reward.Claim(Owner, TycoonManager, Self)
            if ( Mod[ID, 7] = 0) then Sleep(0.0)
            
        for ( ID : SeasonPassStats.ClaimedPremiumRewardIDs, Reward := MaybePremiumRewards[ID]?, not Reward.BlingBucksReward?):
            Reward.Claim(Owner, TycoonManager, Self)
            if ( Mod[ID, 7] = 0) then Sleep(0.0)

        spawn{PollEvents(Owner, TycoonManager)}

    UpgradeToPremium<public>() : void =
        set IsPremium = true

    PollEvents(Owner : custom_player, TycoonManager : tycoon_manager)<suspends> : void =
        defer{UI.Remove(Owner)}
        race:
            SeasonPassResetEvent.Await()
            loop:
                Agent := InteractButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    UI.Display(Owner, Self)
                    AwaitUIEvents(Owner, TycoonManager)
                    UI.Remove(Owner)
            loop:
                Level := Owner.TycoonLevel.LeveledUpEvent.Await()
                Print("Reached level: {Level}")
                if ( UnlockedReward := MaybePremiumRewards[Level - 1]?) then UnlockedReward.Unlock()
                if ( UnlockedReward := MaybeFreeRewards[Level - 1]?) then UnlockedReward.Unlock()

    AwaitUIEvents(Owner : custom_player, TycoonManager : tycoon_manager)<suspends> : void =
        race:
            Owner.FortCharacter.EliminatedEvent().Await()
            SeasonPassResetEvent.Await()
            UI.ExitButton.OnClick().Await()
            AwaitRewardButtonClick(Owner, TycoonManager, reward_tier.Premium, 0)
            AwaitRewardButtonClick(Owner, TycoonManager, reward_tier.Premium, 1)
            AwaitRewardButtonClick(Owner, TycoonManager, reward_tier.Premium, 2)
            AwaitRewardButtonClick(Owner, TycoonManager, reward_tier.Premium, 3)
            AwaitRewardButtonClick(Owner, TycoonManager, reward_tier.Free, 0)
            AwaitRewardButtonClick(Owner, TycoonManager, reward_tier.Free, 1)
            AwaitRewardButtonClick(Owner, TycoonManager, reward_tier.Free, 2)
            AwaitRewardButtonClick(Owner, TycoonManager, reward_tier.Free, 3)
            loop: <# Keypad thing #>
                UI.ActivatePremiumButton.OnClick().Await()
                if ( not IsPremium?):
                    UI.Remove(Owner)
                    AwaitPremiumActivate(Owner)
                    break
                else:
                    Print("Already premium!")

            loop: <# Back page pressed #>
                UI.BackPageButton.OnClick().Await()
                if ( UI.CurrentPage > 1):
                    UI.SetPage(UI.CurrentPage - 1)
                    UI.RefreshPage(Owner, Self)
            loop: <# Next page pressed #>
                UI.NextPageButton.OnClick().Await()
                if ( UI.CurrentPage * 4 < PremiumRewards.Length):
                    UI.SetPage(UI.CurrentPage + 1)
                    UI.RefreshPage(Owner, Self)

    AwaitRewardButtonClick(Owner : custom_player, TycoonManager : tycoon_manager, RewardTier : reward_tier, ButtonIndex : int)<suspends> : void =
        RewardWidgets := (RewardTier = reward_tier.Premium) and UI.PremiumRewardWidgets or UI.FreeRewardWidgets
        MaybeRewards := (RewardTier = reward_tier.Premium) and MaybePremiumRewards or MaybeFreeRewards
        Button := RewardWidgets[ButtonIndex].ClaimButton or button_quiet{}
        loop:
            Button.OnClick().Await()
            RewardIndex := 4 * (UI.CurrentPage - 1) + ButtonIndex
            if ( Reward := MaybeRewards[RewardIndex]?):
                case(Reward.GetClaimStatus()):
                    season_pass_reward_claim_status.Locked => 
                        Print("Reward {RewardIndex} is locked!")
                        AudioSettings.RewardLocked.Play(Owner.Player)

                    season_pass_reward_claim_status.Unlocked => 
                        if ( IsPremium? or RewardTier = reward_tier.Free):
                            Audio := RewardTier = reward_tier.Premium and AudioSettings.PremiumRewardClaimed or AudioSettings.FreeRewardClaimed
                            Audio.Play(Owner.Player)
                            Print("Claiming {RewardIndex}!")
                            Reward.Claim(Owner, TycoonManager, Self)
                            UI.RefreshPage(Owner, Self)
                        else:
                            Print("You need premium for {RewardIndex}")
                            AudioSettings.RewardLocked.Play(Owner.Player)

                    season_pass_reward_claim_status.Claimed => 
                        Print("Reward {RewardIndex} already claimed!")

    AwaitPremiumActivate(Owner : custom_player)<suspends> : void =
        Sleep(0.0)
        defer{PremiumKeypad.Remove(Owner)}
        PremiumKeypad.Display(Owner)
        race:
            ResetEvent().Await()
            PremiumKeypad.ExitEvent.Await()
            block:
                PremiumKeypad.SuccessEvent.Await()
                AudioSettings.SeasonPassUpgradeSuccess.Play(Owner.Player)
                UpgradeToPremium()
                
                Print("Enabled premium!")
            loop:
                PremiumKeypad.FailedEvent.Await()
                AudioSettings.SeasonPassUpgradeFail.Play(Owner.Player)
                Print("Incorrect code!")

    GetStats<public>()<suspends> : season_pass_stats =
        var ClaimedFreeRewardIDs : []int = array{}
        var ClaimedPremiumRewardIDs : []int = array{}
        for ( ID->MaybeReward : MaybeFreeRewards, Reward := MaybeReward?):
            if ( Reward.GetClaimStatus() = season_pass_reward_claim_status.Claimed) then set ClaimedFreeRewardIDs = ClaimedFreeRewardIDs + array{ID}
            if ( Mod[ID, 8] = 0) then Sleep(0.0)
        for ( ID->MaybeReward : MaybePremiumRewards, Reward := MaybeReward?):
            if ( Reward.GetClaimStatus() = season_pass_reward_claim_status.Claimed) then set ClaimedPremiumRewardIDs = ClaimedPremiumRewardIDs + array{ID}
            if ( Mod[ID, 8] = 0) then Sleep(0.0)
        season_pass_stats:
            IsPremium := IsPremium
            ClaimedFreeRewardIDs := ClaimedFreeRewardIDs
            ClaimedPremiumRewardIDs := ClaimedPremiumRewardIDs

            
    Reset<public>()<suspends> : void = 
        set IsPremium = false
        SeasonPassResetEvent.Signal()
        UI.Reset()
        for ( Index->MaybeReward : MaybeFreeRewards, Reward := MaybeReward?):
            if ( Mod[Index, 7] = 0) then Sleep(0.0)
            Reward.Reset()
        for ( Index->MaybeReward : MaybePremiumRewards, Reward := MaybeReward?):
            if ( Mod[Index, 7] = 0) then Sleep(0.0)
            Reward.Reset()
            
    ResetEvent<public>() : event() = SeasonPassResetEvent
            
season_pass_audio_settings := class<concrete>:
    @editable       PremiumRewardClaimed : audio_player_device = audio_player_device{}
    @editable       FreeRewardClaimed : audio_player_device = audio_player_device{}
    @editable       RewardLocked : audio_player_device = audio_player_device{}
    @editable       SeasonPassUpgradeSuccess : audio_player_device = audio_player_device{}
    @editable       SeasonPassUpgradeFail : audio_player_device = audio_player_device{}
    
    