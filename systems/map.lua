local concord = require("lib.concord")

local consts = require("consts")

local map = concord.system({})

function map:newWorld(width, height)
	self.width, self.height = width, height
	
	self.soilMaterials = {
		{material = "loam", abundance = 10}, -- TODO: Links to the materials registry instead of just strings
		{material = "clay", abundance = 5},
		{material = "sand", abundance = 2}
	}
	
	local tiles = {}
	self.tiles = tiles
	for x = 0, width - 1 do
		local column = {}
		tiles[x] = column
		for y = 0, height - 1 do
			local tile = {}
			column[y] = tile
			tile.topping = {
				type = "solid",
				chunks = {}
			}
			local constituents = self:generateConstituents(x, y, self.soilMaterials)
			for _=1, consts.chunksPerLayer do
				local chunk = {}
				tile.topping.chunks[#tile.topping.chunks + 1] = chunk
				chunk.constituents = constituents
			end
			tile.superTopping = nil
		end
	end
end

function map:generateConstituents(x, y, materialsSet)
	-- All constituents must add up to const.chunkConstituentsTotal
	local constituents = {}
	
	-- Get base weights
	local total1 = 0
	for i, materialsSetEntry in pairs(materialsSet) do
		local amount = math.random() * materialsSetEntry.abundance -- TODO: replace with clouds
		constituents[i] = {material = materialsSetEntry.material, amount = amount}
		total1 = total1 + amount
	end
	
	-- Get proper amounts
	local total2 = 0
	for i, entry in ipairs(constituents) do
		entry.amount = math.floor(consts.chunkConstituentsTotal * entry.amount / total1)
		total2 = total2 + entry.amount
	end
	
	-- Spread remainder (this could be done differently)
	local i = 1
	for _ = 1, consts.chunkConstituentsTotal - total2 do
		constituents[i].amount = constituents[i].amount + 1
		i = (i - 1 + 1) % #constituents + 1
	end
	
	-- Debug test
	-- local total3 = 0
	-- for i, entry in ipairs(constituents) do
	-- 	total3 = total3 + entry.amount
	-- end
	-- assert(total3 == consts.chunkConstituentsTotal)
	
	return constituents
end

function map:validate()
	-- TODO: Go over every tile and check that the structure is correct, and error if not
end

function map:mine(x, y, layerName, subLayerIndex)
	local tile = self.tiles[x][y]
	if layerName == "topping" then
		-- TODO: mine topping
	else -- layerName == "superTopping"
		if tile.superTopping.type == "wall" then
			-- TODO: mine super topping wall
		else -- tile.superTopping.type == "subLayers"
			local subLayer = tile.superTopping.subLayers[subLayerIndex]
			-- TODO: mine super topping sub-layer
		end
	end
end

return map
