#if defined MEDIC_NECROMANCY
	#endinput
#endif
#define MEDIC_NECROMANCY

#if !defined MAXCLIENTS
#define MAXCLIENTS (MAXPLAYERS + 1)
#endif

static ConVar MinCharge;
static ConVar SummonPenalty;
static ConVar NextSideEffect;
static ConVar RandomDeath;

static float NextSummonTimer[MAXCLIENTS];
static float NextEffectsAt[MAXCLIENTS];
TFCond LastCond[MAXCLIENTS];
ArrayList Minions;
bool medic_revive;

public bool Necro_PrepareConfig()
{
	if(!AddCommandListener(OnPlayerTaunt, "taunt") || !AddCommandListener(OnPlayerTaunt, "+taunt"))
		return false;
	
	MinCharge = CreateConVar("nm_mincharge", "80.0", "Minimum Uber required to summon");
	SummonPenalty = CreateConVar("nm_wait_duration", "20.0", "Duration before next summon is available");
	NextSideEffect = CreateConVar("nm_sideeffects_delay", "0.9", "Delay between Bad/Random effects");
	RandomDeath = CreateConVar("nm_randomdeath", "3", "Random death percentage for summon");
	
	if(!Minions) {
		Minions = new ArrayList(2);
	}
	return true;
}

public Action OnPlayerTaunt(int client, const char[] command, int arg)
{
	if(!RoundIsActive())
		return Plugin_Continue;
	
	FF2Player player = FF2Player(client);
	if(player.bIsBoss)
		return Plugin_Continue;
	
	if(TF2_GetPlayerClass(client) != TFClass_Medic)
		return Plugin_Continue;
	
	if(NextSummonTimer[client] >= GetGameTime())
		return Plugin_Continue;
	
	if(!!GetEntProp(client, Prop_Send, "m_bDucking"))
		return Plugin_Continue;
	
	int minion_aidx = Minions.FindValue(player);
	if(minion_aidx != -1)
		return Plugin_Continue;
	
	static char weapon[48];
	int hActive = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(hActive == -1)
		return Plugin_Continue;
	
	if(!GetEntityClassname(hActive, weapon, sizeof(weapon)) || strcmp(weapon, "tf_weapon_medigun"))
		return Plugin_Continue;
	
	if(GetEntProp(hActive, Prop_Send, "m_bChargeRelease"))
		return Plugin_Continue;
	
	float charge = GetEntPropFloat(hActive, Prop_Send, "m_flChargeLevel");
	if(charge * 100 < MinCharge.FloatValue)
		return Plugin_Continue;
	
	SetEntPropFloat(hActive, Prop_Send, "m_flChargeLevel", charge - (MinCharge.FloatValue / 100));
	
	int dead = GetRandomDead();
	if(dead <= 0)
		return Plugin_Continue;
	
	static float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	
	FF2Player minion = FF2Player(dead);
	
	minion.ForceTeamChange(GetClientTeam(client));
	
	medic_revive = true;
	
#if defined MARKER_DROPMERC
	RemoveMarker(dead);
#endif

	TF2_RespawnPlayer(dead);
	RequestFrame(NextFrame_EnableMarkerCount);
	TF2_SetPlayerClass(dead, TFClass_Heavy);
	TF2_RegeneratePlayer(dead);
	TeleportEntity(dead, pos, NULL_VECTOR, NULL_VECTOR);
	
	NextSummonTimer[client] = GetGameTime() + SummonPenalty.FloatValue;
	SDKHook(dead, SDKHook_PostThinkPost, Post_SummonPostThink);
	ApplyBadStuff(dead);
	NextEffectsAt[dead] = GetGameTime() + NextSideEffect.FloatValue;
	CreateParticle(client, "merasmus_spawn");
	
	minion_aidx = Minions.Push(player);
	Minions.Set(minion_aidx, minion, 1);
	
	return Plugin_Continue;
}

public void Medic_PlayerDeath(FF2Player victim)
{
	EndHook(victim.index);
}

public void Medic_PlayerDisconnect(int client)
{
	EndHook(client);
}

public void Post_SummonPostThink(int client)
{
	if(!RoundIsActive()) {
		EndHook(client);
		return;
	}
	
	if(NextEffectsAt[client] > GetGameTime())
		return;

	ApplyBadStuff(client);
	if(GetRandomInt(0, 100) < RandomDeath.IntValue)
	{
		ForcePlayerSuicide(client);
		EndHook(client);
		return;
	}
	
	NextEffectsAt[client] = GetGameTime() + NextSideEffect.FloatValue;
}

static void ApplyBadStuff(int victim)
{
	if(TF2_IsPlayerInCondition(victim, LastCond[victim]))
		TF2_RemoveCondition(victim, LastCond[victim]);
	
	static const TFCond condList[] = {
		TFCond_CritCola, TFCond_Milked, TFCond_MarkedForDeath, 
		TFCond_NoHealingDamageBuff, TFCond_PreventDeath, TFCond_Gas,
		TFCond_Slowed, TFCond_Jarated
	};
	
	LastCond[victim] = condList[GetRandomInt(0, 7)];
	
	TF2_AddCondition(victim, LastCond[victim]);
	TF2_MakeBleed(victim, victim, 0.25);
}

static void EndHook(int client)
{
	int idx;
	int uid = GetClientUserId(client);
	for(int i; i < 2; i++) 
	{
		idx = Minions.FindValue(uid, i);
		if(idx != -1) 
		{
			Minions.Erase(i);
			break;
		}
	}
	
	SDKUnhook(client, SDKHook_PostThinkPost, Post_SummonPostThink);
}

static stock int GetRandomDead()
{
	int[] clients = new int[MaxClients];
	int total;
	for (int x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x))
			continue;
		
		if(IsPlayerAlive(x))
			continue;
		
		if(!FF2Player(x).bIsBoss)
			clients[total++] = x;
	}
	return !total ? -1:clients[GetRandomInt(0, total - 1)];
}

public void NextFrame_EnableMarkerCount()
{
	medic_revive = false;
}
