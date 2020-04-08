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
	
	Minions = new ArrayList(2);
	return true;
}

public Action OnPlayerTaunt(int client, const char[] command, int arg)
{
	if(!RoundIsActive())
		return Plugin_Continue;
	
	int boss = FF2_GetBossIndex(client);
	if(boss >=0)
		return Plugin_Continue;
	
	if(TF2_GetPlayerClass(client) != TFClass_Medic)
		return Plugin_Continue;
	
	if(NextSummonTimer[client] >= GetGameTime())
		return Plugin_Continue;
	
	if(!!GetEntProp(client, Prop_Send, "m_bDucking"))
		return Plugin_Continue;
	
	boss = Minions.FindValue(GetClientSerial(client), 0);
	if(boss != -1){
		return Plugin_Continue;
	}
	
	static char weapon[48];
	int hActive = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEntity(hActive))
		return Plugin_Continue;
	
	GetEntityClassname(hActive, weapon, sizeof(weapon));
	if(strcmp(weapon, "tf_weapon_medigun"))
		return Plugin_Continue;
	
	if(!!GetEntProp(hActive, Prop_Send, "m_bChargeRelease"))
		return Plugin_Continue;
	
	float charge = GetEntPropFloat(hActive, Prop_Send, "m_flChargeLevel");
	if(charge * 100 < MinCharge.FloatValue)
		return Plugin_Continue;
	
	SetEntPropFloat(hActive, Prop_Send, "m_flChargeLevel", charge - (MinCharge.FloatValue / 100));
	
	int dead = GetRandomDead();
	if(dead <= 0 || dead > MaxClients) //ik its not even possible, but whatever.
		return Plugin_Continue;
	
	static float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	
	if(TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		FF2_SetFF2flags(dead, FF2_GetFF2flags(dead) | FF2FLAG_ALLOWSPAWNINBOSSTEAM);
		TF2_ChangeClientTeam(dead, TFTeam_Blue);
	}
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
	CreateTimedParticle(dead, "merasmus_spawn", pos, 1.4);
	
	boss = Minions.Push(GetClientSerial(client));
	Minions.Set(boss, GetClientSerial(dead), 1);
	
	return Plugin_Continue;
}

public void Medic_PlayerDeath(int client)
{
	int index = Minions.FindValue(GetClientSerial(client), 1);
	if(index != -1){
		PrintToChatAll("index : %i, vicitim : %N, owner: %N", index, GetClientFromSerial(Minions.Get(index, 1)), GetClientFromSerial(Minions.Get(index, 0)));
		Minions.Erase(index);
	}
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
	switch(GetRandomInt(1, 8))
	{
		case 1: LastCond[victim] = TFCond_CritCola;
		case 2: LastCond[victim] = TFCond_Milked;
		case 3: LastCond[victim] = TFCond_MarkedForDeath;
		case 4: LastCond[victim] = TFCond_NoHealingDamageBuff;
		case 5: LastCond[victim] = TFCond_PreventDeath;
		case 6: LastCond[victim] = TFCond_Gas;
		case 7: LastCond[victim] = TFCond_Slowed;
		case 8: LastCond[victim] = TFCond_Jarated;
	}
	TF2_AddCondition(victim, LastCond[victim]);
	TF2_MakeBleed(victim, victim, 0.25);
}

static void EndHook(int client)
{
	SDKUnhook(client, SDKHook_PostThinkPost, Post_SummonPostThink);
}

static stock int GetRandomDead()
{
	int[] Clients = new int[MaxClients];
	int total;
	for (int x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x))
			continue;
		if(IsPlayerAlive(x))
			continue;
		if(FF2_GetBossIndex(x) == -1)
			Clients[total++] = x;
	}
	return !total ? -1:Clients[GetRandomInt(0, total - 1)];
}

public void NextFrame_EnableMarkerCount()
{
	medic_revive = false;
}
