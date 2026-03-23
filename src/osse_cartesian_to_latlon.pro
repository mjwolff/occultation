; ===============================================================================
; FUNCTION: osse_cartesian_to_latlon
;
; Converts Cartesian position to geodetic coordinates (inverse conversion)
;
; INPUT:
; position - [3] array, Cartesian position vector in km
;
; RETURNS:
; Structure with fields:
; .latitude  - Latitude in degrees (-90 to +90)
; .longitude - Longitude in degrees (0 to 360)
; .altitude  - Altitude above Mars surface in km
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

  ; Guard: position at or within 0.001 km of Mars center (e.g. tangent point on Sun-Mars line)
  if r lt 0.001d then begin
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
