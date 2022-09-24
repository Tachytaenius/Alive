# Materials

Part of the registry.

Fields:
- `colour`: An array of three 0-1 numbers corresponding to red, green, and blue.
- `deadColour`: For grass super topping sub-layers, display colour is a lerp between this and `colour` using `grassHealth`.
- `noiseSize`: Higher numbers mean bigger clouds when rendering tiles.
- `visualWeight`: How much to multiply into the weight of this material's impact on the apppearance of a tile. Defaults to 1.
- `contrast`: The contrast of the noise texture.
- `brightness`: The brightness of the noise texture.
- `growthRate`: For grass, how much `grassAmount` is added to per second at full `grassHealth`.
- `decayRate`: For grass, how much `grassAmount` loses per second at 0 `grassHealth`.
- `healthIncreaseRate`: For grass, how much `grassHealth` is added to per second when grass health is increasing.
- `healthDecreaseRate`: For grass, how much `grassHealth` loses per second when grass target health is lower than current health.
- `fullness1`: The `grassAmount` at and above which the texture fullness is 1. Defaults to 1.
- `targetGrassAmountAdd`: Amount to add to health to get target grass amount when doing growth/decay calculations.
	Target remains clamped between 0 and 1.
