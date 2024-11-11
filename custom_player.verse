using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { VerseStuff.Managers }
using { VerseStuff.Cosmetics }
using { UIStuff}

custom_player<public> := class<unique>:
    Player<public> : player
    Agent<public> : agent
    FortCharacter<public> : fort_character
    TycoonLevel<public> : tycoon_level = tycoon_level{}
    Canvas : canvas = canvas{}
    CurrencyWidgets : player_currency_widgets = player_currency_widgets{}
    IncomeStreamWidgets : player_income_stream_widgets = player_income_stream_widgets{}
    
    var<private> Cash : int = 0
    var<private> Candy : int = 0
    var<private> BlingBucks : int = 0
    var<private> Rebirths : int = 0
    var<private> CurrencyMultiplier : float = 1.0
    var<private> MaybeTycoonManager : ?tycoon_manager = false

    UniqueBegin<public>(TycoonLevelSettings : tycoon_level_settings)<suspends> : void =
        Print("Unique begin new custom player")
        if ( PlayerUI := GetPlayerUI[Player]) then PlayerUI.AddWidget(Canvas)
        Sleep(0.0)
        TycoonLevel.UniqueBegin(TycoonLevelSettings)
        Sleep(0.0)
        CurrencyWidgets.UniqueBegin()
        Sleep(0.0)
        IncomeStreamWidgets.UniqueBegin(Self)
        Sleep(0.0)
        Canvas.AddWidget(
            canvas_slot:
                Widget := texture_block{DefaultImage := SocialsUI.MapCode, DefaultDesiredSize := vector2{X := 256.0, Y := 32.0}}
                Anchors := anchors{Minimum := vector2{ X := 0.5, Y := 0.0}, Maximum := vector2{ X := 0.5, Y := 0.0}}
                Alignment := vector2{X := 0.5, Y := 0.0}
                Offsets := margin{Top := 5.0}
        )

    Init(TycoonManager : tycoon_manager, Stats : player_stats) : void =
        set MaybeTycoonManager = option{TycoonManager}
        set Cash = Stats.CurrencyStats.Cash
        set Candy = Stats.CurrencyStats.Candy
        set Rebirths = Stats.CurrencyStats.Rebirths
        set BlingBucks = Stats.CurrencyStats.BlingBucks
    
        set CurrencyMultiplier = Min(1.0 + Rebirths * 0.2, 4.0)
        
        CurrencyWidgets.Init(Self, Stats)
        Canvas.AddWidget(
            canvas_slot:
                Widget := CurrencyWidgets.GetRootWidget()
                Anchors := anchors{ Minimum := vector2{ X := 0.0, Y := 0.5}, Maximum := vector2{ X := 0.0, Y := 0.5}}
                Alignment := vector2{ X := 0.0, Y := 0.0}
                Offsets := margin{ Left := 10.0, Top := -150.0}
        )
        TycoonLevel.Init(Self, Stats)
        
    Reset() : void =
        Print("Restting custom player!")
        set Cash = 0
        set Candy = 0
        set BlingBucks = 0 
        set Rebirths = 0
        set MaybeTycoonManager = false
        TycoonLevel.Reset()
        if ( PlayerUI := GetPlayerUI[Player]):
            Canvas.RemoveWidget(CurrencyWidgets.GetRootWidget())
            CurrencyWidgets.Reset()
            
    SetCash(Amount : int) : void = set Cash = Amount
    SetSubscribers(Amount : int) : void = set Candy = Amount
    SetBlingBucks(Amount : int) : void = set BlingBucks = Amount
    SetRebirths(Amount : int) : void = set Rebirths = Amount
  
    GetCanvas() : canvas = Canvas
    GetCash<public>()<transacts> : int = Cash
    GetSubscribers<public>()<transacts> : int = Candy
    GetBlingBucks<public>()<transacts> : int = BlingBucks
    GetCurrencyMultiplier<public>()<transacts> : float = CurrencyMultiplier
    GetCurrencyWidgets<public>()<transacts> : player_currency_widgets = CurrencyWidgets
    GetIncomeStreamWidgets<public>()<transacts> : player_income_stream_widgets = IncomeStreamWidgets
    GetPosition<public>()<transacts> : vector3 = FortCharacter.GetTransform().Translation
    GetRotation<public>()<transacts> : rotation = FortCharacter.GetTransform().Rotation
