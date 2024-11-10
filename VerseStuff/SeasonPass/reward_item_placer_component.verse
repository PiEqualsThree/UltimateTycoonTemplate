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

reward_item_component := class<concrete>(reward_component):
    @editable       ItemSlot : creative_prop = creative_prop{}
    @editable       ItemPlacer : item_placer_device = item_placer_device{}

    RewardResetEvent : event() = event(){}

    var DefaultItemSlotTransform : transform = transform{}

    UniqueBegin() : void =
        set DefaultItemSlotTransform = ItemSlot.GetTransform()

    Init<override>() : void =
        if ( ItemSlot.TeleportTo[DefaultItemSlotTransform.Translation - vector3{ Z := 3000.0}, rotation{}]) {}
    
    Claim<override>(Owner : custom_player, TycoonManager : tycoon_manager, Pass : season_pass) : void =
        if ( ItemSlot.TeleportTo[DefaultItemSlotTransform]) {}
        ItemPlacer.Enable()

    Reset<override>() : void =
        ItemPlacer.Disable()
        ResetEvent().Signal()

    ResetEvent<override>() : event() = RewardResetEvent