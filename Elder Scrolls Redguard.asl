//The Elder Scrolls Adventure: Redguard Autosplitter Version 1.3.1 – May 14, 2023
//Script by TheDementedSalad & SabulineHorizon

//Known issues:
//Loading a previous area after that crosses a loading transition might split additional times
//The code is a bit of a mess, this was the result of adding features quickly while trying not to disturb legacy behavior
//	It is probably worth rewriting it to be more streamlined once the moist challenge is over

state("dosbox","Steam")
{
	byte loading		:	0x353078, 0x57B401;		//0 loading, 128 not loading (pre-game until start is also 0)
	byte mapID		:	0x353078, 0x573194;		//1 starting town, 4 goblin cave
	byte markerID		:	0x353078, 0x57319C;		//+8 from mapID
	string20 dialogue1	:	0x353078, 0x9456;		//Various descriptions and exclamations
	string20 dialogue2	:	0x353078, 0x589BD4;		//Selected text during dialogue
	string30 interact	:	0x353078, 0x57B500;		//Text that appears for interacting with items
	string8 finalCutscene	: 	0x17CEDF0;			//"AH!" when final cutscene is playing
	
	byte menuIndex		:	0x353078, 0x592148;		//0 main menu, 1 save, 2 load, 3 movies, 4 options, 5 display,6 sound, 7 controls
	bool menuOpen		:	0x353078, 0x56F9D6;		//0 closed, 1 open
 	bool menuSelected	:	0x353078, 0x592180;		//Active during a menu transition if an option was selected with Enter
	bool menuTransition	:	0x353078, 0x5922F4;		//Active during all menu transitions (but not when selecting NEW) even if Esc was used
	byte cutsceneIndex	:	0x353078, 0x67A19C;		//0-3 cutscene index, 129 loading started
	
	ushort ferryActive	:	0x353078, 0x57D7B0;		//48640 means ferry cutscene is active
}

state("dosbox","GOG")
{
	byte loading		:	0x1C62C30, 0x3C9F3D;		//0 loading, 128 not loading (pre-game until start is also 0)
	byte mapID	 	:	0x1C62C30, 0x376F5C;		//1 starting town, 4 goblin cave
	byte markerID		:	0x1C62C30, 0x376F64;		//+8 from mapID
	string20 dialogue1	:	0x1C62C30, 0x604038;		//Various descriptions and exclamations
	string20 dialogue2	:	0x1C62C30, 0x3C95A8;		//Selected text during dialogue
	string30 interact	:	0x1C62C30, 0x3D3DB8;		//Text that appears for interacting with items
	string8 finalCutscene	: 	0x1709898;			//"AH!" when final cutscene is playing
	
	byte menuIndex		:	0x1C62C30, 0x3CCBDC;		//0 main menu, 1 save, 2 load, 3 movies, 4 options, 5 display,6 sound, 7 controls
	bool menuOpen		:	0x1C62C30, 0x379678;		//0 closed, 1 open
	bool menuSelected	:	0x1C62C30, 0x3CCC10;		//Active during a menu transition if an option was selected with Enter
	bool menuTransition	:	0x1C62C30, 0x3CCD84;		//Active during all menu transitions (but not when selecting NEW) even if Esc was used
	byte cutsceneIndex	:	0x1C62C30, 0x5BF06C;		//0-3 cutscene index, 81 loading started
	
	ushort ferryActive	:	0x1C62C30, 0x3B1988;		//48640 means ferry cutscene is active

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
	byte cutsceneIndex	:	0x4B34B4, 0x5BF06C;		//0-3 cutscene index, 81 loading started
	
	ushort ferryActive	:	0x4B34B4, 0x3B1988;		//48640 means ferry cutscene is active
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
	
	vars.interact = false;
	vars.finalSplitFlag = false;
	vars.canStart = false;
	vars.dockFlag = false;
	vars.postDockFlag = false;
	vars.pirateFlag = false;
	vars.ferryLoadingFlag = false;
	vars.normalSilverKeyFlag = false;
	vars.palaceKeyFlag = false;
	vars.amuletFlag = false;
	vars.cutsceneIndex = 0;
	vars.addTimeFlag = false;
	vars.addTimeIndex = 0;
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
	
	//Set cutscene times (in seconds) to replace the time that was removed
	//Data used was the fastest time for each cutscene from Joenome's testing, rounded up to 2 decimals
	vars.shipDocking = 24.64;
	vars.ferryDepartA = 13.59;
	vars.ferryDepartB = 32.32;
	vars.ferryReturnA = 13.74;
	vars.ferryReturnB = 18.32;
	
	//Info option, not used as a setting but to display version information
	settings.Add("Autosplitter Version 1.3.1 – May 14, 2023", false);
		settings.SetToolTip("Autosplitter Version 1.3.1 – May 14, 2023", "This setting is only here for information, it has no effect on the timer/splits");
	
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
		
		settings.Add("palaceKeySplit", true, "Silver Palace Key", "updatedSplits");
		settings.SetToolTip("palaceKeySplit", "Splits when collecting the silver palace key");
	
	//Additional splits
	settings.Add("additionalSplits", false, "Additional Splits");
	settings.SetToolTip("additionalSplits", "Additional alternate split options");
	
		settings.Add("afterPirates", false, "After Pirates", "additionalSplits");
		settings.SetToolTip("afterPirates", "Splits on the first load after fighting the pirates");
		
		settings.Add("enterShopSplit", false, "Entering Shop", "additionalSplits");
		settings.SetToolTip("enterShopSplit", "Splits when the player enters Gerrick's shop");
		
		settings.Add("leavePalaceSplit", false, "Leaving Palace", "additionalSplits");
		settings.SetToolTip("leavePalaceSplit", "Splits between the palace and the palace courtyard (after the silver key)");
	
	//Additional settings
	settings.Add("additionalSettings", true, "Additional Settings");
	settings.SetToolTip("additionalSettings", "Additional settings");
	
		settings.Add("spamFinalSplit", true, "Spam Final Split", "additionalSettings");
		settings.SetToolTip("spamFinalSplit", "Once the final split triggers, it will keep triggering until the timer stops in case some splits were missed");
		
		settings.Add("redundantReset", true, "Redundant Reset", "additionalSettings");
		settings.SetToolTip("redundantReset", "The normal reset condition sometimes fails to trigger. This is a backup reset condition in case the other fails");
		
		//Cutscene removal settings
		settings.Add("cutsceneSettings", true, "Cutscene Settings", "additionalSettings");
		settings.SetToolTip("cutsceneSettings", "Settings to balance the variation in cutscene time across runs");
		
			settings.Add("removeDockingTime", true, "Remove Ship Docking Time", "cutsceneSettings");
			settings.SetToolTip("removeDockingTime", "Pauses timer while the ship docking cutscene is active");
			
			settings.Add("removeFerryTime", true, "Remove Ferry Time", "cutsceneSettings");
			settings.SetToolTip("removeFerryTime", "Pauses timer while the ferry cutscenes are active");
			
			settings.Add("restoreDockingTime", true, "Restore Ship Docking Time", "cutsceneSettings");
			settings.SetToolTip("restoreDockingTime", "Adds a set amount of time to the timer when the ship docking cutscene is finished (24.64s)");
			
			settings.Add("restoreFerryTime", true, "Restore Ferry Time", "cutsceneSettings");
			settings.SetToolTip("restoreFerryTime", "Adds set amounts of time to the timer when each ferry cutscene is finished (13.59s, 32.32s, 13.74s, 18.32s)");
	
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
	if(current.mapID == 255 || vars.cutsceneIndex > 2)
		vars.canStart = true;
	
	//alternate reset condition since the current one sometimes fails to trigger
	if((current.cutsceneIndex == (old.cutsceneIndex + 1)) || (old.cutsceneIndex == 3 && current.cutsceneIndex > 20))
	{
		vars.cutsceneIndex++;
		// print(vars.cutsceneIndex.ToString());
	}
	else if(current.cutsceneIndex != old.cutsceneIndex)
		vars.cutsceneIndex = 0;
	
	//I was getting null reference exceptions on current.interact although I don't know why
	if(current.interact != null)
	{
		vars.interact = current.interact;
	}
	
	//enables split flags after loading
	if(vars.interact.Contains("LoadMap") || vars.interact.Contains("LoadGame"))
	{
		vars.dockFlag = true;
		vars.normalSilverKeyFlag = true;
		vars.palaceKeyFlag = true;
		vars.amuletFlag = true;
	}
	
	//Set a flag to remove time between when loading finishes and when ferryActive is initialized
	//If loading start while ferry cutscene was active
	if(current.loading == 0 && old.ferryActive == 48640)
		vars.ferryLoadingFlag = true;
	//Else if game is active and ferry ctuscene isn't active, restore flag to false
	else if((current.loading != 0) && (current.ferryActive == 48640) || vars.interact.Contains("LoadGame"))
	// else if((current.loading != 0) && (current.ferryActive == 48640))
		vars.ferryLoadingFlag = false;
	
	// print(vars.postDockFlag.ToString());
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
	vars.postDockFlag = false;
	vars.pirateFlag = true;
	vars.ferryLoadingFlag = false;
	vars.normalSilverKeyFlag = true;
	vars.palaceKeyFlag = true;
	vars.amuletFlag = true;
	vars.addTimeFlag = false;
	vars.addTimeIndex = 0;
}

isLoading
{
	return(
		current.loading == 0 ||
		
		//Pause timer during ship docking cutscene
		(settings["removeDockingTime"] &&
		(current.mapID == 1) &&
		(current.markerID == 1) &&
		!vars.postDockFlag) ||
		
		//Pause timer during ferry cutscene
		(settings["removeFerryTime"] &&
		((current.ferryActive == 48640) ||
		vars.ferryLoadingFlag))
	);
}

gameTime
{
	//Check ferryActive for 20? ticks in a row, and if it's equal to 48640 the whole time, then set vars.addTimeFlag
	if(current.ferryActive == 48640)
	{
		vars.addTimeIndex++;
		if (vars.addTimeIndex > 100)
			vars.addTimeFlag = true;
	}
	else
		vars.addTimeIndex = 0;
	
	//If ship arrives in dock, add ship docking cutscene time
	if((current.interact == "inventory_object_file[18]") &&
		(current.mapID == 1) &&
		(current.markerID == 1) &&
		vars.dockFlag &&
		!vars.postDockFlag)
	{
		vars.postDockFlag = true;
		if(settings["removeDockingTime"])
			return timer.CurrentTime.GameTime.Value.Add(TimeSpan.FromSeconds(vars.shipDocking)); //30s
	}
	//If ferry leaves from main island and loading starts, add ferryDepartureA time
	else if((old.ferryActive == 48640) &&
		(old.loading == 128) &&
		(current.loading == 0) &&
		(old.mapID == 1) &&
		vars.addTimeFlag &&
		settings["restoreFerryTime"])
		{
			vars.addTimeFlag = false;
			return timer.CurrentTime.GameTime.Value.Add(TimeSpan.FromSeconds(vars.ferryDepartA)); //1m
		}
	//If ferry arrives at necro island, add ferryDepartureB time
	else if((old.ferryActive == 48640) &&
		(current.ferryActive != 48640) &&
		(current.loading == 128) &&
		(current.mapID == 6) &&
		vars.addTimeFlag &&
		settings["restoreFerryTime"])
		{
			vars.addTimeFlag = false;
			return timer.CurrentTime.GameTime.Value.Add(TimeSpan.FromSeconds(vars.ferryDepartB)); //2m
		}
	//If ferry leaves from necro island and loading starts, add ferryReturnA time
	else if((old.ferryActive == 48640) &&
		(old.loading == 128) &&
		(current.loading == 0) &&
		(old.mapID == 6) &&
		vars.addTimeFlag &&
		settings["restoreFerryTime"])
		{
			vars.addTimeFlag = false;
			return timer.CurrentTime.GameTime.Value.Add(TimeSpan.FromSeconds(vars.ferryReturnA)); //5m
		}
	//If ferry arrives at main island, add ferryReturnB time
	else if((old.ferryActive == 48640) &&
		(current.ferryActive != 48640) &&
		(current.loading == 128) &&
		(current.mapID == 1) &&
		vars.addTimeFlag &&
		settings["restoreFerryTime"])
		{
			vars.addTimeFlag = false;
			return timer.CurrentTime.GameTime.Value.Add(TimeSpan.FromSeconds(vars.ferryReturnB)); //10m
		}
	else
		return null;
}

split
{
	return(
		//Newer splits - since the run is shorter now
		//There are two splits (amuletSplit and deliverySplit) that are duplicated
		//The duplicates are to avoid confusion for those who just want to check one options list
		
			//Docks
		((current.interact == "inventory_object_file[18]") &&
		(current.mapID == 1) &&
		(current.markerID == 1) &&
		vars.dockFlag &&
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
		((current.interact == "inventory_object_file[11]") &&
		(current.mapID == 6) &&
		vars.amuletFlag &&
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
		
			//Silver Palace Key
		((current.interact == "inventory_object_file[79]") &&
		(current.mapID == 3) &&
		vars.palaceKeyFlag &&
		settings["palaceKeySplit"]) ||
		
			//Additional Splits
			//Leaving Palace (meant to replace the silver key split that is reportedly unreliable)
		((old.mapID == 3) &&
		(current.mapID == 30) &&
		settings["leavePalaceSplit"]) ||
			
			//Entering Gerrick's
		((old.mapID == 1) &&
		(current.mapID == 22) &&
		settings["enterShopSplit"]) ||
			
			//After Pirates
		((old.mapID == 0) &&
		(current.mapID == 1) &&
		vars.pirateFlag &&
		settings["afterPirates"]) ||
		
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
		
			//Normal Silver Key (Catacombs?)
		((current.interact == "inventory_object_file[10]") &&
		(current.mapID == 2) &&
		vars.normalSilverKeyFlag &&
		settings["silverKeySplit"]) ||
		
			//Palace Courtyard
		((old.mapID == 1) &&
		(current.mapID == 30) &&
		(current.markerID == 8) &&
		settings["courtyardSplit"]) ||
		
			//Final Split
			//This isn't tied to a group of settings, and should always happen
		(!vars.finalSplitFlag &&
		(current.mapID == 30) &&
		(current.finalCutscene == "AH!") &&
		(current.loading == 128))
	);
}

onSplit
{
	vars.pirateFlag = false;
	vars.dockFlag = false;
	vars.normalSilverKeyFlag = false;
	vars.palaceKeyFlag = false;
	vars.amuletFlag = false;
	
	if(!settings["spamFinalSplit"] &&
		!vars.finalSplitFlag &&
		(current.mapID == 30) &&
		(current.finalCutscene == "AH!") &&
		(current.loading == 128))
	{
		vars.finalSplitFlag = true;
	}
}

reset
{
	//if menuSelected becomes true and menuTransition doesn't, it means "new" was selected
	return (
		(current.menuSelected &&
		!old.menuSelected &&
		!current.menuTransition &&
		current.menuIndex == 0 &&
		current.menuOpen) ||
		
		(vars.cutsceneIndex == 4 &&
		settings["redundantReset"])
	);
}

onReset
{
	//initialize variables
	vars.pirateFlag = false;
	vars.postDockFlag = false;
	vars.ferryLoadingFlag = false;
	vars.finalSplitFlag = false;
	vars.cutsceneIndex = 0;
	vars.addTimeFlag = false;
	vars.addTimeIndex = 0;
}

exit
{
    //pauses timer if the game crashes
	timer.IsGameTimePaused = true;
}
