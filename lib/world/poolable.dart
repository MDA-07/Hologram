/// Bir nesnenin bellek havuzunda (Object Pool) yönetilebilmesi için gereken şablon
abstract class Poolable {
  // Nesne şu an sahnede aktif mi, yoksa havuzda bekliyor mu?
  bool isActive = false;
  
  // Nesne havuza döndüğünde üzerindeki değişiklikleri (pozisyon, rotasyon) sıfırlamak için
  void reset();
}