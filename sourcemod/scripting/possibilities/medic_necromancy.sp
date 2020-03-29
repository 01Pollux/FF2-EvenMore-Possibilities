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

public bool Necro_PrepareConfig()
{
	if(!AddCommandListener(OnPlayerTaunt, "taunt") || !AddCommandListener(OnPlayerTaunt, "+taunt"))
		return false;
	
	MinCharge = CreateConVar("nm_mincharge", "80.0", "Minimum Uber required to summon");
	SummonPenalty = CreateConVar("nm_wait_duration", "20.0", "Duration before next summon is available");
	NextSideEffect = CreateConVar("nm_sideeffects_delay", "0.9", "Delay between Bad/Random effects");
	RandomDeath = CreateConVar("nm_randomdeath", "3", "Random death percentage for summon");
	
	Minions = new ArrayList(2);
	
	HookEvent("arena_win_panel", CleanUp_OnPostRoundEnd, EventHookMode_PostNoCopy);
	return true;
}

public void OnMapStart()
{
	Minions.Clear();
}

public Action OnPlayerTaunt(int client, const char[] command, int arg)
{
	if(FF2_GetRoundState() != 1)
		return Plugin_Continue;
	
	int boss = FF2_GetBossIndex(client);
	if(boss >=0)
		return Plugin_Continue;
	
	if(NextSummonTimer[client] >= GetGameTime())
		return Plugin_Continue;
	
	if(!!GetEntProp(client, Prop_Send, "m_bDucking"))
		return Plugin_Continue;
	
	boss = Minions.FindValue(GetClientSerial(client), 1);
	if(boss != -1)
		return Plugin_Continue;
	
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
	
	hActive = GetRandomDead();
	if(hActive <= 0)
		return Plugin_Continue;
		
	static float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	
	if(TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		FF2_SetFF2flags(hActive, FF2_GetFF2flags(hActive) | FF2FLAG_ALLOWSPAWNINBOSSTEAM);
		TF2_ChangeClientTeam(hActive, TFTeam_Blue);
	}
	TF2_RespawnPlayer(hActive);
	TF2_SetPlayerClass(hActive, TFClass_Heavy);
	TF2_RegeneratePlayer(hActive);
	TeleportEntity(hActive, pos, NULL_VECTOR, NULL_VECTOR);
	
	NextSummonTimer[client] = GetGameTime() + SummonPenalty.FloatValue;
	SDKHook(hActive, SDKHook_PostThinkPost, Post_SummonPostThink);
	ApplyBadStuff(hActive);
	NextEffectsAt[hActive] = GetGameTime() + NextSideEffect.FloatValue;
	CreateTimedParticle(hActive, "merasmus_spawn", pos, 1.4);
	
	boss = Minions.Push(GetClientSerial(hActive));
	Minions.Set(boss, GetClientSerial(client), 1);
	
	return Plugin_Continue;
}

public void Post_SummonPostThink(int client)
{
	if(FF2_GetRoundState() !=1)
	{
		EndHook(client);
		return;
	}
	else if(!IsPlayerAlive(client))
	{
		int index = Minions.FindValue(GetClientSerial(client), 0);
		if(index != -1)
			Minions.Erase(index);
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

public void CleanUp_OnPostRoundEnd(Event event, const char[] Name, bool broadcast)
{
	Minions.Clear();
}

void ApplyBadStuff(int victim)
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
	return Clients[GetRandomInt(0, total - 1)];
}
