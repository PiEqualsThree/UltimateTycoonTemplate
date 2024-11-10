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

reward_aura_component := class<concrete>(reward_component):
    @editable       AuraID : int = 0

    RewardResetEvent : event() = event(){}

    Init<override>() : void =
        {}
    
    Claim<override>(Owner : custom_player, TycoonManager : tycoon_manager, Pass : season_pass) : void =
        TycoonManager.CosmeticsManager.UnlockAura(Owner, AuraID)

    Reset<override>() : void =
        {}

    ResetEvent<override>() : event() = RewardResetEvent