local boilerplate = require("lib.love-game-boilerplate-lib")
local concord = require("lib.concord")
local vec2 = require("lib.mathsies").vec2

local consts = require("consts")
local util = require("util")

local rendering = concord.system({
	players = {"position", "player", "vision"},
	sprites = {"position", "sprite"}, lights = {"position", "light"}
})

function rendering:sendConstantsToShaders()
	self.crushAndClipShader:send("inputCanvasSize", {consts.preCrushCanvasWidth, consts.preCrushCanvasHeight})
	
	self.noiseShader:send("noiseTexture", boilerplate.assets.noiseTexture.value)
	self.noiseShader:send("noiseTextureSize", {boilerplate.assets.noiseTexture.value:getDimensions()})
	self.noiseShader:send("fullnessNoiseSize", consts.fullnessNoiseSize)
	self.noiseShader:send("fullnessNoiseOffset", consts.fullnessNoiseOffset)
	
	self.lightingShader:send("revealDepth", consts.shadowTextureRevealDepth)
	self.lightingShader:send("forceNonRevealMinDepth", consts.shadowForceTextureNonRevealMinDepth)
end

function rendering:init()
	self.albedoCanvas = love.graphics.newCanvas(consts.preCrushCanvasWidth, consts.preCrushCanvasHeight)
	self.lightFilterCanvas = love.graphics.newCanvas(consts.preCrushCanvasWidth, consts.preCrushCanvasHeight)
	self.lightingCanvas = love.graphics.newCanvas(consts.preCrushCanvasWidth, consts.preCrushCanvasHeight)
	
	self.crushedLightFilterCanvas = love.graphics.newCanvas(boilerplate.config.canvasSystemWidth, boilerplate.config.canvasSystemHeight)
	
	if consts.linearFilterLightFilterCanvas then
		self.lightFilterCanvas:setFilter("linear", "linear")
		self.crushedLightFilterCanvas:setFilter("linear", "linear")
	end
	
	self.crushAndClipShader = love.graphics.newShader("shaders/crushAndClip.glsl")
	self.noiseShader = love.graphics.newShader("shaders/noise.glsl")
	self.lightingShader = love.graphics.newShader("shaders/lighting.glsl")
	self:sendConstantsToShaders()
	
	self.changedTiles = {}
end

local function setTileMeshVertices(mesh, iBase, x, y, ...)
	mesh:setVertex(iBase, x * consts.tileWidth, y * consts.tileHeight, ...)
	mesh:setVertex(iBase + 1, (x + 1) * consts.tileWidth, y * consts.tileHeight, ...)
	mesh:setVertex(iBase + 2, x * consts.tileWidth, (y + 1) * consts.tileHeight, ...)
	
	mesh:setVertex(iBase + 3, x * consts.tileWidth, (y + 1) * consts.tileHeight, ...)
	mesh:setVertex(iBase + 4, (x + 1) * consts.tileWidth, y * consts.tileHeight, ...)
	mesh:setVertex(iBase + 5, (x + 1) * consts.tileWidth, (y + 1) * consts.tileHeight, ...)
end

function rendering:fixedUpdate(dt)
	for _, tile in ipairs(self.changedTiles) do
		local localTileX, localTileY = tile.localTileX, tile.localTileY
		local globalTileX, globalTileY = tile.globalTileX, tile.globalTileY
		local chunk = tile.chunk
		local iBase = (localTileX + localTileY * consts.chunkWidth) * 6 + 1
		
		-- Update topping
		if tile.topping then
			local
				colourR, colourG, colourB, colourA,
				lightFilterColourR, lightFilterColourG, lightFilterColourB, lightFilterColourA,
				noiseSize, noiseContrast, noiseBrightness, noiseFullness
			=
				tile.topping.red, tile.topping.green, tile.topping.blue, tile.topping.alpha,
				nil, nil, nil, 0, -- This isn't a wall
				tile.topping.noiseSize, tile.topping.noiseContrast, tile.topping.noiseBrightness, 1
			
			setTileMeshVertices(chunk.toppingMesh, iBase, globalTileX, globalTileY,
				colourR, colourG, colourB, colourA,
				lightFilterColourR, lightFilterColourG, lightFilterColourB, lightFilterColourA,
				noiseSize, noiseContrast, noiseBrightness, noiseFullness
			)
		else
			for i = 0, 5 do
				self.toppingMesh:setVertex(iBase + i) -- nil all
			end
		end
		
		-- Update super topping
		if tile.superTopping then
			if tile.superTopping.type == "wall" then
				local
					colourR, colourG, colourB, colourA,
					lightFilterColourR, lightFilterColourG, lightFilterColourB, lightFilterColourA,
					noiseSize, noiseContrast, noiseBrightness, noiseFullness
				=
					tile.superTopping.red, tile.superTopping.green, tile.superTopping.blue, tile.superTopping.alpha,
					tile.superTopping.lightFilterR, tile.superTopping.lightFilterG, tile.superTopping.lightFilterB, 1,
					tile.superTopping.noiseSize, tile.superTopping.noiseContrast, tile.superTopping.noiseBrightness, 1
				
				setTileMeshVertices(chunk.superToppingMeshes[1], iBase, globalTileX, globalTileY,
					colourR, colourG, colourB, colourA,
					lightFilterColourR, lightFilterColourG, lightFilterColourB, lightFilterColourA,
					noiseSize, noiseContrast, noiseBrightness, noiseFullness
				)
				
				for j = 2, consts.maxSubLayers do -- Clear meshes used for sub-layers
					for i = 0, 5 do
						chunk.superToppingMeshes[j]:setVertex(iBase + i) -- nil all
					end
				end
			else -- "subLayers"
				for j = 1, consts.maxSubLayers do
					local subLayer = tile.superTopping.subLayers[j]
					if subLayer then
						local
							colourR, colourG, colourB, colourA,
							lightFilterColourR, lightFilterColourG, lightFilterColourB, lightFilterColourA,
							noiseSize, noiseContrast, noiseBrightness, noiseFullness
						=
							subLayer.red, subLayer.green, subLayer.blue, subLayer.alpha,
							nil, nil, nil, 0, -- This isn't a wall
							subLayer.noiseSize, subLayer.noiseContrast, subLayer.noiseBrightness, subLayer.noiseFullness
						
						setTileMeshVertices(chunk.superToppingMeshes[j], iBase, globalTileX, globalTileY,
							colourR, colourG, colourB, colourA,
							lightFilterColourR, lightFilterColourG, lightFilterColourB, lightFilterColourA,
							noiseSize, noiseContrast, noiseBrightness, noiseFullness
						)
					else
						for i = 0, 5 do
							chunk.superToppingMeshes[j]:setVertex(iBase + i) -- nil all
						end
					end
				end
			end
		else -- No super topping
			for j = 1, consts.maxSubLayers do
				for i = 0, 5 do
					chunk.superToppingMeshes[j]:setVertex(iBase + i) -- nil all
				end
			end
		end
	end
	self.changedTiles = {}
end

function rendering:drawSprite(e)
	love.graphics.circle("fill", e.position.interpolated.x, e.position.interpolated.y, e.sprite.radius)
end

function rendering:shouldDrawChunk(x, y, player, renderDistance, sensingCircleRadius)
	local lineStart = player.position.interpolated
	local lineDirection = vec2.rotate(vec2(1, 0), player.angle.interpolated) -- TEMP: Should be vec2.fromAngle
	local lineEnd = lineStart - lineDirection -- Subtraction to invert which side of the divided plane is supposed to be drawn
	return
		self:getWorld().map:chunkPositionIsInRadius(x, y, player, renderDistance) and
		util.collision.dividedPlaneAabb(lineStart.x, lineStart.y, lineEnd.x, lineEnd.y, x * consts.chunkWidth * consts.tileWidth, y * consts.chunkHeight * consts.chunkHeight,  consts.chunkWidth * consts.tileWidth, consts.chunkHeight * consts.chunkHeight) or
		self:getWorld().map:chunkPositionIsInRadius(x, y, player, sensingCircleRadius)
end

function rendering:draw(lerp, dt, performance)
	local player = self.players[1]
	if not player then
		return
	end
	
	-- Make render setups
	local tileCanvasSetup = {
		self.albedoCanvas, self.lightFilterCanvas
	}
	local canvasCrushSetup = {
		boilerplate.gameCanvas, self.crushedLightFilterCanvas
	}
	
	local renderDistance = player.vision.maxViewDistance
	local sensingCircleRadius = 30 -- TODO
	local viewPadding = 4 -- TODO
	local fov = 7 * math.tau / 16 -- TODO
	local ambientLightR, ambientLightG, ambientLightB = 1, 1, 1 -- TODO
	
	assert(renderDistance <= consts.chunkProcessingRadius, "Player vision is greater than chunk processing radius")
	assert(boilerplate.settings.graphics.crushStartRatio > 0 and boilerplate.settings.graphics.crushStartRatio <= 1, "Crush start ratio must be between 0 (exclusive) and 1 (inclusive).")
	
	local preCrushPlayerPosX, preCrushPlayerPosY = consts.preCrushCanvasWidth / 2, consts.preCrushCanvasHeight / 2
	
	love.graphics.translate(preCrushPlayerPosX, preCrushPlayerPosY)
	love.graphics.rotate(-player.angle.interpolated)
	love.graphics.translate(-player.position.interpolated.x, -player.position.interpolated.y)
	
	local mapSystem = self:getWorld().map
	
	love.graphics.setCanvas(self.albedoCanvas)
	love.graphics.clear()
	love.graphics.setCanvas(self.lightFilterCanvas)
	love.graphics.clear(1, 1, 1, 0)
	
	-- Draw toppings
	love.graphics.setCanvas(tileCanvasSetup)
	love.graphics.setShader(self.noiseShader)
	local x1, x2, y1, y2 = mapSystem:getChunkIterationStartEnd(player, renderDistance)
	for x = x1, x2 do
		for y = y1, y2 do
			if self:shouldDrawChunk(x, y, player, renderDistance, sensingCircleRadius) then
				local chunk = mapSystem:getLoadedChunk(x, y)
				if chunk.toppingPresent then
					assert(chunk, "Missing chunk in draw radius at " .. x .. ", " .. y)
					love.graphics.draw(chunk.toppingMesh)
				end
			end
		end
	end
	
	-- Draw superToppings
	love.graphics.setCanvas(tileCanvasSetup)
	love.graphics.setShader(self.noiseShader)
	local x1, x2, y1, y2 = mapSystem:getChunkIterationStartEnd(player, renderDistance)
	for x = x1, x2 do
		for y = y1, y2 do
			if self:shouldDrawChunk(x, y, player, renderDistance, sensingCircleRadius) then
				local chunk = mapSystem:getLoadedChunk(x, y)
				assert(chunk, "Missing chunk in draw radius at " .. x .. ", " .. y)
				for i, mesh in ipairs(chunk.superToppingMeshes) do
					if chunk.superToppingPresences[i] then
						love.graphics.draw(mesh)
					end
				end
			end
		end
	end
	
	-- Draw entities
	love.graphics.setCanvas(self.albedoCanvas)
	love.graphics.setShader()
	local sprites = {}
	for i, v in ipairs(self.sprites) do
		sprites[i] = v
	end
	table.sort(sprites, function(a, blue)
		-- Draw closer sprites on top, i.e. draw more distant sprites first
		-- TODO: Also draw sprites on top of the topping layer on top
		return vec2.distance(a.position.interpolated, player.position.interpolated) > vec2.distance(blue.position.interpolated, player.position.interpolated)
	end)
	for _, e in ipairs(sprites) do
		self:drawSprite(e)
	end
	
	-- Switch to lights phase
	love.graphics.setCanvas(self.lightingCanvas)
	self.lightingShader:send("canvasSize", {consts.preCrushCanvasWidth, consts.preCrushCanvasHeight})
	self.lightingShader:send("isView", false)
	love.graphics.setShader()
	love.graphics.clear(ambientLightR, ambientLightG, ambientLightB)
	self.lightingShader:send("lightFilterCanvas", self.lightFilterCanvas)
	love.graphics.setShader(self.lightingShader)
	love.graphics.setBlendMode("add")
	
	-- Draw lights
	for _, e in ipairs(self.lights) do
		local posInWindowSpace = e.position.interpolated
		posInWindowSpace = posInWindowSpace - player.position.interpolated
		posInWindowSpace = vec2.rotate(posInWindowSpace, -player.angle.interpolated)
		posInWindowSpace = posInWindowSpace + vec2(preCrushPlayerPosX, preCrushPlayerPosY)
		self.lightingShader:send("lightOrigin", {vec2.components(posInWindowSpace)})
		love.graphics.setColor(e.light.red, e.light.green, e.light.blue)
		love.graphics.draw(boilerplate.assets.lightInfluenceTexture.value, e.position.interpolated.x - e.light.radius, e.position.interpolated.y - e.light.radius, 0, e.light.radius * 2 / consts.lightInfluenceTextureSize)
	end
	love.graphics.setColor(1, 1, 1)
	
	-- Multiply albedo into lighting canvas
	love.graphics.origin()
	love.graphics.setShader()
	love.graphics.setBlendMode("multiply", "premultiplied")
	love.graphics.draw(self.albedoCanvas)
	love.graphics.setBlendMode("alpha", "alphamultiply")
	
	-- Draw lighting canvas to boilerplate canvas
	-- Draw light filter canvas to crushed light filter canvas
	love.graphics.setCanvas(boilerplate.gameCanvas)
	love.graphics.clear(0, 0, 0, 1)
	love.graphics.setCanvas(self.crushedLightFilterCanvas)
	love.graphics.clear(1, 1, 1, 0)
	love.graphics.setCanvas(canvasCrushSetup)
	love.graphics.setShader(self.crushAndClipShader)
	local crushCentreX, crushCentreY = preCrushPlayerPosX, preCrushPlayerPosY
	local crushEnd = consts.crushEnd
	local crushStart = boilerplate.settings.graphics.crushStartRatio * crushEnd
	local power = math.log(renderDistance / crushStart) / math.log(crushEnd / crushStart)
	self.crushAndClipShader:send("crushCentre", {crushCentreX, crushCentreY})
	self.crushAndClipShader:send("crushStart", crushStart)
	self.crushAndClipShader:send("crushEnd", crushEnd)
	self.crushAndClipShader:send("power", power)
	self.crushAndClipShader:send("sensingCircleRadius", sensingCircleRadius)
	self.crushAndClipShader:send("fov", fov)
	self.crushAndClipShader:send("fogFadeLength", boilerplate.settings.graphics.fogFadeLength)
	self.crushAndClipShader:send("lightingCanvas", self.lightingCanvas)
	self.crushAndClipShader:send("lightFilterCanvas", self.lightFilterCanvas)
	love.graphics.draw(boilerplate.assets.nullTexture.value,
		boilerplate.config.canvasSystemWidth / 2 - crushCentreX,
		boilerplate.config.canvasSystemHeight - sensingCircleRadius - viewPadding - crushCentreY,
		0,
		consts.preCrushCanvasWidth, consts.preCrushCanvasHeight
	)
	
	-- Do light shader over view canvas with whiteNullTexture
	love.graphics.setCanvas(boilerplate.gameCanvas)
	love.graphics.setBlendMode("multiply", "premultiplied")
	love.graphics.setShader(self.lightingShader)
	self.lightingShader:send("lightFilterCanvas", self.crushedLightFilterCanvas)
	self.lightingShader:send("canvasSize", {boilerplate.config.canvasSystemWidth, boilerplate.config.canvasSystemHeight})
	self.lightingShader:send("crushStart", crushStart)
	self.lightingShader:send("power", power)
	self.lightingShader:send("isView", true)
	self.lightingShader:send("lightOrigin", {
		boilerplate.config.canvasSystemWidth / 2,
		boilerplate.config.canvasSystemHeight - sensingCircleRadius - viewPadding
	})
	love.graphics.draw(boilerplate.assets.whiteNullTexture.value, 0, 0, 0, boilerplate.config.canvasSystemWidth, boilerplate.config.canvasSystemHeight)
	love.graphics.setBlendMode("alpha", "alphamultiply")
	
	-- Finish
	love.graphics.setCanvas()
	love.graphics.setShader()
end

return rendering
