local concord = require("lib.concord")

local map = concord.system({
	players = {"player", "position"}
})

for _, suffix in ipairs({
	"core", "chunks", "tiles", "rendering"
}) do
	for k, v in pairs(require("systems.map." .. suffix)) do
		map[k] = v
	end
end

return map
