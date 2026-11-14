import 'package:vector_math/vector_math_64.dart' as math;
import 'object_pool.dart';
import 'poolable_box.dart';

class Chunk {
  final int gridX;
  final int gridZ;
  final double chunkSize;

  // Bu bölgedeki (Chunk) aktif objelerin referansları
  final List<PoolableBox> activeObjects = [];

  Chunk(this.gridX, this.gridZ, {this.chunkSize = 20.0});

  // Bölge yüklendiğinde havuzdan nesne çek ve koordinatlarını ayarla
  void load(ObjectPool<PoolableBox> pool) {
    int objCount = 4; // Örnek: Her bölgede 4 obje olsun
    
    for (int i = 0; i < objCount; i++) {
      var box = pool.getObject();
      
      // Nesnenin 3D dünyadaki gerçek koordinatını hesapla
      double posX = (gridX * chunkSize) + (i * 4.0) - (chunkSize / 2);
      double posZ = (gridZ * chunkSize) + (i * 4.0) - (chunkSize / 2);
      
      box.transform = math.Matrix4.identity()..translate(posX, 0.0, posZ);
      activeObjects.add(box);
    }
  }

  // Bölge kameradan uzaklaştığında nesneleri havuza geri gönder
  void unload(ObjectPool<PoolableBox> pool) {
    for (var obj in activeObjects) {
      pool.release(obj);
    }
    activeObjects.clear();
  }
}