#if defined DEMO_NEWSHIELD
	#endinput
#endif
#define DEMO_NEWSHIELD

#if !defined MAXCLIENTS
#define MAXCLIENTS (MAXPLAYERS + 1)
#endif

static Handle SDKEquipWearable = null;
static ConVar RegenDuration;

int m_iEntityQuality, m_iEntityLevel;

float flRegenTime[MAXCLIENTS];
int iShieldIndex[MAXCLIENTS] =  { 131, ... };

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
	
	if(LateLoaded)
	{
		int shield = -1;
		while((shield = FindEntityByClassname(shield, "tf_wearable_demoshield")) != -1)
		{
			iShieldIndex[GetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity")] = GetEntProp(shield, Prop_Send, "m_iItemDefinitionIndex");
		}
	}
	PrintToServer("%s", LateLoaded ? "yes":"no");
	
	return (m_iEntityLevel != -1 && m_iEntityQuality != -1);
}

public void Post_DemoThinkPost(int client)
{
	if(TF2_GetPlayerClass(client) != TFClass_DemoMan || FF2_GetBossIndex(client) > -1 || FF2_GetRoundState() != 1)
	{
		SDKUnhook(client, SDKHook_PostThinkPost, Post_DemoThinkPost);
		return;
	}
	
	if(flRegenTime[client] <= GetGameTime())
	{
		CreateAndEquipShield(client);
		SDKUnhook(client, SDKHook_PostThinkPost, Post_DemoThinkPost);
		return;
	}
}

public void OnEntityCreated(int entity, const char[] cls)
{
	if(!strcmp(cls, "tf_wearable_demoshield"))
	{
		iShieldIndex[GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")] = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
	}
}

public void OnEntityDestroyed(int entity)
{
	static char cls[48];
	GetEntityClassname(entity, cls, sizeof(cls));
	if(strcmp(cls, "tf_wearable_demoshield"))
		return;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	SDKHook(owner, SDKHook_PostThinkPost, Post_DemoThinkPost);
	flRegenTime[owner] = GetGameTime() + RegenDuration.FloatValue;
}

void CreateAndEquipShield(int owner)
{
	int shield = CreateEntityByName("tf_wearable_demoshield");
	if(!IsValidEntity(shield))
		return;
	
	SetEntProp(shield, Prop_Send, "m_iItemDefinitionIndex", iShieldIndex[owner]);
	SetEntData(shield, m_iEntityQuality, 4);
	SetEntProp(shield, Prop_Send, "m_iEntityQuality", 4);
	SetEntData(shield, m_iEntityLevel, 39);
	SetEntProp(shield, Prop_Send, "m_iEntityLevel", 39);
	
	DispatchSpawn(shield);
	SDKCall(SDKEquipWearable, owner, shield);
}
