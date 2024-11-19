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
using { TycoonInterfaces }
using { Managers }

extra_xp_perk<public> := class(tycoon_perk):
    ResetEvent : event() = event(){}
    PerkEnabledEvent : event() = event(){}
    PerkDisabledEvent : event() = event(){}
    
    var Level : int = 0
    var IsEnabled : logic = false
    var MaybeOwner : ?custom_player = false
    var Settings : extra_xp_perk_settings = extra_xp_perk_settings{}

    UniqueBegin<override>(InSettings : tycoon_perk_settings) : void =
        if ( ExtraXPSettings := extra_xp_perk_settings[InSettings]):
            set Settings = ExtraXPSettings
            Print("✅Succesfully Initialized Extra XP Settings")
        else:
            Print("❌Error! No Setings found for Extra XP perk)")

    Init<override>(TycoonManager : tycoon_manager) : void =
        {}

    Reset<override>() :void =
        set Level = 0
        Disable()

    Enable<override>(Owner : custom_player, TycoonManager : tycoon_manager) : void =
        if ( not IsEnabled?):
            set IsEnabled = true
            set MaybeOwner = option{Owner}
            Owner.TycoonLevel.SetXPMultiplier(1.0 + Level * 0.025)

    Disable<override>() : void =
        if ( IsEnabled?, Owner := MaybeOwner?):
            set IsEnabled = false
            Owner.TycoonLevel.SetXPMultiplier(1.0)
            PerkDisabledEvent.Signal()

    Update<override>(Owner : custom_player, TycoonManager : tycoon_manager)<suspends> : void =
        {}
                
    SetLevel<override>(InLevel : int) : void = set Level = InLevel
    GetLevel<override>()<transacts> : int = Level
    GetDescription<override>()<transacts> : string = 
        Thing := (Level * 2.5)
        "Earn {FormatFloat(Thing, 1)}% extra Tycoon XP!\n" +
        "NOTE: This is NOT Battle Pass XP"
        
extra_xp_perk_settings<public> := class<concrete>(tycoon_perk_settings):
