using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Concurrency }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { VerseStuff.Managers }

purchasable<public> := interface:
    GetPurchaseCurrencyType<public>()<transacts> : currency_type
    GetPrice<public>()<transacts> : int
    Unlock<public>(Owner : custom_player, ?PlayAnimations : logic = true) : void
    Purchase<public>(Owner : custom_player, ?PlayAnimations : logic = true) : void
    GetPurchaseButton<public>()<transacts> : creative_prop
    GetPurchaseStatus<public>()<transacts> : purchase_status
    GetNextBuildingUnlockIDs<public>()<transacts> : []int

purchase_status<public> := enum:
    Locked
    Unlocked
    Purchased