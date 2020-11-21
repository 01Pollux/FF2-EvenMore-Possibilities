#if defined CLASSES_REGEN
	#endinput
#endif
#define CLASSES_REGEN

static int nOldBytes[6];
static Address pRegenThink;

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
	
	if((pRegenThink = Config.GetAddress("CTFPlayer::RegenThink [is player medic]")) == Address_Null)
		return false;
	
	for(int i; i < 6; i++)
		nOldBytes[i] = LoadFromAddress(pRegenThink + view_as<Address>(i), NumberType_Int8);
	
	cv_AllowedClasses = CreateConVar("rt_classes", "sniper ; heavy ; spy ; engineer", "Allow Those classes to get regenerated over time");
	cv_AllowedClasses.GetString(g_sClasses, sizeof(g_sClasses));
	
	cv_AllowedClasses.AddChangeHook(OnClassesChange);
	
	return true;
}

public void OnClassesChange(ConVar cConVar, const char[] oldVal, const char[] newVal)
{
	cv_AllowedClasses.GetString(g_sClasses, sizeof(g_sClasses));
}

static bool bCanRegen = false;
public MRESReturn Pre_RegenThink(int player)
{
	if(!RoundIsActive()) {
		return MRES_Ignored;
	}
	
	FF2Player ff2player = FF2Player(player);
	if(ff2player.bIsBoss) {
		return MRES_Ignored;
	}
	
	bCanRegen = false;
	
	if(StrContains(g_sClasses, TF2_ClassName[view_as<int>(TF2_GetPlayerClass(player))])  == -1) {
		return MRES_Ignored;
	}
	
	bCanRegen = true;
	for(int i; i < 6; i++)
		StoreToAddress(pRegenThink + view_as<Address>(i), 0x90, NumberType_Int8);
	
	return MRES_Ignored;
}

public MRESReturn Post_RegenThink(int player) 
{
	if(bCanRegen){
		for(int i; i < 6; i++) {
			StoreToAddress(pRegenThink + view_as<Address>(i), nOldBytes[i], NumberType_Int8);
		}
		bCanRegen = false;
	}
	return MRES_Ignored;
}
