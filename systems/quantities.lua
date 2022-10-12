local concord = require("lib.concord")

local quantities = concord.system({
	-- Pools that use lerp
	position = {"position"},
	angle = {"angle"}
})

function quantities:fixedUpdate(dt)
	-- Iterate over all entities with component X and set its "previous value" to the current one
	for _, pool in ipairs(self.__pools) do
		local component = pool.__name
		for _, e in ipairs(pool) do
			local bag = e:get(component)
			bag.previousValue = bag.value
		end
	end
end

function quantities:draw(lerp, dt, performance)
	local function lerpPool(pool)
		local component = pool.__name
		for _, e in ipairs(pool) do
			local bag = e:get(component)
			bag.interpolated = math.lerp(bag.previousValue or bag.value, bag.value, lerp)
		end
	end

	local function angleLerpPool(pool)
		local component = pool.__name
		for _, e in ipairs(pool) do
			local bag = e:get(component)
			bag.interpolated = math.angleLerp(bag.previousValue or bag.value, bag.value, lerp)
		end
	end

	lerpPool(self.position)
	angleLerpPool(self.angle)
end

return quantities
