/* Hopper Mine - weapon_hl2_hoppermine 
    Primary Fire: Throw a hopper mine
    This is a HL2-style tripmine that can be thrown and will hop towards the nearest enemy.
    It will explode on contact with the ground or when it detects an enemy in its radius.
    It will also emit a sound when it is armed and when it is triggered.

    env_hl2_hoppermine
    This is the entity that represents the hopper mine entity. This can be placed in the world.
    Hopper mines are armed and active by default, but setting a targetname will make it inactive until triggered.

Part of the SC Half-Life 2 Weapons Pack.
- Outerbeast
*/
#include "weapon_base"

namespace HL2_WEAPONS
{

enum ANIM_HOPPERMINE
{
    IDLE1,
    IDLE2,
    PLACE,
    THROW,
    DRAW,
    HOLSTER
};

enum ANIM_HOPPERMINE_WORLD
{
    IDLE_DETACHED,
    IDLE_ATTACHED,
    ATTACH,
    DETACH
};

enum HOPPERMINE_SKINS
{
    SKIN_OFF,
    SKIN_BLUE,
    SKIN_GREEN,
    SKIN_ORANGE,
    SKIN_RED,
};

const array<float> FL_ANIMTIME_HOPPERMINE =
{
    3.07,
    2.07,
    0.37,
    1.00,
    0.53,
    0.53
};

array<int> I_STATS_HOPPERMINE =
{
    4,// Weapon slot
    7,// Position in the weapon slot
    10,// Max ammo for primary ammo
    WEAPON_NOCLIP,// Max ammo for  secondary ammo
    WEAPON_NOCLIP,// Clip size, -1 if not used
    0,// Damage of Primary Fire ammo
    0,// Damage of Secondary Fire ammo, -1 if not used
    5,
    ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE
};

array<string>
    STR_HOPPERMINE_MODELS =
    {
        "sprites/hl2/weapon_hl2_hoppermine.spr",
        "sprites/glow01.spr"
    },
    STR_HOPPERMINE_SOUNDS =
    {
        "hl2/hopper_jump.ogg",//jump and explode
        "hl2/hopper_attach.ogg",//blades in
        "hl2/hopper_deploy.ogg",//enemy entered detection radius
        "hl2/hopper_bladesout.ogg",//blades out
        "hl2/hopper_loop.ogg",//enemy detected in radius but still too far, looping
        "hl2/hopper_off.ogg"//after enemy leaves radius and didn't explode
    };

const string strWeapon_Hoppermine = "weapon_hl2_hoppermine";

bool RegisterHopperMine()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::weapon_hl2_hoppermine", "weapon_hl2_hoppermine" );
    g_ItemRegistry.RegisterWeapon( "weapon_hl2_hoppermine", "hl2", "weapon_hl2_hoppermine" );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::env_hl2_hoppermine", "env_hl2_hoppermine" );

    return g_CustomEntityFuncs.IsCustomEntity( "weapon_hl2_hoppermine" );
}

final class weapon_hl2_hoppermine : CustomWeaponBase, ThrowableWeaponBase
{
    weapon_hl2_hoppermine()
    {
        strModel_V = "models/hl2/v_hopper.mdl";
        strModel_P = "models/hl2/p_hopper.mdl";
        strModel_W = "models/hl2/w_hopper.mdl";
        strSpriteDir = "hl2";
        M_I_STATS = I_STATS_HOPPERMINE;
    }

    void Precache()
    {
        PrecacheContent( STR_HOPPERMINE_MODELS, STR_HOPPERMINE_SOUNDS );
        BaseClass.Precache();
    }

    void Spawn()
    {
        SpawnWeapon( 5 );   
        BaseClass.Spawn();
    }

    void Materialize()
    {
        self.pev.skin = SKIN_OFF;
        BaseClass.Materialize();
    }

    bool Deploy()
    {
        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( strModel_V ), self.GetP_Model( strModel_P ), ANIM_HOPPERMINE::DRAW, "trip" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_HOPPERMINE[ANIM_HOPPERMINE::DRAW];

        return blDeployed;
    }

    void Idle()
    {
        ANIM_HOPPERMINE AnimIdle = ANIM_HOPPERMINE( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, int( ANIM_HOPPERMINE::IDLE1 ), int( ANIM_HOPPERMINE::IDLE2 ) ) );
        self.SendWeaponAnim( AnimIdle );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_HOPPERMINE[AnimIdle];
    }

    void Throw()
    {
        Math.MakeVectors( m_pPlayer.pev.angles );
        CBaseEntity@ pMine = g_EntityFuncs.Create( "env_hl2_hoppermine", m_pPlayer.Center(), m_pPlayer.pev.angles, true, m_pPlayer.edict() );
        pMine.pev.angles = m_pPlayer.pev.angles;
        pMine.pev.angles.x = 0;
        pMine.pev.skin = SKIN_OFF;
        pMine.pev.velocity = g_Engine.v_forward * 350 + m_pPlayer.pev.velocity;

        if( g_EntityFuncs.DispatchSpawn( pMine.edict() ) > -1 )
        {
            SetThink( ThinkFunction( this.ReadyNext ) );
            self.pev.nextthink = g_Engine.time + FL_ANIMTIME_HOPPERMINE[ANIM_HOPPERMINE::THROW];
            DeductPrimaryAmmo();
        }
    }

    void ReadyNext()
    {
        self.SendWeaponAnim( ANIM_HOPPERMINE::DRAW );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_HOPPERMINE[ANIM_HOPPERMINE::DRAW];

        SetThink( null );
        self.pev.nextthink = 0.0f;
    }

    void PrimaryAttack()
    {
        if( IsEmpty() )
			return;

        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
        self.SendWeaponAnim( ANIM_HOPPERMINE::THROW );
        SetThink( ThinkFunction( this.Throw ) );
        self.pev.nextthink = g_Engine.time + 0.6f;// 0.6 seconds is the time it takes to throw the mine
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + FL_ANIMTIME_HOPPERMINE[ANIM_HOPPERMINE::THROW] + 1.0f;
    }

    void SecondaryAttack()
    {
        if( IsEmpty() )
            return;
    }
};

final class env_hl2_hoppermine : ScriptBaseAnimating
{
    private bool blAlerted = false;
    private float flDangerRadius = 256.0f;
    private EHandle hIndicator;
    EHandle m_hTarget;

    private CSprite@ m_pIndicator
    {
        get { return cast<CSprite@>( hIndicator.GetEntity() ); }
        set { hIndicator = EHandle( @value ); }
    }

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( szKey == "radius" )
            flDangerRadius = atof( szValue ) <= 0.0f ? 256.0f : atof( szValue );
        else
            return BaseClass.KeyValue( szKey, szValue );

        return true;
    }

    void Precache()
    {
        g_Game.PrecacheModel( self, self.pev.model );
        g_Game.PrecacheOther( strWeapon_Hoppermine );

        BaseClass.Precache();
    }

    void Spawn()
    {
        if( self.pev.model == "" )
            self.pev.model = "models/hl2/w_hopper.mdl";

        self.Precache();
        self.pev.movetype = MOVETYPE_TOSS;
        self.pev.solid = SOLID_BBOX;
        self.pev.takedamage = DAMAGE_NO;
        self.pev.friction = 1.0f;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );
        g_EntityFuncs.SetModel( self, self.pev.model );
        g_EntityFuncs.SetSize( self.pev, Vector( -4, -4, -4 ), Vector( 4, 4, 4 ) );
        self.pev.skin = SKIN_BLUE;// The blue color as it not yet armed.
        self.pev.sequence = ANIM_HOPPERMINE_WORLD::IDLE_DETACHED;

        if( self.pev.dmg <= 0 )
            self.pev.dmg = 100;

        if( self.pev.speed <= 0 )
            self.pev.speed = 100;
        // The hopper was thrown
        if( self.pev.owner !is null && self.pev.velocity != g_vecZero )
        {
            self.m_iClassSelection = g_EntityFuncs.Instance( self.pev.owner ).m_iClassSelection; // Not necessary, but for consistency.
            SetThink( ThinkFunction( this.Toss ) );
            self.pev.nextthink = g_Engine.time + 0.1f;
        }
        else if( self.GetTargetname() == "" )// The hopper was spawned by the map
        {
            SetThink( ThinkFunction( this.Arm ) );
            self.pev.nextthink = g_Engine.time + 1.7f;
        }

        BaseClass.Spawn();
    }

    void PostSpawn()
    {
        @m_pIndicator = g_EntityFuncs.CreateSprite( "sprites/glow01.spr", self.pev.origin, false );
        m_pIndicator.SetTransparency( kRenderGlow, 0, 0, 255, 128, kRenderFxNone );
        m_pIndicator.SetScale( 0.1f );
        m_pIndicator.SetAttachment( self.edict(), 1 );
        BaseClass.PostSpawn();
    }

    void Toss()
    {
        if( self.pev.velocity != g_vecZero )// Still moving
            self.pev.nextthink = g_Engine.time + 0.1f;
        else
        {
            SetThink( ThinkFunction( this.Arm ) );
            self.pev.nextthink = g_Engine.time + 1.7f;
        }
    }

    void Arm()
    {
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.skin = SKIN_GREEN;// The green color as it is armed.
        self.pev.sequence = ANIM_HOPPERMINE_WORLD::IDLE_ATTACHED;
        m_pIndicator.pev.rendercolor = Vector( 0, 255, 0 );
        g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hl2/hopper_attach.ogg", 1.0f, ATTN_NORM );
        SetThink( ThinkFunction( this.SensorThink ) );
        self.pev.nextthink = g_Engine.time + 1.0f;
    }

    void SensorThink()
    {
        array<CBaseEntity@> P_ENTITIES( 16 );
        
        if( g_EntityFuncs.MonstersInSphere( @P_ENTITIES, self.pev.origin, flDangerRadius ) < 1 )
        {
            if( blAlerted )
            {
                blAlerted = false;
                g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hl2/hopper_off.ogg", 1.0f, ATTN_NORM );
                self.pev.skin = SKIN_GREEN;

                if( m_pIndicator !is null )
                    m_pIndicator.pev.rendercolor = Vector( 0, 255, 0 );
            }

            self.pev.nextthink = g_Engine.time + 1.0f;

            return;
        }

        uint i = 0;

        for( ; i < P_ENTITIES.length(); i++ )
        {
            if( P_ENTITIES[i] is null || !P_ENTITIES[i].IsAlive() )
                continue;

            if( self.pev.owner !is null )
            {
                if( P_ENTITIES[i].edict() is self.pev.owner || P_ENTITIES[i].IRelationship( g_EntityFuncs.Instance( self.pev.owner ) ) == R_AL )
                    continue;
            }
            else if( P_ENTITIES[i].IRelationshipByClass( CLASS( self.m_iClassSelection ) ) == R_AL )
                continue;

            break;
        }

        CBaseEntity@ pTarget;

        try
        {
            @pTarget = P_ENTITIES[i];
        }
        catch
        {// Out of bounds.
            @pTarget = null;
        }

        bool blShouldWarn = false;
        
        if( pTarget !is null )
        {
            blShouldWarn = Warn();

            if( ( pTarget.pev.origin - self.pev.origin ).Length() <= flDangerRadius * 0.6f )
            {
                m_hTarget = pTarget;
                g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hl2/hopper_bladesout.ogg", 1.0f, ATTN_NORM );
                self.pev.sequence = ANIM_HOPPERMINE_WORLD::IDLE_DETACHED;
                SetThink( ThinkFunction( this.Hop ) );
                self.pev.nextthink = g_Engine.time + 0.43f;

                return;
            }
        }

        self.pev.nextthink = g_Engine.time + ( blShouldWarn ?  1.45f : 0.42f );
    }

    bool Warn()
    {
        if( blAlerted )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hl2/hopper_loop.ogg", 1.0f, ATTN_NORM );
            return true;
        }
            
        g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hl2/hopper_deploy.ogg", 1.0f, ATTN_NORM );
        self.pev.skin = SKIN_RED;// The red color as it is alerted.

        if( m_pIndicator !is null )
            m_pIndicator.pev.rendercolor = Vector( 255, 0, 0 );

        blAlerted = true;

        return false;
    }

    void Hop()
    {
        self.pev.movetype = MOVETYPE_TOSS;
        self.pev.gravity = 0.5f;
        g_EntityFuncs.SetOrigin( self, self.pev.origin + Vector( 0, 0, 5 ) );
        self.pev.velocity.z = 400.0f;
        // Target the entity to hop towards.
        if( m_hTarget )
        {
            Vector vecDir = ( m_hTarget.GetEntity().Center() - self.pev.origin ).Normalize();
            vecDir.z = 0;
            self.pev.velocity = self.pev.velocity + vecDir * self.pev.speed;// speed is the bias strength.
            self.pev.avelocity = CrossProduct( m_hTarget.GetEntity().Center(), self.pev.velocity * 50 ) / pow( m_hTarget.GetEntity().Center().Length(), 2 );
            self.pev.avelocity = self.pev.avelocity * 2;
        }

        g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "hl2/hopper_jump.ogg", 1.0f, ATTN_NORM );
        SetTouch( TouchFunction( this.Fall ) );
        SetThink( null );
        self.pev.nextthink = 0.0f;
    }

    void Fall(CBaseEntity@ pOther)
    {
        if( self.pev.movetype != MOVETYPE_TOSS || self.pev.velocity.z > 0 )
            return;

        Detonate();

        BaseClass.Touch( pOther );
    }

    void Detonate()
    {
        entvars_t@ pevOwner = self.pev.owner !is null ? self.pev.owner.vars : self.pev;
        g_EntityFuncs.ShootContact( pevOwner, self.pev.origin + Vector( 0, 0, 1 ), self.pev.velocity ).pev.effects |= EF_NODRAW;
        g_EntityFuncs.Remove( self );
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
    {
        if( self.pev.nextthink <= 0.0f )// Hopper mine is not armed yet.
            Arm();
        else
        {
            switch( useType )
            {
                case USE_ON:
                case USE_TOGGLE:
                    Hop();
                    break;

                case USE_KILL:
                    Detonate();
                    break;

                default: break;
            }
        }
    }

    void Killed(entvars_t@ pevAttacker, int iGib)
    {
        Detonate();
    }

    void UpdateOnRemove()
    {
        if( m_pIndicator !is null )
            g_EntityFuncs.Remove( m_pIndicator );
        
        SetThink( null );
        self.pev.nextthink = 0.0f;

        BaseClass.UpdateOnRemove();
    }
};

}
