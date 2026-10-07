-- Playtest harness. The runner appends `require "harness_main"` to a copy of
-- the game's main.lua, so this runs after the game's callbacks are defined
-- but before love.load. It plays the scenario in harness_scenario.lua with a
-- fixed clock, fixed random seed and simulated keyboard, so a run on a given
-- LÖVE version renders the same frames every time.
--
-- A scenario may set seed=n (default 1234) for the game's math.randomseed.
--
-- Scenario steps, run in order (a step waits until it can run):
--   {wait=seconds}                   let the game run
--   {state="gameA", timeout=s}       wait until gamestate matches (default 60s)
--   {press="return"}                 key press (released the same frame)
--   {hold="left"} / {release="left"} keep a key down for isDown()
--   {shot="name"}                    screenshot after this frame is drawn
--   {dump="name"}                    write gamestate, scores and piece bodies
--   {expect=function() return ok, detail end, label="..."}
--   {call=function(log) ... end}     anything else
--   {quit=true}
local compat = require "harness_compat"
local scenario = require "harness_scenario"

local FRAME = 1/60
local MAX_SECONDS = scenario.max_seconds or 600
local SEED = scenario.seed or 1234

local clock = 0 --simulated seconds since start
local t = 0 --simulated seconds since the current step started waiting
local step = 1
local frames = 0
local held = {}
local pendingshot = nil

local function log(...)
	local args = {...}
	for i = 1, select("#", ...) do
		args[i] = tostring(args[i])
	end
	io.stdout:write("[harness] ", table.concat(args, " "), "\n")
	io.stdout:flush()
end

local function fail(code, ...)
	log(...)
	io.stdout:flush()
	os.exit(code)
end

compat.onerror(function(msg)
	log("ERROR", tostring(msg))
	log(debug.traceback("", 2))
	os.exit(1)
end)

love.timer.getTime = function() return clock end
if love.timer.getMicroTime then
	love.timer.getMicroTime = function() return clock end
end
love.keyboard.isDown = function(...)
	for _, k in ipairs({...}) do
		if held[k] then
			return true
		end
	end
	return false
end
local randomseed = math.randomseed
math.randomseed = function() randomseed(SEED) end

local function dump(name)
	local lines = {
		"gamestate " .. tostring(gamestate),
		string.format("score %s level %s lines %s", tostring(scorescore), tostring(levelscore), tostring(linesscore)),
	}
	if tetribodies then
		for i = 1, table.maxn(tetribodies) do
			local b = tetribodies[i]
			if b then
				local vx, vy = b:getLinearVelocity()
				table.insert(lines, string.format("body %d kind %s pos %.3f %.3f angle %.4f vel %.3f %.3f",
					i, tostring(tetrikind and tetrikind[i]), b:getX(), b:getY(), b:getAngle(), vx, vy))
			end
		end
	end
	love.filesystem.write(name .. ".txt", table.concat(lines, "\n") .. "\n")
	log("dump", name, #lines - 2, "bodies")
end

local function runsteps()
	while step <= #scenario do
		local s = scenario[step]
		if s.wait and t < s.wait then
			return
		end
		if s.state and gamestate ~= s.state then
			if t > (s.timeout or 60) then
				fail(2, "TIMEOUT waiting for state", s.state, "still in", gamestate)
			end
			return
		end
		t = 0
		step = step + 1
		if s.press then
			compat.keypressed(s.press)
			compat.keyreleased(s.press)
		elseif s.hold then
			held[s.hold] = true
			compat.keypressed(s.hold)
		elseif s.release then
			held[s.release] = nil
			compat.keyreleased(s.release)
		elseif s.shot then
			--taken at the end of this frame's draw, so later steps wait a frame
			pendingshot = s.shot
			return
		elseif s.dump then
			dump(s.dump)
		elseif s.expect then
			local ok, detail = s.expect()
			if ok then
				log("ok", s.label or "", detail or "")
			else
				fail(3, "FAILED", s.label or "", detail or "")
			end
		elseif s.call then
			s.call(log)
		elseif s.quit then
			log("DONE", "love", compat.version, "state", gamestate, "frames", frames)
			compat.quit()
			return
		end
	end
end

local gameupdate = love.update
love.update = function(dt)
	frames = frames + 1
	clock = clock + FRAME
	t = t + FRAME
	if clock > MAX_SECONDS then
		fail(2, "TIMEOUT scenario still on step", step, "after", MAX_SECONDS, "simulated seconds")
	end
	runsteps()
	gameupdate(FRAME)
end

local gamedraw = love.draw
love.draw = function()
	gamedraw()
	if pendingshot then
		compat.screenshot(pendingshot)
		log("shot", pendingshot)
		pendingshot = nil
	end
end

log("start", "love", compat.version, "era", compat.era)
