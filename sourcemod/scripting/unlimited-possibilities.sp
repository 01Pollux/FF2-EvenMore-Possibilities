#pragma semicolon 1

#include <sourcemod>
#include <dhooks>
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>

#pragma newdecls required

bool LateLoaded;

#undef REQUIRE_PLUGIN
#tryinclude "possibilities/infinite_fan_push.sp"
#tryinclude "possibilities/medic_necromancy.sp"
#tryinclude "possibilities/demo_newshield.sp"
#include "possibilities/revive_marker.sp"
#define REQUIRE_PLUGIN

public Plugin myinfo = 
{
	name			= "[FF2] Unlimited Possibilities",
	author		= "[01]Pollux.",
	version		= "1.0",
	url 			= "go-away.net"
};

public APLRes AskPluginLoad2(Handle Plugin, bool late, char[] err, int err_max)
{
	LateLoaded = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	PrepareAllConfigs();
	HookEvent("player_death", Pre_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", Post_PlayerSpawn, EventHookMode_Post);
	HookEvent("arena_round_start", Post_RoundStart, EventHookMode_PostNoCopy);
}

void PrepareAllConfigs()
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
		SetFailState("[FF2] Failed to Load \"infinite_fan_push.sp\","
						..."Try updating your GameData");
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
		SetFailState("[FF2] Failed to Load \"demo_newshield.sp\"");
		return;
	}
#endif

#if defined MARKER_DROPMERC
	if(!Marker_PrepareConfig(Config))
	{
		delete Config;
		SetFailState("[FF2] Failed to Load \"revive_marker.sp\"");
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

#if defined DEMO_NEWSHIELD
	iShield.Clear();
#endif
}

public void Post_RoundStart(Event hEvent, const char[] Name, bool broadcast)
{
#if defined MARKER_DROPMERC
	for (int x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x))
			continue;
		Revives[x] = 0;
	}
#endif
}

public void Post_PlayerSpawn(Event hEvent, const char[] Name, bool broadcast)
{
#if defined MARKER_DROPMERC
	if(!RoundIsActive())
		return;
	int player = GetClientOfUserId(hEvent.GetInt("userid"));
	Revives[player]++;
	
	if(hMarkerTimer[player] != null)
	{
		RemoveMarker(player);
		delete hMarkerTimer[player];
	}
	else return;
#endif
}

public void Pre_PlayerDeath(Event hEvent, const char[] Name, bool broadcast)
{
#if defined MARKER_DROPMERC
	if(!RoundIsActive())
		return;
	
	if(hEvent.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER)
		return;
	
	int victim = GetClientOfUserId(hEvent.GetInt("userid"));
	if(Revives[victim] >= iMaxRevives.IntValue)
		return;
	
	if(FF2_GetBossIndex(victim) != -1)
		return;
		
	int marker = CreateEntityByName("entity_revive_marker");
	if(!IsValidEntity(marker))	
		return;
	iMarker[victim] = EntIndexToEntRef(CreateReviveMarkerFrom(marker, victim));
	RemoveEntity(marker);
	
	hMarkerTimer[victim] =  CreateTimer(GetMaxDecay(TF2_GetPlayerClass(victim)), Timer_RemoveMarker, GetClientSerial(victim), TIMER_FLAG_NO_MAPCHANGE);
#endif
}

public void OnClientPostAdminCheck(int client)
{
#if defined MARKER_DROPMERC
	Revives[client] = 0;
#endif
}

public void OnEntityCreated(int entity, const char[] cls)
{
#if defined DEMO_NEWSHIELD
	if(!strcmp(cls, "tf_wearable_demoshield"))
		CreateTimer(0.1, Post_DemoShieldCreated, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
#endif
}

stock void CreateTimedParticle(int owner, const char[] Name, float SpawnPos[3], float duration)
{
	CreateTimer(duration, Timer_KillEntity, EntIndexToEntRef(AttachParticle(owner, Name, SpawnPos)), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_KillEntity(Handle timer, any EntRef)
{
	int entity = EntRefToEntIndex(EntRef);
	if(IsValidEntity(entity))
		RemoveEntity(entity);
}

stock int AttachParticle(int owner, const char[] ParticleName, float SpawnPos[3])
{
	int entity = CreateEntityByName("info_particle_system");

	TeleportEntity(entity, SpawnPos, NULL_VECTOR, NULL_VECTOR);

	static char buffer[64];
	FormatEx(buffer, sizeof(buffer), "target%i", owner);
	DispatchKeyValue(owner, "targetname", buffer);

	DispatchKeyValue(entity, "targetname", "tf2particle");
	DispatchKeyValue(entity, "parentname", buffer);
	DispatchKeyValue(entity, "effect_name", ParticleName);
	DispatchSpawn(entity);
	
	SetVariantString(buffer);
	AcceptEntityInput(entity, "SetParent", entity, entity);
	
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", owner);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "start");
	
	return entity;
}

stock bool RoundIsActive()
{
	return (FF2_GetRoundState() == 1);
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


#file "[FF2] Unlimited Possibilities"
