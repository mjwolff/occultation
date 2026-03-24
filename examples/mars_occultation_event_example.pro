;+
; NAME:
;   MARS_OCCULTATION_EVENT_EXAMPLE
;
; PURPOSE:
;   Demonstrate mars_occultation_event_raytrace by running a default survey
;   and ray-tracing the first detected event.
;
; CALLING SEQUENCE:
;   mars_occultation_event_example
;
; MODIFICATION HISTORY:
;   2026-03-24: Initial implementation
;-

pro mars_occultation_event_example
  compile_opt idl2

  ; Run survey with default parameters (5 orbits, TGO-like orbit, LsubS=90)
  mars_occultation_survey, survey = survey

  if survey.n_ingress + survey.n_egress eq 0 then begin
    print, 'No events found in default survey.'
    return
  endif

  ; Ray-trace the first event
  mars_occultation_event_raytrace, survey, 0, result, /verbose

  print, '================================================='
  print, 'Result fields available:'
  print, '  result.time          - time array (s)'
  print, '  result.tang_alt      - tangent altitude (km)'
  print, '  result.transmittance - line-of-sight transmittance'
  print, '  result.n_int         - layers intersected per step'
  print, '  result.path_info     - pointer array of pathlength structs'
  print, '  result.event         - event struct (type, times, geometry)'
  print, '================================================='
  print, ''

  ; Plot transmittance vs tangent altitude
  plot, result.transmittance, result.tang_alt, $
    xrange = [0, 1], xstyle = 1, $
    yrange = [0, 110], ystyle = 1, $
    xtitle = 'Transmittance', $
    ytitle = 'Tangent Altitude (km)', $
    title = 'Event ' + strtrim(0, 2) + ' (' + result.event.type + '): Transmittance vs Altitude', $
    psym = -1, symsize = 0.8

end
