using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { CustomUI }
using { UIStuff.RebirthUI}
using { UIStuff.SeasonPassUI}
using { UIStuff.PerksUI}
using { UIStuff.CosmeticsUI.Auras}

rebirth_manager<public> := class:
    RebirthConfirmWidget : rebirth_confirmation_widget = rebirth_confirmation_widget{}

    UniqueBegin() : void =
        RebirthConfirmWidget.UniqueBegin()

    LoadData(CustomPlayer : custom_player, TycoonManager : tycoon_manager, PlayerStats : player_stats)<suspends> : void =
        CurrencyMultiplier := Min(1.0 + CustomPlayer.Rebirths * 0.2, 4.0)
        CustomPlayer.SetCurrencyMultiplier(CurrencyMultiplier)
        if ( CustomPlayer.Rebirths = 10) then TycoonManager.CosmeticsManager.UnlockAura(CustomPlayer, 24)
        if ( CustomPlayer.Rebirths > 0) then TycoonManager.PerksManager.SetPerkLevel(2, Min(CustomPlayer.Rebirths, 10))

    HandleRebirthButtonInteraction(CustomPlayer : custom_player)<suspends> : logic =
        RewardDataArray := if ( RebirthRewardDataArray := RebirthRewards[CustomPlayer.Rebirths + 1]):
            RebirthRewardDataArray
        else:
            array{rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}}

        RebirthConfirmWidget.Show(CustomPlayer, RewardDataArray)
        return race:
            block:
                CustomPlayer.FortCharacter.EliminatedEvent().Await()
                false
            block:
                RebirthConfirmWidget.RebirthAcceptedEvent.Await()
                true
            block:
                RebirthConfirmWidget.RebirthDeniedEvent.Await()
                false

RebirthRewards : [int][]rebirth_reward_data = map:
    1 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+20% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+20% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
        rebirth_reward_data{Name := "Cashback Lv.1", Image := T_Perk_Icon_Cashback, TextColor := MakeColorFromHex("F2DB00FF")}
    2 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+40% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+40% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
        rebirth_reward_data{Name := "Cashback Lv.2", Image := T_Perk_Icon_Cashback, TextColor := MakeColorFromHex("F2DB00FF")}
    3 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+60% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+60% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
        rebirth_reward_data{Name := "Cashback Lv.3", Image := T_Perk_Icon_Cashback, TextColor := MakeColorFromHex("F2DB00FF")}
    4 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+80% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+80% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
        rebirth_reward_data{Name := "Cashback Lv.4", Image := T_Perk_Icon_Cashback, TextColor := MakeColorFromHex("F2DB00FF")}
    5 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+100% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+100% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
        rebirth_reward_data{Name := "Cashback Lv.5", Image := T_Perk_Icon_Cashback, TextColor := MakeColorFromHex("F2DB00FF")}
    6 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+120% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+120% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
        rebirth_reward_data{Name := "Cashback Lv.6", Image := T_Perk_Icon_Cashback, TextColor := MakeColorFromHex("F2DB00FF")}
    7 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+140% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+140% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
        rebirth_reward_data{Name := "Cashback Lv.7", Image := T_Perk_Icon_Cashback, TextColor := MakeColorFromHex("F2DB00FF")}
    8 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+160% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+160% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
        rebirth_reward_data{Name := "Cashback Lv.8", Image := T_Perk_Icon_Cashback, TextColor := MakeColorFromHex("F2DB00FF")}
    9 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+180% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+180% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
        rebirth_reward_data{Name := "Cashback Lv.9", Image := T_Perk_Icon_Cashback, TextColor := MakeColorFromHex("F2DB00FF")}
    10 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+200% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+200% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
        rebirth_reward_data{Name := "Cashback Lv.10", Image := T_Perk_Icon_Cashback, TextColor := MakeColorFromHex("F2DB00FF")}
        rebirth_reward_data{Name := "Super Aura", Image := T_Aura_Super, TextColor := MakeColorFromHex("FE2A00FF")}
    11 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+220% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+220% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
    12 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+240% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+240% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}    
    13 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+260% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+260% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
    14 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+280% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+280% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
    15 => array:
        rebirth_reward_data{Name := "Instant Save!", Image := T_Rebirth_Reward_Save, TextColor := MakeColorFromHex("6DFF00FF")}
        rebirth_reward_data{Name := "+300% Cash", Image := T_Rebirth_Reward_Extra_Cash, TextColor := MakeColorFromHex("56FF00FF")}
        rebirth_reward_data{Name := "+300% Candy", Image := T_Rebirth_Reward_Extra_Candy, TextColor := MakeColorFromHex("FFC000FF")}
        
rebirth_reward_data<public> := class<computes>:
    Name<public> : string
    Image<public> : texture
    TextColor<public> : color