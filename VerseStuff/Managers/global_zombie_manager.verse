using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

global_zombie_manager<public> := class(creative_device):
    @editable       ZombieEliminationData : []zombie_type_elimination_data = array{}
    
    Init<public>(PlayerManager : player_manager, CurrencyManager : currency_manager, UIManager : user_interface_manager) : void =
        for ( Data : ZombieEliminationData) do spawn { Data.AwaitElimination(PlayerManager, CurrencyManager, UIManager)}

    (ZombieTypeEliminationData : zombie_type_elimination_data).AwaitElimination(PlayerManager : player_manager, CurrencyManager : currency_manager, UIManager : user_interface_manager)<suspends> : void =
        loop:
            Agent := ZombieTypeEliminationData.ZombieManager.MatchingCreatureTypeEliminatedEvent.Await()
            if ( CustomPlayer := PlayerManager.GetCustomPlayerFromAgent[Agent]):
                profile("Handling Zombie elimination!"){
                    CashGain := Clamp(Ceil[0.01 * CustomPlayer.Candy * ZombieTypeEliminationData.BaseCashGain] or 10, ZombieTypeEliminationData.BaseCashGain, ZombieTypeEliminationData.MaxCashGain)
                    CashTransaction := currency_transaction{ Amount := CashGain, Type := currency_type.Cash}
                    CustomPlayer.TycoonLevel.GrantXP(ZombieTypeEliminationData.XPGain)
                    ZombieTypeEliminationData.EliminationAudio.Play(CustomPlayer.Player)
                    CurrencyManager.IncreaseCurrency(CustomPlayer, CashTransaction)
                    UIManager.DisplayIncomeGain(CustomPlayer, CashTransaction, ?TextColor := MakeColorFromHex("ED00FFFF"))
                    AccoladesArray := Shuffle(ZombieTypeEliminationData.Accolades)
                    if ( Accolades := AccoladesArray[0]) then Accolades.Award(CustomPlayer.Agent)
                }
                
zombie_type_elimination_data := class<concrete>:
    ZombieMessage<localizes> : message = "Zombie manager corersponding to a specific zombie"
    @editable { ToolTip := ZombieMessage
    } ZombieManager : creature_manager_device = creature_manager_device{}

    AudioMessage<localizes> : message = "Audio played when a zombie is defeated!"
    @editable { ToolTip := AudioMessage
    } EliminationAudio : audio_player_device = audio_player_device{}
    
    AccoladesMessage<localizes> : message = "Array of accolades to be awarded upon elimination. When eliminated, choose a random accolade form the give list"
    @editable { ToolTip := AccoladesMessage
    } Accolades : []accolades_device = array{}

    CashGainMessage<localizes> :  message = "Amount of cash gained per 100 candy"
    @editable { ToolTip := CashGainMessage
    } BaseCashGain : int = 10

    XPGainMessage<localizes> : message = "Amount of tycoon level xp gained on elimination"
    @editable { ToolTip := XPGainMessage
    } XPGain : int = 5

    MaxCashGainMessage<localizes> : message = "Maximum amount of cash gained per elimination corresponding to this zombie type"
    @editable { ToolTip := MaxCashGainMessage
    } MaxCashGain : int = 10000


