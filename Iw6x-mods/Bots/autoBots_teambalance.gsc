#include maps\mp\bots\_bots;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\bots\_bots_util;
#include maps\mp\bots\_bots_loadout;
#include maps\mp\bots\_bots_strategy;
#include maps\mp\bots\_bots_personality;

init()
{
    // for private mode
	// SetDevDvar( "sv_maxclients", 4 ); // Max players(bot+human) allowed in Game
	// SetDevDvar( "ui_maxclients", 4 ); // Max players(bot+human) allowed in Game 

	setMatchData( "hasBots", true );

	level thread onPlayerConnect(); 
}

// ======================================================== Initialize bot
#define ALLIES_BOT_AMOUNT 4
#define AXIS_BOT_AMOUNT 4
#define BOTS_DIFFICULTY "veteran" // recruit, regular, hardened, veteran
// ======================================================== 

onPlayerConnect()
{
		level waittill( "connected", player );
		player thread onJoinedTeam();
}

onJoinedTeam()
{
	self endon("disconnect");
	for (;;)
	{
		self waittill( "joined_team" );
		if( !IsBot(self) )
		{	

			if( self.team == "allies") 
			{
				
				childthread balanceTeam_allies(); // kick bot from human's joining team ( - )
				wait(1.0);
				childthread balanceTeam_axis(); // add bot to empty slot, opposite team ( + )
				wait(5.0);
				
				foreach ( player in level.players )
				{
					if ( IsBot( player ) )
					{
					player make_entity_sentient_mp( "allies" );
					}
				}
			}
			if( self.team == "axis") 
			{
				childthread balanceTeam_axis();
				wait(1.0);
				childthread balanceTeam_allies();
			}
		}
	}
}

getAllBots( team ) {
	bots = [];

	foreach ( player in level.players )
	{
		if ( IsBot( player ) && player.team == team )
		{
			player make_entity_sentient_mp( team );
			bots[bots.size] = player;
		}
	}
	return bots;
}

getTeams_Count()
{
	level.team["allies"] = 0;
	level.team["axis"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if((IsDefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
			level.team["allies"]++;
		else if((IsDefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
			level.team["axis"]++;
	}
	return [ level.team["allies"], level.team["axis"] ];
}

balanceTeam_allies() 
{
	teamSize = getTeams_Count();

	if( teamSize[0] != ALLIES_BOT_AMOUNT) 
	{
		imbalance = teamSize[0] - ALLIES_BOT_AMOUNT;

		if( imbalance < 0 ) // below limit
		{
			postiveInt = ALLIES_BOT_AMOUNT - teamSize[0];
			spawn_bots( postiveInt, "allies", undefined, undefined, "spawned bots", BOTS_DIFFICULTY ); // num_bots, team, botCallback, haltWhenFull, notifyWhenDone, difficulty
		}
		
		if( imbalance > 0) // over limit
        {
			allies_bots = getAllBots( "allies" );
			for ( i = 0; i < imbalance; i++ )
				executecommand("kick " + allies_bots[i].name); // native drop_bots, bot_drop broken ??
        }
	}
}

balanceTeam_axis()
{
	teamSize = getTeams_Count();

	if( teamSize[1] != AXIS_BOT_AMOUNT) 
	{
		imbalance = teamSize[1] - AXIS_BOT_AMOUNT;

		if( imbalance < 0 ) // below limit
		{
			postiveInt = AXIS_BOT_AMOUNT - teamSize[1];
			spawn_bots( postiveInt, "axis", undefined, undefined, "spawned bots", BOTS_DIFFICULTY ); // num_bots, team, botCallback, haltWhenFull, notifyWhenDone, difficulty
		}
		
		if( imbalance > 0) // over limit
        {
			axis_bots = getAllBots( "axis" );
			for ( i = 0; i < imbalance; i++ )
				executecommand("kick " + axis_bots[i].name); // native drop_bots, bot_drop broken ??
        }
	}
} 
