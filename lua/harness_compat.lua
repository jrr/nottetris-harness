-- The only harness file that knows how LÖVE's API differs between versions.
-- Each function lists the versions it has been checked against; anything else
-- fails loudly instead of guessing.
local compat = {}

-- 0.7.x sets love._version to a number (72 for 0.7.2); 0.8 onwards to a
-- string; 0.9.1 onwards also has love.getVersion().
local function detect()
	if love.getVersion then
		local major, minor, rev = love.getVersion()
		return major, minor, rev
	end
	local v = love._version
	if type(v) == "number" then
		return 0, math.floor(v / 10), v % 10
	end
	local major, minor, rev = tostring(v):match("^(%d+)%.(%d+)%.?(%d*)")
	return tonumber(major), tonumber(minor), tonumber(rev) or 0
end

local major, minor, rev = detect()
compat.version = string.format("%d.%d.%d", major, minor, rev)
-- 0.7.2 -> "0.7", 11.5 -> "11"
compat.era = major == 0 and ("0." .. minor) or tostring(major)

local function unsupported(what)
	error("harness: " .. what .. " not yet verified on LÖVE " .. compat.version, 2)
end

-- Error handler: verified 0.7.
function compat.onerror(fn)
	if compat.era == "0.7" then
		love.errhand = fn
	else
		unsupported("onerror")
	end
end

-- Deliver a key press to the game's own callback: verified 0.7.
function compat.keypressed(key)
	if not love.keypressed then
		return
	end
	if compat.era == "0.7" then
		local unicode = #key == 1 and key:byte() or (key == "return" and 13 or 0)
		love.keypressed(key, unicode)
	else
		unsupported("keypressed")
	end
end

function compat.keyreleased(key)
	if not love.keyreleased then
		return
	end
	if compat.era == "0.7" then
		local unicode = #key == 1 and key:byte() or (key == "return" and 13 or 0)
		love.keyreleased(key, unicode)
	else
		unsupported("keyreleased")
	end
end

-- Save what has been drawn so far this frame. Call at the end of love.draw,
-- before the frame is presented. Verified 0.7, where encode() writes
-- uncompressed TGA whatever format is asked for; the container converts it.
function compat.screenshot(name)
	if compat.era == "0.7" then
		local data = love.graphics.newScreenshot():encode("tga")
		love.filesystem.write(name .. ".tga", data)
	else
		unsupported("screenshot")
	end
end

-- Verified 0.7.
function compat.quit()
	if compat.era == "0.7" then
		love.event.push("q")
	else
		unsupported("quit")
	end
end

return compat
