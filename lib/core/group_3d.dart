import 'mesh_3d.dart';
import 'package:vector_math/vector_math_64.dart' as math;

/// Birden fazla 3D nesneyi gruplayıp tek bir merkezden hareket ettirmeyi sağlar
class Group3D {
  final List<Mesh3D> children;
  
  // Grubun ana konumu
  math.Matrix4 transform = math.Matrix4.identity();

  Group3D({required this.children});

  Group3D translate({double x = 0, double y = 0, double z = 0}) {
    transform.translate(x, y, z);
    
    for (var child in children) {
      math.Vector4 pos = child.transform.getColumn(3);
      pos.x += x;
      pos.y += y;
      pos.z += z;
      child.transform.setColumn(3, pos);
    }
    
    return this;
  }

  // KİMİ'NİN EKLEMEK İSTEDİĞİ ANİMASYON METOTLARI
  Group3D rotateX(double angleRadians) {
    transform.rotateX(angleRadians);
    for (var child in children) {
      child.rotateX(angleRadians);
    }
    return this;
  }

  Group3D rotateY(double angleRadians) {
    transform.rotateY(angleRadians);
    for (var child in children) {
      child.rotateY(angleRadians);
    }
    return this;
  }

  Group3D rotateZ(double angleRadians) {
    transform.rotateZ(angleRadians);
    for (var child in children) {
      child.rotateZ(angleRadians);
    }
    return this;
  }
  
  List<Mesh3D> getRenderableMeshes() {
    return children;
  }
}