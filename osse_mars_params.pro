;===============================================================================
; PHYSICAL CONSTANTS AND PARAMETERS
;===============================================================================
FUNCTION osse_mars_params
  COMPILE_OPT idl2, hidden

  nlayer = 100L
  r_mars = 3397.d3
  radii = fltarr(nlayer+1)
  dr = 1000.d0
  for i=0,nlayer do begin
      radii[i] = r_mars + i*dr
  endfor
  
  params = { $
    PI:         !DPI, $
    R_MARS:     r_mars, $        ; Mars radius in meters
    RADII:      radii, $         ; radii of shells
    H_ATM:      100.0D3, $         ; Atmosphere height in meters
    N_LAYERS:   nlayer, $          ; Number of atmospheric layers
    N0:         1.0D20, $          ; Surface number density (m^-3)
    H_SCALE:    11.1D3, $          ; Scale height (m)
    MAX_INT_PTS: 10000L $          ; Maximum integration points
  }
  
  RETURN, params
END

