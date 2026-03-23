;+
; NAME:
;   MARS_OCCULTATION_SURVEY
;
; PURPOSE:
;   Survey solar occultation events over multiple orbits. Propagates a
;   TGO-like orbit and computes the tangent altitude at each time step,
;   then identifies and classifies occultation events.
;
;   Two event types are detected:
;
;     INGRESS — tangent altitude is decreasing with time.
;               Starts when tang_alt crosses altitude_max (descending).
;               Ends   when tang_alt crosses 0 km (descending).
;
;     EGRESS  — tangent altitude is increasing with time.
;               Starts when tang_alt crosses 0 km (ascending).
;               Ends   when tang_alt crosses altitude_max (ascending).
;
;   A complete solar occultation consists of one INGRESS event followed
;   by one EGRESS event, separated by a sub-zero gap where the ray passes
;   through the planet. Only event pairs where both halves occur within the
;   simulated interval are reported; partial events at the simulation
;   boundaries are discarded.
;
;   Designed as a lightweight survey tool; use mars_occultation_orbit for
;   detailed pathlength analysis of specific events found here.
;
; USAGE:
;   IDL> mars_occultation_survey
;   IDL> mars_occultation_survey, norbits=10, dt=5.0
;   IDL> mars_occultation_survey, altitude_max=80.0d0
;
; KEYWORDS:
;   SURVEY       - named output variable that receives the result structure
;                  (see OUTPUTS below). Must be supplied to retrieve results.
;   NORBITS      - number of orbits to simulate (default: 5)
;   DT           - time step in seconds (default: orbital period / 1000).
;                  At 400 km altitude the tangent altitude changes at
;                  ~1-3 km/s during limb crossing; the default dt gives
;                  ~100-300 m resolution in tangent altitude per event.
;   ALTITUDE_MAX - upper tangent altitude boundary in km
;                  (default: params.h_atm = 100 km).
;                  Events are bounded by crossings of this level and 0 km.
;   LSUBS        - areocentric solar longitude in degrees (default: 90.0,
;                  northern summer solstice). Controls the sub-solar
;                  latitude via sp_calculate_subsolar_latitude.
;   VERBOSE      - if set, print tangent altitude at every time step
;
; INPUTS (configured in the USER CONFIGURATION sections below):
;   Orbital elements: a, e, i, raan, omega, M0
;   Solar geometry:   LsubS (keyword, default 90 deg), ss_lon_at_t0
;
; OUTPUTS:
;   Structure 'survey' containing:
;     .time       - time array (s from epoch)
;     .tang_alt   - tangent altitude at each step (km)
;     .tang_lat   - tangent point latitude (deg)
;     .tang_lon   - tangent point longitude (deg)
;     .n_int      - number of atmospheric layers intersected
;     .n_ingress  - number of ingress events found
;     .n_egress   - number of egress events found
;     .events     - array of event structs sorted by t_start (see below),
;                   or scalar -1 if no events found
;
;   Each event struct contains:
;     .type        - 'ING' (tangent alt decreasing, altitude_max -> 0)
;                    or 'EGR' (tangent alt increasing, 0 -> altitude_max)
;     .ingress     - byte flag: 1 for ingress event, 0 for egress event.
;                    Allows array filtering: idx = where(events.ingress)
;     .i_start     - index of first sample inside the event window:
;                    ING: first sample with tang_alt < altitude_max
;                    EGR: first sample with tang_alt >= 0
;     .i_end       - index of last sample inside the event window:
;                    ING: last sample with tang_alt >= 0
;                    EGR: last sample with tang_alt < altitude_max
;     .t_start_interp - linearly interpolated time of the start threshold crossing (s):
;                    ING: when tang_alt descends through altitude_max
;                    EGR: when tang_alt ascends through 0 km
;     .t_end_interp - linearly interpolated time of the end threshold crossing (s):
;                    ING: when tang_alt descends through 0 km
;                    EGR: when tang_alt ascends through altitude_max
;     .t_start_nn  - time of the nearest sampled step at the start crossing (s);
;                    equals t[i_start] (first sample inside the event window)
;     .t_end_nn    - time of the nearest sampled step at the end crossing (s);
;                    equals t[i_end] (last sample inside the event window)
;     .duration    - t_end_interp - t_start_interp (s)
;     .tang_alt_min - minimum tangent altitude within the event window (km);
;                    near 0 for both event types (deepest atmospheric point)
;     .lat_min     - tangent point latitude at minimum tangent altitude (deg)
;     .lon_min     - tangent point longitude at minimum tangent altitude (deg)
;     .tang_alt_max - maximum tangent altitude within the event window (km);
;                    near altitude_max for both event types
;     .lat_max     - tangent point latitude at maximum tangent altitude (deg)
;     .lon_max     - tangent point longitude at maximum tangent altitude (deg)
;
; NOTES:
;   - Uses ROUTINE_FILEPATH for path setup (IDL 8.0+)
;   - ss_lon_at_t0 is a mission parameter: the Mars-fixed longitude facing
;     the Sun at epoch t0.
;   - Detection proceeds in two steps: (1) find complete occultation spans
;     (altitude_max crossing in to altitude_max crossing out) that are fully
;     contained within the simulation; (2) split each span at its 0-km
;     crossing to produce the ING and EGR half-events.
;   - Crossing times (t_start, t_end) are estimated by linear interpolation
;     between the two bracketing samples on either side of each threshold.
;     The nearest-sample equivalents (t_start_nn, t_end_nn) are provided for
;     cases where the sampled grid is sufficient or interpolation is not
;     desired. The difference |t_start - t_start_nn| is at most dt/2 and is
;     typically much smaller for smooth tangent altitude profiles.
;
; MODIFICATION HISTORY:
;   2026-03-21: Initial implementation
;   2026-03-21: Redesign event detection to report ingress and egress
;               half-events separately, each bounded by altitude_max and 0
;   2026-03-23: Add interpolated t_start/t_end and nearest-sample t_start_nn/t_end_nn
;-

pro mars_occultation_survey, survey = survey, $
  norbits = norbits, dt = dt, $
  altitude_max = altitude_max, lsubs = LsubS, verbose = verbose
  compile_opt idl2

  ; ===========================================================================
  ; 0. IDL PATH SETUP
  ; ===========================================================================
  this_dir = file_dirname(routine_filepath('mars_occultation_survey'))
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

  ; ===========================================================================
  ; 2. SIMULATION TIME
  ; ===========================================================================
  if n_elements(norbits) eq 0 then norbits = 5
  period = 2.0d0 * !dpi * sqrt(elements.a ^ 3 / mars.mu)
  if n_elements(dt) eq 0 then dt = period / 1000.0d0
  npts = long(norbits * period / dt) + 1l
  t = dindgen(npts) * dt

  ; ===========================================================================
  ; 3. SUB-SOLAR GEOMETRY  — USER CONFIGURATION
  ; ===========================================================================
  if n_elements(LsubS) eq 0 then LsubS = 90.0d0 ; default: northern summer solstice
  ss_lat = sp_calculate_subsolar_latitude(LsubS, /degrees)
  ss_lon_at_t0 = 0.0d0 ; sub-solar longitude at epoch t0 (degrees)

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
  print, format = '(A,F8.2,A)', 'Orbital period:       ', period / 60.0d0, ' min'
  print, format = '(A,I0)', 'Orbits simulated:     ', norbits
  print, format = '(A,F6.1,A)', 'Time step:            ', dt, ' s'
  print, format = '(A,I0)', 'Total time steps:     ', npts
  print, format = '(A,F6.2,A)', 'Sub-solar latitude:   ', ss_lat, ' deg'
  print, format = '(A,F6.2,A)', 'Altitude max:         ', altitude_max, ' km'
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
  n_int = lonarr(npts)

  print, 'Computing tangent altitudes...'

  for i = 0l, npts - 1l do begin
    sat_alt = orb[i].alt ; km
    sat_pos = osse_latlon_to_cartesian(orb[i].lat, orb[i].lon, sat_alt)

    ss_lon = sp_calculate_subsolar_longitude(t[i], t0, ss_lon_at_t0, mars)
    sun_dir = osse_sspt_to_sun_direction(ss_lat, ss_lon, sat_position = sat_pos)

    osse_trace_ray_occultation_3d, sat_pos, sun_dir, ta, isects, ni, params = params

    tang_alt[i] = ta
    n_int[i] = ni

    ; Tangent point position
    s_tp = -total(sat_pos * sun_dir)
    tp = osse_cartesian_to_latlon(sat_pos + s_tp * sun_dir)
    tang_lat[i] = tp.latitude
    tang_lon[i] = tp.longitude

    if keyword_set(verbose) then $
      print, format = '(I6,A,E14.6,A,F8.2,A,F7.2,A,F7.2)', $
      i, '  t=', t[i], '  tang_alt=', ta, ' km' + $
      '  lat=', tang_lat[i], '  lon=', tang_lon[i]
  endfor

  ; ===========================================================================
  ; 8. EVENT DETECTION
  ; ===========================================================================
  ; Strategy:
  ; Step 1 — find complete occultation spans: contiguous intervals where
  ; tang_alt < altitude_max, bounded by crossings of altitude_max,
  ; and fully contained within the simulation (not clipped at t=0
  ; or t=end).  A span is complete if min(tang_alt) crosses 0.
  ;
  ; Step 2 — split each complete span at its 0-km crossing:
  ; INGRESS half: tang_alt descends from altitude_max to 0
  ; EGRESS  half: tang_alt ascends  from 0 to altitude_max

  ; --- Step 1: altitude_max crossing flags ---
  ; Seed boundaries so that a simulation starting/ending mid-span produces
  ; a flagged pair whose i_start=0 or i_end=npts-1 is later excluded.
  span_start_flags = bytarr(npts)
  span_start_flags[0] = (tang_alt[0] lt altitude_max)
  if npts gt 1 then $
    span_start_flags[1 : *] = (tang_alt[1 : *] lt altitude_max) and $
      (tang_alt[0 : npts - 2] ge altitude_max)

  span_end_flags = bytarr(npts)
  span_end_flags[npts - 1] = (tang_alt[npts - 1] lt altitude_max)
  if npts gt 1 then $
    span_end_flags[0 : npts - 2] = (tang_alt[0 : npts - 2] lt altitude_max) and $
      (tang_alt[1 : *] ge altitude_max)

  i_span_start = where(span_start_flags, n_span_start)
  i_span_end = where(span_end_flags, n_span_end)

  ; --- Step 2: split spans into ING/EGR half-events ---
  event_template = { $
    type: 'ING', $ ; 'ING' (descending) or 'EGR' (ascending)
    ingress: 0b, $ ; 1 for ingress event, 0 for egress event
    i_start: 0l, $
    i_end: 0l, $
    t_start_interp: 0.0d, $ ; interpolated crossing time at event start
    t_end_interp: 0.0d, $   ; interpolated crossing time at event end
    t_start_nn: 0.0d, $     ; nearest sample time at event start
    t_end_nn: 0.0d, $       ; nearest sample time at event end
    duration: 0.0d, $
    tang_alt_min: 0.0d, $
    lat_min: 0.0d, $
    lon_min: 0.0d, $
    tang_alt_max: 0.0d, $
    lat_max: 0.0d, $
    lon_max: 0.0d $
    }

  n_ingress = 0l
  n_egress = 0l
  events = -1

  n_spans = n_span_start < n_span_end

  if n_spans gt 0 then begin
    event_buf = replicate(event_template, 2l * n_spans)
    n_events = 0l

    for k = 0l, n_spans - 1l do begin
      ii = i_span_start[k]
      ie = i_span_end[k]

      ; Skip boundary-clipped spans and malformed pairs
      if ii gt 0 and ie lt npts - 1 and ie gt ii then begin
        ; Locate the 0-km descent crossing within this span
        i_zd = where(tang_alt[ii : ie - 1] ge 0.0d and tang_alt[ii + 1 : ie] lt 0.0d, n_zd)
        ; Locate the 0-km ascent crossing within this span
        i_za = where(tang_alt[ii : ie - 1] lt 0.0d and tang_alt[ii + 1 : ie] ge 0.0d, n_za)

        if n_zd ge 1 and n_za ge 1 then begin
          j_ing_end = ii + i_zd[0] ; last step with tang_alt >= 0 before descent
          j_egr_start = ii + i_za[0] + 1 ; first step with tang_alt >= 0 after ascent

          ; --- INGRESS event: altitude_max -> 0 (decreasing) ---
          ; Interpolate exact altitude_max crossing (descending) for t_start
          frac_s = (altitude_max - tang_alt[ii-1]) / (tang_alt[ii] - tang_alt[ii-1])
          t_ing_start = t[ii-1] + frac_s * (t[ii] - t[ii-1])
          ; Interpolate exact 0-km crossing (descending) for t_end
          frac_e = (0.0d - tang_alt[j_ing_end]) / (tang_alt[j_ing_end+1] - tang_alt[j_ing_end])
          t_ing_end = t[j_ing_end] + frac_e * (t[j_ing_end+1] - t[j_ing_end])
          ta_min = min(tang_alt[ii : j_ing_end], i_min_rel)
          ta_max = max(tang_alt[ii : j_ing_end], i_max_rel)
          event_buf[n_events].type    = 'ING'
          event_buf[n_events].ingress = 1b
          event_buf[n_events].i_start = ii
          event_buf[n_events].i_end = j_ing_end
          event_buf[n_events].t_start_interp = t_ing_start
          event_buf[n_events].t_end_interp   = t_ing_end
          event_buf[n_events].t_start_nn     = t[ii]
          event_buf[n_events].t_end_nn       = t[j_ing_end]
          event_buf[n_events].duration       = t_ing_end - t_ing_start
          event_buf[n_events].tang_alt_min = ta_min
          event_buf[n_events].lat_min = tang_lat[ii + i_min_rel]
          event_buf[n_events].lon_min = tang_lon[ii + i_min_rel]
          event_buf[n_events].tang_alt_max = ta_max
          event_buf[n_events].lat_max = tang_lat[ii + i_max_rel]
          event_buf[n_events].lon_max = tang_lon[ii + i_max_rel]
          n_events++
          n_ingress++

          ; --- EGRESS event: 0 -> altitude_max (increasing) ---
          ; Interpolate exact 0-km crossing (ascending) for t_start
          frac_s = (0.0d - tang_alt[j_egr_start-1]) / (tang_alt[j_egr_start] - tang_alt[j_egr_start-1])
          t_egr_start = t[j_egr_start-1] + frac_s * (t[j_egr_start] - t[j_egr_start-1])
          ; Interpolate exact altitude_max crossing (ascending) for t_end
          frac_e = (altitude_max - tang_alt[ie]) / (tang_alt[ie+1] - tang_alt[ie])
          t_egr_end = t[ie] + frac_e * (t[ie+1] - t[ie])
          ta_min = min(tang_alt[j_egr_start : ie], i_min_rel)
          ta_max = max(tang_alt[j_egr_start : ie], i_max_rel)
          event_buf[n_events].type    = 'EGR'
          event_buf[n_events].ingress = 0b
          event_buf[n_events].i_start = j_egr_start
          event_buf[n_events].i_end = ie
          event_buf[n_events].t_start_interp = t_egr_start
          event_buf[n_events].t_end_interp   = t_egr_end
          event_buf[n_events].t_start_nn     = t[j_egr_start]
          event_buf[n_events].t_end_nn       = t[ie]
          event_buf[n_events].duration       = t_egr_end - t_egr_start
          event_buf[n_events].tang_alt_min = ta_min
          event_buf[n_events].lat_min = tang_lat[j_egr_start + i_min_rel]
          event_buf[n_events].lon_min = tang_lon[j_egr_start + i_min_rel]
          event_buf[n_events].tang_alt_max = ta_max
          event_buf[n_events].lat_max = tang_lat[j_egr_start + i_max_rel]
          event_buf[n_events].lon_max = tang_lon[j_egr_start + i_max_rel]
          n_events++
          n_egress++
        endif
      endif
    endfor

    if n_events gt 0 then events = event_buf[0 : n_events - 1]
  endif

  ; ===========================================================================
  ; 9. PRINT RESULTS
  ; ===========================================================================
  print, ''
  print, '================================================='
  print, format = '(A,I0,A,I0,A,I0,A)', $
    'Events found: ', n_ingress + n_egress, $
    '  (', n_ingress, ' ingress, ', n_egress, ' egress)'
  print, '================================================='

  if n_ingress + n_egress gt 0 then begin
    print, ''
    print, format = '(A6,A5,A14,A12,A14,A12,A10,A10,A10,A10,A10)', $
      '#', 'Type', 't_start_interp', 't_start_nn', 't_end_interp', 't_end_nn', $
      'dur(s)', 'alt_min(km)', 'alt_max(km)', 'lat_min', 'lon_min'
    print, string(replicate(45b, 117))
    for k = 0l, n_ingress + n_egress - 1l do begin
      print, format = '(I6,A5,F14.1,F12.1,F14.1,F12.1,F10.1,F10.2,F10.2,F10.2,F10.2)', $
        k + 1, $
        events[k].type, $
        events[k].t_start_interp, $
        events[k].t_start_nn, $
        events[k].t_end_interp, $
        events[k].t_end_nn, $
        events[k].duration, $
        events[k].tang_alt_min, $
        events[k].tang_alt_max, $
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
    time: t, $
    tang_alt: tang_alt, $
    tang_lat: tang_lat, $
    tang_lon: tang_lon, $
    n_int: n_int, $
    n_ingress: n_ingress, $
    n_egress: n_egress, $
    events: events $
    }
end
