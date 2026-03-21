;+
; NAME:
;   OSSE_LOCAL_TRUE_SOLAR_TIME
;
; PURPOSE:
;   Compute Local True Solar Time (LTST) at one or more longitudes given the
;   sub-solar longitude at the observation epoch.  LTST is 12:00 h when the
;   Sun is on the meridian and advances by 1 h per 15 degrees eastward.
;
; CALLING SEQUENCE:
;   ltst = osse_local_true_solar_time(lon, ss_lon)
;
; INPUTS:
;   lon    - geographic longitude(s) in degrees; scalar or any-size array.
;            May be negative or exceed 360 degrees.
;   ss_lon - sub-solar longitude in degrees (scalar); obtain via
;            sp_calculate_subsolar_longitude before calling this function.
;
; OUTPUTS:
;   ltst   - Local True Solar Time in decimal hours, range [0, 24).
;            Same dimensions as lon.
;
; EXAMPLES:
;   ; Sub-solar point at 90 deg E
;   print, osse_local_true_solar_time(90.0d,  90.0d)   ; -> 12.0
;   print, osse_local_true_solar_time(270.0d, 90.0d)   ; ->  0.0 (midnight)
;   print, osse_local_true_solar_time(0.0d,   90.0d)   ; ->  6.0 (dawn)
;
;   ; Array call
;   lons = [0.d, 90.d, 180.d, 270.d]
;   print, osse_local_true_solar_time(lons, 90.0d)     ; -> [6, 12, 18, 0]
;
; NOTES:
;   - ss_lon must be a scalar; it is a property of the time instant, not
;     of the location.
;   - The double-mod wrap handles negative deltas correctly on all platforms.
;
; MODIFICATION HISTORY:
;   2026-03-21: Initial implementation
;-

function osse_local_true_solar_time, lon, ss_lon
  compile_opt idl2

  ; Angular distance east of sub-solar point, wrapped to (-180, 180]
  delta = ((lon - ss_lon + 180.0d0) mod 360.0d0) - 180.0d0

  ; Convert to hours and wrap to [0, 24)
  ltst = ((12.0d0 + delta / 15.0d0) mod 24.0d0 + 24.0d0) mod 24.0d0

  return, ltst
end
