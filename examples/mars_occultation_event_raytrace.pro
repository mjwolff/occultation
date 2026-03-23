;+
; NAME:
;   MARS_OCCULTATION_EVENT_RAYTRACE
;
; PURPOSE:
;   Ray-trace each spacecraft position within a single occultation event
;   from a survey structure. Computes tangent altitude, layer intersections,
;   transmittance, and pathlength for every time step in the event window.
;   No orbit propagation is required; all position and solar geometry are
;   drawn directly from the survey struct.
;
; CALLING SEQUENCE:
;   mars_occultation_event_raytrace, survey, event_index, result
;
; INPUTS:
;   survey      - structure returned by mars_occultation_survey; must contain
;                 .sat_lat, .sat_lon, .sat_alt, .ss_lat, .ss_lon, .time,
;                 .tang_alt, and .events
;   event_index - integer index into survey.events selecting which event to
;                 process (0-based)
;
; OUTPUTS:
;   result - structure containing:
;     .time         - time array for the event window (s from epoch)
;     .sat_lat      - spacecraft latitude at each step (deg)
;     .sat_lon      - spacecraft longitude at each step (deg)
;     .sat_alt      - spacecraft altitude at each step (km)
;     .tang_alt     - tangent altitude at each step (km)
;     .tang_lat     - tangent point latitude at each step (deg)
;     .tang_lon     - tangent point longitude at each step (deg)
;     .n_int        - number of atmospheric layers intersected at each step
;     .transmittance - line-of-sight transmittance at each step
;     .path_info    - pointer array; each element points to a pathlength
;                     struct {path_length, path_longitude, path_latitude,
;                     path_altitude} if n_int > 0, otherwise unallocated
;     .event        - the event struct for the processed event
;
; KEYWORDS:
;   VERBOSE - if set, print tangent altitude and transmittance at every step
;
; EXAMPLE:
;   mars_occultation_survey, survey=s, norbits=5
;   mars_occultation_event_raytrace, s, 0, result
;   plot, result.time, result.transmittance
;
; MODIFICATION HISTORY:
;   2026-03-23: Initial implementation
;-

pro mars_occultation_event_raytrace, survey, event_index, result, verbose = verbose
  compile_opt idl2

  ; ===========================================================================
  ; 0. PATH SETUP
  ; ===========================================================================
  this_dir = file_dirname(routine_filepath('mars_occultation_event_raytrace'))
  sp_src = this_dir + '/../../satellite_position/src'
  occ_src = this_dir + '/../src'
  !path = expand_path(sp_src) + ':' + expand_path(occ_src) + ':' + !path

  params = osse_mars_params()

  ; ===========================================================================
  ; 1. EXTRACT EVENT WINDOW
  ; ===========================================================================
  ev = survey.events[event_index]
  i0 = ev.i_start
  i1 = ev.i_end
  npts = i1 - i0 + 1

  time    = survey.time[i0:i1]
  sat_lat = survey.sat_lat[i0:i1]
  sat_lon = survey.sat_lon[i0:i1]
  sat_alt = survey.sat_alt[i0:i1]
  ss_lon  = survey.ss_lon[i0:i1]
  ss_lat  = survey.ss_lat            ; scalar

  print, ''
  print, '================================================='
  print, format = '(A,I0,A,A)', 'EVENT ', event_index, '  type=', ev.type
  print, format = '(A,F10.1,A,F10.1,A)', 'Time window: ', ev.t_start_interp, $
    ' to ', ev.t_end_interp, ' s'
  print, format = '(A,I0)', 'Steps in window: ', npts
  print, '================================================='
  print, ''

  ; ===========================================================================
  ; 2. ALLOCATE OUTPUT ARRAYS
  ; ===========================================================================
  tang_alt      = dblarr(npts)
  tang_lat      = dblarr(npts)
  tang_lon      = dblarr(npts)
  n_int_arr     = lonarr(npts)
  transmittance = dblarr(npts)
  path_info     = ptrarr(npts, /allocate_heap)

  ; ===========================================================================
  ; 3. RAY TRACE LOOP
  ; ===========================================================================
  for i = 0l, npts - 1l do begin
    sat_pos = osse_latlon_to_cartesian(sat_lat[i], sat_lon[i], sat_alt[i])
    sun_dir = osse_sspt_to_sun_direction(ss_lat, ss_lon[i], sat_position = sat_pos)

    osse_trace_ray_occultation_3d, sat_pos, sun_dir, ta, intersections, n_int, $
      params = params

    tang_alt[i]  = ta
    n_int_arr[i] = n_int

    ; Tangent point coordinates
    s_tp = -total(sat_pos * sun_dir)
    tp = osse_cartesian_to_latlon(sat_pos + s_tp * sun_dir)
    tang_lat[i] = tp.latitude
    tang_lon[i] = tp.longitude

    ; Transmittance
    transmittance[i] = osse_calculate_transmittance(sat_pos, sun_dir, $
      intersections, n_int, params = params)

    ; Pathlength struct (only when ray intersects atmosphere)
    if n_int gt 0 then begin
      osse_construct_pathlength, intersections, s_inbound, s_outbound, params = params
      s_points = [s_inbound, s_tp, s_outbound]
      n_s = n_elements(s_points)
      pts = fltarr(3, n_s)
      for j = 0, n_s - 1 do begin
        res = osse_cartesian_to_latlon(sat_pos + s_points[j] * sun_dir)
        pts[*, j] = [res.longitude, res.latitude, res.altitude]
      endfor
      *path_info[i] = { $
        path_length:    s_points, $
        path_longitude: reform(pts[0, *]), $
        path_latitude:  reform(pts[1, *]), $
        path_altitude:  reform(pts[2, *]) }
    endif

    if keyword_set(verbose) then $
      print, format = '(I6,A,F10.1,A,F8.2,A,I4,A,F8.5)', $
        i, '  t=', time[i], '  tang_alt=', ta, ' km  n_int=', n_int, $
        '  T=', transmittance[i]
  endfor

  ; ===========================================================================
  ; 4. PRINT SUMMARY TABLE
  ; ===========================================================================
  print, format = '(A6,A12,A10,A6,A12)', '#', 't(s)', 'tang_alt', 'n_int', 'transmittance'
  print, string(replicate(45b, 46))
  for i = 0l, npts - 1l do $
    print, format = '(I6,F12.1,F10.2,I6,F12.5)', $
      i, time[i], tang_alt[i], n_int_arr[i], transmittance[i]
  print, ''

  ; ===========================================================================
  ; 5. RETURN RESULT
  ; ===========================================================================
  result = { $
    time:          time, $
    sat_lat:       sat_lat, $
    sat_lon:       sat_lon, $
    sat_alt:       sat_alt, $
    tang_alt:      tang_alt, $
    tang_lat:      tang_lat, $
    tang_lon:      tang_lon, $
    n_int:         n_int_arr, $
    transmittance: transmittance, $
    path_info:     path_info, $
    event:         ev $
    }
end
