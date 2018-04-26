import itertools as itr

from unittest import TestCase

from sgp.stargen import System, SunConfig, InvalidStateException, \
    SunView, PlanetView


# Note: For all system generation tests, set a seed value to ensure
# tests are repeatable. Otherwise a random seed will be used.


class TestSystemGeneration(TestCase):
    def test_system_generation_will_not_generate_twice(self):
        sun = SunConfig(1, 1)
        system = System(rng_seed=24, sun_config=sun)
        system.generate()
        self.assertRaises(InvalidStateException, system.generate)

    def test_system_is_marked_as_generated_after_generation(self):
        sun = SunConfig(1, 1)
        system = System(rng_seed=24, sun_config=sun)
        system.generate()
        self.assertTrue(system.generated)

    def test_system_sun_receives_data_passed_in_sun_config(self):
        sun_mass = 0.43
        sun_luminosity = 0.31
        sun_config = SunConfig(sun_mass, sun_luminosity)
        system = System(rng_seed=24, sun_config=sun_config)
        system.generate()
        sun = system.sun
        self.assertIsNotNone(sun)
        self.assertEqual(sun.mass, sun_mass)
        self.assertEqual(sun.luminosity, sun_luminosity)

    def test_system_default_sun_has_valid_data(self):
        system = System(rng_seed=24)
        system.generate()
        sun = system.sun
        self.assertIsNotNone(sun)
        self.assertGreater(sun.mass, 0)
        self.assertGreater(sun.luminosity, 0)

    def test_generated_system_has_planets(self):
        system = System(rng_seed=24)
        system.generate()
        planets = [planet for planet in system.planets]
        self.assertGreater(len(planets), 0)

    def test_moons_are_generated(self):
        system = System(rng_seed=24, do_moons=True)
        system.generate()
        moons = [moon for moon in itr.chain(
            [[moon for moon in planet.moons] for planet in system.planets])]
        self.assertGreater(len(moons), 0)

    def test_systems_generated_with_same_seed_are_identical(self):
        system_a = System(rng_seed=24, do_moons=True)
        system_a.generate()
        system_b = System(rng_seed=24, do_moons=True)
        system_b.generate()
        planets_a = [i for i in system_a.planets]
        planets_b = [i for i in system_b.planets]
        self.assertEqual(planets_a[0].mass, planets_b[0].mass)
        self.assertEqual(planets_a[1].mass, planets_b[1].mass)
        self.assertEqual(planets_a[2].mass, planets_b[2].mass)

    def test_systems_generated_with_different_seeds_are_not_identical(self):
        system_a = System(rng_seed=24, do_moons=True)
        system_a.generate()
        system_b = System(rng_seed=25, do_moons=True)
        system_b.generate()
        planets_a = [i for i in system_a.planets]
        planets_b = [i for i in system_b.planets]
        self.assertNotEqual(planets_a[0].mass, planets_b[0].mass)
        self.assertNotEqual(planets_a[1].mass, planets_b[1].mass)
        self.assertNotEqual(planets_a[2].mass, planets_b[2].mass)


class TestSunConfig(TestCase):
    def test_sun_must_be_instantiated_with_mass_or_lum(self):
        self.assertRaises(ValueError, SunConfig)


class TestSunView(TestCase):
    def test_exception_thrown_on_property_use_if_ptr_not_set(self):
        some_system = System()
        sun = SunView(some_system)
        self.assertRaises(InvalidStateException, lambda: sun.mass)
