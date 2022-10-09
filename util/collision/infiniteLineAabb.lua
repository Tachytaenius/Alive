local infiniteLineLineSegment = require("util.collision.infiniteLineLineSegment")

return function(lineStartX, lineStartY, lineEndX, lineEndY, aabbX, aabbY, aabbWidth, aabbHeight)
	return
		infiniteLineLineSegment(lineStartX, lineStartY, lineEndX, lineEndY, aabbX, aabbY, aabbX + aabbWidth, aabbY) or
		infiniteLineLineSegment(lineStartX, lineStartY, lineEndX, lineEndY, aabbX, aabbY, aabbX, aabbY + aabbHeight) or
		infiniteLineLineSegment(lineStartX, lineStartY, lineEndX, lineEndY, aabbX, aabbY + aabbHeight, aabbX + aabbWidth, aabbY + aabbHeight) or
		infiniteLineLineSegment(lineStartX, lineStartY, lineEndX, lineEndY, aabbX + aabbWidth, aabbY, aabbX + aabbWidth, aabbY + aabbHeight)
end
