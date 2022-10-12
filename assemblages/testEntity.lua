return function(e, posX, posY, angle)
	e
		:give("position", posX, posY)
		:give("velocity")
		:give("sprite", 10)
		:give("will")
		:give("grounded")
		:give("gait", 100, 800, 10, 10)
		:give("flyingRecoveryRate", 100)
		:give("angle", angle)
		:give("angularVelocity")
		:give("angularGait", math.tau * 2, math.tau * 32)
		:give("vision", 1024)
end
