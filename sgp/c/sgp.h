#ifndef SGP_H_
#define SGP_H_

#include "structs.h"


/* Return Codes ---------------------------------------------------- */

#define sgp_SUCCESS             0
#define sgp_INVALID_ARGUMENT    1
#define sgp_UNINITIALIZED_INPUT 2
#define sgp_NULL_PTR_ERROR      3
#define sgp_INVALID_STATE       4
#define sgp_LOCK_ERROR          5


/* ----------------------------------------------------------------- */


/**
 * SystemGeneration stores information used in generation of a system,
 * and stores results.
 *
 * Once sun, seed_system, and system_name are set, ownership is assumed
 * by SystemGeneration, and will be freed
 * by sgp_systemGeneration_free()
 */
typedef struct sgp_SystemGeneration {
     sun*           sun;
     planet_pointer innermost_planet;
     long           rng_seed;
     int 			use_seed_system;
     planet_pointer seed_system;
     char			flag_char;
     int			sys_no;
     char*			system_name;
     long double 	inner_dust_limit;       /* 0.0 == default / no-limit    */
     long double 	outer_planet_limit;     /* 0.0 == default / no-limit    */
     long double 	ecc_coef;
     long double 	inner_planet_factor;
     int			do_gases;               /* Calculate atm. gas comp.     */
     int			do_moons;               /* Should moons be generated    */
     int            generated;              /* Whether generation occurred  */
} sgp_SystemGeneration;


/* Struct Functions ------------------------------------------------ */


void    sgp_SystemGeneration_init      (sgp_SystemGeneration*);
void    sgp_SystemGeneration_free      (sgp_SystemGeneration*);
int     sgp_SystemGeneration_generate  (sgp_SystemGeneration*);

void    sgp_sun_init                    (sun*);
void    sgp_sun_free                    (sun*);

void    sgp_planet_init                 (planets*);
void    sgp_planet_free                 (planets*);


/* ----------------------------------------------------------------- */


#endif  /* SGP_H_ */
