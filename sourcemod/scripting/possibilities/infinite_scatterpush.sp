#if defined FAN_FORCE_SCATTER
	#endinput
#endif
#define FAN_FORCE_SCATTER

static Address g_ScatterSelfForce = Address_Null;
static Address g_UnlimitedSelfForce = Address_Null;
static int OLD_Address[6];

static ConVar cv_UnlimitedPushes;

public bool FaN_PrepareConfig(GameData Config)
{
	Handle OnFireBullet = DHookCreateFromConf(Config, "CTFScattergun::FireBullet");
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
	
	for (int x; x < 6; x++)
		OLD_Address[x] = LoadFromAddress(g_ScatterSelfForce + view_as<Address>(x), NumberType_Int8);
	
	cv_UnlimitedPushes = CreateConVar("up_max_fanpush", "0", "Unlimited Pushes for FaN");
	
	return true;
}

public MRESReturn Pre_ScatterFireBullet(int weapon, Handle Params)
{
	LimitedFan();
	DisableScatterFaN();
	
	int client = DHookGetParam(Params, 1);
	int boss = FF2_GetBossIndex(client);
	if(boss >= 0)
		return MRES_Ignored;
	
	if(!RoundIsActive())
		return MRES_Ignored;
	
	if(cv_UnlimitedPushes.BoolValue)
		UnLimitedFan();
	
	int index = GetItemDefinitionIndex(weapon);
	if(index != 1103 && index != 220)	//back scratcher && shortstop
		return MRES_Ignored;
		
	EnableScatterFaN();
	return MRES_Ignored;
}

public MRESReturn Post_ScatterFireBullet(int weapon, Handle Player)
{
	LimitedFan();
	DisableScatterFaN();
}


stock void EnableScatterFaN()
{
	for (int x; x < 6; x++)
	{
		StoreToAddress(g_ScatterSelfForce + view_as<Address>(x), 0x90, NumberType_Int8);
	}
}

stock void UnLimitedFan()
{
	StoreToAddress(g_UnlimitedSelfForce + view_as<Address>(0x06), 0x00, NumberType_Int8);
}

stock void DisableScatterFaN()
{
	for (int x; x < 6; x++)
		StoreToAddress(g_ScatterSelfForce + view_as<Address>(x), OLD_Address[x], NumberType_Int8);
}

stock void LimitedFan()
{
	StoreToAddress(g_UnlimitedSelfForce + view_as<Address>(0x06), 0x01, NumberType_Int8);
}
