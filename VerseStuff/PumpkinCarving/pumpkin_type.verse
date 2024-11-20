using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }

pumpkin_stock_type<public> := enum:
    Rotten
    Good
    Perfect

pumpkin_stock_type_queue<public> := class:
    var Array : []pumpkin_stock_type = array{}
    var Size : int = 0

    Queue<public>(PumpkinType : pumpkin_stock_type) : void =
        set Array = Array + array{PumpkinType}
        set Size = Size + 1

    Dequeue<public>()<transacts> : ?pumpkin_stock_type =
        var MaybePumpkinType : ?pumpkin_stock_type = false
        if ( PumpkinType := Array[0]):  
            set MaybePumpkinType = option{PumpkinType}
            set Array = for ( Index->Element : Array, Index <> 0) do Element
            set Size = Size - 1
        MaybePumpkinType

    Reset<public>() : void =
        set Array = array{}
        set Size = 0

    GetSize<public>()<transacts> : int = Size

GetPumpkinTypeMultiplier<public>(PumpkinType : pumpkin_stock_type)<transacts> : float = 
    case(PumpkinType):
        pumpkin_stock_type.Rotten => 0.85
        pumpkin_stock_type.Good => 1.0
        pumpkin_stock_type.Perfect => 1.15
