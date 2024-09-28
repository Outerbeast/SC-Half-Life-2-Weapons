/* Combine Overwatch Sniper Rifle - weapon_hl2_sniperrifle
    Primary fire: primes a shot with a laser to take aim, release to shoot.
    Secondary fire: Aim down sights
    Reload: Cancel a primed shot
    Ammo: ammo_hl2_sniperrifle, 1 in clip, 9 reserve

Part of the SC Half-Life 2 Weapons Pack.
- Outerbeast
*/
#include "weapon_base"

namespace HL2_WEAPONS
{

enum ANIM_SRIFLE
{
    DRAW,
    IDLE,
    FIRE,
    RELOAD,
    HOLSTER
};

const array<float> FL_ANIMTIME_SRIFLE =
{
    0.84f,
    3.05f,// long ass duration!!
    1.3f,
    3.28f,
    0.84f,
};

array<int> I_STATS_SRIFLE =
{
    3,//iSlot,
    8,//iPosition,
    10,//iMaxAmmo1,
    -1,//iMaxAmmo2,
    1//iMaxClip,
};

array<string>
    STR_SRIFLE_MODELS =
    {
        "models/hl2/p_combinesniper.mdl",
        "models/hl2/v_combinesniper.mdl",
        "models/hl2/w_combinesniper.mdl",
        "models/hl2/scope_combinesniper.mdl",
        "models/hl2/w_combinesniper_clip.mdl",
        "sprites/hl2/weapon_hl2_sniperrifle.spr",
        "sprites/laserbeam.spr"
    },
    STR_SRIFLE_SOUNDS =
    {
        "hl2/sniperfire1.ogg",
        "hl2/sniperreload1.ogg",
        "hl2/sniperreload2.ogg",
        "hl2/sniper_zoom.ogg",
        "hl2/sniperdot.ogg"
    };

const string 
    strWeapon_SniperRifle = "weapon_hl2_sniperrifle",
    strAmmo_SniperRifle = "ammo_hl2_sniperrifle";

bool RegisterSniperRifle()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_SniperRifle, strWeapon_SniperRifle );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strAmmo_SniperRifle, strAmmo_SniperRifle );
	g_ItemRegistry.RegisterWeapon( strWeapon_SniperRifle, "hl2", strAmmo_SniperRifle );

    return g_CustomEntityFuncs.IsCustomEntity( strWeapon_SniperRifle );
}

final class weapon_hl2_sniperrifle : CustomGunBase
{
    private bool blShotPrimed;
    private EHandle hAimLaser;

    CBeam@ m_pAimLaser
    {
        get { return cast<CBeam@>( hAimLaser.GetEntity() ); }
        set { hAimLaser = EHandle( @value ); }
    }

    weapon_hl2_sniperrifle()
    {
        strSpriteDir = "hl2";
        M_I_STATS = I_STATS_SRIFLE;
    }

    void Precache()
    {
        PrecacheContent( STR_SRIFLE_MODELS, STR_SRIFLE_SOUNDS, { "events/muzzle_combinesniper.txt" } );
        BaseClass.Precache();
    }

    void Spawn()
    {
        SpawnWeapon( "models/hl2/w_combinesniper.mdl", M_I_STATS[WpnStatIdx::iMaxClip] * 20 );
        BaseClass.Spawn();
    }

    bool Deploy()
    {
        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( "models/hl2/v_combinesniper.mdl" ), self.GetP_Model( "models/hl2/p_combinesniper.mdl" ), ANIM_SRIFLE::DRAW, "sniper" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_SRIFLE[ANIM_SRIFLE::DRAW];
        blShotPrimed = false;

        if( m_pAimLaser is null )
            CreateAimLaser();

        return blDeployed;
    }

    void Idle()
    {
        self.SendWeaponAnim( ANIM_SRIFLE::IDLE );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_SRIFLE[ANIM_SRIFLE::IDLE];
    }

    bool CreateAimLaser()
    {
        @m_pAimLaser = g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 4 );
        m_pAimLaser.SetType( BEAM_ENTPOINT );
        m_pAimLaser.PointEntInit( AimPos(), m_pPlayer );
		m_pAimLaser.SetEndAttachment( 1 );
        m_pAimLaser.SetColor( 83, 170, 213 );
        m_pAimLaser.SetNoise( 0 );
        m_pAimLaser.pev.effects |= EF_NODRAW;

        return m_pAimLaser !is null;
    }

    bool PreShoot()
    {
        Cancel();
        self.SendWeaponAnim( ANIM_SRIFLE::FIRE );

        return true;
    }

    bool PostShoot()
    {
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/sniperfire1.ogg", 1.0f, ATTN_NORM, 0, PITCH_NORM );
        MuzzleFlash( RGBA( 50, 128, 255, 8 ) );
        DrawColourTracer( m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES ), 3 );
        Recoil( Vector( -5, 0, 0 ) );
        
        if( self.m_fInZoom )
            HipFire();

        return true;
    }

    bool PrimeShot()
    {
        m_pPlayer.SetMaxSpeedOverride( int( m_pPlayer.GetMaxSpeed() * 0.33f ) );
        m_pAimLaser.pev.effects &= ~EF_NODRAW;
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/sniperdot.ogg", 1.0f, ATTN_NORM, 0, PITCH_NORM );

        return m_pAimLaser.pev.effects & EF_NODRAW == 0;
    }

    void Cancel()
    {
        m_pPlayer.SetMaxSpeedOverride( -1 );
        m_pAimLaser.pev.effects |= EF_NODRAW;
        blShotPrimed = false;
    }

    void AimDownSights(const int iZoomFov)
    {
        if( self.m_fInReload )
            return;

        CustomGunBase::AimDownSights( iZoomFov );

        m_pPlayer.set_m_szAnimExtension( "sniperscope" );
        m_pPlayer.pev.viewmodel = "models/hl2/scope_combinesniper.mdl";
        g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl2/sniper_zoom.ogg", 0.7f, ATTN_NORM, 0, PITCH_NORM );
        g_PlayerFuncs.ConcussionEffect( m_pPlayer, 1.0f, 1.0f, 0.05f );// Add zoom drift
        //m_pPlayer.m_iHideHUD |= HIDEHUD_CROSSHAIR;
    }

    void HipFire()
    {
        CustomGunBase::HipFire();
        
        m_pPlayer.set_m_szAnimExtension( "sniper" );
        m_pPlayer.pev.viewmodel = self.GetV_Model( "models/hl2/v_combinesniper.mdl" );
        g_PlayerFuncs.ConcussionEffect( m_pPlayer, 0.0f, 0.0f, 0.0f );// remove zoom drift
        //m_pPlayer.m_iHideHUD &= ~HIDEHUD_CROSSHAIR;
    }

    void ItemPostFrame()
    {   
        if( m_pAimLaser !is null )
            m_pAimLaser.SetStartPos( AimPos() );
        // cancel the shot
        if( blShotPrimed && m_pPlayer.m_afButtonPressed & IN_RELOAD != 0 )
        {
            Cancel();

            if( self.m_flNextPrimaryAttack < g_Engine.time )
                self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;

            self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
        }

        if( blShotPrimed && m_pPlayer.m_afButtonReleased & IN_ATTACK != 0 )
        {
            if( self.m_fInZoom )
                Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES ), VECTOR_CONE_1DEGREES, BULLET_PLAYER_SNIPER );
            else// Hip fire is much less accurate.
                Shoot( 1, m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ), VECTOR_CONE_4DEGREES, BULLET_PLAYER_SNIPER );

            if( self.m_flNextPrimaryAttack < g_Engine.time )
                self.m_flNextPrimaryAttack = g_Engine.time + FL_ANIMTIME_SRIFLE[ANIM_SRIFLE::FIRE];

            self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_SRIFLE[ANIM_SRIFLE::FIRE];
        }

        BaseClass.ItemPostFrame();
    }

    void PrimaryAttack()
    {
        if( self.m_iClip < 1 )
        {
            self.Reload();
            return;
        }

        if( !blShotPrimed )
        {
            blShotPrimed = PrimeShot();
            self.m_flNextPrimaryAttack = 0.0f;
        }
    }

    void SecondaryAttack()
    {
        if( self.m_fInReload )
            return;

        if( !self.m_fInZoom )
            AimDownSights( 15 );
        else
            HipFire();

        self.m_flNextSecondaryAttack = g_Engine.time + 1.0f;
    }

    void Reload()
    {
        if( self.m_flNextPrimaryAttack > g_Engine.time )// Stop manual reloads
            return;

        if( self.m_iClip < 1 )
            BaseClass.Reload();

        if( self.DefaultReload( 1, ANIM_SRIFLE::RELOAD, FL_ANIMTIME_SRIFLE[ANIM_SRIFLE::RELOAD], 0 ) )
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "hl2/sniperreload1.ogg", 0.7f, ATTN_NORM, 0, PITCH_NORM );
    }
    
    void Holster(int skiplocal = 0)
    {
        CustomGunBase::Holster( skiplocal );
        g_EntityFuncs.Remove( m_pAimLaser );
    }
};

final class ammo_hl2_sniperrifle : CustomAmmoBase
{
    ammo_hl2_sniperrifle()
    {
        strModel = "models/hl2/w_combinesniper_clip.mdl";
        strPickupSound = "items/9mmclip1.wav";
        iClipSize = 1;
        iMax = I_STATS_SRIFLE[WpnStatIdx::iMaxAmmo1];
    }
};

}
