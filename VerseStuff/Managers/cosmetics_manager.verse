using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary }
using { Cosmetics }

cosmetics_manager<public> := class<concrete>:  
    @editable       VehicleManager<public> : vehicle_manager = vehicle_manager{}

    ResetEvent : event() = event(){}

    var MaybeCosmeticData : ?global_cosmetic_data = false

    var UnlockedAuraIndexMap<public> : [int]logic = map{ }
    var SortedAuraIndices<public> : []int = array{}
    var EquippedAuraID<public> : int = -1    
    
    var UnlockedVFXCosmeticIndexMap<public> : [int]logic = map{}
    var SortedVFXCosmeticIndices<public> : []int = array{}
    var EquippedVFXCosmeticID<public> : int = -1

    UniqueBegin(CosmeticData : global_cosmetic_data) : void =
        set MaybeCosmeticData = option{CosmeticData}
        VehicleManager.UniqueBegin(CosmeticData)
        
    Init(TycoonManager : tycoon_manager, CosmeticData : global_cosmetic_data) : void =
        VehicleManager.Init(TycoonManager, CosmeticData)

    LoadData(Owner : custom_player, CosmeticData : global_cosmetic_data, PlayerStats : player_stats)<suspends> : void =
        for ( ID : PlayerStats.CosmeticStats.UnlockedAuraIDs) do UnlockAura(Owner, ID)
        for ( ID : PlayerStats.CosmeticStats.UnlockedVFXCosmeticIDs) do UnlockVFXCosmetic(Owner, ID)
        set EquippedAuraID = -1
        set EquippedVFXCosmeticID = -1
        VehicleManager.LoadData(Owner, CosmeticData, PlayerStats)
        
    Update(Owner : custom_player)<suspends> : void =
        race:
            ResetEvent.Await()
            loop:
                Sleep(15.0)
                spawn {ReapplyActiveAura(Owner)}
                spawn {ReapplyActiveVFXCOsmetic(Owner)}
                
            loop:
                Owner.FortCharacter.EliminatedEvent().Await()
                spawn{ ReapplyActiveAura(Owner, ?Delay := 3.5)}
                spawn{ ReapplyActiveVFXCOsmetic(Owner, ?Delay := 3.5)}

    EquipAura<public>(Owner : custom_player, AuraID : int) : void = 
        if ( CosmeticData := MaybeCosmeticData?):
            if ( AuraVFX := CosmeticData.AuraVFXPowerups[AuraID]):
                Print("Equipping Aura {AuraID}")
                set EquippedAuraID = AuraID
                AuraVFX.Pickup(Owner.Player)
            else if ( AuraID = -1):
                Print("Unequipping Aura by ID lookup")
                UnequipAura(Owner)
            else:
                Print("Unkown Aura Index {AuraID}")
        else:
            Print("Error: No cosmetic data set for cosmetic manager!")

    EquipVFXCosmetic<public>(Owner : custom_player, VFXCosmeticIndex : int) : void = 
        if ( CosmeticData := MaybeCosmeticData?):
            if ( VFXPowerup := CosmeticData.VFXCosmeticPowerups[VFXCosmeticIndex]):
                Print("Equipping VFX Cosmetic {VFXCosmeticIndex}")
                set EquippedVFXCosmeticID = VFXCosmeticIndex
                VFXPowerup.Pickup(Owner.Player)
            else if ( VFXCosmeticIndex = -1):
                CosmeticData.VFXCosmeticClearChannel.Transmit(option{Owner.Agent})
            else:
                Print("Unkown vfx {VFXCosmeticIndex}")
        else:
            Print("Error: No cosmetic data set for cosmetic manager!")

    UnlockAura<public>(Owner : custom_player, AuraID : int) : void =
        if ( not UnlockedAuraIndexMap[AuraID]?, set UnlockedAuraIndexMap[AuraID] = true):
            Print("Unlocking Aura {AuraID}")
            set SortedAuraIndices = SortIndicesMap(UnlockedAuraIndexMap)

    UnlockVFXCosmetic<public>(Owner : custom_player, VFXCosmeticID : int) : void =
        if ( set UnlockedVFXCosmeticIndexMap[VFXCosmeticID] = true):
            Print("Unlocking VFX Cosmetic {VFXCosmeticID}")
            set SortedVFXCosmeticIndices = SortIndicesMap(UnlockedVFXCosmeticIndexMap)

    UnequipAura<public>(Owner : custom_player) : void =
        if ( CosmeticData := MaybeCosmeticData?):
            Print("Unequipping Aura!")
            set EquippedAuraID = -1
            CosmeticData.AuraClearChannel.Transmit(option{Owner.Agent})

    UnequipVFXCosmetic<public>(Owner : custom_player) : void =
        if (CosmeticData := MaybeCosmeticData?):
            Print("Unequipping VFX")
            set EquippedVFXCosmeticID = -1
            CosmeticData.VFXCosmeticClearChannel.Transmit(option{Owner.Agent})


    ReapplyActiveAura(Owner : custom_player, ?Delay : float = -1.0)<suspends> : void = 
        Sleep(Delay)
        race:
            Sleep(7.0) <# Timeout #>
            loop:
                if ( Owner.FortCharacter.IsActive[]):
                    EquipAura(Owner, EquippedAuraID)
                    break
                else:
                    Sleep(0.0)
            
    ReapplyActiveVFXCOsmetic(Owner : custom_player, ?Delay : float = -1.0)<suspends> : void = 
        Sleep(Delay)
        race:
            Sleep(7.0) <# Timeout #>
            loop:
                if ( Owner.FortCharacter.IsActive[]):
                    EquipVFXCosmetic(Owner, EquippedVFXCosmeticID)
                    break
                else:
                    Sleep(0.0)

    GetStats() : cosmetic_stats = 
        cosmetic_stats:
            UnlockedAuraIDs := SortedAuraIndices
            UnlockedVehicleIDs := VehicleManager.UnlockedVehicleIDs
            UnlockedVFXCosmeticIDs := SortedVFXCosmeticIndices

    Reset() : void =
        ResetEvent.Signal()
        VehicleManager.Reset()
        set UnlockedAuraIndexMap = map{}
        set SortedAuraIndices = array{}
        set EquippedAuraID = -1

        set UnlockedVFXCosmeticIndexMap = map{}
        set SortedVFXCosmeticIndices = array{}
        set EquippedVFXCosmeticID = -1

    SortIndicesMap<public>(Map : [int]logic) : []int =
        Unsorted := for ( N->Bool : Map, Bool? ) do N
        Print("Sorting {Unsorted.Length} Auras")
        return SortBy(Unsorted, IntCompare)