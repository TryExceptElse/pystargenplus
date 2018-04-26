# pystargenplus
Stargen simplified and wrapped in Python.

### Example Use:

```
sun_config = SunConfig(0.43, 0.31)  # inputs are in solar masses, solar luminosity
system = System(rng_seed=24, sun_config=sun, do_gases=True, do_moons=True)
for planet in system.planets:
    print(planet.mass)
```
