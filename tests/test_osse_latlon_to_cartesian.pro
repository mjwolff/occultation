; ===============================================================================
; PRO: test_osse_latlon_to_cartesian
;
; Tests for osse_latlon_to_cartesian
; ===============================================================================
pro test_osse_latlon_to_cartesian
  compile_opt idl2

  print, ''
  print, '========================================='
  print, 'TEST: osse_latlon_to_cartesian'
  print, '========================================='
  print, ''

  params = osse_mars_params()

  ; Test 1: Equator, 0° longitude, 400 km altitude → position on +x axis
  print, 'Test 1: Equator, 0° lon, 400 km alt'
  pos = osse_latlon_to_cartesian(0.0d, 0.0d, 400.0d3)
  print, format = '(A,3F12.1)', '  Cartesian (m):   ', pos
  print, format = '(A,F12.1)',  '  Expected x (m):  ', params.r_mars + 400.0d3
  print, ''

  ; Test 2: North pole → position on +z axis
  print, 'Test 2: North pole, 500 km alt'
  pos = osse_latlon_to_cartesian(90.0d, 0.0d, 500.0d3)
  print, format = '(A,3F12.1)', '  Cartesian (m):   ', pos
  print, format = '(A,F12.1)',  '  Expected z (m):  ', params.r_mars + 500.0d3
  print, ''

  ; Test 3: 45°N, 90°E → position on +y/+z diagonal, x=0
  print, 'Test 3: 45°N, 90°E, 300 km alt'
  pos = osse_latlon_to_cartesian(45.0d, 90.0d, 300.0d3)
  print, format = '(A,3F12.1)', '  Cartesian (m):   ', pos
  print, format = '(A)',        '  Expected x=0, y=z'
  print, ''

  ; Test 4: Round-trip — recovered lat/lon/alt should match inputs
  print, 'Test 4: Round-trip lat/lon/alt recovery'
  lat_in = 33.5d & lon_in = 217.3d & alt_in = 150.0d3
  pos = osse_latlon_to_cartesian(lat_in, lon_in, alt_in)
  coords = osse_cartesian_to_latlon(pos)
  print, format = '(A,3F10.3)', '  Input  (lat,lon,km): ', lat_in, lon_in, alt_in/1000.d
  print, format = '(A,3F10.3)', '  Output (lat,lon,km): ', $
    coords.latitude, coords.longitude, coords.altitude/1000.d
  print, ''

  ; Test 5: South pole → position on -z axis
  print, 'Test 5: South pole, 500 km alt'
  pos = osse_latlon_to_cartesian(-90.0d, 0.0d, 500.0d3)
  print, format = '(A,3F12.1)', '  Cartesian (m):    ', pos
  print, format = '(A,F12.1)',  '  Expected z (m):   ', -(params.r_mars + 500.0d3)
  print, ''

  ; Test 6: Zero altitude — magnitude should equal R_MARS exactly
  print, 'Test 6: Zero altitude (surface), equator 0° lon'
  pos = osse_latlon_to_cartesian(0.0d, 0.0d, 0.0d)
  print, format = '(A,F12.1)', '  |pos| (m):        ', sqrt(total(pos^2))
  print, format = '(A,F12.1)', '  R_MARS (m):       ', params.r_mars
  print, ''

  ; Test 7: Longitude near 360° — round-trip should return lon=359.9, not negative
  print, 'Test 7: Longitude near 360° boundary (lon=359.9°)'
  pos = osse_latlon_to_cartesian(0.0d, 359.9d, 400.0d3)
  coords = osse_cartesian_to_latlon(pos)
  print, format = '(A,F10.3)', '  Round-trip lon (expect 359.900): ', coords.longitude
  print, ''

  ; Test 8: lon=0 and lon=360 produce the same Cartesian position to floating-point precision
  ; cos(360°) differs from cos(0°) by ~1e-16 in float64, giving ~0.15 m at Mars radius.
  print, 'Test 8: lon=0 and lon=360 give same Cartesian position (float64 precision)'
  pos0   = osse_latlon_to_cartesian(30.0d,   0.0d, 200.0d3)
  pos360 = osse_latlon_to_cartesian(30.0d, 360.0d, 200.0d3)
  diff = sqrt(total((pos0 - pos360)^2))
  print, format = '(A,E10.3)', '  |difference| m (expect < 1 m): ', diff
  print, ''

  print, '========================================='
  print, 'test_osse_latlon_to_cartesian complete'
  print, '========================================='
  print, ''
end
