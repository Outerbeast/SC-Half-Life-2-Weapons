/* Combine Pulse Cannon - weapon_hl2_pulsecannon
    Heavy weapon
    Primary Attack to shoot
    Secondary Attack to deploy the Pulse Cannon as a controllable mounted cannon
    Weapon must be dropped in order to switch to a different weapon

Part of the SC Half-Life 2 Weapons Pack.
- Outerbeast
*/
#include "weapon_base"

namespace HL2_WEAPONS
{   

enum ANIM_PULSECANNON
{
    IDLE1,
    IDLE2,
    IDLE3,
    IDLE4,
    DRAW,
    FIRE,
    HOLSTER,
    TRIPOD
};

enum SPAWNFLAGS_PULSECANNON
{
    SF_NOHEAT = 1 << 0, // Disables the heat system
    SF_NOLASER = 1 << 1,// Disables the laser sight
    SF_NOTRIPOD = 1 << 2, // Disables the tripod model
    SF_TANK_CANCONTROL = 1 << 10
};

const array<float> FL_ANIMTIME_PULSECANNON =
{
    2.7f,
    2.7f,
    2.7f,
    2.7f,
    1.03f,
    0.82f,
    1.03f,
    4.37f
};

array<int> I_STATS_PULSECANNON =
{
    4,//iSlot,
    8,//iPosition,
    600,//iMaxAmmo1,
    WEAPON_NOCLIP,//iMaxAmmo2,
    WEAPON_NOCLIP,//iMaxClip,
    int( g_EngineFuncs.CVarGetFloat( "sk_556_bullet" ) ),
    -1,
    10,
    ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_IGNOREWEAPONSTAY
};

array<string>
    STR_PULSECANNON_MODELS =
    {
        "models/hl2/w_tripod.mdl",
        "sprites/hl2/weapon_hl2_pulsecannon.spr"
    },
    STR_PULSECANNON_SOUNDS =
    {
        "hl2/pulsecannon_draw.ogg",
        "hl2/pulsecannon_shoot.ogg",
        "hl2/pulsecannon_spinup.ogg",
        "hl2/pulsecannon_spindown.ogg"
    };

const string strWeapon_PulseCannon = "weapon_hl2_pulsecannon";
uint16 iPulseCannonTurretCost = 300; 

bool RegisterPulseCannon()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_PulseCannon, strWeapon_PulseCannon );
    g_ItemRegistry.RegisterWeapon( strWeapon_PulseCannon, "hl2", "556" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::env_hl2_pulsecannon", "env_hl2_pulsecannon" );

    return g_CustomEntityFuncs.IsCustomEntity( strWeapon_PulseCannon );
}

final class weapon_hl2_pulsecannon : CustomGunBase
{
    private ThinkFunction@ fnDeploy;

    weapon_hl2_pulsecannon()
    {
        strModel_V = "models/hl2/v_pulsecannon.mdl";
        strModel_P = "models/hl2/p_pulsecannon.mdl";
        strModel_W = "models/hl2/w_pulsecannon.mdl";
        strSpriteDir = "hl2";
        M_I_STATS = I_STATS_PULSECANNON;
    }

    void Precache()
    {
        PrecacheContent( STR_PULSECANNON_MODELS, STR_PULSECANNON_SOUNDS );
        BaseClass.Precache();
    }

    void Spawn()
    {
        if( self.pev.noise == "" )
            self.pev.noise = "hl2/pulsecannon_shoot.ogg";

        SpawnWeapon( M_I_STATS[WpnStatIdx::iMaxAmmo1] );
        self.pev.spawnflags |= 256;// USE Only
        self.m_bExclusiveHold = true;
        BaseClass.Spawn();
    }

    bool CanDeploy()
    {
        return self.m_bExclusiveHold;
    }

    bool Deploy()
    {
        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( strModel_V ), self.GetP_Model( strModel_P ), ANIM_PULSECANNON::DRAW, "minigun" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_PULSECANNON[ANIM_PULSECANNON::DRAW];

        if( blDeployed )
        {
            m_pPlayer.SetMaxSpeedOverride( int( m_pPlayer.GetMaxSpeed() * 0.33f ) );
            m_pPlayer.pev.fuser4 = 1.0f;
        }

        return blDeployed;
    }

    void Idle()
    {
        m_iShotsFired = 0;
        const ANIM_PULSECANNON AnimIdle = ANIM_PULSECANNON( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, int( ANIM_PULSECANNON::IDLE1 ), int( ANIM_PULSECANNON::IDLE4 ) ) );
        self.SendWeaponAnim( AnimIdle );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_PULSECANNON[AnimIdle];
    }

    bool PreShoot()
    {
        self.SendWeaponAnim( ANIM_PULSECANNON::FIRE );
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        return true;
    }

    bool PostShoot()
    {
        m_iShotsFired++;
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, self.pev.noise, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        MuzzleFlash( RGBA( 50, 128, 255, 8 ) );
        DrawColourTracer( m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ), 3 );

        Vector vecAimPunch;
        g_Utility.GetCircularGaussianSpread( vecAimPunch.x, vecAimPunch.y );
        
        if( vecAimPunch.x < 0.0f )
            vecAimPunch.x *= 2;

        Recoil( vecAimPunch, log10( m_iShotsFired ) + 1 );

        if( DeductPrimaryAmmo() < 1 )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        return false;
    }

    void ItemThink()
    {
        if( !self.pev.SpawnFlagBitSet( 256 ) )
            self.pev.spawnflags |= 256;
        
        UpdateViewModelEntity();
    }

    void PlacePulseCannon()
    {
        Math.MakeVectors( m_pPlayer.pev.v_angle );
        const Vector 
            vecStart = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs,
            vecEnd = vecStart + g_Engine.v_forward * 45.0f;

        TraceResult trForward;
        g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, dont_ignore_glass, m_pPlayer.edict(), trForward );
        // Ensure the cannon does not clip through a surface
        Vector vecFinalPos = trForward.vecEndPos;
        vecFinalPos.z = m_pPlayer.pev.absmin.z;

        if( g_EntityFuncs.Create( "env_hl2_pulsecannon", vecFinalPos, Vector( 0, m_pPlayer.pev.angles.y, 0 ), false ) !is null )
        {
            SetThink( @fnDeploy = null );
            self.pev.nextthink = 0.0f;
            DeductPrimaryAmmo( iPulseCannonTurretCost );
            self.RetireWeapon();// Not necessary, but just in case of cosmic rays
            self.DestroyItem();
        }
    }

    void RestoreMovement()
    {
        m_pPlayer.SetMaxSpeedOverride( -1 );
        m_pPlayer.pev.fuser4 = 0.0f;
    }

    void PrimaryAttack()
    {
        if( fnDeploy !is null )
            return;

        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < 1 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;

            return;
        }

        Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ), self.BulletAccuracy( VECTOR_CONE_6DEGREES, VECTOR_CONE_6DEGREES, VECTOR_CONE_4DEGREES ), BULLET_PLAYER_SAW );

        if( self.m_flNextPrimaryAttack < g_Engine.time )
            self.m_flNextPrimaryAttack = g_Engine.time + 0.06f;

        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_PULSECANNON[ANIM_PULSECANNON::FIRE];
    }

    void SecondaryAttack()
    {
        if( fnDeploy !is null || m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || !m_pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
        {
            self.PlayEmptySound();
            self.m_flNextSecondaryAttack = g_Engine.time + 0.15f;

            return;
        }

        if( uint16( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) ) < iPulseCannonTurretCost )
        {
            g_PlayerFuncs.ClientPrint( m_pPlayer, HUD_PRINTCENTER, "" + iPulseCannonTurretCost + " ammo required to deploy Pulsecannon" );
            self.m_flNextSecondaryAttack = g_Engine.time + 0.15f;

            return;
        }

        self.SendWeaponAnim( ANIM_PULSECANNON::TRIPOD );
        SetThink( @fnDeploy = ThinkFunction( this.PlacePulseCannon ) );
        m_pPlayer.SetMaxSpeedOverride( 0 );// Disable player movement while deploying the cannon
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.pev.nextthink = g_Engine.time + FL_ANIMTIME_PULSECANNON[ANIM_PULSECANNON::TRIPOD];
    }

    CBasePlayerItem@ DropItem()
    {
        RestoreMovement();
        return self;
    }

    void Holster(int skiplocal = 0)
    {
        RestoreMovement();
        CustomGunBase::Holster( skiplocal );
    }

    void RetireWeapon()
    {
        RestoreMovement();
        BaseClass.RetireWeapon();
    }
};

final class env_hl2_pulsecannon : ScriptBaseAnimating
{
    float 
        T,// current temperature
        dT = 0.005f, // Heat differential unit
        flCoolInterval = 1.0f,
        flLastCoolTime;
    Vector vecOffset = Vector( 0, 0, 42 );
    string strTripodModel = "models/hl2/w_tripod.mdl";
    private dictionary dictCannon =
    {
        { "spriteflash", "sprites/hl2/ar2_muzzleflash.spr" },
        { "spritescale", "0.2" },
        { "bullet", "1" }, // This gets overridden anyway by the gun temperature.
        { "bullet_damage", "" + I_STATS_PULSECANNON[WpnStatIdx::iDamage1] },
        { "firerate", "17" },
        { "firespread", "1" },
        { "persistence", "1" },
        { "barrel", "36" },
        { "pitchtolerance", "5" },
        { "pitchrange", "60" },
        { "pitchrate", "500" },
        { "yawtolerance", "15" },
        { "yawrange", "60" },
        { "yawrate", "500" },
        { "spawnflags", "32" }
    };

    private EHandle hPulseCannon, hAimLaser, hTripod, hBarrelSmoke;
    private CBaseTank@ pCannon
    {
        get { return cast<CBaseTank@>( hPulseCannon.GetEntity() ); }
        set { hPulseCannon = EHandle( @value ); }
    }

    private CBeam@ m_pAimLaser
    {
        get { return cast<CBeam@>( hAimLaser.GetEntity() ); }
        set { hAimLaser = EHandle( @value ); }
    }

    int ObjectCaps()
    {
        return FCAP_IMPULSE_USE | BaseClass.ObjectCaps();
    }

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( dictCannon.exists( szKey ) )
            dictCannon[szKey] = szValue;
        else if( szKey == "offset" )
            g_Utility.StringToVector( vecOffset, szValue );
        else if( szKey == "cool_interval" )
            flCoolInterval = atof( szValue ) > 0.0f ? atof( szValue ) : 1.0f;
        else if( szKey == "tripod_model" )
            strTripodModel = szValue != "" ? szValue : "models/hl2/w_tripod.mdl";
        else
            return BaseClass.KeyValue( szKey, szValue );
 
        return true;
    }

    void Precache()
    {
        g_Game.PrecacheModel( self, self.pev.model );
        g_Game.PrecacheModel( self, strTripodModel );
        g_Game.PrecacheModel( self, string( dictCannon["spriteflash"] ) );
        g_Game.PrecacheOther( strWeapon_PulseCannon );
        g_SoundSystem.PrecacheSound( self, self.pev.noise );
        
        BaseClass.Precache();
    }

    void Spawn()
    {
        if( self.pev.model == "" )
            self.pev.model = "models/hl2/w_pulsecannon.mdl";

        if( self.pev.noise == "" )
            self.pev.noise = "hl2/pulsecannon_shoot.ogg";

        self.Precache();
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_BBOX;
        self.AddEntityFlag( EFLAG_IGNOREGRAVITY );
        g_EntityFuncs.SetModel( self, self.pev.model );
        g_EntityFuncs.SetOrigin( self, self.pev.origin + vecOffset );
        g_EntityFuncs.SetSize( self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX );
        
        if( self.GetTargetname() == "" )
            self.pev.targetname = "hl2_pulsecannon#" + self.entindex();

        BaseClass.Spawn();
    }

    void PostSpawn()
    {
        dictCannon["origin"] = self.pev.origin.ToString().Replace( ",", "" );
        dictCannon["angles"] = self.pev.angles.ToString().Replace( ",", "" );
        dictCannon["model"] = string( self.pev.model );
        dictCannon["targetname"] = "hl2_pulsecannon_deployed#" + self.entindex();
        dictCannon["target"] = self.GetTargetname();
        
        @pCannon = cast<CBaseTank@>( g_EntityFuncs.CreateEntity( "func_tank", dictCannon ) );
        pCannon.pev.solid = SOLID_NOT;// otherwise the game dies when player collides with it
        pCannon.pev.effects |= EF_NODRAW;
        @pCannon.pev.owner = self.edict();

        if( !self.pev.SpawnFlagBitSet( SF_NOTRIPOD ) )
        {   // Tripod model and position.
            dictionary dictTripod =
            {
                { "origin", ( self.pev.origin - vecOffset ).ToString().Replace( ",", "" ) },
                { "angles", self.pev.angles.ToString() },
                { "model", strTripodModel },
                { "minhullsize", VEC_HUMAN_HULL_MIN.ToString().Replace( ",", "" ) },
                { "maxhullsize", VEC_HUMAN_HULL_MAX.ToString().Replace( ",", "" ) },
                { "movetype", "8" },
                { "solid", "" + SOLID_BBOX }
            };

            hTripod = g_EntityFuncs.CreateEntity( "item_generic", dictTripod );
            @hTripod.GetEntity().pev.owner = self.edict();
        }

        g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/mine_deploy.wav", 1.0f, ATTN_NORM );

        if( !self.pev.SpawnFlagBitSet( SF_NOLASER ) && m_pAimLaser is null )
            CreateAimLaser();

        self.pev.nextthink = g_Engine.time + 0.1f;

        BaseClass.PostSpawn();
    }

    bool CreateAimLaser()
    {
        @m_pAimLaser = g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 6 );
        m_pAimLaser.SetType( BEAM_ENTPOINT );
        m_pAimLaser.PointEntInit( pCannon.BarrelPosition(), self );// The actual start position will be updated in Think()
        m_pAimLaser.SetEndAttachment( 2 );
        m_pAimLaser.SetColor( 83, 170, 213 );
        m_pAimLaser.SetNoise( 0 );
        m_pAimLaser.pev.effects |= EF_NODRAW;
        @m_pAimLaser.pev.owner = pCannon.edict();

        return m_pAimLaser !is null;
    }

    void HeatUp()// This is called when the cannon is shot.
    {
        if( T >= 1.0f || self.pev.SpawnFlagBitSet( SPAWNFLAGS_PULSECANNON::SF_NOHEAT ) )
            return;
        
        T += ( 1.0f + log10( T + 10.0f ) ) * dT;
        // Getting hot!
        if( T >= 0.3f && T < 0.7f )
            self.pev.skin = 1;
        else if( T >= 0.7f )
            self.pev.skin = 2;

        pCannon.m_spread = self.pev.skin + 1;
        // Barrel overheated.
        if( T >= 1.0f )
        {
            DisableCannon();
            hBarrelSmoke = g_EntityFuncs.Create( "env_smoker", pCannon.BarrelPosition() - Vector( 0, 0, 15 ), pCannon.pev.angles, false, pCannon.edict() );
            hBarrelSmoke.GetEntity().pev.health = 133769420.0f;
            hBarrelSmoke.GetEntity().pev.scale = 0.2f;
            g_SoundSystem.EmitSoundDyn( pCannon.edict(), CHAN_WEAPON, "hl2/pulsecannon_spindown.ogg", 1.0f, ATTN_NORM );
        }
    }

    void CoolDown(bool blForceCool = false)
    {
        if( blForceCool )
        {
            T = 0.0f;
            self.pev.skin = 0;
        }
        else if( T > 0.0f )
        {
            T -= ( 1.0f + log10( T + 10.0f ) ) * 5 * dT;

            if( T < 0.0f )
                T = 0.0f;
            else if( T < 0.3f )
                self.pev.skin = 0;
            else if( T < 0.7f )
                self.pev.skin = 1;

            flLastCoolTime = g_Engine.time;
        }
        else
            T = flLastCoolTime = 0.0f;
    }
    
    void EnableCannon()
    {
        if( pCannon.pev.SpawnFlagBitSet( SF_TANK_CANCONTROL ) )
            pCannon.pev.spawnflags &= ~SF_TANK_CANCONTROL;
    }

    void DisableCannon()
    {  
        if( !pCannon.pev.SpawnFlagBitSet( SF_TANK_CANCONTROL ) )
            pCannon.pev.spawnflags |= SF_TANK_CANCONTROL;
    }

    void Think()
    {   
        if( pCannon !is null )
        {   // Update the cannon model position and angles.
            self.pev.angles = pCannon.pev.angles;
            self.pev.angles.x *= -1;
            self.pev.avelocity = pCannon.pev.avelocity;

            if( hBarrelSmoke )
                g_EntityFuncs.SetOrigin( hBarrelSmoke.GetEntity(), pCannon.BarrelPosition() - Vector( 0, 0, 15 ) );

            if( T >= 1.0f )
                DisableCannon();
            else
                EnableCannon();
            // The cannon is being controlled by a player.
            if( pCannon.GetController() !is null )
            {
                Math.MakeVectors( pCannon.pev.angles );
                TraceResult trTank;
                pCannon.TankTrace( pCannon.BarrelPosition(), g_Engine.v_forward.Normalize() * 100, g_vecZero, trTank );
                m_pAimLaser.SetStartPos( trTank.vecEndPos );

                if( m_pAimLaser !is null && m_pAimLaser.pev.effects & EF_NODRAW != 0 )
                    m_pAimLaser.pev.effects &= ~EF_NODRAW;
            }
            else if( m_pAimLaser !is null && m_pAimLaser.pev.effects & EF_NODRAW == 0 )
                m_pAimLaser.pev.effects |= EF_NODRAW;
            // Passive cooling when the cannon is not being shot.
            if( T > 0.0f && g_Engine.time > pCannon.m_fireLast + 5.0f )
            {
                if( g_Engine.time > flLastCoolTime + flCoolInterval )
                {   // Start cooling down.
                    CoolDown();

                    if( hBarrelSmoke )
                        hBarrelSmoke.GetEntity().pev.health = 0.0f;
                }
            }
        }

        self.pev.nextthink = g_Engine.time;
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {   // The cannon is not being controlled yet. Allow a player to control it.
        if( pCannon.GetController() is null && pActivator.IsPlayer() )
        {
            CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );

            if( pPlayer.m_hActiveItem )
            {
                if
                (   // If the player is holding a Pulse Cannon or any exclusivehold weapon, controlling deployed Pulse Cannons is not allowed.
                    pPlayer.m_hActiveItem.GetEntity().GetClassname() == strWeapon_PulseCannon || 
                    cast<CBasePlayerItem@>( pPlayer.m_hActiveItem.GetEntity() ).m_bExclusiveHold
                )
                    return;
            }

            if( !pCannon.IsFacing( pActivator.pev, VIEW_FIELD_WIDE ) && !pCannon.pev.SpawnFlagBitSet( SF_TANK_CANCONTROL ) )
            {   // Invoking "Use" rather than "StartControl" as it accounts for additional checks.
                pCannon.Use( pActivator, pCaller, USE_ON );
                g_SoundSystem.EmitSoundDyn( pCannon.edict(), CHAN_WEAPON, "hl2/pulsecannon_spinup.ogg", 1.0f, ATTN_NORM );
            }
        }
        else if( pCaller is pCannon && useType == USE_TOGGLE )// The gun is being shot.
        {
            HeatUp();// Increase the barrel temperature
            g_SoundSystem.EmitSoundDyn( pCannon.edict(), CHAN_WEAPON, self.pev.noise, 1.0f, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        }
    }

    void OnSetOriginByMap()
    {
        g_EntityFuncs.SetOrigin( pCannon, self.pev.origin );
        g_EntityFuncs.SetOrigin( hTripod.GetEntity(), self.pev.origin - vecOffset );

        if( hBarrelSmoke )
            g_EntityFuncs.SetOrigin( hBarrelSmoke.GetEntity(), pCannon.BarrelPosition() - Vector( 0, 0, 15 ) );
    }

    void UpdateOnRemove()
    {
        g_EntityFuncs.Remove( pCannon );
        g_EntityFuncs.Remove( hTripod.GetEntity() );
        g_EntityFuncs.Remove( m_pAimLaser );
        g_EntityFuncs.Remove( hBarrelSmoke.GetEntity() );
        BaseClass.UpdateOnRemove();
    }
};

}
