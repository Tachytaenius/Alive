local path = (...):gsub("%.[^%.]+$", "")

local suit = require(path .. ".lib.suit")
local input = require(path .. ".input")
local config = require(path .. ".config")
local settings = require(path .. ".settings")

local ui = {}

function ui.configure(array, userPathPrefix)
	ui.uis = {}
	for _, name in ipairs(array) do
		ui.uis[name] = require(userPathPrefix .. ".uis." .. name)
	end
	for _, name in ipairs({"plainPause", "settings", "quitConfirmation"}) do
		ui.uis[name] = require(path .. ".uis." .. name)
	end
end

function ui.construct(type)
	suit.enterFrame()
	
	ui.current = {
		type = type,
		mouseX = ui.current and ui.current.mouseX or config.canvasSystemWidth / 2,
		mouseY = ui.current and ui.current.mouseY or config.canvasSystemHeight / 2,
		scrollAmountY = 0
	}
	
	ui.uis[type].construct(ui.current)
end

function ui.destroy()
	ui.current = nil
	suit.updateMouse(nil, nil, false)
	suit.exitFrame()
end

-- destroy followed by construct resets cursor position. This doesn't
function ui.replace(type)
	assert(ui.current, "Can't replace UI without a UI")
	local mx, my = ui.current.mouseX, ui.current.mouseY
	ui.construct(type)
	ui.current.mouseX, ui.current.mouseY = mx, my
	suit.exitFrame()
	suit.enterFrame()
end

function ui.update()
	assert(ui.current, "Can't update UI without a UI")
	
	suit.updateMouse(ui.current.mouseX, ui.current.mouseY, love.mouse.isDown(1) and not require(path).disableMouseButtonUntilReleased) -- HACK to avoid a circular dependency error
	
	local destroy, typeToTransitionTo = ui.uis[ui.current.type].update(ui.current)
	if destroy then
		if typeToTransitionTo then
			ui.replace(typeToTransitionTo)
		else
			ui.destroy()
		end
	else
		ui.current.scrollAmountY = 0
	end
end

function ui.mouse(dx, dy)
	local div = settings.mouse.divideByScale and settings.graphics.scale or 1
	ui.current.mouseX = math.min(math.max(0, ui.current.mouseX + (dx * settings.mouse.xSensitivity) / div), config.canvasSystemWidth)
	ui.current.mouseY = math.min(math.max(0, ui.current.mouseY + (dy * settings.mouse.ySensitivity) / div), config.canvasSystemHeight)
end

return ui
