import 'package:flutter/material.dart';
import '../core/mesh_3d.dart';
import 'chunk.dart';
import 'object_pool.dart';
import 'poolable_box.dart';

class WorldManager {
  // 200 kapasiteli nesne havuzu
  late final ObjectPool<PoolableBox> boxPool;
  
  // O an bellekte olan aktif bölgeler
  final Map<String, Chunk> _activeChunks = {};
  
  final double chunkSize = 20.0;
  
  // Kameranın etrafındaki 3x3'lük alan aktif olur
  final int viewDistance = 1; 

  WorldManager() {
    boxPool = ObjectPool<PoolableBox>(
      () => PoolableBox(width: 2.0, height: 2.0, depth: 2.0, color: Colors.greenAccent), 
      200
    );
  }

  // Kameranın pozisyonuna göre Chunk'ları dinamik olarak yükler ve siler
  void update(double cameraX, double cameraZ) {
    int playerChunkX = (cameraX / chunkSize).floor();
    int playerChunkZ = (cameraZ / chunkSize).floor();

    List<String> currentVisibleKeys = [];

    // Görüş mesafesindeki Chunk'ları bul
    for (int x = -viewDistance; x <= viewDistance; x++) {
      for (int z = -viewDistance; z <= viewDistance; z++) {
        int cx = playerChunkX + x;
        int cz = playerChunkZ + z;
        String key = "$cx,$cz";
        currentVisibleKeys.add(key);

        // Eğer Chunk henüz oluşturulmadıysa oluştur ve nesneleri diz
        if (!_activeChunks.containsKey(key)) {
          var newChunk = Chunk(cx, cz, chunkSize: chunkSize);
          newChunk.load(boxPool);
          _activeChunks[key] = newChunk;
        }
      }
    }

    // Görüş alanından çıkan eski Chunk'ları temizle
    _activeChunks.removeWhere((key, chunk) {
      if (!currentVisibleKeys.contains(key)) {
        chunk.unload(boxPool); // İçindeki objeleri havuza geri ver
        return true; // Hafızadan (Map'ten) sil
      }
      return false;
    });
  }

  // Sadece aktif olan nesneleri çizim motoruna yollamak için toplar
  List<Mesh3D> getVisibleMeshes() {
    List<Mesh3D> visibleMeshes = [];
    for (var chunk in _activeChunks.values) {
      visibleMeshes.addAll(chunk.activeObjects);
    }
    return visibleMeshes;
  }
}