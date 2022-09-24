# Materials

Part of the registry.

Fields:
- `colour`: An array of three 0-1 numbers corresponding to red, green, and blue.
- `deadColour`: For grass super topping sub-layers, display colour is a lerp between this and `colour` using health.
- `noiseSize`: Higher numbers mean bigger clouds when rendering tiles.
- `visualWeight`: How much to multiply into the weight of this material's impact on the apppearance of a tile. Defaults to 1.
- `contrast`: The contrast of the noise texture.
- `brightness`: The brightness of the noise texture.
