local concord = require("lib.concord")

local quantities = concord.system({
	-- Pools that use lerp
	position = {"position"}
})

function quantities:fixedUpdate(dt)
	-- Iterate over all entities with component X and set its "previous value" to the current one
	for _, pool in ipairs(self.__pools) do
		local component = pool.__name
		for _, e in ipairs(pool) do
			local bag = e:get(component)
			bag.pval = bag.val
		end
	end
end

function quantities:draw(lerp, dt, performance)
	local function lerpPool(pool)
		local component = pool.__name
		for _, e in ipairs(pool) do
			local bag = e:get(component)
			bag.ival = math.lerp(bag.pval, bag.val, lerp)
		end
	end
	
	lerpPool(self.position)
end

return quantities
