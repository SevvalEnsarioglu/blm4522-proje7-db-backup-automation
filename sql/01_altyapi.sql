-- 1. ŞEMA OLUŞTURMA
CREATE SCHEMA IF NOT EXISTS backup_automation;

-- 2. BACKUP LOG TABLOSU
-- Her backup işleminin durumunu kaydeder.

CREATE TABLE IF NOT EXISTS backup_automation.backup_log (
    backup_id SERIAL PRIMARY KEY,
    database_name VARCHAR(100) NOT NULL,
    backup_type VARCHAR(30) NOT NULL,
    backup_file_path TEXT NOT NULL,
    backup_status VARCHAR(20) NOT NULL CHECK (backup_status IN ('SUCCESS', 'FAILED', 'STARTED')),
    backup_start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    backup_end_time TIMESTAMP,
    duration_seconds NUMERIC(10,2),
    backup_size_mb NUMERIC(10,2),
    error_message TEXT
);

-- 3. BACKUP AUDIT TABLOSU
-- Backup işlemlerinin denetim kayıtlarını tutar.

CREATE TABLE IF NOT EXISTS backup_automation.backup_audit (
    audit_id SERIAL PRIMARY KEY,
    backup_id INT,
    action_type VARCHAR(50) NOT NULL,
    action_description TEXT,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    performed_by VARCHAR(100) DEFAULT CURRENT_USER,
    CONSTRAINT fk_backup_audit_log
        FOREIGN KEY (backup_id)
        REFERENCES backup_automation.backup_log(backup_id)
        ON DELETE SET NULL
);

-- 4. BACKUP ALERT TABLOSU
-- Başarısız backup işlemlerinde uyarı kaydı oluşturur.

CREATE TABLE IF NOT EXISTS backup_automation.backup_alerts (
    alert_id SERIAL PRIMARY KEY,
    backup_id INT,
    alert_message TEXT NOT NULL,
    alert_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_time TIMESTAMP,
    CONSTRAINT fk_backup_alert_log
        FOREIGN KEY (backup_id)
        REFERENCES backup_automation.backup_log(backup_id)
        ON DELETE SET NULL
);
