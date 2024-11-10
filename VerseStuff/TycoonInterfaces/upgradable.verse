using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { TycoonAnimations }
using { VerseStuff.TycoonInterfaces}
using { VerseStuff.TycoonBuildings}
using { VerseStuff.Managers}

upgradable<public> := interface:
    Unlock<public>(Owner : custom_player , ?PlayAnimations : logic = true) : void 
    Upgrade<public>(Owner : custom_player , ?PlayAnimations : logic = true) : void
    GetCurrentUpgradeCurrencyType<public>()<transacts><decides> : currency_type
    GetCurrentUpgradePrice<public>()<transacts><decides> : int
    GetCurrentUpgradeButton<public>()<transacts><decides> : creative_prop
    GetCurrentLevel<public>()<transacts> : int
    GetMaxLevel<public>()<transacts> : int
    GetUnlockedBulidingIDs<public>()<transacts> : []int
    IsUnlocked<public>()<transacts><decides> : void
    
