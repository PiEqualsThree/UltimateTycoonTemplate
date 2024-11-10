using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

aura_selection_manager<public> := class<concrete>:
    @editable       SelectButton : button_device = button_device{}
    @editable       CycleLeftButton : button_device = button_device{}
    @editable       CycleRightButton : button_device = button_device{}
    @editable       Billboard : billboard_device = billboard_device{}
    @editable       NPCSpawner : npc_spawner_device = npc_spawner_device{}
    
    ResetEvent : event() = event(){}

    var MannequinAgent : ?agent = false
    var SelectedAuraArrayIndex : int = 0
    var CurrentAuraIndex : int = 0

    UniqueBegin<public>() : void =
        {}

    Init<public>() : void =
        Billboard.HideText()
        Print("JFD;ak")

    LoadData<public>(Owner : custom_player) : void =
        #CosmeticsManager.UnlockAura(Owner, 0)
        Billboard.ShowText()
        NPCSpawner.Enable()
        spawn{Update(Owner)}

    Reset<public>() : void =
        NPCSpawner.DespawnAll(false)
        NPCSpawner.Disable()
        ResetEvent.Signal()

    Update(Owner : custom_player)<suspends> : void =
        AssignMannequin()
        CosmeticData := Owner.GetCosmeticsData()
        Sleep(1.5)
        race:
            ResetEvent.Await()
            loop: <# Cycle aura left #>
                Agent := CycleLeftButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    set SelectedAuraArrayIndex = Mod[SelectedAuraArrayIndex - 1, CosmeticData.SortedAuraIndices.Length] or SelectedAuraArrayIndex
                    set CurrentAuraIndex = CosmeticData.SortedAuraIndices[SelectedAuraArrayIndex] or CurrentAuraIndex
                    PreviewAura(CurrentAuraIndex, CosmeticData.SortedAuraIndices)
            loop:<# Cycle aura right #>
                Agent := CycleRightButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    set SelectedAuraArrayIndex = Mod[SelectedAuraArrayIndex + 1, CosmeticData.SortedAuraIndices.Length] or SelectedAuraArrayIndex
                    set CurrentAuraIndex = CosmeticData.SortedAuraIndices[SelectedAuraArrayIndex] or CurrentAuraIndex
                    PreviewAura(CurrentAuraIndex, CosmeticData.SortedAuraIndices)
            loop: <# Equip Button #>
                Agent := SelectButton.InteractedWithEvent.Await()
                if ( Owner.Agent = Agent):
                    #CosmeticsManager.EquipAura(Owner, CurrentAuraIndex)
                    PreviewAura(CurrentAuraIndex, CosmeticData.SortedAuraIndices)
                    
            loop:
                PreviewAura(CurrentAuraIndex, CosmeticData.SortedAuraIndices)
                Sleep(10.0)

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

    PreviewAura(AuraIndex : int, SortedAuraIndices : []int) : void =
        {}
        # if ( Agent := MannequinAgent?, AuraVFX := CosmeticsManager.AuraVFXPowerups[AuraIndex]):
        #     Billboard.SetText(StringToMessage("{SelectedAuraArrayIndex + 1} / {SortedAuraIndices.Length}"))
        #     Billboard.UpdateDisplay()
        #     AuraVFX.Pickup(Agent)

