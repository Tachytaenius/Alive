local registry = require("registry")
local consts = require("consts")

local rendering = {}

function rendering:makeChunkMeshes(chunk)
	local tileMeshVertexCount = consts.chunkWidth * consts.chunkHeight * 6
	chunk.toppingMesh = love.graphics.newMesh(consts.tileMeshVertexFormat, tileMeshVertexCount, "triangles", "dynamic")
	chunk.superToppingMeshes = {}
	for i = 1, consts.maxSubLayers do
		chunk.superToppingMeshes[i] = love.graphics.newMesh(consts.tileMeshVertexFormat, tileMeshVertexCount, "triangles", "dynamic")
	end
end

local function getGrassNoiseFullness(subLayer)
	local grassMaterial = registry.materials.byName[subLayer.lump.constituents[1].materialName]
	local grassNoiseFullness1 = grassMaterial.grassNoiseFullness1 or 1
	return grassNoiseFullness1 == 0 and 1 or subLayer.lump.grassAmount / grassNoiseFullness1 -- NOTE: Does not need to be capped at 1
end

local function calculateConstituentDrawFields(materialAmount, tableToWriteTo, grassHealth)
	local weightTotal = 0
	local red, green, blue, lightInfoR, lightInfoG, lightInfoB, noiseSize, noiseContrast, noiseBrightness = 0, 0, 0, 0, 0, 0, 0, 0, 0
	for material, amount in pairs(materialAmount) do
		local weight = amount * (material.visualWeight or 1)
		weightTotal = weightTotal + weight
		
		-- Get colour in linear space
		local materialRed, materialGreen, materialBlue = love.math.gammaToLinear(material.colour[1], material.colour[2], material.colour[3])
		if grassHealth and material.grassDeadColour then
			local deadRed, deadGreen, deadBlue = love.math.gammaToLinear(material.grassDeadColour[1], material.grassDeadColour[2], material.grassDeadColour[3])
			materialRed = math.lerp(deadRed, materialRed, grassHealth)
			materialGreen = math.lerp(deadGreen, materialGreen, grassHealth)
			materialBlue = math.lerp(deadBlue, materialBlue, grassHealth)
		end
		red = red + materialRed * weight
		green = green + materialGreen * weight
		blue = blue + materialBlue * weight
		
		-- Get light info colour in linear space
		local materialLightInfoR, materialLightInfoG, materialLightInfoB
		if material.lightInfoColour then
			materialLightInfoR, materialLightInfoG, materialLightInfoB = love.math.gammaToLinear(
				material.lightInfoColour[1],
				material.lightInfoColour[2],
				material.lightInfoColour[3]
			)
		else
			materialLightInfoR, materialLightInfoG, materialLightInfoB = 0, 0, 0
		end
		lightInfoR = lightInfoR + materialLightInfoR * weight
		lightInfoG = lightInfoG + materialLightInfoG * weight
		lightInfoB = lightInfoB + materialLightInfoB * weight
		
		noiseSize = noiseSize + (material.noiseSize or 10) * weight
		noiseContrast = noiseContrast + (material.noiseContrast or 0.5) * weight
		noiseBrightness = noiseBrightness + (material.noiseBrightness or 0.5) * weight
	end
	
	-- Convert colours back to sRGB
	tableToWriteTo.red, tableToWriteTo.green, tableToWriteTo.blue = love.math.linearToGamma(
		red / weightTotal,
		green / weightTotal,
		blue / weightTotal
	)
	tableToWriteTo.lightInfoR, tableToWriteTo.lightInfoG, tableToWriteTo.lightInfoB = love.math.linearToGamma(
		lightInfoR / weightTotal,
		lightInfoG / weightTotal,
		lightInfoB / weightTotal
	)
	
	tableToWriteTo.noiseSize = math.max(consts.minimumTextureNoiseSize,
		math.floor((noiseSize / weightTotal) / consts.textureNoiseSizeIrresolution) * consts.textureNoiseSizeIrresolution
	)
	tableToWriteTo.noiseContrast = noiseContrast / weightTotal
	tableToWriteTo.noiseBrightness = noiseBrightness / weightTotal
end

function rendering:updateTileRendering(tile)
	local x, y = tile.globalTileX, tile.globalTileY
	
	-- Update topping
	if tile.topping then
		local materialAmount = {}
		if tile.topping.lumps.compressedToOne then
			for _, constituent in ipairs(tile.topping.lumps.compressionLump.constituents) do
				local material = registry.materials.byName[constituent.materialName]
				materialAmount[material] = (materialAmount[material] or 0) + constituent.amount * tile.topping.lumps.compressionLumpCount
			end
		else
			for _, lump in ipairs(tile.topping.lumps) do
				for _, constituent in ipairs(lump.constituents) do
					local material = registry.materials.byName[constituent.materialName]
					materialAmount[material] = (materialAmount[material] or 0) + constituent.amount
				end
			end
		end
		calculateConstituentDrawFields(materialAmount, tile.topping)
	end
	
	-- Update super topping
	if tile.superTopping then
		if tile.superTopping.type == "subLayers" then
			for _, subLayer in ipairs(tile.superTopping.subLayers) do
				local materialAmount = {}
				for _, constituent in ipairs(subLayer.lump.constituents) do
					materialAmount[registry.materials.byName[constituent.materialName]] = constituent.amount
				end
				calculateConstituentDrawFields(materialAmount, subLayer, subLayer.type == "grass" and subLayer.lump.grassHealth)
				subLayer.noiseFullness = getGrassNoiseFullness(subLayer)
			end
		else -- type == "wall"
			local materialAmount = {}
			if tile.superTopping.lumps.compressedToOne then
				for _, constituent in ipairs(tile.superTopping.lumps.compressionLump.constituents) do
					local material = registry.materials.byName[constituent.materialName]
					materialAmount[material] = (materialAmount[material] or 0) + constituent.amount * tile.superTopping.lumps.compressionLumpCount
				end
			else
				for _, lump in ipairs(tile.superTopping.lumps) do
					for _, constituent in ipairs(lump.constituents) do
						local material = registry.materials.byName[constituent.materialName]
						materialAmount[material] = (materialAmount[material] or 0) + constituent.amount
					end
				end
			end
			calculateConstituentDrawFields(materialAmount, tile.superTopping)
		end
	end
	
	local changedTiles = self:getWorld().rendering.changedTiles
	changedTiles[#changedTiles + 1] = tile
end

return rendering
