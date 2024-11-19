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

    SetClaimStatus<public>(RewardClaimStatus : season_pass_reward_claim_status)<transacts> : void = set ClaimStatus = RewardClaimStatus
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
using { UIStuff.SeasonPassUI.FreeRewards}
using { UIStuff.SeasonPassUI.PremiumRewards}
using { UIStuff.CosmeticsUI.Auras }
using { UIStuff.CurrencyUI }
using { UIStuff.PerksUI }
FreeRewardImages<public> : []texture = array:
    <# 0#>T_Perk_Icon_Refund
    <# 1#>T_Bling_Bucks
    <# 2#>T_Bling_Bucks
    <# 3#>T_Perk_Icon_Refund
    <# 4#>T_Warforged_AR
    <# 5#>T_Cosmetic_Pirate_Hat
    <# 6#>T_Perk_Icon_Refund
    <# 7#>T_Bling_Bucks 
    <# 8#>T_Aura_Basic_Green
    <# 9#>T_Shockwave_Grenades
    <#10#>T_Bling_Bucks
    <#11#>T_Perk_Icon_Refund
    <#12#>T_Aura_Basic_Blue
    <#13#>T_Bling_Bucks 
    <#14#>T_Shockwave_Grenades 
    <#15#>T_Bling_Bucks
    <#16#>T_Perk_Icon_Refund
    <#17#>T_Aura_Basic_Pink
    <#18#>T_Bling_Bucks 
    <#19#>T_Dual_Micro_SMG 
    <#20#>T_Perk_Icon_Refund 
    <#21#>T_Cosmetic_Panda_Mask
    <#22#>T_Bling_Bucks
    <#23#>T_Aura_Basic_Gold
    <#24#>T_Perk_Icon_Refund 
    <#25#>T_Bling_Bucks
    <#26#>T_Shockwave_Bow
    <#27#>T_Bling_Bucks
    <#28#>T_Bling_Bucks
    <#29#>T_Perk_Icon_Refund
    <#30#>T_Aura_Basic_Red
    <#31#>T_Bling_Bucks
    <#32#>T_Jetpack
    <#33#>T_Bling_Bucks
    <#34#>T_Bling_Bucks
    <#35#>T_Perk_Icon_Refund
    <#36#>T_Bling_Bucks
    <#37#>T_Grapple_Glove
    <#38#>T_Perk_Icon_Refund
    <#39#>T_Aura_Halo


PremiumRewardImages<public> : []texture = array:
    <# 0#>T_Perk_Icon_Supercharged
    <# 1#>T_Grappler
    <# 2#>T_Aura_Portal_White
    <# 3#>T_Perk_Icon_Supercharged
    <# 4#>T_Cybertruck
    <# 5#>T_Aura_Portal_Green
    <# 6#>T_Witch_Broom
    <# 7#>T_Perk_Icon_Supercharged
    <# 8#>T_Aura_Portal_Blue
    <# 9#>T_Pumpkin_Launcher
    <#10#>T_Corvette
    <#11#>T_Perk_Icon_Supercharged
    <#12#>T_Cosmetic_Llama_Mask
    <#13#>T_Aura_Portal_Pink
    <#14#>T_Nitro_Fists
    <#15#>T_Perk_Icon_Supercharged
    <#16#>T_Aura_Portal_Gold
    <#17#>T_Cosmetic_Chicken_Mask
    <#18#>T_Porsche
    <#19#>T_Aura_Portal_Red
    <#20#>T_Perk_Icon_Supercharged
    <#21#>T_Kinetic_Blade
    <#22#>T_Aura_Butterfly
    <#23#>T_Cosmetic_Witch_Hat
    <#24#>T_Aura_Lightning
    <#25#>T_Perk_Icon_Supercharged  
    <#26#>T_Aura_Spirit
    <#27#>T_Icarus_Wings
    <#28#>T_Perk_Icon_Supercharged
    <#29#>T_Aura_Ghost_Squid
    <#30#>T_Bugatti
    <#31#>T_Cosmetic_Rabbit
    <#32#>T_Aura_Melody
    <#33#>T_Perk_Icon_Supercharged
    <#34#>T_Aura_Dance_Floor
    <#35#>T_Cosmetic_Pumpkin
    <#36#>T_Perk_Icon_Supercharged
    <#37#>T_Chainsaw
    <#38#>T_Aura_Fire_Runes
    <#39#>T_Lamborghini




    

