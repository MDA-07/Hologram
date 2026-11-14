import 'poolable.dart';

class ObjectPool<T extends Poolable> {
  final List<T> _pool = [];
  
  // Yeni nesne üretmek gerektiğinde kullanılacak fonksiyon
  final T Function() _factory;

  // Oyun başlarken havuzu belirtilen kapasiteyle doldururuz
  ObjectPool(this._factory, int initialSize) {
    for (int i = 0; i < initialSize; i++) {
      _pool.add(_factory());
    }
  }

  // Sahneye yeni obje lazım olduğunda havuzdan çekeriz
  T getObject() {
    for (var item in _pool) {
      if (!item.isActive) {
        item.isActive = true;
        return item;
      }
    }
    
    // Eğer havuzdaki tüm objeler kullanımdaysa, mecburen yeni üretip havuza ekleriz
    var newItem = _factory();
    newItem.isActive = true;
    _pool.add(newItem);
    return newItem;
  }

  // Obje kameradan çıkınca silmeyip havuza iade ederiz
  void release(T item) {
    item.isActive = false;
    item.reset();
  }
}