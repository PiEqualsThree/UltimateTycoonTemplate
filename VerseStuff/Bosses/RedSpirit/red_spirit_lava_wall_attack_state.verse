using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Vehicles }
using { /Fortnite.com/Animation }
using { /Fortnite.com/Animation/PlayAnimation }
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
using { VerseStuff.TycoonInterfaces }
using { BossFights}
using { UIStuff }
using { NPCStuff}

red_spirit_lava_wall_attack_state<public> := class(red_spirit_boss_state):

    var IsLavaWallActive : logic = false

    Init<override>(RedSpiritBossManager : red_spirit_boss_manager) : void =
        if ( not IsLavaWallActive?, AC := RedSpiritBossManager.NPCBehavior.GetAgent[].GetFortCharacter[].GetPlayAnimationController[]):
            AC.Play(BossFights.RedSpirit.Red_Spirit_Animation_Summon)
             
    Update<override>(RedSpiritBossManager : red_spirit_boss_manager)<suspends> : void =
        if ( not IsLavaWallActive?, BossFortCharacter := RedSpiritBossManager.NPCBehavior.GetAgent[].GetFortCharacter[]):
            set IsLavaWallActive = true
            Sleep(1.25)
            if (RedSpiritBossManager.LavaWallProp.TeleportTo[BossFortCharacter.GetTransform().Translation - vector3{Z := 750.0} + BossFortCharacter.GetTransform().Rotation.GetLocalForward() * 65.0, BossFortCharacter.GetTransform().Rotation]):
                spawn{ UpdateLavaWall(RedSpiritBossManager, 15.0)} 
                RedSpiritBossManager.LavaWallProp.MoveTo(RedSpiritBossManager.LavaWallProp.GetTransform().Translation + vector3{Z := 600.0}, RedSpiritBossManager.LavaWallProp.GetTransform().Rotation, 1.0)
            Sleep(1.0)
        else:
            End(RedSpiritBossManager)

    End<override>(RedSpiritBossManager : red_spirit_boss_manager) : void =
        if (RedSpiritBossManager.ExplosiveProp.TeleportTo[vector3{} - vector3{X := 10000.0, Z := 3000.0}, rotation{}] ) {}
        RedSpiritBossManager.ChangeState(RedSpiritBossManager.IdleState)


    UpdateLavaWall(RedSpiritBossManager : red_spirit_boss_manager, ActiveTime : float)<suspends> : void =
        set IsLavaWallActive = true
        defer{if(RedSpiritBossManager.LavaWallProp.TeleportTo[vector3{} - vector3{X := 10000.0, Z := 3000.0}, rotation{}]){}}
        race:
            Sleep(ActiveTime)
            loop:
                Agent := RedSpiritBossManager.LavaWallVolume.AgentEntersEvent.Await()
                spawn{ DoLavaWallDamageLoop(Agent, RedSpiritBossManager.LavaWallVolume)}
        set IsLavaWallActive = false

    DoLavaWallDamageLoop(Agent : agent, Volume : volume_device)<suspends> : void =
        if ( FortCharacter := Agent.GetFortCharacter[]):
            race:
                loop:
                    LeavingAgent := Volume.AgentExitsEvent.Await()
                    if ( Agent = LeavingAgent):
                        break
                loop:
                    Sleep(0.0)
                    FortCharacter.Damage(1.0)
