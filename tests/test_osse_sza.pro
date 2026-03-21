; ===============================================================================
; PRO: test_osse_sza
;
; Tests for osse_sza
; ===============================================================================
pro test_osse_sza
  compile_opt idl2

  print, ''
  print, '========================================='
  print, 'TEST: osse_sza'
  print, '========================================='
  print, ''

  ; Test 1: SZA at sub-solar point — should be 0°
  print, 'Test 1: SZA at sub-solar point (expect 0.00°)'
  sza = osse_sza(20.0d, 45.0d, 20.0d, 45.0d)
  print, format = '(A,F8.3,A)', '  SZA: ', sza, '°'
  print, ''

  ; Test 2: SZA at antipodal point — should be 180°
  print, 'Test 2: SZA at antipodal point (expect 180.00°)'
  sza = osse_sza(-20.0d, 45.0d + 180.0d, 20.0d, 45.0d)
  print, format = '(A,F8.3,A)', '  SZA: ', sza, '°'
  print, ''

  ; Test 3: SZA on the terminator — should be 90°
  print, 'Test 3: SZA on terminator, ss at equator 0° (expect 90.00°)'
  sza = osse_sza(0.0d, 90.0d, 0.0d, 0.0d)
  print, format = '(A,F8.3,A)', '  SZA: ', sza, '°'
  print, ''

  ; Test 4: North pole, sub-solar at equator — should be 90°
  print, 'Test 4: North pole, sub-solar on equator (expect 90.00°)'
  sza = osse_sza(90.0d, 0.0d, 0.0d, 0.0d)
  print, format = '(A,F8.3,A)', '  SZA: ', sza, '°'
  print, ''

  print, '========================================='
  print, 'test_osse_sza complete'
  print, '========================================='
  print, ''
end
