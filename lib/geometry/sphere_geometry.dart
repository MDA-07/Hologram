import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as math;
import 'dart:math' as dart_math;
import '../core/mesh_3d.dart';

class SphereGeometry extends Mesh3D {
  SphereGeometry({
    double radius = 1.0,
    int segments = 12, // Düşük poligonlu (Low-poly) casual görünüm
    Color color = Colors.red,
  }) : super(
          vertices: _generateVertices(radius, segments),
          indices: _generateIndices(segments),
          color: color,
        );

  static List<math.Vector3> _generateVertices(double radius, int segments) {
    List<math.Vector3> vertices = [];
    for (int y = 0; y <= segments; y++) {
      double v = y / segments;
      double phi = v * dart_math.pi; // 0'dan Pi'ye (Kuzey kutbundan Güney kutbuna)

      for (int x = 0; x <= segments; x++) {
        double u = x / segments;
        double theta = u * dart_math.pi * 2; // 0'dan 2*Pi'ye (Ekvator etrafında 360 derece)

        double xPos = radius * dart_math.sin(phi) * dart_math.cos(theta);
        double yPos = radius * dart_math.cos(phi);
        double zPos = radius * dart_math.sin(phi) * dart_math.sin(theta);

        vertices.add(math.Vector3(xPos, yPos, zPos));
      }
    }
    return vertices;
  }

  static List<int> _generateIndices(int segments) {
    List<int> indices = [];
    for (int y = 0; y < segments; y++) {
      for (int x = 0; x < segments; x++) {
        int first = (y * (segments + 1)) + x;
        int second = first + segments + 1;

        // Kare yüzeyi oluşturan iki üçgeni saat yönünde ekle
        indices.addAll([first, second, first + 1]);
        indices.addAll([second, second + 1, first + 1]);
      }
    }
    return indices;
  }
}