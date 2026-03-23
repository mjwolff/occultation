; ===============================================================================
; PRO: test_osse_cartesian_to_latlon
;
; Tests for osse_cartesian_to_latlon
; ===============================================================================
pro test_osse_cartesian_to_latlon
  compile_opt idl2

  print, ''
  print, '========================================='
  print, 'TEST: osse_cartesian_to_latlon'
  print, '========================================='
  print, ''

  params = osse_mars_params()

  ; Test 1: Position on +x axis → equator, 0° lon
  print, 'Test 1: +x axis at 400 km alt'
  pos = [params.r_mars + 400.0d0, 0.0d, 0.0d]
  coords = osse_cartesian_to_latlon(pos)
  print, format = '(A,3F10.2)', '  lat,lon,km: ', $
    coords.latitude, coords.longitude, coords.altitude
  print, format = '(A)',        '  Expected:   0.00, 0.00, 400.00'
  print, ''

  ; Test 2: Position on +z axis → north pole
  print, 'Test 2: +z axis at 500 km alt'
  pos = [0.0d, 0.0d, params.r_mars + 500.0d0]
  coords = osse_cartesian_to_latlon(pos)
  print, format = '(A,3F10.2)', '  lat,lon,km: ', $
    coords.latitude, coords.longitude, coords.altitude
  print, format = '(A)',        '  Expected:   90.00, 0.00, 500.00'
  print, ''

  ; Test 3: Guard case — position at Mars center returns altitude = -R_MARS
  print, 'Test 3: Mars center (guard case)'
  coords = osse_cartesian_to_latlon([0.0d, 0.0d, 0.0d])
  print, format = '(A,F10.2,A)', '  Altitude km (expect -3397.00): ', $
    coords.altitude, ' km'
  print, ''

  ; Test 4: Round-trip — Cartesian computed from known lat/lon/alt should recover
  print, 'Test 4: Round-trip lat/lon/alt recovery'
  lat_in = 33.5d & lon_in = 217.3d & alt_in = 150.0d0
  pos = osse_latlon_to_cartesian(lat_in, lon_in, alt_in)
  coords = osse_cartesian_to_latlon(pos)
  print, format = '(A,3F10.3)', '  Input  (lat,lon,km): ', lat_in, lon_in, alt_in
  print, format = '(A,3F10.3)', '  Output (lat,lon,km): ', $
    coords.latitude, coords.longitude, coords.altitude
  print, ''

  ; Test 5: Position on -x axis → equator, lon=180°
  print, 'Test 5: -x axis at 400 km alt (expect lat=0, lon=180)'
  pos = [-(params.r_mars + 400.0d0), 0.0d, 0.0d]
  coords = osse_cartesian_to_latlon(pos)
  print, format = '(A,3F10.2)', '  lat,lon,km: ', $
    coords.latitude, coords.longitude, coords.altitude
  print, format = '(A)',        '  Expected:   0.00, 180.00, 400.00'
  print, ''

  ; Test 6: Position on -z axis → south pole
  print, 'Test 6: -z axis at 500 km alt (expect lat=-90)'
  pos = [0.0d, 0.0d, -(params.r_mars + 500.0d0)]
  coords = osse_cartesian_to_latlon(pos)
  print, format = '(A,3F10.2)', '  lat,lon,km: ', $
    coords.latitude, coords.longitude, coords.altitude
  print, format = '(A)',        '  Expected:   -90.00, 0.00, 500.00'
  print, ''

  ; Test 7: Longitude output is in [0, 360) — never negative
  print, 'Test 7: Longitude in [0,360) for position in 3rd quadrant (expect lon~270)'
  pos = [0.0d, -(params.r_mars + 300.0d0), 0.0d]  ; -y axis → lon=270°
  coords = osse_cartesian_to_latlon(pos)
  print, format = '(A,F10.2)', '  lon (expect 270.00): ', coords.longitude
  print, ''

  print, '========================================='
  print, 'test_osse_cartesian_to_latlon complete'
  print, '========================================='
  print, ''
end
