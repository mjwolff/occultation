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
