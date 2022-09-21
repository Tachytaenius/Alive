local boilerplate = require("lib.love-game-boilerplate-lib")
local concord = require("lib.concord")

local consts = require("consts")

local rendering = concord.system({players = {"player"}, sprites = {"position", "sprite"}})

function rendering:init()
	self.preCrushCanvas = love.graphics.newCanvas(consts.preCrushCanvasWidth, consts.preCrushCanvasHeight)
	-- self.crushShader = love.graphics.newShader("shaders/crush.glsl")
	self.dummyImage = love.graphics.newImage(love.image.newImageData(1, 1))
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
	local tilesX1, tilesX2 = 0, mapSystem.width - 1
	local tilesY1, tilesY2 = 0, mapSystem.height - 1
	
	-- Draw toppings
	for x = tilesX1, tilesX2 do
		local column = mapSystem.tiles[x]
		for y = tilesY1, tilesY2 do
			local tile = column[y]
			if tile.topping then
				love.graphics.rectangle("fill", x * consts.tileWidth, y * consts.tileHeight, consts.tileWidth, consts.tileHeight)
			end
		end
	end
	
	-- Draw entities in ditches
	for _, e in ipairs(normalHeightSprites) do
		self:drawSprite(e)
	end
	
	-- Draw superToppings
	for x = tilesX1, tilesX2 do
		local column = mapSystem.tiles[x]
		for y = tilesY1, tilesY2 do
			local tile = column[y]
			if tile.superTopping then
				if tile.superTopping.type == "layer" then
					love.graphics.rectangle("fill", x * consts.tileWidth, y * consts.tileHeight, consts.tileWidth, consts.tileHeight)
				else -- wall
					love.graphics.rectangle("fill", x * consts.tileWidth, y * consts.tileHeight, consts.tileWidth, consts.tileHeight)
				end
			end
		end
	end
	
	-- Draw entities at normal height
	for _, e in ipairs(normalHeightSprites) do
		self:drawSprite(e)
	end
	
	love.graphics.origin()
	love.graphics.setCanvas()
end

return rendering
