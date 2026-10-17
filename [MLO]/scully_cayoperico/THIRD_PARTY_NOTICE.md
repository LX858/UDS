# THIRD-PARTY NOTICE

This package includes an integration based on the public project:

- Scullyy/scully_cayoperico
- https://github.com/Scullyy/scully_cayoperico

The upstream project provides the IPL-based approach that allows San Andreas
and Cayo Perico to be enabled alongside one another.

Integration changes in this READY package:
- Adds a startup safety reset that keeps `HeistIsland` / IslandHopper disabled.
- Adds `/dualmapreset` as a client command to restore San Andreas if another
  resource enabled IslandHopper.
- Keeps the upstream IPL set and distance-based Cayo water/path/ambient logic.
- Does not include the upstream optional binary mansion-gate YMAP overrides;
  those are not required for Los Santos + Cayo dual-map operation.
- Adds Vietnamese locale text.
