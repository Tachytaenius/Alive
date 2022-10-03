-- WARNING: Used by threads, don't expect changes to propagate through (not that any of these values are supposed to be changed)

local consts = {}

-- Load constants
for _, suffix in ipairs({
	"core", "misc", "threads", "graphics", "mouse", "map"
}) do
	for k, v in pairs(require("consts." .. suffix)) do
		assert(not consts[k], "Duplicate constant \"" .. k .. "\"")
		consts[k] = v
	end
end

-- Set constants that depend on constants from other modules
-- Would be map:
consts.randomTickInterval = consts.fixedUpdateTickLength / 4

-- Do asserts
assert(consts.randomTickInterval > 0, "Random tick interval cannot be 0")

return consts
