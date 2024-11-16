using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

currency_manager<public> := class<concrete>:

    var UIManager : user_interface_manager = user_interface_manager{}

    Init<public>(InUIManager : user_interface_manager) : void =
        set UIManager = InUIManager

    # Check if player has enough currency to complete trasaction
    ValidatePurchase<public>(CustomPlayer : custom_player, Transaction : currency_transaction)<transacts><decides> : void =
        case(Transaction.Type):
            currency_type.Cash => CustomPlayer.Cash >= Transaction.Amount
            currency_type.Candy => CustomPlayer.Candy >= Transaction.Amount
            currency_type.BlingBucks => CustomPlayer.BlingBucks >= Transaction.Amount

    IncreaseCurrency<public>(CustomPlayer : custom_player, Transaction : currency_transaction) : void =
        case(Transaction.Type):
            currency_type.Cash => CustomPlayer.SetCash(CustomPlayer.Cash + Transaction.Amount)
            currency_type.Candy => CustomPlayer.SetCandy(CustomPlayer.Candy + Transaction.Amount)   
            currency_type.BlingBucks => CustomPlayer.SetBlingBucks(CustomPlayer.BlingBucks + Transaction.Amount)
        UIManager.UpdateCurrencyUI(CustomPlayer, Transaction.Type)

    DecreaseCurrency<public>(CustomPlayer : custom_player, Transaction : currency_transaction) : void = 
        case(Transaction.Type):
            currency_type.Cash => CustomPlayer.SetCash(CustomPlayer.Cash - Transaction.Amount)
            currency_type.Candy => CustomPlayer.SetCandy(CustomPlayer.Candy - Transaction.Amount)
            currency_type.BlingBucks => CustomPlayer.SetBlingBucks(CustomPlayer.BlingBucks - Transaction.Amount)
        UIManager.UpdateCurrencyUI(CustomPlayer, Transaction.Type)

    GetCustomPlayerCurrencyGain<public>(CustomPlayer : custom_player, BaseAmount : int)<transacts> : int =
        CustomPlayer.Rebirths > 0 and (Round[BaseAmount * CustomPlayer.GetCurrencyMultiplier()] or BaseAmount) or BaseAmount
    
currency_transaction<public> := struct:
    Type<public> : currency_type
    Amount<public> : int

currency_type<public> := enum:
    Cash
    Candy
    BlingBucks

passive_income<public> := class<concrete>:
    @editable       Cash<public> : int = 1
    @editable       Candy<public> : int = 0
