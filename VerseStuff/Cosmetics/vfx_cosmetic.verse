
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { TycoonInterfaces }


# vfx_cosmetic<public> := class<concrete><unique>:
#     @editable       Name : string = "Cosmetic"
#     @editable       VFXPowerup : visual_effect_powerup_device = visual_effect_powerup_device{}

#     EquippedEvent : event(custom_player) = event(custom_player){}
#     UnEquippedEvent : event(custom_player) = event(custom_player){}
#     CosmeticResetEvent : event() = event(){}

#     # UniqueBegin<public>() : void =
#     #     set DisplayTransform = EquipSwitch.GetTransform()
#     #     if ( SwitchComponent := PhysicalSwitchComponent?) then SwitchComponent.UniqueBegin()

#     Init<public>() : void = 
#         {}

    # AwaitEquip(Owner : custom_player)<suspends> : void =
    #     race:
    #         DisabledEvent.Await()
    #         ResetEvent().Await()
    #         loop:
    #             Agent := EquipSwitch.TurnedOffEvent.Await()
    #             # TODO: Check for groups
    #             if ( Owner.Agent = Agent):
    #                 Equip(Owner)
    #             else:
    #                 EquipSwitch.TurnOn(Agent)
    #         loop:
    #             Agent := EquipSwitch.TurnedOnEvent.Await()
    #             # TODO: Check for groups
    #             if ( Owner.Agent = Agent):
    #                 Unequip(Owner)
    #             else:
    #                 EquipSwitch.TurnOff(Agent)

    # Equip<public>(Owner : custom_player) : void =
    #     EquippedEvent.Signal(Owner)
        # for ( Cosmetic : Owner.GetCosmeticSettings().GetEquippedCosmetics(), Cosmetic.GetCosmeticGroup() = CosmeticGroup)  do Cosmetic.Unequip(Owner)
        # spawn{PollEquip(Owner)}
        
        
    # PollEquip(Owner : custom_player)<suspends> : void =
    #     Sleep(0.1)
    #     #Owner.GetCosmeticSettings().AddEquippedCosmetic(Self)
    #     VFXPowerup.Pickup(Owner.Player)
    #     spawn{ UpdateEquippedVFX(Owner)}
    #     set IsEquipped = true
    #     set MaybeOwner = option{Owner}

    # UpdateEquippedVFX(Owner : custom_player)<suspends> : void =
    #     race:
    #         ResetEvent().Await()
    #         UnEquippedEvent.Await()
    #         loop:
    #             Sleep(15.0)
    #             if ( IsEquipped?) then VFXPowerup.Pickup(Owner.Player)

    # Unequip<public>(Owner : custom_player) : void =
    #     if ( not IsEquipped?) then return
    #     UnEquippedEvent.Signal(Owner)
    #     Owner.GetCosmeticSettings().RemoveEquippedCosmetic(Self)
    #     VFXRemoveTrigger.Trigger(Owner.Player)
    #     EquipSwitch.TurnOn(Owner.Player)
    #     set IsEquipped = false
    #     set MaybeOwner = false
    
    # Reset<public>() : void = 
    #     Disable()
    #     CosmeticResetEvent.Signal()
                        
    # ResetEvent<override>() : event() = CosmeticResetEvent
                    
# vfx_cosmetic_switch_component := class<concrete>:
#     @editable       ContainerProp : creative_prop = creative_prop{}
#     @editable       EquipSwitch : switch_device = switch_device{} 

#     var DefaultContainerPropTransform : transform = transform{}

#     UniqueBegin() : void =
#         EquipSwitch.SetTurnOffInteractionText(StringToMessage("Put on {Name}"))
#         EquipSwitch.SetTurnOnInteractionText(StringToMessage("Take Off {Name}"))
#         set DefaultContainerPropTransform = ContainerProp.GetTransform()

#     Reset() : void =
#         {}# EquipSwitch.TurnOn

#     Show() : void = if ( ContainerProp.TeleportTo[DefaultContainerPropTransform]) {}
#     Hide() : void = if ( ContainerProp.TeleportTo[DefaultContainerPropTransform.Translation - vector3{}, rotation{}]) {}