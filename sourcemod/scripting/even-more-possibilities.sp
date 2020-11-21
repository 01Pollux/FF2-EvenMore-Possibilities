
#undef REQUIRE_PLUGIN
#tryinclude <dhooks>
#define REQUIRE_PLUGIN
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>

#pragma semicolon 1
#pragma newdecls required


#undef REQUIRE_PLUGIN
#tryinclude "possibilities/infinite_scatterpush.sp"
#tryinclude "possibilities/medic_necromancy.sp"
#tryinclude "possibilities/demo_newshield.sp"
#tryinclude "possibilities/revive_marker.sp"
#tryinclude "possibilities/classes_regen.sp"
#tryinclude "possibilities/teleporting_jarate.sp"
#define REQUIRE_PLUGIN

FF2GameMode ff2_gm;

public Plugin myinfo = 
{
	name			= "[FF2] Even More Possibilities",
	author		= "[01]Pollux.",
	version		= "1.1",
	url 			= "go-away.net"
};

public void OnPluginStart()
{
	StartConfig();
}

public void OnLibraryAdded(const char[] lib_name)
{
	if(!strcmp(lib_name, "VSH2"))
	{
#if defined DEMO_NEWSHIELD
		VSH2_Hook(OnBossDealDamage_OnHitShield, _OnHitShield);
#endif
		HookEvent("player_death", Pre_PlayerDeath, EventHookMode_Pre);
		HookEvent("player_spawn", Post_PlayerSpawn, EventHookMode_Post);
		HookEvent("arena_round_start", Post_RoundStart, EventHookMode_PostNoCopy);
		HookEvent("arena_win_panel", Post_RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("player_changeclass", Post_PlayerChangeClass);
	}
}

public void OnLibraryRemoved(const char[] lib_name)
{
	if(!strcmp(lib_name, "VSH2"))
	{
#if defined DEMO_NEWSHIELD
		VSH2_Unhook(OnBossDealDamage_OnHitShield, _OnHitShield);
#endif
		UnhookEvent("player_death", Pre_PlayerDeath, EventHookMode_Pre);
		UnhookEvent("player_spawn", Post_PlayerSpawn, EventHookMode_Post);
		UnhookEvent("arena_round_start", Post_RoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("arena_win_panel", Post_RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("player_changeclass", Post_PlayerChangeClass);
	}
}

static void StartConfig()
{
	GameData Config = new GameData("unlimited");
	
	if(!Config)
	{
		SetFailState("[GameData] how do u expect it to work without \"unlimited.txt\"?");
		return;
	}
	
#if defined FAN_FORCE_SCATTER
	if(!FaN_PrepareConfig(Config))
	{
		delete Config;
		SetFailState("[GameData] Failed to Load \"infinite_scatterpush.sp\"");
		return;
	}
#endif

#if defined MEDIC_NECROMANCY
	if(!Necro_PrepareConfig())
	{
		delete Config;
		SetFailState("[FF2] Failed to Load \"medic_necromancy.sp\"");
		return;
	}
#endif

#if defined DEMO_NEWSHIELD
	if(!NewShield_PrepareConfig(Config))
	{
		delete Config;
		SetFailState("[GameData] Failed to Load \"demo_newshield.sp\"");
		return;
	}
#endif

#if defined MARKER_DROPMERC
	if(!Marker_PrepareConfig(Config))
	{
		delete Config;
		SetFailState("[GameData] Failed to Load \"revive_marker.sp\"");
		return;
	}
#endif

#if defined CLASSES_REGEN
	if(!Regen_PrepareConfig(Config))
	{
		delete Config;
		SetFailState("[GameData] Failed to Load \"classes_regen.sp\"");
		return;
	}
#endif

#if defined TELEPORTING_JARATE
	if(!Teleport_PrepareConfig(Config))
	{
		delete Config;
		SetFailState("[GameData] Failed to Load \"teleporting_jarate.sp\"");
		return;
	}
#endif

	delete Config;
}

public void OnMapStart()
{
#if defined MEDIC_NECROMANCY
	Minions.Clear();
#endif
}

public void Post_RoundStart(Event hEvent, const char[] Name, bool broadcast)
{
	if(!RoundIsActive())
		return;
	
#if defined MARKER_DROPMERC
	for (int x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x))
			continue;
		Revives[x] = 0;
	}
#endif
}

public void Post_RoundEnd(Event event, const char[] Name, bool broadcast)
{
#if defined MEDIC_NECROMANCY
	Minions.Clear();
#endif
}

public void Post_PlayerChangeClass(Event hEvent, const char[] Name, bool broadcast)
{
	if(!RoundIsActive())
		return;
	
	FF2Player player = FF2Player(hEvent.GetInt("userid"), true);
	
#if defined DEMO_NEWSHIELD
	Shield_UnhookClient(player);
#endif
}

public void Post_PlayerSpawn(Event hEvent, const char[] Name, bool broadcast)
{
	if(!RoundIsActive())
		return;
	
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	
#if defined MARKER_DROPMERC
	Marker_PlayerSpawn(client);
#endif
}

public void Pre_PlayerDeath(Event hEvent, const char[] Name, bool broadcast)
{
	if(!RoundIsActive())
		return;
	
	if(hEvent.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER)
		return;
	
	FF2Player victim = FF2Player(hEvent.GetInt("userid"), true);
#if defined DEMO_NEWSHIELD
	Shield_UnhookClient(victim);
#endif

#if defined MARKER_DROPMERC
	Marker_PlayerDeath(victim);
#endif

#if defined MEDIC_NECROMANCY
	Medic_PlayerDeath(victim);
#endif
}

public void _NextFrame_SetPlayerInfo(int client)
{
	#if defined MARKER_DROPMERC
	Marker_PlayerPutInServer(client);
#endif
#if defined DEMO_NEWSHIELD
	Shield_UnhookClient(FF2Player(client));
#endif
}

public void OnClientPutInServer(int client)
{
	if(!ff2_gm.FF2IsOn)
		return;
	
	RequestFrame(_NextFrame_SetPlayerInfo, client);
}

public void OnClientDisconnect(int client)
{
	if(!ff2_gm.FF2IsOn)
		return;
	
#if defined MARKER_DROPMERC
	Marker_PlayerDisconnect(client);
#endif
#if defined MEDIC_NECROMANCY
	Medic_PlayerDisconnect(client);
#endif
}


stock void CreateParticle(int client, const char[] name)
{
	int table = FindStringTable("ParticleEffectNames");
	int particle = FindStringIndex(table, name);
	
	float pos[3]; GetClientAbsOrigin(client, pos);
	float ang[3]; GetClientEyeAngles(client, ang);
	
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", pos[0]);
	TE_WriteFloat("m_vecOrigin[1]", pos[1]);
	TE_WriteFloat("m_vecOrigin[2]", pos[2]);
	TE_WriteVector("m_vecAngles", ang);
	TE_WriteNum("m_iParticleSystemIndex", particle);
	TE_WriteNum("entindex", -1);
	TE_WriteNum("m_iAttachType", 5);
	TE_SendToAll();
}

stock bool RoundIsActive()
{
	return (ff2_gm.FF2IsOn && ff2_gm.RoundState == StateRunning);
}

stock int GethOwnerEntityOfEntity(int entity)
{
	return GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
}

stock int GetItemDefinitionIndex(int iItem)
{
	return GetEntProp(iItem, Prop_Send, "m_iItemDefinitionIndex");
}

#if defined MARKER_DROPMERC
stock int CreateReviveMarkerFrom(int Marker, int client)
{
	return SDKCall(SDKCreateReviveMarker, Marker, client);
}
#endif

#file "[FF2] Even More Possibilities"
