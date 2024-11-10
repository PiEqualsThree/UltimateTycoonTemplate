using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

GetLookAtRotation(V0 : vector3, V1 : vector3) : rotation = 
    if (LookDirection := (V1 - V0).MakeUnitVector[]):
        Yaw := RadiansToDegrees(ArcTan(LookDirection.Y, LookDirection.X))
        return NewRotation := MakeRotationFromYawPitchRollDegrees(Yaw, 0.0, 0.0)
    rotation{}

FormatSecondsToMinutes(Seconds : int) : string = 
    Minutes := Floor(Seconds / 60) or 0
    RemainingSeconds := Mod[Seconds, 60] or 0
    return "{Minutes < 10 and "0{Minutes}" or "{Minutes}"}:{RemainingSeconds < 10 and "0{RemainingSeconds}" or "{RemainingSeconds}"}"

FormatSecondsToHours(Seconds : int) : string = 
    Hours := Floor(Seconds / 3600) or 0
    RemainingSeconds := Mod[Seconds, 3600] or 0
    return "{Hours > 9 and "{Hours}" or "0{Hours}"}:{FormatSecondsToMinutes(RemainingSeconds)}"
    
FormatTime(Time : tycoon_time) : string = 
    "{Time.Hours > 9 and "{Time.Hours}" or "0{Time.Hours}"}:{Time.Minutes > 9 and "{Time.Minutes}" or "0{Time.Minutes}"}:{Time.Seconds > 9 and "{Time.Seconds}" or "0{Time.Seconds}"}"

FormatNumber(Amount : int) : string =                                                                                                                                                                                                                                                                                               
    if ( Amount < 1000):
        return ToString(Amount)
    else if ( Amount >= 1000 and Amount < 10000):
        return ToString(Amount).Insert[1, ","] or ""
    else if ( Amount >= 10000 and Amount < 1000000):
        StringAmount := ToString(Amount)
        return for ( I := 0..(-4 + StringAmount.Length), NumChar := StringAmount[I]) { NumChar } + (not (StringAmount[-3 + StringAmount.Length] = '0' and StringAmount[-2 + StringAmount.Length] = '0') and "." + for ( I := -3 + StringAmount.Length..-2 + StringAmount.Length, Decimal := StringAmount[I]) {Decimal} or "" ) + "K"
    else if ( Amount >= 1000000 and Amount < 1000000000):
        StringAmount := ToString(Amount)
        return for ( I := 0..(-7 + StringAmount.Length), NumChar := StringAmount[I]) { NumChar } + (not (StringAmount[-6 + StringAmount.Length] = '0' and StringAmount[-5 + StringAmount.Length] = '0') and "." + for ( I := -6 + StringAmount.Length..-5 + StringAmount.Length, Decimal := StringAmount[I]) {Decimal} or "") + "M"
    else if ( Amount >= 1000000000 and Amount < 1000000000000):
        StringAmount := ToString(Amount)
        return for ( I := 0..(-10 + StringAmount.Length), NumChar := StringAmount[I]){ NumChar } + (not (StringAmount[-9 + StringAmount.Length] = '0' and StringAmount[-8 + StringAmount.Length] = '0') and "." + for ( I := -9 + StringAmount.Length..-8 + StringAmount.Length, Decimal := StringAmount[I]) {Decimal} or "") + "B"
    else if ( Amount >= 1000000000000 and Amount < 1000000000000000):
        StringAmount := ToString(Amount)
        return for ( I := 0..(-13 + StringAmount.Length), NumChar := StringAmount[I]){ NumChar } + (not (StringAmount[-12 + StringAmount.Length] = '0' and StringAmount[-11 + StringAmount.Length] = '0') and "." + for ( I := -12 + StringAmount.Length..-11 + StringAmount.Length, Decimal := StringAmount[I]) {Decimal} or "") + "T"
    ToString(Amount)

FormatFloat(Float : float, Decimals : int) : string =
    var DecimalStr : string = ""
    DecimalString := ToString(Float) 
    if ( Index := DecimalString.Find['.']):
        set DecimalStr = for ( I := 0..Index - 1, Char := DecimalString[I]) { Char} + "."
        set DecimalStr += for ( I := Index + 1..Index + Decimals, NextDecimal := DecimalString[I]) do NextDecimal
    return DecimalStr

IdentityVector : vector3 = vector3{ X := 1.0, Y := 1.0, Z := 1.0}
IntToMessage<localizes>(Number : int) : message = "{Number}"
StringToMessage<localizes>(String : string) : message = "{String}"
AgentToMessage<localizes>(Agent : agent) : message = "{Agent}"
operator'+'<localizes>(M1 : message, M2 : message) : message = "{M1}{M2}"
IntCompare<public>(LHS : int, RHS : int)<computes><decides> : int = LHS < RHS

# ToString<public>(Map : [t]u where t : subtype(comparable), u : subtype(comparable)) : string = 
#     var String : string = ""
#     for ( Key->Value : Map):
#         set String += "{Key} => {Value}\n"
#     return String

ToMap<public>(Array : []t where t : subtype(comparable)) : [t]int = 
    var Map : [t]int = map{}
    for ( Element : Array, set Map[Element] = 0) do {}
    return Map

Lerp<public>(Start : color, Finish : color, Alpha : float) : color = 
    color:
        R := Lerp(Start.R, Finish.R, Alpha)
        G := Lerp(Start.G, Finish.G, Alpha)
        B := Lerp(Start.B, Finish.B, Alpha)

MakeScaledTransform(CreativeProp : creative_prop, ?XScale : float = 1.0, ?YScale : float = 1.0, ?ZScale : float = 1.0)<transacts> : transform = 
    transform:
        Translation := CreativeProp.GetTransform().Translation
        Rotation := CreativeProp.GetTransform().Rotation
        Scale := vector3{X := XScale, Y := YScale, Z := ZScale}
        
MakeScaledTransform(Translation : vector3, ?Rotation : rotation = IdentityRotation(), ?XScale : float = 1.0, ?YScale : float = 1.0, ?ZScale : float = 1.0)<transacts> : transform = 
    transform:
        Translation := Translation
        Rotation := Rotation
        Scale := vector3{X := XScale, Y := YScale, Z := ZScale}
      
(Map : [t]u).RemoveKey(KeyToRemove : t where t : subtype(comparable), u : subtype(any))<transacts> : [t]u = 
    var NewMap : [t]u = map{}
    for:
        Key->Index : Map
        Key <> KeyToRemove
        set NewMap[Key] = Index
    do {}
    return NewMap

MergeSort<public>(Array:[]t, Compare:type{_(L:t, R:t)<decides><transacts>:t} where t:type)<transacts>:[]t=
    Length:int = Array.Length

    if:
        Length > 1 # Verify there is more than one element in the array, otherwise we've reached the base case.
        Mid:int = Floor(Length / 2) # Get the middle index of the array.
        Left:[]t = Array.Slice[0, Mid] # Split the array in half. This keeps elements from the beginning to Mid - 1 index.
        Right:[]t = Array.Slice[Mid] # Split the array in half. This keeps elements from Mid index to the end of the array.
    then:
        # Call MergeSort on the left half of the array.
        LeftSorted:[]t = MergeSort(Left, Compare)
        # Call MergeSort on the right half of the array.
        RightSorted:[]t = MergeSort(Right, Compare)

        # Combine the two arrays and return the result.
        Merge(LeftSorted, RightSorted, Compare)
    else:
        # Return the array passed in because we've reached the base case.
        Array

# A helper function for MergeSort that combines the divided arrays in an order based on the Compare function.
Merge(Left:[]t, Right:[]t, Compare:type{_(L:t, R:t)<decides><transacts>:t} where t:type)<transacts>:[]t=
    var LeftIndex:int = 0
    var RightIndex:int = 0
    var MergedArray:[]t = array{}
    
    # Loop through all the elements in the arrays to add them to the MergedArray variable.
    loop:
        if (LeftElement := Left[LeftIndex], RightElement := Right[RightIndex]):
            # Check the element in the left half array with the element in the right half array.
            # Uses the Compare function passed in as an argument
            if (Compare[LeftElement, RightElement]):
                set MergedArray += array{LeftElement}
                set LeftIndex += 1
            else:
                set MergedArray += array{RightElement}
                set RightIndex += 1
        else:
            # We've added all of the elements from one the arrays at this point.
            # Now check which array still has elements to merge in and add all remaining elements.
            if (LeftIndex >= Left.Length):
                option{set MergedArray += Right.Slice[RightIndex]}
            else:
                option{set MergedArray += Left.Slice[LeftIndex]}

            # Exit out of the loop because we've finished adding all elements.
            break
        
    # Return the merged array.
    MergedArray

tycoon_time<public> := struct<concrete>:
    @editable       Hours : type{_X : int where _X >= 0, _X <= 11} = 0
    @editable       Minutes : type{_X : int where _X >= 0, _X <= 59} = 0
    @editable       Seconds : type{_X : int where _X >= 0, _X <= 59} = 0