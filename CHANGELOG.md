# Changelog

### 0a17eaa — 2026-03-19 17:23:46 +0100
Fix IDL path setup and guard against divide-by-zero in osse_cartesian_to_latlon

Files changed:
  - CLAUDE.md
  - examples/mars_occultation_orbit.pro
  - src/osse_mars_coordinates.pro

### 8d6df7d — 2026-03-19 11:59:23 +0100
Create LICENSE

Files changed:
  - LICENSE

### ed9b535 — 2026-03-18 20:27:41 +0100
Add README with routine summaries and calling structure

Files changed:
  - README.md

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

### 253c359 — 2026-03-18 19:49:51 +0100
Item 9: Integration complete — cross-repo commit reference

Files changed:
  - TODO.md

### 9b4830d — 2026-03-18 19:49:19 +0100
Items 7 & 8: Full orbit verified; tang_alt validated in IDL

Files changed:
  - TODO.md

### 7caa021 — 2026-03-18 19:38:17 +0100
Item 6: Complete ray-trace loop body, remove scaffolding

Files changed:
  - TODO.md
  - mars_occultation_orbit.pro

### 5422cf5 — 2026-03-18 19:35:39 +0100
Item 5: Add and verify per-step sub-solar longitude formula

Files changed:
  - TODO.md
  - mars_occultation_orbit.pro

### e55a620 — 2026-03-18 19:29:32 +0100
Item 4: Add unit conversion (km->m) and osse_latlon_to_cartesian connection

Files changed:
  - TODO.md
  - mars_occultation_orbit.pro

### d60ef40 — 2026-03-18 19:27:08 +0100
Item 3: Add sp_propagate_orbit call and first-step diagnostics

Files changed:
  - TODO.md
  - mars_occultation_orbit.pro

### e7d3c8c — 2026-03-18 19:22:51 +0100
Item 2: Add mars_occultation_orbit.pro skeleton

Files changed:
  - TODO.md
  - mars_occultation_orbit.pro

### 28e6271 — 2026-03-18 19:21:36 +0100
Add project status summary

Files changed:
  - STATUS.md

### 0e91e53 — 2026-03-18 19:15:25 +0100
Add project TODO list

Files changed:
  - TODO.md
