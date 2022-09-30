local ffi = require("ffi")

local consts = require("consts")

ffi.typedef([[
	typedef
]])


ffi.typedef([[
	typedef struct {
		int64 localX, localY;
		int64 globalX, globalY;
		
	} Tile;
]])
