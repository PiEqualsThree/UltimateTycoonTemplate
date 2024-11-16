using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Assets }
using { TycoonAnimations }
using { VFXStuff }
using { VerseStuff.TycoonInterfaces }
using { VerseStuff.Managers}

upgradable_currency_collector<public> := class<concrete>(tycoon_building, upgradable, resetable):
    @editable       ID : int = 0
    @editable       UpgradeBuildingIDRequired : int = 200
    @editable       Billboard : billboard_device = billboard_device{}
    @editable       CollectionTrigger : trigger_device = trigger_device{}
    @editable       CollectionAudio : audio_player_device = audio_player_device{}
    @editable       CollectorBuilding : upgradable_building = upgradable_building{}
    @editable       AutoCollectBuilding : upgradable_building = upgradable_building{}

    BuildingResetEvent : event() = event(){}

    var CashPerSecond : int = 0
    var CandyPerSecond : int = 0
    var StoredCash<public> : int = 0
    # Maybe an XP thing here

    var CurrentLevel : int = 0

    var IsBuildingUnlocked<public> : logic = false

    # Run once per game start
    UniqueBegin<override>() : void =
        CollectorBuilding.UniqueBegin()
        AutoCollectBuilding.UniqueBegin()
            
    Init<override>(TycoonManager : tycoon_manager) : void =
        CollectorBuilding.Init(TycoonManager)
        AutoCollectBuilding.Init(TycoonManager)
        CollectionTrigger.Disable()

    Reset<override>() : void =
        ResetEvent().Signal()
        set CashPerSecond = 0
        set CandyPerSecond = 0
        set StoredCash = 0
        set CurrentLevel = 0
        set IsBuildingUnlocked = false
        CollectionTrigger.Disable()
        CollectorBuilding.Reset()
        AutoCollectBuilding.Reset()

    Unlock<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void =
        set IsBuildingUnlocked = true
        CollectorBuilding.Unlock(Owner, ?PlayAnimations := PlayAnimations)

    Upgrade<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void =
        set IsBuildingUnlocked = true
        set CurrentLevel = CurrentLevel + 1
        if ( CurrentLevel = 1):
            CollectorBuilding.Purchase(Owner)
            CollectionTrigger.Enable()
            spawn{ AwaitUpgradeUnlock(Owner)}
            spawn{Update(Owner)}
        else if ( CurrentLevel = 2):
            AutoCollectBuilding.Purchase(Owner)
            spawn{ AutoCollectCash(Owner)}

    Update(Owner : custom_player)<suspends> : void =
        if ( TycoonManager := Owner.MaybeTycoonManager?):
            CurrencyManager := TycoonManager.CurrencyManager
            UIManager := TycoonManager.UIManager
            race:
                ResetEvent().Await()
                loop: <# Await player claims money #>
                    MaybeAgent := CollectionTrigger.TriggeredEvent.Await()
                    if ( Owner.Agent = MaybeAgent?):
                        TransactionGain := currency_transaction{Type := currency_type.Cash, Amount := StoredCash}
                        set StoredCash = 0
                        CurrencyManager.IncreaseCurrency(Owner, TransactionGain)
                        UIManager.DisplayIncomeGain(Owner, TransactionGain)
                        CollectionAudio.Play(Owner.Player)  
                        Billboard.SetText(StringToMessage("$0"))
                        Billboard.UpdateDisplay()
                        

                loop: <# Increase stored cash, update billboard, increase Candy (per passive Candy gain) #>
                    Sleep(1.0)
                    set StoredCash = StoredCash + CashPerSecond
                    Billboard.SetText(StringToMessage("${FormatNumber(StoredCash)}"))
                    Billboard.UpdateDisplay()
                    CandyGain := CurrencyManager.GetCustomPlayerCurrencyGain(Owner, CandyPerSecond)
                    CurrencyManager.IncreaseCurrency(Owner, currency_transaction{Type := currency_type.Candy, Amount := CandyGain})

    AutoCollectCash(Owner : custom_player)<suspends> : void =
        if ( CurrencyManager := Owner.MaybeTycoonManager?.CurrencyManager):
            race:
                ResetEvent().Await()
                loop:
                    Sleep(1.5)
                    CurrencyManager.IncreaseCurrency(Owner, currency_transaction{Amount := StoredCash, Type := currency_type.Cash })
                    Billboard.SetText(StringToMessage("$0"))
                    Billboard.UpdateDisplay()
                    set StoredCash = 0

    AwaitUpgradeUnlock(Owner : custom_player)<suspends> : void =
        if ( TycoonManager := Owner.MaybeTycoonManager?):
            race:
                ResetEvent().Await()
                loop:
                    PurchaseResult := TycoonManager.TycoonBuildingPurchasedEvent.Await()
                    if ( PurchaseResult.TycoonBuildingID = UpgradeBuildingIDRequired):
                        AutoCollectBuilding.Unlock(Owner)


    AddPassiveIncome<public>(Owner : custom_player, CurrencyManager : currency_manager, IncomeGain : passive_income) : void =
        set CashPerSecond = CashPerSecond + CurrencyManager.GetCustomPlayerCurrencyGain(Owner, IncomeGain.Cash)
        set CandyPerSecond = CandyPerSecond + CurrencyManager.GetCustomPlayerCurrencyGain(Owner, IncomeGain.Candy)
      
    SetStoredCash<public>(Amount : int) : void =
        set StoredCash = Amount

    ResetEvent<override>() : event() = BuildingResetEvent
    GetCurrentUpgradePrice<override>()<transacts><decides> : int = case(CurrentLevel) { 0 => CollectorBuilding.GetPrice(); 1 => AutoCollectBuilding.GetPrice() }
    GetCurrentUpgradeButton<override>()<transacts><decides> : creative_prop = case(CurrentLevel) { 0 => CollectorBuilding.GetPurchaseButton(); 1 => AutoCollectBuilding.GetPurchaseButton()}
    GetCurrentUpgradeCurrencyType<override>()<transacts><decides> : currency_type = case(CurrentLevel) { 0 => CollectorBuilding.GetPurchaseCurrencyType(); 1 => AutoCollectBuilding.GetPurchaseCurrencyType()}
    GetMaxLevel<override>()<transacts> : int = 2
    GetCurrentLevel<override>()<transacts> : int = CurrentLevel
    GetPassiveIncome<override>()<transacts> : passive_income = case(CurrentLevel) { 1 => CollectorBuilding.GetPassiveIncome(); 2 => AutoCollectBuilding.GetPassiveIncome(); _ => passive_income{}}
    GetUnlockedBulidingIDs<override>()<transacts> : []int = case(CurrentLevel) { 1 => CollectorBuilding.GetNextBuildingUnlockIDs(); 2 => AutoCollectBuilding.GetNextBuildingUnlockIDs(); _ => array{}}
    GetID<override>()<transacts> : int = ID
    IsUnlocked<override>()<transacts><decides> : void = IsBuildingUnlocked?