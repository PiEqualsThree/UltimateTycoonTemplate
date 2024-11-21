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

pumpkin_collection_farmer<public> := class<concrete>:
    @editable       FarmingBillboard : billboard_device = billboard_device{}
    @editable       FarmingProgressBar : creative_prop = creative_prop{}
    @editable       CharacterDevice : character_device = character_device{}

    FinishedMessage<localizes> : message = "Finished!"
    CollectionMessage<localizes> : message = "Collectin pumpkins . . ."
    StockFullMessage<localizes> : message = "Pumpkin storage full!"
    ResetEvent : event() = event(){}
    EnabledEvent : event() = event(){}
    ProgressMaterial : M_Hitbox_Progress_material = M_Hitbox_Progress_material{}

    UniqueBegin<public>() : void =
        FarmingProgressBar.SetMaterial(ProgressMaterial)

    Init<public>(PumpkinCarvingManager : pumpkin_carving_manager) : void =
        spawn{Update(PumpkinCarvingManager)} 

    Update(PumpkinCarvingManager : pumpkin_carving_manager)<suspends> : void =
        loop:
            ResetEvent.Await()
            PollCollectionEvents(PumpkinCarvingManager)

    PollCollectionEvents(PumpkinCarvingManager : pumpkin_carving_manager)<suspends> : void =
        CollectionIntervals := 300
        CollectionIntervalsF := 1.0 * CollectionIntervals
        loop:
            set ProgressMaterial.Progress = 0.0
            if ( PumpkinCarvingManager.PumpkinStockQueue.GetSize() < PumpkinCarvingManager.MaxStock):
                FarmingBillboard.SetText(CollectionMessage)
                FarmingBillboard.UpdateDisplay()
                for ( I := 1..CollectionIntervals):
                    Progress := (1.0 * I ) / CollectionIntervalsF
                    set ProgressMaterial.Progress = Progress
                    Sleep(0.0)
                if ( PumpkinCarvingManager.PumpkinStockQueue.GetSize() < PumpkinCarvingManager.MaxStock):
                    PumpkinCarvingManager.RestockPumpkin(pumpkin_stock_type.Good)
                    CharacterDevice.PlayEmote()
                    FarmingBillboard.SetText(FinishedMessage)
                    FarmingBillboard.UpdateDisplay()
                else:
                    FarmingBillboard.SetText(StockFullMessage)
                    FarmingBillboard.UpdateDisplay()

                Sleep(2.0)
            else:
                FarmingBillboard.SetText(StockFullMessage)
                FarmingBillboard.UpdateDisplay()
                PumpkinCarvingManager.PumpkinCarvingEndEvent.Await()
                
    Reset<public>() : void =
        set ProgressMaterial.Progress = 0.0
        FarmingBillboard.SetText(StubMessage)
        FarmingBillboard.UpdateDisplay()
        ResetEvent.Signal()
        


    
