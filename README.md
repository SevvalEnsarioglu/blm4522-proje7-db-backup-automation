# BLM4522 — Proje 7: Veritabanı Yedekleme ve Otomasyon

> 22290742 - ŞEVVAL ENSARİOĞLU  
> **Video Linki:** *(eklenecek)*

---

## Proje Hakkında

Bu projede Northwind PostgreSQL veritabanı üzerinde otomatik yedekleme altyapısı kurulmuş, yedekleme loglama süreçleri otomatikleştirilmiş ve uyarı/audit sistemleri entegre edilmiştir. Proje kapsamında aşağıdaki konular ele alınmaktadır:

- Yedekleme altyapısı: şema, log, denetim (audit) ve uyarı (alert) tabloları
- Başarılı ve başarısız yedekleme durumlarını otomatik loglayan ve uyarı üreten fonksiyonlar
- `pg_cron` veya benzeri araçlarla zamanlanmış iş (job) tanımlama örnekleri
- Yedekleme geçmişi ve hatalar için kapsamlı raporlama (View'lar)
- pg_dump tabanlı gerçek yedekleme komutları

---

## Kullanılan Araçlar

| Araç | Sürüm | Açıklama |
|------|-------|----------|
| PostgreSQL | 17 | Ana veritabanı sistemi |
| DBeaver | 25.2.4 | Veritabanı yönetim arayüzü |
| pg_cron | — | PostgreSQL iş zamanlayıcısı |
| Northwind DB | — | Örnek veritabanı |

---

## Proje Yapısı

```
blm4522-proje7-db-backup-automation/
│
├── README.md
├── script.sql                  ← Ana birleşik script dosyası
├── rapor/
│   └── rapor.pdf
├── sql/
│   ├── 01_altyapi.sql          ← Şema ve Tablolar (log, audit, alerts)
│   ├── 02_fonksiyonlar.sql     ← Başarılı/Başarısız loglama fonksiyonları
│   ├── 03_yedekleme.sql        ← Gerçek yedekleme komut referansları
│   ├── 04_raporlama.sql        ← Raporlama View'ları (detay, özet, alert)
│   ├── 05_pgagent_jobs.sql     ← pg_cron zamanlanmış iş örnekleri
│   └── 06_test_demo.sql        ← Test senaryoları ve demo veri girişleri
└── ekran_goruntuleri/
    ├── adim-1.png
    ├── adim-2.png
    └── ...
```

---

## Yapılan Çalışmalar

### 1. Yedekleme Altyapısı (`01_altyapi.sql`)

`backup_automation` adlı ayrı bir şema altında yedekleme süreçlerini yönetmek için üç adet tablo oluşturulmuştur:

| Tablo | Amaç |
|-------|------|
| `backup_automation.backup_log` | Yedekleme işlemlerinin genel durumunu ve sürelerini tutar. |
| `backup_automation.backup_audit` | Yedekleme adımlarının denetim kayıtlarını kaydeder. |
| `backup_automation.backup_alerts` | Başarısız yedeklemeler için üretilen uyarıları tutar. |

### 2. Loglama ve Uyarı Fonksiyonları (`02_fonksiyonlar.sql`)

Yedekleme durumlarını sisteme kaydetmek için iki adet PL/pgSQL fonksiyonu yazılmıştır:

- `log_successful_backup`: Başarılı yedeklemeleri loglar ve audit tablosuna kayıt atar.
- `log_failed_backup`: Başarısız yedeklemeleri loglar, audit tablosuna yazar ve `backup_alerts` tablosunda uyarı kaydı oluşturur.

### 3. Gerçek Yedekleme İşlemleri (`03_yedekleme.sql`)

PostgreSQL veritabanının fiziksel/mantıksal yedeklerini almak için kullanılan terminal komutları ve örnek çağrılar listelenmiştir.

- **FULL (Tam) Yedek:**
  ```bash
  pg_dump -U postgres -d northwind -F p -f /Users/Shared/backups/northwind_full_backup.sql
  ```

### 4. Raporlama Görünümleri (`04_raporlama.sql`)

Yedekleme geçmişinin analiz edilebilmesi için 3 adet View hazırlanmıştır:

| View | Açıklama |
|------|----------|
| `v_backup_report` | Tüm yedeklerin durumu ve sürelerini detaylı listeler. |
| `v_daily_backup_summary` | Günlük bazda başarılı/başarısız yedek sayılarını ve ortalama süreleri gösterir. |
| `v_open_backup_alerts` | Henüz çözülmemiş (is_resolved = false) hataları listeler. |

### 5. Zamanlanmış İşler (`05_pgagent_jobs.sql`)

PostgreSQL üzerinde zamanlanmış işlerin otomatik çalıştırılabilmesi için `pg_cron` eklentisi kullanılarak yazılmış örnek zamanlama tanımları içerir:

```sql
-- Her gün saat 02:00'de backup log kaydı oluşturan örnek job:
SELECT cron.schedule(
    'daily_northwind_backup_log',
    '0 2 * * *',
    $$
    SELECT backup_automation.log_successful_backup(
        'northwind',
        'FULL',
        '/Users/Shared/backups/northwind_auto_backup_' || TO_CHAR(CURRENT_DATE, 'YYYY_MM_DD') || '.sql',
        12.50
    );
    $$
);
```

### 6. Test ve Doğrulama (`06_test_demo.sql`)

Sistemin çalıştığını doğrulamak amacıyla başarılı/başarısız örnek kayıtlar eklenmekte, rapor görünümleri sorgulanmakta ve uyarıların çözüldü durumuna getirilmesi test edilmektedir.
