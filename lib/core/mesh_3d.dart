import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as math;

class Mesh3D {
  // Uzaydaki 3 boyutlu noktalar (Köşeler)
  final List<math.Vector3> vertices;
  
  // Hangi köşelerin birleşip üçgen yüzey oluşturacağını belirten sıra
  final List<int> indices;
  
  // Objenin temel rengi
  final Color color;

  // Objenin dünyadaki konumu, dönüşü ve ölçeğini tutan yerel matris
  math.Matrix4 transform = math.Matrix4.identity();

  Mesh3D({
    required this.vertices,
    required this.indices,
    this.color = Colors.white,
  });

  /// Nesneyi X, Y, Z eksenlerinde kaydırır
  Mesh3D translate({double x = 0, double y = 0, double z = 0}) {
    transform.translate(x, y, z);
    return this; // Zincirleme kullanım (Cascade) için kendini döndür
  }

  /// Nesneyi X ekseninde döndürür (Radyan cinsinden)
  Mesh3D rotateX(double angleRadians) {
    transform.rotateX(angleRadians);
    return this;
  }

  /// Nesneyi Y ekseninde döndürür (Radyan cinsinden)
  Mesh3D rotateY(double angleRadians) {
    transform.rotateY(angleRadians);
    return this;
  }

  /// Nesneyi Z ekseninde döndürür (Radyan cinsinden)
  Mesh3D rotateZ(double angleRadians) {
    transform.rotateZ(angleRadians);
    return this;
  }
  
  /// Nesneyi büyütüp küçültür
  Mesh3D scale(double factor) {
    transform.scale(factor);
    return this;
  }
}