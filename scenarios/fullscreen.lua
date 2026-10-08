-- Turn on fullscreen in the options menu, then go back to the title and
-- play game A in it.
return {
	seed=1,
	{state="logo", timeout=5}, {press="return"}, {state="title"},
	{press="right"}, {press="right"}, {press="return"}, {state="options"},
	{press="down"}, {press="down"}, {press="down"}, {press="left"},
	{wait=1}, {shot="01_options"},
	{call=function(log) log("fullscreen", tostring(fullscreen), "window", love.graphics.getWidth(), love.graphics.getHeight(), "scale", scale) end},
	{press="escape"}, {state="title"}, {press="left"}, {press="left"}, {wait=0.5}, {shot="02_title"},
	{press="return"}, {state="menu"}, {press="return"}, {state="gameA"},
	{wait=2}, {shot="03_gameA"},
	{expect=function() return fullscreen == true, "fullscreen " .. tostring(fullscreen) end, label="fullscreen on"},
	{quit=true},
}
