local path = (...):gsub("%.[^%.]+$", ""):gsub("%.uis$", "")

local suit = require(path .. ".lib.suit")

local config = require(path .. ".config")
local assets = require(path .. ".assets")

local plainPause = {}

function plainPause.construct(state)
	state.causesPause = true
end

function plainPause.update(state)
	suit.layout:reset(config.canvasSystemWidth / 3, config.canvasSystemHeight / 3, config.uiPad)
	if suit.Button("Resume", suit.layout:row(config.canvasSystemWidth / 3, assets.ui.font.value:getHeight() + config.uiButtonPad)).hit then
		return true -- Destroy UI
	end
	if suit.Button("Release Mouse", suit.layout:row()).hit then
		love.mouse.setRelativeMode(false)
	end
	if suit.Button("Settings", suit.layout:row()).hit then
		return true, "settings" -- Replace UI with settings UI
	end
	if suit.Button("Save", suit.layout:row()).hit then
		if require(path).save then -- HACK: To avoid a circular dependency error
			require(path).save()
		end
	end
	if suit.Button("Quit", suit.layout:row()).hit then
		love.event.quit()
	end
end

return plainPause
