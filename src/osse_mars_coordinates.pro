;+
; NAME:
;   OSSE_MARS_COORDINATES
;
; PURPOSE:
;   Coordinate conversion utilities for Mars occultation ray tracing
;   Converts between geodetic (lat/lon/alt) and Cartesian coordinates
;
; AUTHOR:
;   Mars Occultation Ray Tracing Team
;   Date: 2024
;
; USAGE:
;   .compile osse_mars_coordinates
;   sat_pos = osse_latlon_to_cartesian(lat, lon, alt)
;   sun_dir = osse_sspt_to_sun_direction(sat_pos, ss_lat, ss_lon)
;-

; ===============================================================================
; FUNCTION: osse_latlon_to_cartesian
;
; Converts satellite geodetic coordinates to Cartesian position vector
;
; INPUT:
; latitude  - Geodetic latitude in degrees (-90 to +90)
; Positive = North, Negative = South
; longitude - Longitude in degrees (0 to 360 or -180 to +180)
; Positive = East
; altitude  - Altitude above Mars surface in meters
;
; RETURNS:
; position - [3] array, Cartesian position vector in meters [x, y, z]
; x: toward 0° longitude
; y: toward 90° E longitude
; z: toward north pole
;
; COORDINATE SYSTEM:
; Mars-centered, Mars-fixed Cartesian coordinates
; Origin at Mars center of mass
; ===============================================================================
function osse_latlon_to_cartesian, latitude, longitude, altitude
  compile_opt idl2

  ; Get Mars parameters
  params = osse_mars_params()

  ; Convert to radians
  lat_rad = latitude * !dtor
  lon_rad = longitude * !dtor

  ; Radial distance from Mars center
  r = params.r_mars + altitude

  ; Cartesian coordinates
  ; x = r * cos(lat) * cos(lon)
  ; y = r * cos(lat) * sin(lon)
  ; z = r * sin(lat)
  position = dblarr(3)
  position[0] = r * cos(lat_rad) * cos(lon_rad)
  position[1] = r * cos(lat_rad) * sin(lon_rad)
  position[2] = r * sin(lat_rad)

  RETURN, position
end

; ===============================================================================
; FUNCTION: osse_sspt_to_sun_direction
;
; Computes sun direction vector from satellite position and sub-solar point
;
; INPUT:
; sat_position - [3] array, Satellite Cartesian position in meters
; subsolar_lat - Sub-solar point latitude in degrees
; subsolar_lon - Sub-solar point longitude in degrees
;
; RETURNS:
; sun_direction - [3] array, Unit vector pointing from satellite toward Sun
;
; NOTES:
; The sub-solar point is where the Sun is directly overhead on Mars.
; The sun direction is computed as the vector from satellite to the
; point on the ray from Mars center through the sub-solar point.
; history:
; 2026/02/08 (mjw):  fix bug in sun_vector (it is NOT -ss_pos)
; 2026/02/11 (mjw):  allow SAT_POSITION,SUN_DISTANCE as optional arguments
; 
; ===============================================================================
function osse_sspt_to_sun_direction, subsolar_lat, subsolar_lon, sat_position=sat_position, $
  sun_distance=sun_distance

  compile_opt idl2

  ; 1 au in meters
  if N_ELEMENTS(sun_distance) ne 1 then sun_distance = 1.52d0 * 1.496d+11

  ; Convert sub-solar point to Cartesian (unit vector from Mars center)
  lat_rad = subsolar_lat * !dtor
  lon_rad = subsolar_lon * !dtor

  ss_pos = dblarr(3)
  ss_pos[0] = cos(lat_rad) * cos(lon_rad)
  ss_pos[1] = cos(lat_rad) * sin(lon_rad)
  ss_pos[2] = sin(lat_rad)

  ; The sun is in the direction AWAY from Mars, along the line
  ; through the sub-solar point. We want direction FROM satellite TO sun.
  ; Sun direction is opposite to the direction from sun to Mars center.
;  sun_vector = -ss_pos
  if N_ELEMENTS(sat_position) eq 3 then begin
    sun_vector = sun_distance*ss_pos - sat_position
  endif else begin
    sun_vector = ss_pos
  endelse
  
    ; Normalize to unit vector
  mag = sqrt(total(sun_vector ^ 2))
  sun_direction = sun_vector / mag

  RETURN, sun_direction
end

; ===============================================================================
; FUNCTION: osse_cartesian_to_latlon
;
; Converts Cartesian position to geodetic coordinates (inverse conversion)
;
; INPUT:
; position - [3] array, Cartesian position vector in meters
;
; RETURNS:
; Structure with fields:
; .latitude  - Latitude in degrees (-90 to +90)
; .longitude - Longitude in degrees (0 to 360)
; .altitude  - Altitude above Mars surface in meters
; ===============================================================================
function osse_cartesian_to_latlon, position
  compile_opt idl2

  ; Get Mars parameters
  params = osse_mars_params()

  x = position[0]
  y = position[1]
  z = position[2]

  ; Radial distance
  r = sqrt(x ^ 2 + y ^ 2 + z ^ 2)

  ; Guard: position at or within 1 m of Mars center (e.g. tangent point on Sun-Mars line)
  if r lt 1.0d then begin
    result = {latitude: 0.0d, longitude: 0.0d, altitude: -params.r_mars}
    return, result
  endif

  ; Altitude
  altitude = r - params.r_mars

  ; Latitude (arcsin of z/r)
  latitude = asin(z / r) * !radeg

  ; Longitude (arctan2 of y/x)
  longitude = atan(y, x) * !radeg

  ; Ensure longitude is in range [0, 360)
  if longitude lt 0.0d then longitude = longitude + 360.0d

  ; Return as structure
  result = {latitude: latitude, longitude: longitude, altitude: altitude}

  RETURN, result
end

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

; ===============================================================================
; PRO: osse_sza
;
; Calculate solar zenith angle at a given location
;
; INPUT:
; latitude  - Point latitude in degrees
; longitude - Point longitude in degrees
; ss_lat    - Sub-solar latitude in degrees
; ss_lon    - Sub-solar longitude in degrees
;
; RETURNS:
; Solar zenith angle in degrees (0° = overhead, 90° = horizon)
; ===============================================================================
function osse_sza, latitude, longitude, ss_lat, ss_lon
  compile_opt idl2

  ; Convert to radians
  lat_rad = latitude * !dtor
  lon_rad = longitude * !dtor
  ss_lat_rad = ss_lat * !dtor
  ss_lon_rad = ss_lon * !dtor

  ; Position on Mars surface (unit vectors)
  pos_x = cos(lat_rad) * cos(lon_rad)
  pos_y = cos(lat_rad) * sin(lon_rad)
  pos_z = sin(lat_rad)

  ; Sub-solar position (unit vector)
  ss_x = cos(ss_lat_rad) * cos(ss_lon_rad)
  ss_y = cos(ss_lat_rad) * sin(ss_lon_rad)
  ss_z = sin(ss_lat_rad)

  ; Cosine of solar zenith angle (dot product)
  cos_sza = pos_x * ss_x + pos_y * ss_y + pos_z * ss_z

  ; Solar zenith angle in degrees
  sza = acos(cos_sza) * !radeg

  RETURN, sza
end

; ===============================================================================
; MAIN PROCEDURE
; ===============================================================================
pro osse_mars_coordinates
  compile_opt idl2

  print, 'Mars Coordinate Conversion Utilities Loaded'
  print, ''
  print, 'Available functions:'
  print, '  osse_latlon_to_cartesian(lat, lon, alt)'
  print, '  osse_sspt_to_sun_direction(sat_pos, ss_lat, ss_lon)'
  print, '  osse_cartesian_to_latlon(position)'
  print, '  osse_sza(lat, lon, ss_lat, ss_lon)'
  print, ''
  print, 'Available procedures:'
  print, '  test_coordinate_conversions'
  print, '  mars_coordinates_example'
  print, ''
  print, 'Usage examples:'
  print, '  IDL> test_coordinate_conversions        ; Run tests'
  print, '  IDL> mars_coordinates_example           ; Run example'
  print, ''
  print, '  IDL> sat_pos = osse_latlon_to_cartesian(25.0D, 135.0D, 400.0D3)'
  print, '  IDL> sun_dir = osse_sspt_to_sun_direction(sat_pos, 10.0D, 270.0D)'
  print, ''
end
