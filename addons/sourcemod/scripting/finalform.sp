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
#include <tf2_stocks>

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
#define FRAME_RATE	66
#define POWER_LEVEL_STEP	5
#define POWER_UP_STUNFLAG  TF_STUNFLAG_SLOWDOWN  | TF_STUNFLAG_THIRDPERSON |  TF_STUNFLAG_NOSOUNDOREFFECT | TF_STUNFLAG_LIMITMOVEMENT

#define STEP_GLOW 50.0;

#define SOUND_BOOM		"weapons/explode3.wav"
#define SOUND_TELEPORT	"af_ff/tp.wav"
#define SOUND_AURUA 	"af_ff/au.wav"
#define SOUND_MELEE 	"af_ff/sk.wav"
#define SOUND_SWOOP 	"af_ff/sw.wav"
#define SOUND_DEATH 	"af_ff/dbc.wav"

#define SOUND_DEMO_YELL "vo/demoman_sf12_falling01.wav"
#define SOUND_HEAVY_YELL "vo/heavy_scram2012_falling01.wav"
#define SOUND_MEDIC_YELL "vo/medic_sf12_falling01.wav"
#define SOUND_SCOUT_YELL "vo/scout_sf12_falling01.wav"
#define SOUND_SOLDIER_YELL "vo/soldier_sf12_falling01.wav"
#define SOUND_SPY_YELL "vo/spy_sf12_falling01.wav"
#define SOUND_THUNDER "ambient/explosions/explode_9.wav"

new Float:gPowerLevels[MAXPLAYERS + 1];
new bool:gIsCharging[MAXPLAYERS + 1];

new SPRITE_FIRE;
new SPRITE_EXPLOSION;
new SPRITE_HALO;
new SPRITE_GLOW;
new SPRITE_SMOKE;
new SPRITE_LIGHTNING;
new gColor[4]     = {188, 220, 255, 255};
new Float:UP[3]   = {0.0, 0.0, 1.0};
new Float:DOWN[3] = {0.0, 1.0, 0.0};
new Float:gClock = 0.0;

public OnPluginStart()
{


	RegConsoleCmd("+sm_powerup", PowerupPlus);
	RegConsoleCmd("-sm_powerup", PowerupMinus);
	RegConsoleCmd("sm_instant_transmission", Command_Instant_Transmission);
	RegConsoleCmd("sm_tst1", tst1);
	RegConsoleCmd("sm_tst3", tst3);


	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);

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
	PrecacheSound(SOUND_SWOOP, true);
	PrecacheSound(SOUND_DEATH, true);

	PrecacheSound(SOUND_DEMO_YELL, true);
	PrecacheSound(SOUND_HEAVY_YELL, true);
	PrecacheSound(SOUND_MEDIC_YELL, true);
	PrecacheSound(SOUND_SCOUT_YELL, true);
	PrecacheSound(SOUND_SOLDIER_YELL, true);
	PrecacheSound(SOUND_SPY_YELL, true);

	PrecacheSound(SOUND_THUNDER, true);


	decl String:teleportPath[128];
	decl String:auruaPath[128];
	decl String:meleePath[128];
	decl String:swoopPath[128];
	decl String:deathPath[128];
	Format(teleportPath, sizeof(teleportPath), "sound/%s", SOUND_TELEPORT);
	Format(auruaPath, sizeof(auruaPath), "sound/%s", SOUND_AURUA);
	Format(meleePath, sizeof(meleePath), "sound/%s", SOUND_MELEE);
	Format(swoopPath, sizeof(swoopPath), "sound/%s", SOUND_SWOOP);
	Format(deathPath, sizeof(deathPath), "sound/%s", SOUND_DEATH);

	AddFileToDownloadsTable(teleportPath);
	AddFileToDownloadsTable(auruaPath);
	AddFileToDownloadsTable(meleePath);
	AddFileToDownloadsTable(swoopPath);
	AddFileToDownloadsTable(deathPath);

	SPRITE_FIRE      = PrecacheModel("materials/sprites/fire2.vmt");
	SPRITE_HALO      = PrecacheModel("materials/sprites/halo01.vmt");
	SPRITE_EXPLOSION = PrecacheModel("sprites/sprite_fire01.vmt");
	SPRITE_GLOW      = PrecacheModel("materials/sprites/blueglow2.vmt");
	SPRITE_SMOKE     = PrecacheModel("sprites/steam1.vmt");
	SPRITE_LIGHTNING = PrecacheModel("sprites/lgtning.vmt");
}

public OnClientDisconnect(client){
	gPowerLevels[client] = 0.0;
	gIsCharging[client] = false;
}



public Action:PowerupPlus(client, args){
	if (!Client_IsIngame(client) || !IsPlayerAlive(client)) {
		return Plugin_Handled;
	}
	startPowerup(client);
	

	return Plugin_Handled;	
}
public startPowerup(client){
	TF2_StunPlayer(client,
			TIME_STEP + 0.2,
			1.0,
			POWER_UP_STUNFLAG);
	gIsCharging[client] = true;

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1, 1);

	new String:sound[64];
	if(getYell(client, sound)){
		EmitSoundToAll(sound, client, SNDCHAN_VOICE, SNDLEVEL_AIRCRAFT, SND_NOFLAGS, SNDVOL_NORMAL);
	}


	EmitSoundToAll(SOUND_AURUA, client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL);

}



//On a melee hit, send player flying
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast){

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(gPowerLevels[attacker] > 50){
		//Only work if above a certain power level
		new weapon = GetEventInt(event, "weaponid");
		if( weapon == TF_WEAPON_BAT ||
				weapon == TF_WEAPON_BAT_WOOD ||
				weapon == TF_WEAPON_BOTTLE ||
				weapon == TF_WEAPON_FIREAXE ||
				weapon == TF_WEAPON_CLUB ||
				weapon == TF_WEAPON_CROWBAR ||
				weapon == TF_WEAPON_KNIFE ||
				weapon == TF_WEAPON_FISTS ||
				weapon == TF_WEAPON_SHOVEL ||
				weapon == TF_WEAPON_WRENCH ||
				weapon == TF_WEAPON_BONESAW ||
				weapon == TF_WEAPON_GRENADE_STUNBALL ||
				weapon == TF_WEAPON_GRENADE_JAR ||
				weapon == TF_WEAPON_GRENADE_JAR_MILK ||
				weapon == TF_WEAPON_JAR ||
				weapon == TF_WEAPON_SWORD ||
				weapon == TF_WEAPON_JAR_MILK ||
				weapon == TF_WEAPON_BAT_FISH ||
				weapon == TF_WEAPON_MECHANICAL_ARM ||
				weapon == TF_WEAPON_BAT_GIFTWRAP ||
				weapon == TF_WEAPON_GRENADE_ORNAMENT ||
				weapon == TF_WEAPON_CLEAVER ||
				weapon == TF_WEAPON_GRENADE_CLEAVER
			)
			{

				decl Float:vPos[3];
				GetClientAbsOrigin(attacker, vPos);
				pushPlayer(victim, vPos, gPowerLevels[attacker] * 60, true);
				EmitSoundToAll(SOUND_MELEE, attacker, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL);
				EmitSoundToAll(SOUND_SWOOP, victim, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL);

			}
	}

	return Plugin_Continue;
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){

	//Stop powering up on death
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(gIsCharging[client]){
		endPowerup(client);
	}

	return Plugin_Continue;
}
public Action:PowerupMinus(client, args){
	if (!Client_IsIngame(client) || !IsPlayerAlive(client)) {
		return Plugin_Handled;
	}

	endPowerup(client);

	return Plugin_Handled;	
}
public endPowerup(client){
	gIsCharging[client] = false;
	//gPowerLevels[client] = 0.0;

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0, 1);

	new String:sound[64];
	if(getYell(client, sound)){
		StopSound(client, SNDCHAN_VOICE, sound);
	}
	StopSound(client, SNDCHAN_AUTO, SOUND_AURUA);

}

/**
  Do calculations for every player if they are charging up
 */
public Action:PowerStep(Handle:timer){
	gClock += 0.1;

	for (new client=1; client <= MaxClients; client++){
		if(gIsCharging[client]){
			gPowerLevels[client] += POWER_LEVEL_STEP;

			//Prevent player from moving
			TF2_StunPlayer(client,
					TIME_STEP + 0.2,
					1.0,
					POWER_UP_STUNFLAG);

			Entity_AddHealth(client, 10);

			applyChargingEffects(client);

		}
		if(gPowerLevels[client] > 200.0){
			//Low power level
			//Roll die for a lightning strike
			if(GetRandomInt(0, 128) == 0){
				lightningStrike(client);
			}

		}if(gPowerLevels[client] > 50.0){
			//High power level
			//Roll die for a lightning strike
			if(GetRandomInt(0, 16) == 0){
				lightningStrike(client);
			}

			glowEffect(client);

		}

	}

	CreateTimer(TIME_STEP, PowerStep);
}
/**
  Apply an effect to every client, from a clien
 */
public applyChargingEffects(from){
	decl Float:vPos[3];
	GetClientAbsOrigin(from, vPos);

	new Float:powerLevel = gPowerLevels[from];

	TE_SetupBeamRingPoint(vPos, 10.0, 15.0 + (0.25 * powerLevel), SPRITE_FIRE, SPRITE_HALO, 0, FRAME_RATE, TIME_STEP * 3, 128.0, 0.2, gColor, 25, 0);
	TE_SendToAll();
	TE_SetupSmoke(vPos, SPRITE_HALO, 10.0 + (0.25 * powerLevel), FRAME_RATE);
	TE_SendToAll();
	TE_SetupSparks(vPos, UP, 10, 15);
	TE_SendToAll();

	for (new client=1; client <= MaxClients; client++){
		if (!Client_IsIngame(client) || !IsPlayerAlive(client)) {
			//Ignore players we don't care about
			continue;
		}

		//new Float:coefficient = powerLevel / Pow((Entity_GetDistance(from, client) + 1), 2.0);
		new Float:coefficient = powerLevel * 30  / Pow((Entity_GetDistance(from, client) + 1), 2.2);
		if(coefficient > 0.0001){
			pushPlayer(client, vPos, coefficient * 6000, false);
			Client_Shake(client,
					SHAKE_START,
					5.0,
					600 * coefficient,
					TIME_STEP * 3);
		}

	}

}

public pushPlayer(victim, Float:fromOrigin[3], Float:force, bool:flying){
	new Float:vector[3];
	new Float:victimOrigin[3], Float:victimVelocity[3];

	Entity_GetAbsVelocity(victim, victimVelocity);

	//Build push vector
	GetClientAbsOrigin(victim, victimOrigin);
	MakeVectorFromPoints(fromOrigin, victimOrigin, vector);
	NormalizeVector(vector, vector);
	ScaleVector(vector, force);

	AddVectors(vector, victimVelocity, victimVelocity);
	if(flying){
		//Avoid friction
		victimVelocity[2] = 900.0;
	}

	Entity_SetAbsVelocity(victim, victimVelocity);
	//TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vector);
}

/**
  Start the class specific falling yell
 */
public bool:getYell(client, String:sound[64]){

	switch(TF2_GetPlayerClass(client)){
		case TFClass_Scout:
			{
				Format(sound, sizeof(sound), "%s", SOUND_SCOUT_YELL);
				return true;
			}
		case TFClass_Soldier:
			{
				Format(sound, sizeof(sound), "%s", SOUND_SOLDIER_YELL);
				return true;
			}
		case TFClass_DemoMan:
			{
				Format(sound, sizeof(sound), "%s", SOUND_DEMO_YELL);
				return true;
			}
		case TFClass_Heavy:
			{
				Format(sound, sizeof(sound), "%s", SOUND_HEAVY_YELL);
				return true;
			}
		case TFClass_Medic:
			{
				Format(sound, sizeof(sound), "%s", SOUND_MEDIC_YELL);
				return true;
			}
		case TFClass_Spy:
			{
				Format(sound, sizeof(sound), "%s", SOUND_SPY_YELL);
				return true;
			}
		default:
			{
				return false;
			}
	}
	return false;

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

public glowEffect(client){
	decl Float:vPos[3];
	new Float:powerLevel = gPowerLevels[client];
	new brightness;
	GetClientAbsOrigin(client, vPos);
	vPos[2] +=200;
	brightness = RoundFloat((0.25 * powerLevel) + Sine(gClock) * 25.0); //Builds an oscilating effect
	TE_SetupGlowSprite(vPos, SPRITE_EXPLOSION, TIME_STEP * 3, 0.5, brightness);
	TE_SendToAll();

}
public lightningStrike(client){
	decl Float:vPos[3];
	GetClientAbsOrigin(client, vPos);
	//Randomize position
	vPos[0] = vPos[0] + GetRandomInt(-128, 128);
	vPos[1] = vPos[1] + GetRandomInt(-128, 128);
	vPos[2] -= 26; // increase y-axis by 26 to strike at player's chest instead of the ground

	// define where the lightning strike starts
	decl Float:vStart[3];
	vStart[0] = vPos[0];
	vStart[1] = vPos[1];
	vStart[2] = vPos[2] + 800;



	TE_SetupBeamPoints(vStart, vPos, SPRITE_LIGHTNING, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, gColor, 3);
	TE_SendToAll();

	TE_SetupSparks(vPos, UP, 5000, 1000);
	TE_SendToAll();

	TE_SetupEnergySplash(vPos, UP, false);
	TE_SendToAll();

	TE_SetupSmoke(vPos, SPRITE_SMOKE, 5.0, 10);
	TE_SendToAll();


	EmitSoundToAll(SOUND_THUNDER, client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL);
}


public Action:tst1(client, args){
	PrintToChatAll("Hit tst1");
	if (!client) {
		return Plugin_Handled;
	}

	decl String:searchKey[64];
	GetCmdArg(1, searchKey, sizeof(searchKey));


	new target = Client_FindByName(searchKey);
	startPowerup(target);

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
	endPowerup(target);

	return Plugin_Handled;
}
