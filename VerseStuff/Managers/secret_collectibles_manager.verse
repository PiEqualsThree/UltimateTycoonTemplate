using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

secret_collectibles_manager<public> := class:
    
    ResetEvent : event() = event(){}

    Init<public>(CustomPlayer : custom_player, Settings : secret_collectible_settings) : void =
        Settings.Tracker.Reset(CustomPlayer.Agent)
        Settings.Tracker.Assign(CustomPlayer.Player)
        for ( Collectible : Settings.Collectibles) do Collectible.Respawn(CustomPlayer.Agent)
        for ( Collectible : Settings.Collectibles) do spawn{ Collectible.AwaitCollection(CustomPlayer, Settings) }
        spawn{ AwaitTrackerCompletion(CustomPlayer, Settings)}
 
    Reset<public>(Owner : custom_player, Settings : secret_collectible_settings) : void =
        Settings.Tracker.Reset(Owner.Player)
        Settings.Tracker.Remove(Owner.Player)
        ResetEvent.Signal()
        
    (Collectible : collectible_object_device).AwaitCollection(Owner : custom_player, Settings : secret_collectible_settings)<suspends> : void =
        race:
            ResetEvent.Await()
            loop:
                Agent := Collectible.CollectedEvent.Await()
                if ( Owner.Agent = Agent ):
                    Settings.Tracker.Increment(Agent)
                    Owner.TycoonLevel.GrantXP(350)
                    if ( Accolade := Settings.Accolades[GetRandomInt(0, Settings.Accolades.Length - 1)]) then Accolade.Award(Agent)

    AwaitTrackerCompletion(Owner : custom_player, Settings : secret_collectible_settings)<suspends> : void =
            race:
                ResetEvent.Await()
                loop:
                    Agent := Settings.Tracker.CompleteEvent.Await()
                    if ( Owner.Agent = Agent):
                        Owner.TycoonLevel.GrantXP(2500)
                        Settings.AllCollectiblesAccolade.Award(Agent)


                    
secret_collectible_settings<public> := class<concrete>:
    @editable       Tracker : tracker_device = tracker_device{}
    @editable       Collectibles : []collectible_object_device = array{}
    @editable       Accolades : []accolades_device = array{}
    @editable       AllCollectiblesAccolade : accolades_device = accolades_device{}
    