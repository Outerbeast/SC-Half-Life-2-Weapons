/* SC Half-Life 2 Weapons Pack
    Half-Life 2 weapons brough to Sven Co-op

1)  Download and extract the files into `svencoop_addon`, or your own maps files
2)  Add `map_script hl2_weapons` to your map cfg
    OR
    Add a trigger_script entity to your map with the key `"m_iszScriptFile"` set to `"hl2_weapons"`
    OR
    If you have a main map script, add an `#include` for this script in your main map script header.

3)  You need to register the weapons. Either:
    Add the entity `info_register_hl2weapons` to your map
    OR
    Execute `HL2_WEAPONS::RegisterWeapons()` in MapInit of the main map script:

    void MapInit()
    {
        HL2_WEAPONS::RegisterWeapons();
    }

    If the map doesn't have a map script, simply create one, name it, and stick the above code into that script file, then add `map_script <your_script_name_here>` to four map's CFG file.

Credits:
- Outerbeast: Project lead, programming
- Garompa: Graphics (models, textures, icons, visual fx), testing, feedback
- KernCore, H2: Support
- SV BOY: Testing
*/
#include "hl2/weapon_hl2_stunstick"
#include "hl2/weapon_hl2_gravgun"
#include "hl2/weapon_hl2_frag"
#include "hl2/weapon_hl2_pistol"
#include "hl2/weapon_hl2_alyxgun"
#include "hl2/weapon_hl2_revolver"
#include "hl2/weapon_hl2_smg"
#include "hl2/weapon_hl2_shotgun"
#include "hl2/weapon_hl2_oicw"
#include "hl2/weapon_hl2_ar2"
#include "hl2/weapon_hl2_crossbow"
#include "hl2/weapon_hl2_sniperrifle"
#include "hl2/weapon_hl2_pulsecannon"

namespace HL2_WEAPONS
{

bool blConfigEntityRegistered = RegisterConfigEntity();

array<ItemMapping@> IM_HL2_WEAPONS =
{
    ItemMapping( "weapon_crowbar", "weapon_hl2_stunstick" ),
    ItemMapping( "weapon_9mmhandgun", "weapon_hl2_pistol" ),
    ItemMapping( "weapon_357", "weapon_hl2_revolver" ),
    ItemMapping( "weapon_eagle", "weapon_hl2_revolver" ),
    ItemMapping( "weapon_9mmAR", "weapon_hl2_smg" ),
    ItemMapping( "weapon_uzi", "weapon_hl2_alyxgun" ),
    ItemMapping( "weapon_m16", "weapon_hl2_oicw" ),
    ItemMapping( "weapon_shotgun", "weapon_hl2_shotgun" ),
    ItemMapping( "weapon_crossbow", "weapon_hl2_crossbow" ),
    ItemMapping( "weapon_m249", "weapon_hl2_ar2" ),
    ItemMapping( "weapon_egon", "weapon_hl2_gravgun" ),
    ItemMapping( "weapon_sniperrifle", "weapon_hl2_sniperrifle" ),
    ItemMapping( "weapon_minigun", "weapon_hl2_pulsecannon" ),
    ItemMapping( "ammo_ARgrenades", "ammo_hl2_oicw_grenade" ),
    ItemMapping( "ammo_crossbow", "ammo_hl2_crossbow" ),
    ItemMapping( "ammo_762", "ammo_hl2_sniperrifle" )
};

bool RegisterConfigEntity()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::info_register_hl2weapons", "info_register_hl2weapons" );
    return g_CustomEntityFuncs.IsCustomEntity( "info_register_hl2weapons" );
}

bool RegisterWeapons(const bool blReplaceStockWeapons = true)
{
    const bool blAllRegistered =
        RegisterStunStick() &&
        RegisterGravGun() &&
        RegisterPistol() &&
        RegisterAlyxGun() &&
        RegisterRevolver() &&
        RegisterSMG() &&
        RegisterShotgun() &&
        RegisterAR2() &&
        RegisterOICW() &&
        RegisterXBow() &&
        RegisterSniperRifle() &&
        RegisterPulseCannon() &&
        RegisterFrag();

    if( blAllRegistered && blReplaceStockWeapons )
    {
        g_ClassicMode.SetItemMappings( @IM_HL2_WEAPONS );
        g_ClassicMode.ForceItemRemap( g_Hooks.RegisterHook( Hooks::PickupObject::Materialize, SwapItem ) );
    }

    g_Game.PrecacheModel( "sprites/hl2/hl2ammo.spr" );

    return blAllRegistered;
}

HookReturnCode SwapItem(CBaseEntity@ pOldItem)
{
    if( pOldItem is null ) 
        return HOOK_CONTINUE;

    for( uint w = 0; w < IM_HL2_WEAPONS.length(); w++ )
    {
        if( pOldItem.GetClassname() != IM_HL2_WEAPONS[w].get_From() || IM_HL2_WEAPONS[w].get_To() == "" )
            continue;

        CBaseEntity@ pNewItem = g_EntityFuncs.Create( IM_HL2_WEAPONS[w].get_To(), pOldItem.pev.origin, pOldItem.pev.angles, true );

        if( pNewItem is null ) 
            continue;

        pNewItem.pev.spawnflags = pOldItem.pev.spawnflags;
        pNewItem.pev.movetype = pOldItem.pev.movetype;
        pNewItem.pev.rendermode = pNewItem.m_iOriginalRenderMode = pOldItem.m_iOriginalRenderMode;
        pNewItem.pev.renderfx = pNewItem.m_iOriginalRenderFX = pOldItem.m_iOriginalRenderFX;
        pNewItem.pev.renderamt = pNewItem.m_flOriginalRenderAmount = pOldItem.m_flOriginalRenderAmount;
        pNewItem.pev.rendercolor = pNewItem.m_vecOriginalRenderColor = pOldItem.m_vecOriginalRenderColor;

        if( pOldItem.GetTargetname() != "" )
            pNewItem.pev.targetname = pOldItem.GetTargetname();

        if( pOldItem.pev.target != "" )
            pNewItem.pev.target = pOldItem.pev.target;

        if( pOldItem.pev.netname != "" )
            pNewItem.pev.netname = pOldItem.pev.netname;

        CBasePlayerWeapon@
            pOldWeapon = cast<CBasePlayerWeapon@>( pOldItem ), 
            pNewWeapon = cast<CBasePlayerWeapon@>( pNewItem );

        if( pOldWeapon !is null && pNewWeapon !is null )
        {
            pNewWeapon.m_flDelay = pOldWeapon.m_flDelay;
            pNewWeapon.m_bExclusiveHold = pOldWeapon.m_bExclusiveHold;

            if( pOldWeapon.m_iszKillTarget != "" )
                pNewWeapon.m_iszKillTarget = pOldWeapon.m_iszKillTarget;
        }

        if( g_EntityFuncs.DispatchSpawn( pNewItem.edict() ) < 0 )
            continue;

        g_EntityFuncs.Remove( pOldItem );
    }
    
    return HOOK_CONTINUE;
}
// !-WIP-!: more features to be added
final class info_register_hl2weapons : ScriptBaseEntity 
{
    void PreSpawn()
    {
        if( RegisterWeapons( self.pev.SpawnFlagBitSet( 1 << 0 ) ) )
            g_Log.PrintF( "HL2_WEAPONS: Weapons are all registered. Woohoo!\n" );

        g_EntityFuncs.Remove( self );
    }
};

}
