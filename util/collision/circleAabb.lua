local abs = math.abs

local function circleAabbCollision(circleX, circleY, circleRadius, aabbX, aabbY, aabbWidth, aabbHeight)
	local circleDistanceX = abs(circleX - aabbX - aabbWidth / 2)
	local circleDistanceY = abs(circleY - aabbY - aabbHeight / 2)
	
	if circleDistanceX > aabbWidth / 2 + circleRadius then
		return false
	end
	if circleDistanceY > aabbHeight / 2 + circleRadius then
		return false
	end
	
	if circleDistanceX <= aabbWidth / 2 then
		return true
	end
	if circleDistanceY <= aabbHeight / 2 then
		return true
	end
	
	local a = circleDistanceX - aabbWidth / 2
	local b = circleDistanceY - aabbHeight / 2
	-- x raised to an integer is not necessarily deterministic, according to mathsies lib version 5
	local cornerDistanceSquared = a * a + b * b
	
	return cornerDistanceSquared <= circleRadius * circleRadius
end

return circleAabbCollision
