local boilerplate = require("lib.love-game-boilerplate-lib")
local concord = require("lib.concord")

package.loaded.systems = {}
package.loaded.assemblages = {}
local systems = require("systems")
local assemblages = require("assemblages")
concord.utils.loadNamespace("components")
concord.utils.loadNamespace("systems", systems)
concord.utils.loadNamespace("assemblages", assemblages)

require("monkeypatch")

local consts = require("consts")
local registry = require("registry")
local util = require("util")

local frameCommands = {

}

local fixedCommands = {
	moveForward = "whileDown",
	moveBackward = "whileDown",
	moveLeft = "whileDown",
	moveRight = "whileDown"
}

local settingsUiLayout = {
	{title = "Graphics",
		{name = "Fog Fade Length", "graphics","fogFadeLength",
			getLowLimit = function() return 0 end,
			getLimit = function() return 40 end
		},
		{name = "Crush Start Ratio", "graphics","crushStartRatio",
			getLowLimit = function() return 0.01 end,
			getLimit = function() return 1 end
		}
	},
	{title = "Mouse",
		{name = "Turn Sensitivity", "mouse","turnSensitivity",
			getLowLimit = function() return 0 end,
			getLimit = function() return 1 end
		}
	}
}

local settingsTypes = boilerplate.settingsTypes
local settingsTemplate = {
	graphics = {
		fogFadeLength = settingsTypes.number(10),
		crushStartRatio = settingsTypes.number(0.3)
	},
	mouse = {
		turnSensitivity = settingsTypes.number(0.5)
	},
	fixedCommands = settingsTypes.commands("fixed", {
		moveForward = "w",
		moveBackward = "s",
		moveLeft = "a",
		moveRight = "d"
	})
}

local uiNames = {

}

local assetsConstructors, assetsUtilities = boilerplate.assetsConstructors, boilerplate.assetsUtilities
local assets = {
	noiseTexture = {load = function(self)
		self.value = love.graphics.newImage("assets/images/noiseTexture.png")
		self.value:setFilter("linear")
		self.value:setWrap("repeat")
	end},
	lightInfluenceTexture = {load = function(self)
		local lightInfluenceTextureCanvas = love.graphics.newCanvas(consts.lightInfluenceTextureSize, consts.lightInfluenceTextureSize)
		love.graphics.setCanvas(lightInfluenceTextureCanvas)
		love.graphics.setShader(love.graphics.newShader([[
			vec4 effect(vec4 colour, sampler2D texture, vec2 textureCoords, vec2 windowCoords) {
				vec2 transformedTextureCoords = (textureCoords - 0.5) * 2.0;
				float value = max(0.0, 1.0 - length(transformedTextureCoords));
				return vec4(vec3(value), 1.0);
			}
		]]))
		love.graphics.draw(love.graphics.newImage(love.image.newImageData(1, 1)), 0, 0, 0, consts.lightInfluenceTextureSize)
		love.graphics.setCanvas()
		love.graphics.setShader()
		self.value = love.graphics.newImage(lightInfluenceTextureCanvas:newImageData())
		self.value:setFilter("linear")
	end},
	nullTexture = {load = function(self) self.value = love.graphics.newImage(love.image.newImageData(1, 1)) end},
	whiteNullTexture = {
		load = function(self)
			local imageData = love.image.newImageData(1, 1)
			imageData:mapPixel(function()
				return 1, 1, 1, 1
			end)
			self.value = love.graphics.newImage(imageData)
		end
	},
	ui = {
		font = {load = function(self) self.value = love.graphics.newImageFont("assets/images/ui/font.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.!?$,#@~:;-{}&()<>'%/*0123456789") end},
		cursor = {load = function(self) self.value = love.graphics.newImage("assets/images/ui/cursor.png") end}
	}
}

local initConfig = {
	fixedUpdateTickLength = consts.fixedUpdateTickLength,
	canvasSystemWidth = consts.canvasSystemWidth,
	canvasSystemHeight = consts.canvasSystemHeight,
	windowTitle = consts.windowTitle,
	frameCommands = frameCommands,
	fixedCommands = fixedCommands,
	settingsUiLayout = settingsUiLayout,
	settingsTemplate = settingsTemplate,
	uiNames = uiNames,
	uiNamePathPrefix = "uis",
	uiTint = {0.5, 0.5, 0.5},
	assets = assets,
	suppressQuitWithDoubleQuitEvent = true,
	defaultFilterMin = "nearest",
	defaultFilterMag = nil,
	defaultFilterAnisotropy = nil,
	lineStyle = "smooth",
	scrollSpeed = 20,
	uiPad = 4,
	uiButtonPad = 2,
	pauseInputType = "released"
}

local gameInstance

local function ensureDirectory(name)
	local info = love.filesystem.getInfo(name)
	if not info then
		love.filesystem.createDirectory(name)
	elseif info.type ~= "directory" then
		error("There is a non-directory item called \"" .. name .. "\" in your Alive data folder, please remove it or rename it to run the game")
	end
end

local function recursivelyDelete(item)
	-- From the wiki
	if love.filesystem.getInfo(item, "directory") then
		for _, child in ipairs(love.filesystem.getDirectoryItems(item)) do
			recursivelyDelete(item .. "/" .. child)
			love.filesystem.remove(item .. "/" .. child)
		end
	elseif love.filesystem.getInfo(item) then
		love.filesystem.remove(item)
	end
	love.filesystem.remove(item)
end

local function ensureEmptyDirectory(name)
	-- TEMP/HACK: Bodge
	local info = love.filesystem.getInfo(name)
	if not info then
		ensureDirectory(name)
		return
	elseif info.type ~= "directory" then
		error("There is a non-directory item called \"" .. name .. "\" in your Alive data folder, please remove it or rename it to run the game")
	end
	recursivelyDelete(name)
	ensureDirectory(name)
end

function boilerplate.load(args)
	registry.load()

	local seed = love.math.random(0, consts.maxWorldSeed)
	local rng = love.math.newRandomGenerator(seed)

	ensureEmptyDirectory("current")
	ensureDirectory("saves")

	boilerplate.log.info("Creating game instance")

	gameInstance = {
		seed = seed,
		rng = rng,
		unsaved = true,
		time = 0,
		savePathPrefix = "saves/saveFile/",
		nextSubWorldId = consts.firstSubWorldId,
		subWorldsById = {}
	}

	ensureDirectory(gameInstance.savePathPrefix)

	local mainSubWorld = concord.world()
	mainSubWorld.id = gameInstance.nextSubWorldId
	gameInstance.subWorldsById[gameInstance.nextSubWorldId] = mainSubWorld
	mainSubWorld.gameInstance = gameInstance
	gameInstance.nextSubWorldId = gameInstance.nextSubWorldId + 1
	mainSubWorld
		:addSystem(systems.quantities) -- Should be first
		:addSystem(systems.map) -- Should come before most other processing as it ensures the world is present
		:addSystem(systems.flying)
		:addSystem(systems.wills)
		:addSystem(systems.walking)
		:addSystem(systems.movement)
		:addSystem(systems.rendering)
		:addSystem(systems.hud)

	local player = concord.entity():assemble(assemblages.testEntity):give("player")
	mainSubWorld:addEntity(player)

	for _, subWorld in ipairs(gameInstance.subWorldsById) do
		subWorld:emit("newWorld")
	end

	boilerplate.log.info("Done initialising game instance")
end

local function getSubWorldsAsArray()
	-- For determinism reasons
	local array = {}
	for _, subWorld in pairs(gameInstance.subWorldsById) do
		array[#array + 1] = subWorld
	end
	table.sort(array, function(a, b)
		return a.id < b.id
	end)
	return array
end

function boilerplate.update(dt, performance)
	util.iterateOverAllThreads(gameInstance, function(thread)
		local err = thread:getError()
		assert(not err, err)
	end)
	for _, subWorld in ipairs(getSubWorldsAsArray()) do
		subWorld:emit("update", dt)
	end
end

function boilerplate.fixedUpdate(dt)
	gameInstance.time = gameInstance.time + dt
	for _, subWorld in ipairs(getSubWorldsAsArray()) do
		subWorld:emit("fixedUpdate", dt)
	end
	gameInstance.unsaved = true
end

function boilerplate.draw(lerp, dt, performance)
	for _, subWorld in ipairs(getSubWorldsAsArray()) do -- TEMP
		subWorld:emit("draw", lerp, dt, performance)
	end
end

function boilerplate.getUnsaved()
	return gameInstance.unsaved
end

function boilerplate.save()
	boilerplate.log.info("Saving game")
	local sourceChunksPath = "current/chunks/"
	local destinationChunksPath = gameInstance.savePathPrefix .. "chunks/"
	ensureDirectory(destinationChunksPath)
	for _, itemName in ipairs(love.filesystem.getDirectoryItems(sourceChunksPath)) do
		local data = love.filesystem.read(sourceChunksPath .. itemName)
		love.filesystem.remove(sourceChunksPath .. itemName)
		love.filesystem.write(destinationChunksPath .. itemName, data)
	end
	boilerplate.log.info("Saved game")
	gameInstance.unsaved = false
end

function boilerplate.onQuit()
	recursivelyDelete("current")
end

function boilerplate.killThreads()
	love.thread.getChannel(consts.quitChannelName):push("quit")
	local timeStart = love.timer.getTime()
	local definitelyQuitAllThreads = true
	util.iterateOverAllThreads(gameInstance, function(thread)
		while thread:isRunning() do
			if love.timer.getTime() - timeStart > consts.threadShutdownTime then
				boilerplate.log.error("Chunk loading thread in sub-world with ID " .. subWorld.id .. " hasn't shut down after " .. consts.threadShutdownTime .. " seconds")
				definitelyQuitAllThreads = false
				break
			end
		end
	end)
	return definitelyQuitAllThreads
end

boilerplate.init(initConfig, arg)

function love.threaderror(thread, errorString)
	error("Thread error!\n" .. errorString)
end
