#include "sgp.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "stargen.h"



/* Constant Values ------------------------------------------------- */

const double    sgp_default_eccentricity            = 0.077;
const double    sgp_default_inner_planet_factor     = 0.3;

const char * const sgp_default_name = "Unnamed";

const planets   sgp_default_planet = {0,0.,0.,0,0,0,0,0,ZEROES,0,NULL,NULL};


/* Forward Declarations -------------------------------------------- */

/* Externally declared functions */
void generate_stellar_system(
    planet_pointer *innermost_planet,
    sun            *sun,
    int             use_seed_system,
    planet_pointer  seed_system,
    char            flag_char,
    int             sys_no,
    char           *system_name,
    long double     inner_dust_limit,
    long double     outer_planet_limit,
    long double     ecc_coef,
    long double     inner_planet_factor,
    int             do_gases,
    int             do_moons);

/* Utility */
char*   sgp_new_str                     (const char *);


/* sgp_SystemGeneration Functions ---------------------------------- */

/**
 * Initializes a SystemGeneration.
 */
void sgp_SystemGeneration_init(sgp_SystemGeneration *generation) {
    generation->sun                   = NULL;
    generation->innermost_planet      = NULL;
    generation->use_seed_system       = 0;
    generation->seed_system           = NULL;
    generation->flag_char             = '?';
    generation->sys_no                = 0;
    generation->system_name           = sgp_new_str(sgp_default_name);
    generation->inner_dust_limit      = 0.0;
    generation->outer_planet_limit    = 0.0;
    generation->ecc_coef              = sgp_default_eccentricity;
    generation->inner_planet_factor   = sgp_default_inner_planet_factor;
    generation->do_gases              = 0;
    generation->do_moons              = 0;
}

/**
 * Frees all fields held by SystemGeneration.
 */
void sgp_SystemGeneration_free(sgp_SystemGeneration *generation) {
    if (generation == NULL) {
        return;
    }
    if (generation->sun != NULL) {
        free(generation->sun);
        generation->sun = NULL;
    }
    if (generation->seed_system != NULL) {
        sgp_planet_free(generation->seed_system);
        free(generation->seed_system);
        generation->seed_system = NULL;
    }
    if (generation->system_name != NULL) {
        free(generation->system_name);
        generation->system_name = NULL;
    }
    if (generation->innermost_planet != NULL) {
        sgp_planet_free(generation->innermost_planet);
        free(generation->innermost_planet);
        generation->innermost_planet = NULL;
    }
}

/**
 * Generates a stellar system from information passed in passed config
 */
int sgp_SystemGeneration_generate(sgp_SystemGeneration *config) {
    if (config->generated) {
        fprintf(stderr, "sgp_SystemGeneration_generate() : "
            "SystemGeneration has already been generated.");
        return sgp_INVALID_STATE;
    }
    if (config->use_seed_system &&
            config->seed_system == NULL) {
        fprintf(stderr, "sgp_SystemGeneration_generate() : "
            "Passed seed system was NULL.");
        return sgp_NULL_PTR_ERROR;
    }
    if (config->system_name == NULL) {
        fprintf(stderr, "sgp_SystemGeneration_generate() : "
            "System name was NULL");
        return sgp_NULL_PTR_ERROR;
    }
    if (config->sun == NULL) {
        fprintf(stderr, "sgp_SystemGeneration_generate() : "
            "Passed sun was NULL.");
        return sgp_NULL_PTR_ERROR;
    } else {
        if (config->sun->mass == 0.0 && config->sun->luminosity == 0.0) {
            fprintf(stderr, "sgp_SystemGeneration_generate() : "
                "Either mass or luminosity (or both) must be assigned to sun "
                "before generation.");
            return sgp_INVALID_ARGUMENT;
        }
    }
    if (config->sys_no < 0) {
        fprintf(stderr, "sgp_SystemGeneration_generate() : "
            "System number was invalid: %d", config->sys_no);
        return sgp_INVALID_ARGUMENT;
    }
    if (config->inner_dust_limit < 0.0) {
        fprintf(stderr, "sgp_SystemGeneration_generate() : "
            "inner_dust_limit was invalid: %f",
            (double)config->inner_dust_limit);
        return sgp_INVALID_ARGUMENT;
    }
    if (config->outer_planet_limit < 0.0) {
        fprintf(stderr, "sgp_SystemGeneration_generate() : "
            "outer_dust_limit was invalid: %f",
            (double)config->outer_planet_limit);
        return sgp_INVALID_ARGUMENT;
    }
    if (config->ecc_coef < 0.0) {
        fprintf(stderr, "sgp_SystemGeneration_generate() : "
            "ecc_coef was invalid: %f",
            (double)config->ecc_coef);
        return sgp_INVALID_ARGUMENT;
    }
    if (config->inner_planet_factor < 0.0) {
        fprintf(stderr, "sgp_SystemGeneration_generate() : "
            "inner_planet_factor was invalid: %f",
            (double)config->inner_planet_factor);
        return sgp_INVALID_ARGUMENT;
    }
    generate_stellar_system(
            &config->innermost_planet,
             config->sun,
             config->use_seed_system,
             config->seed_system,
             config->flag_char,
             config->sys_no,
             config->system_name,
             config->inner_dust_limit,
             config->outer_planet_limit,
             config->ecc_coef,
             config->inner_planet_factor,
             config->do_gases,
             config->do_moons
    );
    config->generated = 1;
    return sgp_SUCCESS;
}


/* sun Functions --------------------------------------------------- */


void sgp_sun_init(sun *sun) {
    sun->luminosity     = 0.0;  /* If 0, will be estimated from mass        */
	sun->mass           = 0.0;  /* If 0, will be estimated from lum         */
	                            /* Life determined from lum + mass          */
	                            /* Age determined randomly                  */
	                            /* r_ecosphere determined from lum          */
	sun->name           = sgp_new_str(sgp_default_name);
}

void sgp_sun_free(sun *sun) {
    if (sun == NULL) {
        return;
    }
    if (sun->name != NULL) {
        free(sun->name);        /* Ownership is assumed upon assignment     */
        sun->name = NULL;
    }
}


/* planet Functions ------------------------------------------------ */


void sgp_planet_init(planets *planet) {
    *planet = sgp_default_planet;
}

void sgp_planet_free(planets *planet) {
    for (; planet != NULL; planet = planet->next_planet) {
        if (planet->atmosphere != NULL) {
            free(planet->atmosphere);
            planet->atmosphere = NULL;
        }
        if (planet->first_moon != NULL) {
            sgp_planet_free(planet->first_moon);
            free(planet->first_moon);
            planet->first_moon = NULL;
        }
    }
}


/* Utility Functions ----------------------------------------------- */


char* sgp_new_str(const char *src) {
    char *new_str = malloc(sizeof(char) * strlen(src));
    strcpy(new_str, src);
    return new_str;
}
