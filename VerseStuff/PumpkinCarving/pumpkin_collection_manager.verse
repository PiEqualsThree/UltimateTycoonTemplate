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
    PumpkinCollectedEvent : event() = event(){}
    PumpkinDroppedOffEvent : event() = event(){}

    RottenPumpkinMessage<localizes> : message = "Carrying Rotten Pumpkin"
    GoodPumpkinMessage<localizes> : message = "Carrying Good Pumpkin"
    PerfectPumpkinMessage<localizes> : message = "Carrying Perfect Pumpkin"

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
        Sleep(0.25)
        if ( PumpkinCarvingManager.ShouldShowTutorial?, Settings := PumpkinCarvingManager.TutorialSettings?):
            spawn{ Settings.QueueDisplayPumpkinCollectionTutorial(Owner, PumpkinCollectedEvent, ?DelayTime := 1.0) }
        sync:
            loop:
                Agent := CollectionButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    PumpkinCollectedEvent.Signal()
                    if ( PumpkinCarvingManager.ShouldShowTutorial?, Settings := PumpkinCarvingManager.TutorialSettings?):
                        spawn{ Settings.QueueDisplayDropOffTutorial(Owner, PumpkinDroppedOffEvent, ?DelayTime := 0.0) }
                    <# Pick up pumpkin #>
                    PumpkinType := AwaitPumpkinHarvest(?PumpkinTypeOverride := option{PumpkinCarvingManager.ShouldShowTutorial? and pumpkin_stock_type.Perfect})
                    case(PumpkinType):
                        pumpkin_stock_type.Rotten => {CarryingPumpkinHud.SetText(RottenPumpkinMessage); if ( PumpkinVFX := CarryingPumpkinVFXPowerups[0]) then PumpkinVFX.Pickup(Owner.Player)}
                        pumpkin_stock_type.Good => {CarryingPumpkinHud.SetText(GoodPumpkinMessage); if ( PumpkinVFX := CarryingPumpkinVFXPowerups[1]) then PumpkinVFX.Pickup(Owner.Player)}
                        pumpkin_stock_type.Perfect => {CarryingPumpkinHud.SetText(PerfectPumpkinMessage); if ( PumpkinVFX := CarryingPumpkinVFXPowerups[2]) then PumpkinVFX.Pickup(Owner.Player)}
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
                                else: <# Drop off pumpkin #>
                                    PumpkinCarvingManager.RestockPumpkin(PumpkinType)
                                    UpdatePumpkinStockVisuals(PumpkinCarvingManager.PumpkinStockQueue.GetSize(), PumpkinCarvingManager.MaxStock)
                                    PumpkinDroppedOffEvent.Signal()
                                    if ( PumpkinCarvingManager.ShouldShowTutorial?, Settings := PumpkinCarvingManager.TutorialSettings?):
                                        spawn{ Settings.QueueCarvingTutorial(Owner, PumpkinCarvingManager.PumpkinCarvingBeginEvent, ?DelayTime := 0.0) }
                                break
                    CarryingPumpkinHud.Hide(Owner.Agent)
                    VFXClearChannel.Transmit(option{Owner.Agent})
            loop:
                PumpkinCarvingManager.PumpkinCarvingBeginEvent.Await()
                Sleep(0.0)
                UpdatePumpkinStockVisuals(PumpkinCarvingManager.PumpkinStockQueue.GetSize(), PumpkinCarvingManager.MaxStock)

            loop:
                PumpkinCarvingManager.PumpkinCarvingEndEvent.Await()
                UpdatePumpkinStockVisuals(PumpkinCarvingManager.PumpkinStockQueue.GetSize(), PumpkinCarvingManager.MaxStock)
            loop:
                PumpkinCarvingManager.PumpkinRestockedEvent.Await()
                UpdatePumpkinStockVisuals(PumpkinCarvingManager.PumpkinStockQueue.GetSize(), PumpkinCarvingManager.MaxStock)
                
    AwaitPumpkinHarvest(?PumpkinTypeOverride : ?pumpkin_stock_type = false)<suspends> : pumpkin_stock_type =
        if ( Type := PumpkinTypeOverride?) then return Type
        case(GetRandomInt(0, 2)):
            0 => pumpkin_stock_type.Rotten
            1 => pumpkin_stock_type.Good
            2 => pumpkin_stock_type.Perfect
            _ => pumpkin_stock_type.Good

    Reset<public> () : void =
        {}

    
    
        
    