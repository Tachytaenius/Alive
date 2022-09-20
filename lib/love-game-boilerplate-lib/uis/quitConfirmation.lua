local path = (...):gsub("%.[^%.]+$", ""):gsub("%.uis$", "")

local suit = require(path .. ".lib.suit")
local assets = require(path .. ".assets")
local config = require(path .. ".config")

local quitConfirmation = {}

function quitConfirmation.construct(state)
	state.causesPause = true
end

function quitConfirmation.update(state)
	suit.layout:reset(config.canvasSystemWidth / 3, config.canvasSystemHeight / 3, config.uiPad)
	if suit.Button("Save and quit", suit.layout:row(config.canvasSystemWidth / 3, assets.ui.font.value:getHeight() + config.uiButtonPad)).hit then
		if require(path).save then -- HACK to avoid a circular dependency error
			require(path).save()
		end
		love.event.quit()
	end
	if suit.Button("Quit without saving", suit.layout:row()).hit then
		require(path).forceQuit = true -- Fix bug where this button wouldn't work when config.suppressQuitWithDoubleQuitEvent was true
		love.event.quit()
	end
	if suit.Button("Don't quit", suit.layout:row()).hit then
		return true
	end
end

return quitConfirmation
