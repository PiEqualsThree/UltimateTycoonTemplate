using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Random }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }

pumpkin_carving_tutorial_settings<public> := class<concrete>:
    @editable       ShopHud : hud_message_device = hud_message_device{}
    @editable       CustomerHud : hud_message_device = hud_message_device{}
    @editable       DecorateHud : hud_message_device = hud_message_device{}
    @editable       PumpkinCollectionHud : hud_message_device = hud_message_device{}
    @editable       PumpkinDropOffHud : hud_message_device = hud_message_device{}
    @editable       PumpkinCarvingHud : hud_message_device = hud_message_device{}

    @editable       PumpkinCollectionBeacon : beacon_device = beacon_device{}
    @editable       PumpkinDropOffBeacon : beacon_device = beacon_device{}
    @editable       PumpkinCarvingBeacon : beacon_device = beacon_device{}

    @editable       PumpkinCollectionCamera : gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}
    @editable       PumpkinDropOffCamera : gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}
    @editable       PumpkinCarvingCamera : gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}
    @editable       PumpkinShopCamera : gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}
    

    QueueDisplayPumpkinCollectionTutorial<public>(CustomPlayer : custom_player, TutorialTriggerPointEvent : event(), ?DelayTime : float)<suspends> : void =
        CustomPlayer.FortCharacter.SetVulnerability(false)
        Sleep(DelayTime)
        PumpkinCollectionBeacon.Enable()
        PumpkinCollectionHud.Show(CustomPlayer.Player)
        PumpkinCollectionBeacon.AddToShowList(CustomPlayer.Player)
        PumpkinCollectionCamera.AddTo(CustomPlayer.Player)
        Sleep(3.0)
        PumpkinCollectionCamera.RemoveFrom(CustomPlayer.Player)

        TutorialTriggerPointEvent.Await()
        PumpkinCollectionHud.Hide(CustomPlayer.Player)
        PumpkinCollectionBeacon.RemoveFromShowList(CustomPlayer.Player)
        PumpkinCollectionBeacon.Disable()
        CustomPlayer.FortCharacter.SetVulnerability(true)

    QueueDisplayDropOffTutorial<public>(CustomPlayer : custom_player, TutorialTriggerPointEvent : event(), ?DelayTime : float)<suspends> : void =
        CustomPlayer.FortCharacter.SetVulnerability(false)
        Sleep(DelayTime)
        PumpkinDropOffHud.Show(CustomPlayer.Player)
        PumpkinDropOffBeacon.Enable()
        PumpkinDropOffBeacon.AddToShowList(CustomPlayer.Player)
        PumpkinDropOffCamera.AddTo(CustomPlayer.Player)
        Sleep(3.0)
        PumpkinDropOffCamera.RemoveFrom(CustomPlayer.Player)

        TutorialTriggerPointEvent.Await()
        PumpkinDropOffHud.Hide(CustomPlayer.Player)
        PumpkinDropOffBeacon.RemoveFromShowList(CustomPlayer.Player)
        PumpkinDropOffBeacon.Disable()
        CustomPlayer.FortCharacter.SetVulnerability(true)

    QueueCarvingTutorial<public>(CustomPlayer : custom_player, DismissTutorialEvent : event(), ?DelayTime : float = 0.0)<suspends> : void =
        CustomPlayer.FortCharacter.SetVulnerability(false)
        Sleep(DelayTime)
        PumpkinCarvingHud.Show(CustomPlayer.Player)
        PumpkinCarvingCamera.AddTo(CustomPlayer.Player)
        PumpkinCarvingBeacon.Enable()
        PumpkinCarvingBeacon.AddToShowList(CustomPlayer.Player)
        Sleep(3.0)
        PumpkinCarvingCamera.RemoveFrom(CustomPlayer.Player)
        DismissTutorialEvent.Await()
        PumpkinCarvingBeacon.RemoveFromShowList(CustomPlayer.Player)
        PumpkinCarvingHud.Hide(CustomPlayer.Player)
        PumpkinCarvingBeacon.Disable()
        CustomPlayer.FortCharacter.SetVulnerability(true)
        
    QueueDisplayDecorateTutorial<public>(CustomPlayer : custom_player, ?DelayTime : float = 0.0)<suspends> : void =
        CustomPlayer.FortCharacter.SetVulnerability(false)
        Sleep(DelayTime)
        CustomPlayer.FortCharacter.SetVulnerability(true)

    QueueDisplayCustomerTutorial<public>(CustomPlayer : custom_player, ?DelayTime : float = 0.0)<suspends> : void =
        CustomPlayer.FortCharacter.SetVulnerability(false)
        Sleep(DelayTime)
        CustomerHud.Show(CustomPlayer.Player)
        CustomPlayer.FortCharacter.SetVulnerability(true)

    QueueDisplayShopTutorial<public>(CustomPlayer : custom_player, ?DelayTime : float)<suspends> : void =
        CustomPlayer.FortCharacter.SetVulnerability(false)
        Sleep(DelayTime)
        PumpkinShopCamera.AddTo(CustomPlayer.Player)
        Sleep(2.5)
        PumpkinShopCamera.RemoveFrom(CustomPlayer.Player)
        ShopHud.Show(CustomPlayer.Player)
        CustomPlayer.FortCharacter.SetVulnerability(true)