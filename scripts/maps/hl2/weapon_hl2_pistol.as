/* USP Pistol - weapon_hl2_pistol
    Primary fire: Semi-auto fire
    Secondary fire: 3-shot burst, no trigger reset
*/
#include "weapon_base"

namespace HL2_WEAPONS
{

enum ANIM_PISTOL
{
    IDLE,
    FIDGET,
    FIDGET2,
    DRAW,
    FIRE1,
    FIRE2,
    FIRE3,
    FIRE4,
    FIRELAST,
    RELOAD,
    RELOAD_EMPTY,
    EMPTY_IDLE,
    EMPTY_DRAW,
    EMPTY_HOLSTER,
    HOLSTER
};

const array<float> FL_ANIMTIME_PISTOL =
{
    3.37f,
    3.7f,
    3.03f,
    0.7f,
    0.67f,
    0.67f,
    0.67f,
    0.67f,
    0.67f,
    1.47f,
    1.47f,
    3.37f,
    0.7f,
    0.37f,
    0.37f
};

array<string>
    STR_PISTOL_MODELS =
    {
        "models/hl2/w_usp.mdl",
        "models/hl2/p_usp.mdl",
        "models/hl2/v_usp.mdl",
        "sprites/hl2/weapon_hl2_pistol.spr",
        "sprites/hl2/pistol_muzzleflash.spr"
    },
    STR_PISTOL_SOUNDS =
    {
        "hl2/pistol_shoot.ogg",
        "hl2/pistol_reload1.ogg"
    };

array<int> I_STATS_PISTOL =
{
    1,//iSlot,
    5,//iPosition,
    300,//iMaxAmmo1,
    -1,//iMaxAmmo2,
    18,//iMaxClip,
    int( g_EngineFuncs.CVarGetFloat( "sk_9mm_bullet" ) )
};

const string strWeapon_Pistol = "weapon_hl2_pistol";

bool RegisterPistol()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_Pistol, strWeapon_Pistol );
	g_ItemRegistry.RegisterWeapon( strWeapon_Pistol, "hl2", "9mm" );

    return g_CustomEntityFuncs.IsCustomEntity( strWeapon_Pistol );
}

final class weapon_hl2_pistol : CustomGunBase
{
    private CScheduledFunction@ fnBurst;

    weapon_hl2_pistol()
    {
        strSpriteDir = "hl2";
        M_I_STATS = I_STATS_PISTOL;
    }

    void Precache()
    {
        PrecacheContent( STR_PISTOL_MODELS, STR_PISTOL_SOUNDS, { "events/muzzle_hl2_pistol.txt" } );
        BaseClass.Precache();
    }

    void Spawn()
    {
        SpawnWeapon( "models/hl2/w_usp.mdl", M_I_STATS[WpnStatIdx::iMaxClip] * 3 );
    }

    bool Deploy()
    {
        const ANIM_PISTOL AnimDeploy = self.m_iClip < 1 ? ANIM_PISTOL::EMPTY_DRAW : ANIM_PISTOL::DRAW;
        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( "models/hl2/v_usp.mdl" ), self.GetP_Model( "models/hl2/p_usp.mdl" ), AnimDeploy, "onehanded" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_PISTOL[AnimDeploy];

        return blDeployed;
    }

    void Idle()
	{
		ANIM_PISTOL AnimIdle = self.m_iClip < 1 ? ANIM_PISTOL::EMPTY_IDLE : ANIM_PISTOL::IDLE;
		
        if( AnimIdle == ANIM_PISTOL::IDLE )
        {
            const float fl = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.0f, 1.0f );

            if( fl <= 0.2f )
                AnimIdle = ANIM_PISTOL::FIDGET2;
            else if( fl <= 0.3f )
                AnimIdle = ANIM_PISTOL::FIDGET;
        }
        
        self.SendWeaponAnim( AnimIdle );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_PISTOL[AnimIdle];
	}

    bool PreShoot()
    {
        const ANIM_PISTOL AnimShoot = ANIM_PISTOL( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, int( ANIM_PISTOL::FIRE1 ), int( ANIM_PISTOL::FIRE4 ) ) );
        self.SendWeaponAnim( self.m_iClip == 1 ? ANIM_PISTOL::FIRELAST : AnimShoot );

        return true;
    }

    bool PostShoot()
    {
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/pistol_shoot.ogg", 1.0, ATTN_NORM, 0, PITCH_NORM );
        MuzzleFlash( RGBA( 255, 200, 180, 8 ) ); 
        EjectCasing( 24, 7, -6 );
        Vector vecAimPunch;
        g_Utility.GetCircularGaussianSpread( vecAimPunch.x, vecAimPunch.y );

        if( vecAimPunch.x < 0.0f )
            vecAimPunch.x *= 2;

        Recoil( vecAimPunch );

        return true;
    }

    void Burst(int iShots)
    {
        if( self.m_flNextBurstRound <= 0.0f )
            return;

        if( iShots < 1 )
        {
            self.m_flNextBurstRound = -1.0f;
            return;
        }

        Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES ), self.BulletAccuracy( VECTOR_CONE_8DEGREES, VECTOR_CONE_4DEGREES, VECTOR_CONE_3DEGREES ), BULLET_PLAYER_9MM );
        @fnBurst = g_Scheduler.SetTimeout( this, "Burst", self.m_flNextBurstRound, --iShots );
    }

    void PrimaryAttack()
    {
        if( self.m_iClip < 1 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;

			return;
		}
        // Can't shoot full auto;
        if( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 )
        {
            self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_PISTOL[ANIM_PISTOL::FIRE1];
            return;
        }

        Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES ), self.BulletAccuracy( VECTOR_CONE_8DEGREES, VECTOR_CONE_4DEGREES, VECTOR_CONE_3DEGREES ), BULLET_PLAYER_9MM );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_PISTOL[ANIM_PISTOL::FIRE1];

        if( self.m_flNextPrimaryAttack < g_Engine.time )
            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.1f;
    }

    void SecondaryAttack()
    {
        if( self.m_iClip < 1 )
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = g_Engine.time + 0.15f;

			return;
		}

        if( self.m_iClip == 1 )
            Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES ), self.BulletAccuracy( VECTOR_CONE_8DEGREES, VECTOR_CONE_4DEGREES, VECTOR_CONE_3DEGREES ), BULLET_PLAYER_9MM );
        else
        {
            self.m_flNextBurstRound = 0.066f;
            Burst( self.m_iClip > 3 ? 3 : self.m_iClip );
        }

        if( self.m_flNextSecondaryAttack < g_Engine.time )
            self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.6f;// duration of burst
    }

    void Reload()
    {
        if( self.m_iClip < self.iMaxClip() )
            BaseClass.Reload();

        const ANIM_PISTOL AnimReload = self.m_iClip < 1 ? ANIM_PISTOL::RELOAD_EMPTY : ANIM_PISTOL::RELOAD;
        
        if( self.DefaultReload( self.iMaxClip(), AnimReload, FL_ANIMTIME_PISTOL[AnimReload], 0 ) )
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "hl2/pistol_reload1.ogg", 1.0, ATTN_NORM, 0, PITCH_NORM );
    }

    void Holster(int skiplocal)
	{
		self.m_fInReload = false;
		BaseClass.Holster( skiplocal );
	}
};

}
