#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bots_util;

#include maps\mp\agents\_agent_utility;
#include maps\mp\gametypes\_horde_util;
#include maps\mp\gametypes\_horde_laststand;
#include maps\mp\gametypes\_horde_crates;

#include maps\mp\gametypes\horde;
#include maps\mp\killstreaks\_airdrop;
#include maps\mp\gametypes\_class;


main()
{
    replaceFunc(  maps\mp\gametypes\horde::onSpawnPlayer, ::onSpawnPlayer_ );
	replaceFunc(  maps\mp\gametypes\horde::onSpawnFinished, ::onSpawnFinished_ ); 
	
	replaceFunc(  maps\mp\gametypes\horde::onPlayerConnectHorde, ::onPlayerConnectHorde_ ); 

	replaceFunc(  maps\mp\gametypes\_horde_laststand::gameShouldEnd, ::gameShouldEnd_ );
	replaceFunc(  maps\mp\gametypes\horde::runHordeMode, ::runHordeMode_ );

	replaceFunc(  maps\mp\gametypes\_horde_crates::createHordeCrates, ::createHordeCrates_ );
	replaceFunc(  maps\mp\gametypes\_horde_crates::setupLootCrates, ::setupLootCrates_ ); 
}


init()
{
	level.specialRoundTime = 50; // 50
}

onPlayerConnectHorde_()
{
	while ( true )
	{
		level waittill( "connected", player );
	
		player.gameModefirstSpawn = true;
		player.hasUsedSquadMate	= false;

		player.bar = player createBar((0, 0, 0), 75, 80);
		player.bar.x = 13;                        
		player.bar.y = 365;                        
		player.bar.alpha = 0.1;                    
		player.bar.HideWhenInMenu = true;      

		thread onJoinedTeam( player );
		player thread monitor_points_();
	}
}

onJoinedTeam( player )
{
	player endon("disconnect");

	while ( true )
	{
		player waittill( "joined_team" );
		
		player thread shop_command();

		level thread createPlayerVariables( player ); 
		level thread monitorDoubleTap( player ); 
		level thread monitorStuck( player );
		level thread updateOutlines( player );
	}
}

revive_horde()
{
	thread respawnEliminatedPlayers();
	IPrintLnBold("^2PLAYERS REVIVED");
}

gameShouldEnd_( player )
{
	isAnyPlayerStillActive = false;
	
	foreach( activePlayer in level.participants )
	{

		if( (player == activePlayer) && !hasAgentSquadMember(player) && player.pers["score"] == 0 ) 
			continue;
		
		if( !isOnHumanTeam(activePlayer) )
			continue;

		if( isPlayerInLastStand(activePlayer) && !hasAgentSquadMember(activePlayer) && player.pers["score"] == 0 )
			continue;
		
		if( !IsDefined(activePlayer.sessionstate) || (activePlayer.sessionstate != "playing") )
			continue;
		
		isAnyPlayerStillActive = true;
		break;
	}
	
	return !isAnyPlayerStillActive;
}

shop_command()
{
	if( !IsDefined(self.shop_name) )
	{
	self.shop_name = self createFontString( "objective", 1.3 );
	self.shop_name.hideWhenInMenu = true;
	self.shop_name setPoint( "TOP", "TOP", 0, 5 );
	self.shop_name setText( "^:SHOP" );
	self.shop_name.alpha = 0;	
	}

	if( !IsDefined(self.shop_display) )
	{
	shop_text = "^5 {NUKE} ^2(250) ^1!nuk ^5| {ODIN} ^2(250) ^1!odi ^5| {REVIVE RESPAWN ALL} ^2(100) ^1!rev \n" + "\n" + "^2Bank: {DEPOSIT} ^5!dep ^2| {WITHDRAW} ^5!wit";
	self.shop_display = self createFontString( "objective", 1 );
	self.shop_display.hideWhenInMenu = true;
	self.shop_display setPoint( "TOP", "TOP", 0, 25 );
	self.shop_display setText( shop_text );
	self.shop_display.alpha = 0;
	}

	if( IsDefined(self.shop_name) && IsDefined(self.shop_display) )
	{
	thread fade_in_shop( self.shop_name );
	thread fade_in_shop( self.shop_display );	
	}
}

fade_in_shop( message )
{
	message FadeOverTime(5);
	message.alpha = 0.7;
	fade_out_shop( message );
}

fade_out_shop( message )
{	
	wait(30);
	message FadeOverTime(5);
	message.alpha = 0;
}


monitor_points_() // Setup initial HUD
{

	level_human_scores = self get_all_humans_score();

	self.myScore = self createFontString( "default", 1.4 );
	self.myScore setPoint( "LEFT", "LEFT", 15, 145 );
	self.myScore.alpha = 0.6;
	self.myScore.label = &"^2";

	if( level_human_scores[0] )
	{
		self.teamScore1 = self createFontString( "default", 1.2 );
		self.teamScore1 setPoint( "LEFT", "LEFT", 15, 160 );
		self.teamScore1.alpha = 0.4;
		self.teamScore1.label = &"";
	}

	if( level_human_scores[1] )
	{
		self.teamScore2 = self createFontString( "default", 1.2 );
		self.teamScore2 setPoint( "LEFT", "LEFT", 15, 175 ); 
		self.teamScore2.alpha = 0.4;
		self.teamScore2.label = &"";
	}

	if( level_human_scores[2] )
	{
		self.teamScore3 = self createFontString( "default", 1.2 );
		self.teamScore3 setPoint( "LEFT", "LEFT", 15, 190 );
		self.teamScore3.alpha = 0.4;
		self.teamScore3.label = &"";
	}

	self thread add_points();
}

add_points()
{		
	self endon("disconnect"); 

	while( true ) 
	{
		self waittill_any("joined_team", "horde_kill", "withdraw", "deposit", "shop_item");

		self.myScore setValue( self.pers["score"] );

		level_human_scores = self get_all_humans_score();

		//------- Update Team-mates points
		team_player1_score = IsDefined(level_human_scores[0]) ? level_human_scores[0] : 0;
			self.teamScore1 setValue( team_player1_score ); 
		
		team_player2_score = IsDefined(level_human_scores[1]) ? level_human_scores[1] : 0;
			self.teamScore2 setValue( team_player2_score ); 

		team_player3_score = IsDefined(level_human_scores[2]) ? level_human_scores[2] : 0;
			self.teamScore3 setValue( team_player3_score ); 
	}
}

get_all_humans_score()
{
	humans = [];
	
	foreach ( player in level.players )
	{
		if ( !IsAI(player) && self.name != player.name)
			humans = array_add( humans, player.pers["score"] );
	}
	
	return humans;
}

createPlayerVariables( player )
{
	player.weaponState 		= [];
	player.horde_perks		= [];
	player.pointNotifyLUA	= [];
	player.beingRevived 	= false;
	
	// stats
	player.killz = 0;
	player.numRevives = 0;
	player.numCrtaesCaptured = 0;
	player.roundsPlayed = 0;
	player.maxWeaponLevel = 1;

	level.playerStartWeaponName = player.primaryWeapon; 
	
	createHordeWeaponState( player, level.playerStartWeaponName, true );
	if ( player.secondaryWeapon != "none" )
		createHordeWeaponState( player, player.secondaryWeapon, true );

	level thread activatePlayerHUD( player );
	level thread monitorWeaponProgress( player );
	level thread monitorPointNotifyLUA( player );
}

onSpawnPlayer_()
{

	if( self.gameModefirstSpawn && IsAgent(self) )
	{	
		self.pers["class"] 				= "gamemode"; 
		self.pers["lastClass"] 			= "";	
		self.pers["gamemodeLoadout"] 	= level.hordeLoadouts[level.playerTeam]; 
		self.class 						= self.pers["class"];
		self.lastClass 					= self.pers["lastClass"];		
	}

	if ( !IsAI(self) && !IsAgent(self) ) 
		self.class = "custom1";
		
	if( IsAgent(self) )
	{
		if( !isOnHumanTeam(self) )
		{
			setEnemyAgentHealth( self );
			setEnemyDifficultySettings( self );
			
			loadout = getHordeEnemyLoadOut();
			self.pers["gamemodeLoadout"] = loadout;
			self.agentname = loadout["name_localized"];
			self.horde_type = loadout["type"];
			
			self thread maps\mp\agents\_agents_gametype_horde::playAISpawnEffect();
		}
		else
		{
			self.pers["gamemodeLoadout"] = level.hordeLoadouts["squadmate"];
			
			self bot_set_personality( "camper" );
			self bot_set_difficulty( "veteran" );
			self BotSetDifficultySetting( "allowGrenades", 1 );
		}
		
		self.avoidKillstreakOnSpawnTimer = 0;
	}

	self thread onSpawnFinished();
}

onSpawnFinished_()
{
	self  endon( "death" );
	self  endon( "disconnect" );
	level endon( "game_ended" );
	
	self waittill( "giveLoadout" );
	
	self maps\mp\killstreaks\_killstreaks::clearKillstreaks();
	
	if( isOnHumanTeam(self) )
	{
		self GiveMaxAmmo( level.playerStartWeaponName );
		self thread playerAmmoRegen( level.playerStartWeaponName ); // test: add secoundry
		
		if( IsPlayer(self) )
		{
			self _clearPerks();
	
			self givePerkEquipment( "proximity_explosive_mp", false );
			self givePerkOffhand( "concussion_grenade_mp", false );
			self givePerk( "specialty_pistoldeath", false );
			
			if( !self.hasUsedSquadMate )
			{
				self thread maps\mp\killstreaks\_killstreaks::giveKillstreak( "agent", false, false, self );
			}
			
			self childthread updateRespawnSplash( self.gameModefirstSpawn );
			
			removePerkHUD( self );
			updateTimerOmnvars( self );
		}
		
		if( IsAgent(self) )
		{
			self.agentname = &"HORDE_BUDDY";
			self.horde_type = "Buddy";
			
			self childthread ammoRefillPrimary();
			self thread maps\mp\bots\_bots::bot_think_revive();
			
			if( IsDefined(self.owner) )
				self.owner.hasUsedSquadMate = true;
		}
	}
	else
	{
		self childthread ammoRefillPrimary();
		self childthread ammoRefillSecondary();
		
		switch( self.horde_type )
		{
			case "Ravager":
				self setRavagerModel();
				break;
			case "Enforcer":
				self setEnforcerModel();
				break;
			case "Striker":
				self setStrikerModel();
				self BotSetFlag( "path_traverse_wait", true );
				break;
			case "Blaster":
				self setBlasterModel();
				self BotSetDifficultySetting( "maxFireTime", 2800 );
				self BotSetDifficultySetting( "minFireTime", 1500 );
				break;
			case "Hammer":
				self setHammerModel();
				break;
			default:
				AssertMsg( "Unhandeled enemy type" );
		}

		self SetViewmodel( "viewhands_juggernaut_ally" );
		self SetClothType( "cloth" );
		
		self giveEnemyPerks();
	}
	
	self.gameModefirstSpawn = false;
}

runHordeMode_() // This for removing field orders
{	
	level endon( "game_ended" );
		
	waitUntilMatchStart();
	
	foreach( player in level.players )
	{
		if( player.class == "" )
		{
			player notify( "luinotifyserver", "class_select", 0 );
			player thread closeClassMenu(); 
		}
	}
	
	while( true )
	{
		updateHordeSettings();
		showNextRoundMessage();

		level notify( "start_round" );
		level.gameHasStarted = true;
		level childthread monitorRoundEnd();
		level waittill( "round_ended" );
	}
}

createHordeCrates_( friendly_crate_model, enemy_crate_model )
{
	level.getRandomCrateTypeForGameMode = ::getRandomCrateTypeHorde;
	
	// ammo icon
	level.hordeIcon["ammo"] 								= "specialty_ammo_crate";

	// weapon icons
	level.hordeIcon["throwingknife_mp"] 							= "throw_knife_sm";
	
	
	// perk icons
	level.hordeIcon["specialty_lightweight"] 						= "icon_perks_agility";					// incresed movement speed
	level.hordeIcon["specialty_fastreload"] 						= "icon_perks_sleight_of_hand";			// fast reload
	level.hordeIcon["specialty_quickdraw"] 							= "icon_perks_quickdraw";				// faster aiming
	level.hordeIcon["specialty_marathon"] 							= "icon_perks_marathon";				// unlimited sprint
	level.hordeIcon["specialty_quickswap"] 							= "icon_perks_reflex";					// swap weapons faster
	level.hordeIcon["specialty_bulletaccuracy"] 					= "icon_perks_steady_aim";				// increase hip fire accuracy 
	level.hordeIcon["specialty_fastsprintrecovery"] 				= "icon_perks_ready_up";				// weapon is ready faster after sprinting
	level.hordeIcon["_specialty_blastshield"] 						= "icon_perks_blast_shield"; 			// resistance to explosives
	level.hordeIcon["specialty_stalker"] 							= "icon_perks_stalker"; 				// move faster while aiming
	level.hordeIcon["specialty_sharp_focus"] 						= "icon_perks_focus"; 					// reduce flinch when hit
	level.hordeIcon["specialty_regenfaster"] 						= "icon_perks_icu"; 					// faster health regeneration
	level.hordeIcon["specialty_sprintreload"] 						= "icon_perks_on_the_go"; 				// reload while sprinting
	level.hordeIcon["specialty_triggerhappy"] 						= "icon_perks_triggerhappy"; 			// auto-reload after kill
	
	
	//				Drop Type				Type											Weight  Function					Friendly Model		  Enemy Model		 Hint String				
	addCrateType(	"a",					"throwingknife_mp",								3,		::hordeCrateLethalThink,	friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_KNIFE" );
	addCrateType(	"a",					"specialty_lightweight",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_LIGHT" );
	addCrateType(	"a",					"specialty_fastreload",							0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_FAST" );
	addCrateType(	"a",					"specialty_quickdraw",							10,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_QIUCK" );
	addCrateType(	"a",					"specialty_marathon",							0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_MARA" );
	addCrateType(	"a",					"specialty_quickswap",							10,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_SWAP" );
	addCrateType(	"a",					"specialty_bulletaccuracy",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_AIM" );
	addCrateType(	"a",					"specialty_fastsprintrecovery",					7,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_READY" );
	addCrateType(	"a",					"_specialty_blastshield",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_BLAST" );
	addCrateType(	"a",					"specialty_stalker",							10,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_STALK" );
	addCrateType(	"a",					"specialty_sharp_focus",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_FOCUS" );
	addCrateType(	"a",					"specialty_regenfaster",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_HEALTH" );
	addCrateType(	"a",					"specialty_sprintreload",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_GO" );
	addCrateType(	"a",					"specialty_triggerhappy",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_TRIGGER" );
	addCrateType(	"a",					"ammo",											0,		::hordeCrateAmmoThink,		friendly_crate_model, enemy_crate_model, &"HORDE_AMMO" );
	
	addCrateType(	"b",					"throwingknife_mp",								3,		::hordeCrateLethalThink,	friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_KNIFE" );
	addCrateType(	"b",					"specialty_lightweight",						10,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_LIGHT" );
	addCrateType(	"b",					"specialty_fastreload",							0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_FAST" );
	addCrateType(	"b",					"specialty_quickdraw",							0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_QIUCK" );
	addCrateType(	"b",					"specialty_marathon",							10,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_MARA" );
	addCrateType(	"b",					"specialty_quickswap",							0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_SWAP" );
	addCrateType(	"b",					"specialty_bulletaccuracy",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_AIM" );
	addCrateType(	"b",					"specialty_fastsprintrecovery",					0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_READY" );
	addCrateType(	"b",					"_specialty_blastshield",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_BLAST" );
	addCrateType(	"b",					"specialty_stalker",							0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_STALK" );
	addCrateType(	"b",					"specialty_sharp_focus",						7,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_FOCUS" );
	addCrateType(	"b",					"specialty_regenfaster",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_HEALTH" );
	addCrateType(	"b",					"specialty_sprintreload",						10,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_GO" );
	addCrateType(	"b",					"specialty_triggerhappy",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_TRIGGER" );
	addCrateType(	"b",					"ammo",											0,		::hordeCrateAmmoThink,		friendly_crate_model, enemy_crate_model, &"HORDE_AMMO" );
	
	addCrateType(	"c",					"throwingknife_mp",								2,		::hordeCrateLethalThink,	friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_KNIFE" );
	addCrateType(	"c",					"specialty_lightweight",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_LIGHT" );
	addCrateType(	"c",					"specialty_fastreload",							12,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_FAST" );
	addCrateType(	"c",					"specialty_quickdraw",							0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_QIUCK" );
	addCrateType(	"c",					"specialty_marathon",							0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_MARA" );
	addCrateType(	"c",					"specialty_quickswap",							0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_SWAP" );
	addCrateType(	"c",					"specialty_bulletaccuracy",						12,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_AIM" );
	addCrateType(	"c",					"specialty_fastsprintrecovery",					0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_READY" );
	addCrateType(	"c",					"_specialty_blastshield",						12,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_BLAST" );
	addCrateType(	"c",					"specialty_stalker",							0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_STALK" );
	addCrateType(	"c",					"specialty_sharp_focus",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_FOCUS" );
	addCrateType(	"c",					"specialty_regenfaster",						12,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_HEALTH" );
	addCrateType(	"c",					"specialty_sprintreload",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_GO" );
	addCrateType(	"c",					"specialty_triggerhappy",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_TRIGGER" );
	addCrateType(	"c",					"ammo",											0,		::hordeCrateAmmoThink,		friendly_crate_model, enemy_crate_model, &"HORDE_AMMO" );
	
	addCrateType(	"d",					"throwingknife_mp",								2,		::hordeCrateLethalThink,	friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_KNIFE" );
	addCrateType(	"d",					"specialty_lightweight",						3,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_LIGHT" );
	addCrateType(	"d",					"specialty_fastreload",							4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_FAST" );
	addCrateType(	"d",					"specialty_quickdraw",							3,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_QIUCK" );
	addCrateType(	"d",					"specialty_marathon",							4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_MARA" );
	addCrateType(	"d",					"specialty_quickswap",							3,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_SWAP" );
	addCrateType(	"d",					"specialty_bulletaccuracy",						4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_AIM" );
	addCrateType(	"d",					"specialty_fastsprintrecovery",					3,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_READY" );
	addCrateType(	"d",					"_specialty_blastshield",						4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_BLAST" );
	addCrateType(	"d",					"specialty_stalker",							3,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_STALK" );
	addCrateType(	"d",					"specialty_sharp_focus",						4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_FOCUS" );
	addCrateType(	"d",					"specialty_regenfaster",						4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_HEALTH" );
	addCrateType(	"d",					"specialty_sprintreload",						4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_GO" );
	addCrateType(	"d",					"specialty_triggerhappy",						0,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_TRIGGER" );
	addCrateType(	"d",					"ammo",											0,		::hordeCrateAmmoThink,		friendly_crate_model, enemy_crate_model, &"HORDE_AMMO" );
	
	addCrateType(	"e",					"throwingknife_mp",								2,		::hordeCrateLethalThink,	friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_KNIFE" );
	addCrateType(	"e",					"specialty_lightweight",						4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_LIGHT" );
	addCrateType(	"e",					"specialty_fastreload",							4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_FAST" );
	addCrateType(	"e",					"specialty_quickdraw",							4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_QIUCK" );
	addCrateType(	"e",					"specialty_marathon",							4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_MARA" );
	addCrateType(	"e",					"specialty_quickswap",							4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_SWAP" );
	addCrateType(	"e",					"specialty_bulletaccuracy",						4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_AIM" );
	addCrateType(	"e",					"specialty_fastsprintrecovery", 				4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_READY" );
	addCrateType(	"e",					"_specialty_blastshield",						4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_BLAST" );
	addCrateType(	"e",					"specialty_stalker",							4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_STALK" );
	addCrateType(	"e",					"specialty_sharp_focus",						4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_FOCUS" );
	addCrateType(	"e",					"specialty_regenfaster",						4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_HEALTH" );
	addCrateType(	"e",					"specialty_sprintreload",						4,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_GO" );
	addCrateType(	"e",					"specialty_triggerhappy",						3,		::hordeCratePerkThink,		friendly_crate_model, enemy_crate_model, &"HORDE_DOUBLE_TAP_TRIGGER" );
	addCrateType(	"e",					"ammo",											0,		::hordeCrateAmmoThink,		friendly_crate_model, enemy_crate_model, &"HORDE_AMMO" );
	
	setupLootCrates( friendly_crate_model, enemy_crate_model );
}

setupLootCrates_( friendly_crate_model, enemy_crate_model )
{
	//				Drop Type				Type							Weight  Function						Friendly Model		  Enemy Model		 Hint String
	addCrateType(	"loot",					"sentry",						15,		::killstreakCrateThinkHorde,	friendly_crate_model, enemy_crate_model, &"KILLSTREAKS_HINTS_SENTRY_PICKUP"); 
	addCrateType(	"loot",					"vanguard",						15,		::killstreakCrateThinkHorde,	friendly_crate_model, enemy_crate_model, &"KILLSTREAKS_HINTS_VANGUARD_PICKUP"); 
	addCrateType(	"loot",					"agent",						15,		::killstreakCrateThinkHorde,	friendly_crate_model, enemy_crate_model, &"KILLSTREAKS_HINTS_AGENT_PICKUP" );
}
