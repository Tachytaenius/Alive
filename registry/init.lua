local json = require("lib.json")

local function traverse(registryTable, path, createFromJson)
	local directoryItems = love.filesystem.getDirectoryItems(path)
	table.sort(directoryItems) -- For deterministic ids
	for _, itemName in ipairs(directoryItems) do
		local path = path .. itemName
		if love.filesystem.getInfo(path, "directory") then
			traverse(registryTable, path .. "/", createFromJson)
		elseif love.filesystem.getInfo(path, "file") then
			if itemName:match("%.json$") then
				local jsonData = json.decode(love.filesystem.read(path))
				local entryName = itemName:sub(1, -6) -- remove .json
				local entry = createFromJson(jsonData, entryName, path)
				entry.name = entryName
				registryTable.byName[entryName] = entry
				entry.id = registryTable.nextId
				registryTable.byId[registryTable.nextId] = entry
				registryTable.nextId = registryTable.nextId + 1
			end
		end
	end
end

local registry = {
	materials = {byName = {}, byId = {}, nextId = 0}
}

local nextMaterialid = 1
local function createMaterial(jsonData, entryName, path)
	local entry = jsonData
	return entry
end

local function createRealmTheme(jsonData, entryName, path)
	local entry = jsonData
	
end

function registry.load()
	traverse(registry.materials, "registry/materials/", createMaterial)
end

return registry
