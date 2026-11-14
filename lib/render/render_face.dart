import 'dart:ui' as ui;
import 'package:vector_math/vector_math_64.dart' as math;

/// Ekrana çizilecek olan tek bir üçgen yüzeyi temsil eder.
/// Bu sınıf sayesinde yüzeyleri derinliğe (Z eksenine) göre sıralayabileceğiz.
class RenderFace {
  // Üçgenin ekran uzayındaki 3 köşesi
  final math.Vector3 v0;
  final math.Vector3 v1;
  final math.Vector3 v2;
  
  // Üçgenin kameraya olan ortalama uzaklığı
  final double zDepth;
  
  // Işıklandırma hesaplanmış son renk
  final ui.Color color;

  RenderFace({
    required this.v0,
    required this.v1,
    required this.v2,
    required this.zDepth,
    required this.color,
  });
}