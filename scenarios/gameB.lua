-- Start game B and drop three pieces, steering the first, and check that
-- they land and the game carries on.
return {
	seed=1,
	{state="logo", timeout=5}, {press="return"}, {state="title"},
	{press="return"}, {state="menu"}, {press="right"}, {press="return"}, {state="gameB"},
	{wait=1}, {shot="01_falling"},
	{hold="right"}, {wait=0.5}, {release="right"},
	{hold="down"}, {wait=12}, {release="down"},
	{wait=1}, {shot="02_landed"}, {dump="state"},
	{expect=function() return gamestate == "gameB", gamestate end, label="still playing"},
	{expect=function() return tetribodies[4] ~= nil, "three pieces landed" end, label="pieces landed"},
	{quit=true},
}
