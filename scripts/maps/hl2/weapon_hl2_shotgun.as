/* SPAS12 - weapon_hl2_shotgun
	This weapon is largely unchanged from HL.
    Primary fire: single shot
    Secondary fire: more powerful "double" shot, uses 2 shells
	Ammo: uses stock ammo_buckshot, 6 in clip, 36 reserve

Part of the SC Half-Life 2 Weapons Pack.
- Outerbeast
*/
#include "weapon_base"

namespace HL2_WEAPONS
{

enum ANIM_SHOTGUN
{
	IDLE1,
	IDLE2,
	IDLE3,
	FIRE1,
	FIRE2,
	ALTFIRE,
	RELOAD_SINGLE,
	RELOAD_END,
	RELOAD_START,
	DRAW,
	HOLSTER,
	PUMP2,
	DRYFIRE
};

const array<float> FL_ANIMTIME_SHOTGUN =
{
	6.73f,
	6.73f,
	6.73f,
	1.00f,
	1.00f,
	1.17f,
	0.47f,
	1.03f,
	0.57f,
	0.8f,
	0.33f,
	0.6f,
	0.4f
};

array<int> I_STATS_SHOTGUN =
{
	2,
	5,
	30,
	-1,
	6,
	int( g_EngineFuncs.CVarGetFloat( "sk_plr_buckshot" ) ), // Damage of Primary Fire ammo
	0
};

array<string>
	STR_SHOTGUN_MODELS =
	{
		"models/w_shotgun.mdl",
		"models/p_shotgun.mdl",
		"models/hl2/v_shotgun.mdl",
		"sprites/hl2/weapon_hl2_shotgun.spr"
	},
	STR_SHOTGUN_SOUNDS =
	{
		"hl2/shotgun_fire1.ogg",
		"hl2/shotgun_fire2.ogg",
		"hl2/shotgun_dbl_fire1.ogg",
		"hl2/shotgun_dbl_fire2.ogg",
		"hl2/shotgun_reload1.ogg",
		"hl2/shotgun_reload2.ogg",
		"hl2/shotgun_reload3.ogg",
		"hl2/shotgun_cock.ogg",
		"hl2/shotgun_empty.ogg"
	};

const string strWeapon_Shotgun = "weapon_hl2_shotgun";

bool RegisterShotgun()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "HL2_WEAPONS::" + strWeapon_Shotgun, strWeapon_Shotgun );
	g_ItemRegistry.RegisterWeapon( strWeapon_Shotgun, "hl2", "buckshot" );

	return g_CustomEntityFuncs.IsCustomEntity( strWeapon_Shotgun );
}

final class weapon_hl2_shotgun: CustomGunBase
{
	private bool blDoubleShot = false;
	private CScheduledFunction @ fnEjectShell;

	weapon_hl2_shotgun()
	{
		strSpriteDir = "hl2";
		m_iShell = g_Game.PrecacheModel( "models/shotgunshell.mdl" );
		strEmptySound = "hl2/shotgun_empty.ogg";
		M_I_STATS = I_STATS_SHOTGUN;
	}

	void Precache()
	{
		PrecacheContent( STR_SHOTGUN_MODELS, STR_SHOTGUN_SOUNDS );
		BaseClass.Precache();
	}

	void Spawn()
	{
		SpawnWeapon( "models/w_shotgun.mdl", M_I_STATS[WpnStatIdx::iMaxClip] * 5 );
		BaseClass.Spawn();
	}

	bool Deploy()
	{
		const bool blDeployed = self.DefaultDeploy( self.GetV_Model( "models/hl2/v_shotgun.mdl" ), self.GetP_Model( "models/p_shotgun.mdl" ), ANIM_SHOTGUN::DRAW, "shotgun" );
		self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_SHOTGUN[ANIM_SHOTGUN::DRAW];

		return blDeployed;
	}

	void Idle()
	{
		const ANIM_SHOTGUN AnimIdle = ANIM_SHOTGUN( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, int( ANIM_SHOTGUN::IDLE1 ), int( ANIM_SHOTGUN::IDLE3 ) ) );
		self.SendWeaponAnim( AnimIdle );
		self.m_flTimeWeaponIdle = g_Engine.time + FL_ANIMTIME_SHOTGUN[AnimIdle];
	}

	bool PreShoot()
	{ // Gun was in the middle of a reload, cancel it.
		if( self.pev.nextthink > 0 )
			StopReloading();

		if( !blDoubleShot || ( blDoubleShot && self.m_iClip < 2 ) )
		{
			blDoubleShot = false;
			--self.m_iClip;
			self.SendWeaponAnim( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, int( ANIM_SHOTGUN::FIRE1 ), int( ANIM_SHOTGUN::FIRE2 ) ) );
		}
		else
		{
			blDoubleShot = true;
			self.m_iClip -= 2;
			self.SendWeaponAnim(ANIM_SHOTGUN::ALTFIRE);
		}

		return true;
	}

	bool PostShoot()
	{
		g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "hl2/shotgun_" + ( blDoubleShot ? "dbl_" : "" ) + "fire2.ogg", 1.0f, ATTN_NORM, 0, 93 + Math.RandomLong( 0, 31 ) );
		MuzzleFlash( RGBA( 255, 200, 180, 8 ) );
		Recoil( Vector( -5, 0, 0 ), blDoubleShot ? 2 : 1 );
		@fnEjectShell = g_Scheduler.SetTimeout( this, "EjectShell", blDoubleShot ? 0.57f : 0.4f );

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType) < 1 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		blDoubleShot = false;

		return false;
	}

	bool IsReloading()
	{
		return self.pev.nextthink > 0;
	}

	void InsertShell()
	{
		if( self.m_iClip < self.iMaxClip() )
		{
			self.SendWeaponAnim( ANIM_SHOTGUN::RELOAD_SINGLE );
			m_pPlayer.SetAnimation( PLAYER_RELOAD );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "hl2/shotgun_reload" + Math.RandomLong( 1, 3 ) + ".ogg", 1.0f, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 31 ) );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_SHOTGUN[ANIM_SHOTGUN::RELOAD_SINGLE];
		}
		else
		{
			StopReloading();
			return;
		}

		DeductPrimaryAmmo();
		++self.m_iClip;
		self.pev.nextthink = g_Engine.time + FL_ANIMTIME_SHOTGUN[ANIM_SHOTGUN::RELOAD_SINGLE];
	}

	void EjectShell()
	{
		EjectCasing( 10.0f, 16.0f, -15.0f, TE_BOUNCE_SHOTSHELL );
	}

	void StopReloading()
	{
		self.SendWeaponAnim( ANIM_SHOTGUN::RELOAD_END );
		self.pev.nextthink = 0;
		SetThink( null );
		self.m_fInReload = false;
		self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_SHOTGUN[ANIM_SHOTGUN::RELOAD_END];
	}

	void PrimaryAttack()
	{
		blDoubleShot = false;

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip < 1 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;

			return;
		}

		Shoot( 7, m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ), Vector( 0.08716f, 0.04362f, 0.00f ), BULLET_PLAYER_BUCKSHOT, 2048.0f );
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + FL_ANIMTIME_SHOTGUN[ANIM_SHOTGUN::FIRE1] + ( self.m_iClip < 1 ? 0.5f : 0.0f );
	}

	void SecondaryAttack() {
		blDoubleShot = self.m_iClip > 1;
		// Only one shell left in the magazine, do normal single shell fire.
		if( !blDoubleShot)
		{
			PrimaryAttack();
			return;
		}

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip < 1 )
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = g_Engine.time + 0.15f;

			return;
		}

		Shoot( 12, m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ), Vector( 0.17365f, 0.04362f, 0.0f ), BULLET_PLAYER_BUCKSHOT, 2048.0f );
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + FL_ANIMTIME_SHOTGUN[ANIM_SHOTGUN::ALTFIRE] + ( self.m_iClip < 1 ? 0.5f : 0.0f );
	}

	void Reload()
	{
		if( IsReloading() || self.m_flNextPrimaryAttack > g_Engine.time || self.m_flNextSecondaryAttack > g_Engine.time )
			return;

		if( self.m_iClip < self.iMaxClip() )
			BaseClass.Reload();
		// Start reloading
		if( !IsReloading() && self.m_iClip < self.iMaxClip() )
		{
			self.SendWeaponAnim( ANIM_SHOTGUN::RELOAD_START );
			SetThink( ThinkFunction( this.InsertShell ) );
			self.pev.nextthink = g_Engine.time + FL_ANIMTIME_SHOTGUN[ANIM_SHOTGUN::RELOAD_SINGLE];
		}
	}
};

}
