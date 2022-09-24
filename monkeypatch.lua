do
	math.tau = math.pi * 2
	function math.sign(x)
		return
		  x > 0 and 1 or
		  x == 0 and 0 or
		  x < 0 and -1
	end
	function math.round(x)
		return math.floor(x + 0.5)
	end
	function math.lerp(a, b, i)
		return a + (b - a) * i
	end
	local function shortAngleDist(a, b)
		local d = (b - a) % math.tau
		return 2 * d % math.tau - d
	end
	function math.angleLerp(a, b, i)
		return a + shortAngleDist(a, b) * i
	end
end

-- do
-- 	function love.graphics.multiplyColor(r, g, b)
-- 		if type(r) == "table" then
-- 			r, g, b = r[1], r[2], r[3]
-- 		end
-- 		local curR, curG, curB = love.graphics.getColor()
-- 		love.graphics.setColor(r * curR, g * curG, b * curB)
-- 	end
-- 
-- 	local ffi_copy = require("ffi").copy
-- 	local buffer = love.data.newByteData(64) -- 4*4 floats
-- 	local address = buffer:getFFIPointer()
-- 
-- 	function love.graphics.sendVec3(shader, uniform, vector)
-- 		ffi_copy(address, vector, 12)
-- 		shader:send(uniform, buffer)
-- 	end
-- 
-- 	function love.graphics.sendVec4(shader, uniform, vector)
-- 		ffi_copy(address, vector, 16)
-- 		shader:send(uniform, buffer)
-- 	end
-- 
-- 	function love.graphics.sendMat4(shader, uniform, matrix)
-- 		ffi_copy(address, matrix, 64)
-- 		shader:send(uniform, buffer)
-- 	end
-- end

do
	local list = require("lib.list")
	function list:elements() -- Convenient iterator
		local i = 1
		return function()
			local v = self:get(i)
			i = i + 1
			if v ~= nil then
				return v
			end
		end, self, 0
	end
	function list:find(obj) -- Same as List:has but without "and true"
		return self.pointers[obj]
	end
end

do
	-- Augment worlds by allowing world.systemName behaviour, relying on this project's string -> system class table.
	local systems = require("systems")
	local concord = require("lib.concord")
	local oldWorldNew = concord.world.new
	local newWorldMetatable = {
		__index = function(self, k)
			local v = rawget(self, k)
			if v then return v end
			local v = rawget(concord.world, k)
			if v then return v end
			-- Here is where it is (functionally) different from concord.world.__mt:
			return self:getSystem(systems[k])
		end
	}
	function concord.world.new()
		return setmetatable(oldWorldNew(), newWorldMetatable)
	end
end
