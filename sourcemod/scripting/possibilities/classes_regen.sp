#if defined CLASSES_REGEN
	#endinput
#endif
#define CLASSES_REGEN

static Address g_aRegenThink = Address_Null;
static int OLD_Address[6];

static ConVar cv_AllowedClasses;
static char g_sClasses[78];

static const char TF2_ClassName[][] = {
	"none",
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
	
	cv_AllowedClasses.AddChangeHook(OnClassesChange);
	
	return true;
}
public void OnClassesChange(ConVar cConVar, const cvar[] oldVal, const char[] newVal)
{
	cv_AllowedClasses.GetString(g_sClasses, sizeof(g_sClasses));
}

static bool bCanRegen = false;
public MRESReturn Pre_RegenThink(int player)
{
	if(!RoundIsActive())
		return MRES_Ignored;
		
	if(FF2_GetBossIndex(player) > -1)
		return MRES_Ignored;
	
	bCanRegen = false;
	
	if(StrContains(g_sClasses, TF2_ClassName[view_as<int>(TF2_GetPlayerClass(player))])  == -1)
		return MRES_Ignored;
	
	bCanRegen = true;
	EnableRegen();
	
	return MRES_Ignored;
}

public MRESReturn Post_RegenThink(int player) 
{
	if(bCanRegen){
		DisableRegen();
		bCanRegen = false;
	}
	return MRES_Ignored;
}

static void EnableRegen() {
	for (int x; x < 6; x++)
		StoreToAddress(g_aRegenThink + view_as<Address>(x), 0x90, NumberType_Int8);
}

static void DisableRegen() {
	for (int x; x < 6; x++)
		StoreToAddress(g_aRegenThink + view_as<Address>(x), OLD_Address[x], NumberType_Int8);
}
