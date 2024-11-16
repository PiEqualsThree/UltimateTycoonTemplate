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

custom_income_widget<public> := class:
    TextBlock<public> : text_block = text_block{DefaultTextColor := NamedColors.White, DefaultShadowOffset := option{vector2{ X := 3.0, Y := 3.0}}, DefaultShadowOpacity := 1.0}
    TextureBlock<public> : texture_block = texture_block{DefaultImage := T_Place_Holder}
    SizeBlock<public> : color_block = color_block{DefaultDesiredSize := vector2{}}

    var RootWidget<public> : widget = overlay{}
    var IsMoving<public> : logic = false

    Init<public>() : void =
        set RootWidget = stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                stack_box_slot:
                    Widget := SizeBlock
                stack_box_slot:
                    Widget := stack_box:
                        Orientation := orientation.Horizontal
                        Slots := array:
                            stack_box_slot:
                                Widget := TextureBlock
                                HorizontalAlignment := horizontal_alignment.Left
                                VerticalAlignment := vertical_alignment.Top
                                Padding := margin{Right := 10.0}
                            stack_box_slot:
                                Widget := TextBlock
                
    SetWidgetImage<public>(Image : texture) : void = TextureBlock.SetImage(Image)
    SetWidgetText<public>(Text : string) : void = TextBlock.SetText(StringToMessage(Text))

    Move<public>(DeltaY : float, StartingTextureBlockSize : vector2, Amount : int)<suspends> : void =  
        Target := vector2{ X := 0.0, Y := 0.0}
        Start := vector2{ X := 0.0, Y := DeltaY}
        Intervals := 45
        IntervalsF := 1.0 * Intervals
        var CurrentInterval : int = 0
        set IsMoving = true
        TextBlock.SetTextOpacity(1.0)
        TextBlock.SetShadowOpacity(1.0)
        TextureBlock.SetDesiredSize(StartingTextureBlockSize)
        SizeBlock.SetDesiredSize(Start)
        RootWidget.SetVisibility(widget_visibility.Visible)
        loop:
           
            set CurrentInterval = CurrentInterval + 1
            if ( CurrentInterval >= Intervals) then break
            Alpha := (1.0 * CurrentInterval) / IntervalsF
            Size := Lerp(Start, Target, Alpha)
            Opacity : clamped_float = clamped_float[Clamp(1.0 - Alpha, 0.0, 1.0)] or 1.0
            SizeBlock.SetDesiredSize(Size)
            #TextBlock.SetText(StringToMessage("+ {FormatNumber(Ceil[Lerp(0.0, 1.0 * Amount, Min(Alpha * 5.0, 1.0))] or Amount)}"))
            TextBlock.SetTextOpacity(Opacity)
            TextBlock.SetShadowOpacity(Opacity)
            TextureBlock.SetDesiredSize(Clamp(1.0 - Alpha, 0.3, 1.0) * StartingTextureBlockSize)
           
            Sleep(0.0)

        set IsMoving = false
        RootWidget.SetVisibility(widget_visibility.Hidden)
        Sleep(0.2)
            
    GetRootWidget<public>()<transacts> : widget = RootWidget

