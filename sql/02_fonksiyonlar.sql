-- 5. BAŞARILI BACKUP LOG FONKSİYONU
-- Gerçek backup alındıktan sonra başarı kaydı atmak için kullanılır.

CREATE OR REPLACE FUNCTION backup_automation.log_successful_backup(
    p_database_name VARCHAR,
    p_backup_type VARCHAR,
    p_backup_file_path TEXT,
    p_backup_size_mb NUMERIC DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_backup_id INT;
BEGIN
    INSERT INTO backup_automation.backup_log (
        database_name,
        backup_type,
        backup_file_path,
        backup_status,
        backup_start_time,
        backup_end_time,
        duration_seconds,
        backup_size_mb,
        error_message
    )
    VALUES (
        p_database_name,
        p_backup_type,
        p_backup_file_path,
        'SUCCESS',
        CURRENT_TIMESTAMP - INTERVAL '5 seconds',
        CURRENT_TIMESTAMP,
        5,
        p_backup_size_mb,
        NULL
    )
    RETURNING backup_id INTO v_backup_id;

    INSERT INTO backup_automation.backup_audit (
        backup_id,
        action_type,
        action_description
    )
    VALUES (
        v_backup_id,
        'BACKUP_SUCCESS',
        'Veritabanı yedekleme işlemi başarıyla tamamlandı.'
    );

    RETURN v_backup_id;
END;
$$;

-- 6. BAŞARISIZ BACKUP LOG FONKSİYONU
-- Backup başarısız olduğunda log + alert oluşturur.

CREATE OR REPLACE FUNCTION backup_automation.log_failed_backup(
    p_database_name VARCHAR,
    p_backup_type VARCHAR,
    p_backup_file_path TEXT,
    p_error_message TEXT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_backup_id INT;
BEGIN
    INSERT INTO backup_automation.backup_log (
        database_name,
        backup_type,
        backup_file_path,
        backup_status,
        backup_start_time,
        backup_end_time,
        duration_seconds,
        backup_size_mb,
        error_message
    )
    VALUES (
        p_database_name,
        p_backup_type,
        p_backup_file_path,
        'FAILED',
        CURRENT_TIMESTAMP - INTERVAL '3 seconds',
        CURRENT_TIMESTAMP,
        3,
        NULL,
        p_error_message
    )
    RETURNING backup_id INTO v_backup_id;

    INSERT INTO backup_automation.backup_audit (
        backup_id,
        action_type,
        action_description
    )
    VALUES (
        v_backup_id,
        'BACKUP_FAILED',
        'Veritabanı yedekleme işlemi başarısız oldu.'
    );

    INSERT INTO backup_automation.backup_alerts (
        backup_id,
        alert_message
    )
    VALUES (
        v_backup_id,
        'UYARI: Backup işlemi başarısız oldu. Hata: ' || p_error_message
    );

    RETURN v_backup_id;
END;
$$;
