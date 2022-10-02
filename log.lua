local consts = require("consts")

local log = {}

function log.out(message)
	local success, errorMessage = love.filesystem.append(consts.outputLogFileName, "[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] " .. message .. "\n")
	if not success then
		error("Could not append to log file: " .. errorMessage)
	end
end

return log
