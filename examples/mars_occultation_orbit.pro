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
;     .time            - time array (seconds from epoch)
;     .height          - tangent point altitude (m) at each time step
;     .longitude       - tangent point longitude (degrees)
;     .latitude        - tangent point latitude (degrees)
;     .n_intersections - number of atmospheric layers intersected
;     .path_info       - pointer array of path geometry structs
;
; NOTES:
;   - mars_example.pro is preserved as a standalone hardcoded reference
;   - IDL path setup uses ROUTINE_FILEPATH (IDL 8.0+)
;   - ss_lon_at_t0 is a mission parameter: the Mars-fixed longitude facing
;     the Sun at epoch t0. Must be supplied by the user.
;   - The occultation code uses a spherical Mars (R=3397 km); the propagator
;     uses an oblate ellipsoid (r_eq=3396.19 km). The lat/lon/alt interface
;     insulates the two models; the difference is within the existing
;     spherical approximation already present in the occultation code.
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
  this_dir = FILE_DIRNAME(ROUTINE_FILEPATH('mars_occultation_orbit'))
  sp_src   = this_dir + '/../../satellite_position/src'
  occ_src  = this_dir + '/../src'
  !PATH = EXPAND_PATH(sp_src) + ':' + EXPAND_PATH(occ_src) + ':' + !PATH


  ; ===========================================================================
  ; 1. ORBITAL ELEMENTS  — USER CONFIGURATION
  ; ===========================================================================
  mars = sp_mars_constants()

  ; TGO-like orbit: 400 km mean altitude, 74-degree inclination
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

  PRINT, ''
  PRINT, '========================================='
  PRINT, 'MARS OCCULTATION - ORBIT-DRIVEN EXAMPLE'
  PRINT, '========================================='
  PRINT, FORMAT='(A,F8.1,A)', 'Orbital period: ', period / 60.0d0, ' min'
  PRINT, FORMAT='(A,I0,A)',   'Time steps:     ', npts, ' (one per orbit point)'

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
  PRINT, ''

  ; ===========================================================================
  ; 3. PROPAGATE ORBIT
  ; ===========================================================================
  PRINT, 'Propagating orbit...'
  result = sp_propagate_orbit(elements, t, t0, mars)

  ; ===========================================================================
  ; 4. OCCULTATION SETUP
  ; ===========================================================================
  params = osse_mars_params()
  quiet  = 0
  eps    = 10.0d0   ; meters — tolerance for tangent height consistency check

  path_info       = PTRARR(npts, /ALLOCATE_HEAP)
  height          = DBLARR(npts)
  longitude       = DBLARR(npts)
  latitude        = DBLARR(npts)
  n_intersections = INTARR(npts)

  ; ===========================================================================
  ; 5 & 6. MAIN LOOP over orbital time steps
  ; ===========================================================================
  PRINT, 'Performing ray trace...'

  FOR i = 0, npts - 1 DO BEGIN

    ; Satellite position from propagator (alt: km -> m for occultation code)
    sat_lat = result[i].lat
    sat_lon = result[i].lon
    sat_alt = result[i].alt * 1.0d3   ; km -> meters

    ; Sub-solar longitude at this time step (Mars rotates east, footprint moves west)
    ss_lon = sp_calculate_subsolar_longitude(t[i], t0, ss_lon_at_t0, mars)

    ; Convert to occultation Cartesian frame and get sun direction
    sat_pos = osse_latlon_to_cartesian(sat_lat, sat_lon, sat_alt)
    sun_dir = osse_sspt_to_sun_direction(ss_lat, ss_lon, sat_pos=sat_pos)

    ; Calculate the pathlength to the tangent point
    s_tangent    = -TOTAL(sat_pos * sun_dir)
    tangent_point = sat_pos + s_tangent * sun_dir
    res_tangent  = osse_cartesian_to_latlon(tangent_point)
    PRINT, 'tangent: ', res_tangent.longitude, res_tangent.latitude, $
           res_tangent.altitude / 1000.d0
    height[i]    = res_tangent.altitude
    longitude[i] = res_tangent.longitude
    latitude[i]  = res_tangent.latitude

    ; Trace the ray from spacecraft towards sun through atmospheric layers
    osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, $
      intersections, n_int, quiet=quiet
    n_intersections[i] = n_int

    IF ABS(tang_alt - res_tangent.altitude) GT eps THEN BEGIN
      MESSAGE, 'tangent point height calculations differ.'
      STOP
    ENDIF

    PRINT, FORMAT='(A,F9.4,A,I4)', 'Tangent altitude: ', tang_alt / 1000.0d, $
           ' km, Layers intersected: ', n_int

    ; Get integration points along sightline; skip if ray misses atmosphere
    IF n_int GT 0 THEN BEGIN

      ; Sorted list of intersection points along the sightline
      osse_construct_pathlength, intersections, s_inbound, s_outbound, $
        params=params

      ; Verify discriminants are not near-tangent (would indicate a degenerate ray)
      idx = WHERE(intersections[*].intersects GT 0.)
      IF idx[0] NE -1 THEN BEGIN
        min_discriminant = MIN([intersections[idx].discriminant_inner, $
                                intersections[idx].discriminant_outer])
        IF min_discriminant LT 1.e4 THEN BEGIN
          MESSAGE, 'min(discriminant) lt 1.e4'
          STOP
        ENDIF
      ENDIF

      s_points   = [s_inbound, s_tangent, s_outbound]
      n_s_points = N_ELEMENTS(s_points)
      intersection_points = FLTARR(3, n_s_points)

      FOR j = 0, n_s_points - 1 DO BEGIN
        s_position = sat_pos + s_points[j] * sun_dir
        res = osse_cartesian_to_latlon(s_position)
        intersection_points[*, j] = [res.longitude, res.latitude, res.altitude]
      ENDFOR

      *path_info[i] = { $
        path_length:    s_points, $
        path_longitude: REFORM(intersection_points[0, *]), $
        path_latitude:  REFORM(intersection_points[1, *]), $
        path_altitude:  REFORM(intersection_points[2, *]) $
      }

    ENDIF

  ENDFOR   ; end loop over time steps

  ; ===========================================================================
  ; RESULTS
  ; ===========================================================================
  a = { $
    time:            t, $
    height:          height, $
    longitude:       longitude, $
    latitude:        latitude, $
    n_intersections: n_intersections, $
    path_info:       path_info $
  }

  PRINT, ''
  PRINT, '========================================='
  PRINT, 'Orbit-driven occultation complete'
  PRINT, '========================================='
  PRINT, ''
  STOP
END
