/* AR2 Pulse Rifle - weapon_hl2_ar2
    Primary fire: Shoots full auto at 600rpm
    Secondary fire: launches energy ball
    Primary Ammo: ammo_hl2_ar2, 30 in clip, 90 reserve
    Secondary ammo: ammo_hl2_altfire, 3 reserve

Part of the SC Half-Life 2 Weapons Pack.
- Outerbeast
*/
#include "weapon_base"

namespace HL2_WEAPONS
{

enum ANIM_AR2
{
    IDLE,
    DRAW,
    FIRE1,
    FIRE2,
    FIRE3,
    FIRE4,
    LAUNCH,
    RELOAD,
    IDLE_LAST,
    DRAW_LAST,
    FIRE_LAST,
    LAUNCH_LAST,
    RELOAD_LAST,
    IDLE_EMPTY,
    DRAW_EMPTY,
    FIRE_EMPTY,
    LAUNCH_EMPTY,
    RELOAD_EMPTY,
    HOLSTER
};

const array<float> FL_ANIMTIME_AR2 =
{
    2.7f,
    0.87f,
    0.47f,
    0.7f,
    0.93f,
    0.93f,
    2.63f,
    2.3f,
    2.7f,
    0.87f,
    0.62f,
    2.63f,
    2.3f,
    2.7f,
    0.87f,
    0.62f,
    2.63f,
    2.23f,
    0.7f
};

array<int> I_STATS_AR2 =
{
    3,//iSlot,
    6,//iPosition,
    90,//iMaxAmmo1,
    3,//iMaxAmmo2,
    30,//iMaxClip,
    int( g_EngineFuncs.CVarGetFloat( "sk_556_bullet" ) ),
    300
};

array<string>
    STR_AR2_MODELS =
    {
        "models/hl2/p_ar2.mdl",
        "models/hl2/v_ar2.mdl",
        "models/hl2/w_ar2.mdl",
        "models/hl2/w_ar2_clip.mdl",
        "models/hl2/w_ar2_energy.mdl",
        "models/hl2/ar2_energyball.mdl",
        "models/hl2/disintegration_fx.mdl",
        "sprites/hl2/weapon_hl2_ar2.spr",
        "sprites/hl2/ar2_muzzleflash.spr",
        "sprites/hl2/hl2ammo.spr",
        "sprites/laserbeam.spr"
    },
    STR_AR2_SOUNDS =
    {
        "hl2/ar2_single.ogg",
        "hl2/ar2_altfire.ogg",
        "hl2/ar2_charge.ogg",
        "hl2/eball_bounce1.ogg",
        "hl2/eball_bounce2.ogg",
        "hl2/eball_explode1.ogg",
        "hl2/eball_explode2.ogg",
        "hl2/eball_explode3.ogg",
        "hl2/energy_sing_loop.ogg",
        "hl2/ar2_reload_push.ogg",
        "hl2/ar2_reload_rotate.ogg",
        "weapons/dryfire_rifle.wav"
    };

const float flEnergyBallSpeed = 700.0f;

const string
    strWeapon_AR2   = "weapon_hl2_ar2",
    strAmmo_AR2_1   = "ammo_hl2_ar2",
    strAmmo_AR2_2   = "ammo_hl2_ar2_altfire";

bool RegisterAR2()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_AR2, strWeapon_AR2 );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strAmmo_AR2_1, strAmmo_AR2_1 );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strAmmo_AR2_2, strAmmo_AR2_2 );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::ar2_energy_ball", "ar2_energy_ball" );
    
    g_ItemRegistry.RegisterWeapon( strWeapon_AR2, "hl2", strAmmo_AR2_1, strAmmo_AR2_2, "HL2_WEAPONS::" + strAmmo_AR2_1, "HL2_WEAPONS::" + strAmmo_AR2_2 );

    g_Game.PrecacheOther( strWeapon_AR2 );
    g_Game.PrecacheOther( strAmmo_AR2_1 );
    g_Game.PrecacheOther( strAmmo_AR2_2 );

    return g_CustomEntityFuncs.IsCustomEntity( strWeapon_AR2 );
}

final class weapon_hl2_ar2: CustomGunBase
{
    weapon_hl2_ar2()
    {
        strSpriteDir = "hl2";
        M_I_STATS = I_STATS_AR2;
    }

    void Precache()
    {
        PrecacheContent( STR_AR2_MODELS, STR_AR2_SOUNDS );
        BaseClass.Precache();
    }

    void Spawn()
    {
        SpawnWeapon( "models/hl2/w_ar2.mdl", M_I_STATS[WpnStatIdx::iMaxClip] * 2 );
        self.m_iDefaultSecAmmo = 0;

        BaseClass.Spawn();
    }

    bool Deploy()
    {
        ANIM_AR2 AnimDeploy;

        switch( self.m_iClip )
        {
            case 0:
                AnimDeploy = ANIM_AR2::DRAW_EMPTY;
                break;

            case 1:
                AnimDeploy = ANIM_AR2::DRAW_LAST;
                break;

            default:
                AnimDeploy = ANIM_AR2::DRAW;
        }

        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( "models/hl2/v_ar2.mdl" ), self.GetP_Model( "models/hl2/p_ar2.mdl" ), AnimDeploy, "m16" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_AR2[AnimDeploy];

        return blDeployed;
    }

    void Idle()
    {
        ANIM_AR2 AnimIdle;

        switch( self.m_iClip )
        {
            case 0:
                AnimIdle = ANIM_AR2::IDLE_EMPTY;
                break;

            case 1:
                AnimIdle = ANIM_AR2::IDLE_LAST;
                break;

            default:
                AnimIdle = ANIM_AR2::IDLE;
        }

        self.SendWeaponAnim( AnimIdle );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_AR2[AnimIdle];
        m_iShotsFired = 0;
    }

    bool PreShoot()
    {
        switch( self.m_iClip )
        {
            case 1:
                self.SendWeaponAnim( ANIM_AR2::FIRE_EMPTY );
                break;

            case 2:
                self.SendWeaponAnim( ANIM_AR2::FIRE_LAST );
                break;

            default:
                self.SendWeaponAnim( Math.clamp( ANIM_AR2::FIRE1, ANIM_AR2::FIRE4, m_iShotsFired ) );
        }

        return true;
    }

    bool PostShoot()
    {
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/ar2_single.ogg", 0.9f, ATTN_NORM, 0, PITCH_NORM );
        MuzzleFlash( RGBA( 50, 128, 255, 8 ) );
        DrawColourTracer( m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ), 3 );

        Vector vecAimPunch;
        g_Utility.GetCircularGaussianSpread( vecAimPunch.x, vecAimPunch.y );
        // bias towards top for muzzle rise
        if( vecAimPunch.x < 0.0f )
            vecAimPunch.x *= 2;

        Recoil( vecAimPunch, log10( m_iShotsFired ) + 1 );

        return true;
    }

    void EnergyShot()
    {
        CBaseEntity@ pEnergyBall = g_EntityFuncs.Create( "ar2_energy_ball", m_pPlayer.GetGunPosition(), g_vecZero, true, m_pPlayer.edict() );

        if( pEnergyBall is null )
            return;

        pEnergyBall.pev.speed = flEnergyBallSpeed;
        pEnergyBall.pev.velocity = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ) * pEnergyBall.pev.speed;

        if( g_EntityFuncs.DispatchSpawn( pEnergyBall.edict() ) < 0 )
            return;
        
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/ar2_altfire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );

        if( DeductSecondaryAmmo() < 1 )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        Recoil( Vector( -10, 0, 0 ) );
        SetThink( null );

        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_AR2[ANIM_AR2::LAUNCH];
    }

    void PrimaryAttack()
    {
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip < 1 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;

            return;
        }

        Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ), self.BulletAccuracy( VECTOR_CONE_4DEGREES, VECTOR_CONE_3DEGREES, VECTOR_CONE_2DEGREES ), BULLET_PLAYER_SAW );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_AR2[ANIM_AR2::FIRE4];

        if( self.m_flNextPrimaryAttack < g_Engine.time )
            self.m_flNextPrimaryAttack = g_Engine.time + 0.1f;
    }

    void SecondaryAttack()
    {   
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) < 1 )
        {
            self.PlayEmptySound();
            self.m_flNextSecondaryAttack = g_Engine.time + 0.1f;

            return;
        }

        ANIM_AR2 AnimLaunch;

        switch( self.m_iClip )
        {
            case 0:
                AnimLaunch = ANIM_AR2::LAUNCH_EMPTY;
                break;

            case 1:
                AnimLaunch = ANIM_AR2::LAUNCH_LAST;
                break;

            default:
                AnimLaunch = ANIM_AR2::LAUNCH;
        }
        // Charge up!
        m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
        m_pPlayer.m_flStopExtraSoundTime = g_Engine.time + 0.2f;
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/ar2_charge.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
        self.SendWeaponAnim( AnimLaunch );
        SetThink( ThinkFunction( this.EnergyShot ) );
        self.pev.nextthink = g_Engine.time + FL_ANIMTIME_AR2[AnimLaunch] - 1.63f; // Moment when the gun shoots the orb
        self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_AR2[AnimLaunch];
    }

    void Reload()
    {
        if( self.m_iClip < self.iMaxClip() )
            BaseClass.Reload();

        ANIM_AR2 AnimReload;

        switch( self.m_iClip )
        {
            case 0:
                AnimReload = ANIM_AR2::RELOAD_EMPTY;
                break;

            case 1:
                AnimReload = ANIM_AR2::RELOAD_LAST;
                break;

            default:
                AnimReload = ANIM_AR2::RELOAD;
        }

        self.DefaultReload( self.iMaxClip(), AnimReload, FL_ANIMTIME_AR2[AnimReload], 0 );
    }
};

final class ammo_hl2_ar2 : CustomAmmoBase
{
    ammo_hl2_ar2()
    {
        strModel = "models/hl2/w_ar2_clip.mdl";
        strPickupSound = "items/9mmclip1.wav";
        iClipSize = iMax = I_STATS_AR2[WpnStatIdx::iMaxClip];
    }
};

final class ammo_hl2_ar2_altfire : CustomAmmoBase
{
    ammo_hl2_ar2_altfire()
    {
        strModel = "models/hl2/w_ar2_energy.mdl";
        strPickupSound = "items/9mmclip1.wav";
        iClipSize = 1;
        iMax = I_STATS_AR2[WpnStatIdx::iMaxAmmo2];
    }
};

final class ar2_energy_ball : ScriptBaseAnimating
{
    private uint iBounceLimit = 10;
    private float flLifeTime = 30.0f;
    private CScheduledFunction@ fnApplyTargetMagnetism, fnCheckStuck;

    CBasePlayer@ m_pPlayer
    {
        get { return cast<CBasePlayer@>( g_EntityFuncs.Instance( self.pev.owner ) ); }
    }

    void Spawn()
    {
        self.pev.movetype   = MOVETYPE_BOUNCEMISSILE;
        self.pev.solid      = SOLID_BBOX;
        self.pev.scale      = 1.5f;
        self.pev.skin       = 1;
        self.pev.framerate  = 10.0f;
        self.pev.effects    |= EF_BRIGHTLIGHT;

        g_EntityFuncs.SetOrigin( self, self.pev.origin );
        g_EntityFuncs.SetModel( self, "models/hl2/ar2_energyball.mdl" );
        g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );

        SetThink( ThinkFunction( this.Travel ) );
        SetTouch( TouchFunction( this.Impact ) );
        self.pev.nextthink = g_Engine.time + 0.1f;
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "hl2/energy_sing_loop.ogg", 0.7f, ATTN_NORM, SND_FORCE_LOOP, PITCH_NORM );

        BaseClass.Spawn();
    }

    void Travel()
    {
        if( m_pPlayer is null || !m_pPlayer.IsConnected() )
        {
            Detonate();
            return;
        }

        self.pev.angles = Math.VecToAngles( self.pev.velocity );

        if( ++self.pev.skin > 26 )
            self.pev.skin = 0;

        flLifeTime -= 0.5f;

        if( flLifeTime <= 0.0f )
        {
            Detonate();
            return;
        }
        else
            self.pev.nextthink = g_Engine.time + 0.1f;

        @fnCheckStuck = g_Scheduler.SetTimeout( this, "CheckStuck", 0.2f, self.pev.origin );
    }

    void CheckStuck(const Vector vecPrevPos)
    {
        if( self.pev.origin == vecPrevPos )
            Detonate();
    }

    void Impact(CBaseEntity@ pOther)
    {
        if( m_pPlayer is null || !m_pPlayer.IsConnected() )
        {
            Detonate();
            return;
        }

        if( pOther is null || ( pOther.IsBSPModel() && !pOther.IsBreakable() ) )
        {
            TraceResult trGlobal = g_Utility.GetGlobalTrace();

            if( g_EngineFuncs.PointContents( trGlobal.vecEndPos ) == CONTENTS_SKY )
            {
                g_EntityFuncs.Remove( self );
                return;
            }
            
            Bounce();

            CSprite@ pImpactSpr = g_EntityFuncs.CreateSprite( "sprites/hl2/ar2_muzzleflash.spr", self.pev.origin, false, 0.0f );
            g_EntityFuncs.DispatchKeyValue( pImpactSpr.edict(), "vp_type", "4" );
            pImpactSpr.SetScale( 0.5f );
            pImpactSpr.SetTransparency( kRenderTransAdd, 255, 255, 100, 128, 0 );
            pImpactSpr.pev.angles = Math.VecToAngles( trGlobal.vecPlaneNormal );
            pImpactSpr.pev.angles.z = self.pev.angles.x;
            pImpactSpr.pev.angles.y -= 180;// Correction
            pImpactSpr.SUB_StartFadeOut();
            g_Utility.Sparks( self.pev.origin );
            // exec in next frame, guarantees velocity used in the method is actually the trajectory after bounce
            @fnApplyTargetMagnetism = g_Scheduler.SetTimeout( this, "ApplyTargetMagnetism", 0.0f );

            return;
        }

        if( pOther.edict() is self.pev.owner )
            return;

        switch( pOther.pev.solid )
        {
            case SOLID_NOT:
            case SOLID_TRIGGER:
                return;
        }

        if( pOther.IsMonster() ? pOther.IRelationship( m_pPlayer ) > R_AL : ( pOther.IsBreakable() ? true : false ) )
        {
            pOther.TakeDamage( self.pev, self.pev.owner.vars, I_STATS_AR2[WpnStatIdx::iDamage2], DMG_BLAST | DMG_ENERGYBEAM | DMG_NEVERGIB );

            if( pOther.IsMonster() && !pOther.IsMachine() && !pOther.IsAlive() )
                DisintegrateTarget( pOther );

            Bounce();
        }
    }

    void Bounce()
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "hl2/eball_bounce" + Math.RandomLong( 1, 2 ) + ".ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
        g_Utility.Ricochet( self.pev.origin, 5 );
        
        if( --iBounceLimit < 1 )
            Detonate();
    }

    void ApplyTargetMagnetism()
    {
        array<CBaseEntity@> P_TARGETS( 8 );

        if( g_EntityFuncs.MonstersInSphere( @P_TARGETS, self.pev.origin, 128 ) < 1 )
            return;

        do( P_TARGETS.removeAt( P_TARGETS.findByRef( null ) ) );
        while( P_TARGETS.findByRef( null ) >= 0 );

        for( uint i = 0; i < P_TARGETS.length(); i++ )
        {
            if( P_TARGETS[i] is null || !P_TARGETS[i].IsAlive() || P_TARGETS[i].edict() is self.pev.owner )
                continue;

            if( !P_TARGETS[i].pev.FlagBitSet( FL_MONSTER ) || P_TARGETS[i].pev.FlagBitSet( FL_CLIENT ) )
                continue;
            // I bet this does nothing.
            if( !self.IsFacing( P_TARGETS[i].pev, VIEW_FIELD_NARROW ) || P_TARGETS[i].IRelationship( m_pPlayer ) == R_AL )
                continue;

            const float flAffinity = DotProduct( self.pev.velocity, self.pev.origin - P_TARGETS[i].Center() );

            if( flAffinity <= 0.0f )
                continue;

            P_TARGETS[i].pev.fuser2 = flAffinity;
        }
        // Is this computationally expensive??
        P_TARGETS.sort( function( a, b ) { if( a is null || b is null ) return false; return a.pev.fuser2 > b.pev.fuser2; } );

        if( P_TARGETS[0] !is null )
            self.pev.velocity = ( P_TARGETS[0].Center() - self.pev.origin ).Normalize() * self.pev.speed;
    }

    void DisintegrateTarget(EHandle hTarget)
    {
        if( !hTarget )
            return;

        CBaseEntity@ pTarget = hTarget.GetEntity();
        CSprite@
            pGhost = g_EntityFuncs.CreateSprite( pTarget.pev.model, pTarget.pev.origin, false, 0.0f ),
            pFizzle = g_EntityFuncs.CreateSprite( "models/hl2/disintegration_fx.mdl", pTarget.Center(), true, 20.0f );

        pGhost.SetTransparency( kRenderTransTexture, 0, 0, 0, 128, 0 );
        pGhost.pev.movetype = MOVETYPE_FLY;
        pGhost.pev.skin = -1;
        pGhost.pev.frame = pTarget.pev.frame;
        pGhost.pev.sequence = pTarget.pev.sequence;
        pGhost.pev.velocity = self.pev.velocity / 10;
        pGhost.pev.velocity.z = 0;
        pGhost.pev.velocity.z += 5;// add some upward drift
        pGhost.SetScale( pTarget.pev.scale * 1.12f );
        pGhost.SUB_StartFadeOut();// !-ISSUE-!: this method resets avelocity to g_vecZero!
        // Setting avelocity AFTER SUB_StartFadeOut() >:]
        pGhost.pev.avelocity = CrossProduct( pTarget.Center(), self.pev.velocity * 50 ) / pow( pGhost.Center().Length(), 2 );
        pGhost.pev.avelocity = pGhost.pev.avelocity * 2;// SPEEN FASTER
        pGhost.pev.effects |= EF_INVLIGHT;// hopium

        pFizzle.SetScale( pTarget.pev.scale * 1.12f );
        pFizzle.SUB_StartFadeOut();
        pFizzle.pev.velocity = pGhost.pev.velocity;
        pFizzle.pev.avelocity = pGhost.pev.avelocity;
        
        pTarget.SUB_Remove();
    }

    void Detonate()
    {
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "hl2/eball_explode" + Math.RandomLong( 1, 3 ) + ".ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );

        NetworkMessage shockwave( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
            shockwave.WriteByte( TE_BEAMTORUS );

            shockwave.WriteCoord( self.pev.origin.x );
            shockwave.WriteCoord( self.pev.origin.y );
            shockwave.WriteCoord( self.pev.origin.z );
            shockwave.WriteCoord( self.pev.origin.x );
            shockwave.WriteCoord( self.pev.origin.y );
            shockwave.WriteCoord( self.pev.origin.z + 196 );

            shockwave.WriteShort( g_EngineFuncs.ModelIndex( "sprites/laserbeam.spr" ) );

            shockwave.WriteByte( 0 );// start frame
            shockwave.WriteByte( 16 );// fps

            shockwave.WriteByte( 8 );// life
            shockwave.WriteByte( 32 );// width
            shockwave.WriteByte( 0 );// noise

            shockwave.WriteByte( 128 );
            shockwave.WriteByte( 128 );
            shockwave.WriteByte( 50 );
            shockwave.WriteByte( 100 );

            shockwave.WriteByte( 8 );
        shockwave.End();

        g_PlayerFuncs.ScreenShake( self.pev.origin, 10, 1, 5, 64 );

        g_EntityFuncs.Remove( self );
    }

    void UpdateOnRemove()
    {
        g_SoundSystem.StopSound( self.edict(), CHAN_WEAPON, "hl2/energy_sing_loop.ogg" );
        self.pev.nextthink = 0.0f;
        SetTouch( null );
        SetThink( null );
        g_Scheduler.RemoveTimer( fnApplyTargetMagnetism );
        g_Scheduler.RemoveTimer( fnCheckStuck );
    }
};

}
