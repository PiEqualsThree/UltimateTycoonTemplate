using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }

custom_timer<public> := class:
    Mode<public> : custom_timer_mode
 
    CompletedEvent<public> : event() = event(){}
    StoppedEvent<private> : event() = event(){}
    PausedEvent<private> : event() = event(){}
    ResumedEvent<private> : event() = event(){}

    var StartingTime<private> : int = 0
    var CurrentTime<private> : int = 0
    var State<private> : custom_timer_state = custom_timer_state.Stopped

    SetTime<public>(Time : int) : void =
        set StartingTime = Time
        set CurrentTime = StartingTime

    Start<public>() : void =
        case ( State):
            custom_timer_state.Running => 
                Print("Already running")
            custom_timer_state.Paused => 
                Resume()
            custom_timer_state.Stopped => 
                Reset()
                set State = custom_timer_state.Running
                spawn{ Update() }  

    Update<private>()<suspends> : void =
        TickTime := Mode = custom_timer_mode.Seconds and 1.0 or 0.1
        loop:
            race:
                StoppedEvent.Await()
                PausedEvent.Await()
                loop:
                    Sleep(TickTime)
                    set CurrentTime = CurrentTime - 1
                    if ( CurrentTime <= 0):
                        set State = custom_timer_state.Stopped
                        CompletedEvent.Signal()
                
            if ( State = custom_timer_state.Stopped) then break
            else ResumedEvent.Await()

    Reset() : void =
        Stop()
        set CurrentTime = StartingTime

    Pause<public>() : void =  { set State = custom_timer_state.Paused;  PausedEvent.Signal();  }
    Resume<public>() : void = { set State = custom_timer_state.Running; ResumedEvent.Signal();  }
    Stop<public>() : void =   { set State = custom_timer_state.Stopped; StoppedEvent.Signal(); }

    GetCurrentState<public>()<transacts> : custom_timer_state = State
    GetCurrentTime<public>()<transacts> : int = CurrentTime

custom_timer_state<public> := enum:
    Running
    Paused
    Stopped

custom_timer_mode<public> := enum:
    Seconds
    Deciseconds
    