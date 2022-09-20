local utilities = {}

function utilities.blankImage(r, g, b, a, w, h)
	local w = w or 1
	local h = w or h
	local ret = love.image.newImageData(w, h)
	ret:mapPixel(function()
		return r, g, b, a
	end)
	return love.graphics.newImage(ret)
end

local constructors = {}

local assets = {}

local function traverse(start)
	for _, v in pairs(start) do
		if v.load then
			v:load()
		else
			traverse(v)
		end
	end
end

return setmetatable(assets, {
	__call = function(assets, action, ...)
		if action == "load" then
			traverse(assets)
		elseif action == "save" then
			-- TODO (make sure we can specify particular assets)
		elseif action == "configure" then
			for k, _ in pairs(assets) do
				k = nil
			end
			for k, v in pairs(select(1, ...)) do
				assets[k] = v
			end
		elseif action == "meta" then
			return constructors, utilities
		else
			error("Assets is to be called with \"load\", \"save\", \"configure\", or \"meta\"")
		end
	end
})
