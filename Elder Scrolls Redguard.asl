//The Elder Scrolls Adventure: Redguard Autosplitter V1.0.0 (30/04/2023)
//Script by TheDementedSalad & SabulineHorizon
//Steam Pointers found by TheDementedSalad
//GoG Pointers found by SabulineHorizon

state("dosbox","Steam")
{
   byte Loading		  	:	0x351690, 0x57B401;		//128 not loading 0 loading
   byte MapID			:	0x351690, 0x573194;		//1 starting town, 4 goblin cave
   byte MarkerID		:	0x351690, 0x57319C;		//+8 from MapID
   string20 Dialogue		:	0x351690, 0x9456;		//Shows whatever a character is speaking at the time in all caps
}

state("dosbox","GOG")
{
    byte Loading		:	0x273014, 0x3C9F3D;		//0 loading, 128 not loading (pre-game until start is also 0)
    byte MapID	 		:	0x273014, 0x376F5C;		//Same as Steam
    byte MarkerID		:	0x273014, 0x376F64;		//Same as Steam
    byte cutscene		: 	0x273014, 0x3AB8; //6 when cutscene is playing
    byte finalCutscene		: 	0x17086B8; //32 when final cutscene is playing (false positives during loading)
    string20 Dialogue		:	0x273014, 0x604038;		//Same as Steam
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
}

start
{
	return current.MapID == 0 && current.MarkerID == 0 && current.Loading == 128 && old.Loading == 0;
}

onStart
{
	vars.finalSplitFlag = false;
}

isLoading
{
	return current.Loading == 0;
}

split
{
	//if (version == "Steam")
	//else if (version == "GOG")
	
	if (version == "GOG")
	{
		// if a cutscene is playing and the final cutscene is marked
		if((current.cutscene == 6) && (current.finalCutscene == 32) && !vars.finalSplitFlag)
		{
			if(!settings["spamFinalSplit"]) vars.finalSplitFlag = true;
			return true;
		}
	}
}

onReset
{
	// initialize variables
	vars.finalSplitFlag = false;
}

exit
{
    //pauses timer if the game crashes
	timer.IsGameTimePaused = true;
}
