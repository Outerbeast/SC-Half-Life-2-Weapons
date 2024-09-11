/* Custom weapon baseclass
    Will eventually build documentation for usage. Stay tuned.
- Outerbeast
*/
enum WpnStatIdx
{
    iSlot,
    iPosition,
    iMaxAmmo1,
    iMaxAmmo2,
    iMaxClip,
    iDamage1,// Damage of Primary Fire ammo
    iDamage2,// Damage of Secondary Fire ammo, -1 if not used
    iWeight,
    iFlags
};
// Baseclasses for common weapon behaviour
abstract class CustomWeaponBase : ScriptBasePlayerWeaponEntity
{
    protected string strSpriteDir;
    protected EHandle m_hViewModel;
    protected array<int> M_I_STATS( WpnStatIdx::iFlags + 1 );
    array<Vector> M_VEC_VIEWMODELATTACHMENT_POS( 4 );

    protected CBasePlayer@ m_pPlayer
    {
        get { return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
        set { self.m_hPlayer = EHandle( @value ); }
    }

    protected void Idle() { };
    protected void ClampMaxAmmo() { };
    protected void ItemThink() { };

    bool GetItemInfo(ItemInfo& out info)
    {
        info.iSlot      = M_I_STATS[WpnStatIdx::iSlot];
        info.iPosition  = M_I_STATS[WpnStatIdx::iPosition];
        info.iMaxAmmo1  = M_I_STATS[WpnStatIdx::iMaxAmmo1];
        info.iMaxAmmo2  = M_I_STATS[WpnStatIdx::iMaxAmmo2];
        info.iMaxClip   = info.iAmmo1Drop = M_I_STATS[WpnStatIdx::iMaxClip];

        try { info.iWeight = M_I_STATS[WpnStatIdx::iWeight]; }
        catch { };

        try { info.iFlags = M_I_STATS[WpnStatIdx::iFlags]; }
        catch { };
        
        info.iId = g_ItemRegistry.GetIdForName( self.GetClassname() );
        // GetItemInfo is called every frame, use this to our advantage
        if( m_pPlayer !is null )
            ItemThink();

        return true;
    }
    // invoke in child's Precache method
    bool PrecacheContent(array<string>@ STR_MODELS, array<string>@ STR_SOUNDS, array<string>@ STR_MISC = array<string>()) final
    {
        for( uint i = 0; i < STR_MODELS.length(); i++ )
            g_Game.PrecacheModel( STR_MODELS[i] );

        for( uint i = 0; i < STR_SOUNDS.length(); i++ )
        {
            g_SoundSystem.PrecacheSound( STR_SOUNDS[i] );
            g_Game.PrecacheGeneric( "sound/" + STR_SOUNDS[i] );// Redundant after SC 5.26
        }

        if( STR_MISC.length() > 0 )
        {
            for( uint i = 0; i < STR_MISC.length(); i++ )
                g_Game.PrecacheGeneric( STR_MISC[i] );
        }

        g_Game.PrecacheGeneric( "sprites/" + ( strSpriteDir != "" ? strSpriteDir + "/" : "" ) + self.GetClassname() + ".txt" );
        self.PrecacheCustomModels();

        return true;
    }
    // Invoke in child's Spawn method
    void SpawnWeapon(const string strWorldModel, const int iDefaultAmmoAmount = 0) final
    {
        self.Precache();
        g_EntityFuncs.SetModel( self, self.GetW_Model( strWorldModel ) );
        self.FallInit();

        if( iDefaultAmmoAmount > 0 )
            self.m_iDefaultAmmo = iDefaultAmmoAmount;

        if( M_I_STATS.length() > WpnStatIdx::iDamage1 && M_I_STATS[WpnStatIdx::iDamage1] > 0 )
            self.m_flCustomDmg = M_I_STATS[WpnStatIdx::iDamage1];
        // Fixes third person animations
        if( M_I_STATS[WpnStatIdx::iMaxAmmo1] == WEAPON_NOCLIP )
            self.m_iClip = WEAPON_NOCLIP;
    }

    bool AddToPlayer(CBasePlayer@ pPlayer)
    {
        @m_pPlayer = pPlayer;

        if( BaseClass.AddToPlayer( m_pPlayer ) )
        {
            ClampMaxAmmo();
            NetworkMessage pickup( MSG_ONE, NetworkMessages::WeapPickup, m_pPlayer.edict() );
            pickup.WriteLong( self.m_iId );
            pickup.End();

            return true;
        }

        return false;
    }

    void WeaponIdle()
    {
        self.ResetEmptySound();

        if( self.m_flTimeWeaponIdle > g_Engine.time )
            return;

        Idle();
    }

    CBasePlayerItem@ DropItem()
    {
        return self;
    }
    // Exact position where the player has aimed
    Vector AimPos(const float flRange = 4096.0f) final
    {
        if( m_pPlayer is null )
            return g_vecZero;
        
        TraceResult trForward;

        const Vector
            vecStart = m_pPlayer.GetGunPosition(),
            vecEnd = vecStart + m_pPlayer.GetAutoaimVector( 0 ) * flRange;

        g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, ignore_glass, m_pPlayer.edict(), trForward );

        return trForward.vecEndPos;
    }
    // An evil hack to get a viewmodel's attachment position (Credit: Nero)
    bool CreateViewModelEntity() final
    {
        if( m_pPlayer is null )
            return false;

        CBaseEntity@ pViewModel = g_EntityFuncs.Create( "info_target", m_pPlayer.pev.origin, m_pPlayer.pev.v_angle, true, m_pPlayer.edict() );

        if( pViewModel is null )
            return false;

        pViewModel.pev.movetype = MOVETYPE_NONE;
        pViewModel.pev.solid = SOLID_NOT;
        pViewModel.pev.effects |= EF_NODRAW;
        @pViewModel.pev.owner = m_pPlayer.edict();
        g_EntityFuncs.SetModel( pViewModel, m_pPlayer.pev.viewmodel );
        g_EntityFuncs.SetSize( pViewModel.pev, g_vecZero, g_vecZero );
        g_EntityFuncs.SetOrigin( pViewModel, pViewModel.pev.origin );
        g_EntityFuncs.DispatchSpawn( pViewModel.edict() );
        m_hViewModel = pViewModel;

        return m_hViewModel.IsValid();
    }
    // Run periodically in ItemPreFrame.
    void UpdateViewModelEntity() final
    {
        if( !m_hViewModel || m_pPlayer is null )
            return;

        Vector vecAngles = m_pPlayer.pev.v_angle;
        vecAngles.x *= -1;

        g_EntityFuncs.SetOrigin( m_hViewModel.GetEntity(), m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs );
        m_hViewModel.GetEntity().pev.velocity = m_pPlayer.pev.velocity;
        m_hViewModel.GetEntity().pev.angles = vecAngles;
        m_hViewModel.GetEntity().pev.sequence = m_pPlayer.pev.weaponanim;

        for( uint i = 0; i < M_VEC_VIEWMODELATTACHMENT_POS.length(); i++ )
            g_EngineFuncs.GetAttachment( m_hViewModel.GetEntity().edict(), i, M_VEC_VIEWMODELATTACHMENT_POS[i], void );
    }
};
// Baseclass for guns
abstract class CustomGunBase : CustomWeaponBase
{
    protected int m_iShell = g_Game.PrecacheModel( "models/shell.mdl" ), m_iShotsFired;
    protected string strEmptySound = "weapons/dryfire_rifle.wav";

    protected bool PreShoot() { return true; };// Called before the gun fires a bullet, method should return false if the gun shouldn't fire a bullet.
    protected bool PostShoot() { return true; };// Called after the gun fires a bullet, method should return false if the gun shouldn't deduct ammo.
    // Impose our own carry restrictions on default ammo types.
    void ClampMaxAmmo() final
    {
        if( M_I_STATS[WpnStatIdx::iMaxAmmo1] < 1 )
            return;

        m_pPlayer.SetMaxAmmo( self.m_iPrimaryAmmoType, M_I_STATS[WpnStatIdx::iMaxAmmo1] );

        if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > M_I_STATS[WpnStatIdx::iMaxAmmo1] )
            m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, M_I_STATS[WpnStatIdx::iMaxAmmo1] );

        if( M_I_STATS[WpnStatIdx::iMaxAmmo2] < 1 )
            return;

        m_pPlayer.SetMaxAmmo( self.m_iSecondaryAmmoType, M_I_STATS[iMaxAmmo2] );

        if( m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) > M_I_STATS[iMaxAmmo2] )
            m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, M_I_STATS[iMaxAmmo2] );
    }

    bool ShootingNotAllowed()
    {
        if( m_pPlayer is null )
            return false;

        return( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip < 1 );
    }
    // Common shoot behaviour for guns
    bool Shoot(uint iShots, Vector& in vecAiming, Vector& in vecAccuracy, const Bullet bullet, int iDamage = 0, float flRange = 8192.0f)
    {
        if( m_pPlayer is null )
            return false;

        if( !PreShoot() || iShots < 1 )
            return false;
        // Forced to use BULLET_PLAYER_CUSTOMDAMAGE because using any of the stock ones has risk of gibbing the target when they receive mortal damage.
        // Manually get the damage type of each bullet instead.
        if( iDamage < 1 )
        {
            switch( bullet )
            {
                case BULLET_PLAYER_9MM:
                    iDamage = int( g_EngineFuncs.CVarGetFloat( "sk_plr_9mm_bullet" ) );
                    break;
                
                case BULLET_PLAYER_MP5:
                    iDamage = int( g_EngineFuncs.CVarGetFloat( "sk_plr_9mmAR_bullet" ) );
                    break;

                case BULLET_PLAYER_SAW:
                    iDamage = int( g_EngineFuncs.CVarGetFloat( "sk_556_bullet" ) );
                    break;

                case BULLET_PLAYER_SNIPER:
                    iDamage = int( g_EngineFuncs.CVarGetFloat( "sk_plr_762_bullet" ) );
                    break;

                case BULLET_PLAYER_357:
                    iDamage = int( g_EngineFuncs.CVarGetFloat( "sk_plr_357_bullet" ) );
                    break;

                case BULLET_PLAYER_EAGLE:
                    iDamage = int( g_EngineFuncs.CVarGetFloat( "sk_plr_357_bullet" ) * 0.66f );// according to skill.cfg anyway.
                    break;

                case BULLET_PLAYER_BUCKSHOT:
                    iDamage = int( g_EngineFuncs.CVarGetFloat( "sk_plr_buckshot" ) );
                    break;
                // Yes. Crowbar bullets. Don't ask.
                case BULLET_PLAYER_CROWBAR:
                    iDamage = int( g_EngineFuncs.CVarGetFloat( "sk_plr_crowbar" ) );
                    break;
            }

            if( iDamage < 1 )
            {
                try { iDamage = M_I_STATS[WpnStatIdx::iDamage1]; }
                catch { iDamage = 0; }
            }
        }

        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        g_WeaponFuncs.ClearMultiDamage();
        self.FireBullets( iShots, m_pPlayer.GetGunPosition(), vecAiming, vecAccuracy, flRange, BULLET_PLAYER_CUSTOMDAMAGE, 4, iDamage, m_pPlayer.pev );
        g_WeaponFuncs.ApplyMultiDamage( self.pev, m_pPlayer.pev );
        m_iShotsFired++;

        if( !PostShoot() )
            return true;

        if( --self.m_iClip < 1 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < 1 )
            m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

        return true;
    }

    CGrenade@ LaunchGrenade(int iShootAnim, int iDamage = 0, float flSpeed = 800.0f, float flGravity = 0.0f, string strModel = "")
    {
        m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
        m_pPlayer.m_flStopExtraSoundTime = g_Engine.time + 0.2f;
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        self.SendWeaponAnim( iShootAnim );

        CGrenade@ pGrenade = g_EntityFuncs.ShootContact( m_pPlayer.pev, m_pPlayer.GetGunPosition(), m_pPlayer.GetAutoaimVector( 0 ) * flSpeed );

        if( pGrenade is null )
            return null;

        if( flGravity != 0.0f )
            pGrenade.pev.gravity = flGravity;

        if( iDamage != 0 )
            pGrenade.pev.dmg = float( iDamage );

        if( strModel != "" )
            g_EntityFuncs.SetModel( pGrenade, strModel );

        return pGrenade;
    }
    // rgba.a value is scale of the flash.
    void MuzzleFlash(RGBA& in rgbaColor, float flOffset = 59.0f) final
    {
        if( m_pPlayer is null )
            return;

        m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
        m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
        m_pPlayer.pev.effects |= EF_MUZZLEFLASH;//!-BUG-!: using EF_MUZZLEFLASH doesn't work, forced replicate it via temporary fx
        // This will have to do
        Vector vecFlashPos = m_pPlayer.GetGunPosition() + g_Engine.v_forward * flOffset; // extra bit to align it perfectly with gun muzzle
        vecFlashPos.z = m_pPlayer.pev.origin.z - ( m_pPlayer.pev.FlagBitSet( FL_DUCKING ) ? 18 : 36 );

        NetworkMessage flash( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecFlashPos );
            flash.WriteByte( TE_DLIGHT );

            flash.WriteCoord( vecFlashPos.x );
            flash.WriteCoord( vecFlashPos.y );
            flash.WriteCoord( vecFlashPos.z );

            flash.WriteByte( rgbaColor.a );// scale
            flash.WriteByte( rgbaColor.r );
            flash.WriteByte( rgbaColor.g );
            flash.WriteByte( rgbaColor.b );

            flash.WriteByte( 1 );
            flash.WriteByte( 0 );
        flash.End();
    }
    // Credit: KernCore, https://github.com/KernCore91/-SC-Insurgency-Weapons-Project/blob/master/scripts/maps/ins2/base.as#L462C2-L477
    void EjectCasing(float forwardScale, float rightScale, float upScale, TE_BOUNCE soundtype = TE_BOUNCE_SHELL, int iShellModel = 0) final
    {
        if( m_pPlayer is null )
            return;

        Vector vecForward, vecRight, vecUp, vecShellVelocity, vecShellOrigin;
        g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecForward, vecRight, vecUp );

        const float
        fR = Math.RandomFloat( 50, 70 ),
        fU = Math.RandomFloat( 100, 150 );

        for( int i = 0; i < 3; i++ )
        {
            vecShellVelocity[i] = m_pPlayer.pev.velocity[i] + vecRight[i] * fR + vecUp[i] * fU + vecForward[i] * 25;
            vecShellOrigin[i] = m_pPlayer.pev.origin[i] + m_pPlayer.pev.view_ofs[i] + vecUp[i] * upScale + vecForward[i] * forwardScale + vecRight[i] * rightScale;
        }

        g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles.y, iShellModel > 0 ? iShellModel : m_iShell, soundtype );
    }

    void Recoil(Vector& in vecAimPunch, float flPunchScale = 1.0f) final
    {
        if( m_pPlayer is null || vecAimPunch == g_vecZero )
            return;

        m_pPlayer.pev.punchangle = vecAimPunch * flPunchScale;
    }

    void DrawColourTracer(Vector& in vecDir, uint8 colour = 0, uint8 length = 12) final
    {
        if( m_pPlayer is null || vecDir == g_vecZero )
            return;

        Vector vecStart, vecVelocity = vecDir * 6000.0f;
        g_EngineFuncs.GetAttachment( m_pPlayer.edict(), 0, vecStart, void );

        NetworkMessage colourtracer( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, null );
            colourtracer.WriteByte( TE_USERTRACER );

            colourtracer.WriteCoord( vecStart.x );
            colourtracer.WriteCoord( vecStart.y );
            colourtracer.WriteCoord( vecStart.z );

            colourtracer.WriteCoord( vecVelocity.x );
            colourtracer.WriteCoord( vecVelocity.y );
            colourtracer.WriteCoord( vecVelocity.z );

            colourtracer.WriteByte( 32 );// life
            colourtracer.WriteByte( Math.clamp( 1, 11, colour ) );
            colourtracer.WriteByte( length );
        colourtracer.End();
    }

    void AimDownSights(const int iZoomFov)
    {
        if( m_pPlayer is null || self.m_fInReload )
            return;

        m_pPlayer.pev.fov = m_pPlayer.m_iFOV = iZoomFov;
        //m_pPlayer.SetVModelPos( g_vecZero ); !-UNDONE-!: This was causing the viewmodel to be out of alignment requiring viewmodel edits
        self.m_fInZoom = true;
    }

    void HipFire()
    {
        if( m_pPlayer is null )
            return;

        m_pPlayer.pev.fov = m_pPlayer.m_iFOV = 0;
        //m_pPlayer.ResetVModelPos(); !-UNDONE-!: See reason in method "AimDownSights" 
        self.m_fInZoom = false;
    }

    int DeductPrimaryAmmo(const int iAmount = 1) final
    {
        if( m_pPlayer is null )
            return 0;

        m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - iAmount );
        return m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
    }

    int DeductSecondaryAmmo(const int iAmount = 1) final
    {
        if( m_pPlayer is null )
            return 0;

        m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - iAmount );
        return m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType );
    }

    bool PlayEmptySound()
    {
        if( self.m_bPlayEmptySound )
        {
            self.m_bPlayEmptySound = false;
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, strEmptySound, 0.9f, ATTN_NORM, 0, PITCH_NORM );
        }

        return false;
    }

    void Holster(int skiplocal = 0)
    {
        if( self.m_fInZoom )
            HipFire();

        m_iShotsFired = 0;
        self.pev.nextthink = 0.0f;
        SetThink( null );
        g_EntityFuncs.Remove( m_hViewModel.GetEntity() );
        BaseClass.Holster( skiplocal );
    }
};
// Baseclass for ammo
abstract class CustomAmmoBase : ScriptBasePlayerAmmoEntity
{
    protected string
        strModel = "models/error.mdl", 
        strPickupSound = "items/9mmclip1.wav",
        strName;

    protected int iClipSize, iMax;
    protected bool fFromWeapon = true;

    void Precache()
    {
        g_Game.PrecacheModel( strModel );
        BaseClass.Precache();
    }

    void Spawn()
    {
        self.Precache();
        g_EntityFuncs.SetModel( self, strModel );
        BaseClass.Spawn();

        if( strName == "" )
            strName = self.GetClassname();
    }

    bool AddAmmo(CBaseEntity @pOther)
    {
        if( pOther is null || pOther.GiveAmmo( iClipSize, strName, iMax, fFromWeapon ) < 0 )
            return false;

        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, strPickupSound, 1, ATTN_NORM );
        
        return true;
    }
};
