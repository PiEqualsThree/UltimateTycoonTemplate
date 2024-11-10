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
using { VerseStuff.TycoonInterfaces }
using { TycoonAnimations}
using { UIStuff }

vehicle_manager<public> := class<concrete>(resetable):
    @editable       RequiredBuildingID : int = -1
    @editable       VehicleVFXClearChannel : channel_device = channel_device{}
    @editable       VehicleSpawner : vehicle_spawner_sports_car_device = vehicle_spawner_sports_car_device{}
    @editable       VehicleDisplayProp : creative_prop = creative_prop{}
    @editable       Vehicles : []tycoon_vehicle = array{}
    @editable       ReturnVehicleMesh : ?mesh = false
    @editable       EquipButton : button_device = button_device{}
    @editable       CycleVehiclesBackButton : button_device = button_device{}
    @editable       CycleVehiclesNextButton : button_device = button_device{}
    

    VehicleManagerResetEvent : event() = event(){}
    VehicleEquippedEvent : event(tycoon_vehicle) = event(tycoon_vehicle){}
    var VehiclePreviewProp : creative_prop = creative_prop{}
    var DefaultVehicleDisplayPropTransform : transform = transform{}
    var MaybeOwner : ?custom_player = false
    var VehicleIDMap : [int]tycoon_vehicle = map{}
    var UnlockedVehicles : []tycoon_vehicle = array{}
    var DefaultVehicleSpawnerTransform : transform = transform{}
    var MaybeEquippedVehicle : ?tycoon_vehicle = false
    var MaybeFortVehicle : ?fort_vehicle = false
    var CurrencyManager : currency_manager = currency_manager{}
    var SelectedVehicleID : int = -1

    UniqueBegin<public>(<# TOD#>) : void = {}
        # set DefaultVehicleDisplayPropTransform = VehicleDisplayProp.GetTransform()
        # set DefaultVehicleSpawnerTransform = VehicleSpawner.GetTransform()
        # set VehiclePreviewProp = (DefaultAsset := GetDefaultBlueprintAsset[GetSession()]) and SpawnProp(DefaultAsset, transform{})(0)? or creative_prop{} 
        # for ( Vehicle : Vehicles, set VehicleIDMap[Vehicle.ID] = Vehicle ) do Vehicle.UniqueBegin(CosmeticData.VehicleVFXPowerups[Vehicle.ID] or visual_effect_powerup_device{}, VehicleVFXClearChannel)
        
    Init<public>(TycoonManager : tycoon_manager) : void =
        Print("Init vehicle manager")
        set CurrencyManager = TycoonManager.CurrencyManager
        EquipButton.Disable()
        VehiclePreviewProp.Hide()
        VehicleSpawner.DestroyVehicle()
        for ( Index->Vehicle : Vehicles) do Vehicle.Init()
        if:
            VehicleSpawner.TeleportTo[DefaultVehicleSpawnerTransform.Translation - vector3{ Z := 3000.0}, rotation{}]
            VehicleDisplayProp.TeleportTo[DefaultVehicleDisplayPropTransform.Translation - vector3{ Z := 3000.0}, rotation{}]
        
    LoadData<public>(Owner : custom_player, TycoonManager : tycoon_manager, PlayerStats : player_stats) : void =
        set MaybeOwner = option{Owner}
        for ( ID : PlayerStats.CosmeticStats.UnlockedVehicleIDs, Vehicle := VehicleIDMap[ID]) do UnlockVehicle(Owner, ID, ?PlayAnimations := false) 
        for ( ID->Vehicle : VehicleIDMap, PurchaseComponent := Vehicle.GetPurchaseComponent[], not Vehicle.IsUnlocked?):
            spawn{ Vehicle.AwaitVehiclePurchase(Owner, PurchaseComponent)}
        spawn{Update(Owner, TycoonManager)}

    Update(Owner : custom_player, TycoonManager : tycoon_manager)<suspends> : void =
        if ( not TycoonManager.IsBuildingPurchased[RequiredBuildingID]):
            race:
                ResetEvent().Await()
                loop:
                    PurchaseResult := TycoonManager.TycoonBuildingPurchasedEvent.Await()
                    if ( PurchaseResult.TycoonBuildingID = RequiredBuildingID) then break
        DoTycoonPopupAnimation(VehicleDisplayProp, DefaultVehicleDisplayPropTransform, ?PlayAnimations := true)
        if ( VehiclePreviewProp.TeleportTo[DefaultVehicleDisplayPropTransform]){}
        if ( Vehicle := UnlockedVehicles[0]):
            DoTycoonPopupAnimation(VehicleDisplayProp, DefaultVehicleDisplayPropTransform, ?PlayAnimations := true)
            UpdateVehiclePreview(Owner, Vehicle)
            
        race:
            ResetEvent().Await()
            loop: <# Equip event #>
                Agent := EquipButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent, SelectedVehicle := Vehicles[SelectedVehicleID]):
                    if ( CurrentVehicle := MaybeEquippedVehicle?) then CurrentVehicle.Unequip(Owner)
                    Sleep(0.15)
                    set MaybeEquippedVehicle = option{SelectedVehicle}
                    SelectedVehicle.Equip(Owner, VehicleSpawner, DefaultVehicleSpawnerTransform)
                    VehiclePreviewProp.Hide()
                    spawn{ SelectedVehicle.UpdateVehicle(Owner)}

            loop: <# Back Vehicle Button #>
                Agent := CycleVehiclesBackButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent, UnlockedVehicles.Length > 1, NextID := Mod[SelectedVehicleID - 1, UnlockedVehicles.Length], Vehicle := UnlockedVehicles[NextID]):
                    set SelectedVehicleID = NextID
                    UpdateVehiclePreview(Owner, Vehicle)

            loop: <# Next Vehicle Button #>
                Agent := CycleVehiclesNextButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent, UnlockedVehicles.Length > 1, NextID := Mod[SelectedVehicleID + 1, UnlockedVehicles.Length], Vehicle := UnlockedVehicles[NextID]):
                    set SelectedVehicleID = NextID
                    UpdateVehiclePreview(Owner, Vehicle)

            loop: <# Vehilce spawned event #>
                Vehicle := VehicleSpawner.SpawnedEvent.Await()  
                set MaybeFortVehicle = option{Vehicle}

    (Vehicle : tycoon_vehicle).AwaitVehiclePurchase(Owner : custom_player, PurchaseComponent : tycoon_vehicle_purchase_component)<suspends> : void =
        Transaction := currency_transaction{Amount := PurchaseComponent.Price, Type := PurchaseComponent.PurchaseCurrency}
        race:
            ResetEvent().Await()
            loop:
                Agent := PurchaseComponent.PurchaseButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    if ( CurrencyManager.ValidatePurchase[Owner, Transaction]):
                        Print("Purchased Vehicle {Vehicle.ID}")
                        CurrencyManager.DecreaseCurrency(Owner, Transaction)
                        UnlockVehicle(Owner, Vehicle.ID, ?PlayAnimations := true)
                    else:
                        Print("Not enough to purchase Vehicle {Vehicle.ID}")
                        <# Not enough to purchase #>
        
    UnlockVehicle<public>(Owner : custom_player, VehicleID : int, ?PlayAnimations : logic = true) : void =
        Print("Attempting unlock vehicle { VehicleID}")
        EquipButton.Enable()
        if ( UnlockedVehicle := VehicleIDMap[VehicleID], not UnlockedVehicle.IsUnlocked?):
            Print("Unlocked Vehicle {VehicleID}")
            set UnlockedVehicles = UnlockedVehicles + array{UnlockedVehicle}
            set SelectedVehicleID = VehicleID
            UnlockedVehicle.SetUnlockedStatus(true)
            UpdateVehiclePreview(Owner, UnlockedVehicle)

    UpdateVehiclePreview<public>(Owner : custom_player, NewVehicle : tycoon_vehicle) : void =
        if ( Mesh := VehicleMeshes[NewVehicle.ID]):
            # When vehicle being previewed is the same as the active vehicle
            if ( NewVehicle.ID = MaybeEquippedVehicle?.ID, ReturnMesh := ReturnVehicleMesh?):
                VehiclePreviewProp.SetMesh(ReturnMesh)
            else:
                VehiclePreviewProp.SetMesh(Mesh)
                EquipButton.SetInteractionText(StringToMessage("Equip {NewVehicle.GetName()}"))
    
    (Vehicle : tycoon_vehicle).UpdateVehicle(Owner : custom_player)<suspends> : void =
        race:
            Vehicle.UnEquippedEvent.Await()
            ResetEvent().Await()
            loop: <# Await agent exit vehicle #>
                Agent := VehicleSpawner.AgentExitsVehicleEvent.Await()
                if:
                    Owner.Agent = Agent
                    VehicleSpawner.TeleportTo[MaybeFortVehicle?.GetTransform().Translation - MaybeFortVehicle?.GetTransform().Rotation.GetLocalRight() * 250.0, MaybeFortVehicle?.GetTransform().Rotation]
                    Vehicle.GetProp().TeleportTo[MaybeFortVehicle?.GetTransform()]
                then:
                    VehicleSpawner.RespawnVehicle()
                    Vehicle.GetProp().Show()
                    VehicleVFXClearChannel.Transmit(option{Owner.Agent})
                    
            loop: <# When player re-enters their vehicle #>
                Agent := VehicleSpawner.AgentEntersVehicleEvent.Await()
                if ( Owner.Agent = Agent, VFXPowerup := Vehicle.GetVFXPowerup[]):
                    VFXPowerup.Pickup(Owner.Player)
                    Vehicle.GetProp().Hide()
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
                    if (IsOwnerAPassenger?, VFXPowerup := Vehicle.GetVFXPowerup[]):
                        VFXPowerup.Pickup(Owner.Player)
                    else:
                        VehicleVFXClearChannel.Transmit(option{Owner.Agent})

    Reset<override>() : void = 
        VehicleManagerResetEvent.Signal()
        VehicleSpawner.DestroyVehicle()
        set UnlockedVehicles = array{}
        if ( Owner := MaybeOwner?, EquippedVehicle := MaybeEquippedVehicle?) then EquippedVehicle.Unequip(Owner)
        for ( Vehicle : Vehicles) do Vehicle.Reset()

    GetUnlockedVehicleIDs<public>()<transacts> : []int = for ( Vehicle : UnlockedVehicles) do Vehicle.ID
    ResetEvent<override>() : event() = VehicleManagerResetEvent

    
    


    

    

    
