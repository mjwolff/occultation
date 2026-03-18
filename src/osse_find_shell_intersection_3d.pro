; ==============================================================================
; FIND 3D SHELL INTERSECTION WITH ENTRY/EXIT POINTS
; ==============================================================================
;
; 2026/02/08 (mjw):  set r_inner, r_outer, altitude in INTERSECTION structure
;                        which was not previously done correctly
;

pro osse_find_shell_intersection_3d, sat_pos, sun_dir, r_inner, r_outer, $
  intersection
  compile_opt idl2, hidden

  intersection = osse_create_shell_intersection()
  params = osse_mars_params()

  ; Initialize intersection structure
  intersection.intersects = 0b
  intersection.path_length = 0.0d
  intersection.s_entry = 0.0d
  intersection.s_exit = 0.0d
  intersection.r_inner = r_inner
  intersection.r_outer = r_outer
  intersection.altitude = 0.5*(r_inner+r_outer) - params.r_mars
  s1_outer = 0.d0
  s1_inner = 0.d0
  s2_inner = 0.d0
  s2_outer = 0.d0


  ; Ray equation: r(s) = sat_pos + s * sun_dir
  ; Sphere equation: |r|^2 = R^2
  a = total(sun_dir * sun_dir) ; Should be 1 for unit vector
  b = total(sat_pos * sun_dir)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Check intersection with outer sphere
  c = total(sat_pos * sat_pos) - r_outer ^ 2
  discriminant = b ^ 2 - a * c

  hit_outer = 0b
  if discriminant ge 0.0d then begin
    s1_outer = (-b - sqrt(discriminant)) / a
    s2_outer = (-b + sqrt(discriminant)) / a
    hit_outer = 1b
  endif
  intersection.discriminant_outer = discriminant

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Check intersection with inner sphere
  c = total(sat_pos * sat_pos) - r_inner ^ 2
  discriminant = b ^ 2 - a * c

  hit_inner = 0b
  if discriminant ge 0.0d then begin
    s1_inner = (-b - sqrt(discriminant)) / a
    s2_inner = (-b + sqrt(discriminant)) / a
    hit_inner = 1b
  endif
  intersection.discriminant_inner = discriminant

  ; Calculate entry and exit points for shell
  if hit_outer and not hit_inner then begin
    ; Ray passes through entire shell (tangent ray)
    if s1_outer gt 0.0d and s2_outer gt 0.0d then begin
      intersection.s_entry = s1_outer
      intersection.s_exit = s2_outer
      intersection.path_length = s2_outer - s1_outer
      intersection.intersects = 1b
      print,'case 1'
    endif else if s2_outer gt 0.0d then begin
      ; Satellite inside outer sphere
      intersection.s_entry = 0.0d
      intersection.s_exit = s2_outer
      intersection.path_length = s2_outer
      intersection.intersects = 1b
      print,'case 2'
    endif
  endif else if hit_outer and hit_inner then begin
    ; Ray enters and exits shell
    if s2_outer gt 0.0d then begin
      if s1_inner gt 0.0d then begin
        ; Two segments: before and after inner sphere
        intersection.s_entry = (s1_outer > 0.0d)
        intersection.s_exit = s2_outer
        intersection.path_length = (s1_inner - (s1_outer > 0.0d)) + $
          (s2_outer - s2_inner)
        intersection.intersects = 1b
        ;print,'case 3'
      endif else if s2_inner gt 0.0d then begin
        ; Only exit segment
        intersection.s_entry = s2_inner
        intersection.s_exit = s2_outer
        intersection.path_length = s2_outer - s2_inner
        intersection.intersects = 1b
        print,'case 4.c'
      endif else begin
        ; Entire outer segment
        intersection.s_entry = (s1_outer > 0.0d)
        intersection.s_exit = s2_outer
        intersection.path_length = s2_outer - (s1_outer > 0.0d)
        intersection.intersects = 1b
        print,'case 5'
      endelse
    endif
  endif
  intersection.s1_outer = s1_outer
  intersection.s1_inner = s1_inner
  intersection.s2_inner = s2_inner
  intersection.s2_outer = s2_outer
  ;print,[r_inner,r_outer,intersection.s_entry,intersection.s_exit,s1_outer,s1_inner,s2_inner,s2_outer]/1000.,$
  ;       format='(8(f6.1,1x))'

  ; Calculate 3D positions at entry and exit
  if intersection.intersects then begin
    intersection.pos_entry = sat_pos + intersection.s_entry * sun_dir
    intersection.pos_exit = sat_pos + intersection.s_exit * sun_dir
  endif

end
