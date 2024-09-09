/* Combine Pulse Cannon - weapon_hl2_pulsecannon
    Heavy weapon
    Primary Attack to shoot
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
    HOLSTER
};

const array<float> FL_ANIMTIME_PULSECANNON =
{
    2.7f,
    2.7f,
    2.7f,
    2.7f,
    1.03f,
    0.82f,
    1.03f
};

array<int> I_STATS_PULSECANNON =
{
    4,//iSlot,
    8,//iPosition,
    600,//iMaxAmmo1,
    -1,//iMaxAmmo2,
    -1,//iMaxClip,
    int( g_EngineFuncs.CVarGetFloat( "sk_556_bullet" ) ),
    -1,
    10,
    ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_IGNOREWEAPONSTAY
};

array<string>
    STR_PULSECANNON_MODELS =
    {
        "models/hl2/p_pulsecannon.mdl",
        "models/hl2/v_pulsecannon.mdl",
        "models/hl2/w_pulsecannon.mdl",
        "sprites/hl2/weapon_hl2_pulsecannon.spr"
    },
    STR_PULSECANNON_SOUNDS =
    {
        "hl2/pulsecannon_draw.ogg",
        "hl2/pulsecannon_shoot.ogg"
    };

const string strWeapon_PulseCannon = "weapon_hl2_pulsecannon";

bool RegisterPulseCannon()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_PulseCannon, strWeapon_PulseCannon );
    g_ItemRegistry.RegisterWeapon( strWeapon_PulseCannon, "hl2", "556" );

    return g_CustomEntityFuncs.IsCustomEntity( strWeapon_PulseCannon );
}

final class weapon_hl2_pulsecannon : CustomGunBase
{
    weapon_hl2_pulsecannon()
    {
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
        SpawnWeapon( self.GetW_Model( "models/hl2/w_pulsecannon.mdl" ), 600 );
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
        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( "models/hl2/v_pulsecannon.mdl" ), self.GetP_Model( "models/hl2/p_pulsecannon.mdl" ), ANIM_PULSECANNON::DRAW, "minigun" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_PULSECANNON[ANIM_PULSECANNON::DRAW];

        if( blDeployed )
            m_pPlayer.SetMaxSpeedOverride( int( m_pPlayer.GetMaxSpeed() * 0.33f ) );

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
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/pulsecannon_shoot.ogg", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
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

    void PrimaryAttack()
    {
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

    CBasePlayerItem@ DropItem()
    {
        m_pPlayer.SetMaxSpeedOverride( -1 );
        g_EntityFuncs.Remove( m_hViewModel.GetEntity() );

        return self;
    }

    void Holster(int skiplocal = 0)
    {
        m_pPlayer.SetMaxSpeedOverride( -1 );
        g_EntityFuncs.Remove( m_hViewModel.GetEntity() );
        CustomGunBase::Holster( skiplocal );
    }
};

}
