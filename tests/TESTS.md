# Unit Test Documentation

All tests live in `tests/` and are run together via `osse_run_all_tests.pro`.
Each test procedure prints per-case results to the console; the runner
catches any `MESSAGE`/`STOP` errors and records PASS or FAIL in the summary
table.

Units throughout: distances in **km**, densities in **m^-3**, angles in
**degrees**, times in **hours**.

---

## test_osse_latlon_to_cartesian

**Source:** `tests/test_osse_latlon_to_cartesian.pro`

Tests the forward coordinate conversion from geodetic (lat, lon, altitude)
to Mars-centred Cartesian (x, y, z). Validation cases are all derived from
exact geometry — positions on the coordinate axes have analytically known
Cartesian representations.

| # | Case | Validation source |
|---|------|--------------------|
| 1 | Equator, 0° lon, 400 km alt → position on +x axis | Exact: `[R+400, 0, 0]` km |
| 2 | North pole, 500 km alt → position on +z axis | Exact: `[0, 0, R+500]` km |
| 3 | 45°N, 90°E, 300 km alt → x=0, y=z (45° diagonal in y-z plane) | Exact geometry of cos/sin decomposition |
| 4 | Round-trip: latlon→Cartesian→latlon recovers inputs to floating-point precision | Internal consistency; expected residual < machine epsilon |
| 5 | South pole, 500 km alt → position on −z axis | Exact: `[0, 0, -(R+500)]` km |
| 6 | Zero altitude (surface) → magnitude equals R_MARS exactly | By construction of the formula `r = R + alt` |
| 7 | Longitude near 360° boundary (lon=359.9°) → round-trip returns same longitude | Boundary check; no wrap-around to negative |
| 8 | lon=0 and lon=360 produce the same Cartesian position | cos is periodic; difference bounded by float64 rounding (~1.5e-4 km) |

---

## test_osse_cartesian_to_latlon

**Source:** `tests/test_osse_cartesian_to_latlon.pro`

Tests the inverse coordinate conversion from Mars-centred Cartesian to
geodetic. All validation values are exact for positions on coordinate axes.

| # | Case | Validation source |
|---|------|--------------------|
| 1 | +x axis at 400 km → lat=0, lon=0, alt=400 km | Exact; arcsin(0)=0, arctan2(0,R+400)=0 |
| 2 | +z axis at 500 km → lat=90, lon=0, alt=500 km | Exact; arcsin(1)=90° |
| 3 | Mars centre [0,0,0] → guard case, altitude = −R_MARS | Guard branch: `r < 0.001 km` returns `{0, 0, −R_MARS}` |
| 4 | Round-trip from latlon_to_cartesian → recovers lat, lon, alt exactly | Internal consistency |
| 5 | −x axis at 400 km → lat=0, lon=180, alt=400 km | Exact; arctan2(0,−(R+400))=180° |
| 6 | −z axis at 500 km → lat=−90, lon=0, alt=500 km | Exact; arcsin(−1)=−90° |
| 7 | −y axis at 300 km → lon=270° (not negative) | Checks the `lon + 360` wrap branch |

---

## test_osse_sspt_to_sun_direction

**Source:** `tests/test_osse_sspt_to_sun_direction.pro`

Tests the unit sun-direction vector computed from the sub-solar point.
Exact results apply when the geometry aligns with a coordinate axis.

| # | Case | Validation source |
|---|------|--------------------|
| 1 | Sub-solar at 0°N, 180°E with satellite at 0°N, 0°E → sun direction = [−1, 0, 0] | Exact; Sun is directly opposite the satellite along the x axis |
| 2 | Sub-solar at 0°N, 90°E, no sat_position offset → sun direction = [0, 1, 0] | Exact; Sun lies along +y at infinite distance |
| 3 | Parallax: `with sat_position` vs `without` differ by ~1e-5 | Physical estimate: satellite is ~3800 km from Mars centre vs 1.52 AU to Sun, giving angular parallax ~1.7×10⁻⁵ rad |

---

## test_osse_sza

**Source:** `tests/test_osse_sza.pro`

Tests the solar zenith angle function using the four canonical geometric
configurations where the SZA is known exactly.

| # | Case | Validation source |
|---|------|--------------------|
| 1 | Observation point at the sub-solar point → SZA = 0° | By definition; cos(SZA) = 1 |
| 2 | Observation point at the antipodal point → SZA = 180° | By definition; cos(SZA) = −1 |
| 3 | Observation 90° from sub-solar along equator → SZA = 90° | Terminator; cos(SZA) = 0 |
| 4 | North pole with equatorial sub-solar point → SZA = 90° | Pole lies on the terminator when sub-solar is at equator; angular separation = 90° |

---

## test_osse_find_shell_intersection_3d

**Source:** `tests/test_osse_find_shell_intersection_3d.pro`

Tests intersection geometry of a ray with a spherical shell (inner/outer
bounding spheres). All path lengths and entry distances are computed from
exact chord geometry.

| # | Case | Validation source |
|---|------|--------------------|
| 1 | Empty structure from `osse_create_shell_intersection` | Constructor check; all fields zero |
| 2 | Satellite at 400 km on +x, ray in −x, shell at 50–60 km → symmetric double traverse, path_length=20 km, s_entry=340 km | Chord geometry: entry at R+60 (340 km from sat), exit at R+50, re-entry at R+50, exit at R+60; path = 2×10 km |
| 3 | Ray pointing outward away from planet → no intersection | Shell is entirely behind the satellite |
| 4 | Tangent ray grazing outer sphere exactly → discriminant_outer=0, no intersection | Discriminant = 0 is treated as no entry (strict inequality check) |
| 5 | Satellite inside outer sphere, ray perpendicular (Case 2 geometry) → s_entry=0, path_length≈185.9 km | Entry set to satellite position (s=0); exit = half-chord of inner sphere at 60 km radius |
| 6 | Satellite inside inner sphere, outward-crossing ray (Case 4) → only exit segment, s_entry≈184.9 km, path≈134.7 km | Half-chord difference between inner (50 km) and outer (60 km) spheres at a 45° offset |
| 7 | Satellite between spheres, ray pointing outward (Case 5) → entry=0, path=5 km | Satellite is 5 km inside the 60 km outer shell; path to outer boundary is exactly 5 km |

---

## test_osse_trace_ray_occultation_3d

**Source:** `tests/test_osse_trace_ray_occultation_3d.pro`

Tests the top-level ray tracer that loops over all 100 atmospheric shells
and counts intersections.

| # | Case | Validation source |
|---|------|--------------------|
| 1 | Satellite at 200 km, perpendicular ray → tangent alt = 200 km, n_int = 0 | Impact parameter = R+200 > R+H_ATM = R+100; ray misses atmosphere |
| 2 | Nadir-pointing ray from 400 km → tangent alt < 0, n_int = 0 | Ray hits planet; tracer returns immediately |
| 3 | Ray aimed for 50.5 km tangent altitude → n_int = 49 | Layers 51–99 km are intersected (50 shells); the 50.5 km tangent falls inside layer 50–51, which is excluded because `r_inner < impact`; count = 100 − 51 = 49 |
| 4 | `tang_alt` from tracer vs altitude from `osse_cartesian_to_latlon` at the geometric tangent point | Internal consistency; both compute the impact parameter via different code paths; expected agreement to floating-point precision (< 0.01 km) |
| 5 | Satellite inside atmosphere at 80 km → n_int = 20 | Layers with r_inner ≥ R+80 km: layers 80–99 = 20 shells |
| 6 | Tangent exactly at 100 km (top of atmosphere) → n_int = 0 | `impact_param = R+H_ATM`; the `gt` check is strict so no layer passes; all r_inner ≥ impact condition fails |

---

## test_osse_construct_pathlength

**Source:** `tests/test_osse_construct_pathlength.pro`

Tests that `osse_construct_pathlength` correctly assembles sorted inbound
and outbound ray-parameter arrays from intersection structures. Tangent
altitudes of 50.5 km and 98.5 km are used to avoid landing exactly on a
1-km layer boundary (which triggers a debug `STOP` in the current code; see
`docs/TODO.md` item 10).

| # | Case | Validation source |
|---|------|--------------------|
| 1 | 49-layer geometry (tangent 50.5 km) → n_elements(s_inbound) = 50 | The innermost layer contributes two entries (s_entry and s1_inner) while all others contribute one; total = n_int + 1 |
| 2 | All path segments s_outbound − s_inbound > 0 | Physical requirement; negative segment would indicate reversed entry/exit ordering |
| 3 | s_inbound is monotonically increasing | Segments must be ordered from satellite toward tangent point; any reversal indicates a sorting bug |
| 4 | Single intersecting layer (tangent 98.5 km, layer 99–100 km) → n_int=1, 2 elements, positive total path | Confirms n_int+1 element rule holds for the degenerate single-layer case |

---

## test_osse_generate_integration_points

**Source:** `tests/test_osse_generate_integration_points.pro`

Tests that uniformly-spaced 3D integration points are generated correctly
within each intersecting shell.

| # | Case | Validation source |
|---|------|--------------------|
| 1 | All points satisfy `p = sat_pos + s·sun_dir` → cross-product magnitude < 1e-12 km | Points must lie exactly on the ray; cross product of the offset vector with the direction vector is zero for collinear points |
| 2 | `ds_target` >> any layer path length → minimum 1 step per layer → n_points = 2 × n_int = 98 | Each layer contributes exactly 2 points (entry and exit) when one step is taken |
| 3 | `ds_target = 0.001 km` (1 m) → n_points capped at `MAX_INT_PTS = 10000` | Overflow guard in `osse_generate_integration_points` |
| 4 | All points lie within atmosphere (altitude 0–100 km, 0.001 km tolerance) | Points outside the shell boundaries indicate a ray-parameter error |

---

## test_osse_local_true_solar_time

**Source:** `tests/test_osse_local_true_solar_time.pro`

Tests the Local True Solar Time (LTST) conversion from longitude and
sub-solar longitude. LTST = 12h at the sub-solar meridian, advancing
eastward at 1 hour per 15°.

| # | Case | Validation source |
|---|------|--------------------|
| 1 | lon = ss_lon → LTST = 12.00 h | By definition; sub-solar meridian is local noon |
| 2 | lon = ss_lon + 180° → LTST = 00.00 h | Anti-solar meridian is local midnight |
| 3 | lon = ss_lon − 90° → LTST = 06.00 h | Dawn terminator; 90° west = 6 hours before noon |
| 4 | lon = ss_lon + 90° → LTST = 18.00 h | Dusk terminator; 90° east = 6 hours after noon |
| 5 | Array of four quadrant longitudes → correct LTST at each | Confirms vectorised operation returns correct values simultaneously |
| 6 | Full 361-point longitude sweep → all LTST ∈ [0, 24) | Output range check; no negative values or values ≥ 24 h |
| 7 | lon = −5° gives same result as lon = 355° | Negative longitude equivalence; 360° modular arithmetic |
| 8 | Consecutive 1° steps across the 0°/360° boundary → no discontinuity | Expected step = 2/15 h = 0.1333 h; discontinuity would produce a jump |
| 9 | ss_lon = 355°, observation at lon = 5° → LTST = 12 + 10/15 h | Cross-wrap geometry: 5° is 10° east of 355°, verified analytically |
| 10 | 100,000-element longitude array → correct size and range | Performance and correctness check for large vectorised input |

---

## test_osse_conrath_density

**Source:** `tests/test_osse_conrath_density.pro`

Tests the Conrath atmospheric number density profile:
`N(z) = N_ref · exp(ν · (1 − exp(z / H_c)))`.
With default parameters `N_ref = 1e20 m⁻³`, `ν = 0.007`, `H_c = 10 km`.

| # | Case | Validation source |
|---|------|--------------------|
| 1 | z = 0 with default N_ref → returns 1e20 m⁻³ exactly | At z=0: exp(ν·(1−1)) = exp(0) = 1; N = N_ref regardless of ν or H_c |
| 2 | z = 0 with custom N_ref = 2.5e19 → returns that value exactly | Same identity; confirms keyword is passed correctly |
| 3 | z = 70 km → N < 0.001 · N_ref | With H_c=10 km and ν=0.007: exp(0.007·(1−exp(7))) ≈ 4.7×10⁻⁴; N ≈ 4.7×10¹⁶ m⁻³ |
| 4 | Profile at [0, 10, 20, 50, 100] km decreases monotonically | Physical requirement; Conrath profile has no local maxima above z=0 |
| 5 | 500-element array input → 500-element output | Vectorisation check |
| 6 | Higher ν gives lower density at z = 10 km | Larger shape parameter → faster falloff; analytical from the formula |
| 7 | h_conrath = 1e6 km (≫ 100 km atmosphere) → N ≈ N_ref at all altitudes | exp(z/H_c) ≈ 1 for z ≤ 100 km when H_c = 1e6 km; relative error < 1e-4 |
| 8 | z = 10 km, default parameters → matches analytical formula exactly | Expected: `N_ref · exp(0.007 · (1 − exp(1)))`; confirmed to relative tolerance 1e-10 |

---

## test_osse_calculate_transmittance

**Source:** `tests/test_osse_calculate_transmittance.pro`

Tests line-of-sight transmittance `T = exp(−τ)` where
`τ = σ · Σ N(zᵢ) · ds_target`. Shared geometry: satellite at 400 km,
tangent at 50.5 km (49 intersecting layers). Where optical depths need to
be in a testable range, `n_ref = 1e7 m⁻³` is used (the default `1e20`
gives τ ≫ 1 and T underflows to zero).

| # | Case | Validation source |
|---|------|--------------------|
| 1 | n_int = 0 (outward-pointing ray) → T = 1.0 exactly | No atmosphere intersected; early-return branch |
| 2 | Ray through 49 layers with n_ref = 1e7 → T ∈ (0, 1) | Sanity check; any finite optical depth gives T strictly between 0 and 1 |
| 3 | Constant-N Riemann sum consistency: h_conrath = 1e6 km so N ≈ N_ref everywhere → T_computed matches T_expected = exp(−σ · N_ref · n_points · ds_target) | Internal consistency; both sides use the same Riemann sum formula; relative tolerance 1e-4 (N is not exactly N_ref at finite h_conrath, giving ~4e-6 residual) |
| 4 | Deeper tangent (10.5 km) gives lower T than shallower tangent (50.5 km) | Longer path + denser atmosphere; monotonicity of T with tangent altitude |
| 5 | Larger absorption cross-section σ gives lower T | T = exp(−σ·…) is strictly decreasing in σ |
