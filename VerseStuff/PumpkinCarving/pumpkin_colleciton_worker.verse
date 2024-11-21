using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Random }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { PumpkinCarving}
using { VerseStuff.Managers }
using { VerseStuff.TycoonInterfaces }
using { TycoonAnimations }
using { Materials }
using { UIStuff}
using { UIStuff.PumpkinCarvingUI}
using { UIStuff.PumpkinCarvingUI.PumpkinEyes}
using { UIStuff.PumpkinCarvingUI.PumpkinMouths}
using { PumpkinStuff.PumpkinTops}

pumpkin_carving_worker<public> := class<concrete>:
    @editable       WorkerBillboard : billboard_device = billboard_device{}
    @editable       WorkerProgressBar : creative_prop = creative_prop{}
    @editable       CharacterDevice : character_device = character_device{}


    FinishMessage<localizes> : message = "Finished!"
    WorkingMessage<localizes> : message = "Carving Pumpkins . . ."
    StockEmptyMessage<localizes> : message = "No Pumpkins!"
    ResetEvent : event() = event(){}
    EnabledEvent : event() = event(){}
    ProgressMaterial : M_Hitbox_Progress_material = M_Hitbox_Progress_material{}

    UniqueBegin<public>() : void =
        WorkerProgressBar.SetMaterial(ProgressMaterial)

    Init<public>(Owner : custom_player, TycoonManager : tycoon_manager, PumpkinCarvingManager : pumpkin_carving_manager) : void =
        spawn{Update(Owner, TycoonManager, PumpkinCarvingManager)} 

    Update(Owner : custom_player, TycoonManager : tycoon_manager, PumpkinCarvingManager : pumpkin_carving_manager)<suspends> : void =
        race:
            ResetEvent.Await()
            PollCollectionEvents(Owner, TycoonManager, PumpkinCarvingManager)

    PollCollectionEvents(Owner : custom_player, TycoonManager : tycoon_manager, PumpkinCarvingManager : pumpkin_carving_manager)<suspends> : void =
        WorkingIntervals := 450
        WorkingIntervalsF := 1.0 * WorkingIntervals
        loop:
            set ProgressMaterial.Progress = 0.0
            if ( Stock := PumpkinCarvingManager.PumpkinStockQueue.Dequeue()?):
                WorkerBillboard.SetText(WorkingMessage)
                WorkerBillboard.UpdateDisplay()
                for ( I := 1..WorkingIntervals):
                    Progress := (1.0 * I ) / WorkingIntervalsF
                    set ProgressMaterial.Progress = Progress
                    Sleep(0.0)
                CharacterDevice.PlayEmote()
                CashGain := currency_transaction{Amount := Ceil[GetPumpkinTypeMultiplier(Stock) * Owner.CurrencyMultiplier * Owner.Candy * 0.005] or 1, Type := currency_type.Cash}
                CandyGain := currency_transaction{Amount := Ceil[GetPumpkinTypeMultiplier(Stock) * Owner.CurrencyMultiplier * Owner.Candy * 0.001] or 1, Type := currency_type.Candy}
                TycoonManager.CurrencyManager.IncreaseCurrency(Owner, CashGain)
                TycoonManager.CurrencyManager.IncreaseCurrency(Owner, CandyGain)
                WorkerBillboard.SetText(FinishMessage)
                WorkerBillboard.UpdateDisplay()
                CharacterDevice.PlayEmote()
                Sleep(2.0)
            else:
                WorkerBillboard.SetText(StockEmptyMessage)
                WorkerBillboard.UpdateDisplay()
                PumpkinCarvingManager.PumpkinCarvingEndEvent.Await()
                
    Reset<public>() : void =
        set ProgressMaterial.Progress = 0.0
        WorkerBillboard.SetText(StubMessage)
        WorkerBillboard.UpdateDisplay()
        


    
