# The Tilemap

**Not all of this is implemented yet.**
**Subject to change, too.**
**This document is becoming a mess, please rewrite it according to the actual codebase once the features are all fully implemented.**

## Gameplay Details and Goals

The tilemap layer sits over a layer of bedrock.
Which should be able to have holes in it (that may fill up with water!).

Tiles consist of:
- A topping layer, which can have things like soil, liquid, or be empty.
- A super topping layer, which can be either a series of flat sub-layers (or just one) or a wall, or be empty.

Configurations of tiles and entities that should be able to exist:
- Covered booby trap (super topping) hole into spiked (entities) ditch (no topping) (ouch!).
- Metal grating (super topping) over water underneath (topping).
- Stone foundation (topping) with planks and carpet (super topping(s)).
- Basic soil (topping) with grass (super topping).
- Stone foundation (topping) with a wall (super topping).

When mining tiles, chunks of the part that you are mining will be taken off the tile and added to the game world, probably randomly selected.
Each chunk would be its own inventory item.
A chunk would be little more than a consituents table that maps material definitions to their counts, adding up to a constant size.
All constituent counts are integers!
When building, a chunk is taken from the builder's inventory and added to the tile.
We want to avoid any sort of numeric drift with tile constituent ratios when mining and building, hence things being divided up into chunks.
Chunks of different constituents can be mixed inside toppings and super topping walls.
For multiple-chunk layers, add up all the constituent counts in all the chunks and work on those values for things like drawing.

If you have soil that has all-loam chunks and all-clay chunks, it would be non-homogenous soil.
If you have soil with chunks that all contain a distribution of loam and clay, it would be homogenous soil.

## Fields and Technical Details

Mostly to-decide-upon.

- The tilemap indices start at 0 and ends at (width or height) - 1.

Tile fields:
- `topping`: The topping layer's table, or `nil` for no topping.
- `topping.type` determines the topping's type.
	- `"solid"`: A mix of various solid (and possibly absorbed liquid) constituents in chunks.
	- `"liquid"`: Purely liquid, flows to other nil topping or liquid topping tiles.
- `topping.chunks`: For solids, an array of chunks (which are maps of constituents to constituent counts that adds up to a total value).
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
	- `chunk`: A single chunk that defines the materials of the sub-layer.
	- `health`: For grass, defines how healthy the grass is.
		Would be based on water amount in soil beneath.
		For ordinary grass grass, low values should make it yellower and patchier.
