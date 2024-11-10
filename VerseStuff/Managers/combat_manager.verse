# using { /Fortnite.com/Devices }
# using { /Fortnite.com/Playspaces }
# using { /Fortnite.com/Characters }
# using { /Fortnite.com/Game }
# using { /Verse.org/Concurrency }
# using { /Verse.org/Simulation }
# using { /UnrealEngine.com/Temporary/Diagnostics }
# using { /UnrealEngine.com/Temporary/SpatialMath }

# combat_manager<public> := class<concrete>:
#     @editable       AggressivePlayerHudDevice : hud_message_device = hud_message_device{}
#     @editable       CooledPlayerHudDevice : hud_message_device = hud_message_device{}

#     AggressivePlayerAddedEvent<public> : event(custom_player) = event(custom_player){}
#     AggressivePlayerRemovedEvent<public> : event(custom_player) = event(custom_player){}
#     AggroValueOnElimination : float = 150.0
#     AggroTreshold : float = 425.0

#     var AggressivePlayers : []custom_player = array{}
#     var CustomPlayerAggroValueMap : [custom_player]float = map{}

#     Init<public>(PlayerManager : player_manager, CurrencyManager : currency_manager) : void =
#         spawn{Update(PlayerManager, CurrencyManager)}

#     Update(PlayerManager : player_manager, CurrencyManager : currency_manager)<suspends> : void =
#         sync:
#             loop:
#                 Result := PlayerManager.CustomDamageEvent.Await()
#                 if ( DamagingCustomPlayer := Result.DamagingCustomPlayer?):
#                     if ( AggroValue := CustomPlayerAggroValueMap[DamagingCustomPlayer]):
#                         NewValue := AggroValue + Result.Amount

#                         if ( set CustomPlayerAggroValueMap[DamagingCustomPlayer] = NewValue) {}
#                         if ( NewValue >= AggroTreshold, not AggressivePlayers.Find[DamagingCustomPlayer]):
#                             set AggressivePlayers = AggressivePlayers + array{DamagingCustomPlayer}
#                             AggressivePlayerAddedEvent.Signal(DamagingCustomPlayer)
#                             AggressivePlayerHudDevice.Show(DamagingCustomPlayer.Player)
  
#                     else:
#                         if ( set CustomPlayerAggroValueMap[DamagingCustomPlayer] = Result.Amount) {}
                        
#             loop:
#                 Result := PlayerManager.CustomEliminationEvent.Await()
#                 if ( EliminatingCustomPlayer := Result.CustomEliminatingPlayer?):
#                     if ( AggroValue := CustomPlayerAggroValueMap[EliminatingCustomPlayer]):
#                         NewValue := AggroValue + AggroValueOnElimination

#                         if ( set CustomPlayerAggroValueMap[EliminatingCustomPlayer] = NewValue) {}
#                         if ( NewValue >= AggroTreshold, not AggressivePlayers.Find[EliminatingCustomPlayer]):
#                             set AggressivePlayers = AggressivePlayers + array{EliminatingCustomPlayer}
#                             AggressivePlayerAddedEvent.Signal(EliminatingCustomPlayer)
#                             AggressivePlayerHudDevice.Show(EliminatingCustomPlayer.Player)

#                     else:
#                         if ( set CustomPlayerAggroValueMap[EliminatingCustomPlayer] = AggroValueOnElimination) {}
                        
#             loop:
#                 Sleep(10.0)
#                 for ( CustomPlayer->AggroValue : CustomPlayerAggroValueMap, set CustomPlayerAggroValueMap[CustomPlayer] = Max(AggroValue - 45.0, 0.0)):
#                     # Remove player from aggro list if their aggro value falls to 0
#                     if ( AggroValue <= 0.0, AggressivePlayers.Find[CustomPlayer]):
#                         set AggressivePlayers = for ( Player : AggressivePlayers, Player <> CustomPlayer) do Player
#                         AggressivePlayerRemovedEvent.Signal(CustomPlayer)
#                         CooledPlayerHudDevice.Show(CustomPlayer.Player)
                        
#             loop:
#                 LeavingCustomPlayer := PlayerManager.CustomPlayerRemovedEvent.Await()
#                 UpdatedMap := CustomPlayerAggroValueMap.RemoveKey(LeavingCustomPlayer)
#                 set CustomPlayerAggroValueMap = UpdatedMap