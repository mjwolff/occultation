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
;   IDL> mars_occultation_orbit, /verbose
;
; KEYWORDS:
;   VERBOSE - if set, enable diagnostic output from the ray-tracing
;             routines (osse_trace_ray_occultation_3d,
;             osse_find_shell_intersection_3d,
;             osse_generate_integration_points)
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
;   2026-03-20: Add VERBOSE keyword; pass through to ray-trace routines
;-

pro mars_occultation_orbit, verbose = verbose
  compile_opt idl2

  ; ===========================================================================
  ; 0. IDL PATH SETUP
  ; ===========================================================================
  ; Both codebases are sibling directories under orbit/.
  ; ROUTINE_FILEPATH locates this file regardless of working directory.
  this_dir = file_dirname(routine_filepath('mars_occultation_orbit'))
  sp_src = this_dir + '/../../satellite_position/src'
  occ_src = this_dir + '/../src'
  !path = expand_path(sp_src) + ':' + expand_path(occ_src) + ':' + !path

  ; ===========================================================================
  ; 1. ORBITAL ELEMENTS  — USER CONFIGURATION
  ; ===========================================================================
  mars = sp_mars_constants()

  ; TGO-like orbit: 400 km mean altitude, 74-degree inclination
  elements = { $
    a: mars.r_eq + 400.0d0, $ ; semi-major axis (km)
    e: 0.005d0, $ ; eccentricity
    i: 74.0d0 * !dtor, $ ; inclination (radians)
    raan: 0.0d0, $ ; right ascension of ascending node (rad)
    omega: 0.0d0, $ ; argument of periapsis (radians)
    m0: 0.0d0 $ ; mean anomaly at epoch (radians)
    }

  t0 = 0.0d0 ; epoch (seconds)
  npts = 1000l ; number of time steps

  ; One full orbital period
  period = 2.0d0 * !dpi * sqrt(elements.a ^ 3 / mars.mu)
  t = dindgen(npts) * period / double(npts - 1)

  print, ''
  print, '========================================='
  print, 'MARS OCCULTATION - ORBIT-DRIVEN EXAMPLE'
  print, '========================================='
  print, format = '(A,F8.1,A)', 'Orbital period: ', period / 60.0d0, ' min'
  print, format = '(A,I0,A)', 'Time steps:     ', npts, ' (one per orbit point)'

  ; ===========================================================================
  ; 2. SUB-SOLAR GEOMETRY  — USER CONFIGURATION
  ; ===========================================================================
  ; Sub-solar latitude from areocentric solar longitude L_s
  Ls = 90.0d0 ; northern summer solstice (degrees)
  ss_lat = sp_calculate_subsolar_latitude(Ls, /degrees)

  ; Sub-solar longitude at epoch t0.
  ; Physical meaning: which Mars-fixed longitude faces the Sun when t = t0.
  ; This is a mission/simulation parameter — set to match your scenario.
  ss_lon_at_t0 = 0.0d0 ; degrees

  print, format = '(A,F6.2,A)', 'Sub-solar latitude: ', ss_lat, ' deg'
  print, format = '(A,F6.2,A)', 'Sub-solar longitude at t0: ', ss_lon_at_t0, ' deg'
  print, ''

  ; ===========================================================================
  ; 3. PROPAGATE ORBIT
  ; ===========================================================================
  print, 'Propagating orbit...'
  result = sp_propagate_orbit(elements, t, t0, mars)

  ; ===========================================================================
  ; 4. OCCULTATION SETUP
  ; ===========================================================================
  params = osse_mars_params()
  quiet = 0
  eps = 10.0d0 ; meters — tolerance for tangent height consistency check

  path_info = ptrarr(npts, /allocate_heap)
  height = dblarr(npts)
  longitude = dblarr(npts)
  latitude = dblarr(npts)
  n_intersections = intarr(npts)

  ; ===========================================================================
  ; 5 & 6. MAIN LOOP over orbital time steps
  ; ===========================================================================
  print, 'Performing ray trace...'

  for i = 0, npts - 1 do begin
    ; Satellite position from propagator (alt: km -> m for occultation code)
    sat_lat = result[i].lat
    sat_lon = result[i].lon
    sat_alt = result[i].alt * 1.0d3 ; km -> meters

    ; Sub-solar longitude at this time step (Mars rotates east, footprint moves west)
    ss_lon = sp_calculate_subsolar_longitude(t[i], t0, ss_lon_at_t0, mars)

    ; Convert to occultation Cartesian frame and get sun direction
    sat_pos = osse_latlon_to_cartesian(sat_lat, sat_lon, sat_alt)
    sun_dir = osse_sspt_to_sun_direction(ss_lat, ss_lon, sat_pos = sat_pos)

    ; Calculate the pathlength to the tangent point
    s_tangent = -total(sat_pos * sun_dir)
    tangent_point = sat_pos + s_tangent * sun_dir
    res_tangent = osse_cartesian_to_latlon(tangent_point)
    print, i, t[i], res_tangent.longitude, res_tangent.latitude, $
      res_tangent.altitude / 1000.d0, ss_lon, ss_lat, $
      format = '(i6,1x,e15.8,1x,2(f7.2,1x),f8.1,1x,2(f7.2,1x))'
    height[i] = res_tangent.altitude
    longitude[i] = res_tangent.longitude
    latitude[i] = res_tangent.latitude

    ; Trace the ray from spacecraft towards sun through atmospheric layers
    osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, $
      intersections, n_int, verbose = verbose
    n_intersections[i] = n_int

    if abs(tang_alt - res_tangent.altitude) gt eps then begin
      message, 'tangent point height calculations differ.'
      stop
    endif

    ; print, format = '(A,F9.4,A,I4)', 'Tangent altitude: ', tang_alt / 1000.0d, $
    ; ' km, Layers intersected: ',n_int

    ; Get integration points along sightline; skip if ray misses atmosphere
    if n_int gt 0 then begin
      ; Sorted list of intersection points along the sightline
      osse_construct_pathlength, intersections, s_inbound, s_outbound, $
        params = params

      ; Verify discriminants are not near-tangent (would indicate a degenerate ray)
      idx = where(intersections[*].intersects gt 0.)
      if idx[0] ne -1 then begin
        min_discriminant = min([intersections[idx].discriminant_inner, $
          intersections[idx].discriminant_outer])
        if min_discriminant lt 1.e4 then begin
          message, 'min(discriminant) lt 1.e4'
          stop
        endif
      endif

      s_points = [s_inbound, s_tangent, s_outbound]
      n_s_points = n_elements(s_points)
      intersection_points = fltarr(3, n_s_points)

      for j = 0, n_s_points - 1 do begin
        s_position = sat_pos + s_points[j] * sun_dir
        res = osse_cartesian_to_latlon(s_position)
        intersection_points[*, j] = [res.longitude, res.latitude, res.altitude]
      endfor

      *path_info[i] = { $
        path_length: s_points, $
        path_longitude: reform(intersection_points[0, *]), $
        path_latitude: reform(intersection_points[1, *]), $
        path_altitude: reform(intersection_points[2, *]) $
        }
    endif
  endfor ; end loop over time steps

  ; ===========================================================================
  ; RESULTS
  ; ===========================================================================
  a = { $
    time: t, $
    height: height, $
    longitude: longitude, $
    latitude: latitude, $
    n_intersections: n_intersections, $
    path_info: path_info $
    }

  print, ''
  print, '========================================='
  print, 'Orbit-driven occultation complete'
  print, '========================================='
  print, ''
  stop
end
