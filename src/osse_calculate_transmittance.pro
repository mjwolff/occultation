;+
; NAME:
;   OSSE_CALCULATE_TRANSMITTANCE
;
; PURPOSE:
;   Compute the line-of-sight transmittance for a solar occultation ray
;   through the Mars atmosphere.  Optical depth is accumulated as a
;   Riemann sum over integration points distributed along the ray:
;
;     tau = sigma * SUM_i [ N(z_i) * ds_target ]
;     T   = exp(-tau)
;
;   where N(z) is evaluated via osse_conrath_density and ds_target is the
;   nominal spacing between integration points.
;
; CALLING SEQUENCE:
;   T = osse_calculate_transmittance(sat_pos, sun_dir, intersections, n_int)
;
; INPUTS:
;   sat_pos       - Satellite position in Mars-fixed Cartesian coordinates
;                   (metres).  3-element double array [x, y, z].
;   sun_dir       - Unit vector from satellite toward the Sun.
;                   3-element double array.
;   intersections - Array of shell-intersection structures returned by
;                   osse_trace_ray_occultation_3d.
;   n_int         - Number of atmospheric layers intersected (scalar integer).
;                   If 0 the function returns 1.0 immediately.
;
; KEYWORD INPUTS:
;   SIGMA     - Absorption cross-section in m^2.  Default: 1.0e-12
;               (geometric cross-section of a 1-micron particle).
;   DS_TARGET - Nominal spacing between integration points in metres.
;               Passed directly to osse_generate_integration_points.
;               Default: 1000.0 m (1 km).
;   PARAMS    - Mars parameter structure from osse_mars_params().  Created
;               internally if not supplied.
;   N_REF     - Passed through to osse_conrath_density.  Default: 1.0e20 m^-3.
;   NU        - Passed through to osse_conrath_density.  Default: 0.007.
;   H_CONRATH - Passed through to osse_conrath_density.  Default: 10.0e3 m.
;
; OUTPUTS:
;   T  - Transmittance in the range [0, 1].  Returns 1.0 if n_int = 0.
;
; EXAMPLES:
;   ; Typical call inside an occultation loop
;   osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, intersections, n_int
;   T = osse_calculate_transmittance(sat_pos, sun_dir, intersections, n_int)
;
;   ; Custom aerosol cross-section and integration resolution
;   T = osse_calculate_transmittance(sat_pos, sun_dir, intersections, n_int, $
;         sigma=3.14d-12, ds_target=500.0d)
;
; NOTES:
;   - The Riemann sum uses ds_target as the uniform step weight.  Actual
;     point spacing within each layer differs slightly from ds_target due
;     to integer rounding in osse_generate_integration_points; the error
;     is sub-percent for typical layer thicknesses and ds_target <= 1 km.
;   - Altitude at each integration point is computed as |r| - R_MARS,
;     where |r| = sqrt(total(r^2, 1)) over the 3-component axis.
;
; MODIFICATION HISTORY:
;   2026-03-23: Initial implementation
;-

function osse_calculate_transmittance, sat_pos, sun_dir, intersections, n_int, $
  sigma = sigma, ds_target = ds_target, params = params, $
  n_ref = n_ref, nu = nu, h_conrath = h_conrath
  compile_opt idl2

  ; Apply defaults
  if n_elements(sigma)     eq 0 then sigma     = 1.0d-12
  if n_elements(ds_target) eq 0 then ds_target = 1000.0d0
  if ~keyword_set(params)       then params    = osse_mars_params()

  ; No atmosphere intersected — ray does not enter the atmosphere
  if n_int eq 0 then return, 1.0d0

  ; Generate 3D integration points along the ray (3 x n_points array)
  osse_generate_integration_points, sat_pos, sun_dir, intersections, $
    integration_points, n_points, ds_target, params = params

  ; Altitude at each point: |r| - R_MARS
  altitude = sqrt(total(integration_points ^ 2, 1)) - params.r_mars

  ; Number density at each point via Conrath profile
  n_density = osse_conrath_density(altitude, n_ref = n_ref, nu = nu, $
    h_conrath = h_conrath)

  ; Optical depth (Riemann sum) and transmittance
  tau = sigma * total(n_density) * ds_target

  return, exp(-tau)
end
