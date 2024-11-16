using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/AI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Assets }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { UIStuff }
using { UIStuff.CosmeticsUI}

player_cosmetic_unlock_widget<public> := class:
    RewardTextureBlock : texture_block = texture_block{DefaultImage := T_Block_Icon, DefaultDesiredSize := vector2{ X := 128.0, Y := 128.0}}
    RewardNameTextBlock : text_block = text_block{DefaultTextColor := MakeColorFromHex("FFFFFFFF")}
    var RootWidget : widget = overlay{}


    UniqueBegin<public>(CustomPlayer : custom_player) : void =
        set RootWidget = overlay:
            Slots := array:
                overlay_slot:
                    Widget := RewardTextureBlock
                overlay_slot:
                    Widget := RewardNameTextBlock
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Top := -40.0}

        CustomPlayer.Canvas.AddWidget(
            canvas_slot:
                Widget := RootWidget
                Anchors := anchors{Minimum := vector2{ X := 0.5}, Maximum := vector2{ X := 0.5}}
                Alignment := vector2{ X := 0.5}
                Offsets := margin{Top := 45.0}
        )
        RootWidget.SetVisibility(widget_visibility.Hidden)

    QueueDisplayAuraUnlock(AuraID : int) : void =
        {}

    QueueDisplayVehicleUnlock(VehicleID : int) : void =
        {}

    QueueDisplayCosmeticUnlock(CosmeticID : int) : void =
        {}