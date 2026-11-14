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
