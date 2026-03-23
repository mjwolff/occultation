; ===============================================================================
; PRO: test_osse_construct_pathlength
;
; Tests for osse_construct_pathlength
;
; NOTE: osse_construct_pathlength contains a debug STOP (line 27) that fires
; when the tangent altitude falls exactly on a 1-km layer boundary (see TODO
; item 10). Tests here use tangent altitudes of 50.5 km and 98.5 km to avoid
; landing on a boundary.
;
; NOTE on element count: for n_int intersecting layers, osse_construct_pathlength
; returns n_int+1 elements in s_inbound and s_outbound. The innermost layer
; contributes both s_entry and s1_inner to s_inbound (via the first_one init
; block followed by the else branch), while all other layers contribute only
; s_entry. s_outbound mirrors this: innermost contributes s2_inner and s_exit,
; all others contribute only s_exit.
; ===============================================================================
pro test_osse_construct_pathlength
  compile_opt idl2

  print, ''
  print, '========================================='
  print, 'TEST: osse_construct_pathlength'
  print, '========================================='
  print, ''

  params = osse_mars_params()
  R = params.r_mars

  ; ------------------------------------------------------------------
  ; Multi-layer geometry: tangent at 50.5 km → 49 intersecting layers
  ; ------------------------------------------------------------------
  sat_pos = [R + 400.0d0, 0.0d, 0.0d]
  impact_target = R + 50.5d0
  sin_alpha = impact_target / (R + 400.0d0)
  cos_alpha = sqrt(1.0d - sin_alpha ^ 2)
  sun_dir = [-cos_alpha, sin_alpha, 0.0d]
  osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, isects, n_int, params = params
  osse_construct_pathlength, isects, s_inbound, s_outbound, params = params

  ; Test 1: Element count is n_int + 1 (innermost layer contributes two entries)
  print, 'Test 1: Element count = n_int + 1 (innermost layer contributes s_entry and s1_inner)'
  print, format = '(A,I4)', '  n_int:                            ', n_int
  print, format = '(A,I4)', '  n_elements(s_inbound) (expect 50):', n_elements(s_inbound)
  print, format = '(A,I4)', '  n_elements(s_outbound)(expect 50):', n_elements(s_outbound)
  print, ''

  ; Test 2: All segments have positive length
  print, 'Test 2: All path segments have positive length'
  seg_lengths = s_outbound - s_inbound
  n_neg = total(seg_lengths lt 0.0d)
  print, format = '(A,I4)',   '  n segments < 0 (expect 0):  ', fix(n_neg)
  print, format = '(A,F10.1)', '  Total path km (expect > 0): ', total(seg_lengths)
  print, ''

  ; Test 3: s_inbound is monotonically increasing (inbound from sat toward tangent)
  print, 'Test 3: s_inbound increases monotonically'
  n_unordered = total(s_inbound[1:*] lt s_inbound[0:n_elements(s_inbound)-2])
  print, format = '(A,I4)', '  n out-of-order entries (expect 0): ', fix(n_unordered)
  print, ''

  ; ------------------------------------------------------------------
  ; Single-layer geometry: tangent at 98.5 km → only layer 99 (99-100 km)
  ; ------------------------------------------------------------------
  impact_target1 = R + 98.5d0
  sin_alpha1 = impact_target1 / (R + 400.0d0)
  cos_alpha1 = sqrt(1.0d - sin_alpha1 ^ 2)
  sun_dir1 = [-cos_alpha1, sin_alpha1, 0.0d]
  osse_trace_ray_occultation_3d, sat_pos, sun_dir1, tang_alt, isects1, n_int1, params = params
  osse_construct_pathlength, isects1, s_ib1, s_ob1, params = params

  ; Test 4: Single intersecting layer → 2 elements (n_int+1 = 1+1)
  print, 'Test 4: Single intersecting layer (tangent 98.5 km, expect n_int=1, 2 elements)'
  print, format = '(A,I4)', '  n_int (expect 1):                    ', n_int1
  print, format = '(A,I4)', '  n_elements(s_inbound) (expect 2):    ', n_elements(s_ib1)
  print, format = '(A,I4)', '  n_elements(s_outbound)(expect 2):    ', n_elements(s_ob1)
  print, format = '(A,F8.1)', '  path_length km (expect > 0):       ', $
    total(s_ob1 - s_ib1)
  print, ''

  print, '========================================='
  print, 'test_osse_construct_pathlength complete'
  print, '========================================='
  print, ''
end
