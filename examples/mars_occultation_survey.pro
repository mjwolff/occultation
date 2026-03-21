;+
; NAME:
;   MARS_OCCULTATION_SURVEY
;
; PURPOSE:
;   Survey solar occultation events over multiple orbits. Propagates a
;   TGO-like orbit and computes the tangent altitude at each time step,
;   then identifies complete occultation events — those whose tangent
;   altitude passes through both altitude_max (top of atmosphere) and
;   0 km (surface). Designed as a lightweight survey tool; use
;   mars_occultation_orbit for detailed pathlength analysis of specific
;   events found here.
;
; USAGE:
;   IDL> mars_occultation_survey
;   IDL> mars_occultation_survey, norbits=10, dt=5.0
;   IDL> mars_occultation_survey, altitude_max=80.0d3
;
; KEYWORDS:
;   NORBITS      - number of orbits to simulate (default: 5)
;   DT           - time step in seconds (default: 10.0)
;                  At 400 km altitude the tangent altitude changes at
;                  ~1-3 km/s during limb crossing; dt=10 s gives ~10-30 m
;                  resolution in tangent altitude across each event.
;   ALTITUDE_MAX - upper tangent altitude boundary defining a complete
;                  occultation in meters (default: params.h_atm = 100 km).
;                  Only events whose tangent altitude descends below 0 m
;                  AND whose entry/exit crosses this level are counted.
;   VERBOSE      - if set, print tangent altitude at every time step
;
; INPUTS (configured in the USER CONFIGURATION sections below):
;   Orbital elements: a, e, i, raan, omega, M0
;   Solar geometry:   Ls (areocentric solar longitude), ss_lon_at_t0
;
; OUTPUTS:
;   Structure 'survey' containing:
;     .time        - time array (s from epoch)
;     .tang_alt    - tangent altitude at each step (m)
;     .tang_lat    - tangent point latitude (deg)
;     .tang_lon    - tangent point longitude (deg)
;     .n_int       - number of atmospheric layers intersected
;     .n_complete  - number of complete occultation events found
;     .events      - array of event structs (see below), or -1 if none
;
;   Each event struct contains:
;     .i_ingress   - step index of atmospheric entry (tang_alt = altitude_max)
;     .i_egress    - step index of atmospheric exit
;     .t_ingress   - time of ingress (s)
;     .t_egress    - time of egress (s)
;     .duration    - event duration (s)
;     .tang_alt_min - minimum tangent altitude (m); negative means hits surface
;     .t_min       - time of minimum tangent altitude (s)
;     .lat_min     - tangent point latitude at minimum (deg)
;     .lon_min     - tangent point longitude at minimum (deg)
;
; NOTES:
;   - Uses ROUTINE_FILEPATH for path setup (IDL 8.0+)
;   - Only events with a clear ingress AND egress within the simulated
;     interval are counted; partial events at the start or end are skipped.
;   - ss_lon_at_t0 is a mission parameter: the Mars-fixed longitude facing
;     the Sun at epoch t0.
;
; MODIFICATION HISTORY:
;   2026-03-21: Initial implementation
;-

pro mars_occultation_survey, norbits = norbits, dt = dt, $
  altitude_max = altitude_max, verbose = verbose
  compile_opt idl2

  ; ===========================================================================
  ; 0. IDL PATH SETUP
  ; ===========================================================================
  this_dir = file_dirname(routine_filepath('mars_occultation_survey'))
  sp_src  = this_dir + '/../../satellite_position/src'
  occ_src = this_dir + '/../src'
  !path = expand_path(sp_src) + ':' + expand_path(occ_src) + ':' + !path

  ; ===========================================================================
  ; 1. ORBITAL ELEMENTS  — USER CONFIGURATION
  ; ===========================================================================
  mars = sp_mars_constants()

  ; TGO-like orbit: 400 km mean altitude, 74-degree inclination
  elements = { $
    a:     mars.r_eq + 400.0d0, $ ; semi-major axis (km)
    e:     0.005d0, $              ; eccentricity
    i:     74.0d0 * !dtor, $       ; inclination (radians)
    raan:  0.0d0, $                ; right ascension of ascending node (rad)
    omega: 0.0d0, $                ; argument of periapsis (radians)
    m0:    0.0d0 $                 ; mean anomaly at epoch (radians)
    }

  t0 = 0.0d0 ; epoch (seconds)

  ; ===========================================================================
  ; 2. SIMULATION TIME
  ; ===========================================================================
  if n_elements(norbits) eq 0 then norbits = 5
  if n_elements(dt)      eq 0 then dt      = 10.0d0

  period = 2.0d0 * !dpi * sqrt(elements.a ^ 3 / mars.mu)
  npts   = long(norbits * period / dt) + 1l
  t      = dindgen(npts) * dt

  ; ===========================================================================
  ; 3. SUB-SOLAR GEOMETRY  — USER CONFIGURATION
  ; ===========================================================================
  Ls          = 90.0d0  ; areocentric solar longitude (degrees); 90 = N summer solstice
  ss_lat      = sp_calculate_subsolar_latitude(Ls, /degrees)
  ss_lon_at_t0 = 0.0d0  ; sub-solar longitude at epoch t0 (degrees)

  ; ===========================================================================
  ; 4. OCCULTATION SETUP
  ; ===========================================================================
  params = osse_mars_params()
  if n_elements(altitude_max) eq 0 then altitude_max = params.h_atm

  ; ===========================================================================
  ; 5. PRINT HEADER
  ; ===========================================================================
  print, ''
  print, '================================================='
  print, 'MARS OCCULTATION SURVEY'
  print, '================================================='
  print, format = '(A,F8.2,A)',  'Orbital period:       ', period / 60.0d0, ' min'
  print, format = '(A,I0)',      'Orbits simulated:     ', norbits
  print, format = '(A,F6.1,A)', 'Time step:            ', dt, ' s'
  print, format = '(A,I0)',      'Total time steps:     ', npts
  print, format = '(A,F6.2,A)', 'Sub-solar latitude:   ', ss_lat, ' deg'
  print, format = '(A,F6.2,A)', 'Altitude max:         ', altitude_max / 1000.d0, ' km'
  print, ''

  ; ===========================================================================
  ; 6. PROPAGATE ORBIT
  ; ===========================================================================
  print, 'Propagating orbit...'
  orb = sp_propagate_orbit(elements, t, t0, mars)

  ; ===========================================================================
  ; 7. MAIN LOOP — ray trace at each time step
  ; ===========================================================================
  tang_alt = dblarr(npts)
  tang_lat = dblarr(npts)
  tang_lon = dblarr(npts)
  n_int    = lonarr(npts)

  print, 'Computing tangent altitudes...'

  for i = 0l, npts - 1l do begin

    sat_alt = orb[i].alt * 1.0d3  ; km -> m
    sat_pos = osse_latlon_to_cartesian(orb[i].lat, orb[i].lon, sat_alt)

    ss_lon  = sp_calculate_subsolar_longitude(t[i], t0, ss_lon_at_t0, mars)
    sun_dir = osse_sspt_to_sun_direction(ss_lat, ss_lon, sat_position = sat_pos)

    osse_trace_ray_occultation_3d, sat_pos, sun_dir, ta, isects, ni, params = params

    tang_alt[i] = ta
    n_int[i]    = ni

    ; Tangent point position
    s_tp  = -total(sat_pos * sun_dir)
    tp    = osse_cartesian_to_latlon(sat_pos + s_tp * sun_dir)
    tang_lat[i] = tp.latitude
    tang_lon[i] = tp.longitude

    if keyword_set(verbose) then $
      print, format = '(I6,A,E14.6,A,F8.2,A,F7.2,A,F7.2)', $
        i, '  t=', t[i], '  tang_alt=', ta/1000.d0, ' km', $
        '  lat=', tang_lat[i], '  lon=', tang_lon[i]

  endfor

  ; ===========================================================================
  ; 8. EVENT DETECTION
  ; ===========================================================================
  ; A complete occultation is a contiguous interval where tang_alt < altitude_max
  ; (ray enters the atmospheric window) and min(tang_alt) <= 0 (ray reaches surface).

  in_window = (tang_alt lt altitude_max)

  ; Ingress: first step of a contiguous in_window=1 block
  ingress_flags = bytarr(npts)
  ingress_flags[0] = in_window[0]
  if npts gt 1 then $
    ingress_flags[1:*] = in_window[1:*] and (1b - in_window[0:npts-2])

  ; Egress: last step of a contiguous in_window=1 block
  egress_flags = bytarr(npts)
  egress_flags[npts-1] = in_window[npts-1]
  if npts gt 1 then $
    egress_flags[0:npts-2] = in_window[0:npts-2] and (1b - in_window[1:*])

  i_ingress_all = where(ingress_flags, n_ingress)
  i_egress_all  = where(egress_flags,  n_egress)

  ; Template for one event record
  event_template = { $
    i_ingress:    0l, $
    i_egress:     0l, $
    t_ingress:    0.0d, $
    t_egress:     0.0d, $
    duration:     0.0d, $
    tang_alt_min: 0.0d, $
    t_min:        0.0d, $
    lat_min:      0.0d, $
    lon_min:      0.0d  $
    }

  n_complete = 0l
  events = -1  ; will be replaced with array if events found

  if n_ingress gt 0 and n_egress gt 0 then begin

    n_pairs = n_ingress < n_egress
    event_buf = replicate(event_template, n_pairs)

    for k = 0l, n_pairs - 1l do begin
      ii = i_ingress_all[k]
      ie = i_egress_all[k]

      ; Skip partial events at simulation boundaries and malformed pairs
      if ii gt 0 and ie lt npts-1 and ie ge ii then begin

        ; Check completeness: minimum tangent altitude must reach the surface
        ta_seg = tang_alt[ii:ie]
        ta_min = min(ta_seg, i_min_rel)
        if ta_min le 0.0d then begin
          event_buf[n_complete].i_ingress    = ii
          event_buf[n_complete].i_egress     = ie
          event_buf[n_complete].t_ingress    = t[ii]
          event_buf[n_complete].t_egress     = t[ie]
          event_buf[n_complete].duration     = t[ie] - t[ii]
          event_buf[n_complete].tang_alt_min = ta_min
          event_buf[n_complete].t_min        = t[ii + i_min_rel]
          event_buf[n_complete].lat_min      = tang_lat[ii + i_min_rel]
          event_buf[n_complete].lon_min      = tang_lon[ii + i_min_rel]
          n_complete++
        endif

      endif
    endfor

    if n_complete gt 0 then events = event_buf[0:n_complete-1]

  endif

  ; ===========================================================================
  ; 9. PRINT RESULTS
  ; ===========================================================================
  print, ''
  print, '================================================='
  print, format = '(A,I0,A)', 'Complete occultations found: ', n_complete, ''
  print, '================================================='

  if n_complete gt 0 then begin
    print, ''
    print, format = '(A6,A14,A14,A12,A16,A10,A10)', $
      '#', 't_ingress(s)', 't_egress(s)', 'dur(s)', 'alt_min(km)', 'lat(deg)', 'lon(deg)'
    print, string(replicate(45b, 82))  ; dashes
    for k = 0l, n_complete - 1l do begin
      print, format = '(I6,F14.1,F14.1,F12.1,F16.2,F10.2,F10.2)', $
        k + 1, $
        events[k].t_ingress, $
        events[k].t_egress, $
        events[k].duration, $
        events[k].tang_alt_min / 1000.d0, $
        events[k].lat_min, $
        events[k].lon_min
    endfor
    print, ''
  endif

  print, '================================================='
  print, ''

  ; ===========================================================================
  ; 10. RETURN STRUCTURE
  ; ===========================================================================
  survey = { $
    time:       t, $
    tang_alt:   tang_alt, $
    tang_lat:   tang_lat, $
    tang_lon:   tang_lon, $
    n_int:      n_int, $
    n_complete: n_complete, $
    events:     events $
    }

end
