# bioinfo-workshop

Bu depo, uygulamalı biyoenformatik atölyesinin üç günlük çalışma ortamıdır.
Atölye boyunca bu deponun kendi kopyanızda çalışacaksınız.
Kopyanız GitHub hesabınızda durur ve sizindir.

Çalıştığınız bilgisayara **codespace** denir.
Codespace, GitHub'ın size ücretsiz olarak ödünç verdiği bir bilgisayardır.
İçinde, ön hazırlık modülünden tanıdığınız RStudio çalışır.
Paneller aynıdır: Console, Terminal, Files, Environment, Plots.

Destek için: nedim.kurt@outlook.com

## Ön kontrol: atölyeden bir hafta önce (yaklaşık 15 dakika)

Bu adımları atölyeden bir hafta önce, bir kez yapınız.
Bir sorun varsa böylece bir hafta önceden ortaya çıkar.

1. **Kotanızı okuyunuz.**
   github.com/settings/billing sayfasını açınız.
   "Current included usage" kutusundaki "More details" bağlantısına tıklayınız.
   "120 included Codespaces core hours" ve "15 GB included Codespaces storage" satırlarını görmelisiniz.
   Sonra soldaki menüden "Budgets and alerts" sayfasını açınız.
   "Codespaces" satırında "Stop usage: Yes" ve "$0 budget" yazmalıdır.
   Bu ayar, hiçbir zaman ücret çıkmaması demektir.
   Bu satır yoksa veya "No" yazıyorsa, devam etmeden önce destek adresine yazınız.

2. **Boşta kalma süresini ayarlayınız.**
   github.com/settings/codespaces sayfasını açınız.
   "Default idle timeout" kutusuna `120` yazınız ve Save düğmesine basınız.
   Bu adımı 3. ve 4. adımlardan önce yapınız.
   Ayar, yalnızca bundan sonra oluşturulan codespace'lere uygulanır.

3. **Kendi deponuzu oluşturunuz.**
   github.com/onedimkurt/bioinfo-workshop sayfasını açınız.
   "Use this template" düğmesine, sonra "Create a new repository" seçeneğine tıklayınız.
   "Open in a codespace" seçeneğini seçmeyiniz; o yol, bir depoya bağlı olmayan bir codespace açar.
   Owner olarak kendi kullanıcı adınızı seçiniz.
   Repository name kutusuna `bioinfo-workshop` yazınız.
   "Public" seçili kalsın; 3. günkü sertifika sayfası bunu gerektirir.
   "Create repository" düğmesine basınız.

4. **Codespace oluşturunuz.**
   Yeni deponuzun sayfasında "Code" düğmesine tıklayınız.
   Açılan kutuda "Codespaces" sekmesini, sonra "Create codespace on main" düğmesini seçiniz.
   İlk açılış birkaç dakika sürer.
   Önce koyu renkli bir düzenleyici (VS Code) açılır. Onu kullanmayacaksınız.
   VS Code "Do you trust the authors of the files in this folder?" diye sorarsa
   "Trust Folder & Continue" düğmesine tıklayınız. RStudio bu onaydan sonra başlar.

5. **RStudio'yu açınız.**
   Bir iki dakika içinde tarayıcınızda RStudio ile yeni bir sekme açılır.
   Bu sırada VS Code sekmesini önde, açık tutunuz; RStudio'yu o sekme başlatır.
   RStudio açıldıktan sonra da VS Code sekmesini kapatmayınız; arka planda açık kalsın.
   GitHub, yalnızca bu sekmedeki etkinliği sayar; sekme açıkken RStudio'da çalıştığınız her dakika da sayılır.
   Açılmazsa VS Code penceresinin altındaki "PORTS" sekmesine tıklayınız.
   "RStudio" satırındaki küre simgesine tıklayınız.
   <!-- VERIFY: pilot, sekme kendiliğinden açılıyor mu, açılmıyorsa PORTS yolu -->

6. **Kontrolü çalıştırınız.**
   RStudio'da Terminal sekmesine tıklayınız.
   Şu komutu yazınız ve Enter tuşuna basınız:

   ```bash
   bash check/preflight.sh
   ```

   Son satırda `RESULT: PASS` görmelisiniz.
   FAIL görürseniz, altındaki "Düzeltme:" satırını okuyunuz.

7. **Codespace'i durdurunuz, sonra siliniz.**
   github.com/codespaces sayfasını açınız.
   Codespace satırının sağındaki üç noktaya tıklayınız ve "Stop codespace" seçiniz.
   Satırdaki "Active" yazısı kaybolur; yerine "Last used" ile başlayan bir yazı gelir.
   Sonra yine üç noktaya tıklayınız ve "Delete" seçiniz.
   Deponuz silinmez. Atölyenin ilk sabahı aynı depodan yeni bir codespace oluşturacaksınız.

## Atölye günlerinde

**Başlarken.**
İlk gün codespace'i 4. adımdaki gibi deponuzdan oluşturunuz.
Sonraki sabahlar github.com/codespaces sayfasında codespace'inizin adına tıklayınız.
Gün boyunca iki sekme açık kalır: RStudio sekmesi ve arka planda VS Code sekmesi.

**Sabahları RStudio bir uyarı gösterebilir.**
"The previous R session was abnormally terminated" yazan bir pencere çıkarsa OK düğmesine tıklayınız.
Bu uyarı, codespace akşam durdurulduğu için çıkar; bir sorun değildir.
Kaydettiğiniz dosyalar ve conda ortamlarınız yerindedir; R belleğindeki nesneler silinmiştir.
Terminal dünkü ortamla açılabilir; etkin ortamın adı satırın başında yazar.

**Gün sonunda, her gün 17:30'da: durdurunuz.**
RStudio sekmesini veya VS Code sekmesini kapatmak codespace'i durdurmaz.
Durdurmanın iki yolu vardır:

- github.com/codespaces sayfasında üç noktaya tıklayınız ve "Stop codespace" seçiniz.
- VS Code penceresinin sol alt köşesindeki "Codespaces" yazısına tıklayınız ve "Stop Current Codespace" seçiniz.

Sonra github.com/codespaces sayfasına bakınız.
Satırda artık "Active" yazmamalıdır; "Last used" ile başlayan bir yazı görmelisiniz.
Durma işlemi birkaç dakika sürebilir.
Unutulan bir codespace 120 dakika sonra kendiliğinden durur, ama o süre kotanızdan düşer.

**Bir şey bozulursa.**
İki dakikada düzeltemediğiniz bir sorunda codespace'i siliniz ve deponuzdan yeniden oluşturunuz.
GitHub'a gönderdiğiniz (push) her şey yeni codespace'te yerindedir.
Göndermediğiniz değişiklikler kaybolur. Bu yüzden sık sık sürüm (commit) kaydedip gönderiniz.

## Bu depoda neler var

| Klasör | İçinde ne var |
|---|---|
| `check/` | Kurulum kontrolleri. Yalnızca ortamın hazır olup olmadığına bakar. |
| `envs/` | conda ortam (environment) dosyalarınız. Onları siz yazacaksınız. |
| `scripts/` | Kendi betikleriniz. Her gün satır satır siz yazacaksınız. |
| `data/` | Atölyede indireceğiniz veriler. git'e eklenmez. |
| `results/` | Çıktılarınız. git'e eklenmez. |
| `capstone/` | 3. günün bitirme çalışması. |
