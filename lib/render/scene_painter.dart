import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as math;
import 'dart:math' as dart_math;

import '../core/camera_3d.dart';
import '../core/mesh_3d.dart';
import 'render_face.dart';

class ScenePainter extends CustomPainter {
  final Camera3D camera;
  final List<Mesh3D> meshes;
  final math.Vector3 lightDirection;
  final Color fogColor;
  final bool enableFog;

  ScenePainter({
    required this.camera,
    required this.meshes,
    math.Vector3? lightDir,
    required this.fogColor,
    this.enableFog = true,
  }) : lightDirection = (lightDir ?? math.Vector3(0.0, 0.0, -1.0))..normalize();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    camera.updateAspectRatio(size.width, size.height);
    math.Matrix4 viewMatrix = camera.getViewMatrix();
    math.Matrix4 projMatrix = camera.getProjectionMatrix();

    List<RenderFace> facesToDraw = [];

    for (var mesh in meshes) {
      math.Matrix4 modelMatrix = mesh.transform;
      math.Matrix4 mvpMatrix = projMatrix * viewMatrix * modelMatrix;

      for (int i = 0; i < mesh.indices.length; i += 3) {
        int i0 = mesh.indices[i];
        int i1 = mesh.indices[i + 1];
        int i2 = mesh.indices[i + 2];

        math.Vector3 v0World = mesh.vertices[i0];
        math.Vector3 v1World = mesh.vertices[i1];
        math.Vector3 v2World = mesh.vertices[i2];

        // 1. Işıklandırma (Flat Shading)
        math.Vector3 worldV0 = modelMatrix.transform3(v0World.clone());
        math.Vector3 worldV1 = modelMatrix.transform3(v1World.clone());
        math.Vector3 worldV2 = modelMatrix.transform3(v2World.clone());

        math.Vector3 edge1 = worldV1 - worldV0;
        math.Vector3 edge2 = worldV2 - worldV0;
        math.Vector3 normal = edge1.cross(edge2)..normalize();

        double lightIntensity = dart_math.max(0.25, normal.dot(lightDirection));
        
        Color faceColor = Color.fromRGBO(
          (mesh.color.red * lightIntensity).round().clamp(0, 255),
          (mesh.color.green * lightIntensity).round().clamp(0, 255),
          (mesh.color.blue * lightIntensity).round().clamp(0, 255),
          1.0,
        );

        // 2. Klip Uzayına Dönüşüm
        math.Vector4 v0Clip = mvpMatrix.transform(math.Vector4(v0World.x, v0World.y, v0World.z, 1.0));
        math.Vector4 v1Clip = mvpMatrix.transform(math.Vector4(v1World.x, v1World.y, v1World.z, 1.0));
        math.Vector4 v2Clip = mvpMatrix.transform(math.Vector4(v2World.x, v2World.y, v2World.z, 1.0));

        // 3. PROFESYONEL ÇÖZÜM: YAKIN DÜZLEM KIRPMASI (Sutherland-Hodgman Algoritması)
        // Eğer zemin ayaklarımızın altına girerse silme, üçgeni tam kameranın önünden kes!
        List<List<math.Vector4>> clippedTriangles = _clipTriangleAgainstNearPlane(v0Clip, v1Clip, v2Clip);

        // 4. Kırpılmış üçgenleri ekrana yansıt
        for (var tri in clippedTriangles) {
          math.Vector4 c0 = tri[0];
          math.Vector4 c1 = tri[1];
          math.Vector4 c2 = tri[2];

          // Perspektif bölme
          math.Vector3 ndc0 = math.Vector3(c0.x / c0.w, c0.y / c0.w, c0.z / c0.w);
          math.Vector3 ndc1 = math.Vector3(c1.x / c1.w, c1.y / c1.w, c1.z / c1.w);
          math.Vector3 ndc2 = math.Vector3(c2.x / c2.w, c2.y / c2.w, c2.z / c2.w);

          math.Vector3 screen0 = _ndcToScreen(ndc0, size);
          math.Vector3 screen1 = _ndcToScreen(ndc1, size);
          math.Vector3 screen2 = _ndcToScreen(ndc2, size);

          // W değeri kameraya olan derinlik uzaklığıdır.
          double zDepth = (c0.w + c1.w + c2.w) / 3.0;

          // 5. PROFESYONEL ÇÖZÜM: SİS (FOG) EFEKTİ
          Color finalColor = faceColor;
          if (enableFog) {
            double fogNear = 20.0;  // Sis 20 birim uzakta başlar
            double fogFar = 70.0;   // 70 birimde her şey tamamen gökyüzüne karışır
            double fogFactor = (zDepth - fogNear) / (fogFar - fogNear);
            fogFactor = fogFactor.clamp(0.0, 1.0);
            
            // Yüzey rengini, uzaklığa göre gökyüzü rengine (fogColor) karıştır
            finalColor = Color.lerp(faceColor, fogColor, fogFactor)!;
          }

          facesToDraw.add(RenderFace(
            v0: screen0,
            v1: screen1,
            v2: screen2,
            zDepth: zDepth,
            color: finalColor,
          ));
        }
      }
    }

    // Üçgenleri uzaktan yakına doğru çiz (Painter's Algorithm)
    facesToDraw.sort((a, b) => b.zDepth.compareTo(a.zDepth));

    if (facesToDraw.isEmpty) return;

    Float32List positions = Float32List(facesToDraw.length * 6);
    Int32List colors = Int32List(facesToDraw.length * 3);
    Uint16List indices = Uint16List(facesToDraw.length * 3);

    int posIndex = 0;
    int colorIndex = 0;
    int indIndex = 0;
    int vertexCount = 0;

    for (var face in facesToDraw) {
      positions[posIndex++] = face.v0.x;
      positions[posIndex++] = face.v0.y;
      colors[colorIndex++] = face.color.value;
      indices[indIndex++] = vertexCount++;

      positions[posIndex++] = face.v1.x;
      positions[posIndex++] = face.v1.y;
      colors[colorIndex++] = face.color.value;
      indices[indIndex++] = vertexCount++;

      positions[posIndex++] = face.v2.x;
      positions[posIndex++] = face.v2.y;
      colors[colorIndex++] = face.color.value;
      indices[indIndex++] = vertexCount++;
    }

    ui.Vertices vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      positions,
      indices: indices,
      colors: colors,
    );

    Paint paint = Paint()..style = PaintingStyle.fill;
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
  }

  // YAKIN DÜZLEM (NEAR PLANE) KESİŞİM MATEMATİĞİ
  List<List<math.Vector4>> _clipTriangleAgainstNearPlane(math.Vector4 v0, math.Vector4 v1, math.Vector4 v2) {
    double nearPlane = 0.1; // Kameraya 0.1 birimden daha yakın olan noktaları kes
    double d0 = v0.w - nearPlane;
    double d1 = v1.w - nearPlane;
    double d2 = v2.w - nearPlane;

    int insideCount = 0;
    if (d0 >= 0) insideCount++;
    if (d1 >= 0) insideCount++;
    if (d2 >= 0) insideCount++;

    // Üçgen tamamen kameranın önünde
    if (insideCount == 3) return [[v0, v1, v2]];
    
    // Üçgen tamamen kameranın arkasında
    if (insideCount == 0) return [];

    // Yeni köşeleri oluşturmak için interpolasyon
    math.Vector4 intersect(math.Vector4 p1, math.Vector4 p2, double dist1, double dist2) {
      double t = dist1 / (dist1 - dist2);
      return math.Vector4(
        p1.x + t * (p2.x - p1.x),
        p1.y + t * (p2.y - p1.y),
        p1.z + t * (p2.z - p1.z),
        p1.w + t * (p2.w - p1.w),
      );
    }

    List<math.Vector4> inside = [];
    List<math.Vector4> outside = [];
    List<double> inD = [];
    List<double> outD = [];

    void categorize(math.Vector4 v, double d) {
      if (d >= 0) { inside.add(v); inD.add(d); }
      else { outside.add(v); outD.add(d); }
    }

    categorize(v0, d0);
    categorize(v1, d1);
    categorize(v2, d2);

    if (insideCount == 1) {
      // 1 nokta içeride, 2 nokta dışarıda: Yeni ve daha küçük 1 üçgen oluşur
      math.Vector4 newV1 = intersect(inside[0], outside[0], inD[0], outD[0]);
      math.Vector4 newV2 = intersect(inside[0], outside[1], inD[0], outD[1]);
      return [[inside[0], newV1, newV2]];
    } else {
      // 2 nokta içeride, 1 nokta dışarıda: Dörtgen oluşur, bunu 2 yeni üçgene bölüyoruz
      math.Vector4 newV1 = intersect(inside[0], outside[0], inD[0], outD[0]);
      math.Vector4 newV2 = intersect(inside[1], outside[0], inD[1], outD[0]);
      return [
        [inside[0], inside[1], newV1],
        [inside[1], newV2, newV1]
      ];
    }
  }

  math.Vector3 _ndcToScreen(math.Vector3 ndc, Size size) {
    return math.Vector3(
      (ndc.x + 1.0) * 0.5 * size.width,
      (1.0 - ndc.y) * 0.5 * size.height,
      ndc.z,
    );
  }

  @override
  bool shouldRepaint(covariant ScenePainter oldDelegate) => true;
}