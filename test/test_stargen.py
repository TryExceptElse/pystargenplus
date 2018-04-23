from unittest import TestCase

from sgp.stargen import System, SunConfig, InvalidStateException, \
    SunView, PlanetView


class TestSystemGeneration(TestCase):
    def test_system_generation_will_not_generate_twice(self):
        sun = SunConfig(1, 1)
        system = System(sun_config=sun)
        system.generate()
        self.assertRaises(InvalidStateException, system.generate)

    def test_system_is_marked_as_generated_after_generation(self):
        sun = SunConfig(1, 1)
        system = System(sun_config=sun)
        system.generate()
        self.assertTrue(system.generated)

    def test_system_sun_receives_data_passed_in_sun_config(self):
        sun_mass = 0.43
        sun_luminosity = 0.31
        sun_config = SunConfig(sun_mass, sun_luminosity)
        system = System(sun_config=sun_config)
        system.generate()
        sun = system.sun
        self.assertIsNotNone(sun)
        self.assertEqual(sun.mass, sun_mass)
        self.assertEqual(sun.luminosity, sun_luminosity)

    def test_system_default_sun_has_valid_data(self):
        system = System()
        system.generate()
        sun = system.sun
        self.assertIsNotNone(sun)
        self.assertGreater(sun.mass, 0)
        self.assertGreater(sun.luminosity, 0)


class TestSunConfig(TestCase):
    def test_sun_must_be_instantiated_with_mass_or_lum(self):
        self.assertRaises(ValueError, SunConfig)


class TestSunView(TestCase):
    def test_exception_thrown_on_property_use_if_ptr_not_set(self):
        some_system = System()
        sun = SunView(some_system)
        self.assertRaises(InvalidStateException, lambda: sun.mass)
