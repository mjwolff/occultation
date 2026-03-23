; ===============================================================================
; PRO: test_osse_trace_ray_occultation_3d
;
; Tests for osse_trace_ray_occultation_3d
; ===============================================================================
pro test_osse_trace_ray_occultation_3d
  compile_opt idl2

  print, ''
  print, '========================================='
  print, 'TEST: osse_trace_ray_occultation_3d'
  print, '========================================='
  print, ''

  params = osse_mars_params()
  R = params.r_mars

  ; Test 1: Ray missing atmosphere — tangent altitude > 100 km
  ; Sat at 200 km alt, perpendicular ray → impact = R+200 km
  print, 'Test 1: Ray missing atmosphere (tangent alt 200 km > h_atm=100 km)'
  sat_pos = [R + 200.0d0, 0.0d, 0.0d]
  sun_dir = [0.0d, 1.0d, 0.0d]
  osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, isects, n_int, params = params
  print, format = '(A,F8.1)', '  Tangent alt km (expect 200): ', tang_alt
  print, format = '(A,I4)',   '  n_intersect (expect 0):      ', n_int
  print, ''

  ; Test 2: Ray hitting planet — nadir pointing
  print, 'Test 2: Ray hitting planet (direct nadir, expect n_int=0)'
  sat_pos = [R + 400.0d0, 0.0d, 0.0d]
  sun_dir = [-1.0d, 0.0d, 0.0d]
  osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, isects, n_int, params = params
  print, format = '(A,F8.1)', '  Tangent alt km (expect <0): ', tang_alt
  print, format = '(A,I4)',   '  n_intersect (expect 0):     ', n_int
  print, ''

  ; Test 3: Tangent ray at ~50.5 km altitude
  ; Angle sun_dir so impact_param = R + 50.5 km (between layer boundaries to
  ; avoid the debug STOP in osse_construct_pathlength — see TODO item 10).
  ; Layers with r_inner < impact are skipped, so layers 51-99 km intersected = 49.
  print, 'Test 3: Tangent ray at ~50.5 km (expect 49 layers)'
  sat_pos = [R + 400.0d0, 0.0d, 0.0d]
  impact_target = R + 50.5d0
  sin_alpha = impact_target / (R + 400.0d0)
  cos_alpha = sqrt(1.0d - sin_alpha ^ 2)
  sun_dir = [-cos_alpha, sin_alpha, 0.0d]
  osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, isects, n_int, params = params
  print, format = '(A,F8.2)', '  Tangent alt km (expect ~50.5): ', tang_alt
  print, format = '(A,I4)',   '  n_intersect (expect 49):       ', n_int
  print, ''

  ; Test 4: Cross-check tang_alt against osse_cartesian_to_latlon
  print, 'Test 4: tang_alt vs geometric tangent point (expect diff < 10 m)'
  s_tangent     = -total(sat_pos * sun_dir)
  tangent_point = sat_pos + s_tangent * sun_dir
  res = osse_cartesian_to_latlon(tangent_point)
  print, format = '(A,F10.4)', '  tang_alt from trace (km):     ', tang_alt
  print, format = '(A,F10.4)', '  altitude from latlon (km):    ', res.altitude
  print, format = '(A,F10.6)', '  |difference| km (expect <0.01):', abs(tang_alt - res.altitude)
  print, ''

  ; Test 5: Satellite inside atmosphere (80 km alt), perpendicular ray
  ; impact = R+80 km — some shells will be entered from inside (Case 2 geometry).
  ; Layers with r_inner >= R+80 km are processed: layers 80-99 = 20 layers.
  print, 'Test 5: Satellite inside atmosphere at 80 km (expect 20 layers)'
  sat_pos = [R + 80.0d0, 0.0d, 0.0d]
  sun_dir = [0.0d, 1.0d, 0.0d]
  osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, isects, n_int, params = params
  print, format = '(A,F8.1)', '  Tangent alt km (expect 80.0): ', tang_alt
  print, format = '(A,I4)',   '  n_intersect (expect 20):      ', n_int
  print, ''

  ; Test 6: Impact parameter exactly at top of atmosphere (tangent alt = 100 km)
  ; Passes the initial check (NOT gt), but all layers have r_inner < impact → skipped.
  print, 'Test 6: Tangent at exactly 100 km (top of atmosphere, expect n_int=0)'
  sat_pos = [R + 100.0d0, 0.0d, 0.0d]
  sun_dir = [0.0d, 1.0d, 0.0d]
  osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, isects, n_int, params = params
  print, format = '(A,F8.1)', '  Tangent alt km (expect 100.0): ', tang_alt
  print, format = '(A,I4)',   '  n_intersect (expect 0):        ', n_int
  print, ''

  print, '========================================='
  print, 'test_osse_trace_ray_occultation_3d complete'
  print, '========================================='
  print, ''
end
