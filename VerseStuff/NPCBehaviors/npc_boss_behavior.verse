using { /Fortnite.com/AI }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath}
using { Managers}


npc_boss_behavior<public> := class(npc_behavior):

    OnBegin<override>()<suspends>:void=
        Print("Hello, NPC!")

    MoveToPlayer(TargetCustomPlayer : custom_player, ?ReachRadius : float = 50.0, ?MaxMovementTime : float = 10.0)<suspends> : void =
        if:
            Agent := GetAgent[]
            Fort := Agent.GetFortCharacter[]
            Navigatable := Fort.GetNavigatable[]
        then:
            TargetNavTarget := MakeNavigationTarget(TargetCustomPlayer.Agent)
            race:
                Sleep(MaxMovementTime)
                Navigatable.NavigateTo(TargetNavTarget, ?ReachRadius := ReachRadius)
            
    # OnEnd<override>():void=
    #     DefeatedEvent.Signal()