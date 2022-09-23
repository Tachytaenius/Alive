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
	
}

local settingsTypes = boilerplate.settingsTypes
local settingsTemplate = {
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
	ui = {
		font = {load = function(self) self.value = love.graphics.newImageFont("assets/images/ui/font.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.!?$,#@~:;-{}&()<>'%/*0123456789") end},
		cursor = {load = function(self) self.value = love.graphics.newImage("assets/images/ui/cursor.png") end}
	}
}

local initConfig = {
	fixedUpdateTickLength = 1 / 24,
	canvasSystemWidth = 480,
	canvasSystemHeight = 270,
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

local world

function boilerplate.load(args)
	registry.load()
	world = concord.world()
	world
		:addSystem(systems.quantities) -- Should be first
		:addSystem(systems.map)
		:addSystem(systems.flying)
		:addSystem(systems.wills)
		:addSystem(systems.walking)
		:addSystem(systems.movement)
		:addSystem(systems.rendering)
		:addSystem(systems.hud)
	local player = concord.entity():give("position", 0, 0):give("velocity"):give("sprite", 10):give("will"):give("grounded"):give("gait", 100, 800, 100, 10):give("flyingRecoveryRate", 100)
	local otherGuy = concord.entity():give("position", 0, 0):give("velocity"):give("sprite", 10):give("will"):give("grounded"):give("gait", 100, 800, 100, 10):give("flyingRecoveryRate", 100)
	player:give("player")
	world
		:addEntity(player)
		:addEntity(otherGuy)
	world:emit("newWorld", 64, 64)
	world.unsaved = true
end

function boilerplate.update(dt, performance)
	world:emit("update", dt)
end

function boilerplate.fixedUpdate(dt)
	world:emit("fixedUpdate", dt)
	world.unsaved = true
	-- use boilerplate.fixedMouseDx and boilerplate.fixedMouseDy to look around et cetera
end

function boilerplate.draw(lerp, dt, performance)
	world:emit("draw", lerp, dt, performance)
end

function boilerplate.getUnsaved()
	return world.unsaved
end

function boilerplate.save()
	world.unsaved = false
end

function boilerplate.quit()
	
end

boilerplate.init(initConfig, arg)
