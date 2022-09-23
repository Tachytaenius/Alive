local concord = require("lib.concord")

local registry = require("registry")
local consts = require("consts")

local map = concord.system({})

function map:newWorld(width, height)
	self.width, self.height = width, height
	
	self.soilMaterials = {
		{material = registry.materials.byName.loam, abundance = 10},
		{material = registry.materials.byName.clay, abundance = 5},
		{material = registry.materials.byName.sand, abundance = 2}
	}
	
	local tiles = {}
	self.tiles = tiles
	for x = 0, width - 1 do
		local column = {}
		tiles[x] = column
		for y = 0, height - 1 do
			local tile = {}
			
			-- Generate topping
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
			self:updateToppingDrawFields(x, y)
			
			tile.superTopping = nil
		end
	end
end

function map:updateToppingDrawFields(x, y)
	local tileTopping = self.tiles[x][y].topping
	local materialAmount = {}
	for _, chunk in ipairs(tileTopping.chunks) do
		for _, constituent in ipairs(chunk.constituents) do
			local material = constituent.material
			materialAmount[material] = (materialAmount[material] or 0) + constituent.amount
		end
	end
	local weightTotal = 0
	local r, g, b = 0, 0, 0
	for material, amount in pairs(materialAmount) do
		local weight = amount * (material.visualWeight or 1)
		weightTotal = weightTotal + weight
		r = r + material.colour[1] * weight
		g = g + material.colour[2] * weight
		b = b + material.colour[3] * weight
	end
	tileTopping.r = r / weightTotal
	tileTopping.g = g / weightTotal
	tileTopping.b = b / weightTotal
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
