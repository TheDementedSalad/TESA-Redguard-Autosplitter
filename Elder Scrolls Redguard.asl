//The Elder Scrolls Adventure: Redguard Autosplitter V1.1.0 May 4 2023
//Script by TheDementedSalad & SabulineHorizon

//Known issues:
//Loading a previous area after that crosses a loading transition might split additional times

state("dosbox","Steam")
{
	byte loading		:	0x351690, 0x57B401;		//0 loading, 128 not loading (pre-game until start is also 0)
	byte mapID		:	0x351690, 0x573194;		//1 starting town, 4 goblin cave
	byte markerID		:	0x351690, 0x57319C;		//+8 from mapID
	string20 dialogue1	:	0x351690, 0x9456;		//Various descriptions and exclamations
	string20 dialogue2	:	0x351690, 0x589BD4;		//Selected text during dialogue
	string30 interact	:	0x351690, 0x57B500;		//Text that appears for interacting with items
	string8 finalCutscene	: 	0x17CEDF0;			//"AH!" when final cutscene is playing
	
	byte menuIndex		:	0x351690, 0x592148;		//0 main menu, 1 save, 2 load, 3 movies, 4 options, 5 display,6 sound, 7 controls
	bool menuOpen		:	0x351690, 0x56F9D6;		//0 closed, 1 open
 	bool menuSelected	:	0x351690, 0x592180;		//Active during a menu transition if an option was selected with Enter
	bool menuTransition	:	0x351690, 0x5922F4;		//Active during all menu transitions (but not when selecting NEW) even if Esc was used
}

state("dosbox","GOG")
{
	byte loading		:	0x273014, 0x3C9F3D;		//0 loading, 128 not loading (pre-game until start is also 0)
	byte mapID	 	:	0x273014, 0x376F5C;		//1 starting town, 4 goblin cave
	byte markerID		:	0x273014, 0x376F64;		//+8 from mapID
	string20 dialogue1	:	0x273014, 0x604038;		//Various descriptions and exclamations
	string20 dialogue2	:	0x273014, 0x3C95A8;		//Selected text during dialogue
	string30 interact	:	0x273014, 0x3D3DB8;		//Text that appears for interacting with items
	string8 finalCutscene	: 	0x1709898;			//"AH!" when final cutscene is playing
	
	byte menuIndex		:	0x273014, 0x3CCBDC;		//0 main menu, 1 save, 2 load, 3 movies, 4 options, 5 display,6 sound, 7 controls
	bool menuOpen		:	0x273014, 0x379678;		//0 closed, 1 open
	bool menuSelected	:	0x273014, 0x3CCC10;		//Active during a menu transition if an option was selected with Enter
	bool menuTransition	:	0x273014, 0x3CCD84;		//Active during all menu transitions (but not when selecting NEW) even if Esc was used

}

state("dosbox","GOG_Original")
{
	byte loading		:	0x4B34B4, 0x3C9F3D;		//0 loading, 128 not loading (pre-game until start is also 0)
	byte mapID	 	:	0x4B34B4, 0x376F5C;		//1 starting town, 4 goblin cave
	byte markerID		:	0x4B34B4, 0x376F64;		//+8 from mapID
	string20 dialogue1	:	0x4B34B4, 0x604038;		//Various descriptions and exclamations
	string20 dialogue2	:	0x4B34B4, 0x3C95A8;		//Selected text during dialogue
	string30 interact	:	0x4B34B4, 0x3D3DB8;		//Text that appears for interacting with items
	string8 finalCutscene	: 	0x1949D20;			//"AH!" when final cutscene is playing
	
	byte menuIndex		:	0x4B34B4, 0x3CCBDC;		//0 main menu, 1 save, 2 load, 3 movies, 4 options, 5 display,6 sound, 7 controls
	bool menuOpen		:	0x4B34B4, 0x379678;		//0 closed, 1 open
	bool menuSelected	:	0x4B34B4, 0x3CCC10;		//Active during a menu transition if an option was selected with Enter
	bool menuTransition	:	0x4B34B4, 0x3CCD84;		//Active during all menu transitions (but not when selecting NEW) even if Esc was used
}

init
{
	vars.completedSplits = new List<string>();
	
	switch (modules.First().ModuleMemorySize)
	{
		case (34119680):
			version = "Steam";
			break;
		case (30728192):
			version = "GOG";
			break;
		case (39788544):
			version = "GOG_Original"; //Original version without Glide wrapper update. Probably not needed
			break;
	}
	
	vars.finalSplitFlag = false;
	vars.canStart = false;
}

startup
{
	// Asks user to change to game time if LiveSplit is currently set to Real Time.
	if (timer.CurrentTimingMethod == TimingMethod.RealTime)
	{
		var timingMessage = MessageBox.Show (
		"This game uses a Load Remover as the main timing method.\n"+
		"LiveSplit is currently set to show Real Time (RTA).\n"+
		"Would you like to set the timing method to Game Time?",
		"LiveSplit | TESARedguard",
		MessageBoxButtons.YesNo,MessageBoxIcon.Question
		);
		
		if (timingMessage == DialogResult.Yes)
		{
			timer.CurrentTimingMethod = TimingMethod.GameTime;
		}
	}
	
	//Updated splits
	settings.Add("updatedSplits", false, "Updated Splits");
	settings.SetToolTip("updatedSplits", "Newer split options, added to reflect the current state of the run");
	
		settings.Add("dockSplit", true, "Dock", "updatedSplits");
		settings.SetToolTip("dockSplit", "Splits when the player regains control after arriving at the dock");
		
		settings.Add("shopSplit", true, "Leaving Shop", "updatedSplits");
		settings.SetToolTip("shopSplit", "Splits when the player leaves Gerrick's shop after buying feathers");
		
		settings.Add("ferryOutSplit", true, "Ferry Departure", "updatedSplits");
		settings.SetToolTip("ferryOutSplit", "Splits when traveling to N'gasta's island on the ferry");
		
		settings.Add("amuletNewSplit", true, "N'Gasta's Amulet", "updatedSplits");
		settings.SetToolTip("amuletNewSplit", "Splits when the player receives the amulet from N'Gasta");
		
		settings.Add("ferryInSplit", true, "Ferry Return", "updatedSplits");
		settings.SetToolTip("ferryInSplit", "Splits when the player returns to the main island");
		
		settings.Add("deliveryNewSplit", true, "Amulet Delivery", "updatedSplits");
		settings.SetToolTip("deliveryNewSplit", "Splits when delivering the amulet to Richton at the palace");
		
		settings.Add("keySplit", true, "Silver Palace Key", "updatedSplits");
		settings.SetToolTip("keySplit", "Splits when collecting the silver palace key");
		
	//Additional settings
	settings.Add("additionalSettings", true, "Additional Settings");
	settings.SetToolTip("additionalSettings", "Additional settings");
	
		settings.Add("spamFinalSplit", true, "Spam Final Split", "additionalSettings");
		settings.SetToolTip("spamFinalSplit", "Once the final split triggers, it will keep triggering until the timer stops in case some splits were missed");
		
	//Legacy splits (previously "Main splits")
	settings.Add("mainSplits", false, "Legacy Splits");
	settings.SetToolTip("mainSplits", "These are mostly obselete now, but they're still available if you want them");
	
		settings.Add("caveSplit", false, "Cave Exit", "mainSplits");
		settings.SetToolTip("caveSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("amuletSplit", false, "N'Gasta's Amulet", "mainSplits");
		settings.SetToolTip("amuletSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("deliverySplit", false, "Amulet Delivery", "mainSplits");
		settings.SetToolTip("deliverySplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("escapeSplit", false, "Escape", "mainSplits");
		settings.SetToolTip("escapeSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("insigniaSplit", false, "League Insignia", "mainSplits");
		settings.SetToolTip("insigniaSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("scarabSplit", false, "Scarab Door", "mainSplits");
		settings.SetToolTip("scarabSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("ruinsSplit", false, "Ruins Exit", "mainSplits");
		settings.SetToolTip("ruinsSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("hideoutSplit", false, "League Hideout", "mainSplits");
		settings.SetToolTip("hideoutSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("oldQuarterSplit", false, "Old Quarter", "mainSplits");
		settings.SetToolTip("oldQuarterSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("flaskSplit", false, "Flask of Lillandril", "mainSplits");
		settings.SetToolTip("flaskSplit", "This should work but hasn't been tested at all yet");
		
		settings.Add("soulSplit", false, "Iszara's Soul", "mainSplits");
		settings.SetToolTip("soulSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("silverKeySplit", false, "Silver Key", "mainSplits");
		settings.SetToolTip("silverKeySplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("courtyardSplit", false, "Palace Courtyard", "mainSplits");
		settings.SetToolTip("courtyardSplit", "This should work but hasn't been fully tested yet");
}

update
{
	// print(modules.First().ModuleMemorySize.ToString());
	
	if(timer.CurrentPhase == TimerPhase.NotRunning)
	{
		vars.completedSplits.Clear();
	}
	
	//avoids false starts when resetting at the beginning
	if(current.mapID == 255)
		vars.canStart = true;
	
	//use TryParse() to filter out health values and put strings into a comparison variable
	int num;
	if(!int.TryParse(old.interact, out num))
		vars.oldInteract = old.interact;
}

start
{
	return current.mapID == 0 && current.loading == 128 && old.loading == 0 && vars.canStart;
}

onStart
{
	//initialize variables
	vars.finalSplitFlag = false;
	vars.canStart = false;
}

isLoading
{
	return current.loading == 0;
}

split
{
	//Final Split
	if (version == "Steam" && !vars.finalSplitFlag && (current.mapID == 30))
	{
		if(!settings["spamFinalSplit"]) vars.finalSplitFlag = true;
			return ((current.finalCutscene == "AH!") && (current.loading == 128));
	}
	else if ((version == "GOG" || version == "GOG_Original") && !vars.finalSplitFlag && (current.mapID == 30))
	{
		if(!settings["spamFinalSplit"]) vars.finalSplitFlag = true;
			return ((current.finalCutscene == "AH!") && (current.loading == 128));
	}
	else
	{
		return(
			//Newer splits - since the run is shorter now
			//There are two splits (amuletSplit and deliverySplit) that are duplicated
			//The duplicates are to avoid confusion for those who just want to check one options list
			
				//Docks
			(((vars.oldInteract == "100%") ||
			(vars.oldInteract == "text[16]") ||
			(vars.oldInteract == "SaveGame( 0, Quick Save Game )")) &&
			(current.interact == "inventory_object_file[18]") &&
			(current.mapID == 1) &&
			(current.markerID == 1) &&
			settings["dockSplit"]) ||
			
				//Leaving Gerrick's
			((old.mapID == 22) &&
			(current.mapID == 1) &&
			settings["shopSplit"]) ||
			
				//Ferry Departure
			((current.mapID == 6) &&
			(old.mapID == 1) &&
			settings["ferryOutSplit"]) ||
			
				//N'Gasta's Amulet
			(((old.dialogue2 == "I CAN DO THAT") ||			
			(old.dialogue2 == "I'LL DELIVER THE AMU")) &&
			(current.dialogue2 == "ISZARA") &&
			(current.mapID == 6) &&
			settings["amuletNewSplit"]) ||
			
				//Ferry Return
			((current.mapID == 1) &&
			(old.mapID == 6) &&
			settings["ferryInSplit"]) ||
			
				//Amulet Delivery
			((old.mapID == 1) &&
			(current.mapID == 3) &&
			(current.markerID == 0) &&
			settings["deliveryNewSplit"]) ||
			
				//Silver Key
			((vars.oldInteract == "GET KEY") &&
			(current.interact == "inventory_object_file[79]") &&
			(current.mapID == 3) &&
			settings["keySplit"]) ||
			
			
				//Legacy Splits, these are outdated and aren't recommended for Any%
				//Cave Exit
			((old.mapID == 4) &&
			(current.mapID == 1) &&
			(current.markerID == 2) &&
			settings["caveSplit"]) ||	
			
				//N'Gasta's Amulet
			(((old.dialogue2 == "I CAN DO THAT") ||			
			(old.dialogue2 == "I'LL DELIVER THE AMU")) &&
			(current.dialogue2 == "ISZARA") &&
			(current.mapID == 6) &&
			settings["amuletSplit"]) ||
			
				//Amulet Delivery
			((old.mapID == 1) &&
			(current.mapID == 3) &&
			(current.markerID == 0) &&
			settings["deliverySplit"]) ||
			
				//Escape (split happens after cutscene instead of before)
			((old.mapID == 2) &&
			(current.mapID == 1) &&
			(current.markerID == 45) &&
			settings["escapeSplit"]) ||
			
				//League Insignia
			(((old.dialogue2 == "SHE WOULD HAVE LIKED") ||
			(old.dialogue2 == "YOU'RE PUSHING YOUR") ||
			(old.dialogue2 == "LEAGUE IS GONE") ||
			(old.dialogue2 == "I DON'T KNOW BASIL")) &&
			(current.dialogue2 == "ISZARA") &&
			(current.mapID == 24) &&
			settings["insigniaSplit"]) ||
			
				//Scarab Door
			((old.mapID == 8) &&
			(current.mapID == 1) &&
			(current.markerID == 7) &&
			settings["scarabSplit"]) ||
			
				//Ruins Exit
			((old.mapID == 8) &&
			(current.mapID == 1) &&
			(current.markerID == 44) &&
			settings["ruinsSplit"]) ||
			
				//League Hideout
			((old.mapID == 1) &&
			(current.mapID == 17) &&
			(current.markerID == 6) &&
			settings["hideoutSplit"]) ||
			
				//Old Quarter
			((old.mapID == 11) &&
			(current.mapID == 27) &&
			(current.markerID == 28) &&
			settings["oldQuarterSplit"]) ||
			
				//Flask of Lillandril
			((old.dialogue1 != current.dialogue1) &&
			(current.dialogue1 == "IT'S THE MYTHICAL FL") &&
			settings["flaskSplit"]) ||
			
				//Iszara's Soul
			((current.mapID == 14) &&
			(old.markerID == 0) &&
			(current.markerID == 5) &&
			settings["soulSplit"]) ||
			
				//Silver Key
			((old.interact != current.interact) &&
			(vars.oldInteract == "GET KEY") &&
			(current.interact == "inventory_object_file[10]") &&
			(current.mapID == 2) &&
			settings["silverKeySplit"]) ||
			
				//Palace Courtyard
			((old.mapID == 1) &&
			(current.mapID == 30) &&
			(current.markerID == 8) &&
			settings["courtyardSplit"])
		);
	}
}

reset
{
	//if menuSelected becomes true and menuTransition doesn't, it means "new" was selected
	return (
		current.menuSelected &&
		!old.menuSelected &&
		!current.menuTransition &&
		current.menuIndex == 0 &&
		current.menuOpen
	);
}

onReset
{
	//initialize variables
	vars.finalSplitFlag = false;
}

exit
{
    //pauses timer if the game crashes
	timer.IsGameTimePaused = true;
}
