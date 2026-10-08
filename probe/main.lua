-- Reports which harness-relevant APIs a LÖVE version has, then quits. Run it
-- first against each new version, before trusting harness_compat.lua there:
--
--   docker run --rm -v "$PWD/probe:/work/game:ro" -v "$PWD/out/probe:/work/files" \
--     nottetris-love:0.7.2 harness-entry 30
--
-- Findings on 0.7.2:
--   love._version is the number 72; no love.getVersion.
--   ImageData:encode("png") returns uncompressed TGA (bottom-up rows, header
--   says top-down), so out/probe/encode-png.bin is a TGA.
--   Encoded Data has no getString; write it with love.filesystem.write.
--   love.filesystem.write fails unless the save dir's parent exists
--   (harness-entry sets XDG_DATA_HOME to one that does).
--   An error inside love.draw shows the error screen forever unless
--   love.errhand is replaced; love.event.push("q") quits.
--
-- Findings on 0.8.0:
--   love._version is the string "0.8.0"; still no love.getVersion.
--   ImageData:encode(name) writes a real PNG straight to the save directory,
--   named exactly as given (encode("png") writes a file called "png"), the
--   right way up, and returns nothing.
--   love.event.quit exists. Still Lua 5.1, no LuaJIT.
--
-- Findings on 0.9.2:
--   love.getVersion() exists. love.timer.getMicroTime, love.graphics.setMode
--   and getModes are gone: window code is in love.window (getMode returns a
--   flags table; getDesktopDimensions is 1280x1024 under the harness's Xvfb).
--   ImageData:encode(name) writes a PNG as on 0.8, taking the format from the
--   name's extension (so encode("png") is an error).
--   Key events: keypressed(key, isrepeat), keyreleased(key), and typed text
--   arrives separately in textinput(text).
--   Lua 5.1 here only because Ubuntu 16.04 has no arm64 LuaJIT package.
local function p(...) print(...) io.stdout:flush() end
local function has(path)
	local t = _G
	for part in path:gmatch("[^.]+") do
		if type(t) ~= "table" and type(t) ~= "userdata" then return "no" end
		t = t[part]
	end
	return t == nil and "no" or type(t)
end

love.errhand = function(msg)
	p("ERROR", tostring(msg))
	p(debug.traceback())
	os.exit(1)
end

function love.load()
	p("_version", tostring(love._version), "major", tostring(love._version_major), "minor", tostring(love._version_minor), "rev", tostring(love._version_revision))
	for _, f in ipairs({"love.getVersion", "love.errhand", "love.errorhandler", "love.run",
		"love.timer.getTime", "love.timer.getMicroTime", "love.timer.step",
		"love.graphics.newScreenshot", "love.graphics.captureScreenshot",
		"love.event.quit", "love.event.push", "love.textinput",
		"love.filesystem.getSaveDirectory", "love.filesystem.write", "love.filesystem.exists",
		"love.graphics.setMode", "love.graphics.getModes", "love.graphics.getWidth",
		"love.window", "love.window.setMode", "love.window.getMode", "love.window.getFullscreenModes",
		"love.window.getDesktopDimensions", "love.window.setFullscreen",
		"love.keyboard.setKeyRepeat", "love.keyboard.setTextInput", "socket"}) do
		p("api", f, has(f))
	end
	p("lua", _VERSION, "jit", tostring(jit and jit.version))
end

-- Which arguments the key callbacks get from real (pushed) events.
function love.keypressed(...) p("keypressed", ...) end
function love.keyreleased(...) p("keyreleased", ...) end
local textinput = love.textinput
function love.textinput(...) p("textinput", ...) end

local frames = 0
function love.update(dt)
	frames = frames + 1
	if frames == 2 then
		if love.window and love.window.getMode then
			p("window.getMode", love.window.getMode())
			local w, h, flags = love.window.getMode()
			if type(flags) == "table" then
				for k, v in pairs(flags) do p("window flag", k, tostring(v)) end
			end
		end
		if love.window and love.window.getDesktopDimensions then
			p("desktop", love.window.getDesktopDimensions())
		end
		pcall(love.event.push, "keypressed", "a", false)
		pcall(love.event.push, "textinput", "a")
	end
end
function love.draw()
	love.graphics.setColor(255, 0, 0)
	love.graphics.rectangle("fill", 10, 10, 100, 50)
	if frames == 5 then
		local shot = love.graphics.newScreenshot()
		p("shot", type(shot), shot:getWidth(), shot:getHeight(), shot:getPixel(20, 20))
		local ok, res = pcall(function() return shot:encode("png") end)
		p("encode('png')", ok, type(res), ok and res and res.getSize and res:getSize() or tostring(res))
		local ok2, res2 = pcall(function() return shot:encode("probe.png") end)
		p("encode('probe.png')", ok2, type(res2), tostring(res2), "exists", tostring(love.filesystem.exists and love.filesystem.exists("probe.png")))
		p("encode wrote a file called png", love.filesystem.exists and love.filesystem.exists("png") or "?")
		if ok and res then
			for _, m in ipairs({"getString", "getPointer", "getSize", "typeOf", "type"}) do p("data method", m, tostring(res[m] ~= nil)) end
			p("fs.write", pcall(love.filesystem.write, "encode-png.bin", res))
			p("savedir", love.filesystem.getSaveDirectory())
		end
		if love.event.quit then
			p("quitting via love.event.quit")
			love.event.quit()
		else
			p("quitting via push q")
			love.event.push("q")
		end
	end
end
