import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as math;
import '../core/mesh_3d.dart';

class BoxGeometry extends Mesh3D {
  BoxGeometry({
    double width = 1.0,
    double height = 1.0,
    double depth = 1.0,
    Color color = Colors.blue,
  }) : super(
          vertices: _generateVertices(width, height, depth),
          indices: _generateIndices(),
          color: color,
        );

  /// Bir küpün 8 köşesini (Vertex) hesaplar
  static List<math.Vector3> _generateVertices(double w, double h, double d) {
    // Merkezden dışa doğru uzaklıklar
    double hw = w / 2;
    double hh = h / 2;
    double hd = d / 2;

    return [
      math.Vector3(-hw, -hh,  hd), // 0: Sol-Alt-Ön
      math.Vector3( hw, -hh,  hd), // 1: Sağ-Alt-Ön
      math.Vector3( hw,  hh,  hd), // 2: Sağ-Üst-Ön
      math.Vector3(-hw,  hh,  hd), // 3: Sol-Üst-Ön
      math.Vector3(-hw, -hh, -hd), // 4: Sol-Alt-Arka
      math.Vector3( hw, -hh, -hd), // 5: Sağ-Alt-Arka
      math.Vector3( hw,  hh, -hd), // 6: Sağ-Üst-Arka
      math.Vector3(-hw,  hh, -hd), // 7: Sol-Üst-Arka
    ];
  }

  /// Köşeleri saat yönünde (Clockwise) birleştirerek üçgen yüzeyleri tanımlar
  static List<int> _generateIndices() {
    return [
      // Ön Yüz (2 üçgen)
      0, 1, 2,  0, 2, 3,
      // Arka Yüz
      5, 4, 7,  5, 7, 6,
      // Sol Yüz
      4, 0, 3,  4, 3, 7,
      // Sağ Yüz
      1, 5, 6,  1, 6, 2,
      // Üst Yüz
      3, 2, 6,  3, 6, 7,
      // Alt Yüz
      4, 5, 1,  4, 1, 0,
    ];
  }
}