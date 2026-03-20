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
