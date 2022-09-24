local path = (...):gsub("%.[^%.]+$", ""):gsub("%.uis$", "")

local suit = require(path .. ".lib.suit")
local assets = require(path .. ".assets")
local config = require(path .. ".config")
local ui = require(path .. ".ui")
local settings = require(path .. ".settings")

local types, typeInstanceOrigins, template, uiLayout = settings("meta")

local settingsUI = {}

function settingsUI.construct(state)
	state.causesPause = true
	state.scrollOffset = 0
	state.changes = {}
end

local function get(state, ...)
	local current = state.changes
	for i = 1, select("#", ...) do
		local key = select(i, ...)
		if current[key] ~= nil then
			current = current[key]
		else
			-- Get from original settings
			local current = settings
			for i = 1, select("#", ...) do
				current = current[select(i, ...)]
			end
			return current
		end
	end
	return current
end

local function set(state, to, ...)
	local current = state.changes
	local len = select("#", ...)
	for i = 1, len - 1 do
		local key = select(i, ...)
		current[key] = current[key] or {}
		current = current[key]
	end
	
	current[select(len, ...)] = to
end

local function applyChanges(changes)
	local function traverse(currentChanges, currentSettings, currentTemplate)
		for k, v in pairs(currentChanges) do
			if type(currentTemplate[k]) == "table" then
				 -- Another category to traverse
				traverse(v, currentSettings[k], currentTemplate[k])
			else--if type(currentTemplate[k]) == "function"
				-- A setting to change
				currentSettings[k] = v
			end
		end
	end
	traverse(changes, settings, template)
end

function settingsUI.update(state)
	local x, y = config.canvasSystemWidth / 4, config.uiPad
	local w, h = config.canvasSystemWidth / 2, assets.ui.font.value:getHeight() + config.uiButtonPad
	state.scrollOffset = math.min(0, state.scrollOffset + state.scrollAmountY * config.scrollSpeed)
	y = y + state.scrollOffset
	suit.layout:reset(x, y, config.uiPad)
	
	local rectangles = {}
	local function finishRect()
		if #rectangles ~= 0 then
			rectangles[#rectangles][3] = w + config.uiPad * 2 - 1
			rectangles[#rectangles][4] = (suit.layout._y + config.uiPad) - rectangles[#rectangles][2] + h + config.uiPad - 1
		end
	end
	
	if suit.Button("Cancel", suit.layout:row(w/2-config.uiPad/2, h)).hit then
		return true, "plainPause"
	end
	if suit.Button("OK", suit.layout:col()).hit then
		applyChanges(state.changes)
		settings("apply", suppressRemakeWindow) -- TODO: Define the variable
		settings("save")
		return true, "plainPause"
	end
	suit.layout:reset(x, y + h + config.uiPad, config.uiPad)
	if suit.Button("Reset", suit.layout:row(w/2-config.uiPad/2, h)).hit then
		state.changes = {}
		settings("reset")
		settings("apply")
		settings("save")
	end
	if suit.Button("Apply", suit.layout:col()).hit then
		applyChanges(state.changes)
		settings("apply")
		settings("save")
		state.changes = {}
	end
	
	suit.layout:reset(x, y + h + config.uiPad * 2, config.uiPad)
	
	local id = 1
	
	for _, category in ipairs(uiLayout) do
		finishRect()
		suit.layout:row(w, h)
		suit.Label(category.title .. ":", {align = "left"}, suit.layout:row(w, h))
		rectangles[#rectangles + 1] = {suit.layout._x - config.uiPad + 0.5, suit.layout._y - config.uiPad + 0.5}
		for i, item in ipairs(category) do
			local settingName = item.name
			local settingState = get(state, unpack(item))
			
			local current = template
			for _, key in ipairs(item) do
				current = current[key]
			end
			assert(type(current) == "function", "Settings UI layout references nonexistent setting")
			local settingType = typeInstanceOrigins[current]
			local x,y,w,h=suit.layout:row(w, h)
			if settingType == types.boolean then
				if suit.Checkbox({checked = settingState, text = item.name}, {id = id}, x,y,w,h).hit then
					set(state, not settingState, unpack(item))
				end
				id = id + 1
			elseif settingType == types.natural then
				suit.Label(item.name .. ": (" .. settingState .. "/" .. item.getLimit() .. ")", {align = "left"}, x,y,w,h)
				x,y,w,h=suit.layout:row(w, h)
				local sliderSettings = {value = settingState, min = 1, max = item.getLimit(), step = 1}
				-- if --[=[suit.Slider call]=].changed then
				-- The above line is not used because settings.graphics.scale's limit changes depending on the current display, which can be changed by moving the window while in the settings menu which does not refresh
				suit.Slider(sliderSettings, {id = id}, x,y,w,h)
				set(state, math.min(item.getLimit(), math.floor(sliderSettings.value + 0.5)), unpack(item))
				id = id + 1
			elseif settingType == types.rgb then
				-- TODO
			elseif settingType == types.rgba then
				-- TODO
			elseif settingType == types.number then
				suit.Label(
					item.name .. ": (" ..
					string.format("%.2f", item.getLowLimit()) .. ", " ..
					string.format("%.2f", settingState) .. ", " ..
					string.format("%.2f", item.getLimit()) .. ")",
					{align = "left"}, x,y,w,h
				)
				x,y,w,h=suit.layout:row(w, h)
				local sliderSettings = {value = settingState, min = item.getLowLimit(), max = item.getLimit()}
				suit.Slider(sliderSettings, {id = id}, x,y,w,h)
				set(state, math.max(item.getLowLimit(), math.min(item.getLimit(), sliderSettings.value)), unpack(item))
				id = id + 1
			elseif settingType == types.commands then
				-- TODO
			end
		end
	end
	
	finishRect()
	
	function state.draw()
		for _, rectangle in ipairs(rectangles) do
			-- NOTE: We can bring these back if we do theming
			-- love.graphics.rectangle("line", unpack(rectangle))
		end
	end
end

return settingsUI
