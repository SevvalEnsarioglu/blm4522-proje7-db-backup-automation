-- =========================================================
-- PROJE 7: VERİTABANI YEDEKLEME VE OTOMASYON ÇALIŞMASI
-- DB: PostgreSQL - Northwind
-- Dosya: 06_test_demo.sql
-- Açıklama: Test sorguları ve demo verisi
-- =========================================================


-- =========================================================
-- 10. TEST SENARYOLARI
-- Başarılı ve başarısız backup kaydı oluşturur.
-- =========================================================

SELECT backup_automation.log_successful_backup(
    'northwind',
    'FULL',
    '/Users/Shared/backups/northwind_full_backup.sql',
    12.50
);

SELECT backup_automation.log_failed_backup(
    'northwind',
    'FULL',
    '/Users/Shared/backups/northwind_failed_backup.sql',
    'Backup klasörüne erişim izni bulunamadı.'
);


-- =========================================================
-- 11. RAPOR SORGULARI
-- Videoda ve raporda gösterebilirsin.
-- =========================================================

SELECT * FROM backup_automation.v_backup_report;

SELECT * FROM backup_automation.v_daily_backup_summary;

SELECT * FROM backup_automation.v_open_backup_alerts;

SELECT * FROM backup_automation.backup_audit;


-- =========================================================
-- 12. UYARIYI ÇÖZÜLDÜ OLARAK İŞARETLEME
-- Açık alert kayıtlarını kapatmak için.
-- =========================================================

UPDATE backup_automation.backup_alerts
SET 
    is_resolved = TRUE,
    resolved_time = CURRENT_TIMESTAMP
WHERE alert_id = 1;
