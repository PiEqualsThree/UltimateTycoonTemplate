using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { VerseStuff.Managers }
using { VerseStuff.TycoonInterfaces }
using { TycoonAnimations }

vehicle_selection_building<public> := class<concrete>(tycoon_building, purchasable, resetable): 
    @editable       ID : int = -1
    @editable       Price : int = 0
    @editable       PurchaseCurrencyType : currency_type = currency_type.Cash
    @editable       VehicleSelectionManager<public> : vehicle_selection_manager = vehicle_selection_manager{}
    @editable       ContainerProp : creative_prop = creative_prop{}
    @editable       PurchaseButton : creative_prop = creative_prop{}
    @editable       PassiveIncome : passive_income = passive_income{}
    @editable       NextBuildingUnlockIDs : []int = array{}
    @editable       UseBuildAnimation : logic = true
    @editable       TycoonCinematic : ?tycoon_cinematic = false

    BuildingResetEvent : event() = event(){}

    var DefaultContainerPropTransform : transform = transform{}
    var DefaultPurchaseButtonTransform : transform = transform{}

    var PurchaseStatus : purchase_status = purchase_status.Locked
    UniqueBegin<override>() : void =
        VehicleSelectionManager.UniqueBegin()
        set DefaultContainerPropTransform = ContainerProp.GetTransform()
        set DefaultPurchaseButtonTransform = PurchaseButton.GetTransform()

    Init<override>(TycoonManager : tycoon_manager) : void =
        VehicleSelectionManager.Init(TycoonManager)
        if:
            ContainerProp.TeleportTo[DefaultContainerPropTransform.Translation - vector3{ Z := 3000.0}, DefaultContainerPropTransform.Rotation]
            PurchaseButton.TeleportTo[DefaultPurchaseButtonTransform.Translation - vector3{ Z := 3000.0}, DefaultPurchaseButtonTransform.Rotation]
        
    Reset<override>() : void = 
        set PurchaseStatus = purchase_status.Locked
        VehicleSelectionManager.Reset()
        ResetEvent().Signal()

    Unlock<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void =
        if ( PurchaseStatus = purchase_status.Locked):
            set PurchaseStatus = purchase_status.Unlocked
            spawn { DoTycoonPopupAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}
        
    Purchase<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void = 
        if ( PurchaseStatus <> purchase_status.Purchased):
            set PurchaseStatus = purchase_status.Purchased   
            spawn{ DoTycoonHideAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := logic{PlayAnimations? and UseBuildAnimation?})}
            spawn{ DoTycoonPopupAnimation(ContainerProp, DefaultContainerPropTransform, ?PlayAnimations := logic{PlayAnimations? and UseBuildAnimation?})}
            if ( TycoonManager := Owner.MaybeTycoonManager?):
                spawn{ VehicleSelectionManager.LoadData(Owner, TycoonManager.CosmeticsManager.VehicleManager, TycoonManager.PlayerStatsManager.GetStats(Owner.Player))}
            if ( PlayAnimations?):
                if ( Cinematic := TycoonCinematic?) then spawn{ Cinematic.Play(Owner)}

    ResetEvent<override>() : event() = BuildingResetEvent
    GetNextBuildingUnlockIDs<override>()<transacts> : []int = array{ ID + 1 } + NextBuildingUnlockIDs
    GetPurchaseCurrencyType<override>()<transacts> : currency_type = PurchaseCurrencyType
    GetPurchaseStatus<override>()<transacts> : purchase_status = PurchaseStatus
    GetPurchaseButton<override>()<transacts> : creative_prop = PurchaseButton
    GetPassiveIncome<override>()<transacts> : passive_income = PassiveIncome
    GetPrice<override>()<transacts> : int = Price
    GetID<override>()<transacts> : int = ID
