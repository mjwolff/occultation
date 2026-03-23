; ===============================================================================
; PRO: mars_coordinates_example
;
; Example usage of coordinate conversion utilities
; ===============================================================================
pro mars_example
  compile_opt idl2

  print, ''
  print, '========================================='
  print, 'MARS COORDINATES - EXAMPLE USAGE'
  print, '========================================='
  print, ''

  ; Sub-solar point (where Sun is directly overhead)
  ss_lat = 0.0d ; 10° North
  ss_lon = 0.0d ; 270° East (90° W)
  print, format = '(A,F6.1,A)', 'Sub-solar latitude:  ', ss_lat, '° N'
  print, format = '(A,F6.1,A)', 'Sub-solar longitude: ', ss_lon, '° E'
  print, ''

  eps = 10. ; precision for tangent height comparison (m)

  ; Example: Occultation observed from satellite at specific lat/lon
  print, 'Example: Ray tracing with lat/lon inputs'
  print, ''

  ; Satellite position (geodetic coordinates)
  sat_lat = 0.0d ; 25° North
  ; sat_lon = 180 + (90. - 26.50137d0) ; 135° East
  sat_lon = 180 + (90. - 26.5d0) ; 135° East
  sat_alt = 400.0d3 ; 400 km altitude
  npts = 40
  sat_lon_arr = findgen(npts) * 0.1d0 + sat_lon
  sat_lon_arr = [sat_lon - (reverse(findgen(5)) + 1) * 0.1d0, sat_lon_arr]
  npts = n_elements(sat_lon_arr)

  print, format = '(A,F6.1,A)', 'Satellite latitude:  ', sat_lat, '° N'
  print, format = '(A,F6.1,A)', 'Satellite longitude: ', sat_lon, '° E'
  print, format = '(A,F6.1,A)', 'Satellite altitude:  ', sat_alt / 1000.0d, ' km'
  print, ''

  path_info = ptrarr(npts, /allocate_heap)
  height = dblarr(npts)
  longitude = dblarr(npts)
  latitude = dblarr(npts)
  n_intersections = intarr(npts)
  transmittance = dblarr(npts)

  params = osse_mars_params()

  print, 'Performing ray trace...'
  for i = 0, npts - 1 do begin
    ; Convert to Cartesian
    sat_lon = sat_lon_arr[i]
    sat_pos = osse_latlon_to_cartesian(sat_lat, sat_lon, sat_alt)
    sun_dir = osse_sspt_to_sun_direction(ss_lat, ss_lon, sat_pos = sat_pos)
    ; sun_dir = osse_sspt_to_sun_direction(ss_lat, ss_lon, sat_pos=sat_pos)

    ; calculate the pathlength to the tangent point
    s_tangent = -total(sat_pos * sun_dir)
    tangent_point = sat_pos + s_tangent * sun_dir
    res_tangent = osse_cartesian_to_latlon(tangent_point)
    print, 'tangent: ', res_tangent.longitude, res_tangent.latitude, res_tangent.altitude / 1000.d0
    height[i] = res_tangent.altitude
    longitude[i] = res_tangent.longitude
    latitude[i] = res_tangent.latitude

    ; print, 'Cartesian coordinates:'
    ; print, format = '(A,3F12.1)', '  Satellite position (m): ', sat_pos

    ; Trace the ray from spacecraft towards sun, calculating intersections with atmospheric layers
    osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, intersections, n_int
    n_intersections[i] = n_int
    if abs(tang_alt - res_tangent.altitude) gt eps then begin
      message, 'tangent point heigh caculations differ.'
      stop
    endif
    print, format = '(A,F9.4,A,i4)', 'Tangent altitude: ', tang_alt / 1000.0d, $
      ' km, Layers intersected: ', n_int

    ; compute line-of-sight transmittance through the atmosphere
    transmittance[i] = osse_calculate_transmittance(sat_pos, sun_dir, intersections, n_int, $
      params = params)
    print, format = '(A,F10.6)', 'Transmittance:    ', transmittance[i]

    ; get integration points along sightline, and combine with tangent point
    ; if no intersections, then we can skip the pathlength determination
    if n_int gt 0 then begin
      ; create sorted list of intersections points along the sightline, and combine with tangent point
      osse_construct_pathlength, intersections, s_inbound, s_outbound, params = params

      ; assuming that there is not a tangent ray that matches grid; tangent ray very unlikely to occur,
      ; but we will test anyway.  We will stop the run if we find a small enough positive discriminant.
      idx = where(intersections[*].intersects gt 0.)
      if idx[0] ne -1 then begin
        min_discriminant = min([intersections[idx].discriminant_inner, intersections[idx].discriminant_outer])
        if min_discriminant lt 1.e4 then begin
          message, 'min(discriminant) lt 1.e-4'
          stop
        endif
      endif
      s_points = [s_inbound, s_tangent, s_outbound]

      ; get the pathlength point aerocentric coordinates (keep array fortran efficient)
      n_s_points = n_elements(s_points)
      intersection_points = fltarr(3, n_s_points)
      for j = 0, n_s_points - 1 do begin
        s_position = sat_pos + s_points[j] * sun_dir
        res = osse_cartesian_to_latlon(s_position)
        intersection_points[*, j] = [res.longitude, res.latitude, res.altitude]
      endfor

      ; store the results from this satellite position (i n_int > 0)
      *path_info[i] = {path_length: s_points, $
        path_longitude: reform(intersection_points[0, *]), path_latitude: reform(intersection_points[1, *]), $
        path_altitude: reform(intersection_points[2, *])}

      ; end n_int > 0 logic block
    endif

    ; stop

    ; end loop of sub-spacecraft points
  endfor

  a = {height: height, longitude: longitude, latitude: latitude, n_intersections: n_intersections, $
    transmittance: transmittance, path_info: path_info}

  ; Calculate column density
  ; ;  col_dens = integrate_column_density(sat_pos, sun_dir, intersections, $
  ; method = 'simpson')
  ; print, format = '(A,E12.4,A)', 'Column density: ', col_dens, ' m^-2'
  ; print, ''

  print, '========================================='
  print, 'Example complete'
  print, '========================================='
  print, ''
  stop
end
