#if defined DEMO_NEWSHIELD
	#endinput
#endif
#define DEMO_NEWSHIELD

#if !defined MAXCLIENTS
#define MAXCLIENTS (MAXPLAYERS + 1)
#endif

Handle SDKEquipWearable;
static ConVar RegenDuration;
ArrayList iShield;
static int m_iEntityQuality, m_iEntityLevel;

public bool NewShield_PrepareConfig(const GameData Config)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(Config, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	if((SDKEquipWearable = EndPrepSDKCall()) == null)
		return false;
	
	RegenDuration = CreateConVar("dns_duration", "20.0", "Duration before demo gets a new shield");
	
	m_iEntityQuality = FindSendPropInfo("CTFWearableDemoShield", "m_iEntityQuality");
	m_iEntityLevel = FindSendPropInfo("CTFWearableDemoShield", "m_iEntityLevel");
	
	if(m_iEntityLevel == -1 || m_iEntityQuality == -1)
		return false;
	
	iShield = new ArrayList(2);
	
	if(LateLoaded)
	{
		int x = -1;
		while((x = FindEntityByClassname(x, "tf_wearable_demoshield")) != -1)
			Post_DemoShieldCreated(null, EntIndexToEntRef(x));
	}
	return true;
}

public Action Post_DemoShieldCreated(Handle Timer, int EntRef)
{
	int shield = EntRefToEntIndex(EntRef);
	if(IsValidEntity(shield))
	{
		int owner = GethOwnerEntityOfEntity(shield);
		RegShield(owner, shield);
		SDKHook(owner, SDKHook_PostThinkPost, Post_DemoThinkPost);
	}
}

public void Post_DemoThinkPost(int client)
{
	if(!IsPlayerAlive(client))
	{
		UnHook(client);
		return;
	}
	
	if(!RoundIsActive() || TF2_GetPlayerClass(client) != TFClass_DemoMan || FF2_GetBossIndex(client) > -1)
	{
		UnHook(client);
		return;
	}
	
	if(FF2_GetClientShield(client) != 0.0)
		return;
	
	CreateTimer(RegenDuration.FloatValue, Timer_SetShieldBack, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	UnHook(client);
	return;
}

public Action Timer_SetShieldBack(Handle Timer, any Serial)
{
	int client = GetClientFromSerial(Serial);
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	int index = GetiDefShieldIndex(Serial);
	CreateAndEquipShield(client, index);
	
	return Plugin_Continue;
}

stock void CreateAndEquipShield(int client, int index)
{
	int shield = CreateEntityByName("tf_wearable_demoshield");
	
	SetEntProp(shield, Prop_Send, "m_iItemDefinitionIndex", index);
	
	SetEntProp(shield, Prop_Send, "m_bInitialized", 1);
	
	SetEntData(shield, m_iEntityQuality, 4);
	SetEntProp(shield, Prop_Send, "m_iEntityQuality", 4);
	SetEntData(shield, m_iEntityLevel, 39);
	SetEntProp(shield, Prop_Send, "m_iEntityLevel", 39);
	
	DispatchSpawn(shield);
	SDKCall(SDKEquipWearable, client, shield);
	
	FF2_SetClientShield(client, shield, 100.0);
}

void UnHook(int client)
{
	SDKUnhook(client, SDKHook_PostThinkPost, Post_DemoThinkPost);
}

void RegShield(int owner, int shield)
{
	int index = iShield.FindValue(GetClientSerial(owner));
	switch(index)
	{
		case -1:{
			index = iShield.Push(GetClientSerial(owner));
			iShield.Set(index, GetItemDefinitionIndex(shield), 1);
		}
		default:{
			iShield.Set(index, GetItemDefinitionIndex(shield), 1);
		}
	}
}

int GetiDefShieldIndex(int Serial)
{
	int index = iShield.FindValue(Serial);
	if(index == -1)
		return 131;
	return iShield.Get(index, 1);
}
