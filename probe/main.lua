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
		"love.filesystem.getSaveDirectory", "love.filesystem.write", "socket"}) do
		p("api", f, has(f))
	end
	p("lua", _VERSION, "jit", tostring(jit and jit.version))
end

local frames = 0
function love.update(dt) frames = frames + 1 end
function love.draw()
	love.graphics.setColor(255, 0, 0)
	love.graphics.rectangle("fill", 10, 10, 100, 50)
	if frames == 5 then
		local shot = love.graphics.newScreenshot()
		p("shot", type(shot), shot:getWidth(), shot:getHeight(), shot:getPixel(20, 20))
		local ok, res = pcall(function() return shot:encode("png") end)
		p("encode('png')", ok, type(res), ok and res.getSize and res:getSize() or tostring(res))
		if ok and res then
			for _, m in ipairs({"getString", "getPointer", "getSize", "typeOf", "type"}) do p("data method", m, tostring(res[m] ~= nil)) end
			p("fs.write", pcall(love.filesystem.write, "encode-png.bin", res))
			p("savedir", love.filesystem.getSaveDirectory())
		end
		p("quitting via push q")
		love.event.push("q")
	end
end
