using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { Materials }

aura_selection_manager<public> := class<concrete>:
    @editable       SelectButton : button_device = button_device{}
    @editable       CycleLeftButton : button_device = button_device{}
    @editable       CycleRightButton : button_device = button_device{}
    @editable       EquipButtonSpriteProp : creative_prop = creative_prop{}
    @editable       Billboard : billboard_device = billboard_device{}
    @editable       NPCSpawner : npc_spawner_device = npc_spawner_device{}
    
    ResetEvent : event() = event(){}

    var MannequinAgent : ?agent = false
    var CurrentAuraArrayIndex : int = 0
    var CurrentAuraID : int = -1

    EquipMaterial : MI_Sprite_Equip_Button_material = MI_Sprite_Equip_Button_material{}
    UnequipMaterial : MI_Sprite_Unequip_Button_material = MI_Sprite_Unequip_Button_material{}

    UniqueBegin<public>() : void =
        {}

    Init<public>() : void =
        Billboard.HideText()
        EquipButtonSpriteProp.SetMaterial(EquipMaterial)
        Print("JFD;ak")

    LoadData<public>(Owner : custom_player, CosmeticsManager : cosmetics_manager) : void =
        if ( CosmeticData := CosmeticsManager.MaybeCosmeticData?):
            Billboard.ShowText()
            NPCSpawner.Enable()
            spawn{Update(Owner, CosmeticsManager, CosmeticData)}
        else:
            Print("Fatal Error [Aura Selection Manager] - Cosmetic Data not found!")

    Reset<public>() : void =
        NPCSpawner.DespawnAll(false)
        NPCSpawner.Disable()
        ResetEvent.Signal()

    Update(Owner : custom_player, CosmeticsManager : cosmetics_manager, CosmeticData : global_cosmetic_data)<suspends> : void =
        AssignMannequin()
        Sleep(0.0)
        if ( StarterAuraID := CosmeticsManager.SortedAuraIndices[0], AuraVFX := CosmeticData.AuraVFXPowerups[StarterAuraID]):
            set CurrentAuraArrayIndex = 0
            set CurrentAuraID = StarterAuraID
            PreviewAura(CosmeticsManager, AuraVFX)
        race:
            ResetEvent.Await()
            loop: <# Cycle aura left #>
                Agent := CycleLeftButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    if:
                        ArrayIndex := Mod[CurrentAuraArrayIndex - 1, CosmeticsManager.SortedAuraIndices.Length]
                        AuraID := CosmeticsManager.SortedAuraIndices[ArrayIndex]
                        AuraVFX := CosmeticData.AuraVFXPowerups[AuraID]
                    then:
                        set CurrentAuraArrayIndex = ArrayIndex
                        set CurrentAuraID = AuraID
                        PreviewAura(CosmeticsManager, AuraVFX)
                        SetEquipButtonState(logic{CosmeticsManager.EquippedAuraID <> AuraID})

            loop: <# Cycle aura right #>
                Agent := CycleRightButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    if:
                        ArrayIndex := Mod[CurrentAuraArrayIndex + 1, CosmeticsManager.SortedAuraIndices.Length]
                        AuraID := CosmeticsManager.SortedAuraIndices[ArrayIndex]
                        AuraVFX := CosmeticData.AuraVFXPowerups[AuraID]
                    then:
                        set CurrentAuraArrayIndex = ArrayIndex
                        set CurrentAuraID = AuraID
                        PreviewAura(CosmeticsManager, AuraVFX)
                        SetEquipButtonState(logic{CosmeticsManager.EquippedAuraID <> AuraID})

            loop: <# Equip Button #>
                Agent := SelectButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    if ( CurrentAuraID <> -1, CosmeticsManager.EquippedAuraID <> CurrentAuraID):
                        CosmeticsManager.EquipAura(Owner, CurrentAuraID)
                        SetEquipButtonState(false)
                    else:
                        CosmeticsManager.UnequipAura(Owner)
                        SetEquipButtonState(true)
                    
            loop:
                Sleep(13.0)
                if ( AuraVFX := CosmeticData.AuraVFXPowerups[CurrentAuraID]) then PreviewAura(CosmeticsManager, AuraVFX)

    AssignMannequin()<suspends> : void =
        race:
            block:
                Agent := NPCSpawner.SpawnedEvent.Await()
                set MannequinAgent = option{Agent}
                return
            loop:
                Sleep(0.0)
                NPCSpawner.Spawn()
                Sleep(5.0)

    PreviewAura(CosmeticsManager : cosmetics_manager, VFXPowerup : visual_effect_powerup_device) : void =
        if ( Agent := MannequinAgent?, CosmeticData := CosmeticsManager.MaybeCosmeticData?):
            CosmeticData.AuraClearChannel.Transmit(option{Agent})
            Billboard.SetText(StringToMessage("{CurrentAuraArrayIndex + 1} / {CosmeticsManager.SortedAuraIndices.Length}"))
            Billboard.UpdateDisplay()
            VFXPowerup.Pickup(Agent)

    SetEquipButtonState(Bool : logic) : void =
        if ( Bool?):
            Print("Setting material: Equip")
            EquipButtonSpriteProp.SetMaterial(EquipMaterial)
        else:
            Print("Setting material: Unequip")
            EquipButtonSpriteProp.SetMaterial(UnequipMaterial)

