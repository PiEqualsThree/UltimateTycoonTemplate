using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { TycoonInterfaces }
using { Managers }

cashback_perk<public> := class(tycoon_perk):
    ResetEvent : event() = event(){}
    PerkEnabledEvent : event() = event(){}
    PerkDisabledEvent : event() = event(){}
    
    var Level : int = 0
    var IsEnabled : logic = false
    var Settings : cashback_perk_settings = cashback_perk_settings{}

    UniqueBegin<override>(InSettings : tycoon_perk_settings) : void =
        if ( CashbackSettings := cashback_perk_settings[InSettings]):
            set Settings = CashbackSettings
            Print("✅Succesfully Initialized Cashback Settings")
        else:
            Print("❌Error! No Setings found for Cashback perk)")

    Init<override>(TycoonManager : tycoon_manager) : void =
        {}

    Reset<override>() :void =
        set Level = 0
        Disable()

    Enable<override>(Owner : custom_player, TycoonManager : tycoon_manager) : void =
        if ( not IsEnabled?):
            set IsEnabled = true
            spawn{Update(Owner, TycoonManager)}

    Disable<override>() : void =
        if ( IsEnabled?):
            set IsEnabled = false
            PerkDisabledEvent.Signal()

    Update<override>(Owner : custom_player, TycoonManager : tycoon_manager)<suspends> : void =
        race:
            PerkDisabledEvent.Await()
            ResetEvent.Await()
            AwaitTycoonBuildingPurchaseEvents(Owner, TycoonManager)

    AwaitTycoonBuildingPurchaseEvents(Owner : custom_player, TycoonManager : tycoon_manager)<suspends> : void =
        loop:
            Transaction := race:
                block:
                    PurchaseResult := TycoonManager.TycoonBuildingPurchasedEvent.Await()
                    PurchaseResult.Transaction
                block:
                    UpgradeResult := TycoonManager.TycoonBuildingUpgradedEvent.Await()
                    UpgradeResult.Transaction
            if ( Transaction.Type = currency_type.Cash):
                CashbackTransaction := currency_transaction:
                    Type := currency_type.Cash
                    Amount := Max(Ceil[(Level * 0.01) * Transaction.Amount] or 1, 1)
                TycoonManager.CurrencyManager.IncreaseCurrency(Owner, CashbackTransaction)
                TycoonManager.UIManager.DisplayIncomeGain(Owner, CashbackTransaction, ?AdditionalText := " (Cashback!)", ?TextColor := MakeColorFromHex("FDFF00FF"))
                
    SetLevel<override>(InLevel : int) : void = set Level = InLevel
    GetLevel<override>()<transacts> : int = Level
    GetDescription<override>()<transacts> : string = 
        <# TODO: Make percent dynamic based on level #>
        "Gain 2% cash back on all\n" + 
        "buliding purchases made"

cashback_perk_settings<public> := class<concrete>(tycoon_perk_settings):
