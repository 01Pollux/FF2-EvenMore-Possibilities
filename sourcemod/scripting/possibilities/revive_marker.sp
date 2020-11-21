#if defined MARKER_DROPMERC
	#endinput
#endif
#define MARKER_DROPMERC

#if !defined MAXCLIENTS
	#define MAXCLIENTS (MAXPLAYERS+1)
#endif

Handle SDKCreateReviveMarker;
int Revives[MAXCLIENTS];
int iMarker[MAXCLIENTS] =  { INVALID_ENT_REFERENCE, ... };

enum struct _RMConVars {
	ConVar max_revives;
	ConVar decay_time;
	ConVar heavy_extra;
}
_RMConVars rm_cvars;

public bool Marker_PrepareConfig(const GameData Config)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(Config, SDKConf_Signature, "CTFReviveMarker::Create");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	if((SDKCreateReviveMarker = EndPrepSDKCall()) == null)
		return false;
	
	rm_cvars.max_revives = CreateConVar("rm_max_revives", "1", "Max revives a client can have");
	rm_cvars.decay_time = CreateConVar("rm_max_decay", "10.0", "Decay time for revive marker");
	rm_cvars.heavy_extra = CreateConVar("rm_max_decay_mult", "1.4", "Optional, Heavy's extra time for decay");
	
	return true;
}

public void Marker_PlayerSpawn(int player)
{
	if(!RoundIsActive())
		return;
#if defined MEDIC_NECROMANCY
	if(!medic_revive)
		Revives[player]++;
#else
	Revives[player]++;
#endif
	RemoveMarker(player);
}

public void Marker_PlayerDeath(FF2Player player)
{
	if(!RoundIsActive())
		return;
	
	int victim = player.index;
	
	if(player.bIsBoss)
		return;
	
	if(Revives[victim] >= rm_cvars.max_revives.IntValue)
		return;
	
	int marker = CreateEntityByName("entity_revive_marker");
	if(!IsValidEntity(marker))	
		return;
	
	iMarker[victim] = EntIndexToEntRef(CreateReviveMarkerFrom(marker, victim));
	RemoveEntity(marker);
	CreateTimer(GetMaxDecay(TF2_GetPlayerClass(victim)), Timer_RemoveMarker, GetClientSerial(victim), TIMER_FLAG_NO_MAPCHANGE);
}

public void Marker_PlayerDisconnect(int client)
{
	if(iMarker[client] == INVALID_ENT_REFERENCE)
		return;
	int marker = EntRefToEntIndex(iMarker[client]);
	if(IsValidEntity(marker)){
		iMarker[client] = INVALID_ENT_REFERENCE;
		RemoveEntity(marker);
	}
}

public void Marker_PlayerPutInServer(int client)
{
	Revives[client] = 0;
}

public Action Timer_RemoveMarker(Handle Timer, any Serial)
{
	int victim = GetClientFromSerial(Serial);
	RemoveMarker(victim);
}

void RemoveMarker(int client)
{
	int marker = EntRefToEntIndex(iMarker[client]);
	if(IsValidEntity(marker))
	{
		RemoveEntity(marker);
		iMarker[client] = INVALID_ENT_REFERENCE;
	}
}

float GetMaxDecay(TFClassType Class)
{
	return (Class == TFClass_Heavy ? rm_cvars.decay_time.FloatValue * rm_cvars.heavy_extra.FloatValue:rm_cvars.decay_time.FloatValue);
}
