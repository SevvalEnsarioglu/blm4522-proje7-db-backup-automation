-- 7. BACKUP RAPOR VIEW
-- Backup durumlarını raporlamak için kullanılır.

CREATE OR REPLACE VIEW backup_automation.v_backup_report AS
SELECT
    bl.backup_id,
    bl.database_name,
    bl.backup_type,
    bl.backup_status,
    bl.backup_file_path,
    bl.backup_start_time,
    bl.backup_end_time,
    bl.duration_seconds,
    bl.backup_size_mb,
    bl.error_message,
    CASE
        WHEN bl.backup_status = 'SUCCESS' THEN 'Backup başarılı'
        WHEN bl.backup_status = 'FAILED' THEN 'Backup başarısız'
        ELSE 'Backup başladı'
    END AS backup_result_description
FROM backup_automation.backup_log bl
ORDER BY bl.backup_start_time DESC;

-- 8. GÜNLÜK BACKUP ÖZET RAPOR VIEW
-- Hangi gün kaç başarılı/başarısız backup var gösterir.

CREATE OR REPLACE VIEW backup_automation.v_daily_backup_summary AS
SELECT
    DATE(backup_start_time) AS backup_date,
    COUNT(*) AS total_backup_count,
    COUNT(*) FILTER (WHERE backup_status = 'SUCCESS') AS successful_backup_count,
    COUNT(*) FILTER (WHERE backup_status = 'FAILED') AS failed_backup_count,
    ROUND(AVG(duration_seconds), 2) AS average_duration_seconds
FROM backup_automation.backup_log
GROUP BY DATE(backup_start_time)
ORDER BY backup_date DESC;

-- 9. AÇIK UYARI RAPOR VIEW
-- Çözülmemiş backup hatalarını gösterir.

CREATE OR REPLACE VIEW backup_automation.v_open_backup_alerts AS
SELECT
    ba.alert_id,
    ba.backup_id,
    bl.database_name,
    bl.backup_type,
    ba.alert_message,
    ba.alert_time,
    ba.is_resolved
FROM backup_automation.backup_alerts ba
JOIN backup_automation.backup_log bl
    ON ba.backup_id = bl.backup_id
WHERE ba.is_resolved = FALSE
ORDER BY ba.alert_time DESC;
