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

cosmetics_manager<public> := class(creative_device):
    @editable       AuraClearChannel : channel_device = channel_device{}
    @editable       VFXCosmeticClearChannel : channel_device = channel_device{}
    @editable       AuraVFXPowerups : []visual_effect_powerup_device = array{}
    @editable       VFXCosmeticPowerups : []visual_effect_powerup_device = array{}
    @editable       VehicleVFXPowerups : []visual_effect_powerup_device = array{}

    var PlayerManager : player_manager = player_manager{}

    UniqueBegin() : void =
        {}

    Init() : void =
        {}

    EquipAura<public>(Owner : custom_player, AuraIndex : int) : void =
        if ( AuraVFX := AuraVFXPowerups[AuraIndex]):
            Print("Equipping Aura {AuraIndex}")
            set Owner.GetCosmeticsData().SelectedAuraIndex = AuraIndex
            AuraVFX.Pickup(Owner.Player)
        else if ( AuraIndex = -1):
            AuraClearChannel.Transmit(option{Owner.Agent})
        else:
            Print("Unkown Aura Index {AuraIndex}")

    EquipVFXCosmetic<public>(Owner : custom_player, VFXCosmeticIndex : int) : void =
        if ( VFXPowerup := VFXCosmeticPowerups[VFXCosmeticIndex]):
            Print("Equipping VFX Cosmetic {VFXCosmeticIndex}")
            set Owner.GetCosmeticsData().SelectedVFXCosmeticIndex = VFXCosmeticIndex
            VFXPowerup.Pickup(Owner.Player)
        else if ( VFXCosmeticIndex = -1):
            VFXCosmeticClearChannel.Transmit(option{Owner.Agent})
        else:
            Print("Unkown vfx {VFXCosmeticIndex}")

    UnlockAura<public>(Owner : custom_player, AuraIndex : int) : void =
        if ( set Owner.GetCosmeticsData().UnlockedAuraIndexMap[AuraIndex] = true):
            set Owner.GetCosmeticsData().SortedAuraIndices = SortIndicesMap(Owner.GetCosmeticsData().UnlockedAuraIndexMap)

    UnlockVFXCosmetic<public>(Owner : custom_player, VFXCosmeticIndex : int) : void =
        if ( set Owner.GetCosmeticsData().UnlockedVFXCosmeticIndexMap[VFXCosmeticIndex] = true):
            set Owner.GetCosmeticsData().SortedVFXCosmeticIndices = SortIndicesMap(Owner.GetCosmeticsData().UnlockedVFXCosmeticIndexMap)

    Update(Owner : custom_player)<suspends> : void =
        sync:
            loop:
                Sleep(15.0)
                for ( CustomPlayer : PlayerManager.GetCustomPlayers() ):
                    spawn {ReapplyActiveAura(CustomPlayer)}
                    spawn {ReapplyActiveVFXCOsmetic(CustomPlayer)}
                
            loop:
                CustomEliminationResult := PlayerManager.CustomEliminationEvent.Await()
                spawn{ ReapplyActiveAura(CustomEliminationResult.CustomEliminatedPlayer, ?Delay := 3.5)}
                spawn{ ReapplyActiveVFXCOsmetic(CustomEliminationResult.CustomEliminatedPlayer, ?Delay := 3.5)}
                
    ReapplyActiveAura(Owner : custom_player, ?Delay : float = -1.0)<suspends> : void =
        Sleep(Delay)
        race:
            Sleep(7.0) <# Timeout #>
            loop:
                if ( Owner.FortCharacter.IsActive[]):
                    EquipAura(Owner, Owner.GetCosmeticsData().SelectedAuraIndex)
                    break
                else:
                    Sleep(0.0)
            
    ReapplyActiveVFXCOsmetic(Owner : custom_player, ?Delay : float = -1.0)<suspends> : void =
        Sleep(Delay)
        race:
            Sleep(7.0) <# Timeout #>
            loop:
                if ( Owner.FortCharacter.IsActive[]):
                    EquipVFXCosmetic(Owner, Owner.GetCosmeticsData().SelectedVFXCosmeticIndex)
                    break
                else:
                    Sleep(0.0)

    SortIndicesMap<public>(Map : [int]logic) : []int =
        Unsorted := for ( N->Bool : Map, Bool? ) do N
        Print("Sorting {Unsorted.Length} Auras")
        return SortBy(Unsorted, IntCompare)
            
player_cosmetics_data<public> := class:
    var UnlockedAuraIndexMap<public> : [int]logic = map{ }
    var SortedAuraIndices<public> : []int = array{}
    var SelectedAuraIndex<public> : int = -1    
    
    var UnlockedVFXCosmeticIndexMap<public> : [int]logic = map{}
    var SortedVFXCosmeticIndices<public> : []int = array{}
    var SelectedVFXCosmeticIndex<public> : int = -1
    
using { Cars}
VehicleMeshes<public> : []mesh = array:
    LancerEvo.SM_Vehicle_Lancer
    Supra.SM_Vehicle_Supra
    NissanZ.SM_Vehicle_NissanZ
    McLaren.SM_Vehicle_McLarenF1
    Cybertruck.SM_Vehicle_Cybertruck
    Corvette.SM_Vehicle_Corvette
    Porsche.SM_Vehicle_Porsche_911
    Bugatti.SM_Vehicle_Bugatti
    Lamborghini.SM_Vehicle_Lamborghini
    


