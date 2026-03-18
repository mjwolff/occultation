; ==============================================================================
; SHELL INTERSECTION STRUCTURE
; ==============================================================================
function osse_create_shell_intersection
  compile_opt idl2, hidden

  intersection = { $
    r_inner: 0.0d, $ ; Inner radius of shell (m)
    r_outer: 0.0d, $ ; Outer radius of shell (m)
    altitude: 0.0d, $ ; Mid-layer altitude (m)
    s_entry: 0.0d, $ ; Ray parameter at entry
    s_exit: 0.0d, $ ; Ray parameter at exit
    s1_outer: 0.d0, $
    s1_inner: 0.d0, $
    s2_inner: 0.d0, $
    s2_outer: 0.d0, $
    discriminant_inner: 0.d0, $ ; > 0, 2 pts - = 0, tangent ray
    discriminant_outer: 0.d0, $ ; > 0, 2 pts - = 0, tangent ray
    path_length: 0.0d, $ ; Path length through shell (m)
    pos_entry: dblarr(3), $ ; 3D position at entry (m)
    pos_exit: dblarr(3), $ ; 3D position at exit (m)
    intersects: 0b $ ; Whether ray intersects this shell
    }

  RETURN, intersection
end
