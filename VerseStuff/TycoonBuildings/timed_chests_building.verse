using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Assets }
using { TycoonAnimations }
using { VFXStuff }
using { VerseStuff.TycoonInterfaces }
using { VerseStuff.Managers}

timed_chests_building<public> := class<concrete>(tycoon_building,  purchasable, resetable):
    @editable       ID : int = 0
    @editable       Price : int = 0
    @editable       PurchaseCurrencyType : currency_type = currency_type.Cash
    @editable       ContainerProp : creative_prop = creative_prop{}
    @editable       PurchaseButton : creative_prop = creative_prop{}
    @editable       PassiveIncome : passive_income = passive_income{}
    @editable       TimedChests : []timed_chest = array{}
    @editable       NextBuildingUnlockIDs : []int = array{}
    @editable       UseBuildAnimation : logic = true
    @editable       TycoonCinematic : ?tycoon_cinematic = false

    BuildingResetEvent : event() = event(){}

    var DefaultContainerPropTransform : transform = transform{}
    var DefaultPurchaseButtonTransform : transform = transform{}

    var PurchaseStatus : purchase_status = purchase_status.Locked

    # Run once per game start
    UniqueBegin<override>() : void =
        set DefaultContainerPropTransform = ContainerProp.GetTransform()
        set DefaultPurchaseButtonTransform = PurchaseButton.GetTransform()
        for ( TimedChest : TimedChests) do TimedChest.UniqueBegin()
            
    Init<override>(TycoonManager : tycoon_manager) : void =
        for ( TimedChest : TimedChests) do TimedChest.Init()
        if:
            ContainerProp.TeleportTo[DefaultContainerPropTransform.Translation - vector3{ Z := 3000.0}, DefaultContainerPropTransform.Rotation]
            PurchaseButton.TeleportTo[DefaultPurchaseButtonTransform.Translation - vector3{ Z := 3000.0}, DefaultPurchaseButtonTransform.Rotation]  

    Reset<override>() : void =
        set PurchaseStatus = purchase_status.Locked
        for ( TimedChest : TimedChests) do TimedChest.Reset()
        ResetEvent().Signal() 

    Unlock<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void =
        if ( PurchaseStatus = purchase_status.Locked):
            set PurchaseStatus = purchase_status.Unlocked
            spawn { DoTycoonPopupAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}

    Purchase<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void = 
        if ( PurchaseStatus <> purchase_status.Purchased):
            set PurchaseStatus = purchase_status.Purchased   
            spawn{ DoTycoonHideAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}
            spawn{ DoTycoonPopupAnimation(ContainerProp, DefaultContainerPropTransform, ?PlayAnimations := PlayAnimations)}
            for ( TimedChest : TimedChests) do TimedChest.Unlock(Owner, ?PlayAnimations := PlayAnimations)
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
  

timed_chest := class<concrete>(resetable):
    @editable       Timer : timer_device = timer_device{}
    @editable       ItemPlacer : item_placer_device = item_placer_device{}
    @editable       OpenButton : button_device = button_device{}
    @editable       ChestContainer : creative_prop = creative_prop{}
    @editable       ChestLid : creative_prop = creative_prop{}

    var OriginalChestContainerTransform : transform = transform{}
    var OriginalChestLidTransform : transform = transform{}

    var IsUnlocked : logic = false

    TimedChestResetEvent : event() = event(){}

    UniqueBegin() : void =
        set OriginalChestContainerTransform = ChestContainer.GetTransform()
        set OriginalChestLidTransform = ChestLid.GetTransform()

    Init() : void =
        Timer.Reset()
        OpenButton.Disable()
        if:
            ChestContainer.TeleportTo[OriginalChestContainerTransform.Translation - vector3{ Z := 3000.0}, OriginalChestContainerTransform.Rotation]
            ChestLid.TeleportTo[OriginalChestLidTransform.Translation - vector3{ Z := 3000.0}, OriginalChestLidTransform.Rotation]

    Unlock(Owner : custom_player, ?PlayAnimations : logic = true) : void =
        if ( not IsUnlocked?):
            set IsUnlocked = true
            Timer.Start()
            spawn{DoTycoonPopupAnimation(ChestContainer, OriginalChestContainerTransform, ?PlayAnimations := PlayAnimations)}
            spawn{DoTycoonPopupAnimation(ChestLid, OriginalChestLidTransform, ?PlayAnimations := PlayAnimations)}
            spawn{Update(Owner)}
        
    Update(Owner : custom_player)<suspends> : void =
        race:
            ResetEvent().Await()
            AwaitChestTimer(Owner)
                
    AwaitChestTimer(Owner : custom_player)<suspends> : void =
        Timer.SuccessEvent.Await()
        OpenButton.Enable()
        loop:
            Agent := OpenButton.InteractedWithEvent.Await()
            if ( Owner.Agent = Agent):
                ChestLid.MoveTo(OriginalChestLidTransform.Translation, OriginalChestLidTransform.Rotation.ApplyPitch(PiFloat / 2.0), 1.5)
                ItemPlacer.Enable()
                OpenButton.Disable()
                break

    Reset<override>() : void =
        TimedChestResetEvent.Signal()
        set IsUnlocked = false
        if ( ChestLid.TeleportTo[OriginalChestLidTransform]) {}
        ItemPlacer.Disable()
        OpenButton.Disable()
        Timer.Reset()
        
    ResetEvent<override>() : event() = TimedChestResetEvent