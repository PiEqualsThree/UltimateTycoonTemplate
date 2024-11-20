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

pumpkin_collection_manager<public> := class<concrete>:  
    @editable       CollectionButton : button_device = button_device{}
    @editable       CarryingPumpkinVFXPowerups : []visual_effect_powerup_device = array{}
    @editable       CarryingPumpkinHud : hud_message_device = hud_message_device{}
    @editable       StockFullHud : hud_message_device = hud_message_device{}
    @editable       DropOffButton : button_device = button_device{}
    @editable       VFXClearChannel : channel_device = channel_device{}
    @editable       PumpkinStockProps : []creative_prop = array{}
    @editable       PumpkinStockBillboard : billboard_device = billboard_device{}

    ResetEvent : event() = event(){}
    AutoCollectEnabledEvent : event() = event(){}

    var IsHoldingPumpkin : logic = false

    UniqueBegin() : void =
        {}

    UpdatePumpkinStockVisuals<public>(CurrentStock : int, MaxStock : int) : void =
        PumpkinStockBillboard.SetText(StringToMessage("Pumpkins:\n{CurrentStock} / {MaxStock}"))
        PumpkinStockBillboard.UpdateDisplay()
        for ( I := 0..MaxStock - 1, Prop := PumpkinStockProps[I]):
            if (I < CurrentStock) then Prop.Show() else Prop.Hide()

    LoadData<public>(Owner : custom_player, TycoonManager : tycoon_manager, PumpkinCarvingManager : pumpkin_carving_manager)<suspends> : void =
        UpdatePumpkinStockVisuals(PumpkinCarvingManager.PumpkinStockQueue.GetSize(), PumpkinCarvingManager.MaxStock)
        spawn{Update(Owner, PumpkinCarvingManager)}

    Update(Owner : custom_player, PumpkinCarvingManager : pumpkin_carving_manager)<suspends> : void =
        race:
            ResetEvent.Await()
            AwaitCollectionEvents(Owner, PumpkinCarvingManager)

    AwaitCollectionEvents(Owner : custom_player, PumpkinCarvingManager : pumpkin_carving_manager)<suspends> : void =
        sync:
            loop:
                Agent := CollectionButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    <# Pick up pumpkin #>
                    PumpkinType := AwaitPumpkinHarvest()
                    PumpkinVFX := case(PumpkinType) { pumpkin_stock_type.Rotten => CarryingPumpkinVFXPowerups[0], pumpkin_stock_type.Good => CarryingPumpkinVFXPowerups[1], pumpkin_stock_type.Perfect => CarryingPumpkinVFXPowerups[2]} or visual_effect_powerup_device{}
                    PumpkinVFX.Pickup(Owner.Player)
                    CarryingPumpkinHud.Show(Owner.Player)
                    race:
                        ResetEvent.Await()
                        Owner.FortCharacter.EliminatedEvent().Await()
                        Sleep(30.0)
                        loop:
                            DroppingOffAgent := DropOffButton.InteractedWithEvent.Await()
                            if ( Owner.Agent = DroppingOffAgent):
                                if ( PumpkinCarvingManager.PumpkinStockQueue.GetSize() >= PumpkinCarvingManager.MaxStock):
                                    StockFullHud.Show(Owner.Player)
                                    UpdatePumpkinStockVisuals(PumpkinCarvingManager.PumpkinStockQueue.GetSize(), PumpkinCarvingManager.MaxStock)
                                else:
                                    PumpkinCarvingManager.RestockPumpkin(PumpkinType)
                                break
                    CarryingPumpkinHud.Hide(Owner.Agent)
                    VFXClearChannel.Transmit(option{Owner.Agent})
            loop:
                AutoCollectEnabledEvent.Await()

            loop:
                PumpkinCarvingManager.PumpkinCarvingBeginEvent.Await()
                Sleep(0.0)
                UpdatePumpkinStockVisuals(PumpkinCarvingManager.PumpkinStockQueue.GetSize(), PumpkinCarvingManager.MaxStock)

            loop:
                PumpkinCarvingManager.PumpkinCarvingEndEvent.Await()
                UpdatePumpkinStockVisuals(PumpkinCarvingManager.PumpkinStockQueue.GetSize(), PumpkinCarvingManager.MaxStock)
                
    AwaitPumpkinHarvest()<suspends> : pumpkin_stock_type =
        pumpkin_stock_type.Good

    EnableAutoCollect<public>() : void =
        AutoCollectEnabledEvent.Signal()

    Reset<public> () : void =
        {}

    
    
        
    