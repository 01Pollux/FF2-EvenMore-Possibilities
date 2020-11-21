#if defined DEMO_NEWSHIELD
	#endinput
#endif
#define DEMO_NEWSHIELD

#if !defined MAXCLIENTS
#define MAXCLIENTS (MAXPLAYERS + 1)
#endif

Handle SDKEquipWearable;

enum struct _DNSConVars {
	ConVar damage_ratio;
	ConVar next_think_time;
	ConVar regen_per_think;
}
_DNSConVars dns_cvars;

static int m_iEntityQuality, m_iEntityLevel;

#define ToDemoShieldUser(%0) view_as<DemoShieldUser>(%0)
methodmap DemoShieldUser < FF2Player {
	public DemoShieldUser(int idx, bool uid = false) {
		return view_as<DemoShieldUser>(FF2Player(idx, uid));
	}
	
	property bool bBrokenShield {
		public get() 				{ return this.GetPropAny("bBrokenShield"); }
		public set(const bool b) 	{ this.SetPropAny("bBrokenShield", b); }
	}
	
	property float flShieldHP {
		public get() 				{ return this.GetPropFloat("flShieldHP"); }
		public set(const float f) 	{ this.SetPropFloat("flShieldHP", f); }
	}
	
	property int iShieldDefIdx {
		public get() 				{ return this.GetPropInt("iShieldDefIdx"); }
		public set(const int idx) 	{ this.SetPropInt("iShieldDefIdx", idx); }
	}
}


public bool NewShield_PrepareConfig(const GameData Config)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(Config, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	if((SDKEquipWearable = EndPrepSDKCall()) == null)
		return false;
	
	dns_cvars.damage_ratio = CreateConVar("dns_damage_ratio", "0.5", "Damage's ratio for shield");
	dns_cvars.next_think_time = CreateConVar("dns_next_thin_time", "1.0", "Next think duration for shield regen");
	dns_cvars.regen_per_think = CreateConVar("dns_regen_per_think", "10.0", "amount of health to add each think");
	
	RegConsoleCmd("ff2_shieldhp", Cmd_ShowShieldHP, "Show Shield HP");

	m_iEntityQuality = FindSendPropInfo("CTFWearableDemoShield", "m_iEntityQuality");
	m_iEntityLevel = FindSendPropInfo("CTFWearableDemoShield", "m_iEntityLevel");
	
	return true;
}

public Action Cmd_ShowShieldHP(int client, int args)
{
	if(!IsClientInGame(client)) 
		return Plugin_Continue;
	else if(!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[FF2] You must be alive to use this command");
		return Plugin_Handled;
	}
	
	DemoShieldUser player = DemoShieldUser(client);
	if(player.bIsBoss)
		return Plugin_Continue;
	
	float health = player.flShieldHP;
	
	PrintHintText(client, "Shield Health: %i/100", health);
	return Plugin_Continue;
}


public Action _OnHitShield(VSH2Player victim, int& attacker, int& inflictor, 
							float& damage, int& damagetype, int& weapon, 
							float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(victim.GetPropAny("bIsBoss"))
		return Plugin_Continue;
	
	int client = victim.index;
	
	DemoShieldUser player = ToDemoShieldUser(victim);
	
	float curHealth = player.flShieldHP;
	curHealth -= damage * dns_cvars.damage_ratio.FloatValue;
	
	if(curHealth <= 0.0)
	{
		curHealth = 0.0;
		
		if(!player.bBrokenShield)
		{
			player.iShieldDefIdx = GetItemDefinitionIndex(weapon);
			player.bBrokenShield = true;
			SDKHook(client, SDKHook_PostThinkPost, _PostShieldOwnerThinkPost);
		}
	}
	
	player.flShieldHP = curHealth;
	return player.bBrokenShield ? Plugin_Continue:Plugin_Changed;
}


public void _PostShieldOwnerThinkPost(int client)
{
	DemoShieldUser player = DemoShieldUser(client);
	if(!RoundIsActive())
	{
		UnHook(player);
		return;
	}
	
	if(player.bIsBoss)
	{
		UnHook(player);
		return;
	}
	
	static float flNextRegen[MAXCLIENTS];
	if(flNextRegen[client] <= GetGameTime())
	{
		flNextRegen[client] = GetGameTime() + dns_cvars.next_think_time.FloatValue;
		player.flShieldHP += dns_cvars.regen_per_think.FloatValue;
	}
	
	if(player.flShieldHP >= 100.0)
	{
		UnHook(player);
		ResetShield(player);
	}
}


void Shield_UnhookClient(FF2Player player)
{
	UnHook(ToDemoShieldUser(player));
}


static void ResetShield(DemoShieldUser player)
{
	int shield = CreateEntityByName("tf_wearable_demoshield");
	int index = player.iShieldDefIdx;
	
	SetEntProp(shield, Prop_Send, "m_iItemDefinitionIndex", index);
	
	SetEntProp(shield, Prop_Send, "m_bInitialized", 1);
	
	SetEntData(shield, m_iEntityQuality, 4);
	SetEntProp(shield, Prop_Send, "m_iEntityQuality", 4);
	SetEntData(shield, m_iEntityLevel, 39);
	SetEntProp(shield, Prop_Send, "m_iEntityLevel", 39);
	
	DispatchSpawn(shield);
	SDKCall(SDKEquipWearable, player.index, shield);
}


static void UnHook(DemoShieldUser player)
{
	player.flShieldHP = 100.0;
	player.bBrokenShield = false;
	SDKUnhook(player.index, SDKHook_PostThinkPost, _PostShieldOwnerThinkPost);
}
