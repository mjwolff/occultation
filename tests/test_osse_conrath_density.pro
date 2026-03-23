;+
; NAME:
;   TEST_OSSE_CONRATH_DENSITY
;
; PURPOSE:
;   Unit tests for osse_conrath_density.
;-

pro test_osse_conrath_density
  compile_opt idl2

  tol_rel = 1.0d-10  ; relative tolerance for exact-formula checks

  ; --- Test 1: z=0 returns N_ref exactly (default parameters) ---
  n_ref_default = 1.0d20
  result = osse_conrath_density(0.0d0)
  if abs(result - n_ref_default) / n_ref_default gt tol_rel then $
    message, 'Test 1 FAILED: z=0 should return N_ref exactly'
  print, 'Test 1 PASSED: z=0 returns N_ref (default)'

  ; --- Test 2: z=0 returns N_ref for custom n_ref ---
  n_ref_custom = 2.5d19
  result = osse_conrath_density(0.0d0, n_ref = n_ref_custom)
  if abs(result - n_ref_custom) / n_ref_custom gt tol_rel then $
    message, 'Test 2 FAILED: z=0 should return custom N_ref exactly'
  print, 'Test 2 PASSED: z=0 returns custom N_ref'

  ; --- Test 3: z=70 km < 0.001 * N_ref (default parameters) ---
  ; With nu=0.007, h_conrath=10 km: exp(0.007*(1-exp(7))) ~ 4.6e-4
  result = osse_conrath_density(70.0d0)
  if result ge 0.001d0 * n_ref_default then $
    message, 'Test 3 FAILED: z=70 km should be < 0.001 * N_ref'
  print, format = '(A,E10.3,A)', 'Test 3 PASSED: z=70 km -> ', result, ' m^-3 (< 0.001 * N_ref)'

  ; --- Test 4: profile decreases monotonically with altitude ---
  z_arr = [0.0d0, 10.0d0, 20.0d0, 50.0d0, 100.0d0]
  n_arr = osse_conrath_density(z_arr)
  for i = 1, n_elements(n_arr) - 1 do begin
    if n_arr[i] ge n_arr[i - 1] then $
      message, 'Test 4 FAILED: density not monotonically decreasing at index ' + strtrim(i, 2)
  endfor
  print, 'Test 4 PASSED: density decreases monotonically with altitude'

  ; --- Test 5: array input returns array of correct size ---
  n_pts = 500L
  z_large = dindgen(n_pts) * 0.2d0  ; 0 to 99.8 km in 0.2 km steps
  result_arr = osse_conrath_density(z_large)
  if n_elements(result_arr) ne n_pts then $
    message, 'Test 5 FAILED: output size does not match input size'
  print, format = '(A,I0,A)', 'Test 5 PASSED: array input (', n_pts, ' elements) returns correct size'

  ; --- Test 6: custom nu keyword changes profile shape ---
  ; Larger nu -> faster falloff -> lower density at z=10 km
  n_low_nu  = osse_conrath_density(10.0d0, nu = 0.007d0)
  n_high_nu = osse_conrath_density(10.0d0, nu = 1.0d0)
  if n_high_nu ge n_low_nu then $
    message, 'Test 6 FAILED: larger nu should give lower density at z=10 km'
  print, 'Test 6 PASSED: larger nu gives lower density (faster falloff)'

  ; --- Test 7: large h_conrath gives near-constant profile (approaches N_ref) ---
  ; h_conrath = 1e6 km: exp(z/h_conrath) ~= 1 for z <= 100 km
  ; so N ~= N_ref * exp(0) = N_ref at all altitudes
  z_check = 50.0d0  ; 50 km
  result_flat = osse_conrath_density(z_check, h_conrath = 1.0d6)
  if abs(result_flat - n_ref_default) / n_ref_default gt 1.0d-4 then $
    message, 'Test 7 FAILED: very large h_conrath should give near-constant profile'
  print, 'Test 7 PASSED: h_conrath=1e6 km gives near-constant profile at 50 km'

  ; --- Test 8: analytical value check at z=10 km with default parameters ---
  ; N(10 km) = N_ref * exp(0.007 * (1 - exp(1)))
  z_test    = 10.0d0
  expected  = n_ref_default * exp(0.007d0 * (1.0d0 - exp(1.0d0)))
  result    = osse_conrath_density(z_test)
  if abs(result - expected) / expected gt tol_rel then $
    message, 'Test 8 FAILED: value at z=10 km does not match analytical formula'
  print, format = '(A,E12.6,A)', 'Test 8 PASSED: z=10 km analytical check -> ', result, ' m^-3'

  print, ''
  print, 'All osse_conrath_density tests PASSED'
end
