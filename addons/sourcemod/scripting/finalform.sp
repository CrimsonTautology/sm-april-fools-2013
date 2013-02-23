
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
	RegConsoleCmd("sm_tst1", tst1);
	RegConsoleCmd("sm_tst2", tst2);
	RegConsoleCmd("sm_tst3", tst3);
	RegConsoleCmd("sm_tst4", tst4);
	RegConsoleCmd("sm_tst5", tst5);
	RegConsoleCmd("sm_tst6", tst6);
	RegConsoleCmd("sm_tst7", tst7);
	RegConsoleCmd("sm_tst8", tst8);
	RegConsoleCmd("sm_tst9", tst9);
	RegConsoleCmd("sm_tst10", tst10);
	RegConsoleCmd("sm_tst11", tst11);
}


public Action:Command_Powerup(client, args){
	if (!client) {
		return Plugin_Handled;
	}

	if (args == 0) {
		ReplyToCommand(client, "[SM] Nomgrep Incorrect Syntax:  !nomsearch <searchstring>");
		return Plugin_Handled;
	}

	return Plugin_Continue;	
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
	decl String:searchKey[64];
	GetCmdArg(1, searchKey, sizeof(searchKey));

	Client_Shake(client);
	new target = Client_FindByName(searchKey);
	EmitShake(target);
	EmitForce(target);

	return Plugin_Continue;
}

public Action:tst2(client, args){
	return Plugin_Continue;
}
public Action:tst3(client, args){
	return Plugin_Continue;
}
public Action:tst4(client, args){
	return Plugin_Continue;
}
public Action:tst5(client, args){
	return Plugin_Continue;
}
public Action:tst6(client, args){
	return Plugin_Continue;
}
public Action:tst7(client, args){
	return Plugin_Continue;
}
public Action:tst8(client, args){
	return Plugin_Continue;
}
public Action:tst9(client, args){
	return Plugin_Continue;
}
public Action:tst10(client, args){
	return Plugin_Continue;
}
public Action:tst11(client, args){
	return Plugin_Continue;
}
