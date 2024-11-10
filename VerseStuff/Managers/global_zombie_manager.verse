using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
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
                CashGain := Clamp(Ceil[0.01 * CustomPlayer.Candy * ZombieTypeEliminationData.BaseCashGain] or 10, ZombieTypeEliminationData.BaseCashGain, ZombieTypeEliminationData.MaxCashGain)
                CashTransaction := currency_transaction{ Amount := CashGain, Type := currency_type.Cash}
                CurrencyManager.IncreaseCurrency(CustomPlayer, CashTransaction)
                UIManager.DisplayIncomeGain(CustomPlayer, CashTransaction, ?TextColor := MakeColorFromHex("ED00FFFF"))
                
zombie_type_elimination_data := class<concrete>:
    ZombieMessage<localizes> : message = "Zombie manager corersponding to a specific zombie"
    @editable { ToolTip := ZombieMessage
    } ZombieManager : creature_manager_device = creature_manager_device{}

    CashGainMessage<localizes> :  message = "Amount of cash gained per 100 candy"
    @editable { ToolTip := CashGainMessage
    } BaseCashGain : int = 10

    XPGainMessage<localizes> : message = "Amount of tycoon level xp gained on elimination"
    @editable { ToolTip := XPGainMessage
    } XPGain : int = 5

    MaxCashGainMessage<localizes> : message = "Maximum amount of cash gained per elimination corresponding to this zombie type"
    @editable { ToolTip := MaxCashGainMessage
    } MaxCashGain : int = 10000