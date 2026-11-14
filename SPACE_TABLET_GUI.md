# Holo Anatomy — Space Tablet GUI Update

This update uses the latest uploaded `A(2).zip` as its source and keeps its anatomy data, renderer, astronaut health context, existing controls and model geometry.

## Spaceflight tablet design
- Landscape workspace for large tablets: anatomy systems on the left, large model viewport in the centre, selected-structure and mission display controls on the right.
- Touch-first controls with large 44–56 px interaction targets; no hover-dependent actions.
- High-contrast dark navy and cyan palette suitable for a dim cabin while avoiding excessive glow.
- Large front/left/right/back view controls, reset and zoom slider.
- Male/female selection, display presets, outer-skin transparency and hologram transparency remain accessible.
- Search remains available through the left panel.
- For narrower/portrait layouts, the existing compact layout is retained.

## Space-use design considerations
- Keep core anatomy browsing local/offline; do not assume network access in orbit.
- Do not present sample/default vital values as live telemetry. Values in this prototype are illustrative and must be connected to validated sensors/crew medical workflows before operational use.
- Use touch targets large enough for gloved or imprecise input; avoid small chips and hover-only tooltips.
- The interface is not flight-certified or a medical device. Validate with the actual tablet, gloves, lighting, mounting angle, and mission human-factors requirements.

## Test
Run `flutter pub get`, `flutter analyze`, and `flutter run --release` on the target tablet. Test both landscape and portrait, touch input, stylus, accidental palm contact, and screen scaling.
