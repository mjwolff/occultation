; ===============================================================================
; PRO: run_one_test
;
; Helper: calls a named test procedure via CALL_PROCEDURE, catching any runtime
; errors or debug STOPs. Returns passed=1b if the test completed without error.
; ===============================================================================
pro run_one_test, name, passed
  compile_opt idl2
  error_status = 0
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    passed = 0b
    return
  endif
  call_procedure, name
  catch, /cancel
  passed = 1b
end

; ===============================================================================
; PRO: osse_run_all_tests
;
; Driver routine — runs all osse_ unit tests in sequence and prints a summary
; results table.
; ===============================================================================
pro osse_run_all_tests
  compile_opt idl2

  ; Path setup — works regardless of working directory
  this_dir = file_dirname(routine_filepath('osse_run_all_tests'))
  !path = expand_path(this_dir) + ':' + expand_path(this_dir + '/../src') + ':' + !path

  tests = [ $
    'test_osse_latlon_to_cartesian', $
    'test_osse_cartesian_to_latlon', $
    'test_osse_sspt_to_sun_direction', $
    'test_osse_sza', $
    'test_osse_find_shell_intersection_3d', $
    'test_osse_trace_ray_occultation_3d', $
    'test_osse_construct_pathlength', $
    'test_osse_generate_integration_points', $
    'test_osse_local_true_solar_time' $
  ]
  n_tests = n_elements(tests)
  status = strarr(n_tests)

  print, ''
  print, '######################################'
  print, '# OSSE TEST SUITE'
  print, '######################################'
  print, ''

  for i = 0, n_tests - 1 do begin
    run_one_test, tests[i], passed
    status[i] = passed ? 'OK' : 'FAIL'
  endfor

  ; ---- Summary table ----
  print, ''
  print, '========================================='
  print, 'RESULTS'
  print, '========================================='
  for i = 0, n_tests - 1 do begin
    print, format = '(A,T50,A)', '  ' + tests[i], status[i]
  endfor
  print, '-----------------------------------------'
  n_pass = fix(total(status eq 'OK'))
  n_fail = n_tests - n_pass
  print, format = '(A,I0,A,I0,A)', '  ', n_pass, ' / ', n_tests, ' passed'
  if n_fail gt 0 then $
    print, format = '(A,I0,A)', '  *** ', n_fail, ' FAILED ***'
  print, '========================================='
  print, ''
end
