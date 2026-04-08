# Juicy Smash 2.0 - Code Audit & Review Report

## 1. Mühendislik Kalitesi (Clean Code)

Projenin genel mimarisi, SwiftUI'ın güncel Observation (`@Observable`) yaklaşımını benimsemiş olması açısından olumlu bir temele sahip. Ancak, büyük ve sürdürülebilir ("production-ready") projeler açısından bazı kritik eksiklikler ve "anti-pattern"ler bulunmaktadır.

### 1.1. Bellek Yönetimi (Memory Management) ve Closure'lar
`OrchardOrchestrator.swift` içerisindeki asenkron görevlerde (Task blocks) ve DispatchQueue kullanımlarında bellek yönetimiyle ilgili riskler mevcuttur. Sınıf bir `class` (reference type) olduğu için, `Task` içerisinde `self` doğrudan kullanıldığında ("strong capture" yapılarak) "retain cycle" oluşturma potansiyeli yüksektir veya nesne yok edilmek istense bile asenkron görev bitene kadar bellekte tutulmaya devam eder.

**Bulgu:** `useBoosterOnTile` ve `attemptSwap` gibi metotlarda `Task { ... }` içinde doğrudan sınıf değişkenlerine (`score`, `comboMultiplier`, `nectarGrid` vb.) erişilmektedir. 
**Düzeltme Önerisi:** Asenkron bloklarda (özellikle animasyon gecikmelerinin `Task.sleep` ile yapıldığı uzun süren işlemlerde) `[weak self]` kullanımı şarttır. Swift 5.10+ ve modern concurrency'de Actor yalıtımı kullanılmıyorsa bu çok daha kritiktir.

```swift
// Doğrusu şu olmalı (OrchardOrchestrator.swift - attemptSwap örneği):
Task { [weak self] in
    guard let self = self else { return }
    
    await MainActor.run {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            self.swapInGrid(row1: tile1.row, col1: tile1.col, row2: tile2.row, col2: tile2.col)
        }
    }
    
    // ... işlemler
    
    try? await Task.sleep(nanoseconds: 300_000_000)
    
    await MainActor.run {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { 
            self.applyOrganicGravity() 
        }
    }
    
    // ... diğer işlemler
}
```
*Not: `OrchardOrchestrator` üzerindeki metotların tamamı `@MainActor` işaretli ancak `Task` içinde asenkron `Task.sleep` sonrasında UI güncellenirken (nectarGrid değişimi gibi) MainActor'e dönüldüğünden emin olunmalı ve `self` strong capture yapılmamalıdır.*

### 1.2. Monolitik Mimari Etkileri
(Not: `LevelMapView` ve diğer View'lerin `MainApp.swift` içerisine gömülü olması/planlanması durumuna istinaden:)
View katmanlarının (ör. `LevelMapView`, `ShopView`, `SettingsView`) tek bir `MainApp.swift` dosyasına gömülü (monolithic) şekilde yazılması, iOS geliştirme standartlarında (Clean Architecture, MVVM) kesinlikle önerilmez. 
- **Okunabilirlik ve Sürdürülebilirlik:** Dosya boyutunun binlerce satıra çıkması, code review süreçlerini ve merge conflict çözümlerini imkansızlaştırır.
- **Performans:** Devasa bir dosyanın SwiftUI compiler'ı tarafından derlenmesi çok uzun sürer (compile time overhead). 
- **Doğrusu:** Her bir View ve ViewModel mantıksal klasör yapısına (`Views/Map/`, `Views/Shop/`) ayrılarak kendi `.swift` dosyalarında tanımlanmalıdır.

### 1.3. Nesne Kimlikleri ve Hashable Optimizasyonu
`HarvestTile` modelinde Apple botlarına karşı bir önlem olarak UUID ve salt birleştirilerek ID oluşturulmuş:
`self.id = "\(baseID.uuidString)-\(salt.uuidString)"`
Bu yaklaşım, nesnelerin hash değerlerini çok benzersiz yapsa da string interpolasyonu her tile oluşturulduğunda gereksiz CPU yükü getirir (özellikle büyük bir board'da board sürekli yenilenirken). Daha basitçe doğrudan bir `UUID()` kullanılabilir.

---

## 2. Oyun Döngüsü ve Matematik (Game Loop & Economy)

### 2.1. OrchardOrchestrator ve ProgressionManager İlişkisi
İki yönetici arasındaki bağ genel olarak doğru kurulmuş; harcamalar (IAP mock) doğrudan `ProgressionManager.shared` üzerinden singleton olarak yönetiliyor. Ancak ekonomi oldukça "deflasyonist" bir yapıya sahip, oyuncu kısa sürede parasız kalabilir.

### 2.2. Ekonomi Analizi
- **Başlangıç:** Oyuncu 10 altın ile başlar (`ProgressionManager.swift`).
- **Kazanım:** Bir level bittiğinde taban 20 altın + kalan her hamle için 2 altın kazanır. Ortalama bir oyuncunun 5 hamle artırarak bölümü geçtiğini varsayarsak, bölüm başına **30 altın** kazanacaktır.
- **Harcama (Booster ve Ekstra Hamle):**
    - Çekiç (Hammer): 50 Altın
    - Karıştırma (Shuffle): 70 Altın
    - Mega Patlama: 100 Altın
    - 5 Ekstra Hamle: 50 Altın

**Bulgu:** Oyuncu bölüm başı ~30 altın kazanırken, oyunu kaybettiğinde "Keep playing?" seçeneğinde 5 hamle almak 50 altın. Oyuncu sadece 1 kere başarısız olduğunda 2 bölüm boyunca kazandığı tüm altını kaybedecektir. Bu dengesizlik, "ödüllendirici" (rewarding) olmaktan ziyade çok çabuk "oyundan soğutan" bir yapı oluşturur.
**Düzeltme Önerisi:** Başlangıç altını 100 veya 150 yapılmalı. Böylece oyuncu oyunun başlarında "Booster" deneme fırsatı bulur. Level bitiş altın ödülü `coinRewardForLevel` içerisindeki taban puan artırılabilir (örneğin `50 + (moves * 3)`). Altın kazanım ekonomisi çok kısıtlı.

---

## 3. UI/UX Tutarlılığı (Visual Integrity)

### 3.1. Görsel Dil (Visual Language)
Oyun, "Purple/Candy Gradient Background" yapısıyla çok modern ve canlı bir his veriyor. `HarvestGridView` içerisindeki butonlar (`JellyButton`), kapsül yapısındaki header tasarımları, altın ve skor UI'ları birbirine oldukça uyumlu. Renk paleti tutarlı.

### 3.2. Milimetrik Kaymalar ve Eksiklikler
- **Header Yerleşimleri:** `topHeader` içerisindeki Coin Indicator (Altın göstergesi) ile Back butonu arasında hizalama sorunları yaşanabilir. Altın barında "plus" butonu var, skor barında ise yok. Bu durum genişliklerin dinamik olmasına yol açıp merkezdeki "JUICY SMASH 2" yazısını cihazın ortasından hafifçe sağa veya sola kaydırabilir (ZStack ile tam ortalama sağlanmalı, HStack içi Spacer'lar tehlikelidir).
- **Animasyon Süreleri:** Patlama ve yer çekimi hızı (`.spring` ve `Task.sleep` süreleri) toplamda çok uzun (0.4 + 0.3 + 0.3 saniye). Akıcı bir maç 3 (Match-3) oyunu (ör. Candy Crush) çok daha "snappy" (hızlı ve duyarlı) olmalıdır. 

---

## 4. Global Standartlar (Production-Ready Durumu)

Oyun şu haliyle "Production-Ready" (Yayına Hazır) **değildir**. 

### 4.1. Lokalizasyon (Localization) Eksikliği
Tüm UI metinleri Swift dosyalarında hard-coded (sabit) olarak yazılmış. Örneğin: `"OUT OF MOVES!"`, `"TARGET"`, `"BUY 5 MOVES"`, `"Keep playing?"`. App Store'da "Featured" (Öne Çıkanlar) bölümüne girmek isteniyorsa çoklu dil desteği şarttır. 

**Çözüm:** Bir `Localizable.strings` (English) yapısı aşağıdaki gibi olmalıdır:
```text
/* General */
"APP_TITLE" = "JUICY SMASH 2";
"LEVEL_TITLE_FORMAT" = "LEVEL %d";

/* Game Board */
"TARGET_SCORE" = "TARGET";
"MOVES_LEFT" = "MOVES LEFT";

/* Out of Moves Sheet */
"OUT_OF_MOVES_TITLE" = "OUT OF MOVES!";
"OUT_OF_MOVES_SUBTITLE" = "Keep playing?";
"BUY_MOVES_BUTTON" = "BUY 5 MOVES";
"BUY_MOVES_COST_FORMAT" = "%d Coins";
"WATCH_AD_BUTTON" = "WATCH AD";
"WATCH_AD_SUBTITLE" = "Get 5 Moves Free";
"GIVE_UP_BUTTON" = "Give Up";

/* Alerts */
"MOVES_ADDED_TITLE" = "5 Moves Added! 🍬";
"MOVES_ADDED_MSG" = "Keep smashing!";
"NOT_ENOUGH_COINS_TITLE" = "Not Enough Coins 😔";
"NOT_ENOUGH_COINS_MSG" = "Watch an ad or give up.";
"OK_BUTTON" = "OK";

/* Level Clear Sheet */
"LEVEL_CLEAR_TITLE" = "LEVEL CLEAR!";
"SCORE_LABEL" = "SCORE";
"COINS_EARNED_LABEL" = "COINS EARNED";
"CONTINUE_BUTTON" = "CONTINUE";
```
*Tüm Swift dosyalarında `Text("OUT OF MOVES!")` yerine `Text(String(localized: "OUT_OF_MOVES_TITLE"))` kullanılmalıdır.*

### 4.2. Debug Logları ve Hata Yönetimi
`try? await Task.sleep` kullanımları hata fırlatıldığında sessizce başarısız oluyor (fail silently). Oyuncu oyunu alta aldığında (background'a gönderdiğinde) Task iptal (cancelled) olabilir ancak bu durum ele alınmıyor.

### Genel Sonuç:
"Öne Çıkanlar" kalitesi için Apple, olağanüstü akıcılık (60/120 FPS, takılmayan animasyonlar), memory sızıntısı olmayan bir mimari ve çoklu dil desteği bekler. Şu anki kod tabanı, muazzam bir prototip ancak production için 1.1'deki bellek yönetimi ve 4.1'deki lokalizasyon adımlarının mutlak suretle uygulanması gerekmektedir.
