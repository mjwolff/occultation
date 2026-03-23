;+
; NAME:
;   OSSE_CONRATH_DENSITY
;
; PURPOSE:
;   Compute atmospheric number density as a function of altitude using the
;   Conrath profile.  The profile is parameterised as:
;
;     N(z) = N_ref * exp( nu * (1 - exp(z / H_c)) )
;
;   At z = 0 the function returns N_ref.  The density decreases
;   monotonically with altitude and approaches zero for z >> H_c.
;   The profile is intended as a placeholder for a GCM-derived density
;   field; callers should supply their own n_ref, nu, and h_conrath to
;   match a specific species or retrieval scenario.
;
; CALLING SEQUENCE:
;   N = osse_conrath_density(altitude)
;
; INPUTS:
;   altitude  - Altitude above the Mars surface in km.  Scalar or
;               any-size array.
;
; KEYWORD INPUTS:
;   N_REF     - Surface number density in m^-3.  Default: 1.0e20.
;   NU        - Conrath shape parameter (dimensionless).  Controls how
;               rapidly the density falls off above H_c.  Default: 0.007.
;   H_CONRATH - Characteristic height scale in km.  Default: 10.0d0
;               (10 km).
;
; OUTPUTS:
;   N  - Number density in m^-3.  Same dimensions as altitude.
;
; EXAMPLES:
;   ; Surface density with default parameters
;   print, osse_conrath_density(0.0d)                     ; -> 1.0e20
;
;   ; Profile at several altitudes
;   z = [0.0d, 10.0d, 50.0d, 100.0d]
;   print, osse_conrath_density(z)
;
;   ; Custom species parameters
;   N = osse_conrath_density(z, n_ref=2.5d19, nu=0.01d, h_conrath=8.0d0)
;
; NOTES:
;   - At z = 0 the exponent reduces to nu*(1-1) = 0, so N = N_ref exactly
;     regardless of nu and h_conrath.
;   - For z >> h_conrath the exponent becomes large and negative, driving
;     N toward zero.  With default parameters N < 0.001 * N_ref above ~70 km.
;
; MODIFICATION HISTORY:
;   2026-03-23: Initial implementation
;-

function osse_conrath_density, altitude, n_ref = n_ref, nu = nu, h_conrath = h_conrath
  compile_opt idl2

  if n_elements(n_ref)     eq 0 then n_ref     = 1.0d20
  if n_elements(nu)        eq 0 then nu        = 0.007d0
  if n_elements(h_conrath) eq 0 then h_conrath = 10.0d0

  return, n_ref * exp(nu * (1.0d0 - exp(altitude / h_conrath)))
end
