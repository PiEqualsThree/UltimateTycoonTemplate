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

vehicle_selection_manager<public> := class<concrete>:
    
    @editable       ReturnVehicleMesh : ?mesh = false
    @editable       EquipButton : button_device = button_device{}
    @editable       VehiclePreviewProp : creative_prop = creative_prop{}
    @editable       CycleVehiclesBackButton : button_device = button_device{}
    @editable       CycleVehiclesNextButton : button_device = button_device{}
    
    ResetEvent : event() = event(){}
    
    var CurrentVehicleArrayIndex : int = -1
    var CurrentVehicleID : int = -1
    
    var DefaultPreviewVehiclePropTransform : transform = transform{}

    UniqueBegin<public>() : void = 
        set DefaultPreviewVehiclePropTransform = VehiclePreviewProp.GetTransform()

    Init<public>(TycoonManager : tycoon_manager) : void =
        EquipButton.Disable()
        if ( VehiclePreviewProp.TeleportTo[DefaultPreviewVehiclePropTransform.Translation - vector3{Z := 3000.0}, DefaultPreviewVehiclePropTransform.Rotation]) {}
        VehiclePreviewProp.Hide()
        
    LoadData<public>(Owner : custom_player, VehicleManager : vehicle_manager, PlayerStats : player_stats)<suspends> : void =
        if ( GlobalCosmeticData := VehicleManager.MaybeCosmeticData?):
            EquipButton.Enable()
            if ( VehiclePreviewProp.TeleportTo[DefaultPreviewVehiclePropTransform]) {}
            if ( StarterVehicleID := VehicleManager.UnlockedVehicleIDs[0], Vehicle := GlobalCosmeticData.VehicleCosmetics[StarterVehicleID]):
                set CurrentVehicleArrayIndex = 0
                set CurrentVehicleID = StarterVehicleID
                UpdatePreview(Vehicle)
            else:
                VehiclePreviewProp.SetMesh(ReturnVehicleMesh? or Cars.LancerEvo.SM_Vehicle_Lancer)
                VehiclePreviewProp.Hide()
            spawn{ Update(Owner, VehicleManager, GlobalCosmeticData)}
        else:
            Print("Fatal Error: Vehicle Selection Manager cannot load data (Missing global cosmetic data)")

    Update(Owner : custom_player, VehicleManager : vehicle_manager, GlobalCosmeticData : global_cosmetic_data)<suspends> : void =
        Sleep(0.25)
        race:
            ResetEvent.Await()
            loop: <# Equip event #>
                Agent := EquipButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent, SelectedVehicle := GlobalCosmeticData.VehicleCosmetics[CurrentVehicleID]):
                    VehicleManager.EquipVehicle(Owner, CurrentVehicleID)
                    UpdatePreview(SelectedVehicle)

            loop: <# Back Vehicle Button #>
                Agent := CycleVehiclesBackButton.InteractedWithEvent.Await()
                if:
                    Owner.Agent = Agent
                    VehicleArrayIndex := Mod[CurrentVehicleArrayIndex - 1, VehicleManager.UnlockedVehicleIDs.Length]
                    VehicleID := VehicleManager.UnlockedVehicleIDs[VehicleArrayIndex]
                    VehicleCosmetic := GlobalCosmeticData.VehicleCosmetics[VehicleID]
                then:
                    set CurrentVehicleArrayIndex = VehicleArrayIndex
                    set CurrentVehicleID = VehicleID
                    UpdatePreview(VehicleCosmetic)
        
            loop: <# Next Vehicle Button #>
                Agent := CycleVehiclesNextButton.InteractedWithEvent.Await()
                if:
                    Owner.Agent = Agent
                    VehicleArrayIndex := Mod[CurrentVehicleArrayIndex + 1, VehicleManager.UnlockedVehicleIDs.Length]
                    VehicleID := VehicleManager.UnlockedVehicleIDs[VehicleArrayIndex]
                    VehicleCosmetic := GlobalCosmeticData.VehicleCosmetics[VehicleID]
                then:
                    set CurrentVehicleArrayIndex = VehicleArrayIndex
                    set CurrentVehicleID = VehicleID
                    UpdatePreview(VehicleCosmetic)

            loop: <# Rotate vehicle lol #>
                VehiclePreviewProp.MoveTo(DefaultPreviewVehiclePropTransform.Translation, VehiclePreviewProp.GetTransform().Rotation.ApplyYaw(1.95 * PiFloat), 3.0)
        
    UpdatePreview<public>( Vehicle : vehicle_cosmetic) : void =
        VehiclePreviewProp.Show()
        # When vehicle being previewed is the same as the active vehicle
        # if ( Vehicle.ID = CurrentVehicleID, ReturnMesh := ReturnVehicleMesh?):
        #     VehiclePreviewProp.SetMesh(ReturnMesh)
        # else:
        set CurrentVehicleID = Vehicle.ID
        Print("Updating preview {Vehicle.ID}")
        VehiclePreviewProp.SetMesh(Vehicle.GetMesh())
        EquipButton.SetInteractionText(StringToMessage("Equip {Vehicle.Name}"))
        
    Reset<public>() : void = 
        set CurrentVehicleID = -1
        VehiclePreviewProp.Hide()
        ResetEvent.Signal()

    
    


    

    

    
