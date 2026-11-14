import 'dart:math' as m;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:holo_anatomy/health/health_monitor.dart';
import 'package:holo_anatomy/health/emergency_reference.dart';

void main() => runApp(const HoloApp());

// ───────────────────────── data ─────────────────────────
const kSys = {'skin': 'Skin', 'muscle': 'Muscles', 'skeleton': 'Skeleton & joints', 'organs': 'Organs', 'vessels': 'Blood vessels', 'nerves': 'Nervous'};
const kInfo = <String, String>{
  'skin': 'Barrier, temperature control, touch.|Dry, itchy skin and slow healing are common; radiation adds exposure.|Temperature, rash check',
  'muscle': 'Movement and posture.|Shrinks within weeks without resistance exercise.|Exercise minutes, body mass',
  'skull': 'Protects the brain.|Fluid shifts raise pressure in the head.|Headache, vision',
  'brain': 'Thinking, mood, sleep, balance.|Radiation, CO2, poor sleep and isolation slow reactions and lower mood.|Sleep, mood, reaction test',
  'eye': 'Vision.|Fluid shift can flatten the eyeball and blur near vision (SANS).|Acuity chart, Amsler grid',
  'spine': 'Supports the body and shields the spinal cord.|The spine lengthens in microgravity; back pain is common.|Back pain, exercise load',
  'ribs': 'Protect heart and lungs.|Breathing and posture exercises help.|SpO2, breathing rate',
  'pelvis': 'Carries trunk load.|A fast bone-loss site: about 1-1.5 % per month without loading.|Exercise load, calcium, vitamin D',
  'femur': 'Longest bone; carries body weight.|Density drops without impact and resistance loading.|Exercise, vitamin D, calcium',
  'tibia': 'Shin bones.|Lose load in microgravity, and partly on Moon and Mars.|Exercise minutes',
  'hip': 'Ball joint carrying the trunk.|Highest bone-loss risk.|Hip pain, exercise load',
  'knee': 'Hinge joint with cartilage.|Unloaded cartilage thins; rebuild loads gradually.|Pain, swelling',
  'shoulder': 'Joint with the widest motion.|Overuse in suit and tool tasks.|Pain, mobility',
  'heart': 'Pumps blood to every tissue.|Gets rounder and works less; fluid shifts change blood pressure.|Heart rate, blood pressure, SpO2',
  'lungs': 'Swap oxygen and carbon dioxide.|Dust, CO2 and dry air irritate.|SpO2, cabin CO2, cough',
  'liver': 'Filters blood, stores energy.|Diet changes alter drug handling.|Nutrition, medication log',
  'kidney': 'Filter blood, balance water and salts.|Bone calcium loss plus dehydration raise stone risk.|Hydration, urine colour, flank pain',
  'gut': 'Absorbs nutrients; microbiome.|Microbiome and immune shifts.|Intake, body mass',
  'artery': 'Carry oxygen-rich blood.|Radiation and low activity stiffen vessels.|Blood pressure, heart rate',
  'vein': 'Return blood to the heart.|Fluids shift upward: puffy face, sluggish neck veins.|Blood pressure, headache',
};

class Vit {
  final String k, l, u; final double mn, mx, step, d, g0, g1, y0, y1; final List<String> reg;
  const Vit(this.k, this.l, this.u, this.mn, this.mx, this.step, this.d, this.g0, this.g1, this.y0, this.y1, this.reg);
}
const kVit = [
  Vit('hr', 'Heart rate', 'bpm', 30, 170, 1, 68, 50, 90, 40, 110, ['heart', 'artery', 'vein']),
  Vit('sys', 'BP systolic', 'mmHg', 60, 210, 1, 115, 100, 129, 90, 139, ['heart', 'artery']),
  Vit('dia', 'BP diastolic', 'mmHg', 40, 130, 1, 75, 60, 84, 55, 89, ['artery', 'vein']),
  Vit('temp', 'Body temp', '°C', 33, 41, .1, 36.6, 36.1, 37.2, 35.5, 37.7, ['skin']),
  Vit('spo2', 'SpO2', '%', 80, 100, 1, 98, 95, 100, 92, 100, ['lungs']),
  Vit('rr', 'Breathing', '/min', 6, 40, 1, 15, 12, 20, 10, 24, ['lungs', 'ribs']),
  Vit('glu', 'Glucose', 'mg/dL', 40, 300, 1, 88, 70, 99, 54, 125, ['liver', 'stomach', 'gut']),
  Vit('hyd', 'Hydration', '%', 0, 100, 1, 85, 70, 100, 50, 100, ['kidney', 'bladder']),
  Vit('slp', 'Sleep', 'h', 0, 12, .5, 7.5, 7, 12, 5, 12, ['brain']),
  Vit('mood', 'Mood', '1-5', 1, 5, 1, 4, 4, 5, 3, 5, ['brain']),
  Vit('bone', 'Bone density change', '%', -15, 5, .5, 0, -2, 5, -5, 5, ['femur', 'pelvis', 'spine', 'tibia', 'humerus', 'skull']),
];
int lv(Vit x, double v) => v >= x.g0 && v <= x.g1 ? 0 : v >= x.y0 && v <= x.y1 ? 1 : 2;
const kSym = ['✓', '!', '⚠'];
const kCol = [Color(0xFF3DFF9A), Color(0xFFFFB020), Color(0xFFFF3B4D)];
const kInjT = ['Fracture', 'Laceration', 'Bruise', 'Burn', 'Sprain', 'Pain'];
const kSev = ['Mild', 'Moderate', 'Severe'];

class Inj { final String t, note, at; final int sev; final vm.Vector3 p; Inj(this.t, this.sev, this.note, this.at, this.p); }
class Subj {
  String n; bool f = false; final Map<String, double> v = {for (final x in kVit) x.k: x.d}; final List<Inj> inj = [];
  Subj(this.n);
}

// ───────────────────────── geometry ─────────────────────────
class B {
  final p = <double>[], n = <double>[], ix = <int>[], pk = <List<double>>[];
  int v(double x, double y, double z, double nx, double ny, double nz) {
    final l = m.sqrt(nx * nx + ny * ny + nz * nz), i = p.length ~/ 3;
    p.addAll([x, y, z]); n.addAll([nx / l, ny / l, nz / l]); return i;
  }
  void t(int a, int b, int c) => ix.addAll([a, b, c]);
}

class Part {
  final String sys, id, name; final int col; final Float32List p, n, sp; final Int32List sc; final Uint16List ixL; final List<List<double>> pk;
  final double cx, cy, cz, ext; final int anim; int st = 0; double dim = 1, dimG = 1, hl = 0;
  Part(this.sys, this.id, this.name, this.col, this.p, this.n, this.ixL, this.pk, this.cx, this.cy, this.cz, this.ext, this.anim)
      : sp = Float32List(p.length ~/ 3 * 2), sc = Int32List(p.length ~/ 3);
}

class Gen {
  final double k; final out = <Part>[]; Gen(this.k);
  Part _fin(String sys, String id, String nm, int c, B b, int an) {
    final n = b.p.length ~/ 3; final p = Float32List(n * 3);
    final lo = [1e9, 1e9, 1e9], hi = [-1e9, -1e9, -1e9];
    for (var i = 0; i < n * 3; i++) { p[i] = b.p[i] * k; lo[i % 3] = m.min(lo[i % 3], p[i]); hi[i % 3] = m.max(hi[i % 3], p[i]); }
    final pk = [for (final s in b.pk) [s[0] * k, s[1] * k, s[2] * k, s[3] * k]];
    final pt = Part(sys, id, nm, c, p, Float32List.fromList(b.n), Uint16List.fromList(b.ix), pk, (lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, (lo[2] + hi[2]) / 2,
        m.max(hi[0] - lo[0], m.max(hi[1] - lo[1], hi[2] - lo[2])), an);
    out.add(pt); return pt;
  }
  Part ell(String s, String id, String nm, int c, double cx, double cy, double cz, double rx, double ry, double rz, {int an = 0}) {
    final b = B(); const la = 8, lo = 12;
    for (var i = 0; i <= la; i++) { final ph = m.pi * i / la; for (var j = 0; j <= lo; j++) { final th = 2 * m.pi * j / lo, x = m.sin(ph) * m.cos(th), y = m.cos(ph), z = m.sin(ph) * m.sin(th); b.v(cx + rx * x, cy + ry * y, cz + rz * z, x / rx, y / ry, z / rz); } }
    for (var i = 0; i < la; i++) for (var j = 0; j < lo; j++) { final a = i * (lo + 1) + j; b.t(a, a + lo + 1, a + 1); b.t(a + lo + 1, a + lo + 2, a + 1); }
    b.pk.add([cx, cy, cz, [rx, ry, rz].reduce(m.max)]);
    return _fin(s, id, nm, c, b, an);
  }
  void _cyl(B b, List<double> a, List<double> c, double r1, double r2) {
    final d = vm.Vector3(c[0] - a[0], c[1] - a[1], c[2] - a[2])..normalize();
    final u = (d.y.abs() < .9 ? vm.Vector3(0, 1, 0) : vm.Vector3(1, 0, 0)).cross(d)..normalize(), w = d.cross(u), base = b.p.length ~/ 3; const s = 8;
    for (var e = 0; e < 2; e++) { final o = e == 0 ? a : c, r = e == 0 ? r1 : r2; for (var j = 0; j <= s; j++) { final t = 2 * m.pi * j / s, nx = u.x * m.cos(t) + w.x * m.sin(t), ny = u.y * m.cos(t) + w.y * m.sin(t), nz = u.z * m.cos(t) + w.z * m.sin(t); b.v(o[0] + r * nx, o[1] + r * ny, o[2] + r * nz, nx, ny, nz); } }
    for (var j = 0; j < s; j++) { final a0 = base + j, b0 = a0 + s + 1; b.t(a0, b0, a0 + 1); b.t(b0, b0 + 1, a0 + 1); }
    final rr = m.max(r1, r2) + .008;
    for (final f in [0.0, .5, 1.0]) b.pk.add([a[0] + (c[0] - a[0]) * f, a[1] + (c[1] - a[1]) * f, a[2] + (c[2] - a[2]) * f, rr]);
  }
  Part tap(String s, String id, String nm, int c, List<double> a, List<double> b2, double r1, double r2) { final b = B(); _cyl(b, a, b2, r1, r2); return _fin(s, id, nm, c, b, 0); }
  Part tube(String s, String id, String nm, int c, List<List<double>> pts, double r) {
    final b = B(), q = <List<double>>[];
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[m.max(i - 1, 0)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[m.min(i + 2, pts.length - 1)];
      for (var s2 = 0; s2 < 4; s2++) { final t = s2 / 4, t2 = t * t, t3 = t2 * t; q.add([for (var d = 0; d < 3; d++) .5 * (2 * p1[d] + (-p0[d] + p2[d]) * t + (2 * p0[d] - 5 * p1[d] + 4 * p2[d] - p3[d]) * t2 + (-p0[d] + 3 * p1[d] - 3 * p2[d] + p3[d]) * t3)]); }
    }
    q.add(pts.last); for (var i = 0; i < q.length - 1; i++) _cyl(b, q[i], q[i + 1], r, r);
    return _fin(s, id, nm, c, b, 0);
  }
  Part lathe(String s, String id, String nm, int c, List<List<double>> pr, double zs) {
    final b = B(); const sg = 20;
    for (final q in pr) for (var j = 0; j <= sg; j++) { final th = 2 * m.pi * j / sg; b.v(q[0] * m.cos(th), q[1], q[0] * m.sin(th) * zs, m.cos(th), 0, m.sin(th) / zs); }
    for (var i = 0; i < pr.length - 1; i++) for (var j = 0; j < sg; j++) { final a = i * (sg + 1) + j; b.t(a, a + sg + 1, a + 1); b.t(a + sg + 1, a + sg + 2, a + 1); }
    for (final q in pr) b.pk.add([0, q[1], 0, q[0] * .9]);
    return _fin(s, id, nm, c, b, 0);
  }
}

List<double> o3(List<double> p, [double x = 0, double y = 0, double z = 0]) => [p[0] + x, p[1] + y, p[2] + z];

List<Part> buildBody(bool f) {
  final g = Gen(f ? .93 : 1.0);
  final sw = f ? .175 : .205, hw = f ? .09 : .08, wR = f ? .115 : .135, hR = f ? .17 : .15, cR = f ? .15 : .168, rc = f ? .93 : 1.08;
  const BC = 0xFFE6F7FF, JC = 0xFF9FE8FF, RED = 0xFFFF4A5C, BLU = 0xFF4A8CFF, SK = 0xFF4FD8FF, MU = 0xFFFF6A4A, NV = 0xFFFFD84A;
  g.lathe('skin', 'skin', 'Skin · torso', SK, [[0, .8], [hR * .9, .82], [hR, .93], [wR, 1.08], [cR, 1.28], [cR * 1.02, 1.4], [.1, 1.46], [.055, 1.5], [0, 1.5]], .62);
  g.tap('skin', 'skin', 'Skin · neck', SK, [0, 1.45, 0], [0, 1.56, .005], .05, .045);
  g.ell('skin', 'skin', 'Skin · head', SK, 0, 1.63, 0, .09, .125, .1);
  if (f) for (final s in [-1.0, 1.0]) g.ell('skin', 'skin', 'Skin · chest', SK, s * .055, 1.31, .09, .05, .05, .045);
  g.ell('skeleton', 'skull', 'Skull', BC, 0, 1.64, -.005, .085, .11, .095);
  g.ell('skeleton', 'skull', 'Jaw', BC, 0, 1.55, .04, .06, .035, .055);
  g.ell('organs', 'brain', 'Brain', 0xFFFF9BE6, 0, 1.65, -.005, .07, .08, .08);
  for (var i = 0; i < 24; i++) {
    final y = 1.52 - i * .0245, z = -.07 + .03 * m.cos(i / 23 * m.pi * 3), r = .012 + i * .0007;
    g.tap('skeleton', 'spine', i < 7 ? 'Cervical vertebra C${i + 1}' : i < 19 ? 'Thoracic vertebra T${i - 6}' : 'Lumbar vertebra L${i - 18}', BC, [0, y - .01, z], [0, y + .01, z], r, r);
  }
  g.tube('nerves', 'cord', 'Spinal cord', NV, [[0, 1.55, -.085], [0, 1.4, -.075], [0, 1.2, -.09], [0, 1.0, -.075], [0, .93, -.07]], .006);
  g.tap('skeleton', 'sternum', 'Sternum', BC, [0, 1.43, .1], [0, 1.25, .115], .018, .012);
  g.ell('skeleton', 'pelvis', 'Sacrum', BC, 0, .92, -.07, .05, .07, .03);
  g.ell('skeleton', 'pelvis', 'Pubic bone', BC, 0, .86, .075, .05, .02, .02);
  g.ell('organs', 'heart', 'Heart', 0xFFFF4D6A, .03, 1.27, .04, .032, .041, .03, an: 1);
  g.ell('organs', 'liver', 'Liver', 0xFFFFA14A, -.06, 1.14, .04, .09, .05, .06);
  g.ell('organs', 'stomach', 'Stomach', 0xFFC59BFF, .06, 1.15, .04, .05, .06, .04);
  g.ell('organs', 'gut', 'Small intestine', 0xFFFFD36B, 0, .97, .03, .1, .07, .05);
  g.ell('organs', 'bladder', 'Bladder', 0xFFAAFFEE, 0, .88, .045, .03, .03, .03);
  g.tube('organs', 'gut', 'Large intestine', 0xFFFFB347, [[-.09, .9, .03], [-.09, 1.07, .03], [.09, 1.07, .03], [.09, .9, .03]], .018);
  for (final s in [-1.0, 1.0]) {
    final sd = s > 0 ? 'Left ' : 'Right ';
    final List<double> sh = [s * sw, 1.43, 0], el = [s * (sw + .04), 1.12, 0], wr = [s * (sw + .115), .87, .03], hp = [s * hw, .92, 0], kn = [s * (hw + .02), .51, .01], an = [s * (hw + .035), .1, 0];
    g.ell('organs', 'lungs', '${sd}lung', 0xFF7AB8FF, s * .075, 1.31, 0, .06, .1, .065, an: 2);
    g.ell('organs', 'kidney', '${sd}kidney', 0xFFFF7A9C, s * .06, 1.08, -.06, .025, .04, .02);
    g.ell('organs', 'eye', '${sd}eye', 0xFFFFFFFF, s * .032, 1.645, .085, .012, .012, .012);
    for (var i = 0; i < 10; i++) {
      final y0 = 1.42 - i * .036, k = m.min(i, 6), rx = (.085 + .009 * k) * rc, rz = (.055 + .005 * k) * (f ? .95 : 1.0);
      g.tube('skeleton', 'ribs', '$sd' 'rib ${i + 1}', BC, [for (var a = 0.0; a <= 2.6; a += .2) [s * rx * m.sin(a), y0 - .05 * a / 2.6, -rz * m.cos(a)]], .0045);
    }
    g.tap('skeleton', 'girdle', '${sd}clavicle', BC, [s * .02, 1.46, .05], [s * sw, 1.45, 0], .009, .009);
    g.ell('skeleton', 'girdle', '${sd}scapula', BC, s * (sw - .05), 1.38, -.07, .06, .08, .012);
    g.tap('skeleton', 'humerus', '${sd}humerus', BC, sh, el, .02, .016);
    g.tap('skeleton', 'forearm', '${sd}radius & ulna', BC, el, wr, .015, .01);
    g.tap('skeleton', 'hand', '${sd}hand', BC, wr, o3(wr, s * .01, -.1, .02), .02, .012);
    for (var i = 0; i < 5; i++) {
      final fingerStart = o3(wr, s * .01, -.1, .012);
      final fingerEnd = o3(wr, s * (.02 + i * .004), -.174, .018 + i * .006);
      // Keep phalanges comfortably inside the hand/finger skin envelope.
      g.tap('skeleton', 'hand', '${sd}finger', BC, fingerStart, fingerEnd, .0032, .0022);
    }
    g.tap('skeleton', 'femur', '${sd}femur', BC, hp, kn, .028, .022);
    g.tap('skeleton', 'tibia', '${sd}tibia', BC, kn, an, .022, .016);
    g.tap('skeleton', 'tibia', '${sd}fibula', BC, o3(kn, s * .02, -.02), o3(an, s * .02, .02), .009, .007);
    g.tap('skeleton', 'foot', '${sd}foot', BC, an, [an[0], .03, .13], .02, .014);
    g.ell('skeleton', 'pelvis', '${sd}iliac wing', BC, s * (hw + .01), .97, -.01, f ? .08 : .065, .06, .035);
    for (final j in [['shoulder', sh, .038], ['elbow', el, .028], ['wrist', wr, .02], ['hip', hp, .042], ['knee', kn, .042], ['ankle', an, .03]]) {
      final c = j[1] as List<double>, r = j[2] as double; g.ell('skeleton', j[0] as String, '$sd${j[0]} joint', JC, c[0], c[1], c[2], r, r, r);
    }
    g.tube('vessels', 'artery', '$sd' 'arm artery', RED, [[.01, 1.4, 0], [s * .1, 1.44, .01], o3(el, 0, 0, -.018), o3(wr, 0, 0, -.018)], .0032);
    g.tube('vessels', 'vein', '$sd' 'arm vein', BLU, [o3(wr, s * .01, 0, -.024), o3(el, s * .01, 0, -.026), [s * .06, 1.42, -.02], [.01, 1.36, -.02]], .0032);
    g.tube('vessels', 'artery', '$sd' 'leg artery', RED, [[0, .95, -.035], o3(hp, 0, -.06, -.028), o3(kn, 0, 0, -.028), o3(an, 0, 0, -.025)], .0048);
    g.tube('vessels', 'vein', '$sd' 'leg vein', BLU, [o3(an, s * .012, 0, -.025), o3(kn, s * .012, 0, -.03), o3(hp, s * .012, -.06, -.028), [0, .95, -.02]], .0048);
    g.tube('vessels', 'artery', '$sd' 'carotid artery', RED, [[s * .02, 1.38, .02], [s * .03, 1.5, .02], [s * .035, 1.62, .02]], .006);
    g.tube('vessels', 'vein', '$sd' 'jugular vein', BLU, [[s * .04, 1.6, -.01], [s * .045, 1.5, -.01], [s * .03, 1.4, 0]], .006);
    g.tube('nerves', 'nerve', '$sd' 'arm nerve', NV, [[0, 1.46, -.07], o3(sh, 0, 0, -.03), o3(el, 0, 0, -.03), o3(wr, 0, 0, -.02)], .003);
    g.tube('nerves', 'nerve', '$sd' 'sciatic nerve', NV, [[0, .95, -.07], [s * .07, .82, -.06], o3(kn, 0, 0, -.05), o3(an, 0, 0, -.03)], .004);
    // Layered superficial muscle groups. These are stylized anatomical masses,
    // not clinical-grade muscle meshes; higher segment counts give smoother contours.
    g.ell('muscle', 'muscle', '${sd}pectoralis major', MU, s * .075, 1.345, .078, .078, .052, .034);
    g.ell('muscle', 'muscle', '${sd}pectoralis minor', 0xFFFF8062, s * .052, 1.30, .055, .038, .045, .022);
    g.ell('muscle', 'muscle', '${sd}deltoid anterior', MU, s * sw, 1.425, .035, .043, .052, .046);
    g.ell('muscle', 'muscle', '${sd}deltoid posterior', 0xFFFF805C, s * sw, 1.415, -.035, .042, .052, .04);
    g.tap('muscle', 'muscle', '${sd}biceps brachii', MU, o3(sh, 0, 0, .032), o3(el, 0, 0, .028), .036, .024);
    g.tap('muscle', 'muscle', '${sd}triceps brachii', 0xFFE95743, o3(sh, 0, 0, -.03), o3(el, 0, 0, -.025), .034, .022);
    g.tap('muscle', 'muscle', '${sd}brachioradialis', 0xFFFF8A65, o3(el, 0, 0, .025), o3(wr, 0, 0, .018), .021, .011);
    g.tap('muscle', 'muscle', '${sd}forearm flexors', MU, o3(el, 0, 0, .005), o3(wr, 0, 0, .005), .022, .012);
    g.tap('muscle', 'muscle', '${sd}forearm extensors', 0xFFE95743, o3(el, 0, 0, -.018), o3(wr, 0, 0, -.012), .02, .01);
    g.ell('muscle', 'muscle', '${sd}external oblique', 0xFFE95743, s * .085, 1.12, .055, .035, .105, .025);
    for (var r = 0; r < 4; r++) {
      g.ell('muscle', 'muscle', '${sd}rectus abdominis ${r + 1}', MU, s * .024, 1.205 - r * .052, .105, .022, .024, .014);
    }
    g.ell('muscle', 'muscle', '${sd}serratus anterior', 0xFFFF8968, s * .105, 1.255, .035, .022, .075, .022);
    g.ell('muscle', 'muscle', '${sd}latissimus dorsi', 0xFFE95743, s * .085, 1.19, -.065, .055, .15, .025);
    g.ell('muscle', 'muscle', '${sd}gluteus maximus', MU, s * .075, .9, -.08, .073, .073, .052);
    g.ell('muscle', 'muscle', '${sd}gluteus medius', 0xFFFF8968, s * .105, .96, -.055, .045, .052, .035);
    g.tap('muscle', 'muscle', '${sd}rectus femoris', MU, o3(hp, 0, 0, .045), o3(kn, 0, 0, .035), .032, .022);
    g.tap('muscle', 'muscle', '${sd}vastus lateralis', 0xFFE95743, o3(hp, s * .035, 0, .015), o3(kn, s * .025, 0, .015), .04, .027);
    g.tap('muscle', 'muscle', '${sd}vastus medialis', 0xFFFF8968, o3(hp, -s * .018, 0, .035), o3(kn, -s * .018, 0, .035), .027, .021);
    g.tap('muscle', 'muscle', '${sd}hamstrings', 0xFFE95743, o3(hp, 0, 0, -.045), o3(kn, 0, 0, -.03), .036, .023);
    g.tap('muscle', 'muscle', '${sd}gastrocnemius', MU, [kn[0], .46, -.035], [an[0], .16, -.025], .044, .018);
    g.tap('muscle', 'muscle', '${sd}soleus', 0xFFE95743, [kn[0], .38, -.018], [an[0], .12, -.018], .027, .014);
    g.tap('muscle', 'muscle', '${sd}tibialis anterior', 0xFFFF8968, [kn[0], .46, .035], [an[0], .12, .025], .022, .012);
    g.tap('skin', 'skin', 'Skin · arm', SK, sh, el, .045, .035);
    g.tap('skin', 'skin', 'Skin · forearm', SK, el, wr, .033, .025);
    g.ell('skin', 'skin', 'Skin · hand', SK, wr[0] + s * .01, wr[1] - .065, wr[2] + .012, .034, .073, .023);
    for (var i = 0; i < 5; i++) {
      final fingerStart = o3(wr, s * .01, -.1, .012);
      final fingerEnd = o3(wr, s * (.02 + i * .004), -.174, .018 + i * .006);
      g.tap('skin', 'skin', 'Skin · finger', SK, fingerStart, fingerEnd, .008, .006);
    }
    g.tap('skin', 'skin', 'Skin · thigh', SK, hp, kn, .075, .06);
    g.tap('skin', 'skin', 'Skin · leg', SK, kn, an, .05, .03);
    g.ell('skin', 'skin', 'Skin · foot', SK, an[0], .04, .05, .04, .035, .1);
  }
  g.tube('vessels', 'artery', 'Aorta', RED, [[.02, 1.33, .03], [0, 1.4, 0], [.04, 1.36, -.04], [.03, 1.2, -.045], [.02, 1.0, -.04], [0, .93, -.03]], .011);
  g.tube('vessels', 'vein', 'Vena cava', BLU, [[-.02, 1.3, .035], [-.025, 1.1, -.02], [-.02, .93, -.02]], .012);
  return g.out;
}

// ───────────────────────── interactive anatomy viewer ─────────────────────────

class HoloApp extends StatelessWidget {
  const HoloApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF06111D);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF54DFFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HoloPage(),
    );
  }
}

class HoloPage extends StatefulWidget {
  const HoloPage({super.key});
  @override
  State<HoloPage> createState() => _HoloPageState();
}

class _HoloPageState extends State<HoloPage> {
  // Geometry is immutable between model changes; build it once and reuse it.
  static final List<Part> _maleParts = buildBody(false);
  static final List<Part> _femaleParts = buildBody(true);
  bool female = false;
  bool skinVisible = false;
  bool musclesVisible = false;
  bool skeletonVisible = true;
  bool organsVisible = true;
  bool vesselsVisible = true;
  bool nervesVisible = false;
  double yaw = 0.0;
  double pitch = 0.0;
  double zoom = 1.0;
  double _gestureStartZoom = 1.0;
  double focusX = 0, focusY = .88, focusZ = 0;
  Part? selected;
  late List<Part> parts;
  late List<Part> _visibleParts;
  double layerOpacity = 1.0;
  double outerSkinOpacity = 0.22;
  bool isolateSelection = false;
  final ValueNotifier<int> _viewRevision = ValueNotifier<int>(0);
  final FocusNode _cameraFocusNode = FocusNode(debugLabel: 'Anatomy camera');

  // Camera-space movement changes the model focus only; it never changes zoom.
  static const double _panStep = 0.055;

  KeyEventResult _handleCameraKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rightX = m.cos(yaw);
    final rightZ = -m.sin(yaw);
    final upX = m.sin(yaw) * m.sin(pitch);
    final upY = m.cos(pitch);
    final upZ = m.cos(yaw) * m.sin(pitch);
    var dx = 0.0, dy = 0.0, dz = 0.0;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyA:
        dx = -rightX * _panStep; dz = -rightZ * _panStep; break;
      case LogicalKeyboardKey.keyD:
        dx = rightX * _panStep; dz = rightZ * _panStep; break;
      case LogicalKeyboardKey.keyW:
        dx = upX * _panStep; dy = upY * _panStep; dz = upZ * _panStep; break;
      case LogicalKeyboardKey.keyS:
        dx = -upX * _panStep; dy = -upY * _panStep; dz = -upZ * _panStep; break;
      default:
        return KeyEventResult.ignored;
    }
    setState(() {
      focusX += dx;
      focusY += dy;
      focusZ += dz;
    });
    _viewRevision.value++;
    return KeyEventResult.handled;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final factor = m.exp(-event.scrollDelta.dy * 0.0015);
      setState(() {
        zoom = (zoom * factor).clamp(.45, 5.0).toDouble();
      });
      _viewRevision.value++;
    }
  }

  static const systems = <String, String>{
    'skin': 'Outer layer',
    'muscle': 'Muscles',
    'skeleton': 'Skeleton & joints',
    'organs': 'Organs',
    'vessels': 'Blood vessels',
    'nerves': 'Nervous system',
  };

  @override
  void dispose() {
    _viewRevision.dispose();
    _cameraFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    parts = female ? _femaleParts : _maleParts;
    _refreshVisibleParts();
  }

  void _refreshVisibleParts() {
    _visibleParts = parts.where((p) => visible(p.sys) &&
        (!isolateSelection || selected == null || p.sys == selected!.sys)).toList(growable: false);
  }

  void _focusPart(Part part) {
    setState(() {
      selected = part;
      focusX = part.cx; focusY = part.cy; focusZ = part.cz;
      zoom = (zoom * 1.45).clamp(1.0, 3.2).toDouble();
      isolateSelection = false;
      _refreshVisibleParts();
    });
  }

  bool visible(String sys) {
    switch (sys) {
      case 'skin': return skinVisible;
      case 'muscle': return musclesVisible;
      case 'skeleton': return skeletonVisible;
      case 'organs': return organsVisible;
      case 'vessels': return vesselsVisible;
      case 'nerves': return nervesVisible;
      default: return false;
    }
  }

  void toggleSystem(String sys, bool value) {
    setState(() {
      switch (sys) {
        case 'skin': skinVisible = value; break;
        case 'muscle': musclesVisible = value; break;
        case 'skeleton': skeletonVisible = value; break;
        case 'organs': organsVisible = value; break;
        case 'vessels': vesselsVisible = value; break;
        case 'nerves': nervesVisible = value; break;
      }
      _refreshVisibleParts();
    });
  }

  void changeModel(bool toFemale) {
    setState(() {
      female = toFemale;
      parts = female ? _femaleParts : _maleParts;
        selected = null;
      isolateSelection = false;
      yaw = 0;
      pitch = 0;
      zoom = 1;
      focusX = 0; focusY = .88; focusZ = 0;
      _refreshVisibleParts();
    });
  }

  void applyPreset(String preset) {
    setState(() {
      skinVisible = preset == 'surface';
      musclesVisible = preset == 'muscular' || preset == 'all';
      skeletonVisible = preset == 'skeletal' || preset == 'all';
      organsVisible = preset == 'organs' || preset == 'all';
      vesselsVisible = preset == 'circulatory' || preset == 'all';
      nervesVisible = preset == 'nervous' || preset == 'all';
      if (preset == 'all') skinVisible = false;
      selected = null;
      isolateSelection = false;
      zoom = 1;
      focusX = 0; focusY = .88; focusZ = 0;
      _refreshVisibleParts();
    });
  }

  void setCameraView(String view) {
    setState(() {
      yaw = view == 'left' ? -m.pi / 2 : view == 'right' ? m.pi / 2 : view == 'back' ? m.pi : 0;
      pitch = 0;
    });
  }

  void selectAt(Offset point, Size size) {
    Part? nearest;
    double nearestDistance = double.infinity;
    for (final part in _visibleParts) {
      final p = _project(part.cx, part.cy, part.cz, size);
      final radius = (part.ext * size.height * .48 / (3.8 / zoom)).clamp(12.0, 42.0);
      final d = (Offset(p.$1, p.$2) - point).distance;
      if (d < radius && d < nearestDistance) {
        nearestDistance = d;
        nearest = part;
      }
    }
    if (nearest != null) _focusPart(nearest);
  }

  (double, double, double) _rotate(double x, double y, double z) {
    final yy = y - focusY;
    x -= focusX;
    z -= focusZ;
    final cy = m.cos(yaw), sy = m.sin(yaw);
    final x1 = x * cy + z * sy;
    final z1 = -x * sy + z * cy;
    final cp = m.cos(pitch), sp = m.sin(pitch);
    final y2 = yy * cp - z1 * sp;
    final z2 = yy * sp + z1 * cp;
    return (x1, y2, z2);
  }

  (double, double) _project(double x, double y, double z, Size size) {
    final r = _rotate(x, y, z);
    final cameraDistance = 3.8 / zoom;
    final depth = cameraDistance - r.$3;
    final focal = size.height * 1.05;
    return (size.width * .5 + r.$1 * focal / depth,
        size.height * .52 - r.$2 * focal / depth);
  }

  Future<void> _openAnatomyBrowser() async {
    final query = TextEditingController();
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF0A1A29),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => StatefulBuilder(builder: (context, refreshSheet) {
        final q = query.text.trim().toLowerCase();
        final matches = parts.where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.id.toLowerCase().contains(q) || p.sys.toLowerCase().contains(q)).toList();
        return SafeArea(child: Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: SizedBox(height: MediaQuery.of(context).size.height * .72, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Expanded(child: Text('ANATOMY LIBRARY', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.4, color: Color(0xFF8BEAFF)))), IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close))]),
            TextField(controller: query, onChanged: (_) => refreshSheet(() {}), decoration: InputDecoration(hintText: 'Search bone, organ, joint or system', prefixIcon: const Icon(Icons.search), filled: true, fillColor: const Color(0xFF102638), border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none))),
            const SizedBox(height: 10),
            Text('${matches.length} structures', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 6),
            Expanded(child: ListView.separated(itemCount: matches.length, separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF20394A)), itemBuilder: (_, i) {
              final part = matches[i];
              return ListTile(dense: true, leading: const Icon(Icons.hub_outlined, color: Color(0xFF63DFFF)), title: Text(part.name, style: const TextStyle(fontSize: 13)), subtitle: Text(systems[part.sys] ?? part.sys, style: const TextStyle(fontSize: 11, color: Colors.white54)), trailing: const Icon(Icons.center_focus_strong, size: 17), onTap: () {
                Navigator.pop(sheetContext);
                if (!visible(part.sys)) toggleSystem(part.sys, true);
                _focusPart(part);
              });
            })),
          ])),
        ));
      }),
    );
    query.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPart = selected;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HOLO • ANATOMY', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w800, fontSize: 16)),
            Text('Interactive human anatomy explorer', style: TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
        backgroundColor: const Color(0xFF091A2A),
        actions: [
          IconButton(tooltip: 'Search anatomy', onPressed: _openAnatomyBrowser, icon: const Icon(Icons.search)),
          IconButton(
            tooltip: 'Crew health log (offline)',
            onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (BuildContext routeContext) { return const HealthMonitorPage(); })),
            icon: const Icon(Icons.monitor_heart_outlined),
          ),
          IconButton(
            tooltip: 'Emergency reference',
            onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (BuildContext routeContext) { return const EmergencyReferencePage(); })),
            icon: const Icon(Icons.emergency_outlined, color: Color(0xFFFF7373)),
          ),
          IconButton(
            tooltip: 'Reset view',
            onPressed: () => setState(() { yaw = 0; pitch = 0; zoom = 1; selected = null; isolateSelection = false; focusX = 0; focusY = .88; focusZ = 0; _refreshVisibleParts(); }),
            icon: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final viewSize = Size(constraints.maxWidth, constraints.maxHeight);
                return ValueListenableBuilder<int>(
                  valueListenable: _viewRevision,
                  builder: (context, revision, child) => Stack(
                  children: [
                    Focus(
                      focusNode: _cameraFocusNode,
                      autofocus: true,
                      onKeyEvent: _handleCameraKey,
                      child: Listener(
                        onPointerSignal: _handlePointerSignal,
                        child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => _cameraFocusNode.requestFocus(),
                      onScaleStart: (_) => _gestureStartZoom = zoom,
                      onScaleUpdate: (d) {
                        if (d.pointerCount > 1) {
                          zoom = (_gestureStartZoom * d.scale).clamp(.65, 3.2).toDouble();
                        } else {
                          yaw += d.focalPointDelta.dx * .009;
                          pitch = (pitch + d.focalPointDelta.dy * .009).clamp(-1.25, 1.25).toDouble();
                        }
                        // Rebuild only the viewer subtree while dragging; keep
                        // the app bar and anatomy controls out of the hot path.
                        _viewRevision.value++;
                      },
                      onTapUp: (d) => selectAt(d.localPosition, viewSize),
                      child: RepaintBoundary(
                        child: CustomPaint(
                        size: Size.infinite,
                        painter: AnatomyPainter(
                          parts: _visibleParts,
                          yaw: yaw,
                          pitch: pitch,
                          zoom: zoom,
                          selected: selectedPart,
                          female: female,
                          focusX: focusX, focusY: focusY, focusZ: focusZ,
                          layerOpacity: layerOpacity,
                          outerSkinOpacity: outerSkinOpacity,
                        ),
                      ),
                      ),
                      ),
                      ),
                    ),
                    Positioned(
                      left: 14, top: 12,
                      child: _glassTag(female ? 'FEMALE MODEL' : 'MALE MODEL', Icons.accessibility_new),
                    ),
                    Positioned(
                      right: 14, top: 12,
                      child: _glassTag('DRAG ROTATE • WHEEL ZOOM • WASD MOVE', Icons.threed_rotation),
                    ),
                    Positioned(
                      left: 14,
                      top: 56,
                      child: Wrap(
                        spacing: 5,
                        children: [
                          _viewButton('Front', () => setCameraView('front')),
                          _viewButton('Left', () => setCameraView('left')),
                          _viewButton('Right', () => setCameraView('right')),
                          _viewButton('Back', () => setCameraView('back')),
                        ],
                      ),
                    ),
                    if (selectedPart != null)
                      Positioned(
                        left: 14, right: 14, bottom: 12,
                        child: _selectedCard(selectedPart),
                      ),
                  ],
                ),
                );
              }),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0A1A29),
                border: Border(top: BorderSide(color: Color(0xFF19364A))),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('QUICK VIEWS', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 7),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _presetButton('Surface', () => applyPreset('surface')),
                      _presetButton('Skeleton', () => applyPreset('skeletal')),
                      _presetButton('Muscles', () => applyPreset('muscular')),
                      _presetButton('Organs', () => applyPreset('organs')),
                      _presetButton('Circulatory', () => applyPreset('circulatory')),
                      _presetButton('Nervous', () => applyPreset('nervous')),
                      _presetButton('All systems', () => applyPreset('all')),
                    ]),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      const Text('MODEL', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white54, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      _genderButton('Male', !female, () => changeModel(false)),
                      const SizedBox(width: 8),
                      _genderButton('Female', female, () => changeModel(true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('ANATOMICAL LAYERS', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: systems.entries.map((entry) {
                        final active = visible(entry.key);
                        return Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: FilterChip(
                            label: Text(entry.value, style: const TextStyle(fontSize: 11)),
                            selected: active,
                            showCheckmark: true,
                            onSelected: (v) => toggleSystem(entry.key, v),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: const Color(0xFF102638),
                            selectedColor: const Color(0xFF14516A),
                            side: BorderSide(color: active ? const Color(0xFF55DFFF) : const Color(0xFF294253)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.opacity, size: 16, color: Colors.white54),
                    const SizedBox(width: 7),
                    const Text('HOLOGRAM', style: TextStyle(fontSize: 9, letterSpacing: 1, color: Colors.white54)),
                    Expanded(child: Slider(value: layerOpacity, min: .25, max: 1, onChanged: (v) { setState(() => layerOpacity = v); _viewRevision.value++; })),
                    Text('${(layerOpacity * 100).round()}%', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                  ]),
                  Row(children: [
                    const Icon(Icons.face_retouching_natural, size: 16, color: Colors.white54),
                    const SizedBox(width: 7),
                    const Text('OUTER SKIN', style: TextStyle(fontSize: 9, letterSpacing: 1, color: Colors.white54)),
                    Expanded(child: Slider(
                      value: outerSkinOpacity,
                      min: 0,
                      max: 1,
                      onChanged: (v) { setState(() => outerSkinOpacity = v); _viewRevision.value++; },
                    )),
                    SizedBox(width: 34, child: Text('${(outerSkinOpacity * 100).round()}%', textAlign: TextAlign.end, style: const TextStyle(fontSize: 10, color: Colors.white60))),
                  ]),
                  Row(
                    children: [
                      const Icon(Icons.zoom_out, size: 17, color: Colors.white54),
                      Expanded(
                        child: Slider(
                          value: zoom.clamp(.65, 3.2).toDouble(),
                          min: .65,
                          max: 3.2,
                          onChanged: (v) => setState(() => zoom = v),
                        ),
                      ),
                      const Icon(Icons.zoom_in, size: 17, color: Colors.white54),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Clear selection',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() { selected = null; isolateSelection = false; zoom = 1; focusX = 0; focusY = .88; focusZ = 0; _refreshVisibleParts(); }),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewButton(String label, VoidCallback action) => Padding(
    padding: const EdgeInsets.only(right: 3),
    child: TextButton(
      onPressed: action,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        foregroundColor: const Color(0xFF9DEBFF),
        backgroundColor: const Color(0xCC0B2233),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(label),
    ),
  );

  Widget _presetButton(String label, VoidCallback action) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: OutlinedButton(
      onPressed: action,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        foregroundColor: const Color(0xFF9DEBFF),
        side: const BorderSide(color: Color(0xFF28536A)),
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 10),
      ),
      child: Text(label),
    ),
  );

  Widget _glassTag(String text, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xCC0B2233),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF24536A)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: const Color(0xFF63DFFF)),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 9, letterSpacing: .8, color: Colors.white70)),
    ]),
  );

  Widget _genderButton(String label, bool active, VoidCallback action) => OutlinedButton(
    onPressed: action,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      minimumSize: const Size(0, 32),
      foregroundColor: active ? const Color(0xFF65E2FF) : Colors.white70,
      side: BorderSide(color: active ? const Color(0xFF65E2FF) : const Color(0xFF355064)),
      backgroundColor: active ? const Color(0xFF12394B) : Colors.transparent,
    ),
    child: Text(label, style: const TextStyle(fontSize: 11)),
  );

  Widget _selectedCard(Part part) {
    final details = kInfo[part.id] ?? kInfo[part.sys] ?? 'Anatomical structure selected.';
    final pieces = details.split('|');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xEE0A1D2B),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF4BDFFF), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x5537CFFF), blurRadius: 18)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: Text(part.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8BEAFF)))),
          IconButton(onPressed: () => setState(() { selected = null; isolateSelection = false; zoom = 1; focusX = 0; focusY = .88; focusZ = 0; _refreshVisibleParts(); }), icon: const Icon(Icons.close, size: 17), visualDensity: VisualDensity.compact),
        ]),
        if (pieces.isNotEmpty) Text(pieces[0], style: const TextStyle(fontSize: 12, color: Colors.white)),
        if (pieces.length > 1) Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(pieces[1], style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ),
        const SizedBox(height: 7),
        Wrap(spacing: 7, children: [
          TextButton.icon(onPressed: () => setState(() { isolateSelection = !isolateSelection; _refreshVisibleParts(); }), icon: Icon(isolateSelection ? Icons.layers : Icons.filter_center_focus, size: 15), label: Text(isolateSelection ? 'Show all systems' : 'Isolate system')),
          TextButton.icon(onPressed: () => _openAnatomyBrowser(), icon: const Icon(Icons.menu_book, size: 15), label: const Text('Browse anatomy')),
        ]),
      ]),
    );
  }
}

class AnatomyPainter extends CustomPainter {
  final List<Part> parts;
  final double yaw, pitch, zoom;
  final Part? selected;
  final bool female;
  final double focusX, focusY, focusZ, layerOpacity, outerSkinOpacity;
  AnatomyPainter({required this.layerOpacity, required this.outerSkinOpacity, required this.parts, required this.yaw, required this.pitch, required this.zoom, required this.selected, required this.female, required this.focusX, required this.focusY, required this.focusZ});

  (double, double, double) _rotate(double x, double y, double z) {
    final yy = y - focusY;
    x -= focusX;
    z -= focusZ;
    final cy = m.cos(yaw), sy = m.sin(yaw);
    final x1 = x * cy + z * sy;
    final z1 = -x * sy + z * cy;
    final cp = m.cos(pitch), sp = m.sin(pitch);
    return (x1, yy * cp - z1 * sp, yy * sp + z1 * cp);
  }

  (Offset, double) _project(double x, double y, double z, Size size) {
    final r = _rotate(x, y, z);
    final camera = 3.8 / zoom;
    final depth = camera - r.$3;
    final focal = size.height * 1.05;
    return (Offset(size.width * .5 + r.$1 * focal / depth,
        size.height * .52 - r.$2 * focal / depth), depth);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bgPaint = Paint()..shader = const RadialGradient(
      colors: [Color(0xFF102C40), Color(0xFF071522), Color(0xFF040B12)],
      stops: [0, .55, 1],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final gridPaint = Paint()..color = const Color(0x183F9BB9)..strokeWidth = .6;
    for (double x = 0; x < size.width; x += 28) canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    for (double y = 0; y < size.height; y += 28) canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

    final cy = m.cos(yaw), sy = m.sin(yaw);
    final cp = m.cos(pitch), sp = m.sin(pitch);
    final cameraDistance = 3.8 / zoom;
    final focal = size.height * 1.05;

    // Render each anatomical part as one indexed vertex batch. The previous
    // implementation allocated one Dart object per triangle and globally
    // depth-sorted every triangle on every frame. That is expensive during drag.
    // Geometry is immutable, so only the projected vertex buffer is rebuilt.
    for (final part in parts) {
      final vertexCount = part.p.length ~/ 3;
      if (vertexCount == 0 || part.ixL.isEmpty) continue;

      final positions = Float32List(vertexCount * 2);
      var visibleVertices = 0;
      for (var v = 0; v < vertexCount; v++) {
        final j = v * 3;
        final x = part.p[j] - focusX;
        final y = part.p[j + 1] - focusY;
        final z = part.p[j + 2] - focusZ;
        final rx = x * cy + z * sy;
        final rz = -x * sy + z * cy;
        final ry = y * cp - rz * sp;
        final rotatedZ = y * sp + rz * cp;
        final depth = cameraDistance - rotatedZ;
        // Inline projection avoids allocating a tuple and Offset for every
        // vertex on every frame, which is important on mid-range phones.
        if (depth <= .12) {
          positions[v * 2] = -100000;
          positions[v * 2 + 1] = -100000;
        } else {
          positions[v * 2] = size.width * .5 + rx * focal / depth;
          positions[v * 2 + 1] = size.height * .52 - ry * focal / depth;
          visibleVertices++;
        }
      }
      if (visibleVertices == 0) continue;

      final baseAlpha = part.sys == 'skin' ? 235 : part.sys == 'vessels' ? 220 : 205;
      final opacity = part.sys == 'skin' ? outerSkinOpacity : layerOpacity;
      final alpha = (baseAlpha * opacity).round().clamp(0, 255).toInt();
      final color = identical(part, selected)
          ? const Color(0xFFFFE58A).withAlpha(240)
          : Color(part.col).withAlpha(alpha);
      final colors = Int32List(vertexCount);
      colors.fillRange(0, vertexCount, color.value);
      final vertices = ui.Vertices.raw(
        ui.VertexMode.triangles,
        positions,
        colors: colors,
        indices: part.ixL,
      );
      canvas.drawVertices(vertices, BlendMode.srcOver, Paint()..isAntiAlias = false);
    }

    // Fine capillary overlay intentionally disabled: it was projected in screen space
    // without depth testing and therefore appeared to float outside the skin.
    // Anatomical artery/vein meshes remain rendered with the body geometry.

  }

  @override
  bool shouldRepaint(covariant AnatomyPainter oldDelegate) =>
      oldDelegate.parts != parts || oldDelegate.yaw != yaw ||
      oldDelegate.pitch != pitch || oldDelegate.zoom != zoom ||
      oldDelegate.selected != selected || oldDelegate.female != female || oldDelegate.focusX != focusX || oldDelegate.focusY != focusY || oldDelegate.focusZ != focusZ || oldDelegate.layerOpacity != layerOpacity || oldDelegate.outerSkinOpacity != outerSkinOpacity;
}
