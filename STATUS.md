# Project Status

## Date: 2026-03-18

## Repositories

### occultation/ (this repo)
- 1 commit: `TODO.md` only
- IDL 9.1.0 available at /Applications/NV5/idl/bin/idl

### satellite_position/ (sibling repo, ../satellite_position/)
- Mature library: 14 source modules, 10+ tests, TGO real-world example
- Most recent commit: `sp_calculate_subsolar_longitude.pro` (item 1 of TODO)

## TODO Progress

| # | Status | Description |
|---|--------|-------------|
| 1 | [x] | `sp_calculate_subsolar_longitude.pro` created and committed to satellite_position |
| 2 | [ ] | Create `mars_occultation_orbit.pro` skeleton |
| 3 | [ ] | Add `sp_propagate_orbit` call |
| 4 | [ ] | Connect propagator output to `osse_latlon_to_cartesian` |
| 5 | [ ] | Per-step sub-solar longitude formula |
| 6 | [ ] | Complete ray-trace loop body |
| 7 | [ ] | Full loop runtime verification (IDL) |
| 8 | [ ] | Validate `tang_alt` against `mars_example.pro` (IDL) |
| 9 | [ ] | Final git commit of both new source files |

## Next Step
Proceeding with item 2: create `mars_occultation_orbit.pro` skeleton.

## Notes
- `mars_example.pro` is preserved unchanged as the standalone reference
- The lat/lon/alt interface insulates the two codebases' differing Mars radii
- Sub-solar longitude requires user to supply `ss_lon_at_t0` (mission parameter)
