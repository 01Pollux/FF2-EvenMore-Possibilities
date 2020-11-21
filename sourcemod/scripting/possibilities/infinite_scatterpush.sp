#if defined FAN_FORCE_SCATTER
	#endinput
#endif
#define FAN_FORCE_SCATTER

enum struct _SPConVars {
	ConVar unlimited_pushes;
	ConVar weapon_indexes;
}
static _SPConVars sp_cvars;

methodmap WeaponPoolList < ArrayList {
	public WeaponPoolList()
	{
		return view_as<WeaponPoolList>(new ArrayList());
	}
	
	public bool WeaponExists(const int index)
	{
		return this.FindValue(index) != -1;
	}
	
	public void RemoveWeapon(const int index)
	{
		int pos = this.FindValue(index);
		if(pos != -1)
			this.Erase(pos);
	}
	
	public void AddWeapon(const int index)
	{
		int pos = this.FindValue(index);
		if(pos == -1)
			this.Push(index);
	}
	
	public void EraseAll()
	{
		this.Clear();
	}
}
static WeaponPoolList weapon_list;

static int nOldBytes[6];
static Address pScatterSelfForce;
static Address pUnlimitedFAN;

public bool FaN_PrepareConfig(GameData Config)
{
	Handle OnFireBullet = DHookCreateFromConf(Config, "CTFScattergun::FireBullet");
	if(OnFireBullet == null)
		return false;
	else if(!DHookEnableDetour(OnFireBullet, false, Pre_ScatterFireBullet))
		return false;
	else if(!DHookEnableDetour(OnFireBullet, true, Post_ScatterFireBullet))
		return false;
	
	if((pScatterSelfForce = Config.GetAddress("CTFScattergun::FireBullet [allow all scatterguns]")) == Address_Null)
		return false;
	for(int i; i < 6; i++)
		nOldBytes[i] = LoadFromAddress(pScatterSelfForce + view_as<Address>(i), NumberType_Int8);
	
	if((pUnlimitedFAN = Config.GetAddress("CTFScattergun::FireBullet [set push]")) == Address_Null)
		return false;
	
	weapon_list = new WeaponPoolList();
	
	sp_cvars.unlimited_pushes = CreateConVar("up_max_fanpush", "0", "Unlimited Pushes for FaN");
	(sp_cvars.weapon_indexes = CreateConVar("up_weapons", "1103;220", "Allow these to apply FaN push effect")).AddChangeHook(OnWeaponIdxChange);
	
	return true;
}

public void OnWeaponIdxChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	weapon_list.EraseAll();
	char[][] list = new char[6][PLATFORM_MAX_PATH];
	int count = ExplodeString(oldVal, ";", list, 6, PLATFORM_MAX_PATH);
	
	while(count > 0)
	{
		count--;
		weapon_list.AddWeapon(StringToInt(list[count]));
	}
}

public MRESReturn Pre_ScatterFireBullet(int weapon, Handle Params)
{
	if(!RoundIsActive())
		return MRES_Ignored;
	
	FF2Player player = FF2Player(DHookGetParam(Params, 1));
	if(player.bIsBoss)
		return MRES_Ignored;
		
	if(sp_cvars.unlimited_pushes.BoolValue)
		UnLimitedFan();
	
	int index = GetItemDefinitionIndex(weapon);
	if(!weapon_list.WeaponExists(index))
		return MRES_Ignored;
		
	EnableScatterFaN();
	return MRES_Ignored;
}

public MRESReturn Post_ScatterFireBullet(int weapon, Handle Player)
{
	LimitedFan();
	DisableScatterFaN();
}


static void EnableScatterFaN()
{
	for(int i; i < 6; i++)
		StoreToAddress(pScatterSelfForce + view_as<Address>(i), 0x90, NumberType_Int8);
}

static void UnLimitedFan()
{
	StoreToAddress(pUnlimitedFAN, 0x00, NumberType_Int8);
}

static void DisableScatterFaN()
{
	for(int i; i < 6; i++)
		StoreToAddress(pScatterSelfForce + view_as<Address>(i), nOldBytes[i], NumberType_Int8);
}

static void LimitedFan()
{
	StoreToAddress(pUnlimitedFAN, 0x01, NumberType_Int8);
}