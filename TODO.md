# Integration TODO: satellite_position → occultation

## Status key: [ ] not started  [~] in progress  [x] done

1. [x] Create `sp_calculate_subsolar_longitude.pro` in `../satellite_position/src/`
       Acceptance: function returns expected longitude shift for a known Mars rotation interval (e.g. t=88642s → full 360° rotation)

2. [x] Create `mars_occultation_orbit.pro` with IDL path setup, orbital elements block, and sub-solar geometry block (no loop yet)
       Acceptance: file compiles clean in IDL (`RESOLVE_ROUTINE, 'mars_occultation_orbit'` exits without error)

3. [x] Add `sp_propagate_orbit` call and print `.lat`, `.lon`, `.alt` for first time step
       Acceptance: printed values match expected TGO-like orbit geometry (alt ≈ 400 km, lat in [-74°, 74°])

4. [ ] Add unit conversion (`result[i].alt * 1.0d3`) and connect to `osse_latlon_to_cartesian`
       Acceptance: `sat_pos` at lat=0, lon=243.5°, alt=400 km matches the hardcoded equivalent from `mars_example.pro` within 1 km

5. [ ] Implement per-step sub-solar longitude formula in loop
       Acceptance: `ss_lon` shifts by ~0.24° per 60-second step (consistent with `omega_mars = 7.088e-5 rad/s`)

6. [ ] Complete ray-trace loop body (port lines 64–127 from `mars_example.pro` verbatim)
       Acceptance: loop body compiles and produces no syntax errors

7. [ ] Run full loop over one orbit and verify no errors
       Acceptance: all `npts` iterations complete; no `MESSAGE`/`STOP` is triggered

8. [ ] Validate `tang_alt` against `mars_example.pro` at equivalent geometry (lat≈0, lon≈243.5°, alt≈400 km)
       Acceptance: `tang_alt` values agree within `eps = 10 m`

9. [ ] Commit `mars_occultation_orbit.pro` and `sp_calculate_subsolar_longitude.pro` to git
       Acceptance: `git log --oneline` shows both files in the same commit
