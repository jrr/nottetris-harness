-- Fill the bottom row of game A to 10 blocks (two I pieces and an O; the
-- playfield is x 56-384 with its floor at y 576, 32 px to a block),
-- let the falling piece land on them, and check that the row is cleared:
-- pieces get cut, scored and fall.
local function place(kind, x, y)
	local id = highestbody() + 1
	createtetriA(kind, id, x, y)
	for _, shape in pairs(tetrishapes[id]) do
		local setdata = shape.setUserData or shape.setData --a fixture from 0.8 on
		setdata(shape, {id})
	end
end

return {
	seed=1,
	{state="logo", timeout=5}, {press="return"}, {state="title"},
	{press="return"}, {state="menu"}, {press="return"}, {state="gameA"},
	{wait=0.1},
	{call=function() place(1, 120, 550); place(1, 248, 550); place(4, 344, 534) end},
	{wait=1.5}, {shot="01_row_filled"},
	{hold="down"}, {wait=2.5}, {release="down"},
	{shot="02_clearing"},
	{wait=3}, {shot="03_after"}, {dump="state"},
	{expect=function() return linesscore >= 1, "lines " .. tostring(linesscore) end, label="a line was cleared"},
	{expect=function() return scorescore > 0, "score " .. tostring(scorescore) end, label="it scored"},
	{expect=function() return gamestate == "gameA", gamestate end, label="still playing"},
	{quit=true},
}
