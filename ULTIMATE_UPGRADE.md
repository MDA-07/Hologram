# Holo Anatomy — Ultimate prototype upgrade

This package is an incremental, source-based upgrade of the supplied Flutter project.
It preserves the original procedural anatomy generator and adds interaction/navigation
features without introducing a large, unverified engine dependency.

## Added in this upgrade

- Searchable Anatomy Library opened from the app bar.
- Search by structure name, anatomy ID, or system.
- Selecting a search result enables its system if hidden, focuses the structure, and zooms in.
- Selected-structure action to isolate its entire anatomical system.
- Global hologram intensity control.
- Cached visible-part list, so the viewer does not rebuild a filtered anatomy list on every drag frame.
- Selection hit-testing now respects the currently visible/isolated set.
- Reset and clear-selection actions restore the full visible system state.

## Run and validate

From the `A` folder:

```bash
flutter clean
flutter pub get
flutter analyze
flutter run --release
```

Use a physical device or desktop release build for performance evaluation. Debug builds are
not representative of release rendering performance.

## Important technical truth

This remains a procedural low-detail anatomy prototype rendered by Flutter CustomPainter and
`ui.Vertices`. It is not a full physically based 3D engine, and its procedural structures are
not medically validated anatomy. The supplied reference pictures are visual references only;
they are not source meshes. The current male/female versions are silhouette variants, not
complete sex-specific anatomical atlases.

The next major quality leap requires acquiring properly licensed, medically reviewed GLB/GLTF
assets with separate named meshes, material/opacity support, anatomical metadata, and a suitable
3D renderer. That is the path to genuinely detailed bones, articular cartilage, ligaments,
individual muscles, organs, and branching vasculature. Do not use this prototype for diagnosis
or clinical decisions.
