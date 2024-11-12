using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Vehicles }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /Fortnite.com/AI }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }


pumpkin_carving_metric<public> := enum:
    MetricA
    MetricB
    MetricC
    MetricD
    MetricE


ToString<public>(Metric : pumpkin_carving_metric) : string =
    case(Metric):
        pumpkin_carving_metric.MetricA => return "MetricA"
        pumpkin_carving_metric.MetricB => return "MetricB"
        pumpkin_carving_metric.MetricC => return "MetricC"
        pumpkin_carving_metric.MetricD => return "MetricD"
        pumpkin_carving_metric.MetricE => return "MetricE"

CalculatePumpkinCarvingScore<public>(ComponentMetricsTotal : [pumpkin_carving_metric]int, MetricWeightSheet : [pumpkin_carving_metric]int) : int = 
    var CurrentScore : int = 0
    for ( Metric->Value : MetricWeightSheet):
        Print("{Metric} Weight: {Value}")
    for ( Metric->Value : ComponentMetricsTotal, Weight := MetricWeightSheet[Metric]):
        MetricScore := (Floor[Value * Weight * 1.05] or Value * Weight)
        set CurrentScore = CurrentScore + (Floor[32.5 * MetricScore / 700.0] or 10)
        Print("{Metric} Score: {MetricScore}")
    Print("Total Score: {CurrentScore}")
    return Clamp(CurrentScore, 1, 100)

# Generates a random map of metrics to integers, denoting how "influential" a certain metric is to the overall score of a pumpkin carving
# This is used to determine how much a metric should be weighted when calculating the final score of a pumpkin carving
# Total influence is 100, where sum of all weights = 100
GenerateMetricWeightSheet<public>() : [pumpkin_carving_metric]int =
    TotalMetrics := 5
    Metrics := Shuffle(array{pumpkin_carving_metric.MetricA, pumpkin_carving_metric.MetricB, pumpkin_carving_metric.MetricC, pumpkin_carving_metric.MetricD, pumpkin_carving_metric.MetricE})
    var TotalWeight : int = 100 - TotalMetrics
    var StartingWeightSheet : [pumpkin_carving_metric]int = map:
        pumpkin_carving_metric.MetricA => 1
        pumpkin_carving_metric.MetricB => 1
        pumpkin_carving_metric.MetricC => 1
        pumpkin_carving_metric.MetricD => 1
        pumpkin_carving_metric.MetricE => 1

    return PopulateWeights(StartingWeightSheet, Metrics, TotalWeight)
        
PopulateWeights(CurrentWeightSheet : [pumpkin_carving_metric]int, Metrics : []pumpkin_carving_metric, TotalWeight : int) : [pumpkin_carving_metric]int = 
    var CurrentWeightTotal : int = TotalWeight
    var NewWeightMap : [pumpkin_carving_metric]int = CurrentWeightSheet
    for ( Index->Metric : Metrics, Weight := CurrentWeightSheet[Metric], Index > 1):
        GeneratedWeight := GetRandomInt(GetRandomInt(-30, 20), GetRandomInt(10, 30))
        if ( GeneratedWeight < 0):
            <# Do Nothing #>
        else if ( CurrentWeightTotal - GeneratedWeight < 0):
            # If the weight is too high, set it to the remaining weight, return this map
            if ( set NewWeightMap[Metric] = Weight + CurrentWeightTotal) {}
                return NewWeightMap
        # If there is still remaining weight, set the weight to the remaining weight
        else:
            set CurrentWeightTotal = CurrentWeightTotal - GeneratedWeight
            if ( set NewWeightMap[Metric] = Weight + GeneratedWeight) {}
    if ( DeltaWeight := NewWeightMap[Metrics[0]] - GetRandomInt(-GetRandomInt(0, 2), GetRandomInt(3, 5)), set NewWeightMap[Metrics[0]] = DeltaWeight) {}
    if ( DeltaWeight := NewWeightMap[Metrics[1]] - GetRandomInt(-GetRandomInt(0, 2), GetRandomInt(3, 5)), set NewWeightMap[Metrics[1]] = DeltaWeight) {}
    
    return PopulateWeights(NewWeightMap, Metrics, CurrentWeightTotal)
    
            
pumpkin_carving_score_result<public> := struct:
    Score : int
    CashGain : int
    CandyGain: int
                


        
        



