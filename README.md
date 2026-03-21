# Mars Occultation Ray Tracer

IDL library for computing solar occultation ray paths through the Mars atmosphere. Given a satellite position and sun direction, the code traces a ray through a 100-layer spherical shell atmosphere and returns the shell intersection geometry and sightline sampling points.

---

## Directory Structure

```
occultation/
├── src/          — core library routines
├── examples/     — driver programs
├── docs/         — documentation and planning files
└── tests/        — (reserved)
```

---

## Routine Summaries

### `src/` — Core Library

**`osse_mars_params`** *(function)*
Returns a structure of physical constants and grid parameters: Mars radius (3397 km), 100-layer shell radii (1 km spacing, surface to 100 km), surface number density, scale height, and max integration points. No inputs; called by nearly every other routine.

---

**`osse_create_shell_intersection`** *(function)*
Factory function that returns a blank intersection structure. Fields: inner/outer radii, mid-layer altitude, entry/exit ray parameters (`s_entry`, `s_exit`), the four individual sphere crossing parameters (`s1/s2_inner/outer`), discriminants, entry/exit 3D positions, path length, and an `intersects` flag.

---

**`osse_find_shell_intersection_3d`** *(procedure)*
Computes the intersection of a ray with a single spherical shell (defined by `r_inner`, `r_outer`). Uses the quadratic ray–sphere formula to find crossing parameters for each sphere, then classifies the geometry into cases (tangent ray, satellite inside/outside, two-segment path). Populates and returns an intersection structure.

---

**`osse_trace_ray_occultation_3d`** *(procedure)*
Top-level ray tracer. Given satellite position and sun direction, loops over all 100 atmospheric layers and calls `osse_find_shell_intersection_3d` for each. Computes the impact parameter (tangent altitude) and skips layers below it. Returns an array of intersection structures and the count of intersected layers. Traps rays that miss the atmosphere or hit the planet.

---

**`osse_construct_pathlength`** *(procedure)*
Converts the intersection array from `osse_trace_ray_occultation_3d` into two ordered 1-D arrays: `s_inbound` (ray parameters on the inbound leg, inner-to-outer) and `s_outbound` (outbound leg). Together with the tangent point `s_tangent`, these form the complete sorted sightline sampling grid.

---

**`osse_generate_integration_points`** *(procedure)*
Generates 3D Cartesian positions along the ray at a target step size `ds_target`, distributing points within each intersected shell. Returns a `[3, n_points]` array. Note: this routine exists but is not called by the current example drivers — they use `osse_construct_pathlength` instead.

---

**`osse_local_true_solar_time`** *(function)*
Computes Local True Solar Time (LTST) in decimal hours [0, 24) at one or more geographic longitudes given the sub-solar longitude at the observation epoch. LTST is 12:00 h when the Sun is on the meridian and advances by 1 h per 15° eastward. Accepts scalar or array longitude input; `ss_lon` must be a scalar (a property of the time instant, obtained from `sp_calculate_subsolar_longitude`).

---

**`osse_mars_coordinates`** *(file — multiple routines)*

| Routine | Type | Purpose |
|---|---|---|
| `osse_latlon_to_cartesian` | function | Geodetic (lat, lon, alt) → Mars-centered Cartesian (m) |
| `osse_cartesian_to_latlon` | function | Cartesian → geodetic structure (lat, lon, alt) |
| `osse_sspt_to_sun_direction` | function | Sub-solar point + optional satellite position → unit sun vector |
| `osse_sza` | function | Solar zenith angle at a surface point |
| `test_coordinate_conversions` | procedure | Standalone validation tests |
| `osse_mars_coordinates` | procedure | Prints a usage menu (compile entry point) |

---

### `examples/` — Driver Programs

**`mars_example`**
Standalone hardcoded driver. Sets a fixed sub-solar point and steps a satellite through a range of longitudes at 400 km altitude. For each position it: converts to Cartesian, computes sun direction, finds the tangent point, calls `osse_trace_ray_occultation_3d`, then calls `osse_construct_pathlength` and converts each sightline sample to lat/lon/alt. Results stored in pointer array `path_info`.

**`mars_occultation_orbit`**
Orbit-driven driver. Replaces the hardcoded longitude sweep with Keplerian orbital propagation from the sibling `satellite_position` library (`sp_propagate_orbit`, `sp_mars_constants`, `sp_calculate_subsolar_latitude/longitude`). Otherwise follows the same ray-trace and path-construction logic as `mars_example`. Produces the same output structure `a`.

**`mars_occultation_survey`**
Multi-orbit survey that propagates the orbit, computes the tangent altitude at every time step, and identifies occultation events. Two event types are detected:

| Type | Definition | tang_alt trend |
|---|---|---|
| **INGRESS** | Starts when tang_alt crosses `altitude_max` (descending); ends when tang_alt crosses 0 km (descending) | Decreasing |
| **EGRESS** | Starts when tang_alt crosses 0 km (ascending); ends when tang_alt crosses `altitude_max` (ascending) | Increasing |

A complete solar occultation consists of one INGRESS followed by one EGRESS, separated by a sub-zero gap where the ray passes through the planet. Only event pairs where both halves fall entirely within the simulated interval are reported. Returns a `survey` structure containing the full `tang_alt` time series and an `events` array with one record per half-event (type, start/end times, duration, deepest-point latitude and longitude).

Keywords: `NORBITS` (default 5), `DT` (default period/1000), `ALTITUDE_MAX` (default 100 km), `LSUBS` (areocentric solar longitude in degrees, default 90.0 — northern summer solstice), `VERBOSE`.

---

## Calling Structure

```
mars_example  /  mars_occultation_orbit  /  mars_occultation_survey
│
├── osse_mars_params()                       [parameters]
├── osse_mars_coordinates                    [compile / init]
│
├── osse_latlon_to_cartesian()               [sat pos]
├── osse_sspt_to_sun_direction()             [sun dir]
├── osse_cartesian_to_latlon()               [tangent point coords]
│
├── osse_trace_ray_occultation_3d            [ray trace loop]
│   ├── osse_mars_params()
│   ├── osse_create_shell_intersection()     [struct factory]
│   └── osse_find_shell_intersection_3d      [per-layer geometry]
│       ├── osse_create_shell_intersection()
│       └── osse_mars_params()
│
└── osse_construct_pathlength                [sightline sampling]
    └── osse_mars_params()

[osse_generate_integration_points]          [not called by drivers]
    └── osse_mars_params()
```

`mars_occultation_orbit` additionally calls (from `satellite_position/src/`):
- `sp_mars_constants()`
- `sp_propagate_orbit()`
- `sp_calculate_subsolar_latitude()`
- `sp_calculate_subsolar_longitude()`
