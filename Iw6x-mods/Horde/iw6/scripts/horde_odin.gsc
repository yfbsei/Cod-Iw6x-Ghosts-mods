#include maps\mp\killstreaks\_odin;


main() 
{
    replaceFunc( maps\mp\killstreaks\_odin::odin_watchTargeting, ::odin_watchTargeting_ ); 
}

odin_watchTargeting_() // self == odin
{
	self endon( "death" );
	level endon( "game_ended" );
	
	owner = self.owner;
	owner endon( "disconnect" );
	
	// show a marker in the ground
	startTrace = owner GetViewOrigin();
	endTrace = startTrace + ( AnglesToForward( self GetTagAngles( "tag_player" ) ) * 10000 );
	markerPos = BulletTrace( startTrace, endTrace, false, self );
	marker = Spawn( "script_model", markerPos[ "position" ] );
	marker.angles = VectorToAngles( ( 0, 0, 1 ) );
	marker SetModel( "tag_origin" );
	
	self.targeting_marker = marker;
	marker endon("death");
	
	// keep it on the ground
	trace = BulletTrace( marker.origin + ( 0, 0, 50 ), marker.origin + ( 0, 0, -100 ), false, marker );
	marker.origin = trace[ "position" ] + ( 0, 0, 50 );
	 
	// only the owner can see the targeting
	marker Hide();
	marker ShowToPlayer( owner );
	marker childthread monitorMarkerVisibility(owner);
	
	self thread showFX();
	//self thread watchAirdropUse(); // Don't use airdrop is horde mode
	self thread watchJuggernautUse();
	switch( self.odinType )
	{
		case "odin_support":
			self thread watchSmokeUse();
			self thread watchMarkingUse();
			break;
		case "odin_assault":
			self thread watchLargeRodUse();
			self thread watchSmallRodUse();
			break;
	}
	
	self SetOtherEnt( marker );

}