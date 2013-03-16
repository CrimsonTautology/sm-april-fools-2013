
/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Nonsense Plugin
 * Looks like I'll have to go into my final form.
 *
 *
 * =============================================================================
 *
 */

#include <sourcemod>
#include <smlib>
#include <sdktools>
#include <tf2>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Final Form",
	author = "Billehs",
	version = "0.1",
	description = "Power up and shit",
	url = "https://github.com/CrimsonTautology/sm_finalform"
};

#define TIME_STEP	0.1
#define POWER_LEVEL_STEP	5
#define POWER_UP_STUNFLAG  TF_STUNFLAG_SLOWDOWN  | TF_STUNFLAG_THIRDPERSON |  TF_STUNFLAG_NOSOUNDOREFFECT | TF_STUNFLAG_LIMITMOVEMENT

#define SOUND_BOOM		"weapons/explode3.wav"
#define SOUND_TELEPORT	"af_ff/tp.wav"
#define SOUND_AURUA 	"af_ff/au.wav"
#define SOUND_MELEE 	"af_ff/sk.wav"

new Float:gPowerLevels[MAXPLAYERS + 1];
new bool:gIsCharging[MAXPLAYERS + 1];

public OnPluginStart()
{


	RegConsoleCmd("+sm_powerup", StartPowerup);
	RegConsoleCmd("-sm_powerup", EndPowerup);
	RegConsoleCmd("sm_instant_transmission", Command_Instant_Transmission);
	RegConsoleCmd("sm_tst1", tst1);
	RegConsoleCmd("sm_tst3", tst3);

	RegConsoleCmd("sm_tst2", Command_Tst2);
	RegConsoleCmd("sm_tst4", tst4);
	RegConsoleCmd("sm_tst5", tst5);


	CreateTimer(TIME_STEP, PowerStep);
}

/**
	Precache custom sounds
*/
public OnMapStart(){

	PrecacheSound(SOUND_BOOM, true);
	PrecacheSound(SOUND_TELEPORT, true);
	PrecacheSound(SOUND_AURUA, true);
	PrecacheSound(SOUND_MELEE, true);

	decl String:teleportPath[128];
	decl String:auruaPath[128];
	decl String:meleePath[128];
	Format(teleportPath, sizeof(teleportPath), "sound/%s", SOUND_TELEPORT);
	Format(auruaPath, sizeof(auruaPath), "sound/%s", SOUND_AURUA);
	Format(meleePath, sizeof(meleePath), "sound/%s", SOUND_MELEE);

	AddFileToDownloadsTable(teleportPath);
	AddFileToDownloadsTable(auruaPath);
	AddFileToDownloadsTable(meleePath);
}

public OnClientDisconnect(client){
	gPowerLevels[client] = 0.0;
	gIsCharging[client] = false;
}



public Action:StartPowerup(client, args){
	if (!Client_IsIngame(client) || !IsPlayerAlive(client)) {
		return Plugin_Handled;
	}
	PrintToChatAll("%d StartPowerup", client);
	TF2_StunPlayer(client,
			TIME_STEP + 0.2,
			1.0,
			POWER_UP_STUNFLAG);
	gIsCharging[client] = true;
	EmitSoundToAll(SOUND_AURUA, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL);

	return Plugin_Continue;	
}
public Action:EndPowerup(client, args){
	if (!Client_IsIngame(client) || !IsPlayerAlive(client)) {
		return Plugin_Handled;
	}
	PrintToChatAll("%d EndPowerup", client);
	gIsCharging[client] = false;
	gPowerLevels[client] = 0.0;
	StopSound(client, SNDCHAN_AUTO, SOUND_AURUA);

	return Plugin_Continue;	
}

/**
	Do calculations for every player if they are charging up
 */
public Action:PowerStep(Handle:timer){

	for (new client=1; client <= MaxClients; client++){
		if(!gIsCharging[client]){
			//Ignore players who are not currently charging
			continue;
		}

		gPowerLevels[client] += POWER_LEVEL_STEP;
		TF2_StunPlayer(client,
				TIME_STEP + 0.2,
				1.0,
				POWER_UP_STUNFLAG);
	
		new String:name[64];
		GetClientName(client, name, sizeof(name));
		PrintToChatAll("%s at %f", name, gPowerLevels[client]);
		applyEffects(client);

	}

	CreateTimer(TIME_STEP, PowerStep);
}
/**
  Apply an effect to every client, from a clien
*/
public applyEffects(from){
	for (new client=1; client <= MaxClients; client++){
		if (!Client_IsIngame(client) || !IsPlayerAlive(client)) {
			//Ignore players we don't care about
			continue;
		}

		new Float:coefficient = gPowerLevels[from] / Pow((Entity_GetDistance(from, client) + 1), 2.0);
		if(coefficient > 0.01){
			Client_Shake(client,
					SHAKE_START,
					5.0,
					600 * coefficient,
					TIME_STEP * 3);
		}

	}

}

/**
  Get the target client that client is looking at and teleport at them.
 */
public Action:Command_Instant_Transmission(client, args){
	new target = GetClientAimTarget(client, true);
	if(target >= 0){
		teleport(client, target);
	}
	return Plugin_Handled;
}


/**
  Teleport client just behind target.
 */
public teleport(client, target){
	decl Float:vTargetAng[3], Float:vTargetVel[3], Float:vTargetPos[3], Float:vNewPos[3];
	decl Float:vOffsetPos[3];

	GetClientAbsOrigin(target, vTargetPos);
	GetClientEyeAngles(target, vTargetAng);
	GetAngleVectors(vTargetAng, vTargetVel, NULL_VECTOR, NULL_VECTOR);


	NormalizeVector(vTargetVel, vOffsetPos);
	ScaleVector(vOffsetPos, -60.0);
	AddVectors(vTargetPos, vOffsetPos, vNewPos);
	vOffsetPos[2] = vTargetPos[2];
	vTargetAng[0] = 0.0;
	vTargetAng[2] = 0.0;


	//TODO add teleport effect
	TeleportEntity(client, vNewPos, vTargetAng, vTargetVel);
	EmitAmbientSound(SOUND_TELEPORT, vNewPos, client, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL);
}


public Action:tst1(client, args){
	PrintToChatAll("Hit tst1");
	if (!client) {
		return Plugin_Handled;
	}

	decl String:searchKey[64];
	GetCmdArg(1, searchKey, sizeof(searchKey));


	new target = Client_FindByName(searchKey);
	gIsCharging[target] = true;

	return Plugin_Handled;
}

public Action:Command_Tst2(client, args){
	PrintToChatAll("Hit tst2");
	return Plugin_Handled;
}
public Action:tst3(client, args){
	PrintToChatAll("Hit tst3");
	if (!client) {
		return Plugin_Handled;
	}

	decl String:searchKey[64];
	GetCmdArg(1, searchKey, sizeof(searchKey));


	new target = Client_FindByName(searchKey);
	gIsCharging[target] = false;

	return Plugin_Handled;
}
public Action:tst4(client, args){
	return Plugin_Handled;
}
public Action:tst5(client, args){
	return Plugin_Handled;
}
