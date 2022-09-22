# The Tilemap

**Not all of this is implemented yet.**
**Subject to change, too.**

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

When mining tiles, chunks of the part that you are mining will appear.
They will hold the tile's constituents, which can then be added to your inventory in a stack.
Each chunk would be its own inventory item.
A chunk would be little more than a consituents table that simply contains all the (**all constituent counts are integers!**) constituents taken from the tile it was taken from.
When building, constituents are taken from the last chunks in the builder's inventory (FIFO).
A chunk should have a constant size and the maximum total constituents of a tile should be a multiple of it.
We want to avoid numeric drift with tile constituent ratios when mining and building.

## Fields and Technical Details

Mostly to-decide-upon.

- The tilemap indices start at 0 and ends at (width or height) - 1.

Tile fields:
- `topping`: The topping's table, or `nil` for no topping.
- `topping.type` determines the topping's type.
	- `"solid"`: A mix of various solid (and possibly absorbed liquid) constituents.
	- `"liquid"`: Purely liquid, flows to other nil topping or liquid topping tiles.
- `topping.constituents`: A table mapping materials to their amounts to define what the layer is made of.
	Should add up to a constant value at first, being below that should count as being cracked and mined.
	When the total descends below a threshold, it should break into its constituent parts.
- `tile.superTopping.type` can be either `"layers"` or `"wall"`.
- `tile.superTopping.subLayers`, for layers-type super toppings, is an array of super topping sub-layers.
	Fields for entries:
	- `type`: One of:
		- `grass`: For living matter coating the topping.
		- `planks`: Solid, for a plank texture.
		- `carpet`: Solid, but requires solid topping or super topping.
		- `grate`: Solid, for a grate texture.
	- `constituents`: A table mapping materials to their amounts to define what the sub-layer is made of.
		Should only be one material for things like planks and carpet.
	- `health`: For grass, defines how healthy the grass is.
		Would be based on water amount in soil beneath.
		For ordinary grass grass, low values should make it yellower and patchier.
		The same things for `topping.constituents` apply.
