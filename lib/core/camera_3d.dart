import 'package:vector_math/vector_math_64.dart';

class Camera3D {
  // Kameranın 3D uzaydaki konumu
  Vector3 position;
  
  // Kameranın baktığı merkez nokta
  Vector3 target;
  
  // Kameranın üst yönü (Genelde Y ekseni +1'dir, yani dik durur)
  Vector3 up;

  // Görüş açısı (Radyan cinsinden). FOV ne kadar büyükse lens o kadar geniş açılı olur (Balık gözü gibi).
  double fovYRadians;
  
  // Ekranın en/boy oranı (Genişlik / Yükseklik)
  double aspectRatio;
  
  // Renderlanacak en yakın mesafe (Bunun altındaki cisimler çizilmez)
  double zNear;
  
  // Renderlanacak en uzak mesafe (Görüş mesafesi sınırı)
  double zFar;

  Camera3D({
    Vector3? position,
    Vector3? target,
    Vector3? up,
    double fovDegrees = 60.0,
    this.aspectRatio = 16 / 9, 
    this.zNear = 0.1,
    this.zFar = 1000.0,
  })  : position = position ?? Vector3(0.0, 0.0, 10.0), // Kamerayı Z ekseninde 10 birim geriye koy
        target = target ?? Vector3(0.0, 0.0, 0.0),    // Merkeze (0,0,0) bak
        up = up ?? Vector3(0.0, 1.0, 0.0),            // Y ekseni yukarı
        fovYRadians = radians(fovDegrees);

  /// 1. View Matrix (LookAt)
  /// Kameranın pozisyonuna ve baktığı yöne göre dünyayı hizalar.
  Matrix4 getViewMatrix() {
    return makeViewMatrix(position, target, up);
  }

  /// 2. Projection Matrix (Perspektif)
  /// Derinlik algısını oluşturur. Uzaktaki nesneleri küçültür.
  Matrix4 getProjectionMatrix() {
    return makePerspectiveMatrix(fovYRadians, aspectRatio, zNear, zFar);
  }

  /// Ekran boyutu (veya cihazın yatay/dikey dönmesi) değiştiğinde oranı günceller.
  void updateAspectRatio(double width, double height) {
    if (height > 0) {
      aspectRatio = width / height;
    }
  }

  /// [İleri Seviye] Verilen bir 3D dünya noktasını, kameranın açısına göre
  /// işleyip (-1 ile +1 arasında) Clip Space (Ekran Uzayı) koordinatına çevirir.
  /// 3. Adım olan Render Pipeline'da bu metodu CustomPainter'a veri yollamak için kullanacağız.
  Vector4 projectToClipSpace(Vector3 worldPosition) {
    // Önce noktayı Vector4'e çeviririz (w = 1.0 homojen koordinat)
    Vector4 clipSpacePos = Vector4(worldPosition.x, worldPosition.y, worldPosition.z, 1.0);

    // View matrisi ile çarpıp kameranın önüne getir
    clipSpacePos = getViewMatrix().transform(clipSpacePos);
    
    // Projection matrisi ile çarpıp 2D düzleme izdüşümünü al
    clipSpacePos = getProjectionMatrix().transform(clipSpacePos);

    return clipSpacePos;
  }
}