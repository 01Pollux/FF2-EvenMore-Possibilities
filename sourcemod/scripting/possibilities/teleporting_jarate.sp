#if defined TELEPORING_JARATE
	#endinput
#endif
#define TELEPORING_JARATE

static ConVar g_AllowScout;
static ConVar g_AllowPyro;

public bool Teleport_PrepareConfig(const GameData Config)
{
	Handle JarExplode = DHookCreateFromConf(Config, "JarExplode");
	if(JarExplode == null)
		return false;
	else if(!DHookEnableDetour(JarExplode, false, Pre_JarExplode))
		return false;
	
	g_AllowScout = CreateConVar("tj_allowscout", "0", "Allow Scouts to use Madmilk to teleport");
	g_AllowPyro = CreateConVar("tj_allowpyro", "0", "Allow Pyros to use Gas Tank to teleport");
	return true;
}

public MRESReturn Pre_JarExplode(Handle Params)
{
	int owner = DHookGetParam(Params, 2);
	
	if(!IsPlayerAlive(owner))
		return MRES_Ignored;
	
	if(FF2_GetBossIndex(owner) > -1)
		return MRES_Ignored;
	
	if(TF2_GetPlayerClass(owner) == TFClass_Scout && !g_AllowScout.BoolValue)
		return MRES_Ignored;
	
	else if(TF2_GetPlayerClass(owner) == TFClass_Scout && !g_AllowPyro.BoolValue)
		return MRES_Ignored;
	
	static float Pos[3], EndPos[3];
	DHookGetParamVector(Params, 5, Pos);
	
	if(IsValidPointToTeleport(owner, Pos, EndPos))
		TeleportEntity(owner, EndPos, NULL_VECTOR, NULL_VECTOR);
		
	return MRES_Ignored;
}

bool IsValidPointToTeleport(int client, const float Position[3], float EndPosition[3])
{
	static float vecMaxs[3], vecMins[3];
	
	GetClientMaxs(client, vecMaxs);
	GetClientMins(client, vecMins);
	
	Handle Trace = TR_TraceHullFilterEx(Position, Position, vecMins, vecMaxs, MASK_PLAYERSOLID, Trace_CheckIfStuck, client);
	
	if(!TR_DidHit(Trace))
	{
		EndPosition = Position;
		delete Trace;
		return true;
	}
	delete Trace;
	static float TestPosition[3];
	for (int x; x <= 9; x++)
	{
		for (int y; y <= 9; y++)
		{
			for (int z; z <= 9; z++)
			{
				TestPosition = Position;
				
				switch(x)
				{
					case 0: TestPosition[0] = TestPosition[0] < 0 ? TestPosition[0] + 10.0:TestPosition[0] -10.0;
					case 1: TestPosition[0] = TestPosition[0] > 0 ? TestPosition[0] + 10.0:TestPosition[0] -10.0;
					case 2: TestPosition[0] = TestPosition[0] < 0 ? TestPosition[0] + 15.0:TestPosition[0] -15.0;
					case 3: TestPosition[0] = TestPosition[0] > 0 ? TestPosition[0] + 15.0:TestPosition[0] -15.0;
					case 4: TestPosition[0] = TestPosition[0] < 0 ? TestPosition[0] + 20.0:TestPosition[0] -20.0;
					case 5: TestPosition[0] = TestPosition[0] > 0 ? TestPosition[0] + 20.0:TestPosition[0] -20.0;
					case 6: TestPosition[0] = TestPosition[0] < 0 ? TestPosition[0] + 30.0:TestPosition[0] -30.0;
					case 7: TestPosition[0] = TestPosition[0] > 0 ? TestPosition[0] + 30.0:TestPosition[0] -30.0;
					case 8: TestPosition[0] = TestPosition[0] < 0 ? TestPosition[0] + 50.0:TestPosition[0] -50.0;
					case 9: TestPosition[0] = TestPosition[0] > 0 ? TestPosition[0] + 50.0:TestPosition[0] -50.0;
				}
				switch(y)
				{
					case 0: TestPosition[1] = TestPosition[1] < 0 ? TestPosition[1] + 10.0:TestPosition[1] -10.0;
					case 1: TestPosition[1] = TestPosition[1] > 0 ? TestPosition[1] + 10.0:TestPosition[1] -10.0;
					case 2: TestPosition[1] = TestPosition[1] < 0 ? TestPosition[1] + 15.0:TestPosition[1] -15.0;
					case 3: TestPosition[1] = TestPosition[1] > 0 ? TestPosition[1] + 15.0:TestPosition[1] -15.0;
					case 4: TestPosition[1] = TestPosition[1] < 0 ? TestPosition[1] + 20.0:TestPosition[1] -20.0;
					case 5: TestPosition[1] = TestPosition[1] > 0 ? TestPosition[1] + 20.0:TestPosition[1] -20.0;
					case 6: TestPosition[1] = TestPosition[1] < 0 ? TestPosition[1] + 30.0:TestPosition[1] -30.0;
					case 7: TestPosition[1] = TestPosition[1] > 0 ? TestPosition[1] + 30.0:TestPosition[1] -30.0;
					case 8: TestPosition[1] = TestPosition[1] < 0 ? TestPosition[1] + 00:TestPosition[1] -50.0;
					case 9: TestPosition[1] = TestPosition[1] > 0 ? TestPosition[1] + 00:TestPosition[1] -50.0;
				}
				switch(z)
				{
					case 0: TestPosition[2] = TestPosition[2] < 0 ? TestPosition[2] + 10.0:TestPosition[2] -10.0;
					case 1: TestPosition[2] = TestPosition[2] > 0 ? TestPosition[2] + 10.0:TestPosition[2] -10.0;
					case 2: TestPosition[2] = TestPosition[2] < 0 ? TestPosition[2] + 15.0:TestPosition[2] -15.0;
					case 3: TestPosition[2] = TestPosition[2] > 0 ? TestPosition[2] + 15.0:TestPosition[2] -15.0;
					case 4: TestPosition[2] = TestPosition[2] < 0 ? TestPosition[2] + 20.0:TestPosition[2] -20.0;
					case 5: TestPosition[2] = TestPosition[2] > 0 ? TestPosition[2] + 20.0:TestPosition[2] -20.0;
					case 6: TestPosition[2] = TestPosition[2] < 0 ? TestPosition[2] + 30.0:TestPosition[2] -30.0;
					case 7: TestPosition[2] = TestPosition[2] > 0 ? TestPosition[2] + 30.0:TestPosition[2] -30.0;
					case 8: TestPosition[2] = TestPosition[2] < 0 ? TestPosition[2] + 50.0:TestPosition[2] -50.0;
					case 9: TestPosition[2] = TestPosition[2] > 0 ? TestPosition[2] + 50.0:TestPosition[2] -50.0;
				}
					
				Trace = TR_TraceHullFilterEx(TestPosition, TestPosition, vecMins, vecMaxs, MASK_PLAYERSOLID, Trace_CheckIfStuck, client);
				if(!TR_DidHit(Trace))
				{
					EndPosition = TestPosition;
					delete Trace;
					return true;
				}
				delete Trace;
			}
		}
	}	
	return false;
}

public bool Trace_CheckIfStuck(int entity, int content, any client)
{
	if(!entity)
		return false;
	
	if(GetClientTeam(client) == GetClientTeam(entity))
		return false;
		
	if(client == entity)
		return false;
	
	return true;
}
