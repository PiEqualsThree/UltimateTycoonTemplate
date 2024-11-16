using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

global_vip_manager := class<concrete>:
    @editable       InteractButton : button_device = button_device{}
    @editable       Teleporter : teleporter_device = teleporter_device{}
    #@editable       Accolades : accolades_device = accolades_device{}
    @editable       Barriers : []barrier_device = array{}

    @editable       ErrorHudDevice : hud_message_device = hud_message_device{}
    @editable       CandyRequired : int = 1000000

    Init(PlayerManager : player_manager) : void =
        spawn{Update(PlayerManager)}

    Update(PlayerManager : player_manager)<suspends> : void =
        loop:
            Agent := InteractButton.InteractedWithEvent.Await()
            if ( CustomPlayer := PlayerManager.GetCustomPlayerFromAgent[Agent]):
                if ( CustomPlayer.Candy >= CandyRequired):
                    #Accolades.Award(CustomPlayer.Player)
                    for ( Barrier : Barriers) do Barrier.AddToIgnoreList(CustomPlayer.Player)
                    Teleporter.Teleport(CustomPlayer.Player)
                else:
                    ErrorHudDevice.Show(CustomPlayer.Player)
                    for ( Barrier : Barriers) do Barrier.RemoveFromIgnoreList(CustomPlayer.Player)
                    Print("Not enough candy to enter!")
    