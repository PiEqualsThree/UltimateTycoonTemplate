using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { UIStuff }
using { Managers }

season_pass_reward<public> := class<concrete>:
    @editable       Name : string = "Reward"
    @editable       ItemReward : ?reward_item_component = false
    @editable       AuraReward : ?reward_aura_component = false
    @editable       PerkReward : ?reward_perk_component = false
    @editable       VehicleReward : ?reward_vehicle_component = false
    @editable       CosmeticReward : ?reward_vfx_cosmetic_component = false
    @editable       BlingBucksReward : ?reward_bling_bucks_component = false
    

    var ID : int = -1
    var Tier : reward_tier = reward_tier.Free
    var RewardTierString : string = ""
    var Image : texture = SeasonPassUI.T_Reward_Default
    var ClaimStatus : season_pass_reward_claim_status = season_pass_reward_claim_status.Locked

    UniqueBegin<public>(RewardImage : texture, RewardID : int, RewardTier : reward_tier) : void =
        set Image = RewardImage
        set Tier = RewardTier
        set RewardTierString = Tier = reward_tier.Premium and "Premium" or "Free"
        if ( Reward := ItemReward?) then Reward.UniqueBegin() 
        if ( Reward := VehicleReward?) then Reward.UniqueBegin() 
        if ( Reward := CosmeticReward?) then Reward.UniqueBegin() 


    Init(RewardIndex : int) : void =
        set ID = RewardIndex
        if ( Reward := ItemReward?) then { Reward.Init(); Print("Initing {RewardTierString} Reward {ID} - Item Granter Reward")}
        if ( Reward := AuraReward?) then { Reward.Init(); Print("Initing {RewardTierString} Reward {ID} - Aura Reward")}
        if ( Reward := PerkReward?) then { Reward.Init(); Print("Initing {RewardTierString} Reward {ID} - Perk Reward")}
        if ( Reward := VehicleReward?) then { Reward.Init(); Print("Initing {RewardTierString} Reward {ID} - Vehicle Reward")}
        if ( Reward := CosmeticReward?) then { Reward.Init(); Print("Initing {RewardTierString} Reward {ID} - Cosmetic Reward")}
        if ( Reward := BlingBucksReward?) then { Reward.Init(); Print("Initing {RewardTierString} Reward {ID} - Bling Bucks Reward")}

    Unlock() : void =
        set ClaimStatus = season_pass_reward_claim_status.Unlocked

    Claim(Owner : custom_player, TycoonManager : tycoon_manager, Pass : season_pass) : void =
        set ClaimStatus = season_pass_reward_claim_status.Claimed
        if ( Reward := ItemReward?) then { Reward.Claim(Owner, TycoonManager, Pass); Print("Claiming {RewardTierString} Reward {ID} - Item Granter Reward")}
        if ( Reward := AuraReward?) then { Reward.Claim(Owner, TycoonManager, Pass); Print("Claiming {RewardTierString} Reward {ID} - Aura Reward")}
        if ( Reward := PerkReward?) then { Reward.Claim(Owner, TycoonManager, Pass); Print("Claiming {RewardTierString} Reward {ID} - Perk Reward")}
        if ( Reward := VehicleReward?) then { Reward.Claim(Owner, TycoonManager, Pass); Print("Claiming {RewardTierString} Reward {ID} - Vehicle Reward")}
        if ( Reward := CosmeticReward?) then { Reward.Claim(Owner, TycoonManager, Pass); Print("Claiming {RewardTierString} Reward {ID} - Cosmetic Reward")}
        if ( Reward := BlingBucksReward?) then { Reward.Claim(Owner, TycoonManager, Pass); Print("Claiming {RewardTierString} Reward {ID} - Bling Bucks Reward")}

    Reset() : void =
        set ClaimStatus = season_pass_reward_claim_status.Locked
        if ( Reward := ItemReward?) then { Reward.Reset(); Print("Resetting {RewardTierString} Reward {ID} - Item Granter Reward")}
        if ( Reward := AuraReward?) then { Reward.Reset(); Print("Resetting {RewardTierString} Reward {ID} - Aura Reward")}
        if ( Reward := PerkReward?) then { Reward.Reset(); Print("Resetting {RewardTierString} Reward {ID} - Perk Reward")}
        if ( Reward := VehicleReward?) then { Reward.Reset(); Print("Resetting {RewardTierString} Reward {ID} - Vehicle Reward")}
        if ( Reward := CosmeticReward?) then { Reward.Reset(); Print("Resetting {RewardTierString} Reward {ID} - Cosmetic Reward")}
        if ( Reward := BlingBucksReward?) then { Reward.Reset(); Print("Resetting {RewardTierString} Reward {ID} - Bling Bucks Reward")}

    GetName<public>()<transacts> : string = Name
    GetImage<public>()<transacts> : texture = Image
    GetTier<public>()<transacts> : reward_tier = Tier
    GetClaimStatus<public>()<transacts> : season_pass_reward_claim_status = ClaimStatus

season_pass_reward_claim_status<public> := enum:
    Locked
    Unlocked
    Claimed

reward_tier<public> := enum:
    Free
    Premium
    
using { UIStuff.SeasonPassUI}
# using { SeasonPassUI.FreeRewards}
# using { SeasonPassUI.PremiumRewards}

FreeRewardImages<public> : []texture = array:
#     T_Free_Reward_1
#     T_Free_Reward_2
#     T_Free_Reward_3
#     T_Free_Reward_4
#     T_Free_Reward_5
#     T_Free_Reward_6
#     T_Free_Reward_7
#     T_Free_Reward_8
#     T_Free_Reward_9
#     T_Free_Reward_10
#     T_Free_Reward_11
#     T_Free_Reward_12
#     T_Free_Reward_13
#     T_Free_Reward_14
#     T_Free_Reward_15
#     T_Free_Reward_16
#     T_Free_Reward_17
#     T_Free_Reward_18
#     T_Free_Reward_19
#     T_Free_Reward_20

PremiumRewardImages<public> : []texture = array:
#     T_Premium_Reward_1
#     T_Premium_Reward_2
#     T_Premium_Reward_3
#     T_Premium_Reward_4
#     T_Premium_Reward_5
#     T_Premium_Reward_6
#     T_Premium_Reward_7
#     T_Premium_Reward_8
#     T_Premium_Reward_9
#     T_Premium_Reward_10
#     T_Premium_Reward_11
#     T_Premium_Reward_12
#     T_Premium_Reward_13
#     T_Premium_Reward_14
#     T_Premium_Reward_15
#     T_Premium_Reward_16
#     T_Premium_Reward_17
#     T_Premium_Reward_18
#     T_Premium_Reward_19
#     T_Premium_Reward_20




    

