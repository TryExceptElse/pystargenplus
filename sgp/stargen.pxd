#######################################################################
# External structs
#######################################################################


cdef extern from "structs.h":
    cdef struct sun:
        long double     luminosity
        long double     mass
        long double     life
        long double     age
        long double     r_ecosphere
        char           *name

    enum planet_type:
        tUnknown,
        tRock,
        tVenusian,
        tTerrestrial,
        tGasGiant,
        tMartian,
        tWater,
        tIce,
        tSubGasGiant,
        tSubSubGasGiant,
        tAsteroids,
        t1Face,
        tBrownDwarf

    cdef struct gas:
        int             num
        long double     surf_pressure       # units of millibars (mb)

    cdef struct planets_record:
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

    cdef struct sgp_SystemGeneration:
        sun            *sun
        int             use_seed_system
        planets_record *seed_system
        char            flag_char
        int             sys_no
        char           *system_name
        long double     inner_dust_limit       # 0.0 == default / no-limit
        long double     outer_planet_limit     # 0.0 == default / no-limit
        long double     ecc_coef
        long double     inner_planet_factor
        int             do_gases               # Calculate atm. gas comp.
        int             do_moons               # Should moons be generated
        bint            generated

cdef extern from "sgp.h":
    # return codes
    int sgp_SUCCESS
    int sgp_INVALID_ARGUMENT
    int sgp_UNINITIALIZED_INPUT
    int sgp_NULL_PTR_ERROR
    int sgp_INVALID_STATE

    # functions

    void    sgp_SystemGeneration_init      (sgp_SystemGeneration*)
    void    sgp_SystemGeneration_free      (sgp_SystemGeneration*)
    int     sgp_SystemGeneration_generate  (sgp_SystemGeneration*)

    void    sgp_sun_init                    (sun*)
    void    sgp_sun_free                    (sun*)


#######################################################################
# Extension classes
#######################################################################


cdef class System:
    cdef sgp_SystemGeneration _system_generation


cdef class SunConfig:
    """
    Class storing data about a sun that will be used in
    system generation.
    """
    cdef long double    _mass
    cdef long double    _luminosity
    cdef char*          _name


cdef class SystemObjectView:
    cdef System         _system     # System which owns the viewed object.
    cdef void*          _viewed_ptr  # Pointer to viewed c-struct.

    cdef void           ensure_validity(self) except *


cdef class SunView(SystemObjectView):
    """
    Class providing a view onto a sun in a generated system.
    """
    @staticmethod
    cdef SunView        wrap(sun *sun, System system)

    cdef sun*           _get_sun(self)


cdef class PlanetView(SystemObjectView):
    """
    Class providing a view onto a planet in a generated system.
    """
    @staticmethod
    cdef PlanetView     wrap(planets_record *c_planet, System system)

    cdef planets_record* _get_planet(self)  # Pointer to viewed planet.



#######################################################################
