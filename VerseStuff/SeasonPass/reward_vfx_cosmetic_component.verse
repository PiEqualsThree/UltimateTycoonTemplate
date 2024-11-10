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

reward_vfx_cosmetic_component := class<concrete>(reward_component):
    @editable       VFXCosmeticID: int = 0
    @editable       ItemSlot : creative_prop = creative_prop{}
    @editable       EquipButton : button_device = button_device{}

    RewardResetEvent : event() = event(){}

    var DefaultItemSlotTransform : transform = transform{}

    UniqueBegin() : void =
        set DefaultItemSlotTransform = ItemSlot.GetTransform()

    Init<override>() : void =
        if ( ItemSlot.TeleportTo[DefaultItemSlotTransform.Translation - vector3{ Z := 3000.0}, rotation{}]) {}
    
    Claim<override>(Owner : custom_player, TycoonManager : tycoon_manager, Pass : season_pass) : void =
        if ( ItemSlot.TeleportTo[DefaultItemSlotTransform]) {}
        TycoonManager.CosmeticsManager.UnlockVFXCosmetic(Owner, VFXCosmeticID)
        EquipButton.Enable()
        spawn{ AwaitCosmeticEquip(Owner, TycoonManager.CosmeticsManager)}

    AwaitCosmeticEquip(Owner : custom_player, ComseticsManager : test_c)<suspends> : void =
        race:
            ResetEvent().Await()
            loop:
                Agent := EquipButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    ComseticsManager.EquipVFXCosmetic(Owner, VFXCosmeticID)

    Reset<override>() : void =
        EquipButton.Disable()
        ResetEvent().Signal()

    ResetEvent<override>() : event() = RewardResetEvent