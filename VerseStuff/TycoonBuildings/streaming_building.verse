# using { /Fortnite.com/Devices }
# using { /Fortnite.com/UI }
# using { /Verse.org/Simulation }
# using { /Verse.org/Colors }
# using { /Verse.org/Random }
# using { /UnrealEngine.com/Temporary/Diagnostics }
# using { /UnrealEngine.com/Temporary/SpatialMath }
# using { /UnrealEngine.com/Temporary/UI }
# using { /UnrealEngine.com/Assets }
# using { TycoonAnimations }
# using { VFXStuff }
# using { VerseStuff.TycoonInterfaces }
# using { VerseStuff.Managers}

# streaming_building<public> := class<concrete>(tycoon_building, purchasable, resetable):
#     @editable       ID : int = 0
#     @editable       Price : int = 0
#     @editable       PurchaseCurrencyType : currency_type = currency_type.Cash
#     @editable       StreamTime : float = 5.0
#     @editable       StreamCamera : gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}
#     @editable       StreamHudDevice : hud_message_device = hud_message_device{}
#     @editable       StreamCurrencyGainHudDevice : hud_message_device = hud_message_device{}
#     @editable       StreamMutatorZone : mutator_zone_device = mutator_zone_device{}
#     @editable       StreamHudClearTrigger : trigger_device = trigger_device{}
#     @editable       ContainerProp : creative_prop = creative_prop{}
#     @editable       PurchaseButton : creative_prop = creative_prop{}
#     @editable       PassiveIncome : passive_income = passive_income{}
#     @editable       NextBuildingUnlockIDs : []int = array{}
#     @editable       UseBuildAnimation : logic = true
#     @editable       TycoonCinematic : ?tycoon_cinematic = false

#     BuildingResetEvent : event() = event(){}
#     UI : stream_ui = stream_ui{}

#     var DefaultContainerPropTransform : transform = transform{}
#     var DefaultPurchaseButtonTransform : transform = transform{}

#     var PurchaseStatus : purchase_status = purchase_status.Locked
#     var CurrencyManager : currency_manager = currency_manager{}
#     var MaybeOwner : ?custom_player = false

#     # Run once per game start
#     UniqueBegin<override>() : void =
#         UI.UniqueBegin()
#         set DefaultContainerPropTransform = ContainerProp.GetTransform()
#         set DefaultPurchaseButtonTransform = PurchaseButton.GetTransform()
            
#     Init<override>(TycoonManager : tycoon_manager) : void =
#         if:
#             ContainerProp.TeleportTo[DefaultContainerPropTransform.Translation - vector3{ Z := 3000.0}, DefaultContainerPropTransform.Rotation]
#             PurchaseButton.TeleportTo[DefaultPurchaseButtonTransform.Translation - vector3{ Z := 3000.0}, DefaultPurchaseButtonTransform.Rotation]
        
#     Reset<override>() : void =
#         ResetEvent().Signal()
#         if ( Owner := MaybeOwner?) then Owner.GetCanvas().RemoveWidget(UI.GetRootWidget())
#         set PurchaseStatus = purchase_status.Locked
#         set MaybeOwner = false

#     Update(Owner : custom_player)<suspends> : void =
#         race:
#             ResetEvent().Await()
#             loop:
#                 Agent := StreamMutatorZone.AgentBeginsEmotingEvent.Await()
#                 if ( Owner.Agent = Agent):
#                     StreamHudDevice.SetText(AgentToMessage(Agent))
#                     StreamHudDevice.Show(Agent)
#                     StreamCamera.AddTo(Agent)
#                     UI.Show()
#                     UpdateStreamLoop(Owner)
#                     StreamHudClearTrigger.Trigger(Owner.Player)
#                     StreamCamera.RemoveFrom(Agent)
                            
#     UpdateStreamLoop(Owner : custom_player)<suspends> : void =
#         defer{UI.Hide()}
#         var StreamCount : int = 0
#         race:
#             Owner.FortCharacter.EliminatedEvent().Await()
#             loop:
#                 EndingAgent := StreamMutatorZone.AgentEndsEmotingEvent.Await()
#                 if ( Owner.Agent = EndingAgent) then break
#             loop:
#                 EndingAgent := StreamMutatorZone.AgentExitsEvent.Await()
#                 if ( Owner.Agent = EndingAgent) then break
#             loop:
#                 Percent := Max(15.0 * Pow(2.71, -0.15 * StreamCount), 0.5)
#                 Multiplier := Percent * 0.01
#                 UI.FillProgressBar(StreamTime)
#                 CashGain := CurrencyManager.GetCustomPlayerCurrencyGain(Owner, Min(GetRandomInt(15, 30) + Floor[Owner.Candy * Multiplier * 2.0] or 1, 100000))
#                 SubscribersGain := CurrencyManager.GetCustomPlayerCurrencyGain(Owner, Min(GetRandomInt(10, 20) + Floor[Owner.Candy * Multiplier] or 1, 50000))
#                 CurrencyManager.IncreaseCurrency(Owner, currency_transaction{Type := currency_type.Cash, Amount := CashGain})
#                 CurrencyManager.IncreaseCurrency(Owner, currency_transaction{Type := currency_type.Candy, Amount := SubscribersGain})
#                 StreamCurrencyGainHudDevice.SetText(StringToMessage("💵+${FormatNumber(CashGain)}\n👥+{FormatNumber(SubscribersGain)} Candy"))
#                 StreamCurrencyGainHudDevice.Show(Owner.Player)
#                 set StreamCount = StreamCount + 1
        
#     Unlock<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void =
#         if ( PurchaseStatus = purchase_status.Locked):
#             set PurchaseStatus = purchase_status.Unlocked
#             spawn { DoTycoonPopupAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}

#     Purchase<override>(Owner : custom_player, ?PlayAnimations : logic = true) : void = 
#         if ( PurchaseStatus <> purchase_status.Purchased):
#             set PurchaseStatus = purchase_status.Purchased   
#             set MaybeOwner = option{Owner} 
#             Owner.GetCanvas().AddWidget(UI.GetCanvasSlot())
#             spawn{ DoTycoonHideAnimation(PurchaseButton, DefaultPurchaseButtonTransform, ?PlayAnimations := PlayAnimations)}
#             spawn{ DoTycoonPopupAnimation(ContainerProp, DefaultContainerPropTransform, ?PlayAnimations := PlayAnimations)}
#             if ( PlayAnimations?):
#                 #SpawnPurchaseVFX(Self, OriginalContainerPropTransform.Translation)
#                 if ( Cinematic := TycoonCinematic?) then spawn{ Cinematic.Play(Owner) }
#             spawn{ Update(Owner) }

#     ResetEvent<override>() : event() = BuildingResetEvent
#     GetNextBuildingUnlockIDs<override>()<transacts> : []int = (ID > 0 and array{ ID + 1 } or array{}) + NextBuildingUnlockIDs
#     GetPurchaseCurrencyType<override>()<transacts> : currency_type = PurchaseCurrencyType
#     GetPurchaseStatus<override>()<transacts> : purchase_status = PurchaseStatus
#     GetPurchaseButton<override>()<transacts> : creative_prop = PurchaseButton
#     GetPassiveIncome<override>()<transacts> : passive_income = PassiveIncome
#     GetPrice<override>()<transacts> : int = Price
#     GetID<override>()<transacts> : int = ID

# using { UIStuff}

# stream_ui := class(resetable):

#     ResumedEvent : event() = event(){}
#     PausedEvent : event() = event(){}
#     StreamUIResetEvent : event() = event(){}
#     #ViewerCountTextBlock : text_block = text_block{ DefaultTextColor := NamedColors.White, DefaultJustification := text_justification.Left }
    
#     ProgressBarTextureBlock : texture_block = texture_block{DefaultImage := StreamUI.ProgressBarForeground, DefaultDesiredSize := vector2{X := 110.0, Y := 0.0}}

#     var RootWidget : overlay = overlay{}
#     var CanvasSlot : canvas_slot = canvas_slot{Widget := overlay{}}

#     # Run once for setup
#     UniqueBegin() : void =
#         set RootWidget = overlay:
#             Slots := array:
#                 # overlay_slot: <# View Count #>
#                 #     Widget := ViewerCountTextBlock
#                 #     HorizontalAlignment := horizontal_alignment.Left
#                 #     VerticalAlignment := vertical_alignment.Center
#                 #     Padding := margin{ Left := -1025.0, Bottom := 275.0}

#                 overlay_slot: <# Progress bar #>
#                     HorizontalAlignment := horizontal_alignment.Center
#                     VerticalAlignment := vertical_alignment.Bottom
#                     Widget := overlay:
#                         Slots := array:
#                             overlay_slot: <# Background #>
#                                 Widget := texture_block{DefaultImage := StreamUI.ProgressBarBackground, DefaultDesiredSize := vector2{ X := 110.0, Y := 698.0}, DefaultTint := color{}}
#                                 VerticalAlignment := vertical_alignment.Bottom

#                             overlay_slot: <# Foreground #>
#                                 Widget := ProgressBarTextureBlock
#                                 VerticalAlignment := vertical_alignment.Bottom

#                             overlay_slot: <# Progress Bar overlay #>
#                                 Widget := texture_block{ DefaultImage := StreamUI.ProgressBar, DefaultDesiredSize := vector2{ X := 110.0, Y := 698.0} }
#                                 HorizontalAlignment := horizontal_alignment.Center
#                                 VerticalAlignment := vertical_alignment.Bottom
                
#         # Add the stream ui to the canvas
#         set CanvasSlot = canvas_slot:
#             Widget := GetRootWidget()
#             Anchors := anchors{Minimum := vector2{X := 0.5, Y := 1.0}, Maximum := vector2{ X := 0.5, Y := 1.0}}
#             Alignment := vector2{ X:=0.5,Y:=1.0 }
#             Offsets := margin { Left := 500.0, Top := -175.0}
#         Hide()

#     FillProgressBar(Time : float)<suspends> : void =
#         TotalIntervals := Floor[Time * 10] or 30
#         #ProgressBarTextureBlock.SetDesiredSize(vector2{ X := 66.5 , Y := 648.0 } )
#         race:
#             PausedEvent.Await()
#             for (I := 1..TotalIntervals):
#                 LerpParameter := (I * 1.0) / (TotalIntervals * 1.0) # Used to Linearly Interpolate Current Size to New Size, based on current interval

#                 # Progress Bar Lerp
#                 NewSizeVec2 := Lerp(vector2{ X := 110.0, Y := 0.0}, vector2{ X := 110.0, Y := 698.0}, LerpParameter)
#                 ProgressBarTextureBlock.SetDesiredSize(NewSizeVec2)
                
#                 Sleep(0.1) <# Totals 5 seconds #>

#     # Update(Owner : custom_player)<suspends> : void =
#     #     race:
#     #         ResetEvent().Await()
#     #         loop:
#     #             ResumedEvent.Await()
#     #             race:
#     #                 ResetEvent().Await()
#     #                 PausedEvent.Await()
#     #                 loop:
#     #                     Sleep(GetRandomFloat(0.8, 2.0))
#     #                     ViewerCountTextBlock.SetText(StringToMessage("{FormatNumber(1 + Floor[ Owner.Candy * GetRandomFloat(0.05, 0.20)] or 0)}"))

#     Reset<override>() : void =
#         set RootWidget = overlay{}
#         ResetEvent().Signal()

#     Hide() : void = RootWidget.SetVisibility(widget_visibility.Hidden)
#     Show() : void = RootWidget.SetVisibility(widget_visibility.Visible)
    
#     Resume() : void = ResumedEvent.Signal()
#     Pause() : void = PausedEvent.Signal()
#     ResetEvent<override>() : event() = StreamUIResetEvent
    
#     GetRootWidget() : widget = RootWidget
#     GetCanvasSlot()<transacts> : canvas_slot = CanvasSlot


# # streamer_chat<public> := class:

# #     ResumedEvent : event() = event(){}
# #     PausedEvent : event() = event(){}

# #     var RootWidget : widget = overlay{}
# #     var ChatStackBox : stack_box = stack_box{Orientation := orientation.Vertical }
# #     var ChatTextBlocks : []text_block = array{}


# #     Init<public>() : void =
# #         set ChatTextBlocks = for ( I := 1..8) {CreateChatTextBlock() }
# #         StackBoxSlots : []stack_box_slot= for ( ChatTextBlock : ChatTextBlocks) { stack_box_slot{ Widget := ChatTextBlock, HorizontalAlignment := horizontal_alignment.Left}}

# #         set ChatStackBox = stack_box{Orientation := orientation.Vertical, Slots := StackBoxSlots}

# #         set RootWidget = overlay:
# #             Slots := array:
# #                 overlay_slot:
# #                     Widget := color_block{DefaultDesiredSize := vector2{X := 400.0, Y := 500.0}, DefaultOpacity := 0.1}
# #                 overlay_slot:
# #                     Widget := ChatStackBox
# #                     Padding := margin{Left := 25.0}
# #                     HorizontalAlignment := horizontal_alignment.Left
# #                     VerticalAlignment := vertical_alignment.Center
                    

# #         spawn{ Update() }

# #     Update<public>()<suspends> : void =
# #         loop:
# #             race:
# #                 PausedEvent.Await()
# #                 loop:
# #                     Sleep(GetRandomFloat(0.1, 1.2))
# #                     RefreshChat()
# #             ResumedEvent.Await()

# #     Resume<public>()<suspends> : void = ResumedEvent.Signal()
# #     Pause<public>()<suspends> : void = PausedEvent.Signal()

# #     CreateChatTextBlock() : text_block =  
# #         NewTextBlock := text_block:
# #             DefaultText := StringToMessage(TextChats[GetRandomInt(0, TextChats.Length - 1)] or "")
# #             DefaultJustification := text_justification.Left
# #             DefaultTextColor := NamedColors.White
# #             DefaultShadowColor := color{}
# #             DefaultShadowOffset := option{vector2{X := 3.0, Y := 3.0}}
# #         NewTextBlock.SetShadowOpacity(1.0)
# #         return NewTextBlock

# #     RefreshChat() : void =
# #         for ( Index->ChatTextBlock : ChatTextBlocks, BottomTextChat := ChatTextBlocks[Index + 1]):
# #             ChatTextBlock.SetText(StringToMessage(BottomTextChat.GetText()))
# #         if ( LastTextBlock := ChatTextBlocks[ChatTextBlocks.Length - 1]):
# #             LastTextBlock.SetText(StringToMessage(TextChats[GetRandomInt(0, TextChats.Length - 1)] or "? ? ?"))

# #     GetRootWidget<public>() : widget = RootWidget    

# # StringToMessage<localizes>(String : string) : message = "{String}"

# # TextChats : []string = array:
# #     "ShadowNinja : Let's get this bread 🍞"
# #     "WhisperingEcho : Just lurking"
# #     "Fireball24 : GG, well played 👍"
# #     "ClipMaster : Clip it PogChamp"
# #     "StarlightDreamer : Loving the vibes ❤️"
# #     "BlazeRunner : Pew pew! 🎮"
# #     "JokerJester : ROFL 😂"
# #     "StormySky : Chat's on fire"
# #     "SupportiveSoul : Keep slaying 💪"
# #     "EmoteLover : Emote spam Kappa"
# #     "HypeTrain : Hype train incoming!"
# #     "RaidReady : Raid in 5"
# #     "HostIt : Can we get a host please 🙏"
# #     "SunflowerChild : Positivity overload"
# #     "GameCritic : Epic plays!"
# #     "StreamerFan : Poggers! 💥"
# #     "FollowerLove : Followers unite 💖"
# #     "GiveawayTime : Giveaway hype! 🎁"
# #     "MidnightWatcher : Enjoying the show"
# #     "NewbieGamer : Learning the ropes"
# #     "TourneyFanatic : Tourney time!🎲"
# #     "StreamLove : Much luv to the streamer❤️"
# #     "ExcitedEagle : HYPED! 🎉"
# #     "ClipMaker : Clipping like crazy! 🎥"
# #     "HypeCreator : Hype overload! 🌟"
# #     "LoyalSupporter : Always here supporting"
# #     "StreamerAlly : Supporting the streamer"
# #     "EsportsJunkie : Esports fanatic! 🎮"
# #     "MusicManiac : Grooving to the beats 🎵"
# #     "SubSupport : Subs for days! 🛡️"
# #     "LaughingLlama : Haha Love the jokes😄"
# #     "ClipFanatic : Clip fanatic 📎"
# #     "HypeSeeker : Can't get enough hype🌟"
# #     "RaidLeader : Raid prepped and ready⚔️"
# #     "HostMe : Host me up! 🙋‍♂️"
# #     "Encourager : You got this! 💪"
# #     "GameGuru : Insane gameplay!"
# #     "TrueFan : Biggest fan here ❤️"
# #     "PrizeHunter : Time for prizes! 🎁"
# #     "CompetitionLover : Let the games begin 🎮"
# #     "HeartfeltSupport : the stream❤️"
# #     "EmoteEnthusiast : Emote party! 😄"
# #     "ClipCreator : Crafting clips! 🎥"
# #     "WaveMaker : Making waves! 🌊"
# #     "SilentSpectator : Chillin like a villain"
# #     "GameMastermind : Master of games"
# #     "LegendaryPlays : Legendary plays"
# #     "StealthyObserver : Stealth mode activated"
# #     "EagerLearner : Learning the ropes"
# #     "QuickDraw : Quick on the draw"
# #     "DevotedFan : Biggest fan here"
# #     "MaxChill : Maximum chill mode"
# #     "GamerGalaxy : Game on, gamers! 🎮"
# #     "Jokester : Hilarious as always"
# #     "ChatChampion : Chatting away"
# #     "VictorySupporter : You're killing it"
# #     "EmoteEnthusiast : Emote overload! 😍"
# #     "HypeHustler : Full steam ahead"