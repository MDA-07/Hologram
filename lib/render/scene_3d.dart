import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as math;
import '../core/camera_3d.dart';
import '../core/mesh_3d.dart';
import 'scene_painter.dart';

class Scene3D extends StatelessWidget {
  final Camera3D camera;
  final List<Mesh3D> meshes;
  final math.Vector3? lightDirection;
  final Color backgroundColor;
  final bool enableFog;

  const Scene3D({
    super.key,
    required this.camera,
    required this.meshes,
    this.lightDirection,
    this.backgroundColor = Colors.black,
    this.enableFog = true, // Sis efekti varsayılan olarak açık
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor, // Arkada hileli gradient yok, sadece saf gökyüzü rengi
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: ScenePainter(
          camera: camera,
          meshes: meshes,
          lightDir: lightDirection,
          fogColor: backgroundColor, // Ufuktaki sis gökyüzü rengine bürünecek
          enableFog: enableFog,
        ),
      ),
    );
  }
}