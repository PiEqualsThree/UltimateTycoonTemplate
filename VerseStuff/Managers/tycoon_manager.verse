using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { VerseStuff.Managers}
using { VerseStuff.TycoonInterfaces}
using { VerseStuff.TycoonBuildings }
using { SeasonPass }
PurchaseSuccessMessage<localizes> : message = "✔ Success!"
PurchaseFailMessage<localizes> : message = "❌ Not enough!"

tycoon_manager<public> := class(creative_device, resetable):
    @editable       DebugManager : ?debug = false
    @editable       ClaimMutatorZone : mutator_zone_device = mutator_zone_device{}
    @editable       StartingPropsContainer : creative_prop = creative_prop{}
    @editable       SeasonPassBuilding : season_pass_building = season_pass_building{}
    @editable       VehicleSelectionBuilding : vehicle_selection_building = vehicle_selection_building{}
    @editable       PerksManager<public> : perks_manager = perks_manager{}
    @editable       CosmeticsManager<public> : cosmetics_manager = cosmetics_manager{}
    @editable       TimeGiftBox : time_gift_box = time_gift_box{}
    @editable       CurrencyCollector : upgradable_currency_collector = upgradable_currency_collector{}
    @editable       PhoneBuilding : phone_building = phone_building{}
    @editable       PumpkinCarvingStation : pumpkin_carving_station = pumpkin_carving_station{}
    @editable       Floor1TycoonBuildings : []basic_tycoon_building = array{}
    @editable       Floor2TycoonBuildings : []basic_tycoon_building = array{}
    @editable       Floor3TycoonBuildings : []basic_tycoon_building = array{}
    @editable       Floor4TycoonBuildings : []basic_tycoon_building = array{}
    @editable       Floor5TycoonBuildings : []basic_tycoon_building = array{}
    @editable       Hitboxes : []upgradable_hit_currency_generator = array{}
    @editable       Droppers : []dropper = array{}
    @editable       TycoonDevices : tycoon_devices = tycoon_devices{}

    RebirthEvent : event() = event(){}
    TycoonResetEvent : event() = event(){}
    TycoonBuildingPurchasedEvent<public> : event(tycoon_building_purchase_result) = event(tycoon_building_purchase_result){}
    TycoonBuildingUpgradedEvent<public> : event(tycoon_building_upgrade_result) = event(tycoon_building_upgrade_result){}
    SecretCollectiblesManager<public> : secret_collectibles_manager = secret_collectibles_manager{}
    SaveManager : save_manager = save_manager{}
    RebirthManager : rebirth_manager = rebirth_manager{}
    ButtonRadius : float = 50.0
    ButtonHeight : float = 25.0

    var TycoonBuildingIDMap<public> : [int]tycoon_building = map{}
    var CurrencyManager<public> : currency_manager = currency_manager{}
    var PlayerManager<public> : player_manager = player_manager{}
    var MazeManager<public> : maze_manager = maze_manager{}
    var UIManager<public> : user_interface_manager = user_interface_manager{}
    <# Most op thing ever lol #>
    var MaybeGameManager<public> : ?game_manager = false

    var PlayerStatsManager<public> : player_stats_manager = player_stats_manager{}
    var OriginalStartingPropsContainerTransform : transform = transform{}
    var OriginalClaimMutatorZoneTransform : transform = transform{}

    var OwnerPosition : vector3 = vector3{}
    var IsOccupied : logic = false


    UniqueBegin<public>(GameManager : game_manager)<suspends> : void =
        set OriginalStartingPropsContainerTransform = StartingPropsContainer.GetTransform()
        set OriginalClaimMutatorZoneTransform = ClaimMutatorZone.GetTransform()
        if ( ClaimMutatorZone.TeleportTo[OriginalClaimMutatorZoneTransform.Translation - vector3{Z := 3000.0}, rotation{}]) {}
        for ( BasicBuilding : Floor1TycoonBuildings, Building := tycoon_building[BasicBuilding], set TycoonBuildingIDMap[Building.GetID()] = Building):
            Building.UniqueBegin()
            if ( Mod[Building.GetID(), 8] = 0) then Sleep(0.0)
        for ( BasicBuilding : Floor2TycoonBuildings, Building := tycoon_building[BasicBuilding], set TycoonBuildingIDMap[Building.GetID()] = Building):
            Building.UniqueBegin()
            if ( Mod[Building.GetID(), 8] = 0) then Sleep(0.0)
        for ( BasicBuilding : Floor3TycoonBuildings, Building := tycoon_building[BasicBuilding], set TycoonBuildingIDMap[Building.GetID()] = Building):
            Building.UniqueBegin()
            if ( Mod[Building.GetID(), 8] = 0) then Sleep(0.0)
        for ( BasicBuilding : Floor4TycoonBuildings, Building := tycoon_building[BasicBuilding], set TycoonBuildingIDMap[Building.GetID()] = Building):
            Building.UniqueBegin()
            if ( Mod[Building.GetID(), 8] = 0) then Sleep(0.0)
        for ( BasicBuilding : Floor5TycoonBuildings, Building := tycoon_building[BasicBuilding], set TycoonBuildingIDMap[Building.GetID()] = Building):
            Building.UniqueBegin()
            if ( Mod[Building.GetID(), 8] = 0) then Sleep(0.0)
        for ( Hitbox : Hitboxes, Building := tycoon_building[Hitbox], set TycoonBuildingIDMap[Building.GetID()] = Building) do Building.UniqueBegin()
        for ( Dropper : Droppers, Building := tycoon_building[Dropper], set TycoonBuildingIDMap[Building.GetID()] = Building) do {Building.UniqueBegin(); Sleep(0.0)}
        if ( Building := tycoon_building[SeasonPassBuilding], set TycoonBuildingIDMap[Building.GetID()] = Building) then Building.UniqueBegin()
        if ( Building := tycoon_building[PhoneBuilding], set TycoonBuildingIDMap[Building.GetID()] = Building) then Building.UniqueBegin()
        if ( Building := tycoon_building[CurrencyCollector], set TycoonBuildingIDMap[Building.GetID()] = Building) then Building.UniqueBegin()
        if ( Building := tycoon_building[PumpkinCarvingStation], set TycoonBuildingIDMap[Building.GetID()] = Building) then Building.UniqueBegin()
        if ( Building := tycoon_building[VehicleSelectionBuilding], set TycoonBuildingIDMap[Building.GetID()] = Building) then Building.UniqueBegin()
        RebirthManager.UniqueBegin()
        CosmeticsManager.UniqueBegin(GameManager.CosmeticData)
        PerksManager.UniqueBegin()
        TimeGiftBox.UniqueBegin()

    # Init<public>(InCurrencyManager : currency_manager, InPlayerManager : player_manager, InPlayerStatsManager : player_stats_manager, InUIManager : user_interface_manager, InCosmeticsManager : cosmetics_manager, InMazeManager : maze_manager)<suspends> : void =
    Init<public>(GameManager : game_manager)<suspends> : void =
        Print("Initing Tycoon manager")
        set PlayerStatsManager = GameManager.PlayerStatsManager
        set CurrencyManager = GameManager.CurrencyManager
        set PlayerManager = GameManager.PlayerManager
        set MazeManager = GameManager.MazeManager
        set UIManager = GameManager.UIManager

        set MaybeGameManager = option{GameManager}
        CosmeticsManager.Init(Self, GameManager.CosmeticData)
        PerksManager.Init(Self)
        
        for ( ID->Building : TycoonBuildingIDMap):
            if ( Mod[ID, 5] = 0) then Sleep(0.0)
            Building.Init(Self)
        if:
            StartingPropsContainer.TeleportTo[OriginalStartingPropsContainerTransform.Translation - vector3{Z := 3000.0}, OriginalStartingPropsContainerTransform.Rotation]
            ClaimMutatorZone.TeleportTo[OriginalClaimMutatorZoneTransform]

        set IsOccupied = false
        loop:
            Agent := ClaimMutatorZone.AgentEntersEvent.Await()
            if:
                CustomPlayer := PlayerManager.GetCustomPlayerFromAgent[Agent]
                not CustomPlayer.MaybeTycoonManager?
            then:
                StartTycoon(CustomPlayer, GameManager)
                break

    StartTycoon(Owner : custom_player, GameManager : game_manager)<suspends> : void =
        Print("Starting TycooN!")
        set IsOccupied = true
        GameManager.PVPManager.SetPVPEnabledState(Owner, true)
        PlayerStats := PlayerStatsManager.GetStats(Owner.Player)
        TycoonDevices.TeamSelector.ChangeTeam(Owner.Agent)
        TycoonDevices.PlayerReference.Register(Owner.Player)
        TycoonDevices.RebirthButton.Enable()
        
        Owner.Init(Self, PlayerStats)
        Owner.TycoonLevel.GrantXP(900)  

        TimeGiftBox.Init(Owner)
        MazeManager.InitPlayer(Owner, Self)
        SecretCollectiblesManager.Init(Owner, GameManager.SecretCollectibleSettings)

        LoadData(Owner, GameManager, PlayerStats) <# Load stuff #>
        if ( Debug := DebugManager?) then Debug.Init(Owner, Self)
        if:
            StartingPropsContainer.TeleportTo[OriginalStartingPropsContainerTransform]
            ClaimMutatorZone.TeleportTo[OriginalClaimMutatorZoneTransform.Translation - vector3{Z := 3000.0}, rotation{}]
        
        spawn{ Update(Owner, GameManager)}  
        
    Update(Owner : custom_player, GameManager : game_manager)<suspends> : void =
        race:
            Sleep(Inf)
            DoSaveLoop(Owner)
            loop: <# Rebirth when player rebirts lol #>
                Agent := TycoonDevices.RebirthButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    Print("Player pressed rebirth button")
                    ShouldRebirth := RebirthManager.HandleRebirthButtonInteraction(Owner)
                    if ( ShouldRebirth?):
                        spawn{Rebirth(Owner, GameManager)}
                        break
            loop: <# Reset when player leaves #>
                LeavingPlayer := PlayerManager.CustomPlayerRemovedEvent.Await()
                if (Owner = LeavingPlayer):
                    spawn{ResetTycoon(Owner, GameManager)}
                    break

    DoSaveLoop(Owner : custom_player)<suspends> : void =
        var Time : int = 60 * 50
        loop:
            Sleep(1.0)
            set Time = Time - 1
            UIManager.SaveTimerHudDevice.SetText(StringToMessage("{FormatSecondsToMinutes(Time)}"))
            UIManager.SaveTimerHudDevice.Show(Owner.Player)
            if ( Time <= 0):
                SaveData(Owner, ?ResetTycoonProgress := false)
                Sleep(3.0)
                set Time = 60 * 20

    (Purchasable : purchasable).AwaitPurchase(Owner : custom_player)<suspends> : void =
        Sleep(1.2)
        var PurchaseButtonPosition : vector3 = Purchasable.GetPurchaseButton().GetTransform().Translation
        race:
            ResetEvent().Await()             
            loop:
                Sleep(5.0)
                set PurchaseButtonPosition = Purchasable.GetPurchaseButton().GetTransform().Translation
            loop:
                Sleep(0.0) 
                if:
                    Abs(Owner.FortCharacter.GetTransform().Translation.X - PurchaseButtonPosition.X) <= ButtonRadius
                    Abs(Owner.FortCharacter.GetTransform().Translation.Y - PurchaseButtonPosition.Y) <= ButtonRadius
                    Abs(Owner.FortCharacter.GetTransform().Translation.Z - PurchaseButtonPosition.Z - 65.0) <= ButtonHeight
                then:
                    Transaction := currency_transaction{ Type := Purchasable.GetPurchaseCurrencyType(), Amount := Purchasable.GetPrice()}
                    if ( CurrencyManager.ValidatePurchase[Owner, Transaction]):
                        if (Purchasable.GetPurchaseCurrencyType() <> currency_type.Candy):
                            CurrencyManager.DecreaseCurrency(Owner, Transaction)
                            if ( TycoonDevices.PurchaseVFXCash.TeleportTo[Owner.FortCharacter.GetTransform()]) then TycoonDevices.PurchaseVFXCash.Restart()
                        else:
                            if ( TycoonDevices.PurchaseVFXCandy.TeleportTo[Owner.FortCharacter.GetTransform()]) then TycoonDevices.PurchaseVFXCandy.Restart()
                        Purchasable.ResolvePurchase(Owner)
                        
                        TycoonDevices.PurchaseAudio.Play(Owner.Player)
                        TycoonDevices.PurchaseFeedbackHud.SetText(PurchaseSuccessMessage)
                        TycoonDevices.PurchaseFeedbackHud.Show(Owner.Player)
                        if ( TycoonBuildingID := tycoon_building[Purchasable].GetID()):
                            XPGain := GetTycoonBuildingXPGain(TycoonBuildingID)
                            Owner.TycoonLevel.GrantXP(XPGain)
                            TycoonBuildingPurchasedEvent.Signal(
                                tycoon_building_purchase_result:
                                    TycoonBuildingID := TycoonBuildingID
                                    Transaction := Transaction
                            )
                        return
                    else:
                        TycoonDevices.PurchaseFailAudio.Play(Owner.Player)
                        TycoonDevices.PurchaseFeedbackHud.SetText(PurchaseFailMessage)
                        TycoonDevices.PurchaseFeedbackHud.Show(Owner.Player)
                        Print("Not enough currency!")
                        Sleep(2.0)
                # else:
                #     Sleep(Min(3.0, ))

    (Upgradable : upgradable).AwaitUpgrade(Owner : custom_player)<suspends> : void =
        var UpgradeButtonPosition : vector3 = vector3{}
        race:
            ResetEvent().Await()
            loop: <# Periodically update button position #>
                Sleep(5.0)
                if ( CurrentUpgradeButtonPosition := Upgradable.GetCurrentUpgradeButton[].GetTransform().Translation):
                    set UpgradeButtonPosition = CurrentUpgradeButtonPosition
            loop: <# Await Upgrade events #>
                Sleep(1.25)
                if ( CurrentUpgradeButtonPosition := Upgradable.GetCurrentUpgradeButton[].GetTransform().Translation):
                    set UpgradeButtonPosition = CurrentUpgradeButtonPosition
                    race:
                        ResetEvent().Await()
                        loop:
                            Sleep(0.1)
                            if:
                                Abs(Owner.FortCharacter.GetTransform().Translation.X - UpgradeButtonPosition.X) <= ButtonRadius
                                Abs(Owner.FortCharacter.GetTransform().Translation.Y - UpgradeButtonPosition.Y) <= ButtonRadius
                                Abs(Owner.FortCharacter.GetTransform().Translation.Z - UpgradeButtonPosition.Z - 65.0) <= ButtonHeight
                            then:
                                if ( CurrencyType := Upgradable.GetCurrentUpgradeCurrencyType[], Price := Upgradable.GetCurrentUpgradePrice[]):
                                    Transaction := currency_transaction{Type := CurrencyType, Amount := Price }
                                    if ( CurrencyManager.ValidatePurchase[Owner, Transaction]):
                                        if (Upgradable.GetCurrentUpgradeCurrencyType[] <> currency_type.Candy):
                                            CurrencyManager.DecreaseCurrency(Owner, Transaction)
                                            if ( TycoonDevices.PurchaseVFXCash.TeleportTo[Owner.FortCharacter.GetTransform()]) then TycoonDevices.PurchaseVFXCash.Restart()
                                        else:
                                            if ( TycoonDevices.PurchaseVFXCandy.TeleportTo[Owner.FortCharacter.GetTransform()]) then TycoonDevices.PurchaseVFXCandy.Restart()
                                        Upgradable.ResolveUpgrade(Owner)
                                        TycoonDevices.PurchaseAudio.Play(Owner.Player)
                                        TycoonDevices.PurchaseFeedbackHud.SetText(PurchaseSuccessMessage)
                                        TycoonDevices.PurchaseFeedbackHud.Show(Owner.Player)
                                        if ( TycoonBuildingID := tycoon_building[Upgradable].GetID()):
                                            XPGain := GetTycoonBuildingXPGain(TycoonBuildingID)
                                            Owner.TycoonLevel.GrantXP(XPGain)
                                            TycoonBuildingUpgradedEvent.Signal(
                                                tycoon_building_upgrade_result:
                                                    TycoonBuildingID := TycoonBuildingID
                                                    Transaction := Transaction
                                            )
                                        
                                        break
                                    else:
                                        TycoonDevices.PurchaseFailAudio.Play(Owner.Player)
                                        TycoonDevices.PurchaseFeedbackHud.SetText(PurchaseFailMessage)
                                        TycoonDevices.PurchaseFeedbackHud.Show(Owner.Player)
                                        Sleep(2.0)
                                else:
                                    Print("Couldn't get upgradable info")
                                    break
                else:
                    Print("No more levels!")
                    break

    # When a purchasable is purchaed 
    (Purchasable : purchasable).ResolvePurchase(Owner : custom_player) : void =
        Purchasable.Purchase(Owner)
        TycoonDevices.PurchaseAudio.Play(Owner.Player)
        if ( Accolade := TycoonDevices.PurchaseAccolades[GetRandomInt(0, TycoonDevices.PurchaseAccolades.Length -1)]) then Accolade.Award(Owner.Player)
        if ( TycoonBuilding := tycoon_building[Purchasable]):      
            CurrencyCollector.AddPassiveIncome(Owner, CurrencyManager, TycoonBuilding.GetPassiveIncome())
            SaveManager.RemoveUnlockedBuilding(TycoonBuilding)
            SaveManager.AddPurchasedBuilding(TycoonBuilding)

        for ( NextUnlockID : Purchasable.GetNextBuildingUnlockIDs()):
            # If this building unlocks a purchasable building
            if ( NextPurchasable := purchasable[TycoonBuildingIDMap[NextUnlockID]], NextPurchasable.GetPurchaseStatus() = purchase_status.Locked, TycoonBuilding := tycoon_building[NextPurchasable]):
                NextPurchasable.Unlock(Owner)
                SaveManager.AddUnlockedBuilding(TycoonBuilding)
                spawn{ NextPurchasable.AwaitPurchase(Owner)}

            # If this building unlocks an upgradable building
            else if (NextUpgradable := upgradable[TycoonBuildingIDMap[NextUnlockID]], not NextUpgradable.IsUnlocked[], TycoonBuilding := tycoon_building[NextUpgradable]):
                NextUpgradable.Unlock(Owner)
                SaveManager.AddUnlockedBuilding(TycoonBuilding)
                spawn{ NextUpgradable.AwaitUpgrade(Owner) }
        
    # When an upgradable is upgraded (once)
    (Upgradable : upgradable).ResolveUpgrade(Owner : custom_player) : void =
        Upgradable.Upgrade(Owner)
        if ( Accolade := TycoonDevices.PurchaseAccolades[GetRandomInt(0, TycoonDevices.PurchaseAccolades.Length -1)]) then Accolade.Award(Owner.Player)
        
        if ( TycoonBuilding := tycoon_building[Upgradable]):
            CurrencyCollector.AddPassiveIncome(Owner, CurrencyManager, TycoonBuilding.GetPassiveIncome())
            SaveManager.AddUpgradableBuilding(TycoonBuilding, Upgradable.GetCurrentLevel())
            SaveManager.RemoveUnlockedBuilding(TycoonBuilding)
            
        for ( ID : Upgradable.GetUnlockedBulidingIDs(), TycoonBuilding := TycoonBuildingIDMap[ID]):
            if ( UnlockedPurchasable := purchasable[TycoonBuilding], UnlockedPurchasable.GetPurchaseStatus() = purchase_status.Locked):
                SaveManager.AddUnlockedBuilding(TycoonBuilding)
                UnlockedPurchasable.Unlock(Owner)
                spawn{ UnlockedPurchasable.AwaitPurchase(Owner)}
            if ( UnlockedUpgradable := upgradable[TycoonBuilding], not UnlockedUpgradable.IsUnlocked[]):
                SaveManager.AddUnlockedBuilding(TycoonBuilding)
                UnlockedUpgradable.Unlock(Owner)
                spawn{ UnlockedUpgradable.AwaitUpgrade(Owner) }

    Rebirth(Owner : custom_player, GameManager : game_manager)<suspends> : void =
        Print("Rebirthing!")
        TycoonDevices.RebirthAccolade.Award(Owner.Player)
        TycoonDevices.ItemRemover.Remove(Owner.Player)
        SecretCollectiblesManager.Reset(Owner, GameManager.SecretCollectibleSettings)
        Owner.FortCharacter.PutInStasis(stasis_args{})
        Owner.FortCharacter.SetVulnerability(false)
        Owner.SetRebirths(Owner.Rebirths + 1)
        
        SaveData(Owner, ?ResetTycoonProgress := true)
        
        ResetTycoon(Owner, GameManager)
        Owner.Reset()
        Owner.FortCharacter.ReleaseFromStasis()
        Owner.FortCharacter.SetVulnerability(true)
        Sleep(0.0)
        Owner.FortCharacter.Damage(10000.0)

    SaveData(Owner : custom_player, ?ResetTycoonProgress : logic)<suspends> : void =
        Print("Saving stats!")
        TycoonDevices.RebirthButton.Disable()
        UIManager.SaveInProgressHudDevice.Show(Owner.Player)
        Stats := SaveManager.GetPlayerStats(Owner, Self, ?ShouldResetTycoonStats := ResetTycoonProgress)
        sync:
            Sleep(1.0)
            PlayerStatsManager.SaveTycoonStats(Owner, Stats)
        UIManager.SaveInProgressHudDevice.Hide(Owner.Player)
        UIManager.SaveCompleteHudDevice.Show(Owner.Agent, StubMessage, ?DisplayTime := 3.0)
        TycoonDevices.RebirthButton.Enable()
            
    LoadData(Owner : custom_player, GameManager : game_manager, PlayerStats : player_stats)<suspends> : void =
        PerksManager.LoadData(Owner, Self, PlayerStats)
        CosmeticsManager.LoadData(Owner, GameManager.CosmeticData, PlayerStats)
        # Load unlocked buildings
        UnlockedBuildingIDs := PlayerStats.BuildingStats.UnlockedBuildingIDs
        for ( UnlockedBuildingID : UnlockedBuildingIDs, TycoonBuilding := TycoonBuildingIDMap[UnlockedBuildingID], not SaveManager.IsBuildingUnlocked[TycoonBuilding]):
            Print("Loading unlocked building: {UnlockedBuildingID}")
            if ( Purchasable := purchasable[TycoonBuilding]):
                Purchasable.Unlock(Owner, ?PlayAnimations := false)
                spawn{ Purchasable.AwaitPurchase(Owner)}
            else if ( Upgradable := upgradable[TycoonBuilding]):
                Upgradable.Unlock(Owner, ?PlayAnimations := false)
                spawn{ Upgradable.AwaitUpgrade(Owner)}
            SaveManager.AddUnlockedBuilding(TycoonBuilding)
        # Load purchasables
        for ( PurchasableID : PlayerStats.BuildingStats.PurchasedBuildingIDs, TycoonBuilding := TycoonBuildingIDMap[PurchasableID], Purchasable := purchasable[TycoonBuilding], not SaveManager.IsBuildingPurchased[TycoonBuilding]):
            Print("Loading Purchasable { PurchasableID}")
            Purchasable.Purchase(Owner, ?PlayAnimations := false)
            CurrencyCollector.AddPassiveIncome(Owner, CurrencyManager, TycoonBuilding.GetPassiveIncome())
            SaveManager.RemoveUnlockedBuilding(TycoonBuilding)
            SaveManager.AddPurchasedBuilding(TycoonBuilding)
            if ( Mod[PurchasableID, 4] = 0) then Sleep(0.0)
        #Print("Finished laoding purchasables")
        # Load upagradable
        for ( UpgradableID->Level : PlayerStats.BuildingStats.UpgradableBuildingLevelMap, TycoonBuilding := TycoonBuildingIDMap[UpgradableID], Upgradable := upgradable[TycoonBuilding], not SaveManager.IsBuildingUpgraded[TycoonBuilding]):
            Print("Loading upgradable: {UpgradableID}")
            for ( I := 1..Level):
                Upgradable.Upgrade(Owner, ?PlayAnimations := false)
                CurrencyCollector.AddPassiveIncome(Owner, CurrencyManager, TycoonBuilding.GetPassiveIncome())
            if ( Upgradable.GetCurrentLevel() < Upgradable.GetMaxLevel()):
                spawn{ Upgradable.AwaitUpgrade(Owner)}
                
            SaveManager.RemoveUnlockedBuilding(TycoonBuilding)
            SaveManager.AddUpgradableBuilding(TycoonBuilding, Level)
            Sleep(0.0)
        
        
        RebirthManager.LoadData(Owner, Self, PlayerStats)
        CurrencyCollector.SetStoredCash(PlayerStats.BuildingStats.CurrencyCollectorCash)

    ResetTycoon(Owner : custom_player, GameManager : game_manager)<suspends> : void =
        if ( Owner.Player.IsActive[]) then TycoonDevices.UIRemoveChannel.Transmit(option{Owner.Agent})
        ResetEvent().Signal()
        MazeManager.RemovePlayer(Owner)
        TycoonDevices.PlayerReference.Clear()
        CosmeticsManager.Reset()
        SecretCollectiblesManager.Reset(Owner, GameManager.SecretCollectibleSettings)
        PerksManager.Reset()
        TimeGiftBox.Reset()
        for ( Index->Building : TycoonBuildingIDMap, Resetable := resetable[Building]):
            Resetable.Reset()
            if ( Mod[Index, 6] = 0) then Sleep(0.0)
     
        SaveManager.Reset()
        spawn{Init(GameManager)}

    GetUnlockedBuildings<public>()<transacts> : []tycoon_building = for ( ID : SaveManager.UnlockedBuildingIDs, Building := TycoonBuildingIDMap[ID]) do Building
    GetTycoonBuildingXPGain(TycoonBuildingID : int)<transacts> : int =
        <# Normal Floor Building #>
        if ( TycoonBuildingID >= 100):
            #return (TycoonBuildingID / 100)
            return Clamp((10 * (Ceil(TycoonBuildingID / 100)) + 3 * Mod[TycoonBuildingID, 100]), 25, 1000) or 25
        <# Droppers #>
        if ( TycoonBuildingID <= -10 and TycoonBuildingID >= -19):
            return Clamp(25 * (Mod[TycoonBuildingID * -1, 10] or 1), 25, 500)
        if ( TycoonBuildingID <= -1 and TycoonBuildingID >= -9):
            return Clamp(25 * (Mod[TycoonBuildingID * -1, 10] or 1), 25, 500)
        if ( TycoonBuildingID < 100):
            return 50
        <# Other Special Building - Battle pass, etc. #>
        if ( TycoonBuildingID < -30):
            return 25
        0
        
    IsBuildingPurchased<public>(TycoonBuildingID : int)<transacts><decides> : void = purchasable[TycoonBuildingIDMap[TycoonBuildingID]].GetPurchaseStatus() = purchase_status.Purchased
    Reset<override>() : void = {}
    ResetEvent<override>() : event() = TycoonResetEvent

tycoon_building_purchase_result<public> := struct:
    TycoonBuildingID<public> : int
    Transaction<public> : currency_transaction

tycoon_building_upgrade_result<public> := struct:
    TycoonBuildingID<public> : int
    Transaction<public> : currency_transaction

tycoon_devices := class<concrete>:
    @editable       RebirthButton : button_device = button_device{}
    @editable       PlayerReference : player_reference_device = player_reference_device{}
    @editable       TeamSelector : class_and_team_selector_device = class_and_team_selector_device{}
    @editable       PurchaseAccolades : []accolades_device = array{}
    @editable       RebirthAccolade : accolades_device = accolades_device{}
    @editable       PurchaseVFXCash : vfx_spawner_device = vfx_spawner_device{}
    @editable       PurchaseVFXCandy : vfx_spawner_device = vfx_spawner_device{}
    @editable       PurchaseAudio : audio_player_device = audio_player_device{}
    @editable       PurchaseFailAudio : audio_player_device = audio_player_device{}
    @editable       PurchaseFeedbackHud : hud_message_device = hud_message_device{}
    @editable       ItemRemover : item_remover_device = item_remover_device{}
    @editable       UIRemoveChannel : channel_device = channel_device{}
    
debug := class<concrete>:
    @editable       SaveButton : button_device = button_device{}
    @editable       ResetButton : button_device = button_device{}
    @editable       FreeXPButton : button_device = button_device{}
    @editable       FreeCashButton : button_device = button_device{}
    @editable       FreeSubscribersButton : button_device = button_device{}
    @editable       XPGain : int = 0
    @editable       CashGain : int = 0
    @editable       SubscribersGain : int = 0
    var IsInited : logic = false

    Init(Owner : custom_player, TycoonManager : tycoon_manager) : void =
        if ( IsInited?) then return
        set IsInited = true
        spawn{Update(Owner, TycoonManager)}

    Update(Owner : custom_player, TycoonManager : tycoon_manager)<suspends> : void =
        race:
            TycoonManager.ResetEvent().Await()
            loop:
                Agent := FreeXPButton.InteractedWithEvent.Await()
                Owner.TycoonLevel.GrantXP(XPGain)
            loop:
                Agent := FreeCashButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    TycoonManager.CurrencyManager.IncreaseCurrency(Owner, currency_transaction{Type := currency_type.Cash, Amount := CashGain})
            loop:
                Agent := FreeSubscribersButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    TycoonManager.CurrencyManager.IncreaseCurrency(Owner, currency_transaction{Type := currency_type.Candy, Amount := SubscribersGain})