local Lucide = {}

local PACK_URL = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"
local PREFIX = "lucide:"

local pack = nil
local failed = false
local loading = false
local preloaded = {}
local warned = {}

local function fetch(url)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(body) == "string" and body ~= "" then
		return body
	end
	ok, body = pcall(function()
		return game:HttpGetAsync(url)
	end)
	if ok and type(body) == "string" and body ~= "" then
		return body
	end
	return nil
end

local function loadPack()
	if pack or failed then
		return pack
	end
	if loading then
		while loading do
			task.wait()
		end
		return pack
	end

	loading = true
	local ok, result = pcall(function()
		local body = fetch(PACK_URL)
		if not body then
			error("could not download the icon pack")
		end
		local chunk, err = loadstring(body)
		if not chunk then
			error(err)
		end
		return chunk()
	end)
	loading = false

	if ok and type(result) == "table" then
		pack = result
	else
		failed = true
		warn("[Ophyn] Lucide icons unavailable: " .. tostring(result))
	end
	return pack
end

local function toAsset(value)
	if type(value) == "number" then
		return "rbxassetid://" .. tostring(math.floor(value))
	end
	if type(value) == "string" and value:match("^%d+$") then
		return "rbxassetid://" .. value
	end
	return value
end

function Lucide.isName(value)
	if type(value) ~= "string" or value == "" then
		return false
	end
	if value:match("^%d+$") then
		return false
	end
	if value:match("^rbx%a*://") or value:match("^https?://") then
		return false
	end
	return true
end

local function stripPrefix(name)
	if name:sub(1, #PREFIX):lower() == PREFIX then
		return name:sub(#PREFIX + 1)
	end
	return name
end

local function preload(sheet)
	if preloaded[sheet] then
		return
	end
	preloaded[sheet] = true
	task.spawn(function()
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync({ sheet })
		end)
	end)
end

function Lucide.resolve(value)
	if not Lucide.isName(value) then
		return nil
	end

	local name = stripPrefix(value):lower():gsub("_", "-")
	local loaded = loadPack()
	if not loaded then
		return nil
	end

	local icons = loaded.Icons or loaded
	local entry = type(icons) == "table" and icons[name] or nil
	if type(entry) ~= "table" then
		if not warned[name] then
			warned[name] = true
			warn('[Ophyn] unknown Lucide icon "' .. tostring(value) .. '"')
		end
		return nil
	end

	local sheet = entry.Image
	if type(loaded.Spritesheets) == "table" and loaded.Spritesheets[tostring(entry.Image)] ~= nil then
		sheet = loaded.Spritesheets[tostring(entry.Image)]
	end
	sheet = toAsset(sheet)
	if type(sheet) ~= "string" then
		return nil
	end

	preload(sheet)
	return {
		Image = sheet,
		RectSize = entry.ImageRectSize or Vector2.new(0, 0),
		RectOffset = entry.ImageRectPosition or entry.ImageRectOffset or Vector2.new(0, 0),
	}
end

function Lucide.apply(label, value)
	local sprite = Lucide.resolve(value)
	if sprite then
		label.Image = sprite.Image
		label.ImageRectSize = sprite.RectSize
		label.ImageRectOffset = sprite.RectOffset
		return true
	end

	label.ImageRectSize = Vector2.new(0, 0)
	label.ImageRectOffset = Vector2.new(0, 0)
	if Lucide.isName(value) then
		label.Image = ""
		return false
	end
	label.Image = value or ""
	return value ~= nil
end

return Lucide
