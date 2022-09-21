local path = (...):gsub("%.[^%.]+$", "")

local config = require(path .. ".config")
local settings = require(path .. ".settings")

local input = {}

local function checkCommand(command, updateType)
	assert(updateType == "fixed" or updateType == "frame", "Commands are either for fixed or frame updates")
	
	local list = input[updateType .. "Updates"]
	local this = list[#list]
	local last = list[#list - 1]
	
	assert(config[updateType .. "Commands"][command], "A command has to be registered if you want to check for it")
	
	-- Don't do it multiple times
	local current = this[command]
	if current ~= nil then return current end
	
	-- Get the input from the OS. Mouse or keyboard
	local assignee = settings[updateType .. "Commands"][command]
	if (type(assignee) == "string" and love.keyboard.isScancodeDown(assignee)) or (type(assignee) == "number" and love.mouse.isGrabbed() and love.mouse.isDown(assignee)) then
		this[command] = true
	end
	
	-- Check it against the previous frame if need be
	local ret
	local deltaPolicy = config[updateType .. "Commands"][command]
	if deltaPolicy == "onPress" then
		return this[command] and not last[command]
	elseif deltaPolicy == "onRelease" then
		return not this[command] and last[command]
	elseif deltaPolicy == "whileDown" then
		return this[command]
	else
		error("Command delta policies must be either \"onPress\", \"onRelease\" or \"whileDown\"")
	end
end

function input.stepFixedUpdate()
	assert(not input.replaying, "input.stepFixedUpdate is called every fixed update when you are making new footage or playing unrecorded")
	
	if not input.recording then
		table.remove(input.fixedUpdates, 1)
	end
	table.insert(input.fixedUpdates, {})
end

function input.checkFixedUpdateCommand(command)
	return checkCommand(command, "fixed")
end

function input.doFixedUpdateCommand(command)
	input.fixedUpdates[#input.fixedUpdates][command] = true
end

local function getRecordString(tick)
	local ret = ""
	for command in pairs(tick) do
		if command then
			ret = ret .. command .. ","
		end
	end
	return ret .. "\n"
end

function input.flushFixedUpdateRecording()
	assert(input.recording, "input.flushRecording is called when recording, generally every frame update")
	
	local append = ""
	
	while #input.fixedUpdates > 2 do
		-- accumulate the tick's inputs (TODO, dont know format)
		local tick = table.remove(input.fixedUpdates, 1)
		if not tick.recorded then
			append = append .. getRecordString(tick)
		end
	end
	append = append .. getRecordString(input.fixedUpdates[1]) .. getRecordString(input.fixedUpdates[2])
	
	-- write it to demo file
end

function input.stepFrameUpdate()
	table.remove(input.frameUpdates, 1)
	table.insert(input.frameUpdates, {})
end

function input.checkFrameUpdateCommand(command)
	return checkCommand(command, "frame")
end

function input.doFrameUpdateCommand(command, value)
	input.frameUpdates[#input.frameUpdates][command] = true
end

return input
