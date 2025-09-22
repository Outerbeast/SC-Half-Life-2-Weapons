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
#include "../maps/hl2/weapon_hl2_hoppermine"
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
    WeaponExchangeOption( "Hoppermine: Tripmine",       "tripmine",     "hoppermine" ),
    WeaponExchangeOption( "Hoppermine: Tripmine",       "satchel",      "hoppermine" )
};

array<AmmoExchangeOption> EXCH_MENU_AMMO =
{
    //AmmoExchangeOption( "Option Description", "hl2 weapon name", "ammo type name", "hl2weapon ammo name", "cost", "quantity", "secondary ammo type?" ),
    AmmoExchangeOption( "AR2 Clip: 556 x30",              "ar2",        "556",          "ar2",          30, 1 ),
    AmmoExchangeOption( "AR2 Energy: AR Grenade x2",      "ar2",        "ARgrenades",   "ar2_altfire",  2, 1, true ),
    AmmoExchangeOption( "OICW Grenade Clip: AR Grenade",  "oicw",       "ARgrenades",   "oicw_grenade", 1, 2, true ),
    AmmoExchangeOption( "Overwatch SR Clip: 762",       "sniperrifle",  "m40a1",        "sniperrifle", 1, 1 ),
    AmmoExchangeOption( "Bolt Crossbow: Crossbow Darts", "crossbow",    "bolts",        "crossbow",     1, 1 )
};

CTextMenu@ menuWeaponExchange, menuAmmoExchange;
bool blHL2WeaponsRegistered;

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( "Outerbeast" );
	g_Module.ScriptInfo.SetContactInfo( "https://github.com/Outerbeast/SC-Half-Life-2-Weapons/tree/main" );

    @menuWeaponExchange = CTextMenu( OptionSelected );
    @menuAmmoExchange = CTextMenu( OptionSelected );
    menuWeaponExchange.SetTitle( "HL2 Weapon Exchange " );
    menuAmmoExchange.SetTitle( "HL2 Ammo Exchange " );

    for( uint i = 0; i < EXCH_MENU_WEAPONS.length(); i++ )
    {
        if( EXCH_MENU_WEAPONS[i].m_strDescription == "" )
            continue;

        menuWeaponExchange.AddItem( EXCH_MENU_WEAPONS[i].m_strDescription, any( EXCH_MENU_WEAPONS[i] ) );
    }

    for( uint i = 0; i < EXCH_MENU_AMMO.length(); i++ )
    {
        if( EXCH_MENU_AMMO[i].m_strDescription == "" )
            continue;

        menuAmmoExchange.AddItem( EXCH_MENU_AMMO[i].m_strDescription, any( EXCH_MENU_AMMO[i] ) );
    }

    if( menuWeaponExchange.Register() && menuAmmoExchange.Register() )
        g_Hooks.RegisterHook( Hooks::Player::ClientSay, PlayerOpenMenu );
}

void MapInit()
{
    if( MapIsBlackListed() )
    {
        blHL2WeaponsRegistered = false;
        return;
    }

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
        HL2_WEAPONS::RegisterFrag() &&
        HL2_WEAPONS::RegisterHopperMine();
}

bool MapIsBlackListed()
{
    File@ fileBlackList = g_FileSystem.OpenFile( "scripts/plugins/store/hl2_weapons_mapblacklist.txt", OpenFile::READ );

    if( fileBlackList is null || !fileBlackList.IsOpen() )
        return false;

    bool blBlackListedMapFound = false;

    while( !fileBlackList.EOFReached() && !blBlackListedMapFound )
    {
        string strCurrentLine;
        fileBlackList.ReadLine( strCurrentLine );

        if( strCurrentLine == "" || strCurrentLine.StartsWith( "#" ) )
            continue;

        blBlackListedMapFound = string( g_Engine.mapname ).StartsWith( strCurrentLine );
    }

    fileBlackList.Close();

    return blBlackListedMapFound;
}

void ExchangeWeapons(CBasePlayer@ pPlayer, WeaponExchangeOption@ chosen)
{
    if( pPlayer is null || chosen is null )
        return;

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
    // Give player weapon and switch to it
    pPlayer.GiveNamedItem( "weapon_hl2_" + chosen.m_strItem, 0, 0 );

    if( pPlayer.SwitchWeapon( pPlayer.HasNamedPlayerItem( "weapon_hl2_" + chosen.m_strItem ) ) )
        g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "" + pPlayer.pev.netname + " acquired '" + chosen.m_strItem + "'.\n" );
}

int ExchangeAmmo(CBasePlayer@ pPlayer, AmmoExchangeOption@ chosen)
{
    if( pPlayer is null || chosen is null )
        return -1;

    CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPlayer.HasNamedPlayerItem( "weapon_hl2_" + chosen.m_strWeapon ) );

    if( pWeapon is null )
    {
        g_PlayerFuncs.SayText( pPlayer, "You don't have the weapon '" + chosen.m_strWeapon + "' to buy ammo for.\nPurchase the weapon first.\n" );
        return -1;
    }

    const int iAmmoType = g_PlayerFuncs.GetAmmoIndex( chosen.m_strAmmo );

    if( iAmmoType < 0 )
        return -1;

    if( pPlayer.m_rgAmmo( iAmmoType ) < int( chosen.m_iCost ) )
    {
        g_PlayerFuncs.SayText( pPlayer, "You don't have enough ammo to trade for '" + chosen.m_strItem + "'. Required is " + chosen.m_iCost + " " + chosen.m_strAmmo + "s.\n" );
        return -1;
    }
    // Give the player a magazine(s)
    int iAmmoAdded = 
        chosen.m_blSecondaryAmmo ? 
        pWeapon.AddSecondaryAmmo( chosen.m_iQuantity, "ammo_hl2_" + chosen.m_strItem, pWeapon.iMaxAmmo2() ) :
        pWeapon.AddPrimaryAmmo( pWeapon.iMaxClip() * chosen.m_iQuantity, "ammo_hl2_" + chosen.m_strItem, pWeapon.iMaxClip(), pWeapon.iMaxAmmo1() );

    if( iAmmoAdded > 0 )
        pPlayer.m_rgAmmo( iAmmoType, pPlayer.m_rgAmmo( iAmmoType ) - chosen.m_iCost * chosen.m_iQuantity );

    return iAmmoAdded;
}

void OptionSelected(CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ option)
{
    if( pPlayer is null || menu is null || option is null )
        return;

    if( menu is menuWeaponExchange )
    {
        WeaponExchangeOption weapon_choice;
        option.m_pUserData.retrieve( weapon_choice );
        ExchangeWeapons( pPlayer, @weapon_choice );
    }
    else if( menu is menuAmmoExchange )
    {
        AmmoExchangeOption ammo_choice;
        option.m_pUserData.retrieve( ammo_choice );
        ExchangeAmmo( pPlayer, @ammo_choice );
    }
}

HookReturnCode PlayerOpenMenu(SayParameters@ pParams)
{
    if( pParams is null )
        return HOOK_CONTINUE;

    CBasePlayer@ pPlayer = pParams.GetPlayer();
    const CCommand@ cmdArgs = pParams.GetArguments();

    if( cmdArgs.ArgC() < 1 || pPlayer is null || !pPlayer.IsConnected() )
        return HOOK_CONTINUE;

    if( cmdArgs[0].StartsWith( "!hl2_" ) && MapIsBlackListed() )
    {
        g_PlayerFuncs.SayText( pPlayer, "HL2 Weapons are not available on this map '" + g_Engine.mapname + "'.\n" );
        return HOOK_CONTINUE;
    }

    bool blOptionValid = false;

    if( cmdArgs[0] == "!hl2_weapons" )
    {
        if( cmdArgs[1] != "" )
        {
            for( uint i = 0; i < EXCH_MENU_WEAPONS.length() && !blOptionValid; i++ )
            {
                if( cmdArgs[1].EndsWith( EXCH_MENU_WEAPONS[i].m_strItem ) )
                {
                    ExchangeWeapons( pPlayer, EXCH_MENU_WEAPONS[i] );
                    blOptionValid = true;
                }
            }

            if( !blOptionValid )
                g_PlayerFuncs.SayText( pPlayer, "Weapon '" + cmdArgs[1] + "' doesn't exist.\nCheck the weapon exchange menu to see options.\n" );
        }
        else
            menuWeaponExchange.Open( 15, 0, pPlayer );
    }

    if( cmdArgs[0] == "!hl2_ammo" )
    {
        if( cmdArgs[1] != "" )
        {
            for( uint i = 0; i < EXCH_MENU_AMMO.length() && !blOptionValid; i++ )
            {
                AmmoExchangeOption choice_cmd = EXCH_MENU_AMMO[i];

                if( cmdArgs[1].EndsWith( choice_cmd.m_strItem ) )
                {
                    if( atoui( cmdArgs[2] ) > 0 )
                        choice_cmd.m_iQuantity = atoui( cmdArgs[2] );

                    ExchangeAmmo( pPlayer, choice_cmd );
                    blOptionValid = true;
                }
            }

            if( !blOptionValid )
                g_PlayerFuncs.SayText( pPlayer, "Ammo '" + cmdArgs[1] + "' doesn't exist.\nCheck the ammo exchange menu to see options.\n" );
        }
        else
            menuAmmoExchange.Open( 15, 0, pPlayer );
    }

    pParams.set_ShouldHide( blOptionValid );

    return HOOK_CONTINUE;
}

final class WeaponExchangeOption
{
    array<string> M_STR_REQUIRED;
    string m_strDescription, m_strItem;

    WeaponExchangeOption() { };// Otherwise the compiler throws a fit and halts

    WeaponExchangeOption(string& in Description, const string& in required, const string& in Item)
    {
        this.m_strDescription = Description;
        this.M_STR_REQUIRED.insertLast( required );
        this.m_strItem = Item; 
    }

    WeaponExchangeOption(string& in Description, const array<string>@ REQUIRED, const string& in Item)
    {
        this.m_strDescription = Description;
        this.M_STR_REQUIRED = REQUIRED;
        this.m_strItem = Item; 
    }
};

final class AmmoExchangeOption
{
    string m_strDescription, m_strWeapon, m_strItem, m_strAmmo;
    uint m_iCost, m_iQuantity = 1;
    bool m_blSecondaryAmmo;

    AmmoExchangeOption() { };

    AmmoExchangeOption
    (
        string& in Description,
        string& in Weapon, 
        string& in Ammo,
        string& in Item,
        uint Cost, 
        uint Quantity = 1, 
        bool SecondaryAmmo = false
    )
    {
        this.m_strDescription = Description;
        this.m_strWeapon = Weapon;
        this.m_strAmmo = Ammo;
        this.m_strItem = Item;
        this.m_iCost = Cost;
        this.m_iQuantity = Quantity;
        this.m_blSecondaryAmmo = SecondaryAmmo; 
    }
};
