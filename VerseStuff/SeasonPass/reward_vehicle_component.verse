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

reward_vehicle_component := class<concrete>(reward_component):
    @editable       VehicleID : int = 0

    RewardResetEvent : event() = event(){}

    UniqueBegin() : void = {}

    Init<override>() : void = {}
    
    Claim<override>(Owner : custom_player, TycoonManager : tycoon_manager, Pass : season_pass) : void =
        TycoonManager.CosmeticsManager.VehicleManager.UnlockVehicle(Owner, VehicleID)

    Reset<override>() : void =
        ResetEvent().Signal()

    ResetEvent<override>() : event() = RewardResetEvent