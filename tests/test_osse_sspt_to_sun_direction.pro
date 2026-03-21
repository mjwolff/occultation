; ===============================================================================
; PRO: test_osse_sspt_to_sun_direction
;
; Tests for osse_sspt_to_sun_direction
; ===============================================================================
pro test_osse_sspt_to_sun_direction
  compile_opt idl2

  print, ''
  print, '========================================='
  print, 'TEST: osse_sspt_to_sun_direction'
  print, '========================================='
  print, ''

  ; Satellite at equator, 0°E, 400 km — used throughout
  sat_pos = osse_latlon_to_cartesian(0.0d, 0.0d, 400.0d3)

  ; Test 1: Sub-solar at 0°N, 180°E — sun should be in -x direction
  print, 'Test 1: Sub-solar at 0°N 180°E (opposite satellite)'
  sun_dir = osse_sspt_to_sun_direction(0.0d, 180.0d, sat_position = sat_pos)
  print, format = '(A,3F10.6)', '  Sun direction:          ', sun_dir
  print, format = '(A)',        '  Expected:               [-1, 0, 0]'
  print, format = '(A,F10.6)', '  Magnitude (expect 1.0): ', sqrt(total(sun_dir ^ 2))
  print, ''

  ; Test 2: Sub-solar at 0°N, 90°E — sun should be in +y direction
  print, 'Test 2: Sub-solar at 0°N 90°E (no parallax)'
  sun_dir = osse_sspt_to_sun_direction(0.0d, 90.0d)
  print, format = '(A,3F10.6)', '  Sun direction:          ', sun_dir
  print, format = '(A)',        '  Expected:               [0, 1, 0]'
  print, format = '(A,F10.6)', '  Magnitude (expect 1.0): ', sqrt(total(sun_dir ^ 2))
  print, ''

  ; Test 3: With sat_position vs without — difference should be tiny (parallax << 1 AU)
  print, 'Test 3: Parallax effect (sat_position vs no sat_position)'
  sun_dir_with = osse_sspt_to_sun_direction(20.0d, 45.0d, sat_position = sat_pos)
  sun_dir_no   = osse_sspt_to_sun_direction(20.0d, 45.0d)
  diff = sqrt(total((sun_dir_with - sun_dir_no) ^ 2))
  print, format = '(A,3F10.6)', '  With sat_pos:           ', sun_dir_with
  print, format = '(A,3F10.6)', '  Without sat_pos:        ', sun_dir_no
  print, format = '(A,E10.3)', '  |difference| (expect ~1e-5): ', diff
  print, ''

  print, '========================================='
  print, 'test_osse_sspt_to_sun_direction complete'
  print, '========================================='
  print, ''
end
