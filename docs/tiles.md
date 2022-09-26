# The Tilemap

**Not all of this is implemented yet.**
**Subject to change, too.**
**This document is becoming a mess, please rewrite it according to the actual codebase once the features are all fully implemented.**

## Gameplay Details and Goals

The tilemap layer sits over a layer of bedrock.
Which should be able to have holes in it (that may fill up with water!).

Tiles consist of:
- A topping layer, which can have things like soil, liquid, or be empty.
- A super topping layer, which can be either a series of flat sub-layers (or just one) (with a maximum nubmer of allowed sub-layers) or a wall, or be empty.

Configurations of tiles and entities that should be able to exist:
- Covered booby trap (super topping) hole into spiked (entities) ditch (no topping) (ouch!).
- Metal grating (super topping) over water underneath (topping).
- Stone foundation (topping) with planks and carpet (super topping(s)).
- Basic soil (topping) with grass (super topping).
- Stone foundation (topping) with a wall (super topping).

Configurations of tiles that would not be able to exist:
- A grate on top of bedrock.
- Flowing liquid in the super toppign layer.

When mining tiles, lumps of the part that you are mining will be taken off the tile and added to the game world, probably randomly selected.
Each lump would be its own inventory item.
A lump would be little more than a consituents table that maps material definitions to their counts, adding up to a constant size.
All constituent counts are integers!
When building, a lump is taken from the builder's inventory and added to the tile.
We want to avoid any sort of numeric drift with tile constituent ratios when mining and building, hence things being divided up into lumps.
Lumps of different constituents can be mixed inside toppings and super topping walls.
For multiple-lump layers, add up all the constituent counts in all the lumps and work on those values for things like drawing.

If you have soil that has all-loam lumps and all-clay lumps, it would be non-homogenous soil.
If you have soil with lumps that all contain a distribution of loam and clay, it would be homogenous soil.

## Fields and Technical Details

Mostly to-decide-upon.

- Tiles are always ticked before their values are used (except by rendering).
	Combining that with the fact that ticking essentially catches up on the ticks the tile was not ticked in, tiles essentially *are* the way they would be were every tile ticked every tick, but this only manifests in memory before their values are used.
	Except rendering sees the tiles as they are in memory.
- TODO: Should tiles be ticked before or after building on them, or both?
- The tilemap indices start at 0 and ends at (width or height) - 1.
- Lump constituents must only have one entry per material.
- Grass lumps may only have one material entry.
- Lumps may not be modified without creating a new constituents table in case the table is used by another lump.
	Lumps probably won't be able to be modified anyway, only broken down and produced.

Lump fields:
- `constituents`: An array of entries with the following fields:
	- `material`: The material registry entry for this constituents entry.
	- `amount`: How much of the material is in the lump.
- `grassHealth`: Health of grass that was dug up. Should decrease over time.
- `grassAmount`: Amount of grass that was dug up.

Tile fields:
- `topping`: The topping layer's table, or `nil` for no topping.
- `topping.type` determines the topping's type.
	- `"solid"`: A mix of various solid (and possibly absorbed liquid) constituents in lumps.
	- `"liquid"`: Purely liquid, flows to other nil topping or liquid topping tiles.
- `topping.lumps`: For solids, an array of lumps (which are maps of constituents to constituent counts that adds up to a total value).
	Length should add up to a constant value at first, being below that should count as being cracked and mined.
	When the total descends below a threshold, it should break into its constituent parts.
- `superTopping`: The super topping layer's table, or `nil` for no super topping.
- `superTopping.type` can be either `"layers"` or `"wall"`.
- `superTopping.subLayers`, for layers-type super toppings, an array of super topping sub-layers.
	Fields for entries:
	- `type`: One of:
		- `grass`: For living matter coating the topping.
		- `planks`: Solid, for a plank texture.
		- `carpet`: Solid, but requires solid topping or super topping.
		- `grate`: Solid, for a grate texture.
	- `lump`: A single lump that defines the materials of the sub-layer.
	- `grassHealth`: For grass, defines how healthy the grass is.
		Goes from 0 to 1.
		Would be based on water amount in soil beneath.
		For ordinary grass grass, low values should make it yellower and patchier.
	- `grassAmount`: For grass, defines how much grass there is.
		Goes from 0 to 1.
	- `grassTargetHealth`: Cached value that is recalculated only when a tile is changed.
- `lastTickTimer`: The super world's `tickTimer` value last time this tile was ticked.
	Used with current `tickTimer` to get how much effective delta time to use.
