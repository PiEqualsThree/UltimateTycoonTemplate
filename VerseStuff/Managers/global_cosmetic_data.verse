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

global_cosmetic_data<public> := class(creative_device):
    @editable       AuraClearChannel : channel_device = channel_device{}
    @editable       VFXCosmeticClearChannel : channel_device = channel_device{}
    @editable       AuraVFXPowerups : []visual_effect_powerup_device = array{}
    @editable       VFXCosmeticPowerups : []visual_effect_powerup_device = array{}
    @editable       VehicleVFXPowerups : []visual_effect_powerup_device = array{}

        
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
    


