
# using { /Fortnite.com/Characters }
# using { /Fortnite.com/Devices }
# using { /Fortnite.com/Devices/CreativeAnimation }
# using { /Fortnite.com/AI }
# using { /Fortnite.com/UI }
# using { /Verse.org/Simulation }
# using { /UnrealEngine.com/Temporary/SpatialMath }
# using { /UnrealEngine.com/Temporary/Diagnostics }
# using { /UnrealEngine.com/Temporary/UI }
# using { TycoonInterfaces }

# flying_chair<public> := class<concrete><unique>(resetable):
#     @editable       Name : string = "Pet"
#     @editable       Chair : chair_device = chair_device{}
#     @editable       EquipButton : button_device = button_device{}
#     @editable       ForwardInputTrigger : input_trigger_device = input_trigger_device{}
#     @editable       Camera : gameplay_camera_orbit_device = gameplay_camera_orbit_device{}

#     Velocity : float = 300.0

#     EnabledEvent : event() = event(){}
#     DisabledEvent : event() = event(){}

#     EquippedEvent : event(custom_player) = event(custom_player){}
#     UnEquippedEvent : event(custom_player) = event(custom_player){}
#     FlyingChairResetEvent : event() = event(){}

#     var IsEnabled : logic = false
#     var IsEquipped : logic = false
#     var MaybeOwner : ?custom_player = false
#     var LastTransform : transform = transform{}
#     var OriginalEquipButtonTransform : transform = transform{}
    

#     UniqueBegin<public>() : void =
#         set OriginalEquipButtonTransform = EquipButton.GetTransform()

#     Init<public>() : void =
#         set IsEquipped = false
#         set LastTransform = transform{Translation := vector3{Z := 3500.0}}
#         Hide()
#         EquipButton.SetInteractionText(StringToMessage("Fly {Name}"))

#     Reset<override>() : void = 
#         ResetEvent().Signal()
#         Hide()
#         Disable()  

#     Enable<public>(Owner : custom_player) : void =
#         if ( IsEnabled?) then return
#         set IsEnabled = true
#         ForwardInputTrigger.Register(Owner.Player)
#         EnabledEvent.Signal()
#         EquipButton.Enable()
#         spawn{ AwaitEquip(Owner)}
        
#     Disable<public>() : void =
#         if ( not IsEnabled?) then return
#         if ( IsEquipped?, Owner := MaybeOwner?) then Unequip(Owner)
#         DisabledEvent.Signal()
#         EquipButton.Disable()
#         set IsEnabled = false

#     AwaitEquip(Owner : custom_player)<suspends> : void =
#         race:
#             DisabledEvent.Await()
#             ResetEvent().Await()
#             loop:
#                 InteractingAgent := race:
#                     block:
#                         Agent := EquipButton.InteractedWithEvent.Await()
#                         set LastTransform = transform{Translation := vector3{Z := 3500.0}}
#                         Agent
#                     block:
#                         Agent := Chair.SeatedEvent.Await()
#                         set LastTransform = Chair.GetTransform()
#                         Agent
                        
#                 if ( Owner.Agent = InteractingAgent):
#                     if ( ActiveFlyingChairCosmetic := Owner.GetActiveChairCosmetic[]) then ActiveFlyingChairCosmetic.Unequip(Owner)
#                     Equip(Owner)
#                 else:
#                     Chair.Eject(InteractingAgent)
                    
#         Unequip(Owner)
    
#     Equip(Owner : custom_player)<suspends> : void =
#         if ( IsEquipped?) then return 
#         Print("Equipped {Name}")        
#         set IsEquipped = true
#         set MaybeOwner = option{Owner}
#         Owner.SetActiveFlyingChairCosmetic(Self)
#         if ( Chair.TeleportTo[LastTransform]) {}
#         ForwardInputTrigger.Register(Owner.Player)
#         Chair.Seat(Owner.Agent)
#         Camera.AddTo(Owner.Player)
#         EquippedEvent.Signal(Owner)
#         UpdateEquip(Owner) 

#     Unequip(Owner : custom_player) : void = 
#         if ( not IsEquipped?) then return
#         Print("Unequipped {Name}")
#         Chair.Eject(Owner.Agent)
#         UnEquippedEvent.Signal(Owner)
#         ForwardInputTrigger.Unregister(Owner.Player)
#         Camera.RemoveFrom(Owner.Player)
#         EquipButton.SetInteractionText(StringToMessage("Equip {Name}"))
#         set MaybeOwner = false
#         set IsEquipped = false

#     UpdateEquip<public>(Owner : custom_player)<suspends> : void =
#         race:
#             UnEquippedEvent.Await()
#             ResetEvent().Await()
#             loop:
#                 Owner.FortCharacter.DamagedEvent().Await()
#                 if ( Owner.FortCharacter.GetHealth() <= 1.0):
#                     Owner.FortCharacter.SetHealth(1.0)
#                     break
#             UpdateMovement(Owner)
#         Unequip(Owner)

#     UpdateMovement(Owner : custom_player)<suspends> : void =
#         race:
#             Chair.ExitedEvent.Await()
#             Owner.FortCharacter.EliminatedEvent().Await()
#             loop:
#                 UpdateChairPosition(Owner)
#                 Sleep(0.0)
              
#     UpdateChairPosition(Owner : custom_player)<suspends> : void =
#         race:
#             ForwardInputTrigger.PressedEvent.Await()
#             loop:
#                 # Rotate chair to player view camera rotation
#                 Chair.MoveTo(Chair.GetTransform().Translation, Owner.FortCharacter.GetViewRotation(), 0.25)
#         race:
#             ForwardInputTrigger.ReleasedEvent.Await()
#             loop:
#                 Chair.MoveTo(Chair.GetTransform().Translation + Chair.GetTransform().Rotation.GetLocalForward() * 600.0, Owner.FortCharacter.GetViewRotation(), 0.3)
                      
#     Show<public>() : void = if ( EquipButton.TeleportTo[OriginalEquipButtonTransform]) {}
#     Hide<public>() : void = if (EquipButton.TeleportTo[OriginalEquipButtonTransform.Translation - vector3{Z := 3000.0}, rotation{}]) {}

#     ResetEvent<override>() : event() = FlyingChairResetEvent
#     GetEquipButton<public>()<transacts> : button_device = EquipButton
    
                    
