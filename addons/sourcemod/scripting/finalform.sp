
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

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Final Form",
	author = "Billehs",
	version = "0.1",
	description = "Power up and shit",
	url = "https://github.com/CrimsonTautology/sm_finalform"
};


#define WAVE_STEP 60
new gPowerLevels[MAXPLAYERS + 1];
new bool:gIsCharging[MAXPLAYERS + 1];

public OnPluginStart()
{


	RegConsoleCmd("sm_powerup", Command_Powerup);
	RegConsoleCmd("sm_instant_transmission", Command_Instant_Transmission);
	RegConsoleCmd("sm_tst1", tst1);
	RegConsoleCmd("sm_tst2", Command_Tst2);
	RegConsoleCmd("sm_tst3", tst3);
	RegConsoleCmd("sm_tst4", tst4);
	RegConsoleCmd("sm_tst5", tst5);
}

/**
	Precache custom sounds
*/
public OnMapStart(){
	CreateTimer(0.1, LoadSounds);
}
public Action:LoadSounds(Handle:timer){

	PrecacheSound("af_ff/au.wav", true);
	AddFileToDownloadsTable("sounds/af_ff/au.wav");
	PrecacheSound("af_ff/dbc.wav", true);
	AddFileToDownloadsTable("sounds/af_ff/dbc.wav");
	PrecacheSound("af_ff/sk.wav", true);
	AddFileToDownloadsTable("sounds/af_ff/sk.wav");
	PrecacheSound("af_ff/sw.wav", true);
	AddFileToDownloadsTable("sounds/af_ff/sw.wav");
	PrecacheSound("af_ff/tp.wav", true);
	AddFileToDownloadsTable("sounds/af_ff/tp.wav");
}


public Action:Command_Powerup(client, args){
	if (!client) {
		return Plugin_Handled;
	}


	if (args == 0) {
		ReplyToCommand(client, "[SM]FFFFFFF Nomgrep Incorrect Syntax:  !nomsearch <searchstring>");
		return Plugin_Handled;
	}

	return Plugin_Continue;	
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
	decl Float:vTargetLook[3], Float:vTargetPos[3], Float:vNewPos[3];
	decl Float:vOffsetPos[3];

	GetClientAbsOrigin(target, vTargetPos);
	GetClientAbsAngles(target, vTargetLook);

	NormalizeVector(vTargetLook, vOffsetPos);
	vOffsetPos[0] *=-10.0;
	vOffsetPos[1] *=0.0;
	vOffsetPos[2] *=-10.0;

	vTargetLook[1] = 0.0;
		
		//TODO add teleport effect
	TeleportEntity(client, vTargetPos, NULL_VECTOR, NULL_VECTOR);
	EmitSoundToAll("af_ff/tp.wav",
		client,
		SNDCHAN_AUTO,
		SNDLEVEL_MINIBIKE
		);
}


/**
 * A given client will emit a shake that effects players based on his powerlevel
 * and their distance to him.
 */
public EmitShake(client){
	//for (new i=0; )

}
/**
 * A given client will emit a force that pushes players back based on his
 * powerlevel and their distance to him.
 */
public EmitForce(client){

}
public Action:tst1(client, args){
	PrintToChatAll("Hit tst1");
	if (!client) {
		return Plugin_Handled;
	}

	decl String:searchKey[64];
	GetCmdArg(1, searchKey, sizeof(searchKey));


	Client_Shake(client);
	new target = Client_FindByName(searchKey);
	EmitShake(target);
	EmitForce(target);

	return Plugin_Handled;
}

public Action:Command_Tst2(client, args){
	PrintToChatAll("Hit tst2");
	return Plugin_Handled;
}
public Action:tst3(client, args){
	PrintToChatAll("Hit tst3jk");
	return Plugin_Handled;
}
public Action:tst4(client, args){
	return Plugin_Handled;
}
public Action:tst5(client, args){
	return Plugin_Handled;
}
