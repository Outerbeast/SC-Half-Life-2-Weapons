/* MK3A2 Frag Grenade - weapon_hl2_frag
    Primary Attack - Throw a frag grenade
    Secondary Attack - Toss a frag grenade
    Tertiary Attack - Throw a incendiary grenade (if mp_banana is set to 1 or more) - requires 5 ammo

Part of the SC Half-Life 2 Weapons Pack.
- Outerbeast
*/
namespace HL2_WEAPONS
{

enum ANIM_FRAG
{
    IDLE,
    FIDGET,
    PINPULL,
    THROW1,
    THROW2,
    THROW3,
    HOLSTER,
    DRAW,
    THROW_LOW,
    PINPULL_LOW
};

enum FRAG_TYPE
{
    FRAG_THROW = IN_ATTACK,
    FRAG_TOSS = IN_ATTACK2,
    FRAG_LEMONADE = IN_ALT1
};

const array<float> FL_ANIMTIME_FRAG =
{
    3.4f,
    3.4f,
    0.23f,
    0.43f,
    0.43f,
    0.43f,
    1.33f,
    0.89f,
    0.87f,
    0.47f
};

array<int> I_STATS_FRAG =
{
    4,// Weapon slot
    6,// Position in the weapon slot
    10,// Max ammo for primary ammo
    WEAPON_NOCLIP,// Max ammo for  secondary ammo
    WEAPON_NOCLIP,// Clip size, -1 if not used
    0,// Damage of Primary Fire ammo
    0,// Damage of Secondary Fire ammo, -1 if not used
    5,
    ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE
};

array<string>
    STR_FRAG_MODELS =
    {
        "models/hl2/w_lemonade.mdl",
        "models/hl2/firezone.mdl",
        "sprites/hl2/weapon_hl2_frag.spr",
        "sprites/hl2/hl2ammo.spr"
    },
    STR_FRAG_SOUNDS =
    {
        "hl2/grenade_tick1.ogg",
        "hl2/lemons1.ogg",
        "hl2/lemons2.ogg",
        "weapons/splauncher_impact.wav",
        "hunger/thambs/burning1.wav"
    };

const string strWeapon_Frag = "weapon_hl2_frag";
float flFuseTime = 3.0f;// Fuse time in seconds

const int
    iFuseSprite = g_Game.PrecacheModel( "sprites/laserbeam.spr" ),
    iFireSprite = g_Game.PrecacheModel( "models/hl2/firelemongib.mdl" );

int 
    iLemonadeFireLifetime = 15,// Lemonade fire lifetime in seconds
    iFlameRadius = 128,// Lemonade fire radius in units
    iBurnDmg = 3;// Lemonade fire damage per tick

array<FireZone@> FIRE_ZONES;

bool RegisterFrag()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_Frag, strWeapon_Frag );
    g_ItemRegistry.RegisterWeapon( strWeapon_Frag, "hl2", "weapon_hl2_frag" );

    return g_CustomEntityFuncs.IsCustomEntity( strWeapon_Frag );
}

void Tick(EHandle hGrenade, int ticks)
{
    if( !hGrenade || ticks < 0 )
        return;
    
    float flDelay;

    switch( ticks )
    {
        case 5: flDelay = 1.1f; break;
        case 4: flDelay = 1.05f; break;
        case 3: 
        case 2:
        case 1: flDelay = 0.3; break;
        case 0:
        {   // explode 
            if( GrenadeIsLemonade( hGrenade ) )
            {
                const CLASS Classification = CLASS( hGrenade.GetEntity().m_iClassSelection );
                g_EngineFuncs.ServerPrint( "Throwing a lemonade with classification: " + Classification );
                FIRE_ZONES.insertLast( @FireZone( hGrenade.GetEntity().pev.origin, Classification, g_Engine.time ) );
                g_SoundSystem.EmitSoundDyn( hGrenade.GetEntity().edict(), CHAN_ITEM, "weapons/splauncher_impact.wav", 1.0f, ATTN_NORM );
                g_EntityFuncs.Remove( hGrenade.GetEntity() );
            }
            else
                hGrenade.GetEntity().Killed( null, GIB_NORMAL );

            return;
        }
    }

    g_SoundSystem.EmitSoundDyn( hGrenade.GetEntity().edict(), CHAN_ITEM, "hl2/grenade_tick1.ogg", 1.0f, ATTN_NORM );
    g_Scheduler.SetTimeout( "Tick", flDelay, hGrenade, --ticks );
}

bool GrenadeIsLemonade(EHandle hGrenade)
{
    if( !hGrenade )
        return false;

    CGrenade@ pGrenade = cast<CGrenade@>( hGrenade.GetEntity() );

    if( pGrenade is null || pGrenade.pev.model != "models/hl2/w_lemonade.mdl" )
        return false;

    return true;
}

final class weapon_hl2_frag : CustomWeaponBase, ThrowableWeaponBase
{
    private FRAG_TYPE m_iAttackType;
    private HUDTextParams tp;
    private ThinkFunction@ fnThrow;

    weapon_hl2_frag()
    {
        strModel_V = "models/hl2/v_grenade.mdl";
        strModel_P = "models/hl2/p_grenade.mdl";
        strModel_W = "models/hl2/w_grenade.mdl";
        strSpriteDir = "hl2";
        M_I_STATS = I_STATS_FRAG;
        // This is basically the same as the stock banana cluster grenade hud message
        tp.r1 = 250;
        tp.g1 = 252;
        tp.b1 = 66;
        tp.a1 = 0;

        tp.r1 = 250;
        tp.g1 = 252;
        tp.b1 = 66;
        tp.a1 = 255;

        tp.holdTime = 2;
        tp.channel = 2;
        tp.effect = 0;
        tp.fadeinTime = 0.5;
        tp.fadeoutTime = 0.5;
        tp.fxTime = 0;
        tp.x = 0.47;
        tp.y = 0.495;
    }

    void Precache()
    {
        PrecacheContent( STR_FRAG_MODELS, STR_FRAG_SOUNDS );
        BaseClass.Precache();
    }

    void Spawn()
    {
        SpawnWeapon( 5 );   
        BaseClass.Spawn();
    }

    bool Deploy()
    {
        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( strModel_V ), self.GetP_Model( strModel_P ), ANIM_FRAG::DRAW, "gren" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_FRAG[ANIM_FRAG::DRAW];

        return blDeployed;
    }

    void Idle()
    {
        const ANIM_FRAG AnimIdle = ANIM_FRAG( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, int( ANIM_FRAG::IDLE ), int( ANIM_FRAG::FIDGET ) ) );
        self.SendWeaponAnim( AnimIdle );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_FRAG[AnimIdle];
    }

    bool PullPin(FRAG_TYPE type)
    {
        if( IsEmpty() )
            return false;

        ANIM_FRAG AnimPinPull;

        switch( type )
        {
            case FRAG_THROW:
            case FRAG_LEMONADE:
            {
                AnimPinPull = ANIM_FRAG::PINPULL;
                @fnThrow = ThinkFunction( this.Throw );

                break;
            }

            case FRAG_TOSS:
            {
                AnimPinPull = ANIM_FRAG::PINPULL_LOW;
                @fnThrow = ThinkFunction( this.Toss );

                break;
            }
        }


        self.SendWeaponAnim( AnimPinPull );
        SetThink( @fnThrow );
        self.pev.nextthink = g_Engine.time + FL_ANIMTIME_FRAG[AnimPinPull];

        return true;
    }

    void Throw()
    {
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        // Based from HL SDK grenade behaviour
        Vector vecStart, vecThrow, vecAngle = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;
        vecAngle.x = -10 + vecAngle.x * ( ( 90 - ( vecAngle.x < 0 ? 10 : -10 ) ) / 90.0f );
        self.pev.speed = ( 90 - vecAngle.x ) * 6.5f;

        if( self.pev.speed > 1000.0f )
            self.pev.speed = 1000.0f;

        ANIM_FRAG AnimThrow = self.pev.speed < 500.0f ? ANIM_FRAG::THROW1 : ( self.pev.speed < 1000.0f ? ANIM_FRAG::THROW2 : ANIM_FRAG::THROW3 );
        self.SendWeaponAnim( AnimThrow );

        Math.MakeVectors( vecAngle );
        vecStart = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 16;
        vecThrow = m_pPlayer.pev.velocity + g_Engine.v_forward * self.pev.speed;

        if( Frag( vecStart, vecThrow ) is null )
            return;
        
        if( m_iAttackType == FRAG_LEMONADE )
        {
            g_SoundSystem.PlaySound( m_pPlayer.edict(), CHAN_VOICE, "hl2/lemons" + Math.RandomLong( 1, 2 ) + ".ogg", 0.75f, ATTN_NORM );
            g_PlayerFuncs.HudMessage( m_pPlayer, tp, "LEMONADE ATTACK!\n" );
            DeductPrimaryAmmo( 5 );
        }
        else
            DeductPrimaryAmmo();

        SetThink( ThinkFunction( this.ReadyNext ) );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.pev.nextthink = g_Engine.time + FL_ANIMTIME_FRAG[AnimThrow];
    }

    void Toss()
    {
        m_pPlayer.SetAnimation( PLAYER_DEPLOY );
        self.SendWeaponAnim( ANIM_FRAG::THROW_LOW );
        Math.MakeVectors( m_pPlayer.pev.angles );

        if( Frag( m_pPlayer.Center(), g_Engine.v_forward * 274 + m_pPlayer.pev.velocity ) is null )
            return;

        DeductPrimaryAmmo();
        SetThink( ThinkFunction( this.ReadyNext ) );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.pev.nextthink = g_Engine.time + FL_ANIMTIME_FRAG[ANIM_FRAG::THROW_LOW];
    }
    // Frag FX
    CGrenade@ Frag(const Vector& in pos, const Vector& in velocity)
    {
        CGrenade@ pFrag = g_EntityFuncs.ShootTimed( m_pPlayer.pev, pos, velocity, flFuseTime );
        
        if( pFrag is null )
            return null;
        // !-LIMITATION-!: CGrenade spawned from ShootTimed (and ShootContact) does not inherit the owner's classification - has to be set explicitly after it's spawned
        // Player class selection seems to return 0 when not overriden the player's class, so we check for that and set the incendiary to player class instead
        pFrag.SetClassification( m_pPlayer.m_iClassSelection == 0 ? CLASS_PLAYER : m_pPlayer.m_iClassSelection );
        const bool isLemonade = m_iAttackType == FRAG_LEMONADE;
        g_EntityFuncs.SetModel( pFrag, isLemonade ? "models/hl2/w_lemonade.mdl" : "models/hl2/w_grenade.mdl" );
        pFrag.pev.body = 1;// LED
        const RGBA colour = isLemonade ? RGBA_YELLOW : RGBA_RED;
        const int iAttachmentPoint = 0;// Beam trail FX
        NetworkMessage trail( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
            trail.WriteByte( TE_BEAMFOLLOW );
            trail.WriteShort( pFrag.entindex() + 0x1000 * ( iAttachmentPoint + 1 ) ); 
            trail.WriteShort( iFuseSprite );
            trail.WriteByte( 5 );// life
            trail.WriteByte( 1 );// width
            trail.WriteByte( colour.r );
            trail.WriteByte( colour.g );
            trail.WriteByte( colour.b );
            trail.WriteByte( colour.a );
        trail.End();

        Tick( EHandle( pFrag ), 5 );

        return pFrag;
    }

    void ReadyNext()
    {
        SetThink( @fnThrow = null );
        self.pev.nextthink = 0.0f;
        FRAG_TYPE m_iAttackType = FRAG_TYPE( 0 );

        if( IsEmpty() )
            return;

        self.SendWeaponAnim( ANIM_FRAG::DRAW );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_FRAG[ANIM_FRAG::DRAW];
    }

    void PrimaryAttack()
    {
        if( IsEmpty() )
            return;

        if( fnThrow is null )
            PullPin( m_iAttackType = FRAG_THROW );
    }

    void SecondaryAttack()
    {
        if( IsEmpty() )
            return;

        if( fnThrow is null )
            PullPin( m_iAttackType = FRAG_TOSS );
    }

    void TertiaryAttack()
    {
        if( IsEmpty() || g_EngineFuncs.CVarGetFloat( "mp_banana" ) < 1.0f )
            return;

        if( fnThrow is null )
            PullPin( m_iAttackType = FRAG_LEMONADE );
    }

    void ResetValues()
    {
        SetThink( @fnThrow = null );
        self.pev.nextthink = 0.0f;
        FRAG_TYPE m_iAttackType = FRAG_TYPE( 0 );
    }

    void Holster(int skiplocal = 0)
    {
        ResetValues();
        BaseClass.Holster( skiplocal );
    }

    void RetireWeapon()
    {
        ResetValues();
        BaseClass.RetireWeapon();
    }
};

final class FireZone
{
    private CLASS Classification;
    private float startTime;
    private EHandle hOwner, hFireMdl;
    private CScheduledFunction@ fnBurn;

    FireZone() { };

    FireZone(Vector pos, const CLASS Classification, const float startTime)
    {
        dictionary dictFire =
        {
            { "origin", pos.ToString() },
            { "angle", "" + Math.RandomLong( 0, 360 ) },
            { "model", "models/hl2/firezone.mdl" },
            { "rendermode", "" + kRenderTransAdd },
            { "renderamt", "255" },
            { "rendercolor", "255 255 255" },
            { "sequence", "0" },
            { "scale", "1" }
        };

        CBaseEntity@ pFire = g_EntityFuncs.CreateEntity( "item_generic", dictFire );
        g_SoundSystem.PlaySound( pFire.edict(), CHAN_STATIC, "hunger/thambs/burning1.wav", 1.0f, ATTN_IDLE, SND_ORIGIN | SND_FORCE_LOOP, PITCH_NORM, 0, true, pos );
        TraceResult trDecal;
        g_Utility.TraceLine( pos, pos - Vector( 0, 0, 1 ), ignore_monsters, pFire.edict(), trDecal );
        g_Utility.DecalTrace( trDecal, Math.RandomLong( DECAL_SCORCH1, DECAL_SCORCH2 ) );

        NetworkMessage firegibs( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
            firegibs.WriteByte( TE_EXPLODEMODEL );
            firegibs.WriteCoord( pos.x );
            firegibs.WriteCoord( pos.y );
            firegibs.WriteCoord( pos.z + 50.0f );
            firegibs.WriteCoord( 150.0f );
            firegibs.WriteShort( iFireSprite );
            firegibs.WriteShort( 32 );
            firegibs.WriteByte( 16 );
        firegibs.End();

        this.hFireMdl = pFire;
        this.Classification = Classification;
        this.startTime = startTime;

        g_Scheduler.SetTimeout( @this, "Spread", 0.3f );
    }

    private void Spread()
    {
        hFireMdl.GetEntity().pev.sequence = 1;
        
        if( fnBurn is null )
            @fnBurn = g_Scheduler.SetInterval( @this, "Burn", 0.1f );
    }

    private void Burn()
    {
        if( !hFireMdl )
            return;
        // Fizzle out the fire model before extinguishing it
        if( g_Engine.time >= startTime + iLemonadeFireLifetime - 0.7f )
            hFireMdl.GetEntity().pev.sequence = 2;

        if( g_Engine.time >= startTime + iLemonadeFireLifetime )
        {   
            Extinguish();
            return;
        }

        const Vector pos = hFireMdl.GetEntity().pev.origin;
        array<CBaseEntity@> P_ENTITIES( 32 );

        if( g_EntityFuncs.MonstersInSphere( @P_ENTITIES, pos, float( iFlameRadius ) ) < 1 )
            return;
        
        for( uint i = 0; i < P_ENTITIES.length(); i++ )
        {
            CBaseEntity@ pEntity = P_ENTITIES[i];
            
            if
            ( 
                pEntity is null || 
                !pEntity.IsAlive() || 
                pEntity.IRelationshipByClass( CLASS( Classification ) ) < R_NO || 
                pEntity.pev.absmin.z > pos.z + 64.0f || 
                pEntity.pev.absmax.z < pos.z
            )
                continue;
            // Lemonade fire damage - if someone/something is not on the ground, it will take full damage, otherwise it will take half damage or no damage at all
            const float flDamage = pEntity.pev.FlagBitSet( FL_ONGROUND ) ? float( iBurnDmg ) : ( Math.RandomLong( 0, 1 ) * iBurnDmg ) / 2.0f;
            pEntity.TakeDamage( g_EntityFuncs.Instance( 0 ).pev, g_EntityFuncs.Instance( 0 ).pev, flDamage, DMG_BURN );
        }
    }

    void Extinguish()
    {
        g_SoundSystem.StopSound( hFireMdl.GetEntity().edict(), CHAN_STATIC, "hunger/thambs/burning1.wav", false );
        g_EntityFuncs.Remove( hFireMdl.GetEntity() );
        g_Scheduler.RemoveTimer( fnBurn );
    }
    // Handles to this object never get released but anyway.
    ~FireZone()
    {
        Extinguish();
    }
};

}
