local path = (...):gsub("%.[^%.]+$", "")

local config = require(path .. ".config")
local settings = require(path .. ".settings")

local input = {}

local previousFrameRawCommands, thisFrameRawCommands, fixedCommandsList

local function didCommandBase(name, commandsTable, settingsTable)
	assert(commandsTable[name], name .. " is not a valid command")
	
	local assignee = settingsTable[name]
	local down
	if type(assignee) == "string" then
		local func = settings.useScancodes and love.keyboard.isScancodeDown or love.keyboard.isDown
		down = func(assignee)
	elseif type(assignee) == "number" then
		if love.mouse.getRelativeMode() then
			if assignee ~= require(path).disableMouseButtonUntilReleased then -- HACK to avoid a circular dependency
				down = love.mouse.isDown(assignee)
			end
		end
	end
	down = not not down
	thisFrameRawCommands[name] = down
	
	local deltaPolicy = commandsTable[name]
	if deltaPolicy == "onPress" then
		return thisFrameRawCommands[name] and not previousFrameRawCommands[name]
	elseif deltaPolicy == "onRelease" then
		return not thisFrameRawCommands[name] and previousFrameRawCommands[name]
	elseif deltaPolicy == "whileDown" then
		return thisFrameRawCommands[name]
	else
		error(deltaPolicy .. " is not a valid delta policy")
	end
end

function input.didFrameCommand(name)
	return didCommandBase(name, config.frameCommands, settings.frameCommands)
end

function input.didFixedCommand(name)
	return fixedCommandsList[name]
end

function input.stepRawCommands(paused)
	if not paused then
		for name, deltaPolicy in pairs(config.fixedCommands) do
			local didCommandThisFrame = didCommandBase(name, config.fixedCommands, settings.fixedCommands)
			fixedCommandsList[name] = fixedCommandsList[name] or didCommandThisFrame
		end
	end
	
	previousFrameRawCommands, thisFrameRawCommands = thisFrameRawCommands, {}
end

function input.clearRawCommands()
	previousFrameRawCommands, thisFrameRawCommands = {}, {}
end

function input.clearFixedCommandsList()
	fixedCommandsList = {}
end

return input
