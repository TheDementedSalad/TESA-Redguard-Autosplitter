//The Elder Scrolls Adventure: Redguard Autosplitter V1.0.2 (03/05/2023)
//Script by TheDementedSalad & SabulineHorizon

state("dosbox","Steam")
{
   byte loading		  	:	0x351690, 0x57B401;		//0 loading, 128 not loading (pre-game until start is also 0)
   byte mapID			:	0x351690, 0x573194;		//1 starting town, 4 goblin cave
   byte markerID		:	0x351690, 0x57319C;		//+8 from mapID
   string20 dialogue1		:	0x351690, 0x9456;		//Various descriptions and exclamations
   string20 dialogue2		:	0x351690, 0x589BD4;		//Selected text during dialogue
   string30 interact		:	0x351690, 0x57B500;		//Text that appears for interacting with items
   uint finalCutscene		: 	0x191B068;			//85788928 when final cutscene is playing (there might be false positives during loading)
}

state("dosbox","GOG")
{
    byte loading		:	0x273014, 0x3C9F3D;		//0 loading, 128 not loading (pre-game until start is also 0)
    byte mapID	 		:	0x273014, 0x376F5C;		//1 starting town, 4 goblin cave
    byte markerID		:	0x273014, 0x376F64;		//+8 from mapID
    string20 dialogue1		:	0x273014, 0x604038;		//Various descriptions and exclamations
    string20 dialogue2		:	0x273014, 0x3C95A8;		//Selected text during dialogue
    string30 interact		:	0x273014, 0x3D3DB8;		//Text that appears for interacting with items
    uint finalCutscene		: 	0x1709754;			//2155905152 when final cutscene is playing (there might be false positives during loading)
}

state("dosbox","GOG_Original")
{
    byte loading		:	0x4B34B4, 0x3C9F3D;		//0 loading, 128 not loading (pre-game until start is also 0)
    byte mapID	 		:	0x4B34B4, 0x376F5C;		//1 starting town, 4 goblin cave
    byte markerID		:	0x4B34B4, 0x376F64;		//+8 from mapID
    string20 dialogue1		:	0x4B34B4, 0x604038;		//Various descriptions and exclamations
    string20 dialogue2		:	0x4B34B4, 0x3C95A8;		//Selected text during dialogue
    string30 interact		:	0x4B34B4, 0x3D3DB8;		//Text that appears for interacting with items
    uint finalCutscene		: 	0x1949B40;			//2155905152 when final cutscene is playing (there might be false positives during loading)
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
	vars.canReset = false;
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
	
	//Main Splits
	settings.Add("mainSplits", false, "Main Splits (Experimental)");
	settings.SetToolTip("mainSplits", "These have not been tested thoroughly yet, some might not work");
	
		settings.Add("caveSplit", true, "Cave Exit", "mainSplits");
		settings.SetToolTip("caveSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("amuletSplit", true, "N'Gasta's Amulet", "mainSplits");
		settings.SetToolTip("amuletSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("deliverySplit", true, "Amulet Delivery", "mainSplits");
		settings.SetToolTip("deliverySplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("escapeSplit", true, "Escape", "mainSplits");
		settings.SetToolTip("escapeSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("insigniaSplit", true, "League Insignia", "mainSplits");
		settings.SetToolTip("insigniaSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("scarabSplit", true, "Scarab Door", "mainSplits");
		settings.SetToolTip("scarabSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("ruinsSplit", true, "Ruins Exit", "mainSplits");
		settings.SetToolTip("ruinsSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("hideoutSplit", true, "League Hideout", "mainSplits");
		settings.SetToolTip("hideoutSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("oldQuarterSplit", true, "Old Quarter", "mainSplits");
		settings.SetToolTip("oldQuarterSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("flaskSplit", true, "Flask of Lillandril", "mainSplits");
		settings.SetToolTip("flaskSplit", "This should work but hasn't been tested at all yet");
		
		settings.Add("soulSplit", true, "Iszara's Soul", "mainSplits");
		settings.SetToolTip("soulSplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("silverKeySplit", true, "Silver Key", "mainSplits");
		settings.SetToolTip("silverKeySplit", "This should work but hasn't been fully tested yet");
		
		settings.Add("courtyardSplit", true, "Palace Courtyard", "mainSplits");
		settings.SetToolTip("courtyardSplit", "This should work but hasn't been fully tested yet");
		
	//Additional settings
	settings.Add("additionalSettings", true, "Additional Settings");
	settings.SetToolTip("additionalSettings", "Additional settings");
	
		settings.Add("spamFinalSplit", true, "Spam Final Split", "additionalSettings");
		settings.SetToolTip("spamFinalSplit", "Once the final split triggers, it will keep triggering until the timer stops in case some splits were missed");
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
	//avoids resets when first loading game after crash (some crash resets still slip through, not sure)
	if(old.loading == 0 && current.loading == 128)
		vars.canReset = true;
	
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
		return ((current.finalCutscene == 85788928) && (current.loading == 128));
	}
	else if ((version == "GOG" || version == "GOG_Original") && !vars.finalSplitFlag && (current.mapID == 30))
	{
		if(!settings["spamFinalSplit"]) vars.finalSplitFlag = true;
		return ((current.finalCutscene == 2155905152) && (current.loading == 128));
	}
	else
	{
		// print("Current mapID: " + current.mapID.ToString());
		return(
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
	//RESETS ARE TEMPORARILY DISABLED DUE TO SOME FALSE POSITIVES
	//resets if mapID is initialized after gameplay has started
	//return old.mapID != 255 && current.mapID == 255 && vars.canReset;
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
