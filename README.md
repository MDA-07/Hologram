# Holo Anatomy — Flutter prototype

## What changed
- Kept the procedural anatomy generator and the existing `lib/` 3D engine files.
- Replaced the incomplete root `main.dart` with a working interactive anatomy-viewer UI and painter.
- Added `lib/main.dart` as Flutter's conventional application entry point. It delegates to the root `main.dart`.
- Added the images from `B.zip` under `reference_images/` as visual references.
- Added male/female model switching, independent anatomical layer toggles, drag rotation on horizontal and vertical axes, pinch/slider zoom, and tap selection with a detail panel.
- Added a cached branching red/blue vessel overlay based on the supplied vascular illustration.

## Run
From this folder, with Flutter installed:

```bash
flutter pub get
flutter run
```

Flutter's default entry point is `lib/main.dart`.

## Important limitations
This is an interactive **procedural visual prototype**, not a clinical-grade anatomical atlas. The body parts are low-to-mid detail generated meshes; some structures are simplified or combined, and the male/female variants are silhouette variations rather than complete sex-specific anatomical atlases. The current joint interaction selects and zooms the nearby structure; it does not yet provide a true articulated skeleton, joint range-of-motion simulation, or medically validated internal anatomy.

The branching small-vessel overlay is a procedural visual approximation inspired by the reference image, not a patient-specific or anatomically exact vascular map. For accurate education or clinical use, replace/augment these meshes with licensed, medically reviewed 3D anatomy assets and validate labels and locations with an anatomy professional.

## Project layout
- `main.dart` — app UI, procedural anatomy model generation, interactive 3D painter.
- `lib/main.dart` — standard Flutter entry point.
- `lib/core/` — camera, mesh, and group primitives.
- `lib/geometry/` — basic geometry.
- `lib/render/` — original scene rendering implementation.
- `lib/world/` — original object-pooling/world utilities.
- `reference_images/` — supplied visual references from `B.zip`.

## Performance update

The optimized viewer reuses the male/female anatomy meshes instead of rebuilding them on every switch. The painter now projects each mesh vertex once per frame and submits the sorted triangle geometry in a single `Canvas.drawVertices` batch. Per-triangle path creation and wireframe strokes were removed because they were a major CPU cost. The anatomy layer selector is horizontally scrollable to keep the control area compact.

For best performance, run a release build on a physical device:

```bash
flutter run --release
```

Debug mode is substantially slower for this CPU-based custom renderer. If the viewer still struggles on lower-end devices, turn off the fine blood-vessel network and show only the main vessels, or reduce mesh detail further.

## Performance and interaction pass (2026-11-14)

- Removed the per-triangle `_Face` object list and global triangle sort from the hot paint loop.
- Draws each anatomical part through one indexed `ui.Vertices` batch instead of assembling a single huge sorted triangle list.
- Projects mesh vertices with inline scalar math to avoid allocating a tuple and `Offset` for every vertex.
- Batches the fine red/blue vessel branches into one `Path` per colour rather than issuing one `drawLine` call per branch segment.
- Dragging and pinching now refresh only the viewer subtree through a `ValueNotifier`; the app bar and lower control panel are not rebuilt on every pointer update.
- Added quick anatomy presets (surface, skeleton, muscles, organs, circulatory, nervous, all systems) and front/left/right/back camera shortcuts.

### Renderer architecture note

This remains a Flutter `CustomPainter` renderer using indexed `ui.Vertices` batches. Flutter's canvas is GPU-backed on supported platforms, but the model's perspective projection is still performed on the CPU. This is a substantial incremental optimization over sorting and allocating every triangle each frame, but it is not a full 3D engine migration. A true real-time 3D engine upgrade should use medically reviewed, licensed glTF/GLB anatomy assets with separate named meshes and a renderer such as a maintained OpenGL/WebGL or native 3D integration. The supplied project currently contains procedural low-detail meshes rather than production-ready GLB anatomy assets, so swapping engines alone would not create realistic anatomy.

### Validation

The Dart/Flutter SDK was not installed in the build environment, so this package has not been compiled or run here. After extracting, run:

```bash
flutter clean
flutter pub get
flutter analyze
flutter run --release
```

If `flutter analyze` reports an error, share the complete message and line number. Compare performance using a release build on the same device before and after this update; debug mode is not a meaningful performance benchmark.


## Ultimate prototype upgrade

See `ULTIMATE_UPGRADE.md` for the added searchable Anatomy Library, structure focus, system isolation, hologram intensity control, visible-part caching, and validation instructions. The app remains a procedural educational prototype; medically reviewed GLB/GLTF assets are required for high-fidelity anatomy.


## Camera controls (updated)

- **Mouse wheel:** zoom in and out (0.45× to 5×).
- **W / S:** move the view vertically through the model.
- **A / D:** move the view horizontally through the model.
- **Drag:** rotate the model.
- **Pinch:** zoom on touch devices.
- Click the model once if the keyboard controls do not respond; this gives the anatomy viewer keyboard focus.

WASD pans the camera focus in camera-relative directions. It does not modify the zoom value.
