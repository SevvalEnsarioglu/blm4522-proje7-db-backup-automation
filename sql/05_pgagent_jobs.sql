-- 13. PG_CRON OTOMASYON ÖRNEĞİ
-- NOT: pg_cron kurulmadan çalışmaz.
-- PostgreSQL'de SQL Server Agent alternatifi olarak kullanılır.

-- Extension kurulumu:
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Her gün saat 02:00'de backup log kaydı oluşturan örnek job:
-- SELECT cron.schedule(
--     'daily_northwind_backup_log',
--     '0 2 * * *',
--     $$
--     SELECT backup_automation.log_successful_backup(
--         'northwind',
--         'FULL',
--         '/Users/Shared/backups/northwind_auto_backup_' || TO_CHAR(CURRENT_DATE, 'YYYY_MM_DD') || '.sql',
--         12.50
--     );
--     $$
-- );

-- Her Pazar 03:00'de şema yedeği:
-- SELECT cron.schedule(
--     'weekly_northwind_schema_backup_log',
--     '0 3 * * 0',
--     $$
--     SELECT backup_automation.log_successful_backup(
--         'northwind',
--         'SCHEMA',
--         '/Users/Shared/backups/northwind_schema_' || TO_CHAR(CURRENT_DATE, 'YYYY_MM_DD') || '.sql',
--         2.10
--     );
--     $$
-- );

-- Job listesini görmek için:
-- SELECT * FROM cron.job;

-- Job silmek için:
-- SELECT cron.unschedule('daily_northwind_backup_log');
-- SELECT cron.unschedule('weekly_northwind_schema_backup_log');
