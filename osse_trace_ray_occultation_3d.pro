; ==============================================================================
; MAIN RAY TRACING PROCEDURE WITH 3D SHELL INTERSECTIONS
; ==============================================================================
;
; 2026/02/08 (mjw):  move r_inner,r_outer, altitude attribute of INTERSECTIONS
;                       structure to be set in osse_find_shell_intersection_3d
;                       (was done orginally incorrectly here)
; 2026/02/11 (mjw):  remote r_sat, which wasn't used.
; 2026/02/12 (mjw):  trap case of ray hitting planet
;

pro osse_trace_ray_occultation_3d, sat_pos, sun_dir, tangent_altitude, $
  intersections, n_intersect, $
  params = params, quiet = quiet
  compile_opt idl2

  ; Get parameters
  if ~keyword_set(params) then params = osse_mars_params()

  ; Initialize outputs
  intersections = replicate(osse_create_shell_intersection(), params.n_layers)
  n_intersect = 0l

  ; Normalize sun direction vector
  sun_dir_norm = sun_dir / sqrt(total(sun_dir * sun_dir))

  ; Calculate impact parameter (could also calculate this using the dot-product definition)
  cross_prod = [sat_pos[1] * sun_dir_norm[2] - sat_pos[2] * sun_dir_norm[1], $
    sat_pos[2] * sun_dir_norm[0] - sat_pos[0] * sun_dir_norm[2], $
    sat_pos[0] * sun_dir_norm[1] - sat_pos[1] * sun_dir_norm[0]]
  impact_param = sqrt(total(cross_prod * cross_prod))

  ; Tangent altitude above Mars surface
  tangent_altitude = impact_param - params.r_mars

  ; Check if ray intersects atmosphere
  if impact_param gt params.r_mars + params.h_atm then begin
    if ~keyword_set(quiet) then print, 'Ray does not intersect atmosphere (> h_atm)'
    n_intersect = 0
    RETURN
  endif else if impact_param lt params.r_mars then begin
    if ~keyword_set(quiet) then print, 'Ray intersects planet'
    n_intersect = 0
    RETURN
  endif

  ; Trace through each atmospheric layer and record intersections
  for i = 0l, params.n_layers - 1 do begin
    r_layer_inner = params.radii[i]
    r_layer_outer = params.radii[i+1]
    
    ; Skip layers below tangent altitude
    if r_layer_inner lt impact_param then continue
;    if r_layer_outer lt impact_param then continue

    ; Calculate intersection points and path length
    osse_find_shell_intersection_3d, sat_pos, sun_dir_norm, $
      r_layer_inner, r_layer_outer, $
      intersection_temp

    ; Copy result to array
    intersections[i] = intersection_temp

    intersections[i].r_inner = r_layer_inner
    intersections[i].r_outer = r_layer_outer
    intersections[i].altitude = 0.5*(r_layer_inner+r_layer_outer) - params.r_mars

    if intersections[i].intersects then begin
       n_intersect = n_intersect + 1
;       print,'intersects shell: ',i
;       print,'r_inner,r_outer: ',[r_layer_inner, r_layer_outer]-params.r_mars
    endif
  endfor

  if ~keyword_set(quiet) then begin
    print, format = '("Tangent altitude: ", F10.2, " km")', $
      tangent_altitude / 1000.0d
    print, format = '("Ray intersects ", I4, " atmospheric layers")', $
      n_intersect
  endif
end
