using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { VerseStuff.Managers }

currency_generator<public> := interface:
    CurrencyGeneratedEvent<public>() : event(currency_transaction)