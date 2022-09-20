-- TODO: Organise into canvasName folders

return function(canvas)
	local info = love.filesystem.getInfo("screenshots")
	if not info then
		print("Couldn't find screenshots folder. Creating")
		love.filesystem.createDirectory("screenshots")
	elseif info.type ~= "directory" then
		print("There is already a non-folder item called screenshots. Rename it or move it to take a screenshot") -- TODO: UX(?)
		return
	end
	
	local current = 0
	for _, filename in pairs(love.filesystem.getDirectoryItems("screenshots")) do
		if string.match(filename, "^%d+%.png$") then -- Make sure this file could have been created by this function
			current = math.max(current, tonumber(string.sub(filename, 1, -5)))
		end
	end
	
	canvas:newImageData():encode("png", "screenshots/" .. current + 1 .. ".png")
end
