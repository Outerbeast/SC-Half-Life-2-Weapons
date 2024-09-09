/* Colt Python 357 Revolver - weapon_hl2_revolver
    Primary fire: fires single shot
    Secondary fire: Aim down sights
    Ammo: stock ammo_357, 6 in clip, 12 reserve

Part of the SC Half-Life 2 Weapons Pack.
- Outerbeast
*/
#include "weapon_base"

namespace HL2_WEAPONS
{

enum ANIM_REVOLVER
{
    IDLE,
    FIRE,
    RELOAD,
    DRAW,
    ADS_TO,
    ADS_IDLE,
    ADS_FROM,
    ADS_FIRE,
    HOLSTER
};

const array<float> FL_ANIMTIME_REVOLVER =
{
    4.07f,
    0.87f,
    2.6f,
    1.07f,
    0.34f,
    1.0f,
    0.34f,
    0.87f,
    0.4f
};

array<int> I_STATS_REVOLVER =
{
    1,
    7,
    12,
    -1,
    6
};

array<string>
    STR_REVOLVER_MODELS =
    {
        "models/hl2/w_357.mdl",
        "models/hl2/p_357.mdl",
        "models/hl2/v_357.mdl",
        "sprites/hl2/weapon_hl2_revolver.spr"
    },
    STR_REVOLVER_SOUNDS =
    {
        "hl2/357_shot1.ogg",
        "hl2/357_shot2.ogg",
        "hl2/357_reload1.ogg",
        "hl2/357_reload3.ogg",
        "hl2/357_reload4.ogg",
        "hl2/357_spin1.ogg"
    };

const string strWeapon_Revolver = "weapon_hl2_revolver";

bool RegisterRevolver()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_Revolver, strWeapon_Revolver );
    g_ItemRegistry.RegisterWeapon( strWeapon_Revolver, "hl2", "357" );

    return g_CustomEntityFuncs.IsCustomEntity( strWeapon_Revolver );
}

final class weapon_hl2_revolver : CustomGunBase
{
    private CScheduledFunction@ fnEjectCasings;
    
    weapon_hl2_revolver()
    {
        strSpriteDir = "hl2";
        M_I_STATS = I_STATS_REVOLVER;
    }

    void Precache()
    {
        PrecacheContent( STR_REVOLVER_MODELS, STR_REVOLVER_SOUNDS );
        BaseClass.Precache();
    }

    void Spawn()
    {
        SpawnWeapon( "models/hl2/w_357.mdl", M_I_STATS[WpnStatIdx::iMaxClip] );
        BaseClass.Spawn();
    }

    bool Deploy()
    {
        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( "models/hl2/v_357.mdl" ), self.GetP_Model( "models/hl2/p_357.mdl" ), ANIM_REVOLVER::DRAW, "python" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_REVOLVER[ANIM_REVOLVER::DRAW];

        return blDeployed;
    }

    void Idle()
    {
        const ANIM_REVOLVER AnimIdle = self.m_fInZoom ? ANIM_REVOLVER::ADS_IDLE : ANIM_REVOLVER::IDLE;
        self.SendWeaponAnim( AnimIdle );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_REVOLVER[AnimIdle];
    }

    bool PreShoot()
    {
        self.SendWeaponAnim( self.m_fInZoom ? ANIM_REVOLVER::ADS_FIRE : ANIM_REVOLVER::FIRE );
        return true;
    }

    bool PostShoot()
    {
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/357_shot1.ogg", 1.0, ATTN_NORM, 0, PITCH_NORM );
        MuzzleFlash( RGBA( 255, 200, 180, 8 ) ); 
        Recoil( Vector( -10, 0, 0 ) );

        return true;
    }

    void AimDownSights(const int iZoomFov)
    {
        self.SendWeaponAnim( ANIM_REVOLVER::ADS_TO );
        //m_pPlayer.m_iHideHUD |= HIDEHUD_CROSSHAIR;
        CustomGunBase::AimDownSights( iZoomFov );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_REVOLVER[ANIM_REVOLVER::ADS_TO];
    }

    void HipFire()
    {
        self.SendWeaponAnim( ANIM_REVOLVER::ADS_FROM );
        //m_pPlayer.m_iHideHUD &= ~HIDEHUD_CROSSHAIR;
        CustomGunBase::HipFire();
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_REVOLVER[ANIM_REVOLVER::ADS_FROM];
    }

    void DropCasings()
    {
        for( int i = 6; i > 0; i-- )
        {   // Credit: KernCore, https://github.com/KernCore91/-SC-Cry-of-Fear-Weapons-Project/blob/master/scripts/maps/cof/pistols/weapon_cofrevolver.as#L367
            const Vector vecVelocity = m_pPlayer.pev.view_ofs + g_Engine.v_right * Math.RandomLong( -16, 16 ) + g_Engine.v_up * Math.RandomLong( 16, 32 ) + g_Engine.v_forward * Math.RandomLong( -36, -28 );
            g_EntityFuncs.EjectBrass( m_pPlayer.pev.origin, vecVelocity, 0.0f, m_iShell, TE_BOUNCE_SHELL );
        }
    }

    void PrimaryAttack()
    {
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip < 1 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;

            return;
        }

        if( self.m_fInZoom )
            Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES ), self.BulletAccuracy( VECTOR_CONE_3DEGREES, VECTOR_CONE_1DEGREES, VECTOR_CONE_1DEGREES ), BULLET_PLAYER_357 );
        else
            Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ), self.BulletAccuracy( VECTOR_CONE_6DEGREES, VECTOR_CONE_4DEGREES, VECTOR_CONE_2DEGREES ), BULLET_PLAYER_357 );

        self.m_flNextPrimaryAttack = g_Engine.time + FL_ANIMTIME_REVOLVER[ANIM_REVOLVER::FIRE];
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
        if( self.pev.nextthink > g_Engine.time )
            return;

        if( self.m_fInZoom )
        {
            HipFire();
            SetThink( ThinkFunction( this.Reload ) );
            self.pev.nextthink = g_Engine.time + FL_ANIMTIME_REVOLVER[ANIM_REVOLVER::ADS_FROM];

            return;
        }

        if( self.m_iClip < self.iMaxClip() )
            BaseClass.Reload();
        
        if( self.DefaultReload( self.iMaxClip(), ANIM_REVOLVER::RELOAD, FL_ANIMTIME_REVOLVER[ANIM_REVOLVER::RELOAD], 0 ) )
        {
            @fnEjectCasings = g_Scheduler.SetTimeout( this, "DropCasings", 1.3f );
            SetThink( null );
            self.pev.nextthink = 0.0f;
        }
    }

    void Holster(int skiplocal = 0)
    {
        g_Scheduler.RemoveTimer( fnEjectCasings );
        CustomGunBase::Holster( skiplocal );
    }
};

}