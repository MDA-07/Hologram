# Mouse navigation and vessel depth fix

- Left mouse drag rotates the anatomy (yaw and pitch).
- Right mouse drag pans the model vertically and horizontally without changing its rotation.
- Mouse wheel zoom remains enabled.
- Touch rotation and pinch zoom remain enabled.
- The fine vessel-network overlay that was drawn after every body surface has been disabled. It ignored surface depth and caused vessels to appear to float above the outer layer. The regular vessel anatomical meshes remain available through the Blood vessels system.

Run `flutter analyze` and `flutter run --release` to validate in your local Flutter environment.
