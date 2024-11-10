using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Vehicles }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { VerseStuff.Managers}
using { VerseStuff.TycoonInterfaces}
using { TycoonAnimations}

tycoon_vehicle<public> := class<concrete><unique>(resetable):
    @editable       ID : int = 0
    @editable       Name : string = "Lamborghini Murcielago"
    @editable       PurchaseComponent : ?tycoon_vehicle_purchase_component = false
  
    UnEquippedEvent : event(custom_player) = event(custom_player){}
    VehicleResetEvent : event() = event(){}
    UnlockedEvent<public> : event() = event(){}

    var DisplayOriginalTransform : transform = transform{}
    var EquipButtonOriginalTransform : transform = transform{}
    var VehicleProp : creative_prop = creative_prop{}
    var IsUnlocked<public> : logic = false
    var IsEquipped : logic = false
    var MaybeVFXClearChannel : ?channel_device = false
    var MaybeVFXPowerup : ?visual_effect_powerup_device = false

    UniqueBegin(VehicleVFXPowerup : visual_effect_powerup_device, VehicleVFXClearChannel : channel_device) : void =
        set MaybeVFXClearChannel = option{VehicleVFXClearChannel}
        set MaybeVFXPowerup = option{VehicleVFXPowerup}
        if: 
            Mesh := VehicleMeshes[ID]
            Prop := SpawnProp(GetDefaultBlueprintAsset[GetSession()] or DefaultCreativePropAsset, transform{})(0)?
        then:
            set VehicleProp = Prop
            VehicleProp.SetMesh(Mesh)
            VehicleProp.Hide()
        else:
            Print("Error initializing vehicle {Name}")

    Init() : void =
        {}

    Reset<override>() : void =
        VehicleResetEvent.Signal()
        VehicleProp.Hide()
        set IsUnlocked = false

    Equip(Owner : custom_player, CarSpawner : vehicle_spawner_sports_car_device, SpawnTransform : transform) : void = 
        if ( IsEquipped?) then return
        set IsEquipped = true
        
        if ( CarSpawner.TeleportTo[SpawnTransform]):
            spawn{ AwaitAssignDriver(Owner, CarSpawner)}
            CarSpawner.RespawnVehicle()
            
    Unequip(Owner : custom_player) : void =
        set IsEquipped = false
        if ( Channel := MaybeVFXClearChannel?) then Channel.Transmit(option{Owner.Agent})
        # VFXClearChannel.Transmit(option{Owner.Agent})
        UnEquippedEvent.Signal(Owner)
        VehicleProp.Hide()

    AwaitAssignDriver(Owner : custom_player, VehicleSpawner : vehicle_spawner_sports_car_device)<suspends> : void =       
        VehicleSpawner.SpawnedEvent.Await()
        VehicleSpawner.AssignDriver(Owner.Player)
        if ( VFXPowerup := MaybeVFXPowerup?) then VFXPowerup.Pickup(Owner.Player)

    SetUnlockedStatus(Logic : logic) : void =
        set IsUnlocked = Logic

    ResetEvent<override>() : event() = VehicleResetEvent
    GetName<public>()<transacts> : string = Name
    GetProp<public>()<transacts> : creative_prop = VehicleProp
    GetVFXPowerup<public>()<transacts><decides> : visual_effect_powerup_device = MaybeVFXPowerup?
    GetPurchaseComponent<public>()<transacts><decides> : tycoon_vehicle_purchase_component = PurchaseComponent?


tycoon_vehicle_purchase_component<public> := class<concrete>:
    @editable       Price<public> : int = 0 
    @editable       PurchaseCurrency<public> : currency_type = currency_type.Cash
    @editable       PurchaseButton<public> : button_device = button_device{}
