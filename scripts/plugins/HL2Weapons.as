/* SC Half-Life 2 Weapons Pack
    Half-Life 2 weapons brought to Sven Co-op

This is the plugin script for installing the weapons to your game/server.
The weapon pack can be installed with a plugin to add to your game or server.
It features a in-game menu that you can use to exchange stock weapons for the HL2 weapons.

Install instructions:-
1) Download and extract the files into "svencoop_addon"
2) Edit your default_plugins.txt file (found in "svencoop") and add the following:

    "plugin"
	{
		"name" "HL2Weapons"
		"script" "HL2Weapons"
	}

-then save the file.

Once you've installed the plugin, you can use the chat command `!hl2_weapons` to open the weapon exchange menu,
which allows you to trade in a stock weapon(s) for a HL2 one.
For obtaining ammunition for the weapons that use their own unique ammo types, picking up ammo for the stock weapon will add ammo to the HL2 weapon.

Credits:
- Outerbeast: Project lead, programming
- Garompa: Graphics (models, textures, icons, visual fx), testing, feedback
- KernCore, H2: Support
- SV BOY: Testing
*/
#include "../maps/hl2/weapon_hl2_stunstick"
#include "../maps/hl2/weapon_hl2_gravgun"
#include "../maps/hl2/weapon_hl2_frag"
#include "../maps/hl2/weapon_hl2_pistol"
#include "../maps/hl2/weapon_hl2_alyxgun"
#include "../maps/hl2/weapon_hl2_revolver"
#include "../maps/hl2/weapon_hl2_smg"
#include "../maps/hl2/weapon_hl2_shotgun"
#include "../maps/hl2/weapon_hl2_oicw"
#include "../maps/hl2/weapon_hl2_ar2"
#include "../maps/hl2/weapon_hl2_crossbow"
#include "../maps/hl2/weapon_hl2_sniperrifle"
#include "../maps/hl2/weapon_hl2_pulsecannon"

array<WeaponExchangeOption> EXCH_MENU_WEAPONS =
{
    WeaponExchangeOption( "Stun Baton: Crowbar",        "crowbar",      "stunstick" ),
    WeaponExchangeOption( "USP: Pistol",                "9mmhandgun",   "pistol" ),
    WeaponExchangeOption( "357 Revolver: Colt Python",  "357",          "revolver" ),
    WeaponExchangeOption( "Alyx Gun: Uzi",              "uzi",          "alyxgun" ),
    WeaponExchangeOption( "Alyx Gun: Desert Eagle",     "eagle",        "alyxgun" ),
    WeaponExchangeOption( "MP7: SMG",                   "9mmAR",        "smg" ),
    WeaponExchangeOption( "SPAS12: Shotgun",            "shotgun",      "shotgun" ),
    WeaponExchangeOption( "OICW: M16",                  "m16",          "oicw" ),
    WeaponExchangeOption( "AR2: SMG + M16",             { "9mmAR", "m16" }, "ar2" ),
    WeaponExchangeOption( "AR2: SAW",                   "m249",         "ar2" ),
    WeaponExchangeOption( "Bolt Crossbow: Crossbow",    "crossbow",     "crossbow" ),
    WeaponExchangeOption( "Overwatch SR: Sniper Rifle", "sniperrifle",  "sniperrifle" ),
    WeaponExchangeOption( "Pulse Cannon: Minigun",      "minigun",      "pulsecannon" ),
    WeaponExchangeOption( "Gravity Gun: RPG",           "rpg",          "gravgun" ),
    WeaponExchangeOption( "Gravity Gun: Gauss",         "gauss",        "gravgun" ),
    WeaponExchangeOption( "Gravity Gun: Egon",          "egon",         "gravgun" ),
    WeaponExchangeOption( "Gravity Gun: Displacer",     "displacer",    "gravgun" ),
    WeaponExchangeOption( "MK3A2 Frag: Hand Grenade",   "handgrenade",  "frag" ),
};
// this is pure cancer
dictionary dictAmmoMappings = 
{
    { "ammo_556",           AmmoPickupMapping( "weapon_hl2_ar2", "ammo_hl2_ar2" ) },
    { "ammo_gaussclip",     AmmoPickupMapping( "weapon_hl2_ar2", "ammo_hl2_ar2_altfire", true ) },
    { "ammo_762",           AmmoPickupMapping( "weapon_hl2_sniperrifle", "ammo_hl2_sniperrifle" ) },
    { "ammo_ARgrenades",    AmmoPickupMapping( "weapon_hl2_oicw", "ammo_hl2_oicw_grenades", true ) },
    { "ammo_crossbow",      AmmoPickupMapping( "weapon_hl2_crossbow", "ammo_hl2_crossbow" ) }
};

CTextMenu@ menuWeaponExchange;
bool blHL2WeaponsRegistered;

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( "Outerbeast" );
	g_Module.ScriptInfo.SetContactInfo( "https://github.com/Outerbeast/SC-Half-Life-2-Weapons/tree/main" );

    @menuWeaponExchange = CTextMenu( ExchangeWeapons );
    menuWeaponExchange.SetTitle( "HL2 Weapon Exchange " );

    for( uint i = 0; i < EXCH_MENU_WEAPONS.length(); i++ )
    {
        if( EXCH_MENU_WEAPONS[i].m_strDescription == "" )
            continue;

        menuWeaponExchange.AddItem( EXCH_MENU_WEAPONS[i].m_strDescription, any( EXCH_MENU_WEAPONS[i] ) );
    }

    if( menuWeaponExchange.Register() )
    {
        g_Hooks.RegisterHook( Hooks::Player::ClientSay, PlayerOpenMenu );
        g_Hooks.RegisterHook( Hooks::PickupObject::Collected, CollectHL2Ammo );
    }
}

void MapInit()
{
    blHL2WeaponsRegistered =
        HL2_WEAPONS::RegisterStunStick() &&
        HL2_WEAPONS::RegisterGravGun() &&
        HL2_WEAPONS::RegisterPistol() &&
        HL2_WEAPONS::RegisterAlyxGun() &&
        HL2_WEAPONS::RegisterRevolver() &&
        HL2_WEAPONS::RegisterSMG() &&
        HL2_WEAPONS::RegisterShotgun() &&
        HL2_WEAPONS::RegisterAR2() &&
        HL2_WEAPONS::RegisterOICW() &&
        HL2_WEAPONS::RegisterXBow() &&
        HL2_WEAPONS::RegisterSniperRifle() &&
        HL2_WEAPONS::RegisterPulseCannon() &&
        HL2_WEAPONS::RegisterFrag();
}

void ExchangeWeapons(CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pWeapon)
{
    if( pPlayer is null || pWeapon is null || pWeapon.m_pUserData is null )
        return;

    WeaponExchangeOption chosen;
    pWeapon.m_pUserData.retrieve( chosen );

    if( pPlayer.HasNamedPlayerItem( "weapon_hl2_" + chosen.m_strItem ) !is null )
    {
        g_PlayerFuncs.SayText( pPlayer, "You already have '" + chosen.m_strItem + "'.\nDrop it first to buy another one.\n" );
        return;
    }

    array<bool> BL_SHOULD_EXCHANGE( chosen.M_STR_REQUIRED.length(), false );

    for( uint i = 0; i < chosen.M_STR_REQUIRED.length(); i++ )
        BL_SHOULD_EXCHANGE[i] = pPlayer.HasNamedPlayerItem( "weapon_" + chosen.M_STR_REQUIRED[i] ) !is null;

    if( BL_SHOULD_EXCHANGE.find( false ) >= 0 )
    {
        g_PlayerFuncs.SayText( pPlayer, "You can't afford " + chosen.m_strItem + ".\n" );
        return;
    }

    for( uint i = 0; i < chosen.M_STR_REQUIRED.length(); i++ )
        BL_SHOULD_EXCHANGE[i] = pPlayer.RemovePlayerItem( pPlayer.HasNamedPlayerItem( "weapon_" + chosen.M_STR_REQUIRED[i] ) );

/*     if( BL_SHOULD_EXCHANGE.find( false ) >= 0 )
        return; */

    pPlayer.GiveNamedItem( "weapon_hl2_" + chosen.m_strItem, 0, 0 );

    if( pPlayer.SwitchWeapon( pPlayer.HasNamedPlayerItem( "weapon_hl2_" + chosen.m_strItem ) ) )
        g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "" + pPlayer.pev.netname + " acquired " + chosen.m_strItem + ".\n" );
}

HookReturnCode CollectHL2Ammo(CBaseEntity@ pPickup, CBaseEntity@ pOther)
{
    if( pOther is null || !pOther.IsPlayer() || pPickup is null || !dictAmmoMappings.exists( pPickup.GetClassname() ) )
        return HOOK_CONTINUE;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );

    if( pPlayer is null )
        return HOOK_CONTINUE;

    AmmoPickupMapping ammo = cast<AmmoPickupMapping>( dictAmmoMappings[pPickup.GetClassname()] );
    CBasePlayerWeapon@ pWeapon = pPlayer.HasNamedPlayerItem( ammo.m_strWeapon ).GetWeaponPtr();

    if( pWeapon is null )
        return HOOK_CONTINUE;

    const int
        mag = ammo.m_blSecondaryAmmo ? pPlayer.m_rgAmmo( pWeapon.SecondaryAmmoIndex() ) : pWeapon.iMaxClip(),
        max = ammo.m_blSecondaryAmmo ? pWeapon.iMaxAmmo2() : pWeapon.iMaxAmmo1();

    //pWeapon.AddPrimaryAmmo( mag, ammo.m_strNewAmmo, mag, max );
    pPlayer.GiveAmmo( mag, ammo.m_strNewAmmo, max );

    return HOOK_CONTINUE;
}

HookReturnCode PlayerOpenMenu(SayParameters@ pParams)
{
    if( pParams is null )
        return HOOK_CONTINUE;

    CBasePlayer@ pPlayer = pParams.GetPlayer();
    const CCommand@ cmdArgs = pParams.GetArguments();

    if( cmdArgs.ArgC() < 1 || pPlayer is null || !pPlayer.IsConnected() )
        return HOOK_CONTINUE;

    if( cmdArgs[0] == "!hl2_weapons" )
    {
        pParams.set_ShouldHide( true );
        menuWeaponExchange.Open( 15, 0, pPlayer );
    }
        
    return HOOK_CONTINUE;
}

final class WeaponExchangeOption
{
    array<string> M_STR_REQUIRED;
    string m_strDescription, m_strItem;

    WeaponExchangeOption() { };// Otherwise the compiler throws a fit and halts

    WeaponExchangeOption(string strDescription, const string& in required, const string& in item)
    {
        this.m_strDescription = strDescription;
        this.M_STR_REQUIRED.insertLast( required );
        this.m_strItem = item; 
    }

    WeaponExchangeOption(string strDescription, const array<string>@ REQUIRED, const string& in item)
    {
        this.m_strDescription = strDescription;
        this.M_STR_REQUIRED = REQUIRED;
        this.m_strItem = item; 
    }
};

final class AmmoPickupMapping
{
    string
        m_strOriginalAmmo,
        m_strWeapon,
        m_strNewAmmo;

    bool m_blSecondaryAmmo;

    AmmoPickupMapping() { };

    AmmoPickupMapping(const string& in Weapon, const string& in NewAmmo)
    {
        m_strWeapon = Weapon;
        m_strNewAmmo = NewAmmo;
    }

    AmmoPickupMapping(const string& in Weapon, const string& in NewAmmo, bool SecondaryAmmo)
    {
        m_strWeapon = Weapon;
        m_strNewAmmo = NewAmmo;
        m_blSecondaryAmmo = SecondaryAmmo;
    }
};
