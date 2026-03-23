# Unit Conversion Reference: meters → km

Generated 2026-03-23. Use this as a diagnostic reference if any unit tests fail
after the m→km conversion across the occultation repo.

## satellite_position library
Confirmed entirely in km. Zero meter values. No changes needed.

## Diagnostic notes

1. Core parametric change is in `osse_mars_params.pro`: `r_mars` 3397d3 → 3397.0d0;
   `dr` 1000.d0 → 1.0d0; `H_ATM` 100.0D3 → 100.0d0; `H_SCALE` 11.1D3 → 11.1d0.
2. All `/1000.d0` display divisions removed (values already in km).
3. All `* 1.0d3` km→m interface conversions removed (both sides now in km).
4. 1 AU in `osse_sspt_to_sun_direction.pro`: `1.496d+11` m → `1.496d+8` km.
5. Guard tolerance in `osse_cartesian_to_latlon.pro`: 1.0d m → 0.001d km.
6. `ds_target` defaults: 1000.0d0 m → 1.0d0 km.
7. `h_conrath` default: 10.0d3 m → 10.0d0 km.
8. Large-h_conrath test sentinel: 1.0d9 m → 1.0d6 km.
9. `eps` tolerances in examples: 10.0 m → 0.01 km.
10. Number density (m^-3) is unchanged — density units are independent.

---

## FILE: src/osse_mars_params.pro

  Line 8:  `r_mars = 3397.d3` → `r_mars = 3397.0d0`
  Line 10: `dr = 1000.d0` → `dr = 1.0d0`
  Line 17: `; Mars radius in meters` → `; Mars radius in km`
  Line 19: `H_ATM:      100.0D3, $         ; Atmosphere height in meters` → `H_ATM:      100.0D0, $         ; Atmosphere height in km`
  Line 22: `H_SCALE:    11.1D3, $          ; Scale height (m)` → `H_SCALE:    11.1D0, $          ; Scale height (km)`

## FILE: src/osse_create_shell_intersection.pro

  Line 8:  `r_inner: 0.0d, $ ; Inner radius of shell (m)` → `(km)`
  Line 9:  `r_outer: 0.0d, $ ; Outer radius of shell (m)` → `(km)`
  Line 10: `altitude: 0.0d, $ ; Mid-layer altitude (m)` → `(km)`
  Line 19: `path_length: 0.0d, $ ; Path length through shell (m)` → `(km)`
  Line 20: `pos_entry: dblarr(3), $ ; 3D position at entry (m)` → `(km)`
  Line 21: `pos_exit: dblarr(3), $ ; 3D position at exit (m)` → `(km)`

## FILE: src/osse_latlon_to_cartesian.pro

  Line 11: `altitude  - Altitude above Mars surface in meters` → `in km`
  Line 14: `position - [3] array, Cartesian position vector in meters` → `in km`

## FILE: src/osse_cartesian_to_latlon.pro

  Line 7:  `position - [3] array, Cartesian position vector in meters` → `in km`
  Line 13: `.altitude  - Altitude above Mars surface in meters` → `in km`
  Line 28: `if r lt 1.0d then begin` → `if r lt 0.001d then begin`

## FILE: src/osse_sspt_to_sun_direction.pro

  Line 7:  `sat_position - [3] array, Satellite Cartesian position in meters` → `in km`
  Line 29: `sun_distance = 1.52d0 * 1.496d+11` → `sun_distance = 1.52d0 * 1.496d+8`

## FILE: src/osse_trace_ray_occultation_3d.pro

  Line 79: `tangent_altitude / 1000.0d` → `tangent_altitude`

## FILE: src/osse_conrath_density.pro

  Line 21: `in metres.` → `in km.`
  Line 28: `in metres.  Default: 10.0e3` → `in km.  Default: 10.0d0`
  Line 39: `z = [0.0d, 10.0d, 50.0d, 100.0d] * 1.0d3` → `z = [0.0d, 10.0d, 50.0d, 100.0d]`
  Line 43: `h_conrath=8.0d3` → `h_conrath=8.0d0`
  Line 60: `h_conrath = 10.0d3` → `h_conrath = 10.0d0`

## FILE: src/osse_calculate_transmittance.pro

  Line 21: `(metres).` → `(km).`
  Line 32: `in metres.` → `in km.`
  Line 34: `Default: 1000.0 m (1 km).` → `Default: 1.0 km.`
  Line 39: `Default: 10.0e3 m.` → `Default: 10.0d0 km.`
  Line 52: `ds_target=500.0d` → `ds_target=0.5d`
  Line 72: `ds_target = 1000.0d0` → `ds_target = 1.0d0`

## FILE: examples/mars_example.pro

  Line 22: `eps = 10.` → `eps = 0.01`; comment `(m)` → `(km)`
  Line 32: `sat_alt = 400.0d3` → `sat_alt = 400.0d0`
  Line 40: `sat_alt / 1000.0d` → `sat_alt`
  Line 64: `res_tangent.altitude / 1000.d0` → `res_tangent.altitude`
  Line 79: `tang_alt / 1000.0d` → `tang_alt`  (but check actual current line number)

## FILE: examples/mars_occultation_orbit.pro

  Line 29 (doc): `(m) at each time step` → `(km)`
  Line 119: `eps = 10.0d0 ; meters` → `eps = 0.01d0 ; km`
  Line 136: `sat_alt = result[i].alt * 1.0d3 ; km -> meters` → `sat_alt = result[i].alt ; km`
  Line 150: `res_tangent.altitude / 1000.d0` → `res_tangent.altitude`

## FILE: examples/mars_occultation_survey.pro

  Line 32 (doc): `altitude_max=80.0d3` → `altitude_max=80.0d0`
  Line 40 (doc): `in meters` → `in km`
  Line 55 (doc): `(m)` → `(km)`
  Line 72 (doc): `(m);` → `(km);`
  Line 157: `altitude_max / 1000.d0` → `altitude_max`
  Line 177: `sat_alt = orb[i].alt * 1.0d3 ; km -> m` → `sat_alt = orb[i].alt ; km`
  Line 197: `ta / 1000.d0` → `ta`
  Line 328: `events[k].tang_alt_min / 1000.d0` → `events[k].tang_alt_min`

## FILE: tests/test_osse_find_shell_intersection_3d.pro

  Line 29: `R + 400.0d3` → `R + 400.0d0`
  Line 31: `R+50.0d3, R+60.0d3` → `R+50.0d0, R+60.0d0`
  Line 33: `isect.path_length/1000.d` → `isect.path_length`
  Line 34: `isect.s_entry/1000.d` → `isect.s_entry`
  Line 40: `R+50.0d3, R+60.0d3` → `R+50.0d0, R+60.0d0`
  Line 47: `R + 400.0d3` → `R + 400.0d0`
  Line 49: `R+390.0d3, R+400.0d3` → `R+390.0d0, R+400.0d0`
  Line 52: `isect.path_length/1000.d` → `isect.path_length`
  Line 59: `R + 55.0d3` → `R + 55.0d0`
  Line 61: `R+50.0d3, R+60.0d3` → `R+50.0d0, R+60.0d0`
  Line 63: `isect.s_entry/1000.d` → `isect.s_entry`
  Line 64: `isect.path_length/1000.d` → `isect.path_length`
  Line 71: `R + 45.0d3` → `R + 45.0d0`
  Line 73: `R+50.0d3, R+60.0d3` → `R+50.0d0, R+60.0d0`
  Line 75: `isect.s_entry/1000.d` → `isect.s_entry`
  Line 76: `isect.s_exit/1000.d` → `isect.s_exit`
  Line 77: `isect.path_length/1000.d` → `isect.path_length`
  Line 84: `R + 55.0d3` → `R + 55.0d0`
  Line 86: `R+50.0d3, R+60.0d3` → `R+50.0d0, R+60.0d0`
  Line 88: `isect.s_entry/1000.d` → `isect.s_entry`
  Line 89: `isect.path_length/1000.d` → `isect.path_length`

## FILE: tests/test_osse_cartesian_to_latlon.pro

  Line 19: `params.r_mars + 400.0d3` → `params.r_mars + 400.0d0`
  Line 22: `coords.altitude/1000.d` → `coords.altitude`
  Line 28: `params.r_mars + 500.0d3` → `params.r_mars + 500.0d0`
  Line 31: `coords.altitude/1000.d` → `coords.altitude`
  Line 38: `coords.altitude/1000.d` → `coords.altitude`
  Line 44: `alt_in = 150.0d3` → `alt_in = 150.0d0`
  Line 47: `alt_in/1000.d` → `alt_in`
  Line 48-49: `coords.altitude/1000.d` → `coords.altitude`
  Line 54: `params.r_mars + 400.0d3` → `params.r_mars + 400.0d0`
  Line 56: `coords.altitude/1000.d` → `coords.altitude`
  Line 63: `params.r_mars + 500.0d3` → `params.r_mars + 500.0d0`
  Line 65: `coords.altitude/1000.d` → `coords.altitude`
  Line 72: `params.r_mars + 300.0d3` → `params.r_mars + 300.0d0`

## FILE: tests/test_osse_trace_ray_occultation_3d.pro

  Line 21: `R + 200.0d3` → `R + 200.0d0`
  Line 24: `tang_alt/1000.d` → `tang_alt`
  Line 30: `R + 400.0d3` → `R + 400.0d0`
  Line 33: `tang_alt/1000.d` → `tang_alt`
  Line 42: `R + 400.0d3` → `R + 400.0d0`
  Line 43: `R + 50.5d3` → `R + 50.5d0`
  Line 44: `(R + 400.0d3)` → `(R + 400.0d0)`
  Line 48: `tang_alt/1000.d` → `tang_alt`
  Line 66: `R + 80.0d3` → `R + 80.0d0`
  Line 69: `tang_alt/1000.d` → `tang_alt`
  Line 76: `R + 100.0d3` → `R + 100.0d0`
  Line 79: `tang_alt/1000.d` → `tang_alt`

## FILE: tests/test_osse_construct_pathlength.pro

  Line 33: `R + 400.0d3` → `R + 400.0d0`
  Line 34: `R + 50.5d3` → `R + 50.5d0`
  Line 35: `(R + 400.0d3)` → `(R + 400.0d0)`
  Line 53: `total(seg_lengths)/1000.d` → `total(seg_lengths)`
  Line 65: `R + 98.5d3` → `R + 98.5d0`
  Line 66: `(R + 400.0d3)` → `(R + 400.0d0)`
  Line 78: `total(s_ob1 - s_ib1)/1000.d` → `total(s_ob1 - s_ib1)`

## FILE: tests/test_osse_generate_integration_points.pro

  Line 19: `R + 400.0d3` → `R + 400.0d0`
  Line 20: `R + 50.5d3` → `R + 50.5d0`
  Line 21: `(R + 400.0d3)` → `(R + 400.0d0)`
  Line 35: `1000.0d` (ds_target) → `1.0d0`
  Line 55: `1.0d9` (large ds_target) → stays large (units now km, so 1e9 km still >> any path)
  Line 65: `1.0d` (tiny ds_target, 1 m) → `0.001d0` (0.001 km = 1 m)
  Line 78: `1000.0d` (ds_target) → `1.0d0`
  Line 81: `-1.0d` and `params.h_atm + 1.0d` (1 m tolerance) → `-0.001d0` and `params.h_atm + 0.001d0`

## FILE: tests/test_osse_sspt_to_sun_direction.pro

  Line 16: `400.0d3` (altitude arg to osse_latlon_to_cartesian) → `400.0d0`

## FILE: tests/test_osse_conrath_density.pro

  Line 30: `0.0d0` (z=0, no change)
  Line 35: `70.0d3` → `70.0d0`
  Line 46: `dindgen(n_pts) * 200.0d0` → `dindgen(n_pts) * 0.2d0`; comment `200 m steps` → `0.2 km steps`
  Line 54: `10.0d3` → `10.0d0`
  Line 55: `10.0d3` → `10.0d0`
  Line 63: `50.0d3` → `50.0d0`
  Line 64: `h_conrath = 1.0d9` → `h_conrath = 1.0d6`
  Line 71: `10.0d3` → `10.0d0`

## FILE: tests/test_osse_calculate_transmittance.pro

  Line 16: `r_mars + 400.0d3` → `r_mars + 400.0d0`
  Line 17: `r_mars + 50.5d3` → `r_mars + 50.5d0`
  Line 18: `(r_mars + 400.0d3)` → `(r_mars + 400.0d0)`
  Line 56: `ds_test = 1000.0d0` → `ds_test = 1.0d0`
  Line 80: `r_mars + 10.5d3` → `r_mars + 10.5d0`
  Line 81: `(r_mars + 400.0d3)` → `(r_mars + 400.0d0)`
