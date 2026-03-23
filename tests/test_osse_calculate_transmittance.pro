;+
; NAME:
;   TEST_OSSE_CALCULATE_TRANSMITTANCE
;
; PURPOSE:
;   Unit tests for osse_calculate_transmittance.
;-

pro test_osse_calculate_transmittance
  compile_opt idl2

  params = osse_mars_params()
  r_mars = params.r_mars

  ; Shared geometry: satellite at 400 km, tangent at 50.5 km (49 intersecting layers)
  sat_pos = [r_mars + 400.0d0, 0.0d0, 0.0d0]
  r_tang  = r_mars + 50.5d0
  sin_a   = r_tang / (r_mars + 400.0d0)
  cos_a   = sqrt(1.0d0 - sin_a ^ 2)
  sun_dir = [-cos_a, sin_a, 0.0d0]
  sun_dir = sun_dir / sqrt(total(sun_dir ^ 2))

  osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, intersections, n_int, $
    params = params
  print, format = '(A,F6.1,A,I3,A)', 'Geometry: tang_alt=', tang_alt, $
    ' km, n_int=', n_int, ' layers'

  ; --- Test 1: n_int=0 returns T=1.0 exactly ---
  ; Use ray pointing radially outward — no atmospheric intersections
  sun_dir_out = [1.0d0, 0.0d0, 0.0d0]
  osse_trace_ray_occultation_3d, sat_pos, sun_dir_out, tang_alt_out, isects_out, n_int_out, $
    params = params
  print, format = '(A,F6.1,A,I3,A)', 'Outward ray: tang_alt=', tang_alt_out, $
    ' km, n_int=', n_int_out, ' layers'
  if n_int_out ne 0 then message, 'Test 1 setup FAILED: expected n_int=0 for outward ray'
  t_clear = osse_calculate_transmittance(sat_pos, sun_dir_out, isects_out, n_int_out)
  if t_clear ne 1.0d0 then $
    message, 'Test 1 FAILED: n_int=0 should return T=1.0 exactly'
  print, 'Test 1 PASSED: n_int=0 returns T=1.0 exactly'

  ; --- Test 2: T is in (0, 1) for a ray through the atmosphere ---
  ; Use n_ref=1e7 so tau ~ 1 and T is comfortably non-zero and non-one
  t_val = osse_calculate_transmittance(sat_pos, sun_dir, intersections, n_int, $
    n_ref = 1.0d7, params = params)
  if t_val le 0.0d0 or t_val ge 1.0d0 then $
    message, 'Test 2 FAILED: transmittance not in (0, 1)'
  print, format = '(A,F10.6)', 'Test 2 PASSED: T in (0,1), T = ', t_val

  ; --- Test 3: constant-N internal consistency check ---
  ; With h_conrath=1e6 km, N ~= N_ref at all points.
  ; tau = sigma * N_ref * n_points * ds_target (Riemann sum).
  ; Verify that osse_calculate_transmittance produces T = exp(-tau) to
  ; floating-point precision by computing the expected value the same way.
  sigma_test  = 1.0d-12
  n_ref_test  = 1.0d7
  ds_test     = 1.0d0
  tol_rel     = 1.0d-4  ; h_conrath=1e9 gives N slightly < N_ref; ~4e-6 relative error typical

  osse_generate_integration_points, sat_pos, sun_dir, intersections, $
    ipts, n_pts, ds_test, params = params
  if (size(ipts, /dimensions))[0] ne 3 then $
    message, 'Test 3 setup FAILED: integration_points should have 3 rows'

  tau_expected = sigma_test * n_ref_test * double(n_pts) * ds_test
  t_expected   = exp(-tau_expected)
  t_computed   = osse_calculate_transmittance(sat_pos, sun_dir, intersections, n_int, $
    sigma = sigma_test, n_ref = n_ref_test, h_conrath = 1.0d6, $
    ds_target = ds_test, params = params)

  rel_err = abs(t_computed - t_expected) / (t_expected > 1.0d-300)
  if rel_err gt tol_rel then $
    message, string(format = '(A,E12.5,A,E12.5,A,E10.3)', $
      'Test 3 FAILED: T_computed=', t_computed, ' T_expected=', t_expected, $
      ' rel_err=', rel_err)
  print, format = '(A,E12.5,A,E12.5)', $
    'Test 3 PASSED: T_computed=', t_computed, '  T_expected=', t_expected

  ; --- Test 4: deeper tangent altitude gives lower transmittance ---
  ; Ray at tang ~10 km passes through denser atmosphere than tang ~50 km
  r_tang_deep  = r_mars + 10.5d0
  sin_b        = r_tang_deep / (r_mars + 400.0d0)
  cos_b        = sqrt(1.0d0 - sin_b ^ 2)
  sun_dir_deep = [-cos_b, sin_b, 0.0d0]
  sun_dir_deep = sun_dir_deep / sqrt(total(sun_dir_deep ^ 2))
  osse_trace_ray_occultation_3d, sat_pos, sun_dir_deep, tang_alt_deep, isects_deep, $
    n_int_deep, params = params
  print, format = '(A,F6.1,A,I3,A)', 'Deep ray:    tang_alt=', tang_alt_deep, $
    ' km, n_int=', n_int_deep, ' layers'

  t_shallow = osse_calculate_transmittance(sat_pos, sun_dir,      intersections, n_int,      $
    n_ref = 1.0d7, params = params)
  t_deep    = osse_calculate_transmittance(sat_pos, sun_dir_deep, isects_deep,   n_int_deep, $
    n_ref = 1.0d7, params = params)

  if t_deep ge t_shallow then $
    message, 'Test 4 FAILED: deeper tangent altitude should give lower T'
  print, format = '(A,F8.5,A,F8.5)', $
    'Test 4 PASSED: T(tang=50 km)=', t_shallow, '  T(tang=10 km)=', t_deep

  ; --- Test 5: larger sigma gives lower transmittance ---
  t_small_sigma = osse_calculate_transmittance(sat_pos, sun_dir, intersections, n_int, $
    sigma = 1.0d-14, n_ref = 1.0d7, params = params)
  t_large_sigma = osse_calculate_transmittance(sat_pos, sun_dir, intersections, n_int, $
    sigma = 1.0d-10, n_ref = 1.0d7, params = params)
  if t_large_sigma ge t_small_sigma then $
    message, 'Test 5 FAILED: larger sigma should give lower T'
  print, format = '(A,E10.3,A,E10.3)', $
    'Test 5 PASSED: T(sigma=1e-14)=', t_small_sigma, '  T(sigma=1e-10)=', t_large_sigma

  print, ''
  print, 'All osse_calculate_transmittance tests PASSED'
end
