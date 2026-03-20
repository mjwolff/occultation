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
