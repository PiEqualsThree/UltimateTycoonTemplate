using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Assets }
using { TycoonAnimations }
using { VFXStuff }
using { VerseStuff.TycoonInterfaces }
using { VerseStuff.Managers}
using { SeasonPass }

season_pass_building<public> := class<concrete>(tycoon_building, purchasable, resetable):
    @editable       ID : int = 0
    @editable       Price : int = 0
    @editable       TycoonSeasonPass<public> : season_pass = season_pass{}
    @editable       AuraSelectionManager : aura_selection_manager = aura_selection_manager{}
    @editable       PurchaseCurrencyType : currency_type = currency_type.Cash
    @editable       ContainerProp : creative_prop = creative_prop{}
    @editable       PurchaseButton : creative_prop = creative_prop{}
    @editable       PassiveIncome : passive_income = passive_income{}
    @editable       NextBuildingUnlockIDs : []int = array{}
    @editable       UseBuildAnimation : logic = true
    @editable       TycoonCinematic : ?tycoon_cinematic = false

    BuildingResetEvent : event() = event(){}

    var DefaultContainerPropTransform : transform = transform{}
    var DefaultAutoCollectorTransform : transform = transform{}

    var PurchaseStatus : purchase_status = purchase_status.Locked
    # Run once per game start
    UniqueBegin<override>()<suspends> : void =
        TycoonSeasonPass.UniqueBegin()
        AuraSelectionManager.UniqueBegin()
        set DefaultContainerPropTransform = ContainerProp.GetTransform()

          
    Init<override>(TycoonManager : tycoon_manager) : void =
        Print("INitializing Battle Pass")
        spawn{ TycoonSeasonPass.Init() }
        if:
            ContainerProp.TeleportTo[DefaultContainerPropTransform.Translation - vector3{ Z := 3000.0}, DefaultContainerPropTransform.Rotation]
            #PurchaseButton.TeleportTo[DefaultPurchaseButtonTransform.Translation - vector3{ Z := 3000.0}, DefaultPurchaseButtonTransform.Rotation]

    LoadData(Owner : custom_player, TycoonManager : tycoon_manager, PlayerStats : player_stats)<suspends> : void =
        AuraSelectionManager.LoadData(Owner, TycoonManager.CosmeticsManager)
        TycoonSeasonPass.LoadData(Owner, TycoonManager, TycoonManager.PlayerStatsManager.GetStats(Owner.Player))

    Reset<override>() : void =
        set PurchaseStatus = purchase_status.Locked
        ResetEvent().Signal()
        spawn{ TycoonSeasonPass.Reset() }
        AuraSelectionManager.Reset()

    Unlock<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void =
        if ( PurchaseStatus = purchase_status.Locked):
            set PurchaseStatus = purchase_status.Unlocked
            #spawn { DoTycoonPopupAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}

    Purchase<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void = 
        if ( PurchaseStatus <> purchase_status.Purchased):
            set PurchaseStatus = purchase_status.Purchased   
            #spawn{ DoTycoonHideAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}
            spawn{ DoTycoonPopupAnimation(ContainerProp, DefaultContainerPropTransform, ?PlayAnimations := PlayAnimations)}
            if ( PlayAnimations?):
                SpawnPurchaseVFX(Self, DefaultContainerPropTransform.Translation)
                if ( Cinematic := TycoonCinematic?) then spawn{ Cinematic.Play(Owner)}
                if ( Cinematic := TycoonCinematic?, MapIndicator := Cinematic.UnlockMapIndicator?) then MapIndicator.Deactivate(Owner)
            if ( TycoonManager := Owner.MaybeTycoonManager?):
                spawn{ LoadData(Owner, TycoonManager, TycoonManager.PlayerStatsManager.GetStats(Owner.Player))}
                
    ResetEvent<override>() : event() = BuildingResetEvent
    GetNextBuildingUnlockIDs<override>()<transacts> : []int = (ID >= 0 and array{ ID + 1 } or array{}) + NextBuildingUnlockIDs
    GetPurchaseCurrencyType<override>()<transacts> : currency_type = PurchaseCurrencyType
    GetPurchaseStatus<override>()<transacts> : purchase_status = PurchaseStatus
    GetPurchaseButton<override>()<transacts> : creative_prop = PurchaseButton
    GetPassiveIncome<override>()<transacts> : passive_income = PassiveIncome
    GetPrice<override>()<transacts> : int = Price
    GetID<override>()<transacts> : int = ID
