#if defined MARKER_DROPMERC
	#endinput
#endif
#define MARKER_DROPMERC

#if !defined MAXCLIENTS
	#define MAXCLIENTS (MAXPLAYERS+1)
#endif

Handle SDKCreateReviveMarker;
Handle hMarkerTimer[MAXCLIENTS];
int Revives[MAXCLIENTS];
int iMarker[MAXCLIENTS];

ConVar iMaxRevives;
static ConVar flDecayTime;
static ConVar flHeavyExtra;

public bool Marker_PrepareConfig(const GameData Config)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(Config, SDKConf_Signature, "CTFReviveMarker::Create");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	if((SDKCreateReviveMarker = EndPrepSDKCall()) == null)
		return false;
	
	iMaxRevives = CreateConVar("rm_max_revives", "1", "Max revives a client can have");
	flDecayTime = CreateConVar("rm_max_decay", "10.0", "Decay time for revive marker");
	flHeavyExtra = CreateConVar("rm_max_decay_mult", "1.4", "Optional, Heavy's extra time for decay");
	
	return true;
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
		iMarker[client] = INVALID_ENT_REFERENCE;
		static float pos[3];
		GetEntPropVector(marker, Prop_Send, "m_vecOrigin", pos);
		RemoveEntity(marker);
		pos[2] += 30.0;
		CreateTimedParticle(client, "ghost_smoke", pos, 0.5);
	}
}

float GetMaxDecay(TFClassType Class)
{
	return (Class == TFClass_Heavy ? flDecayTime.FloatValue * flHeavyExtra.FloatValue:flDecayTime.FloatValue);
}
