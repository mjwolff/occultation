# Changelog

### 0e91e53 — 2026-03-18 19:15:25 +0100
Add project TODO list

Files changed:
  - TODO.md

### 28e6271 — 2026-03-18 19:21:36 +0100
Add project status summary

Files changed:
  - STATUS.md

### e7d3c8c — 2026-03-18 19:22:51 +0100
Item 2: Add mars_occultation_orbit.pro skeleton

Files changed:
  - TODO.md
  - mars_occultation_orbit.pro

### d60ef40 — 2026-03-18 19:27:08 +0100
Item 3: Add sp_propagate_orbit call and first-step diagnostics

Files changed:
  - TODO.md
  - mars_occultation_orbit.pro

### e55a620 — 2026-03-18 19:29:32 +0100
Item 4: Add unit conversion (km->m) and osse_latlon_to_cartesian connection

Files changed:
  - TODO.md
  - mars_occultation_orbit.pro

### 5422cf5 — 2026-03-18 19:35:39 +0100
Item 5: Add and verify per-step sub-solar longitude formula

Files changed:
  - TODO.md
  - mars_occultation_orbit.pro

### 7caa021 — 2026-03-18 19:38:17 +0100
Item 6: Complete ray-trace loop body, remove scaffolding

Files changed:
  - TODO.md
  - mars_occultation_orbit.pro

### 9b4830d — 2026-03-18 19:49:19 +0100
Items 7 & 8: Full orbit verified; tang_alt validated in IDL

Files changed:
  - TODO.md

### 253c359 — 2026-03-18 19:49:51 +0100
Item 9: Integration complete — cross-repo commit reference

Files changed:
  - TODO.md

### 72747e9 — 2026-03-18 19:56:01 +0100
Add pre-existing occultation source files and integration plan

Files changed:
  - INTEGRATION_PLAN.md
  - mars_example.pro
  - osse_construct_pathlength.pro
  - osse_create_shell_intersection.pro
  - osse_find_shell_intersection_3d.pro
  - osse_generate_integration_points.pro
  - osse_mars_coordinates.pro
  - osse_mars_params.pro
  - osse_trace_ray_occultation_3d.pro

### 5b910e9 — 2026-03-18 20:23:36 +0100
Reorganize project into docs/, examples/, and src/ directories

Files changed:
  - docs/INTEGRATION_PLAN.md
  - docs/STATUS.md
  - docs/TODO.md
  - examples/mars_example.pro
  - examples/mars_occultation_orbit.pro
  - src/osse_construct_pathlength.pro
  - src/osse_create_shell_intersection.pro
  - src/osse_find_shell_intersection_3d.pro
  - src/osse_generate_integration_points.pro
  - src/osse_mars_coordinates.pro
  - src/osse_mars_params.pro
  - src/osse_trace_ray_occultation_3d.pro

### ed9b535 — 2026-03-18 20:27:41 +0100
Add README with routine summaries and calling structure

Files changed:
  - README.md

### 8d6df7d — 2026-03-19 11:59:23 +0100
Create LICENSE

Files changed:
  - LICENSE

### 0a17eaa — 2026-03-19 17:23:46 +0100
Fix IDL path setup and guard against divide-by-zero in osse_cartesian_to_latlon

Files changed:
  - CLAUDE.md
  - examples/mars_occultation_orbit.pro
  - src/osse_mars_coordinates.pro

### 3cfbb6a — 2026-03-20 12:45:58 +0100
Split osse_mars_coordinates.pro into per-function files and add CHANGELOG

Files changed:
  - CHANGELOG.md
  - examples/mars_example.pro
  - examples/mars_occultation_orbit.pro
  - src/osse_cartesian_to_latlon.pro
  - src/osse_latlon_to_cartesian.pro
  - src/osse_mars_coordinates.pro
  - src/osse_sspt_to_sun_direction.pro
  - src/osse_sza.pro
  - tests/test_coordinate_conversions.pro

### ecbe292 — 2026-03-20 12:49:06 +0100
Reorder CHANGELOG entries to ascending date order and fix post-commit hook

Files changed:
  - CHANGELOG.md

### abae3ee — 2026-03-20 14:34:37 +0100
Add VERBOSE keyword to src routines; suppress screen output by default

Files changed:
  - src/osse_find_shell_intersection_3d.pro
  - src/osse_generate_integration_points.pro
  - src/osse_trace_ray_occultation_3d.pro

### 546d798 — 2026-03-20 14:41:45 +0100
Document VERBOSE keyword in mars_occultation_orbit header

Files changed:
  - examples/mars_occultation_orbit.pro

### e6b5d71 — 2026-03-20 16:21:01 +0100
small changes to mars_occultation_orbit test case

Files changed:
  - examples/mars_occultation_orbit.pro

### 6ef7b64 — 2026-03-21 12:51:43 +0100
Add per-routine unit tests for all osse_ src routines

Files changed:
  - docs/TODO.md
  - tests/run_all_tests.pro
  - tests/test_coordinate_conversions.pro
  - tests/test_osse_cartesian_to_latlon.pro
  - tests/test_osse_construct_pathlength.pro
  - tests/test_osse_find_shell_intersection_3d.pro
  - tests/test_osse_generate_integration_points.pro
  - tests/test_osse_latlon_to_cartesian.pro
  - tests/test_osse_sspt_to_sun_direction.pro
  - tests/test_osse_sza.pro
  - tests/test_osse_trace_ray_occultation_3d.pro

### b7c4bae — 2026-03-21 12:59:22 +0100
Add osse_test_install and rename run_all_tests to osse_run_all_tests

Files changed:
  - osse_test_install.pro
  - tests/osse_run_all_tests.pro
  - tests/run_all_tests.pro

### 33ec4fb — 2026-03-21 13:07:02 +0100
Add self-contained path setup to osse_run_all_tests

Files changed:
  - tests/osse_run_all_tests.pro

### c2cc935 — 2026-03-21 13:09:25 +0100
Update CHANGELOG

Files changed:
  - CHANGELOG.md

### f97c23b — 2026-03-21 13:25:22 +0100
Add mars_occultation_survey example program

Files changed:
  - CHANGELOG.md
  - examples/mars_occultation_survey.pro

### 269fb18 — 2026-03-21 13:28:48 +0100
Add osse_local_true_solar_time with unit tests

Files changed:
  - src/osse_local_true_solar_time.pro
  - tests/osse_run_all_tests.pro
  - tests/test_osse_local_true_solar_time.pro

### 541d7bf — 2026-03-21 14:25:11 +0100
Redesign survey event detection: separate ingress and egress half-events

Files changed:
  - README.md
  - examples/mars_occultation_survey.pro

### bf4f012 — 2026-03-21 14:31:27 +0100
Linter formatting pass on mars_occultation_survey

Files changed:
  - CHANGELOG.md
  - examples/mars_occultation_survey.pro

### e05b883 — 2026-03-21 14:45:10 +0100
Add LsubS as optional keyword to mars_occultation_survey

Files changed:
  - examples/mars_occultation_survey.pro

### dd98a5c — 2026-03-21 14:48:25 +0100
Update README for osse_local_true_solar_time and LsubS keyword

Files changed:
  - CHANGELOG.md
  - README.md

### d242db9 — 2026-03-23 09:11:38 +0100
Linter formatting pass on mars_example and orbit examples; remove unused quiet variable

Files changed:
  - CHANGELOG.md
  - examples/mars_example.pro
  - examples/mars_occultation_orbit.pro
  - examples/mars_occultation_survey.pro

### 537ef14 — 2026-03-23 10:22:09 +0100
Add LOS transmittance: Conrath density profile and integration function

Files changed:
  - CHANGELOG.md
  - docs/TODO.md
  - docs/TODO_transmittance.md
  - src/osse_calculate_transmittance.pro
  - src/osse_conrath_density.pro
  - tests/test_osse_calculate_transmittance.pro
  - tests/test_osse_conrath_density.pro

### 402766d — 2026-03-23 10:40:19 +0100
Integrate transmittance into mars_example; update CLAUDE.md IDL invocation

Files changed:
  - CHANGELOG.md
  - CLAUDE.md
  - docs/TODO.md
  - docs/TODO_transmittance.md
  - examples/mars_example.pro

### 06569cb — 2026-03-23 10:40:54 +0100
Update CHANGELOG for 402766d

Files changed:
  - CHANGELOG.md

### dd1bf3e — 2026-03-23 15:13:32 +0100
Convert all distance units from meters to km across occultation repo

Files changed:
  - docs/UNIT_CONVERSION_m_to_km.md
  - examples/mars_example.pro
  - examples/mars_occultation_orbit.pro
  - examples/mars_occultation_survey.pro
  - osse_test_install.pro
  - src/osse_calculate_transmittance.pro
  - src/osse_cartesian_to_latlon.pro
  - src/osse_conrath_density.pro
  - src/osse_create_shell_intersection.pro
  - src/osse_latlon_to_cartesian.pro
  - src/osse_mars_params.pro
  - src/osse_sspt_to_sun_direction.pro
  - src/osse_trace_ray_occultation_3d.pro
  - tests/test_osse_calculate_transmittance.pro
  - tests/test_osse_cartesian_to_latlon.pro
  - tests/test_osse_conrath_density.pro
  - tests/test_osse_construct_pathlength.pro
  - tests/test_osse_find_shell_intersection_3d.pro
  - tests/test_osse_generate_integration_points.pro
  - tests/test_osse_latlon_to_cartesian.pro
  - tests/test_osse_sspt_to_sun_direction.pro
  - tests/test_osse_trace_ray_occultation_3d.pro

### 63ff2f7 — 2026-03-23 15:17:38 +0100
Add conrath_density and calculate_transmittance to test suite

Files changed:
  - tests/osse_run_all_tests.pro

### 01ff625 — 2026-03-23 15:18:06 +0100
Update CHANGELOG

Files changed:
  - CHANGELOG.md

### e9c5a0e — 2026-03-23 15:21:06 +0100
Add TESTS.md: unit test documentation with validation sources

Files changed:
  - tests/TESTS.md

### de73cea — 2026-03-23 15:22:18 +0100
Update CHANGELOG

Files changed:
  - CHANGELOG.md

### 9339459 — 2026-03-23 15:24:12 +0100
Document SURVEY output keyword in mars_occultation_survey header

Files changed:
  - examples/mars_occultation_survey.pro

### 26339b3 — 2026-03-23 15:28:07 +0100
Update CHANGELOG

Files changed:
  - CHANGELOG.md

### d51586e — 2026-03-23 16:17:20 +0100
Add interpolated t_start/t_end and nearest-sample _nn fields to survey events

Files changed:
  - examples/mars_occultation_survey.pro

### 2434320 — 2026-03-23 16:18:47 +0100
Expand header docs for interpolated event times in mars_occultation_survey

Files changed:
  - examples/mars_occultation_survey.pro

### b7ac7f7 — 2026-03-23 16:23:19 +0100
Add ingress byte flag to survey event struct

Files changed:
  - examples/mars_occultation_survey.pro

### db65476 — 2026-03-23 16:40:42 +0100
Restructure survey event struct: rename t_start/t_end, add tang_alt_max, remove t_min

Files changed:
  - CHANGELOG.md
  - examples/mars_occultation_survey.pro

### 82ea4ad — 2026-03-23 16:44:12 +0100
Rename t_start_nn/t_end_nn -> t_start/t_end; duration -> duration_interp

Files changed:
  - CHANGELOG.md
  - examples/mars_occultation_survey.pro

### c686aee — 2026-03-23 16:46:28 +0100
Fix column header alignment in survey events print table

Files changed:
  - examples/mars_occultation_survey.pro

### 9a6847b — 2026-03-23 17:05:25 +0100
Add ss_lat and ss_lon to survey event struct

Files changed:
  - examples/mars_occultation_survey.pro

### cace9a4 — 2026-03-23 17:16:27 +0100
Move ss_lat/ss_lon from event struct to survey struct

Files changed:
  - examples/mars_occultation_survey.pro

### 3568e3c — 2026-03-23 17:19:17 +0100
Add sat_lat/sat_lon/sat_alt to survey struct; add mars_occultation_event_raytrace

Files changed:
  - examples/mars_occultation_event_raytrace.pro
  - examples/mars_occultation_survey.pro

### f82a690 — 2026-03-24 10:49:32 +0100
Add mars_occultation_event_example; fix raytrace print table alignment

Files changed:
  - examples/mars_occultation_event_example.pro
  - examples/mars_occultation_event_raytrace.pro

### 2bb067d — 2026-03-24 10:50:44 +0100
Add transmittance vs altitude plot to mars_occultation_event_example

Files changed:
  - examples/mars_occultation_event_example.pro
