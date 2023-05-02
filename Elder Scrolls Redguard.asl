//The Elder Scrolls Adventure: Redguard Autosplitter V1.0.1 (02/05/2023)
//Script by TheDementedSalad & SabulineHorizon

state("dosbox","Steam")
{
   byte loading		  	:	0x351690, 0x57B401;		//0 loading, 128 not loading (pre-game until start is also 0)
   byte mapID			:	0x351690, 0x573194;		//1 starting town, 4 goblin cave
   byte markerID		:	0x351690, 0x57319C;		//+8 from mapID
   string20 Dialogue		:	0x351690, 0x9456;		//Shows whatever a character is speaking at the time in all caps
   uint finalCutscene		: 	0x191B068;			//85788928 when final cutscene is playing (there might be false positives during loading)
}

state("dosbox","GOG")
{
    byte loading		:	0x273014, 0x3C9F3D;		//0 loading, 128 not loading (pre-game until start is also 0)
    byte mapID	 		:	0x273014, 0x376F5C;		//1 starting town, 4 goblin cave
    byte markerID		:	0x273014, 0x376F64;		//+8 from mapID
    string20 Dialogue		:	0x273014, 0x604038;		//Shows whatever a character is speaking at the time in all caps
    uint finalCutscene		: 	0x1709754;			//2155905152 when final cutscene is playing (there might be false positives during loading)
}

state("dosbox","GOG_Original")
{
    byte loading		:	0x4B34B4, 0x3C9F3D;		//0 loading, 128 not loading (pre-game until start is also 0)
    byte mapID	 		:	0x4B34B4, 0x376F5C;		//1 starting town, 4 goblin cave
    byte markerID		:	0x4B34B4, 0x376F64;		//+8 from mapID
    string20 Dialogue		:	0x4B34B4, 0x604038;		//Shows whatever a character is speaking at the time in all caps
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
	
	//Additional splits
	settings.Add("additionalSplits", true, "Additional Splits");
	settings.SetToolTip("additionalSplits", "Additional optional splits");
	
		settings.Add("spamFinalSplit", true, "Spam Final Split", "additionalSplits");
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
	//end split only for now, need to add some mid-run splits
	if (version == "Steam" && !vars.finalSplitFlag)
	{
		if(!settings["spamFinalSplit"]) vars.finalSplitFlag = true;
		return ((current.finalCutscene == 85788928) && (current.loading == 128) && (current.mapID == 30));
	}
	else if ((version == "GOG" || version == "GOG_Original") && !vars.finalSplitFlag)
	{
		if(!settings["spamFinalSplit"]) vars.finalSplitFlag = true;
		return ((current.finalCutscene == 2155905152) && (current.loading == 128) && (current.mapID == 30));
	}
}

reset
{
	//resets if mapID is initialized after gameplay has started
	return old.mapID != 255 && current.mapID == 255 && vars.canReset;
}

onReset
{
	//initialize variables
	vars.finalSplitFlag = false;
	vars.canStart = false;
}

exit
{
    //pauses timer if the game crashes
	timer.IsGameTimePaused = true;
}
