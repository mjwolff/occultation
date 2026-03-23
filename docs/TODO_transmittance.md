# LOS Transmittance TODO

## Status key: [ ] not started  [~] in progress  [x] done

1. [x] Create `src/osse_conrath_density.pro`
       Implement analytical Conrath number density profile:
       N(z) = N_ref * exp(nu * (1 - exp(z / H_c)))
       Keywords: n_ref (default 1e20 m^-3), nu (default 0.007),
       h_conrath (default 10e3 m). Accepts scalar or array altitude (m).
       Acceptance: at z=0 returns N_ref; decreases monotonically with
       altitude; at z >> H_c (e.g. z=70 km) returns ~0.

2. [x] Create `src/osse_calculate_transmittance.pro`
       Inputs: sat_pos, sun_dir, intersections, n_int.
       Keywords: sigma (default 1e-12 m^2, geometric cross-section of a
       1-micron particle), ds_target (default 1000.0 m), params, n_ref, nu,
       h_conrath.
       Calls osse_generate_integration_points to obtain 3D sample points
       (shape 3 x n_points).
       At each point: z = sqrt(total(r^2, 1)) - R_MARS where r is the
       3 x n_points position array.
       N = osse_conrath_density(z, n_ref=n_ref, nu=nu, h_conrath=h_conrath).
       tau = sigma * total(N) * ds_target  (Riemann sum); returns T = exp(-tau).
       Acceptance: n_int=0 returns T=1.0; deeper tangent altitude gives lower T.

3. [x] Add unit test `tests/test_osse_conrath_density.pro`
       Acceptance: z=0 returns N_ref; z=70 km returns < 0.001 * N_ref;
       array altitude input returns array output of same size.

4. [x] Add unit test `tests/test_osse_calculate_transmittance.pro`
       For constant-N case: set h_conrath=1e9 m so exp(z/h_conrath) ~= 1
       and N ~= N_ref everywhere; then T = exp(-sigma * N_ref * L) where
       L = total path length through atmosphere (verifiable from geometry).
       Acceptance: computed T matches analytical value within 1%;
       n_int=0 case returns T = 1.0 exactly.

5. [ ] Integrate transmittance into `examples/mars_example.pro`
       Add transmittance = dblarr(npts) before the main loop.
       Call osse_calculate_transmittance inside the loop after
       osse_construct_pathlength; print T per step; add transmittance
       field to the output struct a.
       Acceptance: T values in [0, 1] printed at each step;
       T = 1.0 for positions where n_int = 0.
