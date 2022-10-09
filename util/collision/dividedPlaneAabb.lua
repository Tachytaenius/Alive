local infiniteLineAabb = require("util.collision.infiniteLineAabb")
local dividedPlanePoint = require("util.collision.dividedPlanePoint")

return function(lineStartX, lineStartY, lineEndX, lineEndY, aabbX, aabbY, aabbWidth, aabbHeight)
	if infiniteLineAabb(lineStartX, lineStartY, lineEndX, lineEndY, aabbX, aabbY, aabbWidth, aabbHeight) then
		return true
	end
	-- The dividing line doesn't pass through the AABB, so it is fully on one side of the plane, so check for any of its points
	return dividedPlanePoint(lineStartX, lineStartY, lineEndX, lineEndY, aabbX, aabbY)
end
