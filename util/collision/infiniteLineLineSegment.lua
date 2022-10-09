local vec2 = require("lib.mathsies").vec2

return function(line1StartX, line1StartY, line1EndX, line1EndY, line2StartX, line2StartY, line2EndX, line2EndY)
	-- TEMP: Just put them into vectors to make calculation easier
	local line1Start = vec2(line1StartX, line1StartY)
	local line1End = vec2(line1EndX, line1EndY)
	local line2Start = vec2(line2StartX, line2StartY)
	local line2End = vec2(line2EndX, line2EndY)
	
	local direction = vec2.normalise(line1End - line1Start)
	direction.x, direction.y = -direction.y, direction.x
	local dotA = vec2.dot(direction, line2Start - line1Start)
	local dotB = vec2.dot(direction, line2End - line1Start)
	
	return math.sign(dotA) ~= math.sign(dotB)
end
