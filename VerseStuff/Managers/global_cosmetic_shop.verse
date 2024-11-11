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

global_cosmetic_shop := class<concrete>:
    @editable       VehiclePurchaseComponents : []vehicle_purchase_component = array{}

    Init(PlayerManager : player_manager, CurrencyManager : currency_manager) : void =
        for ( Component : VehiclePurchaseComponents) do spawn {Component.AwaitPurchase(PlayerManager)}

    (VehiclePurchaseComponent : vehicle_purchase_component).AwaitPurchase(PlayerManager : player_manager)<suspends> : void =
        loop:
            Agent := VehiclePurchaseComponent.Button.InteractedWithEvent.Await()
            if ( CustomPlayer := PlayerManager.GetCustomPlayerFromAgent[Agent], TycoonManager := CustomPlayer.MaybeTycoonManager?):
                if ( not TycoonManager.CosmeticsManager.VehicleManager.UnlockedVehicleIDsMap[VehiclePurchaseComponent.VehicleID]?):
                    if ( CustomPlayer.Rebirths >= VehiclePurchaseComponent.RebirthsRequired):
                        #Print("Unlocking vehicle {VehiclePurchaseComponent.VehicleID}!")
                        TycoonManager.CosmeticsManager.VehicleManager.UnlockVehicle(CustomPlayer, VehiclePurchaseComponent.VehicleID)
                    else:
                        Print("Not enough rebirhts to unlock vehicle {VehiclePurchaseComponent.VehicleID}")
                else:
                    Print("Vehicle {VehiclePurchaseComponent.VehicleID} already owned!")

vehicle_purchase_component := class<concrete>:
    @editable       VehicleID : int = 0
    @editable       RebirthsRequired : int = 0
    @editable       Button : button_device = button_device{}