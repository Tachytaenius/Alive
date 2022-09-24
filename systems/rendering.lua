local boilerplate = require("lib.love-game-boilerplate-lib")
local concord = require("lib.concord")

local consts = require("consts")

local rendering = concord.system({players = {"player"}, sprites = {"position", "sprite"}})

function rendering:sendConstantsToShaders()
	self.textureShader:send("tileSize", {consts.tileWidth, consts.tileHeight})
	self.textureShader:send("noiseTexture", boilerplate.assets.noiseTexture.value)
	self.textureShader:send("noiseTextureSize", {boilerplate.assets.noiseTexture.value:getDimensions()})
end

function rendering:init()
	self.preCrushCanvas = love.graphics.newCanvas(consts.preCrushCanvasWidth, consts.preCrushCanvasHeight)
	
	self.dummyImage = love.graphics.newImage(love.image.newImageData(1, 1))
	
	-- self.crushShader = love.graphics.newShader("shaders/crush.glsl")
	self.textureShader = love.graphics.newShader("shaders/texture.glsl")
	
	self:sendConstantsToShaders()
end

function rendering:drawSprite(e)
	love.graphics.circle("fill", e.position.lerpedValue.x, e.position.lerpedValue.y, e.sprite.radius)
end

function rendering:draw(lerp, dt, performance)
	player = self.players[1]
	if not player then
		return
	end
	
	love.graphics.setCanvas(boilerplate.gameCanvas)
	love.graphics.clear(0, 0, 0, 1)
	love.graphics.translate(-player.position.lerpedValue.x, -player.position.lerpedValue.y)
	love.graphics.translate(boilerplate.config.canvasSystemWidth / 2, boilerplate.config.canvasSystemHeight / 2)
	
	local normalHeightSprites = self.sprites -- TODO
	
	local mapSystem = self:getWorld().map
	local tilesX1, tilesX2 = 0, mapSystem.width - 1 -- TODO
	local tilesY1, tilesY2 = 0, mapSystem.height - 1
	
	-- Draw toppings
	love.graphics.setShader(self.textureShader)
	for x = tilesX1, tilesX2 do
		local column = mapSystem.tiles[x]
		for y = tilesY1, tilesY2 do
			local tile = column[y]
			if tile.topping then
				self.textureShader:send("useNoise", true)
				local drawX, drawY = x * consts.tileWidth, y * consts.tileHeight
				self.textureShader:send("tilePosition", {drawX, drawY})
				self.textureShader:send("noiseSize", tile.topping.noiseSize)
				self.textureShader:send("contrast", tile.topping.contrast)
				self.textureShader:send("brightness", tile.topping.brightness)
				self.textureShader:send("fullness", 1)
				love.graphics.setColor(tile.topping.r, tile.topping.g, tile.topping.b)
				love.graphics.draw(self.dummyImage, drawX, drawY, 0, consts.tileWidth, consts.tileHeight)
			end
		end
	end
	love.graphics.setColor(1, 1, 1)
	love.graphics.setShader()
	
	-- Draw entities in ditches
	for _, e in ipairs(normalHeightSprites) do
		self:drawSprite(e)
	end
	
	-- Draw superToppings
	love.graphics.setShader(self.textureShader)
	for x = tilesX1, tilesX2 do
		local column = mapSystem.tiles[x]
		for y = tilesY1, tilesY2 do
			local tile = column[y]
			if tile.superTopping then
				if tile.superTopping.type == "layers" then
					for _, subLayer in ipairs(tile.superTopping.subLayers) do
						self.textureShader:send("useNoise", true)
						local drawX, drawY = x * consts.tileWidth, y * consts.tileHeight
						self.textureShader:send("tilePosition", {drawX, drawY})
						self.textureShader:send("noiseSize", subLayer.noiseSize)
						self.textureShader:send("contrast", subLayer.contrast)
						self.textureShader:send("brightness", subLayer.brightness)
						if subLayer.type == "grass" then
							local grassMaterial = subLayer.chunk.constituents[1].material
							local fullness1 = grassMaterial.fullness1 or 1
							local fullness = fullness1 == 0 and 1 or subLayer.grassAmount / fullness1 -- NOTE: Does not need to be capped to 1
							self.textureShader:send("fullness", fullness)
						else
							self.textureShader:send("fullness", 1)
						end
						love.graphics.setColor(subLayer.r, subLayer.g, subLayer.b)
						love.graphics.draw(self.dummyImage, drawX, drawY, 0, consts.tileWidth, consts.tileHeight)
					end
				else -- wall
					self.textureShader:send("useNoise", true)
					local drawX, drawY = x * consts.tileWidth, y * consts.tileHeight
					self.textureShader:send("tilePosition", {drawX, drawY})
					self.textureShader:send("noiseSize", tile.superTopping.noiseSize)
					self.textureShader:send("contrast", tile.superTopping.contrast)
					self.textureShader:send("brightness", tile.superTopping.brightness)
					self.textureShader:send("fullness", 1)
					love.graphics.setColor(subLayer.r, subLayer.g, subLayer.b)
					love.graphics.draw(self.dummyImage, drawX, drawY, 0, consts.tileWidth, consts.tileHeight)
				end
			end
		end
	end
	love.graphics.setColor(1, 1, 1)
	love.graphics.setShader()
	
	-- Draw entities at normal height
	for _, e in ipairs(normalHeightSprites) do
		self:drawSprite(e)
	end
	
	love.graphics.origin()
	love.graphics.setCanvas()
end

return rendering
