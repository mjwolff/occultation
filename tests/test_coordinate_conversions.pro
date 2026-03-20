; ===============================================================================
; PRO: test_coordinate_conversions
;
; Test routine to validate coordinate conversions
; ===============================================================================
pro test_coordinate_conversions
  compile_opt idl2

  print, ''
  print, '========================================='
  print, 'COORDINATE CONVERSION TESTS'
  print, '========================================='
  print, ''

  ; Get Mars parameters
  params = osse_mars_params()

  ; Test 1: Equator, 0° longitude, 400 km altitude
  print, 'Test 1: Satellite at equator, 0° lon, 400 km alt'
  lat = 0.0d
  lon = 0.0d
  alt = 400.0d3
  pos = osse_latlon_to_cartesian(lat, lon, alt)
  print, format = '(A,3F12.1)', '  Cartesian position (m):  ', pos
  print, format = '(A,F10.1)', '  Expected x:              ', params.r_mars + 400.0d3

  ; Test round-trip conversion
  coords = osse_cartesian_to_latlon(pos)
  print, format = '(A,3F10.2)', '  Round-trip (lat,lon,alt):', $
    coords.latitude, coords.longitude, coords.altitude / 1000.0d
  print, ''

  ; Test 2: North pole, 500 km altitude
  print, 'Test 2: Satellite at north pole, 500 km alt'
  lat = 90.0d
  lon = 0.0d ; Longitude undefined at pole
  alt = 500.0d3
  pos = osse_latlon_to_cartesian(lat, lon, alt)
  print, format = '(A,3F12.1)', '  Cartesian position (m):  ', pos
  print, format = '(A,F10.1)', '  Expected z:              ', params.r_mars + 500.0d3
  print, ''

  ; Test 3: 45° N, 90° E, 300 km altitude
  print, 'Test 3: Satellite at 45°N, 90°E, 300 km alt'
  lat = 45.0d
  lon = 90.0d
  alt = 300.0d3
  pos = osse_latlon_to_cartesian(lat, lon, alt)
  print, format = '(A,3F12.1)', '  Cartesian position (m):  ', pos

  coords = osse_cartesian_to_latlon(pos)
  print, format = '(A,3F10.2)', '  Round-trip (lat,lon,alt):', $
    coords.latitude, coords.longitude, coords.altitude / 1000.0d
  print, ''

  ; Test 4: Sun direction calculation
  print, 'Test 4: Sun direction from sub-solar point'
  print, '  Satellite: 0°N, 0°E, 400 km alt'
  print, '  Sub-solar: 0°N, 180°E (opposite side)'
  lat = 0.0d
  lon = 0.0d
  alt = 400.0d3
  pos = osse_latlon_to_cartesian(lat, lon, alt)

  ss_lat = 0.0d
  ss_lon = 180.0d
  sun_dir = osse_sspt_to_sun_direction(pos, ss_lat, ss_lon)
  print, format = '(A,3F10.6)', '  Sun direction vector:    ', sun_dir
  print, format = '(A,F10.6)', '  Magnitude (should be 1): ', sqrt(total(sun_dir ^ 2))
  print, ''

  ; Test 5: Different sub-solar point
  print, 'Test 5: Sun direction with offset sub-solar point'
  print, '  Satellite: 0°N, 0°E, 400 km alt'
  print, '  Sub-solar: 20°N, 45°E'
  ss_lat = 20.0d
  ss_lon = 45.0d
  sun_dir = osse_sspt_to_sun_direction(pos, ss_lat, ss_lon)
  print, format = '(A,3F10.6)', '  Sun direction vector:    ', sun_dir
  print, ''

  print, '========================================='
  print, 'Tests complete'
  print, '========================================='
  print, ''
end
