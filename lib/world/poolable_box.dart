import 'package:flutter/material.dart';
import '../geometry/box_geometry.dart';
import 'poolable.dart';

/// Havuz sistemiyle çalışabilen, kendini sıfırlayabilen 3D Küp nesnesi
class PoolableBox extends BoxGeometry implements Poolable {
  @override
  bool isActive = false;

  PoolableBox({
    double width = 1.0,
    double height = 1.0,
    double depth = 1.0,
    Color color = Colors.blue,
  }) : super(width: width, height: height, depth: depth, color: color);

  @override
  void reset() {
    // Nesne havuza geri döndüğünde, 3D uzaydaki konumunu sıfırla
    transform.setIdentity();
  }
}