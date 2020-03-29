#if defined FAN_FORCE_SCATTER
	#endinput
#endif
#define FAN_FORCE_SCATTER

static Address g_ScatterSelfForce = Address_Null;
static Address g_UnlimitedSelfForce = Address_Null;
static int OLD_Address[7];

static ConVar cv_UnlimitedPushes;

public bool FaN_PrepareConfig(const GameData Config)
{
	Handle OnFireBullet = DHookCreateFromConf(Config, "FireBullet");
	if(OnFireBullet == null)
		return false;
	else if(!DHookEnableDetour(OnFireBullet, false, Pre_ScatterFireBullet))
		return false;
	else if(!DHookEnableDetour(OnFireBullet, true, Post_ScatterFireBullet))
		return false;
	
	if((g_ScatterSelfForce = Config.GetAddress("CTFScattergun::FireBullet::AnyScatterFaN")) == Address_Null)
		return false;
	if((g_UnlimitedSelfForce = Config.GetAddress("CTFScattergun::FireBullet::NoPushPenalty")) == Address_Null)
		return false;
	
	for (int x; x < 7; x++)
		OLD_Address[x] = LoadFromAddress(g_ScatterSelfForce + view_as<Address>(x), NumberType_Int8);
	
	cv_UnlimitedPushes = CreateConVar("up_max_fanpush", "0", "Unlimited Pushes for FaN");
	
	return true;
}

public MRESReturn Pre_ScatterFireBullet(int weapon, Handle Params)
{
	ToggleFaN(false);
	ToggleScatter(false);
	
	int client = DHookGetParam(Params, 1);
	int boss = FF2_GetBossIndex(client);
	if(boss >= 0)
		return MRES_Ignored;
	
	if(FF2_GetRoundState() != 1)
		return MRES_Ignored;
	
	if(cv_UnlimitedPushes.BoolValue)
		ToggleFaN(true);
	
	int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if(index != 1103 && index != 220)	//back scratcher && shortstop
		return MRES_Ignored;
		
	ToggleScatter(true);
	return MRES_Ignored;
}

public MRESReturn Post_ScatterFireBullet(int weapon, Handle Player)
{
	ToggleFaN(false);
	ToggleScatter(false);
}

static void ToggleFaN(bool enable = true)
{
	StoreToAddress(g_UnlimitedSelfForce, enable ? 0x00 : 0x01, NumberType_Int8);
}

static void ToggleScatter(bool enable)
{
	for (int x; x < 7; x++)
		StoreToAddress(g_ScatterSelfForce + view_as<Address>(x), enable ? 0x90 : OLD_Address[x], NumberType_Int8);
}
