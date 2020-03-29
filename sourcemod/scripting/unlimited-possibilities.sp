#pragma semicolon 1

#include <sourcemod>
#include <dhooks>
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>

#pragma newdecls required

#undef REQUIRE_PLUGIN
#include "possibilities/infinite_fan_push.sp"
#include "possibilities/medic_necromancy.sp"
#define REQUIRE_PLUGIN

public Plugin myinfo = 
{
	name			= "[FF2] Unlimited Possibilities",
	author		= "[01]Pollux.",
	version		= "1.0",
	url 			= "go-away.net"
};

public void OnPluginStart()
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
		SetFailState("[GameData] Failed to Load \"infinite_fan_push.sp\","
						..."Try updating your GameData");
		return;
	}
#endif

#if defined MEDIC_NECROMANCY
	if(!Necro_PrepareConfig())
	{
		delete Config;
		SetFailState("[GameData] Failed to Load \"medic_necromancy.sp\","
						..."Try updating your GameData");
		return;
	}
#endif
	delete Config;
	
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
	AcceptEntityInput(entity, "SetParent", entity, entity, 0);
	
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", owner);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "start");
	
	return entity;
} 
