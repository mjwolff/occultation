; ===============================================================================
; PRO: test_osse_generate_integration_points
;
; Tests for osse_generate_integration_points
; ===============================================================================
pro test_osse_generate_integration_points
  compile_opt idl2

  print, ''
  print, '========================================='
  print, 'TEST: osse_generate_integration_points'
  print, '========================================='
  print, ''

  params = osse_mars_params()
  R = params.r_mars

  ; Shared geometry: tangent at 50.5 km → 49 intersecting layers
  sat_pos = [R + 400.0d3, 0.0d, 0.0d]
  impact_target = R + 50.5d3
  sin_alpha = impact_target / (R + 400.0d3)
  cos_alpha = sqrt(1.0d - sin_alpha ^ 2)
  sun_dir = [-cos_alpha, sin_alpha, 0.0d]
  sun_dir_norm = sun_dir / sqrt(total(sun_dir ^ 2))
  osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, isects, n_int, params = params
  print, format = '(A,F6.1,A,I3,A)', 'Geometry: tang_alt=', tang_alt/1000.d, ' km, n_int=', n_int, ' layers'

  ; ------------------------------------------------------------------
  ; Test 1: All points lie on the ray
  ; Each point p satisfies p = sat_pos + s*sun_dir for some s, so
  ; (p - sat_pos) x sun_dir = 0. Check max cross-product magnitude.
  ; ------------------------------------------------------------------
  print, 'Test 1: All integration points lie on the ray (cross-product near 0)'
  osse_generate_integration_points, sat_pos, sun_dir_norm, isects, $
    ipts, n_pts, 1000.0d, params = params
  max_cross = 0.0d
  for k = 0l, n_pts - 1 do begin
    dv = ipts[*, k] - sat_pos
    cross = [dv[1]*sun_dir_norm[2] - dv[2]*sun_dir_norm[1], $
             dv[2]*sun_dir_norm[0] - dv[0]*sun_dir_norm[2], $
             dv[0]*sun_dir_norm[1] - dv[1]*sun_dir_norm[0]]
    mag = sqrt(total(cross ^ 2))
    if mag gt max_cross then max_cross = mag
  endfor
  print, format = '(A,I6)',   '  n_points generated:                 ', n_pts
  print, format = '(A,E10.3)', '  max |cross product| (expect ~0 m):  ', max_cross
  print, ''

  ; ------------------------------------------------------------------
  ; Test 2: Large ds_target → minimum 1 step per layer → 2 points per layer
  ; With n_int=49 layers and ds_target >> any path_length: n_points = 49*2 = 98
  ; ------------------------------------------------------------------
  print, 'Test 2: Large ds_target (1 step per layer, expect n_points = 2*n_int = 98)'
  osse_generate_integration_points, sat_pos, sun_dir_norm, isects, $
    ipts, n_pts, 1.0d9, params = params
  print, format = '(A,I4)', '  n_int:              ', n_int
  print, format = '(A,I4)', '  n_points (expect 98):', n_pts
  print, ''

  ; ------------------------------------------------------------------
  ; Test 3: Very small ds_target → n_points capped at MAX_INT_PTS
  ; ------------------------------------------------------------------
  print, 'Test 3: ds_target=1 m → n_points capped at MAX_INT_PTS'
  osse_generate_integration_points, sat_pos, sun_dir_norm, isects, $
    ipts, n_pts, 1.0d, params = params
  print, format = '(A,I6)', '  MAX_INT_PTS:          ', params.max_int_pts
  print, format = '(A,I6)', '  n_points (expect cap):', n_pts
  print, format = '(A,I2)', '  n_points <= MAX_INT_PTS (expect 1): ', $
    fix(n_pts le params.max_int_pts)
  print, ''

  ; ------------------------------------------------------------------
  ; Test 4: All points lie within the atmosphere (altitude 0-100 km)
  ; A tolerance of 1 m is allowed for floating-point rounding at shell boundaries.
  ; ------------------------------------------------------------------
  print, 'Test 4: All points within atmosphere (0-100 km, 1 m tolerance)'
  osse_generate_integration_points, sat_pos, sun_dir_norm, isects, $
    ipts, n_pts, 1000.0d, params = params
  r_pts = sqrt(ipts[0,*]^2 + ipts[1,*]^2 + ipts[2,*]^2)
  alt_pts = r_pts - R
  n_out = total(alt_pts lt -1.0d or alt_pts gt params.h_atm + 1.0d)
  print, format = '(A,I6)', '  n_points total:                        ', n_pts
  print, format = '(A,I4)', '  n_points outside atm+1m (expect 0):   ', fix(n_out)
  print, ''

  print, '========================================='
  print, 'test_osse_generate_integration_points complete'
  print, '========================================='
  print, ''
end
