# Integration TODO: satellite_position → occultation

## Status key: [ ] not started  [~] in progress  [x] done

1. [x] Create `sp_calculate_subsolar_longitude.pro` in `../satellite_position/src/`
       Acceptance: function returns expected longitude shift for a known Mars rotation interval (e.g. t=88642s → full 360° rotation)

2. [x] Create `mars_occultation_orbit.pro` with IDL path setup, orbital elements block, and sub-solar geometry block (no loop yet)
       Acceptance: file compiles clean in IDL (`RESOLVE_ROUTINE, 'mars_occultation_orbit'` exits without error)

3. [x] Add `sp_propagate_orbit` call and print `.lat`, `.lon`, `.alt` for first time step
       Acceptance: printed values match expected TGO-like orbit geometry (alt ≈ 400 km, lat in [-74°, 74°])

4. [x] Add unit conversion (`result[i].alt * 1.0d3`) and connect to `osse_latlon_to_cartesian`
       Acceptance: `sat_pos` at lat=0, lon=243.5°, alt=400 km matches the hardcoded equivalent from `mars_example.pro` within 1 km

5. [x] Implement per-step sub-solar longitude formula in loop
       Acceptance: `ss_lon` shifts by ~0.24° per 60-second step (consistent with `omega_mars = 7.088e-5 rad/s`)

6. [x] Complete ray-trace loop body (port lines 64–127 from `mars_example.pro` verbatim)
       Acceptance: loop body compiles and produces no syntax errors

7. [x] Run full loop over one orbit and verify no errors
       Acceptance: all `npts` iterations complete; no `MESSAGE`/`STOP` is triggered

8. [x] Validate `tang_alt` against `mars_example.pro` at equivalent geometry (lat≈0, lon≈243.5°, alt≈400 km)
       Acceptance: `tang_alt` values agree within `eps = 10 m`

9. [x] Commit `mars_occultation_orbit.pro` and `sp_calculate_subsolar_longitude.pro` to git
       Note: files reside in separate repos; cross-reference commit links them.
       occultation:        mars_occultation_orbit.pro (this repo, items 2-8)
       satellite_position: sp_calculate_subsolar_longitude.pro (433c3ee, 76368be)

10. [ ] Fix unhandled tangent-layer case in osse_construct_pathlength
        src/osse_construct_pathlength.pro line 27 contains a debug STOP that
        fires whenever path_length == s_exit - s_entry. This occurs for the
        innermost intersected shell when the ray grazes the outer sphere but
        does not penetrate the inner sphere (hit_outer=1, hit_inner=0). In
        practice it is triggered when the tangent altitude falls exactly on a
        1-km layer boundary (e.g. tang_alt = 50.000 km). The current first_one
        block sets s_inbound=[s1_inner]=0 and s_outbound=[s2_inner]=0 before
        the STOP, which is also wrong.
        Fix: replace the STOP with correct handling for this case. The tangent
        shell has no inner-sphere crossing; the natural split point is
        s_tangent = -total(sat_pos * sun_dir) (the closest approach along the
        ray). Set s_inbound=[s_tangent] and s_outbound=[s_tangent] for this
        layer so the arrays correctly bracket the tangent point.
        Acceptance: osse_construct_pathlength completes without error for a ray
        with tangent altitude exactly 50.0 km; s_inbound and s_outbound are
        non-empty and their difference gives a positive total path length.
