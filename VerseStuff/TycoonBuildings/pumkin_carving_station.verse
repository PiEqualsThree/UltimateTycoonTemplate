using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { TycoonAnimations }
using { VerseStuff.TycoonInterfaces }
using { Managers }

pumpkin_carving_station<public> := class<concrete>(tycoon_building, purchasable, resetable):
    @editable       ID : int = 0
    @editable       Price : int = 0
    @editable       PurchaseCurrencyType : currency_type = currency_type.Cash
    @editable       PumpkinCarvingManager : pumpkin_carving_manager = pumpkin_carving_manager{}
    @editable       ContainerProp : creative_prop = creative_prop{}
    @editable       PurchaseButton : creative_prop = creative_prop{}
    @editable       PassiveIncome : passive_income = passive_income{}
    @editable       NextBuildingUnlockIDs : []int = array{}
    @editable       UseBuildAnimation : logic = true
    @editable       TycoonCinematic : ?tycoon_cinematic = false

    BuildingResetEvent : event() = event(){}
    BuildingPurchasedEvent : event() = event(){}

    var DefaultContainerPropTransform : transform = transform{}
    var DefaultPurchaseButtonTransform : transform = transform{}
    var PurchaseStatus : purchase_status = purchase_status.Locked

    # Run once per game start
    UniqueBegin<override>() : void =
        set DefaultContainerPropTransform = ContainerProp.GetTransform()
        set DefaultPurchaseButtonTransform = PurchaseButton.GetTransform()
        spawn{ PumpkinCarvingManager.UniqueBegin() }
        
    Init<override>(TycoonManager : tycoon_manager) : void =
        PumpkinCarvingManager.Init(TycoonManager)
        if ( DefaultContainerPropTransform.Translation.Z < -2000.0) then Print("Tycoon Building {ID} is already iniitialized")
        if:
            ContainerProp.TeleportTo[DefaultContainerPropTransform.Translation - vector3{ Z := 3000.0}, DefaultContainerPropTransform.Rotation]
            PurchaseButton.TeleportTo[DefaultPurchaseButtonTransform.Translation - vector3{ Z := 3000.0}, DefaultPurchaseButtonTransform.Rotation]
        
    Reset<override>() : void =
        set PurchaseStatus = purchase_status.Locked
        ResetEvent().Signal()
        
    Unlock<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void =
        if ( PurchaseStatus = purchase_status.Locked):
            set PurchaseStatus = purchase_status.Unlocked
            spawn { DoTycoonPopupAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}

    Purchase<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void = 
        if ( PurchaseStatus <> purchase_status.Purchased, TycoonManager := Owner.MaybeTycoonManager?):
            set PurchaseStatus = purchase_status.Purchased   
            spawn{ DoTycoonHideAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}
            spawn{ DoTycoonPopupAnimation(ContainerProp, DefaultContainerPropTransform, ?PlayAnimations := PlayAnimations)}
            if ( PlayAnimations?):
                <# TODO: Spawn VFX Here #>
                if ( Cinematic := TycoonCinematic?) then spawn{ Cinematic.Play(Owner)}
            BuildingPurchasedEvent.Signal()
            # WARNING: Potentially can load data after buying something, which might override the save data if purchasing doesn't immediately update save data
            spawn{ PumpkinCarvingManager.LoadData(Owner, TycoonManager, TycoonManager.PlayerStatsManager.GetStats(Owner.Player)) }
            
    ResetEvent<override>() : event() = BuildingResetEvent
    GetNextBuildingUnlockIDs<override>()<transacts> : []int = (ID > 0 and array{ ID + 1 } or array{}) + NextBuildingUnlockIDs
    GetPurchaseCurrencyType<override>()<transacts> : currency_type = PurchaseCurrencyType
    GetPurchaseStatus<override>()<transacts> : purchase_status = PurchaseStatus
    GetPurchaseButton<override>()<transacts> : creative_prop = PurchaseButton
    GetPassiveIncome<override>()<transacts> : passive_income = PassiveIncome
    GetPrice<override>()<transacts> : int = Price
    GetID<override>()<transacts> : int = ID
    