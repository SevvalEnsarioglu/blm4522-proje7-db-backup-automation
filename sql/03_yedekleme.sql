-- GERÇEK BACKUP KOMUTU
-- Bu komut SQL içinde değil, terminalde çalıştırılır.

-- macOS Terminal için örnek:
-- pg_dump -U postgres -d northwind -F p -f /Users/Shared/backups/northwind_full_backup.sql

-- =========================================================
-- BACKUP TÜRÜ AÇIKLAMALARI
-- =========================================================

-- FULL  → Tüm veritabanı (şema + veri)
-- pg_dump -U postgres -d northwind -F p \
--         -f /Users/Shared/backups/northwind_full_backup.sql

-- SCHEMA → Sadece tablo yapıları
-- pg_dump -U postgres -d northwind --schema-only -F p \ -f /Users/Shared/backups/northwind_schema_backup.sql

-- TABLE → Belirli bir tablo
-- pg_dump -U postgres -d northwind -t orders -F p \  -f /Users/Shared/backups/northwind_orders_backup.sql


-- YEDEK ALMA SONRASI LOG KAYDI
-- Terminalde pg_dump başarıyla bitince bu fonksiyon çağrılır.

-- FULL yedek başarılı:
SELECT backup_automation.log_successful_backup(
    'northwind',
    'FULL',
    '/Users/Shared/backups/northwind_full_backup.sql',
    12.50
);

-- SCHEMA yedeği başarılı:
SELECT backup_automation.log_successful_backup(
    'northwind',
    'SCHEMA',
    '/Users/Shared/backups/northwind_schema_backup.sql',
    2.10
);
