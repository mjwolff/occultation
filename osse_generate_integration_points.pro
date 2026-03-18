; ===============================================================================
; GENERATE INTEGRATION POINTS ALONG RAY PATH
; ===============================================================================
pro osse_generate_integration_points, sat_pos, sun_dir, intersections, $
  integration_points, n_points, ds_target, params = params
  compile_opt idl2

  if ~keyword_set(params) then params = osse_mars_params()

  ; Count total number of points needed
  n_points_total = 0l
  for i = 0l, params.n_layers - 1 do begin
    if intersections[i].intersects then begin
      n_steps = long((intersections[i].path_length / ds_target) > 1)
      n_points_total += n_steps + 1
    endif
  endfor

  ; Allocate array
  n_points_total = n_points_total < params.max_int_pts
  integration_points = dblarr(3, n_points_total)

  n_points = 0l
  for i = 0l, params.n_layers - 1 do begin
    if intersections[i].intersects then begin
      s_start = intersections[i].s_entry
      s_end = intersections[i].s_exit

      ; Calculate number of steps for this segment
      n_steps = long((intersections[i].path_length / ds_target) > 1)
      ds = (s_end - s_start) / n_steps

      ; Generate points
      for j = 0l, n_steps do begin
        if n_points ge n_points_total then begin
          print, 'Warning: Maximum integration points reached'
          RETURN
        endif

        s_current = s_start + j * ds
        integration_points[*, n_points] = sat_pos + s_current * sun_dir
        n_points = n_points + 1
      endfor
    endif
  endfor

  ; Trim array to actual size
  if n_points lt n_points_total then begin
    integration_points = integration_points[*, 0 : n_points - 1]
  endif
end
