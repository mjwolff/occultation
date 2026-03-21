;+
; NAME:
;   OSSE_TEST_INSTALL
;
; PURPOSE:
;   Verify that the occultation ray-tracer library is correctly installed
;   and functional. Tests the three core capabilities: loading parameters,
;   coordinate conversion, and ray tracing through the atmosphere.
;
; CATEGORY:
;   Installation Testing
;
; CALLING SEQUENCE:
;   osse_test_install
;
; INPUTS:
;   None
;
; OUTPUTS:
;   Prints test results to console (PASS/FAIL for each test)
;
; EXAMPLE:
;   From command line:
;     idl -e "osse_test_install"
;
;   From IDL prompt:
;     IDL> cd, '/path/to/occultation'
;     IDL> .run osse_test_install
;
; MODIFICATION HISTORY:
;   2026-03-21: Initial implementation
;-

pro osse_test_install
  compile_opt idl2

  ; Setup path
  !path = 'src' + ':' + !path

  print, ''
  print, '========================================='
  print, 'Testing Occultation Library Installation'
  print, '========================================='
  print, ''

  ; Test 1: Load Mars atmospheric parameters
  print, 'Test 1: Loading Mars parameters...'
  params = osse_mars_params()
  print, '  PASS - Mars parameters loaded'
  print, '  R_MARS   = ', params.r_mars / 1000.d, ' km'
  print, '  N_LAYERS = ', params.n_layers
  print, ''

  ; Test 2: Coordinate conversion round-trip
  print, 'Test 2: Coordinate conversion (lat/lon/alt -> Cartesian -> lat/lon/alt)...'
  lat_in = 30.0d & lon_in = 45.0d & alt_in = 400.0d3
  pos = osse_latlon_to_cartesian(lat_in, lon_in, alt_in)
  coords = osse_cartesian_to_latlon(pos)
  err = abs(coords.latitude - lat_in) + abs(coords.longitude - lon_in) $
      + abs(coords.altitude - alt_in)
  if err lt 1.0d then begin
    print, '  PASS - Round-trip error < 1 m'
  endif else begin
    print, '  FAIL - Round-trip error: ', err, ' m'
    return
  endelse
  print, '  lat: ', lat_in, ' -> ', coords.latitude, ' deg'
  print, '  lon: ', lon_in, ' -> ', coords.longitude, ' deg'
  print, '  alt: ', alt_in/1000.d, ' -> ', coords.altitude/1000.d, ' km'
  print, ''

  ; Test 3: Ray trace through atmosphere
  ; Satellite at 400 km altitude, ray angled to produce a 50 km tangent altitude
  print, 'Test 3: Ray tracing through Mars atmosphere...'
  R = params.r_mars
  sat_pos = [R + 400.0d3, 0.0d, 0.0d]
  impact_target = R + 50.0d3
  sin_alpha = impact_target / (R + 400.0d3)
  cos_alpha = sqrt(1.0d - sin_alpha ^ 2)
  sun_dir = [-cos_alpha, sin_alpha, 0.0d]
  osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, intersections, $
    n_intersect, params = params
  if n_intersect gt 0 and abs(tang_alt - 50.0d3) lt 1.0d then begin
    print, '  PASS - Ray trace completed'
  endif else begin
    print, '  FAIL - Unexpected result'
    return
  endelse
  print, '  Tangent altitude: ', tang_alt / 1000.d, ' km'
  print, '  Layers intersected: ', n_intersect
  print, ''

  print, '========================================='
  print, 'All tests PASSED! Installation verified.'
  print, '========================================='
  print, ''
end
