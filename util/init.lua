local function traverse(utilTable, path)
	for _, itemName in ipairs(love.filesystem.getDirectoryItems(path)) do
		local path = path .. itemName
		if path ~= "util/init.lua" then
			if love.filesystem.getInfo(path, "directory") then
				utilTable[itemName] = {}
				traverse(utilTable[itemName], path .. "/")
			elseif love.filesystem.getInfo(path, "file") then
				if itemName:match("%.lua$") then
					utilTable[itemName:gsub("%.lua$", "")] = require(path:gsub("%.lua", ""):gsub("/", "."))
				end
			end
		end
	end
end

local util = {}

traverse(util, "util/")

return util
