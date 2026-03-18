# Integration Plan: Use satellite_position for Spacecraft Position

## Context

`mars_example.pro` currently hardcodes spacecraft position as a manually
constructed longitude sweep at fixed lat=0°, alt=400 km. The goal is to
replace this with physically realistic positions from the `satellite_position`
codebase (sibling directory `../satellite_position/`), which propagates a
Keplerian orbit and returns lat/lon/alt at each time step.

The two codebases share a natural interface:
`osse_latlon_to_cartesian(lat, lon, alt_meters)` accepts exactly what
`sp_propagate_orbit()` returns (`.lat`, `.lon`, `.alt` in km). The only
change at the seam is a unit conversion: km → meters.

---

## Files to Create

### 1. `../satellite_position/src/sp_calculate_subsolar_longitude.pro` (NEW)

Peer to the existing `sp_calculate_subsolar_latitude.pro`. The sub-solar
longitude is not derivable from `L_s` alone — it depends on Mars's
rotational phase at a reference epoch.

```idl
FUNCTION sp_calculate_subsolar_longitude, t, t_ref, ss_lon_ref, constants
  ; t          - time array (seconds from propagation epoch)
  ; t_ref      - time at which ss_lon_ref is defined (seconds)
  ; ss_lon_ref - sub-solar longitude at t_ref (degrees, -180 to 180)
  ; constants  - from sp_mars_constants() — uses .omega_mars (rad/s)
  ;
  ; As Mars rotates east (+omega_mars), the sub-solar footprint moves west.
  delta_lon = -(t - t_ref) * constants.omega_mars * !RADEG
  ss_lon = ((ss_lon_ref + delta_lon + 180.0d0) MOD 360.0d0) - 180.0d0
  RETURN, ss_lon
END
```

### 2. `mars_occultation_orbit.pro` (NEW, in this directory)

New entry-point procedure that replaces the hardcoded position loop in
`mars_example.pro` with propagated orbital positions. `mars_example.pro`
is left unchanged as a standalone reference.

#### Structure

```idl
PRO mars_occultation_orbit
  COMPILE_OPT IDL2

  ;--- 0. IDL PATH SETUP -----------------------------------------------
  ; Add satellite_position/src using ROUTINE_FILEPATH (IDL 8.0+)
  sp_src = FILE_DIRNAME(ROUTINE_FILEPATH('mars_occultation_orbit')) + $
           '/../satellite_position/src'
  !PATH = EXPAND_PATH(sp_src) + ':' + !PATH

  ;--- 1. ORBITAL ELEMENTS  (user configures) --------------------------
  mars = sp_mars_constants()
  elements = {a: mars.r_eq + 400.0d0, $   ; semi-major axis (km)
              e: 0.005d0, $                ; eccentricity
              i: 74.0d0 * !DTOR, $         ; inclination (radians)
              raan: 0.0d0, $
              omega: 0.0d0, $
              M0: 0.0d0}
  t0 = 0.0d0
  period = 2.0d0 * !DPI * SQRT(elements.a^3 / mars.mu)
  npts = 45L
  t = DINDGEN(npts) * period / DOUBLE(npts - 1)

  ;--- 2. SUB-SOLAR GEOMETRY  (user configures) ------------------------
  Ls = 90.0d0                    ; areocentric solar longitude (degrees)
  ss_lat = sp_calculate_subsolar_latitude(Ls, /DEGREES)
  ss_lon_at_t0 = 0.0d0           ; sub-solar longitude at epoch t0 (degrees)
                                  ; — set to match simulation epoch

  ;--- 3. PROPAGATE ORBIT ----------------------------------------------
  result = sp_propagate_orbit(elements, t, t0, mars)

  ;--- 4. OCCULTATION SETUP --------------------------------------------
  osse_mars_coordinates
  params = osse_mars_params()
  quiet = 0
  eps = 10.0d0   ; meters — tolerance for tangent height consistency check

  path_info       = PTRARR(npts, /ALLOCATE_HEAP)
  height          = DBLARR(npts)
  longitude       = DBLARR(npts)
  latitude        = DBLARR(npts)
  n_intersections = INTARR(npts)

  ;--- 5. MAIN LOOP over orbital time steps ----------------------------
  FOR i = 0, npts - 1 DO BEGIN

    ; Satellite position from propagator (alt: km -> m)
    sat_lat = result[i].lat
    sat_lon = result[i].lon
    sat_alt = result[i].alt * 1.0d3

    ; Sub-solar longitude at this time step
    ss_lon = ss_lon_at_t0 - (t[i] - t0) * mars.omega_mars * !RADEG
    ss_lon = ((ss_lon + 180.0d0) MOD 360.0d0) - 180.0d0

    ; Convert to occultation Cartesian frame and trace ray
    ; (loop body from here is identical to mars_example.pro lines 64-127)
    sat_pos = osse_latlon_to_cartesian(sat_lat, sat_lon, sat_alt)
    sun_dir = osse_sspt_to_sun_direction(ss_lat, ss_lon, sat_pos=sat_pos)

    s_tangent     = -TOTAL(sat_pos * sun_dir)
    tangent_point = sat_pos + s_tangent * sun_dir
    res_tangent   = osse_cartesian_to_latlon(tangent_point)

    PRINT, 'tangent: ', res_tangent.longitude, res_tangent.latitude, $
           res_tangent.altitude / 1000.d0
    height[i]    = res_tangent.altitude
    longitude[i] = res_tangent.longitude
    latitude[i]  = res_tangent.latitude

    osse_trace_ray_occultation_3d, sat_pos, sun_dir, tang_alt, $
      intersections, n_int, quiet=quiet
    n_intersections[i] = n_int

    IF ABS(tang_alt - res_tangent.altitude) GT eps THEN BEGIN
      MESSAGE, 'tangent point height calculations differ.'
      STOP
    ENDIF

    PRINT, FORMAT='(A,F9.4,A,I4)', 'Tangent altitude: ', $
           tang_alt / 1000.0d, ' km, Layers intersected: ', n_int

    IF n_int GT 0 THEN BEGIN
      osse_construct_pathlength, intersections, s_inbound, s_outbound, $
        params=params
      idx = WHERE(intersections[*].intersects GT 0.)
      IF idx[0] NE -1 THEN BEGIN
        min_discriminant = MIN([intersections[idx].discriminant_inner, $
                                intersections[idx].discriminant_outer])
        IF min_discriminant LT 1.e4 THEN BEGIN
          MESSAGE, 'min(discriminant) lt 1.e4'
          STOP
        ENDIF
      ENDIF
      s_points   = [s_inbound, s_tangent, s_outbound]
      n_s_points = N_ELEMENTS(s_points)
      intersection_points = FLTARR(3, n_s_points)
      FOR j = 0, n_s_points - 1 DO BEGIN
        s_position = sat_pos + s_points[j] * sun_dir
        res = osse_cartesian_to_latlon(s_position)
        intersection_points[*, j] = [res.longitude, res.latitude, res.altitude]
      ENDFOR
      *path_info[i] = {path_length:    s_points, $
                       path_longitude: REFORM(intersection_points[0, *]), $
                       path_latitude:  REFORM(intersection_points[1, *]), $
                       path_altitude:  REFORM(intersection_points[2, *])}
    ENDIF

  ENDFOR

  ;--- 6. RESULTS -------------------------------------------------------
  a = {time: t, height: height, longitude: longitude, latitude: latitude, $
       n_intersections: n_intersections, path_info: path_info}

  PRINT, '========================================='
  PRINT, 'Orbit-driven occultation complete'
  PRINT, '========================================='
  STOP
END
```

---

## Files NOT Modified

| File | Reason |
|------|--------|
| `mars_example.pro` | Preserved as standalone reference |
| `osse_mars_params.pro` | Spherical R_MARS=3397 km is self-consistent internally |
| `../satellite_position/src/sp_mars_constants.pro` | Oblate ellipsoid unchanged |

---

## Key Design Decisions

**Units at the seam:** `sp_propagate_orbit` returns `.alt` in km;
`osse_latlon_to_cartesian` expects meters. Multiply by `1.0d3` at hand-off.

**Sub-solar longitude gap:** `satellite_position` provides sub-solar
latitude (from `L_s`) but not longitude — that requires knowing which
face of Mars faces the Sun at epoch. Handled by the new small helper
`sp_calculate_subsolar_longitude` plus a user-supplied `ss_lon_at_t0`.

**Constants mismatch is safe:** The lat/lon/alt interface insulates the
two models. `osse_latlon_to_cartesian` re-projects onto its own spherical
Mars (R=3397 km) regardless of how altitude was originally computed.
The ~0.8 km equatorial difference is within the existing spherical
approximation already present in the occultation code.

**IDL path:** Uses `ROUTINE_FILEPATH` (IDL 8.0+) to construct the
relative path `../satellite_position/src` robustly, regardless of
working directory.

---

## Verification

1. Run `mars_occultation_orbit` in IDL — should print tangent altitudes
   and layer counts at each time step with no errors.
2. At a time step where `result[i].lat ≈ 0`, `result[i].lon ≈ 243.5°`,
   `result[i].alt ≈ 400 km`, compare `tang_alt` against the equivalent
   output from `mars_example.pro` as a sanity check.
3. Confirm `n_intersections > 0` for steps where tangent altitude < 100 km.
4. Verify `ss_lon` evolves ~360° over one Mars sidereal day (~88,642 s).
