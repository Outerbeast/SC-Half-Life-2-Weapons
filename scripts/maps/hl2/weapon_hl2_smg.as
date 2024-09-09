/* MP7 Submachine Gun - weapon_hl2_smg
    Primary fire: Full auto fire at 770rpm
    Secondary fire: Aim down sights - "as_command hl2_mp7_glmode 1" in cfg enables the original grenade launcher mode
    Ammo: uses stock 9mm ammo, 45 in clip, 330 in reserve

Part of the SC Half-Life 2 Weapons Pack.
- Outerbeast
*/
#include "weapon_base"

namespace HL2_WEAPONS
{

enum ANIM_SMG
{
	IDLE,
	LAUNCH_GL,
	RELOAD,
	DRAW,
	SHOOT1,
	SHOOT2,
	SHOOT3,
    ADS_TO,
    ADS_IDLE,
    ADS_FROM,
    ADS_SHOOT1,
    ADS_SHOOT2,
    ADS_SHOOT3
};

const array<float> FL_ANIMTIME_SMG =
{
    0.07f,
    1.05f,
    1.6f,
    0.87f,
    0.7f,
    0.7f,
    0.7f,
    0.33f,
    1.0f,
    0.33f,
    0.7f,
    0.7f,
    0.7f
};

array<int> I_STATS_SMG =
{
    2,//iSlot,
    4,//iPosition,
    300,//iMaxAmmo1,
    5,//iMaxAmmo2,
    45,//iMaxClip,
    int( g_EngineFuncs.CVarGetFloat( "sk_9mm_bullet" ) )
};

array<string>
    STR_SMG_MODELS =
    {
        "models/hl2/p_mp7.mdl",
        "models/hl2/v_mp7.mdl",
        "models/hl2/w_mp7.mdl",
        "sprites/hl2/weapon_hl2_smg.spr",
        "sprites/hl2/smg_muzzleflash.spr"
    },
    STR_SMG_SOUNDS =
    {
        "hl2/mp7_shoot1.ogg",
        "hl2/mp7_shoot2.ogg",
        "hl2/mp7_shoot3.ogg",
        "hl2/mp7_reload.ogg",
        "hl2/mp7_altfire.ogg"
    };

CCVar cvarMP7GL( "hl2_mp7_glmode", 0, "MP7 grenade mode" );
const string strWeapon_SMG = "weapon_hl2_smg";

bool RegisterSMG()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_SMG, strWeapon_SMG );

    if( cvarMP7GL.GetInt() < 1 )
        I_STATS_SMG[WpnStatIdx::iMaxAmmo2] = -1;

	g_ItemRegistry.RegisterWeapon( strWeapon_SMG, "hl2", "9mm", ( I_STATS_SMG[WpnStatIdx::iMaxAmmo2] > 0 ? "ARgrenades" : "" ) );
    g_Game.PrecacheOther( strWeapon_SMG );

    return g_CustomEntityFuncs.IsCustomEntity( strWeapon_SMG );
}

final class weapon_hl2_smg : CustomGunBase
{
    weapon_hl2_smg()
    {
        strSpriteDir = "hl2";
        M_I_STATS = I_STATS_SMG;
    }

    void Precache()
    {
        PrecacheContent( STR_SMG_MODELS, STR_SMG_SOUNDS, { "events/muzzle_hl2_smg.txt" } );
        BaseClass.Precache();
    }

    void Spawn()
    {
        SpawnWeapon( self.GetW_Model( "models/hl2/w_mp7.mdl" ), M_I_STATS[WpnStatIdx::iMaxClip] * 3 );
        BaseClass.Spawn();
    }

    bool Deploy()
    {
        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( "models/hl2/v_mp7.mdl" ), self.GetP_Model( "models/hl2/p_mp7.mdl" ), ANIM_SMG::DRAW, "onehanded" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_SMG[ANIM_SMG::DRAW];

        return blDeployed;
    }

    void Idle()
    {
        self.SendWeaponAnim( self.m_fInZoom ? ANIM_SMG::ADS_IDLE : ANIM_SMG::IDLE );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_SMG[self.m_fInZoom ? ANIM_SMG::ADS_IDLE : ANIM_SMG::IDLE];
    }

    bool PreShoot()
    {
        ANIM_SMG AnimShoot = self.m_fInZoom ?
            ANIM_SMG( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, int( ANIM_SMG::ADS_SHOOT1 ), int( ANIM_SMG::ADS_SHOOT3 ) ) ) :
            ANIM_SMG( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, int( ANIM_SMG::SHOOT1 ), int( ANIM_SMG::SHOOT3 ) ) ) ;

        self.SendWeaponAnim( AnimShoot );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_SMG[AnimShoot];

        return true;
    }

    bool PostShoot()
    {
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/mp7_shoot" + Math.RandomLong( 1, 3 ) + ".ogg", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
        MuzzleFlash( RGBA( 255, 200, 180, 8 ) ); 
        EjectCasing( 24.0f, 16.0f, -15.0f );

        Vector vecAimPunch;
        g_Utility.GetCircularGaussianSpread( vecAimPunch.x, vecAimPunch.y );
        
        if( vecAimPunch.x < 0.0f )
            vecAimPunch.x *= 2;

        Recoil( vecAimPunch, log10( m_iShotsFired ) + 1 );

        return true;
    }

    void AimDownSights(const int iZoomFov)
    {
        self.SendWeaponAnim( ANIM_SMG::ADS_TO );
        //m_pPlayer.m_iHideHUD |= HIDEHUD_CROSSHAIR;
        CustomGunBase::AimDownSights( iZoomFov );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + FL_ANIMTIME_SMG[ANIM_SMG::ADS_TO];
    }

    void HipFire()
    {
        self.SendWeaponAnim( ANIM_SMG::ADS_FROM );
        //m_pPlayer.m_iHideHUD &= ~HIDEHUD_CROSSHAIR;
        CustomGunBase::HipFire();
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + FL_ANIMTIME_SMG[ANIM_SMG::ADS_FROM];
    }

    void PrimaryAttack()
    {
        if( ShootingNotAllowed() )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;

            return;
        }

        if( self.m_fInZoom )
            Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES ), self.BulletAccuracy( VECTOR_CONE_4DEGREES, VECTOR_CONE_2DEGREES, VECTOR_CONE_1DEGREES ), BULLET_PLAYER_9MM );
        else
            Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ), self.BulletAccuracy( VECTOR_CONE_6DEGREES, VECTOR_CONE_6DEGREES, VECTOR_CONE_4DEGREES ), BULLET_PLAYER_9MM );

        if( self.m_flNextPrimaryAttack < g_Engine.time )
            self.m_flNextPrimaryAttack = g_Engine.time + 0.077f;
    }

    void SecondaryAttack()
    {
        if( self.m_fInReload )
            return;

        if( self.iMaxAmmo2() < 0 )
        {
            if( !self.m_fInZoom )
                AimDownSights( 40 );
            else
                HipFire();

            self.m_flNextSecondaryAttack = g_Engine.time + 1.0f;
        }
        else
        {
            if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) < 1 )
            {
                self.PlayEmptySound();
                self.m_flNextSecondaryAttack = g_Engine.time + 0.15f;

                return;
            }

            if( LaunchGrenade( ANIM_SMG::LAUNCH_GL ) !is null )
            {
                g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/mp7_altfire.ogg", 0.9f, ATTN_NORM, 0, PITCH_NORM );
                Recoil( Vector( -10, 0, 0 ) );
                self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_SMG[ANIM_SMG::LAUNCH_GL] * 2;

                if( DeductSecondaryAmmo() < 1 )
                    m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
            }
        }
    }

    void Reload()
	{
        if( self.pev.nextthink > g_Engine.time )
            return;

        if( self.m_fInZoom )
        {
            HipFire();
            SetThink( ThinkFunction( this.Reload ) );
            self.pev.nextthink = g_Engine.time + FL_ANIMTIME_SMG[ANIM_SMG::ADS_FROM];

            return;
        }

        if( self.m_iClip < self.iMaxClip() )
            BaseClass.Reload();

		if( self.DefaultReload( self.iMaxClip(), ANIM_SMG::RELOAD, FL_ANIMTIME_SMG[ANIM_SMG::RELOAD], 0 ) )
        {
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "hl2/mp7_reload.ogg", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
            SetThink( null );
            self.pev.nextthink = 0.0f;
        }
	}
};

}
