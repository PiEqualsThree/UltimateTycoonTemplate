using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { TycoonInterfaces }
using { Managers }

refund_perk<public> := class(tycoon_perk):
    ResetEvent : event() = event(){}
    PerkEnabledEvent : event() = event(){}
    PerkDisabledEvent : event() = event(){}
    
    var Level : int = 0
    var IsEnabled : logic = false
    var Settings : refund_perk_settings = refund_perk_settings{}

    UniqueBegin<override>(InSettings : tycoon_perk_settings) : void =
        if ( RefundSettings := refund_perk_settings[InSettings]):
            set Settings = RefundSettings
            Print("✅Succesfully Initialized Refund Settings")
        else:
            Print("❌Error! No Setings found for Refund perk)")

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
                    
            if ( Transaction.Type = currency_type.Cash, Chance := (Level * 5), Chance > GetRandomInt(1, 1000)):
                CashbackTransaction := currency_transaction{ Amount := Transaction.Amount, Type := Transaction.Type }
                TycoonManager.CurrencyManager.IncreaseCurrency(Owner, CashbackTransaction)
                TycoonManager.UIManager.DisplayIncomeGain(Owner, CashbackTransaction, ?AdditionalText := " (Full Refund!)", ?TextColor := MakeColorFromHex("00FF38FF"))
                Settings.RefundAudio.Play(Owner.Player)
            else:
                Print("Not a full refund!")
                
    SetLevel<override>(InLevel : int) : void = set Level = InLevel
    GetLevel<override>()<transacts> : int = Level
    GetDescription<override>()<transacts> : string = 
        Thing := (Level * 5.0) / 10.0
        "{FormatFloat(Thing, 1)}% chance of being fully\n" + 
        "refunded on a purchase"

refund_perk_settings<public> := class<concrete>(tycoon_perk_settings):
    @editable       RefundAudio : audio_player_device = audio_player_device{}
