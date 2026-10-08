-- Press escape on the title screen: the game should close itself. If it
-- does, the run ends here; if the quit errors, the harness reports the
-- error; if nothing happens, the expect step fails.
return {
	{state="logo", timeout=5}, {press="return"}, {state="title"}, {wait=0.5},
	{press="escape"},
	{wait=2},
	{expect=function() return false, "still running 2 seconds after escape" end, label="escape quits"},
}
