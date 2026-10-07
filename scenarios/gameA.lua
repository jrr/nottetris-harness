-- Start game A, steer and rotate the first piece, drop it, and check that it
-- landed and the next piece spawned.
return {
	seed=1, --deals T, Z, J, L (seed 1234 deals only O pieces: nothing to rotate)
	{state="logo", timeout=5}, {press="return"}, {state="title"},
	{press="return"}, {state="menu"}, {press="return"}, {state="gameA"},
	{wait=1}, {shot="01_falling"},
	{hold="left"}, {wait=0.5}, {release="left"},
	{hold="x"}, {wait=0.4}, {release="x"},
	{hold="down"}, {wait=4}, {release="down"},
	{wait=1}, {shot="02_landed"}, {dump="state"},
	{expect=function() return gamestate == "gameA", gamestate end, label="still playing"},
	{expect=function()
		return tetribodies[2] ~= nil, "first piece became body 2, a new piece took slot 1"
	end, label="first piece landed"},
	{expect=function()
		local x = tetribodies[2]:getX()
		return x < 224, string.format("landed at x=%.1f, spawned at 224", x)
	end, label="moved left"},
	{quit=true},
}
