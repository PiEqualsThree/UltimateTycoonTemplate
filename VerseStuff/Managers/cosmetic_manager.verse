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

<# cosmetic(s) #>
test_c<public> := class:  
    @editable       AuraSelectionManager : aura_selection_manager = aura_selection_manager{}

    #var MaybeCosmeticData : ?global_cosmetics_data = false

    var UnlockedAuraIndexMap<public> : [int]logic = map{ }
    var SortedAuraIndices<public> : []int = array{}
    var SelectedAuraIndex<public> : int = -1    
    
    var UnlockedVFXCosmeticIndexMap<public> : [int]logic = map{}
    var SortedVFXCosmeticIndices<public> : []int = array{}
    var SelectedVFXCosmeticIndex<public> : int = -1

    # UniqueBegin(CosmeticData : global_cosmetics_data) : void =
    #     set MaybeCosmeticData = option{CosmeticData}
    #     AuraSelectionManager.UniqueBegin()

    Init(TycoonManager : tycoon_manager) : void =
        {}
        #AuraSelectionManager.Init(TycoonManager.CosmeticsManager)

    EquipAura<public>(Owner : custom_player, AuraIndex : int) : void = {}
        # if ( CosmeticData := MaybeCosmeticData?):
        #     if ( AuraVFX := CosmeticData.AuraVFXPowerups[AuraIndex]):
        #         Print("Equipping Aura {AuraIndex}")
        #         set Owner.GetCosmeticsData().SelectedAuraIndex = AuraIndex
        #         AuraVFX.Pickup(Owner.Player)
        #     else if ( AuraIndex = -1):
        #         CosmeticData.AuraClearChaznel.Transmit(option{Owner.Agent})
        #     else:
        #         Print("Unkown Aura Index {AuraIndex}")
        # else:
        #     Print("Error: No cosmetic data set for cosmetic manager!")

    EquipVFXCosmetic<public>(Owner : custom_player, VFXCosmeticIndex : int) : void = {}
        # if ( CosmeticData := MaybeCosmeticData?):
        #     if ( VFXPowerup := CosmeticData.VFXCosmeticPowerups[VFXCosmeticIndex]):
        #         Print("Equipping VFX Cosmetic {VFXCosmeticIndex}")
        #         set Owner.GetCosmeticsData().SelectedVFXCosmeticIndex = VFXCosmeticIndex
        #         VFXPowerup.Pickup(Owner.Player)
        #     else if ( VFXCosmeticIndex = -1):
        #         CosmeticData.VFXCosmeticClearChannel.Transmit(option{Owner.Agent})
        #     else:
        #         Print("Unkown vfx {VFXCosmeticIndex}")
        # else:
        #     Print("Error: No cosmetic data set for cosmetic manager!")

    UnlockAura<public>(Owner : custom_player, AuraIndex : int) : void =
        {}
    #     if ( set Owner.GetCosmeticsData().UnlockedAuraIndexMap[AuraIndex] = true):
    #         set Owner.GetCosmeticsData().SortedAuraIndices = SortIndicesMap(Owner.GetCosmeticsData().UnlockedAuraIndexMap)

    UnlockVFXCosmetic<public>(Owner : custom_player, VFXCosmeticIndex : int) : void =
        {}
    #     if ( set Owner.GetCosmeticsData().UnlockedVFXCosmeticIndexMap[VFXCosmeticIndex] = true):
    #         set Owner.GetCosmeticsData().SortedVFXCosmeticIndices = SortIndicesMap(Owner.GetCosmeticsData().UnlockedVFXCosmeticIndexMap)

    Reset() : void =
        {}