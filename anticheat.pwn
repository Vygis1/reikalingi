/*


	=========================================================================
	Server anti-cheat include
	Credits: 
		f0cus
	Thanks:
		Emmet
	=========================================================================


	* NUSTATYMAI:
	--------------------------------------------------------------------------------------------------
	AC_WEAPONS_TIME reikðmë nustato timerio laikà. Rekomenduotina palikti 500-750 tarpe.

	AC_WEAPONS_CHECK_ALWAYS. Jei true, þaidëjo ginklai bus tikrinami nuolatos.
	Kitaip ginklai bus tikrinami tik juos iðsitraukiant/paslepiant ar ðaudant.

	AC_WEAPONS_SKIP_MULTIPLE_BANS.

	ginklø, ammo, airbrk/teleport (onfoot, in vehicle), speedhack, fakedeath, pinigø, gyvybiø hack (maðinø, þaidëjo), playerbugger

	+ Guns & ammo hack
	+ Air-break (onfoot, in vehicle)
	+ Speed hack
	+ Money hack
	+ Vehicle health hack,
	+ Player health hack,
	+ Teleport
	+ Fakekill

*/
 

#if defined _fc_ac_included
	#endinput
#endif
#define _fc_ac_included
#if !defined IsValidVehicle
    native IsValidVehicle(vehicleid);
#endif

#define AC_playerloop(%0) 					for(new %0 = 0, __player_limit = GetPlayerPoolSize(); %0 <= __player_limit; %0++) 		// foreach(new vehicleid : Vehicle) arba foreach(Vehicle, vehicleid)
#define AC_vehicleloop(%0)					for(new %0 = 1, __vehicle_limit = GetVehiclePoolSize(); %0 <= __vehicle_limit; %0++)	// foreach(new playerid : Player) arba foreach(Player, playerid)

// Nustatymai
#define AC_WEAPONS_TIME 					500 	
#define AC_MONEY_TIME 						250 	
#define AC_AIRBREAK_TIME 					800 
#define AC_HEALTH_TIME 						900
#define AC_SPEED_TIME 						250
#define AC_MISC_TIME 						1000

#if !defined AC_ENABLE_WEAPONS 
	#define AC_ENABLE_WEAPONS 					true
#endif
#if !defined AC_ENABLE_MONEY
	#define AC_ENABLE_MONEY 					true
#endif
#if !defined AC_ENABLE_AIRBREAK
	#define AC_ENABLE_AIRBREAK 					true
#endif
#if !defined AC_ENABLE_HEALTH
	#define AC_ENABLE_HEALTH 					true
#endif
#if !defined AC_ENABLE_SPEED
	#define AC_ENABLE_SPEED 					true
#endif
#if !defined AC_ENABLE_INV
	#define AC_ENABLE_INV 						true
#endif
#if !defined AC_ENABLE_JETPACK
	#define AC_ENABLE_JETPACK 					true
#endif

#define AC_WEAPONS_CHECK_ALWAYS 		 	true
#define AC_WEAPONS_SKIP_MULTIPLE_BANS 		true
#define AC_AIRBREAK_MAX_WARNINGS 			3
#define AC_FAKE_KILL_MAX_WARNINGS 			3
#define AC_INV_MAX_WARNINGS 				6

// Forwards
forward OnPlayerWeaponCheat(playerid, weaponid, ammo);
forward OnPlayerMoneyCheat(playerid, amount);
forward OnPlayerAirbreak(playerid);
forward OnPlayerVehicleHealthCheat(playerid, vehicleid);
forward OnPlayerSpeedCheat(playerid, vehicleid);
forward OnPlayerFakeKillCheat(playerid);
forward OnPlayerInvulnerable(playerid);
forward OnPlayerHealthCheat(playerid);
forward OnPlayerArmourCheat(playerid);
forward OnPlayerJetpackCheat(playerid);

// Local forwards
forward FAC_OnPlayerWeaponChanged(playerid, newweapon, oldweapon);
forward FAC_CheckPause(playerid);

// Kintamieji
enum E_AC_WEAPONS
{
	e_ac_WeaponId,
	e_ac_WeaponAmmo
};

enum E_AC_AIRBREAK
{
	Float:e_ac_AirBrkX,
	Float:e_ac_AirBrkY,
	Float:e_ac_AirBrkZ,
	e_ac_AirBrkIgnore,
	e_ac_AirBrkDetected,
	e_ac_AirBrkLast
};

static 
	ac__PlayerWeapons[MAX_PLAYERS][13][E_AC_WEAPONS],
	ac__LastWeapon[MAX_PLAYERS],
	ac__PlayerIgnoreWeaponAC[MAX_PLAYERS],
	
	ac__PlayerMoney[MAX_PLAYERS],

	ac__AirBreak[MAX_PLAYERS][E_AC_AIRBREAK],

	ac__LastDeath[MAX_PLAYERS],
	ac__DeathSpam[MAX_PLAYERS],

	bool:ac__UsingJetpack[MAX_PLAYERS char],
	bool:ac__JetpackGiven[MAX_PLAYERS char],

	bool:ac__Spawned[MAX_PLAYERS char],
	bool:ac__Afk[MAX_PLAYERS char],
	ac__InvWarnings[MAX_PLAYERS],
	ac__AfkCount[MAX_PLAYERS],

	Float:ac__VehicleHealth[MAX_VEHICLES],
	Float:ac__PlayerHealth[MAX_PLAYERS],
	Float:ac__PlayerArmour[MAX_PLAYERS],
	Float:ac__LastHit[MAX_PLAYERS];

static const
	ac__TopSpeeds[212] = {157, 147, 186, 110, 133, 164, 110, 148, 100, 158, 129, 221, 168, 110, 105, 192, 154, 270,
   115, 149, 145, 154, 140, 99, 135, 270, 173, 165, 157, 201, 190, 130, 94, 110, 167, 0, 149,
   158, 142, 168, 136, 145, 139, 126, 110, 164, 270, 270, 111, 0, 0, 193, 270, 60, 135, 157,
   106, 95, 157, 136, 270, 160, 111, 142, 145, 145, 147, 140, 144, 270, 157, 110, 190, 190,
   149, 173, 270, 186, 117, 140, 184, 73, 156, 122, 190, 99, 64, 270, 270, 139, 157, 149, 140,
   270, 214, 176, 162, 270, 108, 123, 140, 145, 216, 216, 173, 140, 179, 166, 108, 79, 101, 270,
   270, 270, 120, 142, 157, 157, 164, 270, 270, 160, 176, 151, 130, 160, 158, 149, 176, 149, 60,
   70, 110, 167, 168, 158, 173, 0, 0, 270, 149, 203, 164, 151, 150, 147, 149, 142, 270, 153, 145,
   157, 121, 270, 144, 158, 113, 113, 156, 178, 169, 154, 178, 270, 145, 165, 160, 173, 146, 0, 0,
   93, 60, 110, 60, 158, 158, 270, 130, 158, 153, 151, 136, 85, 0, 153, 142, 165, 108, 162, 0, 0,
   270, 270, 130, 190, 175, 175, 175, 158, 151, 110, 169, 171, 148, 152, 0, 0, 0, 108, 0};

public OnGameModeInit()
{
	/* 
		Timeriai yra (repeat = false), taip isitikinsim, kad padarem viska ka reikejo ir naujas timeris neveiktu, kol nesibaige sitas. 
	*/
	#if AC_ENABLE_WEAPONS == true
		SetTimer("t_ac__WeaponsTimer", AC_WEAPONS_TIME, false);
	#endif

	#if AC_ENABLE_MONEY == true
		SetTimer("t_ac__MoneyTimer", AC_MONEY_TIME, false);
	#endif

	#if AC_ENABLE_AIRBREAK == true
		SetTimer("t_ac__AirBreak", AC_AIRBREAK_TIME, false);
	#endif

	#if AC_ENABLE_HEALTH == true
		SetTimer("t_ac__Health", AC_HEALTH_TIME, false);
	#endif

	#if AC_ENABLE_SPEED == true
		SetTimer("t_ac__Speed", AC_SPEED_TIME, false);
	#endif

	#if AC_ENABLE_JETPACK == true 
		SetTimer("t_ac__Misc", AC_ENABLE_JETPACK, false);
	#endif

	SetTimer("t_ac__CheckPause", 5000, false);

	return ((funcidx("FAC_OnGameModeInit") != -1) ? CallLocalFunction("FAC_OnGameModeInit", "") : 1);
}

public OnPlayerConnect(playerid)
{
	FAC_ResetPlayerWeapons(playerid);
	FAC_ResetPlayerMoney(playerid);
	new 
		reset__AirBreak[E_AC_AIRBREAK];
	ac__AirBreak[playerid] = reset__AirBreak;
	ac__PlayerIgnoreWeaponAC[playerid] =
	ac__LastDeath[playerid] =
	ac__AfkCount[playerid] = 
	ac__InvWarnings[playerid] = 
	ac__DeathSpam[playerid] = 0;
	ac__PlayerHealth[playerid] = 100.0;
	ac__PlayerArmour[playerid] = 
	ac__LastHit[playerid] = 0.0;
	ac__UsingJetpack{playerid} = 
	ac__JetpackGiven{playerid} = 
	ac__Spawned{playerid} = 
	ac__Afk{playerid} = false;
	return ((funcidx("FAC_OnPlayerConnect") != -1) ? CallLocalFunction("FAC_OnPlayerConnect", "d", playerid) : 1);
}

forward t_ac__Misc();
public t_ac__Misc()
{
	#if AC_ENABLE_JETPACK == true
		AC_playerloop(playerid)
		{
			if(!ac__UsingJetpack{playerid} && GetPlayerSpecialAction(playerid) == 2)
			{
				if(!ac__JetpackGiven{playerid}) 
				{
					SetPlayerSpecialAction(playerid, 0);
					(funcidx("OnPlayerJetpackCheat") != -1) && CallLocalFunction("OnPlayerJetpackCheat", "d", playerid);
					continue;
				}
				else
				{
					ac__UsingJetpack{playerid} = true;
				}
			}
			else if(ac__UsingJetpack{playerid} && GetPlayerSpecialAction(playerid) != 2) 
			{
				ac__UsingJetpack{playerid} = false;
				//if(ac__JetpackGiven{playerid}) ac__JetpackGiven{playerid} = false;
				/*new 
					Float:_x, Float:_y, Float:_z;

				zaidejui islipus is jetpack jis lieka kaip pickup. Paemus ji antra karta, rodys kaip cheateri.

				ClearAnimations(playerid);
				GetPlayerPos(playerid, _x, _y, _z);
				SetPlayerPos(playerid, _x, _y, _z);
				SetPlayerSpecialAction(playerid, 0);*/
			}
		}	
	#endif
	return SetTimer("t_ac__Misc", AC_MISC_TIME, false);
}

stock FAC_SetPlayerSpecialAction(playerid, action)
{
	if(action == 2)	ac__JetpackGiven{playerid} = true;
	else if(action != 2) ac__JetpackGiven{playerid} = false;
	return SetPlayerSpecialAction(playerid, action);
}

forward t_ac__CheckPause();
public t_ac__CheckPause()
{
	AC_playerloop(playerid)
	{
		if(ac__AfkCount[playerid] >= 3 && !ac__Afk{playerid})
		{
			ac__Afk{playerid} = true;
		}
		else if(ac__AfkCount[playerid] < 3 && ac__Afk{playerid})
		{
			ac__Afk{playerid} = false;
		}
		ac__AfkCount[playerid] ++ ;
	}
	return SetTimer("t_ac__CheckPause", 5000, false);
}

public OnVehicleSpawn(vehicleid)
{
	return ((funcidx("FAC_OnVehicleSpawn") != -1) ? CallLocalFunction("FAC_OnVehicleSpawn", "d", vehicleid) : 1);
}

forward t_ac__Speed();
public t_ac__Speed()
{
	AC_vehicleloop(vehicleid)
	{
		if(!IsValidVehicle(vehicleid)) continue;
		new 
			speed = FAC_VehicleSpeed(vehicleid),
			model;
		if(400 <= (model = GetVehicleModel(vehicleid)) <= 611)
		{
			new 
				topspeed = ac__TopSpeeds[model-400];
			if(topspeed + 25 >= 260) { continue; }
			else if(speed > topspeed + 20 || speed > topspeed * 2)
			{
				AC_playerloop(playerid)
				{
					if(IsPlayerInVehicle(playerid, vehicleid) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
					{
						(funcidx("OnPlayerSpeedCheat") != -1) && CallLocalFunction("OnPlayerSpeedCheat", "dd", playerid, vehicleid);
					}
				}
			}
		}
	}
	SetTimer("t_ac__Speed", AC_SPEED_TIME, false);
	return 1;
}

forward t_ac__Health();
public t_ac__Health()
{
	AC_playerloop(playerid)
	{
		if(!IsPlayerConnected(playerid) || !ac__Spawned{playerid}) continue;
		if(!ac__Afk{playerid})
		{
			FAC_CheckPlayerHealth(playerid);
		}
	}
	AC_vehicleloop(vehicleid)
	{
		if(!IsValidVehicle(vehicleid)) continue;
		FAC_CheckVehicleHealth(vehicleid);
	}
	SetTimer("t_ac__Health", AC_HEALTH_TIME, false);
	return 1;
}

public OnPlayerUpdate(playerid)
{
	ac__AfkCount[playerid] = 0;
	return ((funcidx("FAC_OnPlayerUpdate") != -1) && CallLocalFunction("FAC_OnPlayerUpdate", "d", playerid));
}


public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if((newstate != PLAYER_STATE_DRIVER && newstate != PLAYER_STATE_PASSENGER) && (oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER))
	{
		ac__AirBreak[playerid][e_ac_AirBrkIgnore] = gettime() + 2;
	}
	return ((funcidx("FAC_OnPlayerStateChange") != -1) && CallLocalFunction("FAC_OnPlayerStateChange", "ddd", playerid, newstate, oldstate));
}

public OnPlayerDeath(playerid, killerid, reason)
{
	new 
		time = gettime();
	if(0 <= time - ac__LastDeath[playerid] <= 3)
	{
		ac__DeathSpam[playerid] ++;
		if(ac__DeathSpam[playerid] >= AC_FAKE_KILL_MAX_WARNINGS)
		{
			(funcidx("OnPlayerFakeKillCheat") != -1 && CallLocalFunction("OnPlayerFakeKillCheat", "d", playerid));
		}
	}
	else ac__DeathSpam[playerid] = 0;
	ac__LastDeath[playerid] = time;
	return ((funcidx("FAC_OnPlayerDeath") != -1) && CallLocalFunction("FAC_OnPlayerDeath", "ddd", playerid, killerid, reason));
}

public OnPlayerSpawn(playerid)
{
	ac__PlayerHealth[playerid] = 100.0;
	ac__PlayerArmour[playerid] = 0.0;
	ac__InvWarnings[playerid] = 0;
	ac__Spawned{playerid} = true;
	return ((funcidx("FAC_OnPlayerSpawn") != -1) && CallLocalFunction("FAC_OnPlayerSpawn", "d", playerid));
}

stock FAC_SetPlayerHealth(playerid, Float:health)
{
	if(health >= 0.0)
	{
		ac__PlayerHealth[playerid] = health;
		return SetPlayerHealth(playerid, health);
	}
	return false;
}

stock FAC_SetPlayerArmour(playerid, Float:armour)
{
	if(armour >= 0.0)
	{
		ac__PlayerArmour[playerid] = armour;
		return SetPlayerArmour(playerid, armour);
	}
	return false;
}

stock FAC_GetPlayerHealth(playerid, &Float:health)
{
	health = ac__PlayerHealth[playerid];
	return 1;
}

stock FAC_GetPlayerArmour(playerid, &Float:armour)
{
	armour = ac__PlayerArmour[playerid];
	return 1;
}

stock FAC_CheckPlayerHealth(playerid)
{
	new 
		Float:health,
		Float:armour;
	GetPlayerHealth(playerid, health);
	GetPlayerArmour(playerid, armour);
	if(floatround(health, floatround_floor) > floatround(ac__PlayerHealth[playerid]))
	{
		SetPlayerHealth(playerid, ac__PlayerHealth[playerid]);
		return (funcidx("OnPlayerHealthCheat") != -1 && CallLocalFunction("OnPlayerHealthCheat", "d", playerid));
	}
	else
	{
		ac__PlayerHealth[playerid] = health;
	}
	if(floatround(armour, floatround_floor) > floatround(ac__PlayerArmour[playerid]))
	{
		SetPlayerArmour(playerid, ac__PlayerArmour[playerid]);
		return (funcidx("OnPlayerArmourCheat") != -1 && CallLocalFunction("OnPlayerArmourCheat", "d", playerid));
	}
	else
	{
		ac__PlayerArmour[playerid] = armour;
	}
	return 1;
}

stock FAC_CheckVehicleHealth(vehicleid)
{
	new 
		Float:health;
	GetVehicleHealth(vehicleid, health);
	if(health > ac__VehicleHealth[vehicleid])
	{
		SetVehicleHealth(vehicleid, ac__VehicleHealth[vehicleid]);
		AC_playerloop(playerid)
		{
			if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER && IsPlayerInVehicle(playerid, vehicleid))
			{
				(funcidx("OnPlayerVehicleHealthCheat") != -1) && CallLocalFunction("OnPlayerVehicleHealthCheat", "dd", playerid, vehicleid);
				break;
			}
		}
	}
	else if(ac__VehicleHealth[vehicleid] > health)
	{
		ac__VehicleHealth[vehicleid] = health;
	}
	return 1;
}

stock FAC_RepairVehicle(vehicleid)
{
	ac__VehicleHealth[vehicleid] = 1000.0;
	return RepairVehicle(vehicleid);
}

stock FAC_SetVehicleHealth(vehicleid, Float:health)
{
	ac__VehicleHealth[vehicleid] = health;
	return SetVehicleHealth(vehicleid, health);
}

forward t_ac__WeaponsTimer();
public t_ac__WeaponsTimer()
{
	new 
		playerWeapon;
	AC_playerloop(playerid)
	{
		if(!IsPlayerConnected(playerid)) continue; 
		if(ac__PlayerIgnoreWeaponAC[playerid] > 0)
		{
			ac__PlayerIgnoreWeaponAC[playerid] -- ;
			if(ac__PlayerIgnoreWeaponAC[playerid] > 0) continue; 
		}
		#if AC_WEAPONS_CHECK_ALWAYS == true
			#pragma unused playerWeapon
			for(new slot = 0; slot < 13; slot++)
			{
				if(FAC_CheckWeaponCheat(playerid, slot, true))
				{
					#if AC_WEAPONS_SKIP_MULTIPLE_BANS == true
						break; // cheata radom, breakinam, kad nespamintu apie tolimesnisu cheatintus ginklus.
					#endif
				}
			}
		#else
			if((playerWeapon = GetPlayerWeapon(playerid)) != ac__LastWeapon[playerid])
			{
				FAC_OnPlayerWeaponChanged(playerid, playerWeapon, ac__LastWeapon[playerid]);
			}
		#endif
	}
	SetTimer("t_ac__WeaponsTimer", AC_WEAPONS_TIME, false);
	return 1;
}

public FAC_OnPlayerWeaponChanged(playerid, newweapon, oldweapon)
{
	if(newweapon != 0) FAC_CheckWeaponCheat(playerid, newweapon, false);
	else if(oldweapon != 0)
	{
		new 
			slot;
		if((slot = FAC_GetWeaponSlot(oldweapon)) != 0xFFFF)
		{
			new 
				l_data[2];
			GetPlayerWeaponData(playerid, slot, l_data[0], l_data[1]);
			if(l_data[0] <= 0)
			{
				FAC_ResetPlayerWeaponSlotData(playerid, slot);
			}
			else
			{
				FAC_CheckWeaponCheat(playerid, slot, true);
			}
		}
	}
	ac__LastWeapon[playerid] = newweapon;
	return 1;
}

stock FAC_CheckWeaponCheat(playerid, id, bool:byslot)
{
	new 
		slot;
	if(((slot = id) && byslot) || (((slot = FAC_GetWeaponSlot(id)) != 0xFFFF) && !byslot))
	{
		new 
			l_data[2];
		GetPlayerWeaponData(playerid, slot, l_data[0], l_data[1]);
		if((ac__PlayerWeapons[playerid][slot][e_ac_WeaponId] != l_data[0] && l_data[0] != 0) || (ac__PlayerWeapons[playerid][slot][e_ac_WeaponAmmo] < l_data[1] && l_data[1] > 0))
		{
			ac__PlayerIgnoreWeaponAC[playerid] = 4;
			FAC_ResetPlayerWeapons(playerid);
			(funcidx("OnPlayerWeaponCheat") != -1) && CallLocalFunction("OnPlayerWeaponCheat", "ddd", playerid, l_data[0], l_data[1]);
			return true;
		}
	}
	return false;
}

stock FAC_ResetPlayerWeaponSlotData(playerid, slot)
{
	new 
		reset[E_AC_WEAPONS];
	return (ac__PlayerWeapons[playerid][slot] = reset);
}

stock FAC_ResetPlayerWeapons(playerid)
{
	new 
		reset[E_AC_WEAPONS];
	for(new slot = 0; slot < 13; slot++)
	{
		ac__PlayerWeapons[playerid][slot] = reset;
	}
	return ResetPlayerWeapons(playerid);
}

stock FAC_GetWeaponSlot(weaponid)
{
	switch(weaponid) 
    { 
        case 1: return 0; 
        case 2..9: return 1; 
        case 22..24: return 2; 
        case 25..27: return 3; 
        case 28, 29, 32: return 4; 
        case 30, 31: return 5; 
        case 33, 34: return 6; 
        case 35..38: return 7; 
        case 16..18, 39: return 8; 
        case 41..43: return 9; 
        case 10..15: return 10; 
        case 44..46: return 11; 
        case 40: return 12; 
    } 
    return 0xFFFF; 
}

stock FAC_GivePlayerWeapon(playerid, weaponid, ammo)
{
	new 
		slot;
	if((slot = FAC_GetWeaponSlot(weaponid)) != 0xFFFF)
	{	
		if(ac__PlayerWeapons[playerid][slot][e_ac_WeaponId] == weaponid)
		{
			if(ac__PlayerWeapons[playerid][slot][e_ac_WeaponAmmo] >= 0)
			{
				ac__PlayerWeapons[playerid][slot][e_ac_WeaponAmmo] += ammo;
			}
			else ac__PlayerWeapons[playerid][slot][e_ac_WeaponAmmo] = ammo;
		}
		else
		{
			ac__PlayerWeapons[playerid][slot][e_ac_WeaponId] = weaponid;
			ac__PlayerWeapons[playerid][slot][e_ac_WeaponAmmo] = ammo;
		}
		return GivePlayerWeapon(playerid, weaponid, ammo);
	}
	return false;
}

forward t_ac__MoneyTimer();
public t_ac__MoneyTimer()
{
	AC_playerloop(playerid)
	{
		if(GetPlayerMoney(playerid) > ac__PlayerMoney[playerid])
		{
			(funcidx("OnPlayerMoneyCheat") != -1) && CallLocalFunction("OnPlayerMoneyCheat", "dd", playerid, GetPlayerMoney(playerid) - ac__PlayerMoney[playerid]);
			ResetPlayerMoney(playerid);
			GivePlayerMoney(playerid, ac__PlayerMoney[playerid]);
		}
	}
	SetTimer("t_ac__MoneyTimer", AC_MONEY_TIME, false);
	return 1;
}

stock FAC_ResetPlayerMoney(playerid)
{
	ac__PlayerMoney[playerid] = 0;
	return ResetPlayerMoney(playerid);
}

stock FAC_GetPlayerMoney(playerid)
{
	return ac__PlayerMoney[playerid];
}

stock FAC_GivePlayerMoney(playerid, amount)
{
	ac__PlayerMoney[playerid] += amount;
	return GivePlayerMoney(playerid, amount);
}

stock FAC_SetPlayerPos(playerid, Float:x, Float:y, Float:z)
{
	ac__AirBreak[playerid][e_ac_AirBrkIgnore] = gettime() + 3;
	return SetPlayerPos(playerid, x, y, z);
}

forward t_ac__AirBreak();
public t_ac__AirBreak()
{
	new 
		vehicleid,
		playerstate,
		Float:x, 
		Float:y,
		Float:z,
		Float:distance;
	AC_playerloop(playerid)
	{
		if(!IsPlayerConnected(playerid)) continue;
		GetPlayerPos(playerid, x, y, z);
		if(x > 0xdbb9f || y > 0xdbb9f || z > 0xdbb9f)
		{
			SetPlayerPos(playerid, ac__AirBreak[playerid][e_ac_AirBrkX], ac__AirBreak[playerid][e_ac_AirBrkY], ac__AirBreak[playerid][e_ac_AirBrkZ]);
		}
		else if(gettime() > ac__AirBreak[playerid][e_ac_AirBrkIgnore] && GetPlayerSurfingVehicleID(playerid) == INVALID_VEHICLE_ID && GetPlayerSurfingObjectID(playerid) == INVALID_OBJECT_ID && GetPlayerSpecialAction(playerid) != SPECIAL_ACTION_ENTER_VEHICLE && GetPlayerSpecialAction(playerid) != SPECIAL_ACTION_EXIT_VEHICLE)
		{
			vehicleid = GetPlayerVehicleID(playerid);
			switch((playerstate = GetPlayerState(playerid)))
			{
				case PLAYER_STATE_ONFOOT:
				{
					distance = GetPlayerDistanceFromPoint(playerid, ac__AirBreak[playerid][e_ac_AirBrkX], ac__AirBreak[playerid][e_ac_AirBrkY], ac__AirBreak[playerid][e_ac_AirBrkZ]);
					GetPlayerPos(playerid, x, y, z);
					if((floatabs(ac__AirBreak[playerid][e_ac_AirBrkZ] - z) < 15.0 && floatabs(distance) >= 20.0) && 
						(floatabs(ac__AirBreak[playerid][e_ac_AirBrkX] - x) >= 20.0 || floatabs(ac__AirBreak[playerid][e_ac_AirBrkY] - y) >= 20.0)) FAC_Airbreak(playerid);
				}
				case PLAYER_STATE_DRIVER:
				{
					distance = GetVehicleDistanceFromPoint(vehicleid, ac__AirBreak[playerid][e_ac_AirBrkX], ac__AirBreak[playerid][e_ac_AirBrkY], ac__AirBreak[playerid][e_ac_AirBrkZ]);
					GetVehiclePos(vehicleid, x, y, z);
					if((!FAC_IsVehicleMoving(vehicleid) && floatabs(distance) >= 20.0) &&
						(floatabs(ac__AirBreak[playerid][e_ac_AirBrkX] - x) >= 20.0 || floatabs(ac__AirBreak[playerid][e_ac_AirBrkY] - y) >= 20.0)) FAC_Airbreak(playerid);
				}
			}
		}
		switch(playerstate)
		{
			case PLAYER_STATE_ONFOOT:
			{
				GetPlayerPos(playerid, ac__AirBreak[playerid][e_ac_AirBrkX], ac__AirBreak[playerid][e_ac_AirBrkY], ac__AirBreak[playerid][e_ac_AirBrkZ]);
			}
			case PLAYER_STATE_DRIVER:
			{
				GetVehiclePos(vehicleid, ac__AirBreak[playerid][e_ac_AirBrkX], ac__AirBreak[playerid][e_ac_AirBrkY], ac__AirBreak[playerid][e_ac_AirBrkZ]);
			}
		}
	}	
	SetTimer("t_ac__AirBreak", AC_AIRBREAK_TIME, false);
	return 1;
}

stock FAC_Airbreak(playerid)
{
	new 
		time = gettime();
	if((ac__AirBreak[playerid][e_ac_AirBrkDetected]++) >= AC_AIRBREAK_MAX_WARNINGS && (time - ac__AirBreak[playerid][e_ac_AirBrkLast]) < 30)
	{
		(funcidx("OnPlayerAirbreak") != -1) && CallLocalFunction("OnPlayerAirbreak", "d", playerid);
		ac__AirBreak[playerid][e_ac_AirBrkIgnore] = gettime() + 3;
	}
	ac__AirBreak[playerid][e_ac_AirBrkLast] = time;
	return 1;
}

stock FAC_IsVehicleMoving(vehicleid)
{
	// Emmet
	new
	    Float:x,
	    Float:y,
	    Float:z;
	GetVehicleVelocity(vehicleid, x, y, z);
	return (!(floatabs(x) <= 0.001 && floatabs(y) <= 0.001 && floatabs(z) <= 0.005));
}

stock FAC_VehicleSpeed(vehicleid)
{
	static 
		Float:Vx,
		Float:Vy,
		Float:Vz
	;
	GetVehicleVelocity(vehicleid, Vx, Vy, Vz);
	return floatround((floatsqroot((Vx * Vx) + (Vy * Vy) + (Vz * Vz)) * 136.666667));
}

// Rehooks
// Callbacks
#if defined _ALS_OnGameModeInit
    #undef OnGameModeInit
#else
    #define _ALS_OnGameModeInit
#endif
#define OnGameModeInit FAC_OnGameModeInit
forward FAC_OnGameModeInit();

#if defined _ALS_OnPlayerConnect
    #undef OnPlayerConnect
#else
    #define _ALS_OnPlayerConnect
#endif
#define OnPlayerConnect FAC_OnPlayerConnect
forward FAC_OnPlayerConnect(playerid);

#if defined _ALS_OnVehicleSpawn
	#undef OnVehicleSpawn
#else
	#define _ALS_OnVehicleSpawn
#endif
#define OnVehicleSpawn FAC_OnVehicleSpawn
forward FAC_OnVehicleSpawn(vehicleid);

#if defined _ALS_OnPlayerDeath
	#undef OnPlayerDeath
#else
	#define _ALS_OnPlayerDeath
#endif
#define OnPlayerDeath FAC_OnPlayerDeath
forward FAC_OnPlayerDeath(playerid, killerid, reason);

#if defined _ALS_OnPlayerStateChange
	#undef OnPlayerStateChange
#else
	#define _ALS_OnPlayerStateChange
#endif
#define OnPlayerStateChange FAC_OnPlayerStateChange
forward FAC_OnPlayerStateChange(playerid, newstate, oldstate);

#if defined _ALS_OnPlayerSpawn
	#undef OnPlayerSpawn
#else
	#define _ALS_OnPlayerSpawn
#endif
#define OnPlayerSpawn FAC_OnPlayerSpawn
forward FAC_OnPlayerSpawn(playerid);

#if defined _ALS_OnPlayerGiveDamage
	#undef OnPlayerGiveDamage
#else
	#define _ALS_OnPlayerGiveDamage
#endif
#define OnPlayerGiveDamage FAC_OnPlayerGiveDamage
forward FAC_OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid);

#if defined _ALS_OnPlayerUpdate
	#undef OnPlayerUpdate
#else
	#define _ALS_OnPlayerUpdate
#endif
#define OnPlayerUpdate FAC_OnPlayerUpdate
forward OnPlayerUpdate(playerid);

// Functions
#if defined _ALS_GivePlayerWeapon 
	#undef GivePlayerWeapon
#else
	#define _ALS_GivePlayerWeapon
#endif
#define GivePlayerWeapon FAC_GivePlayerWeapon

#if defined _ALS_ResetPlayerWeapons
	#undef ResetPlayerWeapons
#else
	#define _ALS_ResetPlayerWeapons
#endif
#define ResetPlayerWeapons FAC_ResetPlayerWeapons

#if defined _ALS_ResetPlayerMoney
	#undef ResetPlayerMoney
#else
	#define _ALS_ResetPlayerMoney
#endif
#define ResetPlayerMoney FAC_ResetPlayerMoney

#if defined _ALS_GivePlayerMoney
	#undef GivePlayerMoney
#else
	#define _ALS_GivePlayerMoney
#endif
#define GivePlayerMoney FAC_GivePlayerMoney

#if defined _ALS_GetPlayerMoney
	#undef GetPlayerMoney
#else
	#define _ALS_GetPlayerMoney
#endif
#define GetPlayerMoney FAC_GetPlayerMoney


#if defined _ALS_RepairVehicle
	#undef RepairVehicle
#else
	#define _ALS_RepairVehicle
#endif
#define RepairVehicle FAC_RepairVehicle	

#if defined _ALS_SetVehicleHealth
	#undef SetVehicleHealth
#else
	#define _ALS_SetVehicleHealth
#endif
#define SetVehicleHealth FAC_SetVehicleHealth

#if defined _ALS_SetPlayerHealth
	#undef SetPlayerHealth
#else
	#define _ALS_SetPlayerHealth
#endif
#define SetPlayerHealth FAC_SetPlayerHealth

#if defined _ALS_SetPlayerArmour
	#undef SetPlayerArmour
#else
	#define _ALS_SetPlayerArmour
#endif
#define SetPlayerArmour FAC_SetPlayerArmour

#if defined _ALS_GetPlayerHealth
	#undef GetPlayerHealth
#else
	#define _ALS_GetPlayerHealth
#endif
#define GetPlayerHealth FAC_GetPlayerHealth

#if defined _ALS_GetPlayerArmour
	#undef GetPlayerArmour
#else
	#define _ALS_GetPlayerArmour
#endif
#define GetPlayerArmour FAC_GetPlayerArmour

#if defined _ALS_SetPlayerSpecialAction
	#undef SetPlayerSpecialAction
#else 
	#define _ALS_SetPlayerSpecialAction
#endif
#define SetPlayerSpecialAction FAC_SetPlayerSpecialAction

#if defined _ALS_SetPlayerPos 
	#undef SetPlayerPos 
#else 
	#define _ALS_SetPlayerPos
#endif
#define SetPlayerPos FAC_SetPlayerPos

#undef AC_playerloop
#undef AC_vehicleloop
