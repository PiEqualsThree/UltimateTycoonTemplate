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

reward_component<public> := interface:
    Init<public>() : void
    Claim<public>(Owner : custom_player, TycoonManager : tycoon_manager, Pass : season_pass) : void
    ResetEvent<public>() : event()
    Reset<public>() : void