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

reward_bling_bucks_component := class<concrete>(reward_component):
    @editable       Amount : int = 10
    RewardResetEvent : event() = event(){}

    Init<override>() : void =
        {}
    
    Claim<override>(Owner : custom_player, TycoonManager : tycoon_manager, Pass : season_pass) : void =
        TycoonManager.CurrencyManager.IncreaseCurrency(Owner, currency_transaction{Amount := Amount, Type := currency_type.BlingBucks})

    Reset<override>() : void =
        {}

    ResetEvent<override>() : event() = RewardResetEvent