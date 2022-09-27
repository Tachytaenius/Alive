# The Tilemap

**Not all of this is implemented yet.**
**Subject to change, too.**
**This document is becoming a mess, please rewrite it according to the actual codebase once the features are all fully implemented.**

TODO: Roofs.

## Gameplay Details and Goals

The tilemap layer sits over a layer of bedrock.
Which should be able to have holes in it (that may fill up with water!).

Tiles consist of:
- A topping layer, which can have things like soil, liquid, or be empty.
- A super topping layer, which can be either a series of flat sub-layers (or just one) (with a maximum number of allowed sub-layers) or a wall, or be empty.

Configurations of tiles and entities that should be able to exist:
- Covered booby trap (super topping) hole into spiked (entities) ditch (no topping) (ouch!).
- Metal grating (super topping) over water underneath (topping).
- Stone foundation (topping) with planks and carpet (super topping(s)).
- Basic soil (topping) with grass (super topping).
- Stone foundation (topping) with a wall (super topping).

Configurations of tiles that would not be able to exist:
- A grate on top of bedrock.
- Flowing liquid in the super topping layer.

When mining tiles, lumps of the part that you are mining will be taken off the tile and added to the game world, probably randomly selected.
Each lump would be its own inventory item.
A lump would be little more than a constituents table that maps material definitions to their counts, adding up to a constant size.
All constituent counts are integers!
When building, a lump is taken from the builder's inventory and added to the tile.
Grass lumps cannot be used to build toppings and walls.
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
	In cases where the player needs to know what the state of a tile is before acting on it, the tile could indeed be ticked every tick.
	Perhaps tiles closest to the player should be ticked every tick.
	(TEMP, if this is implemented, please replace the sentence before.)
- TODO: Should tiles be ticked before or after building on them, or both?
- The tilemap indices start at 0 and ends at (width or height) - 1.
- Lump constituents must only have one entry per material.
- Grass lumps may only have one material entry.
- Grass lumps may not be used to add to toppings.
- Lumps may not be modified without creating a new constituents table in case the table is used by another lump.
	Lumps probably won't be able to be modified anyway, only broken down and produced.

Lump fields:
- `constituents`: (Saved, altered) An array of entries with the following fields:
	- `material`: (Saved, altered) The material registry entry for this constituents entry.
	- `amount`: (Saved) How much of the material is in the lump.
- `grassHealth`: (Saved) Health of grass.
	Should decrease over time if in a dug-up lump.
	Goes from 0 to 1.
	Would be based on water amount in soil beneath.
	For ordinary grass grass, low values should make it yellower and have a lesser amount.
- `grassAmount`: (Saved) Amount of grass.
	Should decrease over time according to grass rules if in a dug-up lump.
	Goes from 0 to 1.
	Smaller amounts make it patchier.

Tile fields:
- `chunk`: (Not saved) Link to the containing chunk.
- `localTileX`: (Not saved) Chunk-local x position of tile in tiles, not pixels.
- `localTileY`: (Not saved) Chunk-local y position of tile in tiles.
- `globalTileX`: (Not saved) Global x position of tile in tiles.
- `globalTileY`: (Not saved) Global y position of tile in tiles.
- `topping`: (Saved, altered) The topping layer's table, or `nil` for no topping.
- `topping.type`: (Saved) Determines the topping's type.
	- `"solid"`: A mix of various solid (and possibly absorbed liquid) constituents in lumps.
	- `"liquid"`: Purely liquid, flows to other nil topping or liquid topping tiles.
- `topping.lumps`: (Saved, altered) For solids, an array of lumps (which are maps of constituents to constituent counts that adds up to a total value).
	Length should add up to a constant value at first, being below that should count as being cracked and mined.
	When the total descends below a threshold, it should break into its constituent parts.
- `superTopping`: (Saved) The super topping layer's table, or `nil` for no super topping.
- `superTopping.type`: (Saved) Can be either `"layers"` or `"wall"`.
- `superTopping.subLayers`: (Saved) For layers-type super toppings, an array of super topping sub-layers.
	Fields for entries:
	- `type`: (Saved) One of:
		- `grass`: For living matter coating the topping.
		- `planks`: Solid, for a plank texture.
		- `carpet`: Solid, but requires solid topping or super topping.
		- `grate`: Solid, for a grate texture.
	- `lump`: (Saved, altered) A single lump that defines the materials of the sub-layer.
	- `grassTargetHealth`: (Not saved) Cached value that is recalculated only when a tile is changed.
- `lastTimeTicked`: (Saved) The super world's `timer` value last time this tile was ticked.
	Used with current `timer` to get how much effective delta time to use.
