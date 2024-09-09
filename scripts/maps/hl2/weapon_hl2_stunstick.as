/* Stun Stick - weapon_hl2_stunstick
    Melee weapon

Part of the SC Half-Life 2 Weapons Pack.
- Outerbeast
*/
#include "weapon_base"

namespace HL2_WEAPONS
{

enum ANIM_STUNSTICK
{
    IDLE1,
    IDLE2,
    IDLE3,
    DRAW,
    HOLSTER,
    ATTACK1_MISS,
    ATTACK2_MISS,
    ATTACK3_MISS,
    ATTACK1_HIT,
    ATTACK2_HIT,
    ATTACK3_HIT,
    ATTACK_BIG_WIND,
    ATTACK_BIG_HIT,
    ATTACK_BIG_MISS,
    ATTACK_BIG_LOOP
};

array<float> FL_ANIMTIME_STUNSTICK =
{
    2.03f,
    3.03f,
    3.03f,
    0.7f,
    0.7f,
    0.93f,
    0.77f,
    0.77f,
    0.77f,
    0.6f,
    0.77f,
    0.9f,
    0.97f,
    1.0f,
    -1.0f// loop indefinitely
};

array<int> I_STATS_STUNSTICK =
{
    0,
    5,
    WEAPON_NOCLIP,
    WEAPON_NOCLIP,
    WEAPON_NOCLIP,
    -1,
    -1,// Damage of Secondary Fire ammo, -1 if not used
    4
};

array<string>
    STR_STUNSTICK_MODELS =
    {
        "models/hl2/p_stunstick.mdl",
        "models/hl2/v_stunstick.mdl",
        "models/hl2/w_stunstick.mdl",
        "sprites/hl2/weapon_hl2_stunstick.spr",
        "sprites/hl2/stunstick_shock.spr"
    },
    STR_STUNSTICK_SOUNDS =
    {
        "hl2/stunstick_big_hit2.ogg",
        "hl2/stunstick_big_hitbod1.ogg",
        "hl2/stunstick_big_hitbod2.ogg",
        "hl2/stunstick_big_miss.ogg",
        "hl2/stunstick_draw.ogg",
        "hl2/stunstick_hit1.ogg",
        "hl2/stunstick_hit2.ogg",
        "hl2/stunstick_hitbod1.ogg",
        "hl2/stunstick_hitbod2.ogg",
        "hl2/stunstick_hitbod3.ogg",
        "hl2/stunstick_miss1.ogg",
        "hl2/stunstick_miss2.ogg",
        "hl2/stunstick_big_hit1.ogg"
    };

const string strWeapon_StunStick = "weapon_hl2_stunstick";

bool RegisterStunStick()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_StunStick, strWeapon_StunStick );
	g_ItemRegistry.RegisterWeapon( strWeapon_StunStick, "hl2", "" );

    return g_CustomEntityFuncs.IsCustomEntity( strWeapon_StunStick );
}

final class weapon_hl2_stunstick : CustomWeaponBase
{
    weapon_hl2_stunstick()
    {
        M_I_STATS = I_STATS_STUNSTICK;
        strSpriteDir = "hl2";
    }

    void Precache()
    {
        PrecacheContent( STR_STUNSTICK_MODELS, STR_STUNSTICK_SOUNDS, { "events/muzzle_hl2_stunstick.txt" } );
        BaseClass.Precache();
    }

    void Spawn()
    {
        SpawnWeapon( "models/hl2/w_stunstick.mdl" );
        BaseClass.Spawn();
    }

    bool Deploy()
    {
        const bool blDeployed = self.DefaultDeploy( self.GetV_Model( "models/hl2/v_stunstick.mdl" ), self.GetP_Model( "models/hl2/p_stunstick.mdl" ), ANIM_STUNSTICK::DRAW, "crowbar" );
        self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_STUNSTICK[ANIM_STUNSTICK::DRAW];

        return blDeployed;
    }

    void Idle()
    {
        ANIM_STUNSTICK AnimIdle = ANIM_STUNSTICK( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, int( ANIM_STUNSTICK::IDLE1 ), int( ANIM_STUNSTICK::IDLE3 ) ) );
        self.SendWeaponAnim( AnimIdle );
        self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_STUNSTICK[AnimIdle];
    }

    TraceResult HitTarget(const float flRange)
    {
        TraceResult tr;

        Vector 
            vecSrc = m_pPlayer.GetGunPosition(),
            vecEnd = vecSrc + m_pPlayer.GetAutoaimVector( 0 ) * flRange;

        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

        if( tr.flFraction >= 1.0f )
        {
            g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );

            if( tr.flFraction < 1.0f )
            {   // Calculate the point of intersection of the line (or hull) and the object we hit
                // This is and approximation of the "best" intersection
                CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

                if( pHit is null || pHit.IsBSPModel() )
                    g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
            }
        }

        return tr;
    }

    bool Strike(TraceResult& in trStrike, float flDamage, string s_HitBody, string s_HitWall, int iDmgType)
    {
        CBaseEntity@ pEntity = g_EntityFuncs.Instance( trStrike.pHit );
        
        if( self.m_flCustomDmg > 0 )
            flDamage = self.m_flCustomDmg;
 
        g_WeaponFuncs.ClearMultiDamage();
        pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, trStrike, iDmgType | DMG_NEVERGIB );
        g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
        // play thwack, smack, or dong sound
        float flVol = 1.0f;
        bool blHitSurface = true;

        if( pEntity !is null && pEntity.m_iClassSelection > CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
        {
            if( pEntity.IsPlayer() )
                pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
            // play thwack or smack sound
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, s_HitBody, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xF ) );
            m_pPlayer.m_iWeaponVolume = 128;
            g_Utility.Sparks( trStrike.vecEndPos );

            if( !pEntity.IsAlive() )
                return true;
            else
                flVol = 0.1f;

            blHitSurface = false;
        }
        // play texture hit sound
        // UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line
        if( blHitSurface )
        {
            float fvolbar = g_SoundSystem.PlayHitSound( trStrike, m_pPlayer.GetGunPosition(), m_pPlayer.GetGunPosition() + ( trStrike.vecEndPos - m_pPlayer.GetGunPosition()) * 2, BULLET_PLAYER_CUSTOMDAMAGE );
            // override the volume here, cause we don't play texture sounds in multiplayer, 
            // and fvolbar is going to be 0 from the above call.
            fvolbar = 1;
            // also play crowbar strike
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, s_HitWall, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xF ) );
        }

        g_Utility.Sparks( trStrike.vecEndPos );
        g_WeaponFuncs.DecalGunshot( trStrike, BULLET_PLAYER_CROWBAR );
        m_pPlayer.m_iWeaponVolume = int( flVol * 512 );

        return true;
    }

    float Swing()
    {
        ANIM_STUNSTICK AnimSwing;
        const TraceResult trHit = HitTarget( 32.0f );
        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        const string
            strSnd_Miss = "hl2/stunstick_miss" + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 1, 2 ) + ".ogg",
            strSnd_HitBody = "hl2/stunstick_hitbod" + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 1, 3 ) + ".ogg",
            strSnd_HitSurface = "hl2/stunstick_hit" + g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 1, 2 ) + ".ogg";

        if( trHit.flFraction < 1.0f )// hit
        {
            Strike( trHit, g_EngineFuncs.CVarGetFloat( "sk_plr_wrench" ), strSnd_HitBody, strSnd_HitSurface, DMG_CLUB | DMG_SHOCK_GLOW );
            AnimSwing = ANIM_STUNSTICK( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, int( ANIM_STUNSTICK::ATTACK1_HIT ), int( ANIM_STUNSTICK::ATTACK3_HIT ) ) );
        }
        else// missed
        {
            AnimSwing = ANIM_STUNSTICK( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, int( ANIM_STUNSTICK::ATTACK1_MISS ), int( ANIM_STUNSTICK::ATTACK3_MISS ) ) );
            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, strSnd_Miss, 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0, 0xF ) );
        }

        self.SendWeaponAnim( AnimSwing );

        return FL_ANIMTIME_STUNSTICK[AnimSwing];
    }

    void PrimaryAttack()
    {
       self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + Swing();
    }
};

}
