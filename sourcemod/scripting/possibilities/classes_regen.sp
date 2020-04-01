#if defined CLASSES_REGEN
	#endinput
#endif
#define CLASSES_REGEN

static Address g_aRegenThink = Address_Null;
static int OLD_Address[6];

static ConVar cv_AllowedClasses;
static char g_sClasses[78];

static const char TF2_ClassName[][] = {
	"scout",
	"sniper",
	"soldier",
	"demoman",
	"medic",
	"heavy",
	"pyro",
	"spy",
	"engineer"
};

public bool Regen_PrepareConfig(const GameData Config)
{
	Handle OnRegenThink = DHookCreateFromConf(Config, "CTFPlayer::RegenThink");
	if(OnRegenThink == null)
		return false;
		
	else if(!DHookEnableDetour(OnRegenThink, false, Pre_RegenThink))
		return false;
	else if(!DHookEnableDetour(OnRegenThink, true, Post_RegenThink))
		return false;
	
	g_aRegenThink = Config.GetAddress("CTFPlayer::RegenThink::CanRegen");
	if(g_aRegenThink == Address_Null)
		return false;
	
	for (int x; x < 6; x++)
		OLD_Address[x] = LoadFromAddress(g_aRegenThink + view_as<Address>(x), NumberType_Int8);
		
	cv_AllowedClasses = CreateConVar("rt_classes", "sniper ; heavy ; spy ; engineer", "Allow Those classes to get regenerated over time");
	cv_AllowedClasses.GetString(g_sClasses, sizeof(g_sClasses));
	
	return true;
}

public MRESReturn Pre_RegenThink(int player)
{
	if(FF2_GetBossIndex(player) > -1)
		return MRES_Ignored;
	
	if(!RoundIsActive())
		return MRES_Ignored;
	
	if(StrContains(g_sClasses, TF2_ClassName[view_as<int>(TF2_GetPlayerClass(player)) - 1])  == -1)
		return MRES_Ignored;
	
	static char cls[9][12];
	int size = ExplodeString(g_sClasses, " ; ", cls, 9, 12);
	
	TFClassType curClass = TF2_GetPlayerClass(player);
	
	for (; size > 0; size--)
	{
		if(curClass == TF2_GetClass(cls[size - 1]))
		{
			EnableRegen();
			break;
		}
	}
	return MRES_Ignored;
}

public MRESReturn Post_RegenThink(int player)
{
	DisableRegen();
	return MRES_Ignored;
}

static void EnableRegen()
{
	for (int x; x < 6; x++)
		StoreToAddress(g_aRegenThink + view_as<Address>(x), 0x90, NumberType_Int8);
}

static void DisableRegen()
{
	for (int x; x < 6; x++)
		StoreToAddress(g_aRegenThink + view_as<Address>(x), OLD_Address[x], NumberType_Int8);
}
