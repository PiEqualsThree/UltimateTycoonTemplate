using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Vehicles }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary }
using { VerseStuff.TycoonInterfaces }
using { TycoonAnimations}
using { UIStuff }

vehicle_manager<public> := class<concrete>:
    @editable       VehicleSpawner : vehicle_spawner_sports_car_device = vehicle_spawner_sports_car_device{}
    @editable       VehicleVFXClearChannel : channel_device = channel_device{}

    ResetEvent : event() = event(){}
    VehicleEquippedEvent : event(tycoon_vehicle) = event(tycoon_vehicle){}

    var MaybeCosmeticData : ?global_cosmetic_data = false
    var DefaultVehicleSpawnerTransform : transform = transform{}

    var MaybeOwner : ?custom_player = false
    var MaybeFortVehicle : ?fort_vehicle = false
    var VehicleProp : creative_prop = creative_prop{}
    
    var UnlockedVehicleIDsMap : [int]logic = map{}
    var UnlockedVehicleIDs : []int = array{}
    var EquippedVehicleID : int = -1
    

    UniqueBegin<public>(CosmeticData : global_cosmetic_data) : void = 
        set MaybeCosmeticData = option{CosmeticData}
        set DefaultVehicleSpawnerTransform = VehicleSpawner.GetTransform()
        set VehicleProp = (DefaultAsset := GetDefaultBlueprintAsset[GetSession()]) and SpawnProp(DefaultAsset, transform{})(0)? or creative_prop{} 
        
    Init<public>(TycoonManager : tycoon_manager, CosmeticData : global_cosmetic_data) : void =
        Print("Init vehicle manager")
        VehicleSpawner.DestroyVehicle()
        for ( Index->Vehicle : CosmeticData.VehicleCosmetics, set UnlockedVehicleIDsMap[Index] = false) {}

        if ( VehicleSpawner.TeleportTo[DefaultVehicleSpawnerTransform.Translation - vector3{ Z := 3000.0}, rotation{}]) {}
                   
    LoadData<public>(Owner : custom_player, CosmeticData : global_cosmetic_data, PlayerStats : player_stats) : void =
        for ( ID : PlayerStats.CosmeticStats.UnlockedVehicleIDs) do UnlockVehicle(Owner, ID)
        set MaybeOwner = option{Owner}
        spawn{Update(Owner, CosmeticData)}

    Update(Owner : custom_player, CosmeticData : global_cosmetic_data)<suspends> : void =
        race:
            ResetEvent.Await()
            PollVehicleEquipEvents(Owner, CosmeticData)
            loop: <# Vehicle spawned event #>
                Vehicle := VehicleSpawner.SpawnedEvent.Await()  
                set MaybeFortVehicle = option{Vehicle}
            loop:
                VehicleSpawner.VehicleDestroyedEvent.Await()
                set MaybeFortVehicle = false

    PollVehicleEquipEvents(Owner : custom_player, CosmeticData : global_cosmetic_data)<suspends> : void =
        race:
            ResetEvent.Await()
            loop: <# Await agent exit vehicle #>
                Agent := VehicleSpawner.AgentExitsVehicleEvent.Await()
                if:
                    Owner.Agent = Agent
                    VehicleSpawner.TeleportTo[MaybeFortVehicle?.GetTransform().Translation - MaybeFortVehicle?.GetTransform().Rotation.GetLocalRight() * 250.0, MaybeFortVehicle?.GetTransform().Rotation]
                    VehicleProp.TeleportTo[MaybeFortVehicle?.GetTransform()]
                then:
                    VehicleSpawner.RespawnVehicle()
                    VehicleProp.Show()
                    VehicleVFXClearChannel.Transmit(option{Owner.Agent})
                
            loop: <# When player re-enters their vehicle #>
                Agent := VehicleSpawner.AgentEntersVehicleEvent.Await()
                if ( Owner.Agent = Agent, Vehicle := CosmeticData.VehicleCosmetics[EquippedVehicleID]):
                    Vehicle.VFXPowerup.Pickup(Owner.Player)
                    VehicleProp.Hide()
                else:
                    if ( FortVehicle := MaybeFortVehicle?):
                        var IsOwnerAPassenger : logic = false
                        Passengers := FortVehicle.GetPassengers()
                        for ( Passenger : Passengers, Owner.FortCharacter = Passenger) do set IsOwnerAPassenger = true
                        if ( not IsOwnerAPassenger?) then VehicleSpawner.RespawnVehicle()

            loop: <# Refresh VFX Thing #>
                Sleep(15.0)
                if ( FortVehicle := MaybeFortVehicle?):
                    var IsOwnerAPassenger : logic = false
                    Passengers := FortVehicle.GetPassengers()
                    for ( Passenger : Passengers, Owner.FortCharacter = Passenger) do set IsOwnerAPassenger = true
                    if (IsOwnerAPassenger?, Vehicle := CosmeticData.VehicleCosmetics[EquippedVehicleID]):
                        Vehicle.VFXPowerup.Pickup(Owner.Player)
                    else:
                        VehicleVFXClearChannel.Transmit(option{Owner.Agent})

    EquipVehicle(Owner : custom_player, VehicleID : int)<suspends> : void =
        if ( CosmeticData := MaybeCosmeticData?, VehicleCosmetic := CosmeticData.VehicleCosmetics[VehicleID]):
            set EquippedVehicleID = VehicleID
            if ( VehicleSpawner.TeleportTo[DefaultVehicleSpawnerTransform]):
                race:
                    Sleep(10.0)
                    block:
                        VehicleSpawner.SpawnedEvent.Await()
                        VehicleSpawner.AssignDriver(Owner.Agent)
                        VehicleCosmetic.VFXPowerup.Pickup(Owner.Agent)
                        VehicleProp.SetMesh(VehicleCosmetic.GetMesh())
                    block:
                        Sleep(0.0)
                        VehicleSpawner.RespawnVehicle()
                        Sleep(Inf)

        else:
            Print("Fatal Error: Failed to equip vehicle (Missing Cosmetic Data)")
        
    UnlockVehicle<public>(Owner : custom_player, VehicleID : int) : void =
        if ( not UnlockedVehicleIDsMap[VehicleID]?, set UnlockedVehicleIDsMap[VehicleID] = true):
            Print("Unlocking Vehicle {VehicleID}")
            set UnlockedVehicleIDs = SortIndicesMap(UnlockedVehicleIDsMap)
            # If this is first vehicle to be unlocked, update vehicle preview on preview thing
            if:
                UnlockedVehicleIDs.Length = 1
                TycoonManager := Owner.MaybeTycoonManager?
                VehicleCosmetic := MaybeCosmeticData?.VehicleCosmetics[VehicleID]
            then:
                TycoonManager.VehicleSelectionBuilding.VehicleSelectionManager.UpdatePreview(VehicleCosmetic)

    Reset<public>() : void = 
        ResetEvent.Signal()
        VehicleSpawner.DestroyVehicle()
        VehicleProp.Hide()
        set UnlockedVehicleIDsMap = map{}
        set UnlockedVehicleIDs = array{}
        set EquippedVehicleID = -1
        set MaybeOwner = false

    SortIndicesMap<public>(Map : [int]logic) : []int =
        Unsorted := for ( N->Bool : Map, Bool? ) do N
        Print("Sorting {Unsorted.Length} vehicles")
        return SortBy(Unsorted, IntCompare)
    
    


    

    

    
