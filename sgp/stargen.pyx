from libc.stdlib cimport malloc, free


class UninitializedInputException(Exception):
    pass


class NullPointerException(Exception):
    pass


class InvalidStateException(Exception):
    pass


# Dictionary mapping c return codes to exception classes
exception_codes = {
    sgp_SUCCESS: None,
    sgp_INVALID_ARGUMENT: ValueError,
    sgp_UNINITIALIZED_INPUT: UninitializedInputException,
    sgp_NULL_PTR_ERROR: NullPointerException,
    sgp_INVALID_STATE: InvalidStateException
}


cdef class System:
    def __init__(
            self,
            sun_config: SunConfig=SunConfig(1, 1),
            rng_seed: long=0,                   # 0 == random seed
            inner_dust_limit: double=0.0,       # 0.0 == default / no-limit
            outer_planet_limit: double=0.0,     # 0.0 == default / no-limit
            ecc_coef: double=-1.0,              # -1.0 == default
            inner_planet_factor: double=-1.0,   # -1.0 == default
            do_gases: bool=False,
            do_moons: bool=False):
        self._system_generation.sun.mass = sun_config.mass
        self._system_generation.sun.luminosity = sun_config.luminosity
        self._system_generation.rng_seed = rng_seed
        if ecc_coef >= 0:
            self._system_generation.ecc_coef = ecc_coef
        if inner_planet_factor >= 0:
            self._system_generation.inner_planet_factor = ecc_coef
        self._system_generation.do_gases = do_gases
        self._system_generation.do_moons = do_moons

    def __cinit__(self):
        sgp_SystemGeneration_init(&self._system_generation)

        # create and init sun
        cdef sun* sun_ptr = <sun *>malloc(sizeof(sun))
        sgp_sun_init(sun_ptr)

        self._system_generation.sun = sun_ptr

    def __dealloc__(self):
        sgp_SystemGeneration_free(&self._system_generation)

    def generate(self) -> None:
        """ Calculates system planets and properties from inputs """
        result: int = sgp_SystemGeneration_generate(&self._system_generation)
        exception = exception_codes[result]
        if exception:
            raise exception()

    @staticmethod
    def generated_property(f):
        """
        Decorator for SystemGeneration property methods that require
        generation to have occured before the property is accessed.
        If generation has not occurred when the property is accessed,
        generate() will be called.
        """
        def wrapper(self, *args, **kwargs):
            if not self.generated:
                self.generate()
            return f(self, *args, **kwargs)

        wrapper.__name__ = f.__name__ + '_wrapper'
        return property(wrapper)

    @generated_property
    def sun(self) -> SunView:
        return SunView.wrap(self._system_generation.sun, self)

    @generated_property
    def planets(self) -> PlanetView:
        cdef planets_record* planet = self._system_generation.innermost_planet
        while (planet != NULL):
            yield PlanetView.wrap(planet, self)
            planet = planet.next_planet

    @property
    def generated(self) -> bool:
        return self._system_generation.generated


cdef class SunConfig:
    def __init__(self, mass: double=0.0, luminosity: double=0.0):
        if mass == 0.0 and luminosity == 0.0:
            raise ValueError('Either mass or luminosity must be passed to sun')
        self.mass = mass
        self.luminosity = luminosity

    @property
    def mass(self) -> double:
        return self._mass

    @mass.setter
    def mass(self, mass: double):
        if (mass < 0):
            raise ValueError(f'Mass must be > 0 to be valid, '
                             'or == 0 to indicate that it should be estimated '
                             'from luminosity. Got: {mass}')
        self._mass = mass

    @property
    def luminosity(self) -> double:
        return self._luminosity

    @luminosity.setter
    def luminosity(self, luminosity: double):
        if (luminosity < 0):
            raise ValueError(f'Luminosity must be > 0 to be valid, '
                             'or == 0 to indicate that it should be estimated '
                             'from mass. Got: {luminosity}')
        self._luminosity = luminosity


cdef class SystemObjectView:
    def __init__(self, system: System):
        self._system = system

    def __cinit__(self):
        self._viewed_ptr = NULL

    cdef void ensure_validity(self) except *:
        if not self._system:
            raise InvalidStateException(f'No system set: {self._system}')
        if self._viewed_ptr == NULL:
            raise InvalidStateException(f'Viewed pointer was NULL')

def view_property(f):
    def wrapper(self: SystemObjectView, *args, **kwargs):
        self.ensure_validity()
        return f(self, *args, **kwargs)

    wrapper.__name__ = f.__name__ + '_view_property'
    return property(wrapper)


cdef class SunView(SystemObjectView):

    @staticmethod
    cdef SunView wrap(sun* sun, System system):
        view = SunView(system)
        view._viewed_ptr = sun
        return view

    cdef sun* _get_sun(self):
        return <sun *>self._viewed_ptr
    
    @view_property
    def luminosity(self) -> double:
        return self._get_sun().luminosity

    @view_property
    def mass(self) -> double:
        return self._get_sun().mass

    @view_property
    def life(self) -> double:
        return self._get_sun().life

    @view_property
    def age(self) -> double:
        return self._get_sun().age

    @view_property
    def r_ecosphere(self) -> double:
        return self._get_sun().r_ecosphere

    @view_property
    def name(self) -> unicode:
        temp_s: bytes = self._get_sun().name
        return temp_s.decode()


cdef class PlanetView:

    @staticmethod
    cdef PlanetView wrap(planets_record *planet, System system):
        view: PlanetView = PlanetView(system)
        view._viewed_ptr = planet
        return view

    cdef planets_record* _get_planet(self):
        return <planets_record *>self._viewed_ptr

    @view_property
    def next(self) -> PlanetView:
        return PlanetView.wrap(self._get_planet().next_planet, self._system)

    @view_property
    def moons(self) -> PlanetView:
        cdef planets_record* moon = self._get_planet().first_moon
        while (moon != NULL):
            yield PlanetView.wrap(moon, self._system)
            moon = moon.next_planet
        
    @view_property
    def planet_no(self) -> int:
        """ Gets index of planet in system """
        return self._get_planet().planet_no
        
    @view_property
    def a(self) -> double:
        """ Gets semi-major-axis of solar orbit """
        return self._get_planet().a
        
    @view_property
    def e(self) -> double:
        """ eccentricity of solar orbit """
        return self._get_planet().e

    @view_property
    def axial_tilt(self) -> double:
        """ units of degrees """
        return self._get_planet().axial_tilt

    @view_property
    def mass(self) -> double:
        """ mass (in kg) """
        return self._get_planet().mass * SOLAR_MASS_IN_KILOGRAMS

    @view_property
    def solar_masses(self) -> double:
        """ mass (in solar masses) """
        return self._get_planet().mass

    @view_property
    def gas_giant(self) -> bint:
        """ TRUE if the planet is a gas giant """
        return self._get_planet().gas_giant

    @view_property
    def dust_mass(self) -> double:
        """ mass, ignoring gas (kg) """
        return self._get_planet().dust_mass * SOLAR_MASS_IN_KILOGRAMS

    @view_property
    def gas_mass(self) -> double:
        """ mass, ignoring dust (kg) """
        return self._get_planet().gas_mass * SOLAR_MASS_IN_KILOGRAMS

    @view_property
    def imf(self) -> double:
        """ ice mass fraction """
        return self._get_planet().imf

    @view_property
    def ice_mass_fraction(self) -> double:
        """ ice mass fraction """
        return self.imf

    @view_property
    def rmf(self) -> double:
        """ rock mass fraction """
        return self._get_planet().rmf

    @view_property
    def rock_mass_fraction(self) -> double:
        """ rock mass fraction """
        return self.rmf

    @view_property
    def moon_a(self) -> double:
        """ semi-major axis of lunar orbit (in AU) """
        return self._get_planet().moon_a

    @view_property
    def moon_e(self) -> double:
        """ eccentricity of lunar orbit """
        return self._get_planet().moon_e

    @view_property
    def core_radius(self) -> double:
        """ radius of the rocky core (in m) """
        return self._get_planet().core_radius * 1000

    @view_property
    def core_radius_km(self) -> double:
        """ radius of the rocky core (in km) """
        return self._get_planet().core_radius

    @view_property
    def radius(self) -> double:
        """ equatorial radius (in m) """
        return self._get_planet().radius * 1000

    @view_property
    def radius_km(self) -> double:
        """ equatorial radius (in km) """
        return self._get_planet().radius

    @view_property
    def orbit_zone(self) -> int:
        """
        Gets the 'zone' of the planet.
        May be 1, 2, or 3.
        """
        return self._get_planet().orbit_zone

    @view_property
    def density_gcc(self) -> double:
        """ density (in g/cc) """
        return self._get_planet().density

    @view_property
    def density(self) -> double:
        """ density (in kg/m^3) """
        return self._get_planet().density * 1000

    @view_property
    def orb_period_days(self) -> double:
        """ length of the local year (days) """
        return self._get_planet().orb_period

    @view_property
    def orb_period(self) -> double:
        """ length of the local year (seconds) """
        return self._get_planet().orb_period * 24 * 60 * 60

    @view_property
    def day_h(self) -> double:
        """ length of the local day (hours) """
        return self._get_planet().day

    @view_property
    def day(self) -> double:
        """ length of the local day (seconds) """
        return self._get_planet().day * 3600

    @view_property
    def resonant_period(self) -> bint:
        """ TRUE if in resonant rotation """
        return self._get_planet().resonant_period

    @view_property
    def esc_velocity(self) -> double:
        """ units of m/sec """
        # for uncertain reasons, the original c-code uses cm/s
        return self._get_planet().esc_velocity / 100

    @view_property
    def surf_accel(self) -> double:
        """ units of m/sec2 """
        # for uncertain reasons, the original c-code uses cm/s
        return self._get_planet().surf_accel / 100

    @view_property
    def surf_grav(self) -> double:
        """ units of Earth gravities """
        return self._get_planet().surf_grav

    @view_property
    def rms_velocity(self) -> double:
        """ units of m/sec """
        # for uncertain reasons, the original c-code uses cm/s
        return self._get_planet().rms_velocity / 100

    @view_property
    def molec_weight(self) -> double:
        """ smallest molecular weight retained """
        return self._get_planet().molec_weight

    @view_property
    def volatile_gas_inventory(self) -> double:
        return self._get_planet().volatile_gas_inventory

    @view_property
    def surf_pressure_mb(self) -> double:
        """ units of millibars (mb) """
        # for unknown reasons, original c-code uses millibars
        return self._get_planet().surf_pressure

    @view_property
    def surf_pressure_atm(self) -> double:
        """ units of atm (atm) """
        # for unknown reasons, original c-code uses millibars
        return self._get_planet().surf_pressure * 0.000986923

    @view_property
    def surf_pressure(self) -> double:
        """ units of pascals (p) """
        # for unknown reasons, original c-code uses millibars
        return self._get_planet().surf_pressure * 100

    @view_property
    def greenhouse_effect(self) -> bint:
        """ runaway greenhouse effect? """
        return self._get_planet().greenhouse_effect

    @view_property
    def boil_point(self) -> double:
        """ the boiling point of water (Kelvin) """
        return self._get_planet().boil_point

    @view_property
    def albedo(self) -> double:
        """ albedo of the planet """
        return self._get_planet().albedo

    @view_property
    def exospheric_temp(self) -> double:
        """ units of degrees Kelvin """
        return self._get_planet().exospheric_temp

    @view_property
    def estimated_temp(self) -> double:
        """ quick non-iterative estimate (K) """
        return self._get_planet().estimated_temp

    @view_property
    def estimated_terr_temp(self) -> double:
        """ for terrestrial moons and similar """
        return self._get_planet().estimated_terr_temp

    @view_property
    def surf_temp(self) -> double:
        """ surface temperature in Kelvin """
        return self._get_planet().surf_temp

    @view_property
    def greenhs_rise(self) -> double:
        """ Temperature rise due to greenhouse """
        return self._get_planet().greenhs_rise

    @view_property
    def high_temp(self) -> double:
        """ Day-time temperature """
        return self._get_planet().high_temp

    @view_property
    def low_temp(self) -> double:
        """ Night-time temperature """
        return self._get_planet().low_temp

    @view_property
    def max_temp(self) -> double:
        """ Summer/Day """
        return self._get_planet().max_temp

    @view_property
    def min_temp(self) -> double:
        """ Winter/Night """
        return self._get_planet().min_temp

    @view_property
    def hydrosphere(self) -> double:
        """ fraction of surface covered """
        return self._get_planet().hydrosphere

    @view_property
    def cloud_cover(self) -> double:
        """ fraction of surface covered """
        return self._get_planet().cloud_cover

    @view_property
    def ice_cover(self) -> double:
        """ fraction of surface covered """
        return self._get_planet().ice_cover

    @view_property
    def sun(self) -> SunView:
        return SunView.wrap(self._get_planet().sun, self._system)

    @view_property
    def gases(self) -> int:
        """ Count of gases in the atmosphere: """
        return self._get_planet().gases

    @view_property
    def planet_type(self) -> planet_type:
        """ Type code """
        return self._get_planet().type


"""
planets_record members, for reference:

        int             planet_no
        long double     a                   # semi-major axis of solar orbit (in AU)
        long double     e                   # eccentricity of solar orbit
        long double     axial_tilt          # units of degrees
        long double     mass                # mass (in solar masses)
        int             gas_giant           # TRUE if the planet is a gas giant
        long double     dust_mass           # mass, ignoring gas
        long double     gas_mass            # mass, ignoring dust
        long double     imf                 # ice mass fraction
        long double     rmf                 # rock mass fraction
        long double     moon_a              # semi-major axis of lunar orbit (in AU)
        long double     moon_e              # eccentricity of lunar orbit
        long double     core_radius         # radius of the rocky core (in km)
        long double     radius              # equatorial radius (in km)
        int             orbit_zone          # the 'zone' of the planet
        long double     density             # density (in g/cc)
        long double     orb_period          # length of the local year (days)
        long double     day                 # length of the local day (hours)
        int             resonant_period     # TRUE if in resonant rotation
        long double     esc_velocity        # units of cm/sec
        long double     surf_accel          # units of cm/sec2
        long double     surf_grav           # units of Earth gravities
        long double     rms_velocity        # units of cm/sec
        long double     molec_weight        # smallest molecular weight retained
        long double     volatile_gas_inventory
        long double     surf_pressure       # units of millibars (mb)
        int             greenhouse_effect   # runaway greenhouse effect?
        long double     boil_point          # the boiling point of water (Kelvin)
        long double     albedo              # albedo of the planet
        long double     exospheric_temp     # units of degrees Kelvin
        long double     estimated_temp      # quick non-iterative estimate (K)
        long double     estimated_terr_temp # for terrestrial moons and similar
        long double     surf_temp           # surface temperature in Kelvin
        long double     greenhs_rise        # Temperature rise due to greenhouse
        long double     high_temp           # Day-time temperature
        long double     low_temp            # Night-time temperature
        long double     max_temp            # Summer/Day
        long double     min_temp            # Winter/Night
        long double     hydrosphere         # fraction of surface covered
        long double     cloud_cover         # fraction of surface covered
        long double     ice_cover           # fraction of surface covered
        sun            *sun                 # Non-owning ptr
        int             gases               # Count of gases in the atmosphere:
        gas*            atmosphere
        planet_type     type                # Type code
        int             minor_moons
        planets_record *first_moon          # Owning pointer
        planets_record *next_planet         # Owning pointer
"""
