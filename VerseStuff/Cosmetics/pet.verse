
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { TycoonInterfaces }

pet<public> := class<concrete><unique>(resetable):
    @editable       Name : string = "Pet"
    @editable       PetProp : creative_prop = creative_prop{}
    @editable       PositionProp : creative_prop = creative_prop{}
    @editable       EquipSwitch : switch_device = switch_device{}

    Velocity : float = 300.0

    EnabledEvent : event() = event(){}
    DisabledEvent : event() = event(){}

    EquippedEvent : event(custom_player) = event(custom_player){}
    UnEquippedEvent : event(custom_player) = event(custom_player){}
    PetResetEvent : event() = event(){}

    var IsEnabled : logic = false
    var IsEquipped : logic = false
    var MaybeOwner : ?custom_player = false
    var DisplayTransform : transform = transform{}
    var OriginalEquipSwitchTransform : transform = transform{}
    var FailHudDevice : hud_message_device = hud_message_device{}

    UniqueBegin<public>() : void =
        set DisplayTransform = PositionProp.GetTransform()
        set OriginalEquipSwitchTransform = EquipSwitch.GetTransform()
        EquipSwitch.SetTurnOnInteractionText(StringToMessage("Return {Name}"))
        EquipSwitch.SetTurnOffInteractionText(StringToMessage("Equip {Name}"))
        # for ( Object : GetCreativeObjectsWithTag(pet_devices{})):
        #     if ( Hud := hud_message_device[Object]) then set FailHudDevice = Hud

    Init<public>() : void =
        set IsEquipped = false
        Hide()
        
    Reset<override>() : void = 
        PetResetEvent.Signal()
        Disable()
        Hide()

    Enable<public>(Owner : custom_player) : void =
        if ( IsEnabled?) then return
        EnabledEvent.Signal()
        EquipSwitch.Enable()
        spawn{ AwaitEquip(Owner)}
        set IsEnabled = true

    Disable<public>() : void =
        if ( not IsEnabled?) then return
        if ( IsEquipped?, Owner := MaybeOwner?) then Unequip(Owner)
        DisabledEvent.Signal()
        EquipSwitch.Disable()
        set IsEnabled = false

    AwaitEquip(Owner : custom_player)<suspends> : void =
        #PetSettings := Owner.GetPetSettings()
        race:
            DisabledEvent.Await()
            PetResetEvent.Await()
            loop:
                Agent := EquipSwitch.TurnedOffEvent.Await()
                if (Owner.Agent = Agent):
                    # if ( PetSettings.EquippedPets < PetSettings.MaximumPetSlots):`
                    Equip(Owner)
                        
                    # else:
                    #     FailHudDevice.SetText(StringToMessage("Error! Pet Slots Full ({PetSettings.MaximumPetSlots} / {PetSettings.MaximumPetSlots}) ❌"))
                    #     FailHudDevice.Show(Owner.Player)
                    #     Print("You can't equip any more pets!")
        Unequip(Owner)
    
    Equip(Owner : custom_player)<suspends> : void =
        if ( IsEquipped?) then return 
        Print("Equipped {Name}")        
        set IsEquipped = true
        set MaybeOwner = option{Owner}
        #Owner.GetPetSettings().AddEquippedPet(Self)
        EquippedEvent.Signal(Owner)
        #UpdateEquip(Owner, Owner.GetPetSettings().GetPetSlotIndex(Self))
        UpdateEquip(Owner, 0)

    Unequip(Owner : custom_player) : void = 
        if ( not IsEquipped?) then return
        Print("Unequipped {Name}")
        UnEquippedEvent.Signal(Owner)
        #Owner.GetPetSettings().RemoveEquippedPet(Self)
        set MaybeOwner = false
        if ( PositionProp.TeleportTo[DisplayTransform]):
            set IsEquipped = false

    UpdateEquip<public>(Owner : custom_player, SlotIndex : int)<suspends> : void =
        race:
            UnEquippedEvent.Await()
            ResetEvent().Await()
            DoFollowAnimation(Owner, SlotIndex)
            block:
                DisabledEvent.Await()
                Unequip(Owner)
            loop:
                Agent := EquipSwitch.TurnedOnEvent.Await()
                if ( Owner.Agent = Agent):
                    Unequip(Owner)
                    break

    DoFollowAnimation<public>(Owner : custom_player, SlotIndex : int)<suspends> : void =
        SinVal := Sin(SlotIndex * (PiFloat / 3.0))
        CosVal := Cos(SlotIndex * (PiFloat / 3.0))
        loop:
            if ( Owner.FortCharacter.IsActive[]):
                RightVector := Owner.FortCharacter.GetTransform().Rotation.GetLocalForward()
                TargetPosition := Owner.GetPosition() + 350.0 *  vector3:
                    X := RightVector.X * CosVal - RightVector.Y * SinVal
                    Y := RightVector.X * SinVal + RightVector.Y * CosVal
                    Z := 0.0
                CurrentPosition := PositionProp.GetTransform().Translation
                LookAtRotation := GetLookAtRotation(PositionProp.GetTransform().Translation, Owner.GetPosition())
                
                # Move pet forward and look at player (for smooth move transition)
                PositionProp.MoveTo(PositionProp.GetTransform().Translation + PositionProp.GetTransform().Rotation.GetLocalForward() * 50.0, LookAtRotation, 0.1)
                
                # Move towards the player
                TimeToMove := Distance(Owner.GetPosition() , PositionProp.GetTransform().Translation) / Velocity
                race:
                    Sleep(0.5)
                    PositionProp.MoveTo( TargetPosition, LookAtRotation, TimeToMove)
                
                if ( DistanceSquared(PositionProp.GetTransform().Translation, Owner.GetPosition()) <= 450000.0, PositionProp.TeleportTo[PositionProp.GetTransform()]):
                    # Look at player while in range
                    loop:
                        LookRotation := GetLookAtRotation(PositionProp.GetTransform().Translation, Owner.GetPosition())
                        Sleep(0.2)
                        PositionProp.MoveTo(PositionProp.GetTransform().Translation, LookRotation, 0.25)
                        
                        if ( DistanceSquared(PositionProp.GetTransform().Translation, Owner.GetPosition()) > 450000.0):
                            break
            else:   
                Sleep(0.0)
                      
    Show<public>() : void = 
        if ( PositionProp.TeleportTo[DisplayTransform]) {}
        PetProp.Show()

    Hide<public>() : void =
        if (PositionProp.TeleportTo[DisplayTransform.Translation - vector3{Z := 3000.0}, rotation{}]) {}
        PetProp.Hide()

    ResetEvent<override>() : event() = PetResetEvent
    GetPositionProp<public>()<transacts> : creative_prop = PositionProp
    
                    
