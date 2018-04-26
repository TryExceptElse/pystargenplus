# pystargenplus
Stargen simplified and wrapped in Python.

### Example Use:

```
sun_config = SunConfig(0.43, 0.31)  # inputs are in solar masses, solar luminosity
system = System(rng_seed=24, sun_config=sun, do_gases=True, do_moons=True)
for planet in system.planets:
    print(planet.mass)
```

### Planet attributes:
Attributes are subject to change until project matures.

| Property | Detail |
|----------|--------|
|next|Next planet|
|moons|Generator returning moons of this planet.|
|planet_no|Index of this planet in system (solar or planetary)|
|a|Semi-major-axis|
|e|Orbital eccentricity|
|axial_tilt|Axial tilt in units of degrees|
|mass|Mass in kg|
|solar_masses|Mass in solar masses|
|gas_giant|TRUE if the planet is a gas giant|
|dust_mass|Mass, ignoring gas (kg)|
|gas_mass|Mass, ignoring dust (kg)|
|ice_mass_fraction|
|rock_mass_fraction|
|moon_a|Semi-major axis of lunar orbit (in AU)|
|moon_e|Eccentricity of lunar orbit """|
|core_radius|Radius of the rocky core (in m)|
|radius|Equatorial radius (in m)|
|orbit_zone|Gets the 'zone' of the planet. May be 1, 2, or 3.|
|density|Density (in kg/m^3)|
|orb_period|Length of the local year (seconds) """|
|day|Length of the local day (seconds)|
|resonant_period|TRUE if in resonant rotation|
|esc_velocity|Units of m/sec """|
|surf_accel|Units of m/sec2|
|surf_grav|Units of Earth gravities|
|rms_velocity|Units of m/sec|
|molec_weight|Smallest molecular weight retained|
|surf_pressure|Units of pascals (p)|
|greenhouse_effect|Runaway greenhouse effect? (bool)|
|boil_point|The boiling point of water (Kelvin)|
|albedo|Albedo of the planet|
|exospheric_temp|Units of degrees Kelvin |
|estimated_terr_temp| For terrestrial moons and similar|
|surf_temp|Surface temperature in Kelvin|
|greenhs_rise|Temperature rise due to greenhouse|
|high_temp|Day-time temperature|
|low_temp|Night-time temperature|
|max_temp|Summer/Day|
|min_temp|Winter/Night|
|hydrosphere|Fraction of surface covered|
|cloud_cover|Fraction of surface covered|
|ice_cover|Fraction of surface covered|
|sun|Returns a new view instance of the planet's sun|
|gases|Count of gases in the atmosphere|"""|
|planet_type|Type code
