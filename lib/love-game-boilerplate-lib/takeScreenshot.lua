local path = (...):gsub("%.[^%.]+$", "")

local log = require(path .. ".log")

return function(canvas, canvasName)
	local info = love.filesystem.getInfo("screenshots")
	if not info then
		log.info("Couldn't find screenshots folder. Creating")
		love.filesystem.createDirectory("screenshots")
	elseif info.type ~= "directory" then
		log.error("There is already a non-folder item called screenshots. Rename it or move it to take a screenshot") -- TODO: UX(?)
		return
	end
	
	local dateTime = os.date("%Y-%m-%d %H-%M-%S") -- Can't use colons!
	
	local currentIdentifier = 1
	local currentPath
	local function generatePath()
		currentPath =
			"screenshots/" ..
			dateTime .. " " ..
			(canvasName and canvasName .. " " or "") ..
			currentIdentifier ..
			".png"
	end
	generatePath()
	while love.filesystem.getInfo(currentPath) do
		currentIdentifier = currentIdentifier + 1
		generatePath()
	end
	
	canvas:newImageData():encode("png", currentPath)
end
