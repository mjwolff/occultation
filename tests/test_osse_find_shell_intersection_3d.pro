; ===============================================================================
; PRO: test_osse_find_shell_intersection_3d
;
; Tests for osse_find_shell_intersection_3d (and osse_create_shell_intersection)
; ===============================================================================
pro test_osse_find_shell_intersection_3d
  compile_opt idl2

  print, ''
  print, '========================================='
  print, 'TEST: osse_find_shell_intersection_3d'
  print, '========================================='
  print, ''

  params = osse_mars_params()
  R = params.r_mars

  ; Test 1: Empty structure from osse_create_shell_intersection
  print, 'Test 1: osse_create_shell_intersection returns zeroed structure'
  s = osse_create_shell_intersection()
  print, format = '(A,I2)',   '  intersects (expect 0):  ', s.intersects
  print, format = '(A,F8.1)', '  path_length (expect 0): ', s.path_length
  print, ''

  ; Test 2: Satellite outside shell, ray through both surfaces symmetrically
  ; Geometry: sat on +x at 400 km, ray in -x, shell at 50-60 km
  ; The ray traverses the 10-km shell twice → path_length = 20 km
  print, 'Test 2: Ray through shell symmetrically (expect path_length=20 km)'
  sat_pos = [R + 400.0d0, 0.0d, 0.0d]
  sun_dir = [-1.0d, 0.0d, 0.0d]
  osse_find_shell_intersection_3d, sat_pos, sun_dir, R+50.0d0, R+60.0d0, isect
  print, format = '(A,I2)',   '  intersects (expect 1):         ', isect.intersects
  print, format = '(A,F8.1)', '  path_length km (expect 20.0):  ', isect.path_length
  print, format = '(A,F8.1)', '  s_entry km (expect 340.0):     ', isect.s_entry
  print, ''

  ; Test 3: Ray pointing away from planet — no intersection
  print, 'Test 3: Ray pointing away from shell (expect no intersection)'
  sun_dir_out = [1.0d, 0.0d, 0.0d]
  osse_find_shell_intersection_3d, sat_pos, sun_dir_out, R+50.0d0, R+60.0d0, isect
  print, format = '(A,I2)', '  intersects (expect 0): ', isect.intersects
  print, ''

  ; Test 4: Tangent ray — sat at [0,0,R+400], ray in +x, shell at 390-400 km
  ; Ray grazes the outer sphere exactly; discriminant_outer = 0
  print, 'Test 4: Tangent ray grazing outer sphere (expect no intersection)'
  sat_pos_t = [0.0d, 0.0d, R + 400.0d0]
  sun_dir_t  = [1.0d, 0.0d, 0.0d]
  osse_find_shell_intersection_3d, sat_pos_t, sun_dir_t, R+390.0d0, R+400.0d0, isect
  print, format = '(A,I2)',    '  intersects:                   ', isect.intersects
  print, format = '(A,E12.4)', '  discriminant_outer (near 0):  ', isect.discriminant_outer
  print, format = '(A,F8.3)',  '  path_length km (expect 0):    ', isect.path_length
  print, ''

  ; Test 5: Case 2 — satellite inside outer sphere, ray perpendicular (no inner hit)
  ; sat at [0,0,R+55km], ray in +x. s1_outer < 0, s2_outer > 0, hit_inner = 0.
  ; Entry is set to 0 (satellite position); path_length = s2_outer.
  print, 'Test 5: Case 2 — sat inside outer sphere, no inner hit (expect entry=0)'
  sat_pos_c2 = [0.0d, 0.0d, R + 55.0d0]
  sun_dir_c2  = [1.0d, 0.0d, 0.0d]
  osse_find_shell_intersection_3d, sat_pos_c2, sun_dir_c2, R+50.0d0, R+60.0d0, isect
  print, format = '(A,I2)',   '  intersects (expect 1):         ', isect.intersects
  print, format = '(A,F8.1)', '  s_entry km (expect 0.0):       ', isect.s_entry
  print, format = '(A,F8.1)', '  path_length km (expect ~185.9):', isect.path_length
  print, ''

  ; Test 6: Case 4 — satellite inside inner sphere, only exit segment
  ; sat at [R+45km,0,0], ray in +y. hit_inner=1, s1_inner<0, s2_inner>0.
  ; Entry = s2_inner; exit = s2_outer; path_length = s2_outer - s2_inner.
  print, 'Test 6: Case 4 — sat inside inner sphere, only exit segment'
  sat_pos_c4 = [R + 45.0d0, 0.0d, 0.0d]
  sun_dir_c4  = [0.0d, 1.0d, 0.0d]
  osse_find_shell_intersection_3d, sat_pos_c4, sun_dir_c4, R+50.0d0, R+60.0d0, isect
  print, format = '(A,I2)',   '  intersects (expect 1):         ', isect.intersects
  print, format = '(A,F8.1)', '  s_entry km (expect ~184.9):    ', isect.s_entry
  print, format = '(A,F8.1)', '  s_exit km  (expect ~319.6):    ', isect.s_exit
  print, format = '(A,F8.1)', '  path_length km (expect ~134.7):', isect.path_length
  print, ''

  ; Test 7: Case 5 — satellite between spheres, ray pointing outward
  ; sat at [R+55km,0,0], ray in +x. s2_inner < 0 (inner sphere behind).
  ; Entry = 0 (sat inside outer); exit = s2_outer = 5 km.
  print, 'Test 7: Case 5 — sat between spheres, ray outward (expect path=5 km)'
  sat_pos_c5 = [R + 55.0d0, 0.0d, 0.0d]
  sun_dir_c5  = [1.0d, 0.0d, 0.0d]
  osse_find_shell_intersection_3d, sat_pos_c5, sun_dir_c5, R+50.0d0, R+60.0d0, isect
  print, format = '(A,I2)',   '  intersects (expect 1):         ', isect.intersects
  print, format = '(A,F8.1)', '  s_entry km (expect 0.0):       ', isect.s_entry
  print, format = '(A,F8.1)', '  path_length km (expect 5.0):   ', isect.path_length
  print, ''

  print, '========================================='
  print, 'test_osse_find_shell_intersection_3d complete'
  print, '========================================='
  print, ''
end
