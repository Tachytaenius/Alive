local concord = require("lib.concord")

local map = concord.system({})

function map:newWorld(width, height)
	self.width, self.height = width, height
	local tiles = {}
	self.tiles = tiles
	for x = 0, width - 1 do
		local column = {}
		tiles[x] = column
		for y = 0, height - 1 do
			local tile = {}
			column[y] = tile
			tile.topping = nil
			tile.superTopping = nil
		end
	end
end

return map
