/* Gravity Gun - weapon_hl2_gravgun
    Gravity gun from HL2, nuff said.

Part of the SC Half-Life 2 Weapons Pack.
- Outerbeast
*/
#include "weapon_base"

namespace HL2_WEAPONS
{

enum ANIM_GRAVGUN
{
    CLOSED_IDLE,
    CLOSED_FIRE,
    CLOSED_DRAW,
    OPEN_IDLE,
    OPEN_FIRE,
    OPEN_HOLD,
    CLOSED_TO_OPEN,
    OPEN_TO_CLOSED,
    CLOSED_PULL
};

const array<float> FL_ANIMTIME_GRAVGUN =
{
    6.86f,
    0.63f,
    1.0f,
    5.03f,
    0.43f,
    2.0f,
    0.5f,
    0.5f,
    1.0f
};

array<int> I_STATS_GRAVGUN =
{
    0,
    6,
    WEAPON_NOCLIP,
    WEAPON_NOCLIP,
    WEAPON_NOCLIP,
    -1,
    -1,// Damage of Secondary Fire ammo, -1 if not used
    4
};

array<string>
    STR_GRAVGUN_MODELS =
    {
        "models/hl2/p_gravgun.mdl",
        "models/hl2/v_gravgun.mdl",
        "models/hl2/w_gravgun.mdl",
        "sprites/hl2/weapon_hl2_gravgun.spr",
        "sprites/hl2/gravgunbeam.spr"
    },
    STR_GRAVGUN_SOUNDS =
    {
        "hl2/physcannon_charge.ogg",
        "hl2/physcannon_claws_close.ogg",
        "hl2/physcannon_claws_open.ogg",
        "hl2/physcannon_drop.ogg",
        "hl2/physcannon_dryfire.ogg",
        "hl2/physcannon_pickup.ogg",
        "hl2/physcannon_tooheavy.ogg",
        "hl2/superphys_hold_loop.ogg",
        "hl2/superphys_launch1.ogg",
        "hl2/superphys_launch2.ogg",
        "hl2/superphys_launch3.ogg",
        "hl2/superphys_launch4.ogg"
    },
    STR_GRAVGUN_MISC =
    {
        "events/muzzle_gravgun.txt",
        "events/muzzle_gravgun_beam.txt",
        "events/muzzle_gravgun_prongs.txt"
    };

const float 
    flFlingSpeed    = 1500.0f,
    flRange         = 1024.0f,
    flGrabDist      = 192.0f,
    flRadius        = 32.0f;

const string strWeapon_GravGun = "weapon_hl2_gravgun";

bool RegisterGravGun()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_GravGun, strWeapon_GravGun );
    g_ItemRegistry.RegisterWeapon( strWeapon_GravGun, "hl2", "" );

    return g_CustomEntityFuncs.IsCustomEntity( strWeapon_GravGun );
}

final class weapon_hl2_gravgun : CustomGunBase
{
    private ANIM_GRAVGUN AnimGrabReady = ANIM_GRAVGUN( -1 );
    private EHandle m_hTarget, m_hCarried, m_hPull, m_hFlung, m_hPotentialVictim;
    private CScheduledFunction@ fnAnimation;

    weapon_hl2_gravgun()
    {
        M_I_STATS = I_STATS_GRAVGUN;
        strSpriteDir = "hl2";
    }

    void Precache()
    {
        PrecacheContent( STR_GRAVGUN_MODELS, STR_GRAVGUN_SOUNDS, STR_GRAVGUN_MISC );
        BaseClass.Precache();
    }

    void Spawn()
    {
        SpawnWeapon( "models/hl2/w_gravgun.mdl" );
    }

    bool Deploy()
    {
        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( "models/hl2/v_gravgun.mdl" ), self.GetP_Model( "models/hl2/p_gravgun.mdl" ), ANIM_GRAVGUN::CLOSED_DRAW, "gauss" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_GRAVGUN[ANIM_GRAVGUN::CLOSED_DRAW];

        if( blDeployed )
        {
            g_Hooks.RegisterHook( Hooks::PickupObject::Collected, CollectedHook( this.CarryObjectCollected ) );
            self.pev.nextthink = g_Engine.time + 0.1f;
        }

        return blDeployed;
    }

    void Idle()
    {
        ANIM_GRAVGUN AnimIdle;

        if( m_hCarried )
            AnimIdle = ANIM_GRAVGUN::OPEN_HOLD;
        else if( AnimGrabReady == ANIM_GRAVGUN::CLOSED_TO_OPEN )
            AnimIdle = AnimGrabReady = ANIM_GRAVGUN::OPEN_IDLE;
        else 
            AnimIdle = ANIM_GRAVGUN::CLOSED_IDLE;

        self.SendWeaponAnim( AnimIdle );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_GRAVGUN[AnimIdle];
    }

    bool IsCarryObject(CBaseEntity@ pEntity)
    {
        if
        (   
            m_hCarried || 
            pEntity is null || 
            pEntity.IsBSPModel() || 
            pEntity.IsMonster() || 
            pEntity.pev.effects & EF_NODRAW != 0 ||
            !string( pEntity.pev.model ).EndsWith( ".mdl" )
        )
            return false;

        if( CarriedByOther( pEntity ) )
            return false;

        Vector vecDuckHullSize = ( VEC_HUMAN_HULL_MAX - VEC_HUMAN_HULL_MIN );
        float flVolume = vecDuckHullSize.x * vecDuckHullSize.y * vecDuckHullSize.z;

        return ( pEntity.pev.size.x * pEntity.pev.size.y * pEntity.pev.size.z ) <= flVolume;
    }

    bool CarriedByOther(CBaseEntity@ pEntity)
    {
        if( pEntity is null )
            return false;

        for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

            if( pPlayer is null || pPlayer is m_pPlayer || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
                continue;

            if( !pPlayer.m_hActiveItem || pPlayer.m_hActiveItem.GetEntity().GetClassname() != self.GetClassname() ) 
                continue;

            weapon_hl2_gravgun@ pGravGun = cast<weapon_hl2_gravgun@>( CastToScriptClass( pPlayer.m_hActiveItem.GetEntity() ) );

            if( pGravGun is null || !pGravGun.m_hCarried )
                continue;

            if( pEntity is pGravGun.m_hCarried.GetEntity() )
                return true;
        }

        return false;
    }

    TraceResult Zap(CBaseEntity@ pEntity)
    {
        if( pEntity is null )
            return TraceResult();
        
        CBeam@ pBeam = g_EntityFuncs.CreateBeam( "sprites/hl2/gravgunbeam.spr", 75 );
        pBeam.SetType( BEAM_ENTS );
        pBeam.EntsInit( pEntity, m_pPlayer );
        pBeam.SetEndAttachment( 1 );
        pBeam.SetColor( 255, 165, 0 );
        pBeam.SetNoise( 10 );
        pBeam.LiveForTime( 0.05f );

        g_Utility.Sparks( pEntity.pev.origin );
        g_Utility.Ricochet( pEntity.pev.origin, 2.0f );

        TraceResult trBeam;
        g_Utility.TraceLine( m_pPlayer.GetGunPosition(), pEntity.pev.origin, dont_ignore_monsters, dont_ignore_glass, m_pPlayer.edict(), trBeam );
        pBeam.BeamDamageInstant( trBeam, 10.0f );
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/superphys_launch" + Math.RandomLong( 1, 4 ) + ".ogg", 0.9f, ATTN_NORM, 0, PITCH_NORM );

        return trBeam;
    }
    // Get a potential object to grab - must exec cyclicly. m_hTarget is valid if found.
    bool FindObject()
    {
        const Vector
            vecStart = m_pPlayer.GetGunPosition(),
            vecEnd = vecStart + m_pPlayer.GetAutoaimVector( 0 ) * 1024.0f;

        TraceResult trForward;
        g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, dont_ignore_glass, m_pPlayer.edict(), trForward );

        if( trForward.flFraction < 1.0f )
        {
            CBaseEntity@ pHit = g_EntityFuncs.Instance( trForward.pHit ), pTarget;

            if( pHit is null || pHit.IsBSPModel() )
                m_hTarget = g_EntityFuncs.FindEntityInSphere( null, trForward.vecEndPos, flRadius, "*", "classname" );
        }
        else
            m_hTarget = EHandle();
        // Animations for when a target is grabbable
        if( m_hTarget )
        {
            if( AnimGrabReady == -1 && ( m_hTarget.GetEntity().pev.origin - m_pPlayer.GetGunPosition() ).Length() <= flGrabDist )
            {
                AnimGrabReady = ANIM_GRAVGUN::CLOSED_TO_OPEN;
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_BODY, "hl2/physcannon_claws_open.ogg", 0.4f, ATTN_NORM, 0, PITCH_NORM );
                self.SendWeaponAnim( AnimGrabReady );
                self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_GRAVGUN[AnimGrabReady];
            }
        }
        else if( AnimGrabReady != -1 )
        {
            AnimGrabReady = ANIM_GRAVGUN( -1 );
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_BODY, "hl2/physcannon_claws_close.ogg", 0.4f, ATTN_NORM, 0, PITCH_NORM );
            self.SendWeaponAnim( ANIM_GRAVGUN::OPEN_TO_CLOSED );
            self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_GRAVGUN[ANIM_GRAVGUN::OPEN_TO_CLOSED];
        }

        return m_hTarget.IsValid();
    }

    bool Grab()
    {
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        self.SendWeaponAnim( ANIM_GRAVGUN::OPEN_HOLD );
        m_hCarried = m_hTarget;
        m_hTarget = EHandle();

        if( !m_hCarried )
            return false;

        CBaseEntity@ pCarried = m_hCarried.GetEntity();
        pCarried.pev.velocity = g_vecZero;
        pCarried.Touch( m_pPlayer );
        g_SoundSystem.EmitSoundDyn( pCarried.edict(), CHAN_ITEM, "hl2/physcannon_pickup.ogg", 0.9f, ATTN_NORM, 0, PITCH_NORM );
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/superphys_hold_loop.ogg", 0.9f, ATTN_NORM, SND_FORCE_LOOP, PITCH_NORM );

        return m_hCarried.IsValid();
    }
    // Carry grabbed object - must exec cyclicly.
    void Carry()
    {
        if( !m_hCarried )
            return;

        CBaseEntity@ pCarried = m_hCarried.GetEntity();

        if( pCarried.pev.effects & EF_NODRAW != 0 )
        {   // Maybe the object was collected.
            Drop();
            return;
        }
        // There's surely a better way to do this?
        TraceResult trForward, trReflect;
        const Vector 
            vecStart = m_pPlayer.GetGunPosition(),
            vecEnd = vecStart + m_pPlayer.GetAutoaimVector( 0 ) * 96.0f;
        g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, dont_ignore_glass, m_pPlayer.edict(), trForward );
        g_Utility.TraceLine( trForward.vecEndPos, m_pPlayer.pev.origin, dont_ignore_monsters, dont_ignore_glass, pCarried.edict(), trReflect );
        Vector vecCarryPos = trReflect.vecEndPos + ( ( trForward.vecEndPos - m_pPlayer.pev.origin ) * 0.5f );

        g_EntityFuncs.SetOrigin( pCarried, vecCarryPos );
        pCarried.pev.angles.y = m_pPlayer.pev.angles.y;
        @pCarried.pev.owner = m_pPlayer.edict();
    }

    void Push()
    {
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        self.SendWeaponAnim( ANIM_GRAVGUN::CLOSED_FIRE );

        if( m_hTarget )
        {
            Zap( m_hTarget );
            m_hTarget.GetEntity().pev.movetype = MOVETYPE_TOSS;
            m_hTarget.GetEntity().pev.origin.z += 50.0f;
            m_hTarget.GetEntity().pev.velocity = m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES ) * flFlingSpeed + Vector( 0, 0, 30 );
        }

        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_GRAVGUN[ANIM_GRAVGUN::CLOSED_FIRE];
    }

    void Fling()
    {
        g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "hl2/superphys_hold_loop.ogg" );
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        self.SendWeaponAnim( ANIM_GRAVGUN::OPEN_FIRE );
        Zap( m_hCarried );

        CBaseEntity@ pCarried = m_hCarried.GetEntity(), pHit;
        pCarried.pev.movetype = MOVETYPE_TOSS;
        pCarried.pev.velocity = m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES ) * flFlingSpeed;
        //pCarried.pev.avelocity = CrossProduct( pCarried.Center(), self.pev.velocity * 50 ) / pow( pCarried.Center().Length(), 2 );
        pCarried.pev.gravity = m_pPlayer.pev.gravity;
        pCarried.pev.spawnflags |= SF_DODAMAGE;
        @pCarried.pev.owner = null;
        m_hFlung = m_hCarried;
        m_hCarried = EHandle();
        // Find a potential target to fling something at
        TraceResult trFling;
        g_Utility.TraceToss( m_hFlung.GetEntity().edict(), m_pPlayer.edict(), trFling );// Not accurate to where the object was actually tossed but good enough.

        if( trFling.flFraction < 1.0f )
        {
            @pHit = g_EntityFuncs.Instance( trFling.pHit );

            if( pHit is null || pHit.IsBSPModel() )// Missed? maybe check something nearby.
                @pHit = g_EntityFuncs.FindEntityInSphere( null, trFling.vecEndPos, 16, "*", "classname" );

            if( pHit !is null && pHit.IsMonster() && pHit.IsAlive() && pHit.IRelationship( m_pPlayer, true ) > R_AL && pHit !is m_pPlayer )
                m_hPotentialVictim = pHit;
        }

        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_GRAVGUN[ANIM_GRAVGUN::OPEN_FIRE];
    }

    void Drop()
    {
        CBaseEntity@ pCarried = m_hCarried.GetEntity();
        pCarried.pev.movetype = MOVETYPE_TOSS;
        pCarried.pev.velocity = m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );
        pCarried.pev.gravity = m_pPlayer.pev.gravity;
        @pCarried.pev.owner = null;
        m_hCarried = EHandle();
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/physcannon_drop.ogg", 0.9f, ATTN_NORM, 0, PITCH_NORM );
        @fnAnimation = g_Scheduler.SetTimeout( @self, "SendWeaponAnim", 0.1f, int( ANIM_GRAVGUN::OPEN_TO_CLOSED ), 0, 0 );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_GRAVGUN[ANIM_GRAVGUN::OPEN_TO_CLOSED];
        // Sound is not stopping!
        //g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "hl2/superphys_hold_loop.ogg" ); // Doesn't work. Have to do this a frame later
        //g_Scheduler.SetTimeout( @g_SoundSystem, "StopSound", 0.0f, m_pPlayer.edict(), CHAN_WEAPON, "hl2/superphys_hold_loop.ogg" );// Results in "ERROR: CASArguments: unknown type 'SOUND_CHANNEL', aborting!". WHY?!
        g_Scheduler.SetTimeout( this, "StopSound", 0.0f, "hl2/superphys_hold_loop.ogg", int( CHAN_WEAPON ), EHandle( m_pPlayer ) );
    }
    // somebody kill me now
    void StopSound(const string strSound, int channel, EHandle hEmitter = EHandle())
    {
        if( strSound == "" )
            return;

        edict_t@ eEmitter = hEmitter ? hEmitter.GetEntity().edict() : null;
        g_SoundSystem.StopSound( eEmitter, SOUND_CHANNEL( channel ), strSound );
    }

    HookReturnCode CarryObjectCollected(CBaseEntity@ pPickup, CBaseEntity@ pOther)
    {
        if( pPickup is null || !m_hCarried )
            return HOOK_CONTINUE;

        if( pPickup is m_hCarried.GetEntity() && pOther is m_pPlayer )
        {
            Drop();
            //pPickup.OnSetOriginByMap(); // 5.26 feature
        }

        return HOOK_CONTINUE;
    }

    void ItemPreFrame()
    {
        if( m_hCarried )
            Carry();
        else
            FindObject();

        BaseClass.ItemPreFrame();
    }

    void ItemPostFrame()
    {
        if( m_hFlung.IsValid() && m_hPotentialVictim.IsValid() )
        {
            CBaseEntity@
                pFlung = m_hFlung.GetEntity(),
                pVictim = m_hPotentialVictim.GetEntity();

            if( pFlung.pev.FlagBitSet( FL_ONGROUND ) )
            {
                m_hFlung = EHandle();
                return;
            }

            const float flDamage =
                pFlung.pev.dmg > 0.0f ?
                pFlung.pev.dmg :
                pFlung.pev.size.x * pFlung.pev.size.y * pFlung.pev.size.z * 0.01f;

            if( pFlung.Intersects( m_hPotentialVictim.GetEntity() ) )
            {
                pVictim.TakeDamage( pFlung.pev, m_pPlayer.pev, flDamage, DMG_CLUB | DMG_LAUNCH );
                pFlung.pev.velocity.x = pFlung.pev.velocity.y = 0;
                m_hFlung = m_hPotentialVictim = EHandle();
            }
            else if( pFlung.pev.FlagBitSet( FL_ONGROUND ) )
                m_hFlung = m_hPotentialVictim = EHandle();
        }

        BaseClass.ItemPostFrame();
    }
    
    void Think()
    {   // Deceleration business. Why am I forced to do this?
        for( int i = 0; i < 2 && m_hPull; i++ )
        {
            if( m_hPull.GetEntity().pev.velocity == g_vecZero )
            {
                m_hPull = EHandle();
                break;
            }

            m_hPull.GetEntity().pev.velocity[i] *= 0.01f;
        }

        self.pev.nextthink = g_Engine.time + 0.1f;
    }

    void PrimaryAttack()
    {
        if( m_hCarried )
            Fling();
        else if( m_hTarget && IsCarryObject( m_hTarget.GetEntity() ) )
            Push();
        else
            self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_GRAVGUN[ANIM_GRAVGUN::CLOSED_IDLE];

        if( self.m_flNextPrimaryAttack < g_Engine.time )
            self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;
    }

    void SecondaryAttack()
    {
        if( m_hTarget )
        {
            CBaseEntity@ pTarget = m_hTarget.GetEntity();

            if( IsCarryObject( pTarget ) )
            {   // Drag this thing towards us
                float flCurrentDist = ( pTarget.pev.origin - m_pPlayer.GetGunPosition() ).Length();

                if( pTarget.pev.FlagBitSet( FL_ONGROUND ) && flCurrentDist > flGrabDist )
                {
                    pTarget.pev.movetype = MOVETYPE_BOUNCE;
                    pTarget.pev.friction = 0.01f;
                    pTarget.pev.velocity.z += 10.0f;

                    for( int i = 0; i < 2; i++ )
                        pTarget.pev.velocity[i] = Vector( m_pPlayer.GetGunPosition() - pTarget.pev.origin )[i] * 6 / ( flCurrentDist / flGrabDist );

                    m_hPull = cast<CItem@>( pTarget ) !is null ? m_hTarget : EHandle();
                    self.SendWeaponAnim( ANIM_GRAVGUN::CLOSED_PULL );
                    @fnAnimation = g_Scheduler.SetTimeout( @self, "SendWeaponAnim", FL_ANIMTIME_GRAVGUN[ANIM_GRAVGUN::CLOSED_PULL], int( ANIM_GRAVGUN::CLOSED_IDLE ), 0, 0 );
                    g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/physcannon_tooheavy.ogg", 0.9f, ATTN_NORM, 0, PITCH_NORM );
                }
                else
                    Grab();
            }
            else
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/physcannon_tooheavy.ogg", 0.9f, ATTN_NORM, 0, PITCH_NORM );
        }
        else if( m_hCarried )
            Drop();
        else
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/physcannon_dryfire.ogg", 0.9f, ATTN_NORM, 0, PITCH_NORM );

        self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_GRAVGUN[ANIM_GRAVGUN::CLOSED_PULL];
    }

    void Reload() { }

    void Holster(int skiplocal)
    {
        if( m_hCarried )
            Drop();

        g_Scheduler.RemoveTimer( fnAnimation );
        g_Hooks.RemoveHook( Hooks::PickupObject::Collected, CollectedHook( this.CarryObjectCollected ) );
        m_hTarget = m_hCarried = m_hFlung = m_hPotentialVictim = EHandle();
        CustomGunBase::Holster( skiplocal );
        BaseClass.Holster( skiplocal );
    }

    void UpdateOnRemove()
    {
        g_Scheduler.RemoveTimer( fnAnimation );
        g_Hooks.RemoveHook( Hooks::PickupObject::Collected, CollectedHook( this.CarryObjectCollected ) );
    }
};

}
