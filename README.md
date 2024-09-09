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
- Stun Stick
- Frag Grenade
- Gravity Gun
- USP Pistol
- Alyx's Gun
- 357 Colt Python
- MP7 Submachine Gun
- SPAS12 Shotgun
- OICW
- AR2 Pulse Rifle
- Crossbow
- Overwatch Sniper Rifle
- Pulse Cannon

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
    If the map doesn't have a map script, simply create one, name it, and stick the above code into that script file, then add `map_script <your_script_name_here>` to four map's CFG file.

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
