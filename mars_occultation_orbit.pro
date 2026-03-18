;+
; NAME:
;   MARS_OCCULTATION_ORBIT
;
; PURPOSE:
;   Mars solar occultation ray tracer driven by orbital propagation.
;   Replaces the hardcoded lat/lon/alt loop in mars_example.pro with
;   positions derived from Keplerian elements via the satellite_position
;   library (../satellite_position/src/).
;
; USAGE:
;   IDL> mars_occultation_orbit
;
; INPUTS (configured in the USER CONFIGURATION section below):
;   Orbital elements: a, e, i, raan, omega, M0
;   Simulation time:  npts, t0
;   Solar geometry:   Ls (areocentric solar longitude), ss_lon_at_t0
;
; OUTPUTS:
;   Structure 'a' containing:
;     .time           - time array (seconds from epoch)
;     .height         - tangent point altitude (m) at each time step
;     .longitude      - tangent point longitude (degrees)
;     .latitude       - tangent point latitude (degrees)
;     .n_intersections - number of atmospheric layers intersected
;     .path_info      - pointer array of path geometry structs
;
; NOTES:
;   - mars_example.pro is preserved as a standalone hardcoded reference
;   - IDL path setup uses ROUTINE_FILEPATH (IDL 8.0+)
;   - ss_lon_at_t0 is a mission parameter: the Mars-fixed longitude facing
;     the Sun at epoch t0. Must be supplied by the user.
;
; MODIFICATION HISTORY:
;   2026-03-18: Initial implementation
;-

PRO mars_occultation_orbit
  COMPILE_OPT IDL2

  ; ===========================================================================
  ; 0. IDL PATH SETUP
  ; ===========================================================================
  ; Both codebases are sibling directories under orbit/.
  ; ROUTINE_FILEPATH locates this file regardless of working directory.
  sp_src = FILE_DIRNAME(ROUTINE_FILEPATH('mars_occultation_orbit')) + $
           '/../satellite_position/src'
  !PATH = EXPAND_PATH(sp_src) + ':' + !PATH

  ; Compile occultation coordinate utilities
  osse_mars_coordinates

  ; ===========================================================================
  ; 1. ORBITAL ELEMENTS  — USER CONFIGURATION
  ; ===========================================================================
  mars = sp_mars_constants()

  ; TGO-like orbit: 400 km altitude, 74-degree inclination
  elements = { $
    a:     mars.r_eq + 400.0d0, $   ; semi-major axis (km)
    e:     0.005d0, $               ; eccentricity
    i:     74.0d0 * !DTOR, $        ; inclination (radians)
    raan:  0.0d0, $                 ; right ascension of ascending node (rad)
    omega: 0.0d0, $                 ; argument of periapsis (radians)
    M0:    0.0d0 $                  ; mean anomaly at epoch (radians)
  }

  t0   = 0.0d0   ; epoch (seconds)
  npts = 45L     ; number of time steps

  ; One full orbital period
  period = 2.0d0 * !DPI * SQRT(elements.a^3 / mars.mu)
  t = DINDGEN(npts) * period / DOUBLE(npts - 1)

  PRINT, FORMAT='(A,F8.1,A)', 'Orbital period: ', period / 60.0d0, ' min'
  PRINT, FORMAT='(A,I0,A)', 'Time steps: ', npts, ' (one per orbit point)'

  ; ===========================================================================
  ; 2. SUB-SOLAR GEOMETRY  — USER CONFIGURATION
  ; ===========================================================================
  ; Sub-solar latitude from areocentric solar longitude L_s
  Ls     = 90.0d0    ; northern summer solstice (degrees)
  ss_lat = sp_calculate_subsolar_latitude(Ls, /DEGREES)

  ; Sub-solar longitude at epoch t0.
  ; Physical meaning: which Mars-fixed longitude faces the Sun when t = t0.
  ; This is a mission/simulation parameter — set to match your scenario.
  ss_lon_at_t0 = 0.0d0   ; degrees

  PRINT, FORMAT='(A,F6.2,A)', 'Sub-solar latitude: ', ss_lat, ' deg'
  PRINT, FORMAT='(A,F6.2,A)', 'Sub-solar longitude at t0: ', ss_lon_at_t0, ' deg'

  ; ===========================================================================
  ; 3. PROPAGATE ORBIT
  ; ===========================================================================
  PRINT, 'Propagating orbit...'
  result = sp_propagate_orbit(elements, t, t0, mars)

  ; Print first time step to verify geometry
  PRINT, ''
  PRINT, 'First time step (t=0):'
  PRINT, FORMAT='(A,F10.4,A)', '  Latitude:  ', result[0].lat, ' deg'
  PRINT, FORMAT='(A,F10.4,A)', '  Longitude: ', result[0].lon, ' deg'
  PRINT, FORMAT='(A,F10.4,A)', '  Altitude:  ', result[0].alt, ' km'
  PRINT, ''

  ; ===========================================================================
  ; PLACEHOLDER — loop and results follow in subsequent steps
  ; ===========================================================================
  PRINT, 'Propagation OK'
  STOP
END
