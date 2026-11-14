# Spaceflight Health & Reliability Upgrade

## Implemented in this package

1. **Offline-first crew log:** health records are saved locally with `shared_preferences`; no network is needed to enter or review records.
2. **Measurement provenance/history:** each record stores indicator, numeric value, unit, UTC timestamp, source label (manual, verified sensor, or training/simulation), and optional context.
3. **Emergency reference screen:** a conservative escalation/navigation aid that directs crew to mission-approved checklists and flight-surgeon procedures. It intentionally contains no invented thresholds, diagnoses, medication advice, or treatment algorithms.
4. **Adaptive tablet layout:** the health log uses a two-column layout on wide displays and a stacked layout on narrower displays, with scrollable touch-friendly controls.
5. **Vessel overlay fix:** removed the generated capillary network that was drawn as a 2D overlay without depth testing. This was the source of the floating/protruding vessel appearance. The actual 3D artery/vein anatomical meshes remain enabled.

## Important limitations / work still required before operational use

- `shared_preferences` is local convenience storage, **not encrypted medical-record storage** and not a validated flight data store. Production should use an approved encrypted database, access control, audit logs, backup/recovery, and a crew/mission identity model.
- Sensor integration is not implemented. The “connected sensor (verified)” source label is only a provenance field; it does not connect or verify a device. Do not select it unless a future validated integration supplies the reading.
- The app does not calculate clinical risk, diagnose, or determine emergency status. Thresholds must be mission-specific and approved by aerospace medical personnel.
- Emergency procedures and medical thresholds must be supplied and validated by the responsible flight surgeon / mission medical authority.
- Health history currently has a simple local list and delete action; CSV export, trend charts, crew profile separation, encrypted storage, and synchronization are future work.
- The anatomy model remains a procedural visualization. It is not a clinical imaging or diagnostic tool.

## Setup

Run `flutter pub get`, `flutter analyze`, then `flutter run --release` on the target tablet. The added dependency requires package resolution during build, but runtime health-log entry and history viewing work offline after installation.

## Route typing compatibility fix

The app now uses package imports for the health pages and explicitly types both
`MaterialPageRoute<void>` builders and their `BuildContext` arguments. This avoids
ambiguous route generic inference in some analyzer contexts.
