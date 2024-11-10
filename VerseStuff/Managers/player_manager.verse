using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

player_manager<public> := class<concrete>:
    @editable       PlayerSpawners : []player_spawner_device = array{}
    @editable       MutatorZones : []mutator_zone_device = array{}

    var CustomPlayers : []custom_player = array{}

    CustomPlayerRemovedEvent<public> : event(custom_player) = event(custom_player){}
    CustomPlayerAddedEvent<public> : event(custom_player) = event(custom_player){}
    CustomEliminationEvent<public> : event(custom_elimination_result) = event(custom_elimination_result){}
    CustomDamageEvent<public> : event(custom_damage_result) = event(custom_damage_result){}

    var AgentCustomPlayerMap : [agent]custom_player = map{}
    var PlayerCustomPlayerMap : [player]custom_player = map{}
    var FortCharacterCustomPlayerMap : [fort_character]custom_player = map{}

    Init<public>(Playspace : fort_playspace) : void =
        for ( Spawner : PlayerSpawners) do Spawner.SpawnedEvent.Subscribe(OnPlayerSpawn)
        for ( MutatorZone : MutatorZones) do MutatorZone.AgentEntersEvent.Subscribe(OnPlayerSpawn)
        set CustomPlayers = for (Player : Playspace.GetPlayers(), Agent := agent[Player], CustomPlayer := CreateCustomPlayer[Agent]) do CustomPlayer
        for ( CustomPlayer : CustomPlayers) do spawn{ CustomPlayer.AwaitElimination()} 
        spawn{ Update(Playspace) }
        
    Update<private>(Playspace : fort_playspace)<suspends> : void =
        sync:
            loop:
                PlayerWhoJoined := Playspace.PlayerAddedEvent().Await()
                if (Agent := agent[PlayerWhoJoined]) then OnPlayerSpawn(Agent)
            loop:
                PlayerWhoLeft := Playspace.PlayerRemovedEvent().Await()
                OnPlayerLeave(PlayerWhoLeft)      

    CreateCustomPlayer(Agent : agent)<transacts><decides> : custom_player = 
        Player := player[Agent]
        FortCharacter := Agent.GetFortCharacter[]
        NewCustomPlayer := custom_player:
            Agent := Agent
            Player := Player
            FortCharacter := FortCharacter
        set AgentCustomPlayerMap[Agent] = NewCustomPlayer
        set PlayerCustomPlayerMap[Player] = NewCustomPlayer
        set FortCharacterCustomPlayerMap[FortCharacter] = NewCustomPlayer
        NewCustomPlayer

    OnPlayerLeave<private>(Player : player) : void =
        var MaybeLeavingCustomPlayer : ?custom_player = false
        var NewCustomPlayerList : []custom_player = array{}

        for ( CustomPlayer : CustomPlayers):
            if( CustomPlayer.Player = Player):
                set MaybeLeavingCustomPlayer = option{CustomPlayer}
            else:
                set NewCustomPlayerList += array{ CustomPlayer }
        set CustomPlayers = NewCustomPlayerList
        if ( LeavingPlayer := MaybeLeavingCustomPlayer?) then CustomPlayerRemovedEvent.Signal(LeavingPlayer)

    OnPlayerSpawn<private>(Agent : agent) : void =
        for ( CustomPlayer : CustomPlayers, CustomPlayer.Agent = Agent):
            Print("Player already exists")
            return
        if:
            CustomPlayer := CreateCustomPlayer[Agent]
        then:
            Print("Created new custom player")
            
            set CustomPlayers += array { CustomPlayer}
            CustomPlayerAddedEvent.Signal(CustomPlayer)
            spawn{ CustomPlayer.AwaitElimination()}

    GetCustomPlayers<public>()<transacts> : []custom_player = CustomPlayers
    GetCustomPlayerFromAgent<public>(Agent : agent)<transacts><decides> : custom_player = AgentCustomPlayerMap[Agent]
    GetCustomPlayerFromPlayer<public>(Player : player)<transacts><decides> : custom_player = PlayerCustomPlayerMap[Player]
    GetCustomPlayerFromFortCharacter<public>(FortCharacter : fort_character)<transacts><decides> : custom_player = FortCharacterCustomPlayerMap[FortCharacter]

    (CustomPlayer : custom_player).AwaitElimination()<suspends> : void =
        race:
            loop: <# Await player left event #>
                CPlayer := CustomPlayerRemovedEvent.Await()
                if ( CustomPlayer = CPlayer) then break
            loop: <# Await Damage result #>
                Result := race:
                    CustomPlayer.FortCharacter.DamagedEvent().Await()
                    CustomPlayer.FortCharacter.DamagedShieldEvent().Await()
                Print("Damaged event!")
                if ( Instigator := Result.Instigator?.GetInstigatorAgent[], Target := fort_character[Result.Target], Instigator.GetFortCharacter[] <> Target, CustomPlayer = GetCustomPlayerFromFortCharacter[Target]):
                    CustomDamageEvent.Signal(
                            custom_damage_result:
                                DamagingCustomPlayer := option{GetCustomPlayerFromAgent[Instigator]}
                                DamagedCustomPlayer := CustomPlayer
                                Amount := Result.Amount
                        )
            loop: <# Await elimination result #>
                Result := CustomPlayer.FortCharacter.EliminatedEvent().Await()
                Print("custom player eliminatd!")
                if ( CustomPlayer = GetCustomPlayerFromFortCharacter[Result.EliminatedCharacter]):
                    CustomEliminationEvent.Signal(
                            custom_elimination_result:
                                CustomEliminatingPlayer := option{GetCustomPlayerFromFortCharacter[Result.EliminatingCharacter?]}
                                CustomEliminatedPlayer := CustomPlayer
                        )
                spawn{ CustomPlayer.AwaitElimination()}
                    break              

custom_elimination_result<public> := struct:
    CustomEliminatingPlayer<public> : ?custom_player
    CustomEliminatedPlayer<public> : custom_player

custom_damage_result<public> := struct:
    DamagingCustomPlayer<public> : ?custom_player
    DamagedCustomPlayer<public> : custom_player
    Amount<public> : float