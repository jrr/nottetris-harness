-- Let game A pieces pile up in the middle until the stack reaches the top,
-- then type a name into the high score table. The score is set by hand,
-- since a pile-up scores nothing and only beating a high score asks for a
-- name.
return {
	seed=1, max_seconds=900,
	{state="logo", timeout=5}, {press="return"}, {state="title"},
	{press="return"}, {state="menu"}, {press="return"}, {state="gameA"},
	{call=function() scorescore = 123456 end},
	{hold="down"}, {state="failingA", timeout=300}, {release="down"},
	{shot="01_failing"},
	{state="failed", timeout=30}, {wait=1}, {shot="02_failed"}, {press="return"},
	{state="highscoreentry"}, {wait=0.5}, {shot="03_highscore"},
	{press="a"}, {press="b"}, {press="c"}, {press="return"},
	{state="menu", timeout=30}, {wait=0.5}, {shot="04_menu"},
	{expect=function() return highscorename[1] == "abc", "top name " .. tostring(highscorename[1]) end, label="name entered"},
	{quit=true},
}
