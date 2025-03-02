![alt text](https://github.com/Outerbeast/SC-Half-Life-2-Weapons/blob/main/hl2_sven_weaps_poster_v2.png?raw=true)
# Half-Life 2 Weapons Pack
#### Half-Life 2 weapons for Sven Co-op

### Author: Outerbeast
### Co-author: Garompa
This weapon pack aims to be an imagining of Sven Co-op 2's weapon loadout,
and not necessarily a direct one-to-one port of Half-Life 2's loadout.
Some new weapons have been added to the roster, while some of the originals have modified or extra features added.

This project is a work-in-progress, bugs and oversights are expected. Future updates may break compatibility with previous versions.
Other planned features such as support for weapon customisation of models, sound etc are in the works.

If you find any problems, please post an issue in the project's github repository "Issues" section.

### Weapons:
![alt text](https://github.com/Outerbeast/SC-Half-Life-2-Weapons/blob/main/weapon_list.png?raw=true)

Planned weapons for a future update: 
Annabelle (Father Grigori's rifle), Hopper Mine

## Download

### By using this pack, you agree to the following terms:

- Have fun with the weapons
- Provide credit for usage
- [Report bugs and issues if you find them](https://github.com/Outerbeast/SC-Half-Life-2-Weapons/issues). Do not keep them secret
- Do not redistribute anything used in this pack under a different name, under monetisation, or with modified source code

<details>
<summary>- I agree to these terms, gibe da waepons nao</summary>

[Download](https://github.com/Outerbeast/SC-Half-Life-2-Weapons/archive/refs/heads/main.zip)

</details>

# Installation

#### Warning: using this pack along with other installed weapon packs, be it plugins or map scripts, may result in weapon slot conflicts and will cause weapons to be unselectable.

## Game/Server Installation
The weapon pack can be installed with a plugin to add to your game or server. It features a in-game menu that you can use to exchange stock weapons for the HL2 weapons.

To Install the weapon pack to your game/server:-

1) Download and extract the files into `svencoop_addon`
2) Edit your `default_plugins.txt` file (found in `svencoop`) and add the following:

    ```
    "plugin"
	{
		"name" "HL2Weapons"
		"script" "HL2Weapons"
	}
    ```
-then save the file.

### How to equip the weapons

Once you've installed the plugin, you can use the Weapon and Ammo exchange menus which will give you several options for trading in stock weapon(s) and ammunition for HL2 equivalent weapons and ammunition. Most HL2 weapons use stock ammunition, but a few use their own ammo types.

To open the exchange menus, you can use the follow chat commands:

- `!hl2_weapons` opens the weapon exchange menu. Adding a weapon name after the command lets you exchange for the weapon directly without needing to use the menu.

Example:
```!hl2_weapons ar2```

- `!hl2_ammo` opens the ammo exchange menu. Adding an ammo name after the command lets you exchange for the ammo directly, by default one magazine is given. You can purchase multiple copies of the ammo, just add the quantity after the ammo name.

Example:
```!hl2_ammo ar2_altfire 2```

### Blacklisting maps
There is the option to disable HL2 weapons being available when certain maps are running by adding those map BSP names to the blacklist file `hl2_weapons_mapblacklist.txt` which is located in `scripts/plugins/store`. An example file is included explaining its usage.

## Map Installation
The script will automatically replace any stock weapons from cfg/world drops/player loadout with the HL2 equivalents.

To install this weapon pack to your map:-

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
    ```
    void MapInit()
    {
        HL2_WEAPONS::RegisterWeapons();
    }
    ```
    If the map doesn't have a map script, simply create one, name it, and stick the above code into that script file, then add `map_script <your_script_name_here>` to your map's CFG file.

A fgd file is included `hl2_weapons.fgd` to use with a map editor to add weapons and ammunition to your levels.

# Credits
- Outerbeast: Project leader, programming
- Garompa: Graphics (models, textures, icons, visual fx), testing, feedback
- KernCore, H2: Support
- DNIO071: Poster
- SV BOY: Testing

### Special thanks:
- aperture_aerospace: OICW model, OICW textures
- Shadow_RUN, Juniez, LambdaFox: MP7
- TheManClaw: Revolver HD textures
- AsIsAy: AR2 w_ and p_ models
- Pip Cryt: AR2's energy grenade model remake and textures
- Starfreak22: AR2 viewmodel and ammo
- SiNiSteR: Alyx Gun animations
- Juniez, Shadow_RUN, MTB, MidnightDragons: USP Pistol
- Nekromancer: Stun Baton weapon for Sven Co-op
- Kalimando: Pulse Cannon gun model and texture
- Nexon: Pulse Cannon's handle model and animations
- Albedo: Shotgun HD retexture
- alexd_stark: Crossbow HD retexture
- kalo22: Porting HL2's shotgun, revolver, crossbow, grenade, rpg, slam, gravgun, gauss, muzzleflash effects
- Garompa: Porting models and textures from HL2 and HL2 beta, reanimating, rigging, uv mapping fixes, hud sprites, events, effects and sounds
- D.N.I.O. 071, KernCore: Scope base model and animations from INS2 weapon pack for Sven, Remappable Sven Coop default hands
- D.G.F., R4to0: Scope base model and animations from INS2 weapon pack for Sven
- Norman The Loli Pirate: Scope base model and animations from INS2 weapon pack for Sven, default Sven Co-op hands
- Caldwell, Zeropulse: default Sven Co-op hands

All relevant Half-Life 2 IP used belong to Valve Software. Please do not sue us.
