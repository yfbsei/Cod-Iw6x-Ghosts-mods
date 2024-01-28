Init()
{
    // this gives the game interface time to setup
    waittillframeend;
    thread ModuleSetup();
}

ModuleSetup()
{
    // waiting until the game specific functions are ready
    level waittill( level.notifyTypes.gameFunctionsInitialized );

    RegisterCustomCommands();
}

RegisterCustomCommands()
{
    scripts\_integration_shared::RegisterScriptCommand( "bank_withdraw", "withdraw", "wit", "withdraw points", "User", undefined, false, ::bank_withdraw );
    scripts\_integration_shared::RegisterScriptCommand( "bank_deposit", "deposit", "dep", "deposit points", "User", undefined, false, ::bank_deposit );

    scripts\_integration_shared::RegisterScriptCommand( "shop_menu", "shop", "shop", "Open shop menu", "User", undefined, false, ::shop_menu );
    scripts\_integration_shared::RegisterScriptCommand( "shop_nuke", "nuke", "nuk", "Buy nuke", "User", undefined, false, ::shop_nuke );
    scripts\_integration_shared::RegisterScriptCommand( "shop_odin", "odin", "odi", "Buy odin", "User", undefined, false, ::shop_odin );
    scripts\_integration_shared::RegisterScriptCommand( "shop_revive", "revive", "rev", "Buy revive", "User", undefined, false, ::shop_revive );
}

shop_menu( event, _ )
{
    level endon( level.eventTypes.gameEnd );

    self scripts\horde_mod::shop_command();
}

shop_nuke( event, _ )
{   
    level endon( level.eventTypes.gameEnd );

    if( self.pers["score"] >= 250) 
    {
        self thread maps\mp\killstreaks\_killstreaks::giveKillstreak( "nuke", false, false, self );
        self.pers["score"] = self.pers["score"] - 250;
        self notify( "shop_item" );
    }
    else 
        self IPrintLnBold("^1INSUFFICIENT POINTS");
}

shop_odin( event, _ )
{
    level endon( level.eventTypes.gameEnd );

    if( self.pers["score"] >= 250) 
    {
        self thread maps\mp\killstreaks\_killstreaks::giveKillstreak( "odin_assault", false, false, self );
        self.pers["score"] = self.pers["score"] - 250;
        self notify( "shop_item" );
    }
    else 
        self IPrintLnBold("^1INSUFFICIENT POINTS");
}

shop_revive( event, _ )
{
    level endon( level.eventTypes.gameEnd );

    if( self.pers["score"] >= 100) 
    {
        thread scripts\horde_mod::revive_horde();
        self.pers["score"] = self.pers["score"] - 100;
        self notify( "shop_item" );
    }
    else 
        self IPrintLnBold("^1INSUFFICIENT POINTS");
}

bank_withdraw( event, _ )
{
    level endon( level.eventTypes.gameEnd );

    xuid = self GetXUID();
    amount = IsDefined(event.data["args"]) ? event.data["args"] : 0;

    request         = SpawnStruct();
    request.url     = "http://localhost:4000/account/withdraw/?xuid="+xuid+"&amount="+amount;
    request.method  = "GET";

    scripts\_integration_shared::RequestUrlObject( request );
    request waittill( level.eventTypes.urlRequestCompleted, response );

    self.pers["score"] = self.pers["score"] + int(response);
    self notify( "withdraw" );
    self IPrintLnBold( "Withdrew: " + response );
}

bank_deposit( event, _ )
{
    level endon( level.eventTypes.gameEnd );

    xuid = self GetXUID();
    amount = IsDefined(event.data["args"]) ? event.data["args"] : self.pers["score"];

    if( int(amount) <= self.pers["score"] && int(amount) > 0 ) 
        self bank_deposit_one( xuid, amount );
    else
        self bank_deposit_one( xuid, self.pers["score"] ); // deposit all
}

bank_deposit_one( xuid, amount )
{
    request         = SpawnStruct();
    request.url     = "http://localhost:4000/account/deposit/?xuid="+xuid+"&amount="+amount;
    request.method  = "GET";

    scripts\_integration_shared::RequestUrlObject( request );
    request waittill( level.eventTypes.urlRequestCompleted, response );

    self.pers["score"] = self.pers["score"] - int(response);
    self notify( "deposit" );
    self IPrintLnBold( "Deposited: " + int(response) );
}

// toString( num )
// {
// 	return( "" + num );
// }