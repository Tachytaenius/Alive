# The Tilemap

**Not all of this is implemented yet.**
**Subject to change, too.**

## Gameplay Details

The tilemap layer sits over a layer of bedrock.
Which should be able to have holes in it (that may fill up with water!).

Tiles consist of:
- A topping layer, which can have things like soil, liquid, or be empty.
- A super topping layer, which can be either a series of flat layers (or just one) or a wall, or be empty.

Configurations of tiles and entities that should be able to exist:
- Covered booby trap (super topping) hole into spiked (entities) ditch (no topping) (ouch!).
- Metal grating (super topping) over water underneath (topping).
- Stone foundation (topping) with planks and carpet (super topping(s)).
- Basic soil (topping) with grass (super topping).
- Stone foundation (topping) with a wall (super topping).

## Technical Details

Mostly to-decide-upon.

- The tilemap indices start at 0 and ends at (width or height) - 1.

Tile fields:
- `topping`: The topping's table, or `nil` for no topping.
- `topping.type` determines the topping's type.
	- `"solid"`: A mix of various solid (and possibly absorbed liquid) constituents.
	- `"liquid"`: Purely liquid, flows to other nil topping or liquid topping tiles.
- `topping.constituents`: A table mapping materials to their amounts to define what the layer is made of.
	Should add up to a constant value, being below that should count as being loose/spongy.
- `tile.superTopping.type` can be either `"layers"` or `"wall"`.
- `tile.superTopping.layers`, for layers-type super toppings, is an array of super topping layers.
	Fields for entries:
	- `type`: One of:
		- `grass`: For living matter coating the topping.
		- `planks`: Solid, for a plank texture.
		- `carpet`: Solid, but requires solid topping or super topping.
		- `grate`: Solid, for a grate texture.
	- `constituents`: A table mapping materials to their amounts to define what the layer is made of.
		Should only be one material for things like planks and carpet.
		Grates can be made of metal which can be an alloy, though.
	- `health`: For grass, defines how healthy the grass is.
		Would be based on water amount in soil beneath.
		For ordinary grass grass, low values should make it yellower and patchier.
