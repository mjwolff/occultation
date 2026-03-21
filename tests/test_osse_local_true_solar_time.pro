;+
; NAME:
;   TEST_OSSE_LOCAL_TRUE_SOLAR_TIME
;
; PURPOSE:
;   Unit tests for osse_local_true_solar_time.
;-

pro test_osse_local_true_solar_time
  compile_opt idl2

  tol = 1.0d-10  ; hours

  ; --- Test 1: sub-solar meridian is noon ---
  r = osse_local_true_solar_time(90.0d, 90.0d)
  if abs(r - 12.0d) gt tol then message, 'Test 1 FAILED: lon=ss_lon should be 12h'
  print, 'Test 1 PASSED: lon = ss_lon -> 12.00 h'

  ; --- Test 2: 180 deg from sub-solar is midnight ---
  r = osse_local_true_solar_time(270.0d, 90.0d)
  if abs(r - 0.0d) gt tol then message, 'Test 2 FAILED: lon=ss_lon+180 should be 00h'
  print, 'Test 2 PASSED: lon = ss_lon+180 -> 00.00 h'

  ; --- Test 3: 90 deg west of sub-solar is 06:00 (dawn) ---
  r = osse_local_true_solar_time(0.0d, 90.0d)
  if abs(r - 6.0d) gt tol then message, 'Test 3 FAILED: dawn should be 06h'
  print, 'Test 3 PASSED: lon = ss_lon-90 -> 06.00 h (dawn)'

  ; --- Test 4: 90 deg east of sub-solar is 18:00 (dusk) ---
  r = osse_local_true_solar_time(180.0d, 90.0d)
  if abs(r - 18.0d) gt tol then message, 'Test 4 FAILED: dusk should be 18h'
  print, 'Test 4 PASSED: lon = ss_lon+90 -> 18.00 h (dusk)'

  ; --- Test 5: array input, four quadrants simultaneously ---
  lons = [0.0d, 90.0d, 180.0d, 270.0d]
  r = osse_local_true_solar_time(lons, 90.0d)
  expected = [6.0d, 12.0d, 18.0d, 0.0d]
  if max(abs(r - expected)) gt tol then message, 'Test 5 FAILED: array quadrant check'
  print, 'Test 5 PASSED: array of four quadrants correct'

  ; --- Test 6: output is in [0, 24) for full longitude sweep ---
  lons = dindgen(361) - 180.0d0  ; -180 to +180 in 1-deg steps
  r = osse_local_true_solar_time(lons, 45.0d)
  if min(r) lt 0.0d or max(r) ge 24.0d then $
    message, 'Test 6 FAILED: result outside [0, 24)'
  print, 'Test 6 PASSED: all values in [0, 24) for full lon sweep'

  ; --- Test 7: negative longitude input treated same as positive equivalent ---
  r_neg = osse_local_true_solar_time(-5.0d,  0.0d)
  r_pos = osse_local_true_solar_time(355.0d, 0.0d)
  if abs(r_neg - r_pos) gt tol then $
    message, 'Test 7 FAILED: lon=-5 should equal lon=355'
  print, 'Test 7 PASSED: lon=-5 deg same as lon=355 deg'

  ; --- Test 8: ss_lon=0, lon crosses 0/360 boundary without discontinuity ---
  r_lo = osse_local_true_solar_time(359.0d, 0.0d)
  r_hi = osse_local_true_solar_time(  1.0d, 0.0d)
  ; 359 deg west of 0 -> just before noon from below; 1 deg east -> just after noon
  ; difference should be 2/15 h = 0.1333... h
  expected_diff = 2.0d / 15.0d
  if abs((r_hi - r_lo + 24.d) mod 24.d - expected_diff) gt tol then $
    message, 'Test 8 FAILED: 0/360 boundary discontinuity'
  print, 'Test 8 PASSED: no discontinuity across 0/360 boundary'

  ; --- Test 9: ss_lon=355, lon near 0 (wrap test) ---
  ; ss_lon=355 -> noon at 355 deg; lon=5 is 10 deg east -> 12 + 10/15 = 12.667 h
  r = osse_local_true_solar_time(5.0d, 355.0d)
  expected = 12.0d + 10.0d/15.0d
  if abs(r - expected) gt tol then message, 'Test 9 FAILED: ss_lon near 360 wrap'
  print, 'Test 9 PASSED: ss_lon near 360, wrap handled correctly'

  ; --- Test 10: large array — 100,000 elements, timing/correctness check ---
  n = 100000l
  lons_big = (dindgen(n) / double(n)) * 360.0d0
  r_big = osse_local_true_solar_time(lons_big, 180.0d)
  if n_elements(r_big) ne n then message, 'Test 10 FAILED: wrong output size'
  if min(r_big) lt 0.0d or max(r_big) ge 24.0d then $
    message, 'Test 10 FAILED: large array result outside [0, 24)'
  print, format='(A,I0,A)', 'Test 10 PASSED: large array (', n, ' elements) correct'

  print, ''
  print, 'All osse_local_true_solar_time tests PASSED'
end
