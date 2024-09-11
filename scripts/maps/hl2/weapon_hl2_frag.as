/* MK3A2 Frag Grenade - weapon_hl2_frag
    Primary Attack - Throw a frag grenade
    Secondary Attack - Toss a frag grenade

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

array<string>
    STR_FRAG_MODELS =
    {
        "models/hl2/v_grenade.mdl",
        "models/hl2/p_grenade.mdl",
        "models/hl2/w_grenade.mdl",
        "sprites/hl2/weapon_hl2_frag.spr",
        "sprites/laserbeam.spr"
    },
    STR_FRAG_SOUNDS = { "hl2/grenade_tick1.ogg" };

array<float> FL_NEXT_TOSS( g_Engine.maxClients + 1 );
array<EHandle> H_THROWN_GRENADES;

const string strWeapon_Frag = "weapon_hl2_frag";

bool RegisterFrag()
{
    Precache();
    g_EngineFuncs.CVarSetFloat( "mp_banana", 0.0f );
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_Frag, strWeapon_Frag );
    g_Scheduler.SetTimeout( "ReplaceFrags", 0.1f );
    g_Scheduler.SetInterval( "FragThink", 0.0f );
    g_Hooks.RegisterHook( Hooks::Player::PlayerUse, PlayerUseGrenade );
    g_Hooks.RegisterHook( Hooks::Weapon::WeaponSecondaryAttack, GrenadeSecondaryAttack );

    return g_CustomEntityFuncs.IsCustomEntity( strWeapon_Frag );
}

void Precache()
{
    for( uint i = 0; i < STR_FRAG_MODELS.length(); i++ )
        g_Game.PrecacheModel( STR_FRAG_MODELS[i] );

    for( uint i = 0; i < STR_FRAG_SOUNDS.length(); i++ )
    {
        g_SoundSystem.PrecacheSound( STR_FRAG_SOUNDS[i] );
        g_Game.PrecacheGeneric( "sound/" + STR_FRAG_SOUNDS[i] );
    }

    g_Game.PrecacheGeneric( "sprites/hl2/weapon_handgrenade.txt" );
}

void ReplaceFrags()
{
    CBaseEntity@ pEntity;

    while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "weapon_handgrenade" ) ) !is null )
    {
        if( pEntity is null || pEntity.pev.model == "models/hl2/w_grenade.mdl" )
            continue;

        if( g_EntityFuncs.Create( "weapon_hl2_frag", pEntity.pev.origin, pEntity.pev.angles, false ) !is null )
            g_EntityFuncs.Remove( pEntity );
    }
}

void FragThink()
{
    CBaseEntity@ pEntity;

    while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "grenade" ) ) !is null )
    {
        if( pEntity is null || pEntity.pev.owner is null )
            continue;

        if( pEntity.pev.model != "models/w_grenade.mdl" || pEntity.pev.model == "models/hl2/w_grenade.mdl" )
            continue;

        if( H_THROWN_GRENADES.findByRef( EHandle( pEntity ) ) >= 0 )
            continue;
        
        g_EntityFuncs.SetModel( pEntity, "models/hl2/w_grenade.mdl" );
        // This is not a banana cluster grenade
        if( pEntity.pev.gravity == 1.0f && pEntity.pev.friction == 0.8f ) 
            StartFuse( pEntity );

        H_THROWN_GRENADES.insertAt( 0, pEntity );
    }

    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
        {
            FL_NEXT_TOSS[iPlayer] = 0.0f;
            continue;
        }
        
        CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPlayer.m_hActiveItem.GetEntity() );

        if( pWeapon is null || pWeapon.GetClassname() != "weapon_handgrenade" )
            continue;

        pWeapon.m_flNextPrimaryAttack = 69;
    }
}

void ResetThrow(const uint idx)
{
    FL_NEXT_TOSS[idx] = 0.0f;
}

HookReturnCode PlayerUseGrenade(CBasePlayer@ pPlayer, uint& out uiFlags)
{
    if( pPlayer is null || !pPlayer.m_hActiveItem || pPlayer.m_hActiveItem.GetEntity().GetClassname() != "weapon_handgrenade" )
        return HOOK_CONTINUE;

    if( pPlayer.pev.button & IN_ATTACK == 0 || FL_NEXT_TOSS[pPlayer.entindex()] != 0.0f )
        return HOOK_CONTINUE;

    CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPlayer.m_hActiveItem.GetEntity() );
    pWeapon.PrimaryAttack();
    FL_NEXT_TOSS[pPlayer.entindex()] = FL_ANIMTIME_FRAG[ANIM_FRAG::THROW1];
    g_Scheduler.SetTimeout( "ResetThrow", FL_NEXT_TOSS[pPlayer.entindex()], pPlayer.entindex() );

    return HOOK_CONTINUE;
}

HookReturnCode GrenadeSecondaryAttack(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon)
{
    if( pPlayer is null || pWeapon is null || pWeapon.m_iId != WEAPON_HANDGRENADE )
        return HOOK_CONTINUE;

    if( pPlayer.m_rgAmmo( pWeapon.m_iPrimaryAmmoType ) < 1 || FL_NEXT_TOSS[pPlayer.entindex()] != 0.0f )
        return HOOK_CONTINUE;

    const ANIM_FRAG Anim = ANIM_FRAG::PINPULL_LOW;
    pWeapon.SendWeaponAnim( Anim );
    FL_NEXT_TOSS[pPlayer.entindex()] = FL_ANIMTIME_FRAG[Anim];
    pWeapon.m_flNextPrimaryAttack = g_Engine.time + FL_NEXT_TOSS[pPlayer.entindex()];
    g_Scheduler.SetTimeout( "TossFrag", FL_NEXT_TOSS[pPlayer.entindex()], EHandle( pPlayer ), EHandle( pWeapon ) );

    return HOOK_CONTINUE;
}

void TossFrag(EHandle hPlayer, EHandle hWeapon)
{
    if( !hPlayer || !hWeapon )
        return;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
    CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( hWeapon.GetEntity() );
    Math.MakeVectors( pPlayer.pev.angles );
    CGrenade@ pGrenade = g_EntityFuncs.ShootTimed( pPlayer.pev, pPlayer.pev.origin, g_Engine.v_forward * 274 + pPlayer.pev.velocity, 3.0f );

    if( pGrenade is null )
        return;

    pWeapon.SendWeaponAnim( ANIM_FRAG::THROW_LOW );
    pPlayer.SetAnimation( PLAYER_DEPLOY );
    g_EntityFuncs.SetModel( pGrenade, "models/hl2/w_grenade.mdl" );
    pPlayer.m_rgAmmo( pWeapon.m_iPrimaryAmmoType, pPlayer.m_rgAmmo( pWeapon.m_iPrimaryAmmoType ) - 1 );

    if( pPlayer.m_rgAmmo( pWeapon.m_iPrimaryAmmoType ) < 1 )
        pWeapon.Holster();
    else
        g_Scheduler.SetTimeout( @pPlayer, "DeployWeapon", FL_ANIMTIME_FRAG[ANIM_FRAG::DRAW] );

    StartFuse( pGrenade );
    ResetThrow( pPlayer.entindex() );
}

void StartFuse(EHandle hGrenade)
{
    if( !hGrenade )
        return;
    hGrenade.GetEntity().pev.body = 1;// LED
    // Beam trail FX
    const int iAttachmentPoint = 0;
    NetworkMessage trail( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
        trail.WriteByte( TE_BEAMFOLLOW );
        trail.WriteShort( hGrenade.GetEntity().entindex() + 0x1000 * ( iAttachmentPoint + 1 ) ); 
        trail.WriteShort( g_EngineFuncs.ModelIndex( "sprites/laserbeam.spr" ) );
        trail.WriteByte( 5 ); //life
        trail.WriteByte( 1 ); //width
        trail.WriteByte( RGBA_RED.r );
        trail.WriteByte( RGBA_RED.g );
        trail.WriteByte( RGBA_RED.b );
        trail.WriteByte( RGBA_RED.a );
    trail.End();

    Tick( hGrenade, 5 );
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
            hGrenade.GetEntity().pev.dmgtime = 0.0f;
            return;
        }
    }

    g_SoundSystem.EmitSoundDyn( hGrenade.GetEntity().edict(), CHAN_ITEM, "hl2/grenade_tick1.ogg", 1.0f, ATTN_NORM );
    g_Scheduler.SetTimeout( "Tick", flDelay, hGrenade, --ticks );
}
// Not a real weapon. Just an alias for the stock handgrenade + reskinning.
final class weapon_hl2_frag : ScriptBaseEntity
{
    private dictionary dictFrag = 
    {
        { "wpn_v_model", "models/hl2/v_grenade.mdl" },
        { "wpn_w_model", "models/hl2/w_grenade.mdl" },
        { "wpn_p_model", "models/hl2/p_grenade.mdl" },
        { "model","models/hl2/w_grenade.mdl" },
        { "CustomSpriteDir", "hl2" }
    };

    bool KeyValue(const string& in szKeyName, const string& in szValue)
    {
        if( szKeyName == "m_flCustomRespawnTime" || szKeyName == "soundlist" )
            dictFrag[szKeyName] = string( szValue );
        else
            return BaseClass.KeyValue( szKeyName, szValue );

        return true;
    }

    void Spawn()
    {
        self.pev.effects |= EF_NODRAW;
        self.pev.solid = SOLID_NOT;

        CBaseEntity@ pFrag = g_EntityFuncs.CreateEntity( "weapon_handgrenade", dictFrag, false );
        g_EntityFuncs.SetOrigin( pFrag, self.pev.origin );
        pFrag.pev.angles = self.pev.angles;
        pFrag.pev.targetname = self.GetTargetname();
        pFrag.pev.target = self.pev.target;
        pFrag.pev.body = self.pev.body;
        pFrag.pev.skin = self.pev.skin;
        pFrag.pev.scale = self.pev.scale;
        pFrag.pev.movetype = self.pev.movetype;
        pFrag.pev.dmg = self.pev.dmg;
        pFrag.pev.rendermode = self.pev.rendermode;
        pFrag.pev.rendercolor = self.pev.rendercolor;
        pFrag.pev.renderamt = self.pev.renderamt;
        pFrag.pev.renderfx = self.pev.renderfx;
        pFrag.pev.spawnflags = self.pev.spawnflags;
        
        if( g_EntityFuncs.DispatchSpawn( pFrag.edict() ) > -1 )
            g_EntityFuncs.Remove( self );
    }
};

}