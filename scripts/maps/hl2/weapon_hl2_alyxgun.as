/* ALyx's Gun - weapon_hl2_alyxgun
    Primary fire: shoots a single bullet ( full auto fire in SMG mode)
    Secondary fire: unfolds gun and enables SMG mode for full auto fire
    Ammo: uses stock 9mm ammo

Part of the SC Half-Life 2 Weapons Pack.
- Outerbeast
*/
#include "weapon_base"

namespace HL2_WEAPONS
{

enum ANIM_ALYXGUN
{
    PISTOL_IDLE,
    PISTOL_SHOOT,
    PISTOL_RELOAD,
    PISTOL_DRAW,
    SMG_IDLE,
    SMG_SHOOT,
    SMG_RELOAD,
    SMG_DRAW,
    PISTOL_TO_SMG,
    SMG_TO_PISTOL
};

const array<float> FL_ANIMTIME_ALYXGUN =
{
    3.5f,
    0.43f,
    2.82f,
    1.13f,
    3.47f,
    0.57f,
    1.82f,
    0.97f,
    1.95f,
    0.98f
};

array<int> I_STATS_ALYXGUN =
{
    1,//iSlot,
    6,//iPosition,
    300,//iMaxAmmo1,
    -1,//iMaxAmmo2,
    20//iMaxClip,
};

array<string>
    STR_ALYXGUN_MODELS =
    {
        "models/hl2/w_alyxgun.mdl",
        "models/hl2/p_alyxgun.mdl",
        "models/hl2/p_alyxgun_smg.mdl",
        "models/hl2/v_alyxgun.mdl",
        "sprites/hl2/weapon_hl2_alyxgun.spr"
    },
    STR_ALYXGUN_SOUNDS =
    {
        "hl2/alyxgun_fire1.ogg",
        "hl2/alyxgun_reload1.ogg",
        "hl2/alyxgun_reload2.ogg",
        "hl2/alyxgun_switchfrom.ogg",
        "hl2/alyxgun_switchto.ogg"
    };

const string strWeapon_AlyxGun = "weapon_hl2_alyxgun";

bool RegisterAlyxGun()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_AlyxGun, strWeapon_AlyxGun );
    g_ItemRegistry.RegisterWeapon( strWeapon_AlyxGun, "hl2", "9mm" );
    g_Game.PrecacheOther( strWeapon_AlyxGun );

    return g_CustomEntityFuncs.IsCustomEntity( strWeapon_AlyxGun );
}

final class weapon_hl2_alyxgun : CustomGunBase
{
    weapon_hl2_alyxgun()
    {
        strSpriteDir = "hl2";
        M_I_STATS = I_STATS_ALYXGUN;
    }

    void Precache()
    {   
        PrecacheContent( STR_ALYXGUN_MODELS, STR_ALYXGUN_SOUNDS );
        g_Game.PrecacheGeneric( "sprites/hl2/weapon_hl2_alyxgun_smg.txt" );
        BaseClass.Precache();
    }

    void Spawn()
    {
        SpawnWeapon( "models/hl2/w_alyxgun.mdl", M_I_STATS[WpnStatIdx::iMaxClip] * 2 );
        self.m_fIsAkimbo = false;
        BaseClass.Spawn();
    }

    bool Deploy()
    {
        const ANIM_ALYXGUN AnimDeploy = self.m_fIsAkimbo ? ANIM_ALYXGUN::SMG_DRAW : ANIM_ALYXGUN::PISTOL_DRAW;
        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( "models/hl2/v_alyxgun.mdl" ), self.GetP_Model( "models/hl2/p_alyxgun.mdl" ), AnimDeploy, "onehanded" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_ALYXGUN[AnimDeploy];

        return blDeployed;
    }

    void Idle()
    {
        m_iShotsFired = 0;
        const ANIM_ALYXGUN AnimIdle = self.m_fIsAkimbo ? ANIM_ALYXGUN::SMG_IDLE : ANIM_ALYXGUN::PISTOL_IDLE;
        self.SendWeaponAnim( AnimIdle );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_ALYXGUN[AnimIdle];
    }

    bool PreShoot()
    {
        self.SendWeaponAnim( self.m_fIsAkimbo ? ANIM_ALYXGUN::SMG_SHOOT : ANIM_ALYXGUN::PISTOL_SHOOT );
        return true;
    }

    bool PostShoot()
    {
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/alyxgun_fire1.ogg", 1.0f, ATTN_NORM, 0, PITCH_NORM );
        MuzzleFlash( RGBA( 255, 200, 180, 8 ) ); 
        EjectCasing( 26.0f, 16.0f, -15.0f );

        Vector vecAimPunch = Vector( -2, 0, 0 );

        if( self.m_fIsAkimbo )
        {
            g_Utility.GetCircularGaussianSpread( vecAimPunch.x, vecAimPunch.y );
            // bias towards top for muzzle rise
            if( vecAimPunch.x < 0.0f )
                vecAimPunch.x *= 3;
        }

        Recoil( vecAimPunch, self.m_fIsAkimbo ? log10( m_iShotsFired ) + 1 : 1 );

        return true;
    }

    void PrimaryAttack()
    {
        if( self.m_iClip < 1 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;

            return;
        }

        if( self.m_fIsAkimbo )
        {
            Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES ), self.BulletAccuracy( VECTOR_CONE_6DEGREES, VECTOR_CONE_5DEGREES, VECTOR_CONE_4DEGREES ), BULLET_PLAYER_9MM );
            self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_ALYXGUN[ANIM_ALYXGUN::SMG_SHOOT];
        }
        else
        {
            Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ), self.BulletAccuracy( VECTOR_CONE_4DEGREES, VECTOR_CONE_3DEGREES, VECTOR_CONE_3DEGREES ), BULLET_PLAYER_9MM );
            self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_ALYXGUN[ANIM_ALYXGUN::PISTOL_SHOOT];
        }

        if( self.m_flNextPrimaryAttack < g_Engine.time )
            self.m_flNextPrimaryAttack = g_Engine.time + ( self.m_fIsAkimbo ? 0.1f : 0.2f );
    }

    void SecondaryAttack()
    {
        if( !self.m_fIsAkimbo )
        {
            self.SendWeaponAnim( ANIM_ALYXGUN::PISTOL_TO_SMG );
            m_pPlayer.pev.weaponmodel = "models/hl2/p_alyxgun_smg.mdl";
            self.LoadSprites( m_pPlayer, self.GetClassname() + "_smg" );
            self.m_fIsAkimbo = true;
        }
        else
        {
            self.SendWeaponAnim( ANIM_ALYXGUN::SMG_TO_PISTOL );
            m_pPlayer.pev.weaponmodel = self.GetP_Model( "models/hl2/p_alyxgun.mdl" );
            self.LoadSprites( m_pPlayer, self.GetClassname() );
            self.m_fIsAkimbo = false;
        }

        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_ALYXGUN[self.m_fIsAkimbo ? ANIM_ALYXGUN::PISTOL_TO_SMG : ANIM_ALYXGUN::SMG_TO_PISTOL];
    }

    void Reload()
    {
        if( self.m_iClip < self.iMaxClip() )
            BaseClass.Reload();

        const ANIM_ALYXGUN AnimReload = self.m_fIsAkimbo ? ANIM_ALYXGUN::SMG_RELOAD : ANIM_ALYXGUN::PISTOL_RELOAD;
        self.DefaultReload( self.iMaxClip(), AnimReload, FL_ANIMTIME_ALYXGUN[AnimReload], 0 );
    }

    void Holster(int skiplocal)
    {
        SetThink( null );
        self.m_fInReload = self.m_fIsAkimbo = false;
        self.LoadSprites( m_pPlayer, self.GetClassname() );

        BaseClass.Holster( skiplocal );
    }
};

}
