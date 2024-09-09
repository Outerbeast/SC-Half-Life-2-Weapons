/* OICW Assault Rifle - weapon_hl2_oicw
    Primary fire: 3 round burst
    Secondary fire: Aim down sights, single fire
    Tertiary fire: Toggles grenade launcher mode (if grenades are available)
    Primary ammo: stock ammo_556clip, 30 in clip, 150 reserve
    Secondary ammo: ammo_hl2_oicw_grenade (1), ammo_hl2_oicw_grenadeclip (6), 6 total

Part of the SC Half-Life 2 Weapons Pack.
- Outerbeast
*/
#include "weapon_base"

namespace HL2_WEAPONS
{

enum ANIM_OICW
{
    DRAW,
    HOLSTER,
    IDLE,
    FIDGET,
    SHOOT1,
    SHOOT2,
    RELOAD,
    LAUNCH_GL,
    RELOAD_GL,
    RELOAD_EMPTY,
};

const array<float> FL_ANIMTIME_OICW =
{
    0.88f,
    0.27f,
    3.41f,
    3.33f,
    0.31f,
    0.38f,
    2.71f,
    1.07f,
    3.0f,
    3.9f,
};

array<int> I_STATS_OICW =
{
    2,// iSlot,
    7,// iPosition,
    150,// iMaxAmmo1,
    12,// iMaxAmmo2,
    30,// iMaxClip,
    int( g_EngineFuncs.CVarGetFloat( "sk_556_bullet" ) ),// iDamage1
    60 // iDamage2
};

array<string>
    STR_OICW_MODELS =
    {
        "models/hl2/p_oicw.mdl",
        "models/hl2/v_oicw.mdl",
        "models/hl2/w_oicw.mdl",
        "models/hl2/scope_oicw.mdl",
        "models/hl2/grenade_20mm.mdl",
        "models/hl2/shell_20mm.mdl",
        "sprites/hl2/weapon_hl2_oicw.spr",
        "sprites/glow02.spr"
    },
    STR_OICW_SOUNDS =
    {
        "hl2/oicw_altfire.ogg",
        "hl2/oicw_draw.ogg",
        "hl2/oicw_fire.ogg",
        "hl2/oicw_glreload1.ogg",
        "hl2/oicw_glreload2.ogg",
        "hl2/oicw_glreload3.ogg",
        "hl2/oicw_pc1.ogg",
        "hl2/oicw_pc2.ogg",
        "hl2/oicw_pc3.ogg",
        "hl2/oicw_reload1.ogg",
        "hl2/oicw_reload2.ogg",
        "hl2/oicw_reload3.ogg"
    };

const float flOICWGrenadeSpeed = 1000.0f;

const string
    strWeapon_OICW = "weapon_hl2_oicw",
    strAmmo_OICW_2  = "ammo_hl2_oicw_grenade";

bool RegisterOICW()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_OICW, strWeapon_OICW );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strAmmo_OICW_2, strAmmo_OICW_2 );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strAmmo_OICW_2 + "clip", strAmmo_OICW_2 + "clip" );
    g_ItemRegistry.RegisterWeapon( strWeapon_OICW, "hl2", "556", strAmmo_OICW_2, "", "HL2_WEAPONS::" + strAmmo_OICW_2 );

    g_Game.PrecacheOther( strWeapon_OICW );
    g_Game.PrecacheOther( strAmmo_OICW_2 );
    g_Game.PrecacheOther( strAmmo_OICW_2 + "clip" );

    return g_CustomEntityFuncs.IsCustomEntity( "weapon_hl2_oicw" );
}

final class weapon_hl2_oicw : CustomGunBase
{
    private bool blGLMode;
    private EHandle hLaserDot, hGrenade;
    private CScheduledFunction@ fnBurst;
    private HUDTextParams txtRangeInfo;
    private int iShellGrenade = g_Game.PrecacheModel( "models/hl2/shell_20mm.mdl" );

    weapon_hl2_oicw()
    {
        strSpriteDir = "hl2";
        M_I_STATS = I_STATS_OICW;
        m_iShell = g_Game.PrecacheModel( "models/saw_shell.mdl" );

        txtRangeInfo.x = 0.53f;
        txtRangeInfo.y = 0.59f;
        
        txtRangeInfo.r1 = 0;
        txtRangeInfo.g1 = 255;
        txtRangeInfo.b1 = 0;
        txtRangeInfo.a1 = 255;

        txtRangeInfo.r2 = 0;
        txtRangeInfo.g2 = 255;
        txtRangeInfo.b2 = 0;
        txtRangeInfo.a2 = 255;

        txtRangeInfo.fadeinTime = 0.0f;
        txtRangeInfo.fadeoutTime = 0.0f;
        txtRangeInfo.holdTime = 10.0f;
        txtRangeInfo.fxTime = 0.0f;
    }

    void Precache()
    {
        PrecacheContent( STR_OICW_MODELS, STR_OICW_SOUNDS, { "events/muzzle_hl2_oicw.txt" } );
        BaseClass.Precache();
    }

    void Spawn()
    {
        SpawnWeapon( "models/hl2/w_oicw.mdl", M_I_STATS[iMaxClip] * 2 );
        self.m_iClip2 = 0;
        BaseClass.Spawn();
    }

    bool Deploy()
    {
        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( "models/hl2/v_oicw.mdl" ), self.GetP_Model( "models/hl2/p_oicw.mdl" ), ANIM_OICW::DRAW, "m16" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_OICW[ANIM_OICW::DRAW];

        if( !hLaserDot )
        {
            hLaserDot = g_EntityFuncs.Create( "desert_eagle_spot", AimPos(), g_vecZero, false );
            g_EntityFuncs.SetModel( hLaserDot.GetEntity(), "sprites/glow02.spr" );
            hLaserDot.GetEntity().pev.scale /= 2;
            hLaserDot.GetEntity().pev.rendercolor = Vector( 0, 255, 0 );
            hLaserDot.GetEntity().pev.effects |= EF_NODRAW;
        }

        blGLMode = false;

        return blDeployed;
    }

    void Idle()
    {
        const int AnimIdle = g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, ANIM_OICW::IDLE, ANIM_OICW::FIDGET );
        self.SendWeaponAnim( AnimIdle );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_OICW[AnimIdle];
    }

    bool PreShoot()
    {
        self.SendWeaponAnim( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, ANIM_OICW::SHOOT1, ANIM_OICW::SHOOT2 ) );
        return true;
    }

    bool PostShoot()
    {
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/oicw_fire.ogg", 0.5, ATTN_NORM, 0, PITCH_NORM );
        MuzzleFlash( RGBA( 255, 200, 180, 8 ) ); 
        EjectCasing( 26.0f, 16.0f, -15.0f );
        Recoil( Vector( 1.0f, 0.5f, 0.0f ), float( Math.RandomLong( -2, -1 ) ) );

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

        Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ), self.BulletAccuracy( VECTOR_CONE_4DEGREES, VECTOR_CONE_3DEGREES, VECTOR_CONE_2DEGREES ), BULLET_PLAYER_SAW );
        @fnBurst = g_Scheduler.SetTimeout( this, "Burst", self.m_flNextBurstRound, --iShots );
    }

    bool ShootGrenade()
    {
        if( self.m_iClip2 < 1 )
        {
            self.PlayEmptySound();

            if( m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) > 0 )
                ReloadGL();
            
            return false;
        }

        hGrenade = LaunchGrenade( ANIM_OICW::LAUNCH_GL, I_STATS_OICW[WpnStatIdx::iDamage2], flOICWGrenadeSpeed, 0.05f, "models/hl2/grenade_20mm.mdl" );

        if( hGrenade )
        {
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/oicw_altfire.ogg", 0.9f, ATTN_NORM, 0, PITCH_NORM );
            Recoil( Vector( -10, 0, 0 ) );
            EjectCasing( 26.0f, 16.0f, -15.0f, TE_BOUNCE_SHOTSHELL, iShellGrenade );

            if( --self.m_iClip2 < 1 )
                m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

            self.m_flNextPrimaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + FL_ANIMTIME_OICW[ANIM_OICW::LAUNCH_GL];
        }

        if( m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) + self.m_iClip2 < 1 )
            blGLMode = false;

        return true;
    }

    void ReloadGL()
    {
        if( self.m_fInZoom )
            HipFire();

        self.SendWeaponAnim( ANIM_OICW::RELOAD_GL );
        SetThink( ThinkFunction( this.FillGLClip ) );
        self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = self.pev.nextthink = g_Engine.time + FL_ANIMTIME_OICW[ANIM_OICW::RELOAD_GL];
    }

    void FillGLClip()
    {
        self.m_iClip2 = m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) >= 6 ? 6 : m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType );
        DeductSecondaryAmmo( self.m_iClip2 );
        self.pev.nextthink = 0.0f;
        SetThink( null );
    }

    void AimDownSights(const int iZoomFov)
    {
        if( self.m_fInReload )
            return;

        m_pPlayer.set_m_szAnimExtension( "sniperscope" );
        m_pPlayer.pev.viewmodel = "models/hl2/scope_oicw.mdl";

        if( hLaserDot )
            hLaserDot.GetEntity().pev.effects &= ~EF_NODRAW;

        CustomGunBase::AimDownSights( iZoomFov );
    }

    void HipFire()
    {
        m_pPlayer.set_m_szAnimExtension( "m16" );
        m_pPlayer.pev.viewmodel = self.GetV_Model( "models/hl2/v_oicw.mdl" );
        g_PlayerFuncs.HudMessage( m_pPlayer, txtRangeInfo, "" );

        if( hLaserDot )
            hLaserDot.GetEntity().pev.effects |= EF_NODRAW;

        CustomGunBase::HipFire();
    }

    void ItemPreFrame()
    {
        g_EntityFuncs.SetOrigin( hLaserDot.GetEntity(), AimPos() );
        // !-UNDONE-!: Print range data in scope reticle - HUDText does not obey recoil
/*         if( self.m_fInZoom && hLaserDot )
        {
            const float flRange = floor( Vector( m_pPlayer.GetGunPosition() - hLaserDot.GetEntity().pev.origin ).Length() / 40 );
            const string strRange = "" + ( flRange > 100.0f ? "+100" : flRange ) + "M\n";
            g_PlayerFuncs.HudMessage( m_pPlayer, txtRangeInfo, strRange );
        } */

        BaseClass.ItemPreFrame();
    }

    void PrimaryAttack()
    {
        if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.1f;

            return;
        }

        if( blGLMode )
        {
            ShootGrenade();
            return;
        }

        if( self.m_iClip < 1 )
        {
            self.PlayEmptySound();
            self.m_flNextPrimaryAttack = g_Engine.time + 0.1f;

            return;
        }

        if( self.m_fInZoom )
        {
            if( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 )
                return;

            Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES ), self.BulletAccuracy( VECTOR_CONE_3DEGREES, VECTOR_CONE_1DEGREES, VECTOR_CONE_1DEGREES ), BULLET_PLAYER_SAW );

            if( self.m_flNextPrimaryAttack < g_Engine.time )
                self.m_flNextPrimaryAttack = g_Engine.time + 0.1f;
        }
        else
        {
            if( self.m_iClip == 1 )
                Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES ), self.BulletAccuracy( VECTOR_CONE_4DEGREES, VECTOR_CONE_3DEGREES, VECTOR_CONE_2DEGREES ), BULLET_PLAYER_SAW );
            else
            {
                self.m_flNextBurstRound = 0.066f;// Same as M16?
                Burst( self.m_iClip > 3 ? 3 : self.m_iClip );
            }

            if( self.m_flNextPrimaryAttack < g_Engine.time )
                self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;// duration of burst
        }

        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_OICW[ANIM_OICW::SHOOT2];
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

    void TertiaryAttack()
    {
        blGLMode = !blGLMode;

        if( self.m_iClip2 + m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) < 1 )
            blGLMode = false;
        else if( self.m_iClip2 < 1 && m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) > 1 )
            ReloadGL();

        g_PlayerFuncs.ClientPrint( m_pPlayer, HUD_PRINTCENTER, "Grenade Launcher Mode: " + ( blGLMode ? "ON" : "OFF" ) );
        self.m_flNextTertiaryAttack = g_Engine.time + 1.0f;
    }

    void Reload()
    {
        if( self.m_flNextBurstRound > 0.0f )
            return;

        if( self.m_iClip < self.iMaxClip() )
            BaseClass.Reload();

        const ANIM_OICW AnimReload = self.m_iClip < 1 ? ANIM_OICW::RELOAD_EMPTY : ANIM_OICW::RELOAD;

        if( self.DefaultReload( self.iMaxClip(), AnimReload, FL_ANIMTIME_OICW[AnimReload], 0 ) && self.m_fInZoom )
            HipFire();
    }

    void Holster(int skiplocal = 0)
    {
        if( self.m_fInZoom )
            HipFire();

        if( hLaserDot )
            hLaserDot.GetEntity().pev.effects |= EF_NODRAW;

        g_Scheduler.RemoveTimer( fnBurst );

        BaseClass.Holster( skiplocal );
    }

    void RetireWeapon()
    {
        if( self.m_fInZoom )
            HipFire();

        g_Scheduler.RemoveTimer( fnBurst );
        blGLMode = false;

        BaseClass.RetireWeapon();
    }

    void UpdateOnRemove()
    {
        g_Scheduler.RemoveTimer( fnBurst );

        if( hLaserDot )
            g_EntityFuncs.Remove( hLaserDot.GetEntity() );
    }
};

final class ammo_hl2_oicw_grenade : CustomAmmoBase
{
    ammo_hl2_oicw_grenade()
    {
        strModel = "models/hl2/w_argrenade_20mm.mdl";
        iClipSize = 2;
        iMax = 6;
    }
};

final class ammo_hl2_oicw_grenadeclip : CustomAmmoBase
{
    ammo_hl2_oicw_grenadeclip()
    {
        strName = strAmmo_OICW_2;
        strModel = "models/hl2/w_argrenade_20mmclip.mdl";
        iClipSize = iMax = 6;
    }
};

}
