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

local frameCommands = {
	
}

local fixedCommands = {
	moveForward = "whileDown",
	moveBackward = "whileDown",
	moveLeft = "whileDown",
	moveRight = "whileDown"
}

local settingsUiLayout = {
	{title = "Mouse",
		{name = "Turn Sensitivity", "mouse","turnSensitivity",
			getLowLimit = function() return 0 end,
			getLimit = function() return 1 end
		}
	}
}

local settingsTypes = boilerplate.settingsTypes
local settingsTemplate = {
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

local superWorld -- The whole game instance

function boilerplate.load(args)
	registry.load()
	
	local seed = love.math.random(0, consts.maxWorldSeed)
	local rng = love.math.newRandomGenerator(seed)
	
	superWorld = {
		seed = seed,
		rng = rng,
		unsaved = true,
		time = 0,
		nextSubWorldId = consts.firstSubWorldId,
		subWorldsById = {}
	}
	
	local mainSubWorld = concord.world()
	mainSubWorld.id = superWorld.nextSubWorldId
	superWorld.subWorldsById[superWorld.nextSubWorldId] = mainSubWorld
	mainSubWorld.superWorld = superWorld
	superWorld.nextSubWorldId = superWorld.nextSubWorldId + 1
	mainSubWorld
		:addSystem(systems.quantities) -- Should be first
		:addSystem(systems.map)
		:addSystem(systems.flying)
		:addSystem(systems.wills)
		:addSystem(systems.walking)
		:addSystem(systems.movement)
		:addSystem(systems.rendering)
		:addSystem(systems.hud)
	
	local player = concord.entity()
		:give("position", 0, 0)
		:give("velocity")
		:give("sprite", 10)
		:give("will")
		:give("grounded")
		:give("gait", 100, 800, 100, 10)
		:give("flyingRecoveryRate", 100)
		:give("angle", 0)
		:give("angularVelocity")
		:give("angularGait", math.tau * 2, math.tau * 32)
		:give("vision", 1024)
		:give("player")
	
	mainSubWorld
		:addEntity(player)
	
	for _, subWorld in ipairs(superWorld.subWorldsById) do
		subWorld:emit("newWorld")
	end
end

local function getSubWorldsAsArray()
	-- For determinism reasons
	local array = {}
	for _, subWorld in pairs(superWorld.subWorldsById) do
		array[#array + 1] = subWorld
	end
	table.sort(array, function(a, b)
		return a.id < b.id
	end)
	return array
end

function boilerplate.update(dt, performance)
	for _, subWorld in ipairs(getSubWorldsAsArray()) do
		subWorld:emit("update", dt)
	end
end

function boilerplate.fixedUpdate(dt)
	superWorld.time = superWorld.time + dt
	for _, subWorld in ipairs(getSubWorldsAsArray()) do
		subWorld:emit("fixedUpdate", dt)
	end
	superWorld.unsaved = true
end

function boilerplate.draw(lerp, dt, performance)
	for _, subWorld in ipairs(getSubWorldsAsArray()) do -- TEMP
		subWorld:emit("draw", lerp, dt, performance)
	end
end

function boilerplate.getUnsaved()
	return superWorld.unsaved
end

function boilerplate.save()
	superWorld.unsaved = false
end

function boilerplate.killThreads()
	love.thread.getChannel(consts.quitChannelName):push("quit")
	for _, subWorld in pairs(superWorld.subWorldsById) do
		while subWorld.map.chunkLoadingThread:isRunning() do
			-- pass
		end
	end
end

boilerplate.init(initConfig, arg)

function love.threaderror(thread, errorString)
	error("Thread error!\n" .. errorString)
end
