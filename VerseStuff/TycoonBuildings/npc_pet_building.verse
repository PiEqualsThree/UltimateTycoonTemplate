# using { /Fortnite.com/Devices }
# using { /Verse.org/Simulation }
# using { /UnrealEngine.com/Temporary/Diagnostics }
# using { /UnrealEngine.com/Temporary/SpatialMath }
# using { /UnrealEngine.com/Assets }
# using { TycoonAnimations }
# using { VFXStuff }
# using { VerseStuff.TycoonInterfaces }
# using { VerseStuff.Managers}
# using { VerseStuff.Cosmetics }


# npc_pet_building<public> := class<concrete>(tycoon_building,  purchasable, resetable):
#     @editable       ID : int = 0
#     @editable       Price : int = 0
#     @editable       PurchaseCurrencyType : currency_type = currency_type.Cash
#     @editable       Pet : npc_pet = npc_pet{}
#     @editable       LockProp : creative_prop = creative_prop{}
#     @editable       ContainerProp : creative_prop = creative_prop{}
#     @editable       PurchaseButton : creative_prop = creative_prop{}
#     @editable       PassiveIncome : passive_income = passive_income{}
#     @editable       NextBuildingUnlockIDs<public> : []int = array{}
#     @editable       UseBuildAnimation : logic = true
#     @editable       TycoonCinematic : ?tycoon_cinematic = false

#     BuildingResetEvent : event() = event(){}

#     var DefaultContainerPropTransform : transform = transform{}
#     var DefaultPurchaseButtonTransform : transform = transform{}

#     var PurchaseStatus : purchase_status = purchase_status.Locked

#     # Run once per game start
#     UniqueBegin<override>() : void =
#         set DefaultContainerPropTransform = ContainerProp.GetTransform()
#         set DefaultPurchaseButtonTransform = PurchaseButton.GetTransform()
#         Pet.UniqueBegin()
            
#     Init<override>(TycoonManager : tycoon_manager) : void =
#         if:
#             ContainerProp.TeleportTo[DefaultContainerPropTransform.Translation - vector3{ Z := 3000.0}, DefaultContainerPropTransform.Rotation]
#             PurchaseButton.TeleportTo[DefaultPurchaseButtonTransform.Translation - vector3{ Z := 3000.0}, DefaultPurchaseButtonTransform.Rotation]

#         Pet.Init()
#         Pet.Hide()
#         Pet.Disable()
#         LockProp.Show()

#     Reset<override>() : void = 
#         set PurchaseStatus = purchase_status.Locked
#         ResetEvent().Signal()
#         Pet.Reset()

#     Unlock<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void =
#         set PurchaseStatus = purchase_status.Unlocked
#         spawn { DoTycoonPopupAnimation(PurchaseButton, DefaultPurchaseButtonTransform)}
#         spawn{ Build(?PlayAnimations := PlayAnimations) }
#         Pet.Show()
#         LockProp.Show()

#     Purchase<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void = 
#         if ( PurchaseStatus <> purchase_status.Purchased):
#             if ( not IsBuildingUnlocked?) then spawn{Build(?PlayAnimations := PlayAnimations)}
            
#             HidePurchaseButton(?PlayAnimations := PlayAnimations)
#             LockProp.Hide()
            
#             Pet.Enable(Owner)
#             if ( PlayAnimations?):
#                 SpawnPurchaseVFX(Self, DefaultContainerPropTransform.Translation)

#     ResetEvent<override>() : event() = BuildingResetEvent
#     GetNextBuildingUnlockIDs<override>()<transacts> : []int = (ID > 0 and array{ ID + 1 } or array{}) + NextBuildingUnlockIDs
#     GetPurchaseCurrencyType<override>()<transacts> : currency_type = PurchaseCurrencyType
#     GetPurchaseStatus<override>()<transacts> : purchase_status = PurchaseStatus
#     GetPurchaseButton<override>()<transacts> : creative_prop = PurchaseButton
#     GetPassiveIncome<override>()<transacts> : passive_income = PassiveIncome
#     GetPrice<override>()<transacts> : int = Price
#     GetID<override>()<transacts> : int = ID
