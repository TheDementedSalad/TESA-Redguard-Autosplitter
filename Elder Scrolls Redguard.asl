//The Elder Scrolls Adventure: Redguard Autosplitter V1.0.0 (30/04/2023)
//Script by TheDementedSalad & SabulineHorizon
//Steam Pointers found by TheDementedSalad
//GoG Pointers found by SabulineHorizon

state("dosbox","Steam")
{
   byte GameState		:	0x351690, 0x571CC0;		//1 loading/menu/cutscene 0 in game
   byte MapID			:	0x351690, 0x573194;		//1 starting town, 4 goblin cave
   byte MarkerID		:	0x351690, 0x57319C;		//+8 from MapID
   string20 Dialogue	:	0x351690, 0x9456;		//Shows whatever a character is speaking at the time in all caps
}

state("dosbox", "GoG")
{
	byte GameState		:	0x273014, 0x376F94;
    byte MapID	 		:	0x273014, 0x376F5C;
    byte MarkerID		:	0x273014, 0x376F64;
}


init
{
	vars.completedSplits = new List<string>();
	
	switch (modules.First().ModuleMemorySize)
	{
		case (34119680):
			version = "Steam";
			break;
		case (39788544):
			version = "GoG";
			break;
	}
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
}

update
{
	//print(modules.First().ModuleMemorySize.ToString());
	
	if(timer.CurrentPhase == TimerPhase.NotRunning)
	{
		vars.completedSplits.Clear();
	}
}

start
{
	return current.MapID == 0 && current.MarkerID == 0 && current.Loading == 0 && old.Loading == 1;
}

isLoading
{
	return current.GameState == 1;
}

split
{

}

exit
{
    //pauses timer if the game crashes
	timer.IsGameTimePaused = true;
}