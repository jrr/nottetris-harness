-- Start a two player game B, steer both players' first pieces, drop a few,
-- and check that both stacks grow and the game carries on.
return {
	seed=1,
	{state="logo", timeout=5}, {press="return"}, {state="title"},
	{press="right"}, {press="return"}, {state="multimenu"}, {press="return"}, {state="gameBmulti"},
	{wait=1}, {shot="01_falling"},
	{hold="a"}, {hold="right"}, {wait=0.5}, {release="a"}, {release="right"},
	{hold="s"}, {hold="down"}, {wait=10}, {release="s"}, {release="down"},
	{wait=1}, {shot="02_landed"},
	{expect=function() return gamestate == "gameBmulti", gamestate end, label="still playing"},
	{expect=function() return tetribodiesp1[3] ~= nil and tetribodiesp2[3] ~= nil, "both players landed two pieces" end, label="pieces landed"},
	{quit=true},
}
