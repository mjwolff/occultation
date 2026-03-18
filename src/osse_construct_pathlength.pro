; ==============================================================================
; Convert the Intersections along a ray into an ordered list of pathlength
; points through the atmosphere (in the direction to the sun)
;
; ==============================================================================
pro osse_construct_pathlength,intersections,s_inbound,s_outbound,params=params

 COMPILE_OPT idl2
; if parameter structure not passed, generate it
    if ~KEYWORD_SET(params) then params=osse_mars_params()

 ; start with the inner shells and move outward, constructing an inbound and outbound path
    first_one = 0b
    for ii=0,params.N_LAYERS-1 do begin

        if intersections[ii].intersects then begin
            if NOT first_one then begin
               s_inbound = [intersections[ii].s1_inner]
               s_outbound = [intersections[ii].s2_inner]
               first_one = 1b
            endif
          ; check tangent layer (only outer shell crossed)
            pathlength = intersections[ii].path_length
            check = intersections[ii].s_exit - intersections[ii].s_entry
            if pathlength eq check then begin
               message,'make sure this case is handled',/info
               stop
            endif else begin
               s_inbound = [intersections[ii].s_entry,s_inbound]
               s_outbound = [s_outbound,intersections[ii].s_exit]
            endelse
        endif 

    ; end loop over layers    
    endfor

    return
end