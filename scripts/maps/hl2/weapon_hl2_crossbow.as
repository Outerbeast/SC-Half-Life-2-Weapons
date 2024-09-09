/* Crossbow - weapon_hl2_crossbow
    Primary fire: Fire a single crossbow bolt
    Secondary fire: Aim down sights
    Ammo: ammo_hl2_crossbow, 1 in clip, 9 reserve

Part of the SC Half-Life 2 Weapons Pack.
- Outerbeast
*/
#include "weapon_base"

namespace HL2_WEAPONS
{

enum ANIM_XBOW
{
    IDLE,
    IDLE_EMPTY,
    FIRE,
    FIRE_EMPTY,
    RELOAD,
    DRAW,
    DRAW_EMPTY,
    HOLSTER
};

const array<float> FL_ANIMTIME_XBOW =
{
    3.4f,
    2.07f,
    2.63f,
    0.73f,
    1.9f,
    1.07f,
    1.07f,
    0.47f,
};

array<int> I_STATS_XBOW =
{
    3,//iSlot,
    7,//iPosition,
    10,//iMaxAmmo1,
    -1,//iMaxAmmo2,
    1//iMaxClip,
};

array<string>
    STR_XBOW_MODELS =
    {
        "models/hl2/p_crossbow.mdl",
        "models/hl2/v_crossbow.mdl",
        "models/hl2/w_crossbow.mdl",
        "models/hl2/w_crossbow_clip.mdl",
        "models/hl2/crossbow_bolt.mdl",
        "models/hl2/scope_xbow.mdl",
        "sprites/hl2/weapon_hl2_crossbow.spr"
    },
    STR_XBOW_SOUNDS = { "hl2/xbow_fire1.ogg" };

const float flXbowBoltSpeed = 1000.0f;
const string
    strWeapon_XBow = "weapon_hl2_crossbow",
    strAmmo_XBow = "ammo_hl2_crossbow";

bool RegisterXBow()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_XBow, strWeapon_XBow );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strAmmo_XBow, strAmmo_XBow );
    g_ItemRegistry.RegisterWeapon( strWeapon_XBow, "hl2", strAmmo_XBow );

    g_Game.PrecacheOther( strWeapon_XBow );
    g_Game.PrecacheOther( strAmmo_XBow );
    
    return g_CustomEntityFuncs.IsCustomEntity( strWeapon_XBow );
}

final class weapon_hl2_crossbow : CustomGunBase
{
    weapon_hl2_crossbow()
    {
        strSpriteDir = "hl2";
        M_I_STATS = I_STATS_XBOW;
    }

    void Precache()
    {
        PrecacheContent( STR_XBOW_MODELS, STR_XBOW_SOUNDS );
        BaseClass.Precache();
    }

    void Spawn()
    {
        SpawnWeapon( "models/hl2/w_crossbow.mdl", M_I_STATS[WpnStatIdx::iMaxClip] * 4 );
        BaseClass.Spawn();
    }

    bool Deploy()
    {
        const ANIM_XBOW AnimDeploy = self.m_iClip > 0 ? ANIM_XBOW::DRAW : ANIM_XBOW::DRAW_EMPTY;
        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( "models/hl2/v_crossbow.mdl" ), self.GetP_Model( "models/hl2/p_crossbow.mdl" ), AnimDeploy, "bow" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_XBOW[AnimDeploy];

        return blDeployed;
    }

    void Idle()
    {
        const ANIM_XBOW AnimIdle = self.m_iClip > 0 ? ANIM_XBOW::IDLE : ANIM_XBOW::IDLE_EMPTY;
        self.SendWeaponAnim( AnimIdle );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_XBOW[AnimIdle];
    }

    void FireBolt(Vector& in vecAiming)
    {
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        self.SendWeaponAnim( ANIM_XBOW::FIRE_EMPTY );

        CBaseEntity@ pCrossbowBolt = g_EntityFuncs.Create( "crossbow_bolt", m_pPlayer.GetGunPosition(), Math.VecToAngles( vecAiming ), true, m_pPlayer.edict() );
        pCrossbowBolt.pev.speed = m_pPlayer.pev.waterlevel < WATERLEVEL_HEAD ? flXbowBoltSpeed : flXbowBoltSpeed / 2;
        pCrossbowBolt.pev.velocity = vecAiming * pCrossbowBolt.pev.speed;
        g_EntityFuncs.DispatchSpawn( pCrossbowBolt.edict() );
        g_EntityFuncs.SetModel( pCrossbowBolt, "models/hl2/crossbow_bolt.mdl" );
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/xbow_fire1.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );

        Recoil( Vector( Math.RandomLong( -2, -1 ), 0, 0 ) );

        if( --self.m_iClip < 1 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < 1 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
    }

    void AimDownSights(const int iZoomFov)
    {
        if( self.m_fInReload )
            return;

        m_pPlayer.set_m_szAnimExtension( "bowscope" );
        m_pPlayer.pev.viewmodel = "models/hl2/scope_xbow.mdl";
        //m_pPlayer.m_iHideHUD |= HIDEHUD_CROSSHAIR;
        CustomGunBase::AimDownSights( iZoomFov );
    }

    void HipFire()
    {
        m_pPlayer.set_m_szAnimExtension( "bow" );
        m_pPlayer.pev.viewmodel = self.GetV_Model( "models/hl2/v_crossbow.mdl" );
        //m_pPlayer.m_iHideHUD &= ~HIDEHUD_CROSSHAIR;
        CustomGunBase::HipFire();
    }

    void PrimaryAttack()
    {
        if( self.m_iClip < 1 )
        {
            self.Reload();
            return;
        }

        FireBolt( m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES ) );

        if( self.m_flNextPrimaryAttack < g_Engine.time )
            self.m_flNextPrimaryAttack = g_Engine.time + FL_ANIMTIME_XBOW[ANIM_XBOW::FIRE_EMPTY];

        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_XBOW[ANIM_XBOW::FIRE];// fire + reload duration
    }

    void SecondaryAttack()
    {
        if( self.m_fInReload )
            return;

        if( !self.m_fInZoom )
            AimDownSights( 40 );
        else
            HipFire();

        self.m_flNextSecondaryAttack = g_Engine.time + 1.0f;
    }

    void Reload()
    {
        if( self.m_iClip < 2 )
            BaseClass.Reload();

        self.DefaultReload( 1, ANIM_XBOW::RELOAD, FL_ANIMTIME_XBOW[ANIM_XBOW::RELOAD], 0 );
    }
};

final class ammo_hl2_crossbow : CustomAmmoBase
{
    ammo_hl2_crossbow()
    {
        strModel = "models/hl2/w_crossbow_clip.mdl";
        iClipSize = 1;
        iMax = 9;
    }
};

}
