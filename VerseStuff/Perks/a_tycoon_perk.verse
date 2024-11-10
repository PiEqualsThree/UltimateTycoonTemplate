using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { Managers }
using { UIStuff }

tycoon_perk<public> := interface:
    UniqueBegin<public>(Settings : tycoon_perk_settings) : void
    Init<public>(TycoonManager : tycoon_manager) : void
    Reset<public>() : void
    Enable<public>(Owner : custom_player, TycoonManager : tycoon_manager) : void
    Disable<public>() : void 

    Update<public>(Owner : custom_player, TycoonManager : tycoon_manager)<suspends> : void 

    SetLevel<public>(InLevel : int) : void
    GetLevel<public>()<transacts> : int
    GetDescription<public>()<transacts> : string

tycoon_perk_settings<public> := interface:
