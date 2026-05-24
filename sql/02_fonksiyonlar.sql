-- ============================================================
-- BLM4522 — Proje 7: Veritabanı Yedekleme ve Otomasyon
-- BÖLÜM 2: YARDIMCI FONKSİYONLAR
-- BÖLÜM 3: BİLDİRİM (ALERT) FONKSİYONU
-- Veritabanı: Northwind | Platform: PostgreSQL + DBeaver
-- ============================================================

-- ============================================================
-- BÖLÜM 2: YARDIMCI FONKSİYONLAR
-- ============================================================

-- 2.1 Konfigürasyon değeri oku (tekrar tekrar SELECT yazmamak için)
CREATE OR REPLACE FUNCTION backup_mgmt.get_config(p_key VARCHAR)
RETURNS TEXT
LANGUAGE plpgsql AS $$
DECLARE
    v_val TEXT;
BEGIN
    SELECT config_value INTO v_val
    FROM backup_mgmt.backup_config
    WHERE config_key = p_key;

    IF v_val IS NULL THEN
        RAISE EXCEPTION 'Config key bulunamadı: %', p_key;
    END IF;
    RETURN v_val;
END;
$$;

-- 2.2 Log kaydı aç ve log_id döndür (yedekleme başında çağrılır)
CREATE OR REPLACE FUNCTION backup_mgmt.start_backup_log(
    p_type    VARCHAR,
    p_db      VARCHAR,
    p_path    TEXT
)
RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
    v_id INT;
BEGIN
    INSERT INTO backup_mgmt.backup_log
        (backup_type, db_name, backup_path, status)
    VALUES
        (p_type, p_db, p_path, 'RUNNING')
    RETURNING log_id INTO v_id;

    RETURN v_id;
END;
$$;

-- 2.3 Log kaydını kapat: başarılı mı başarısız mı bilgisini yaz
CREATE OR REPLACE FUNCTION backup_mgmt.finish_backup_log(
    p_log_id   INT,
    p_status   VARCHAR,           -- 'SUCCESS' veya 'FAILED'
    p_size     BIGINT DEFAULT 0,
    p_error    TEXT   DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE backup_mgmt.backup_log
    SET
        finished_at     = NOW(),
        status          = p_status,
        file_size_bytes = p_size,
        error_message   = p_error
    WHERE log_id = p_log_id;
END;
$$;


-- ============================================================
-- BÖLÜM 3: BİLDİRİM (ALERT) FONKSİYONU
-- ============================================================

-- 3.1 Yedekleme başarısız olduğunda alert_log'a kayıt yazar
--     ve RAISE WARNING ile DBeaver konsoluna mesaj basar.
--     Gerçek e-posta için pg_notify + harici dinleyici kullanılabilir.
CREATE OR REPLACE FUNCTION backup_mgmt.send_alert(
    p_log_id      INT,
    p_alert_type  VARCHAR,
    p_message     TEXT
)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    v_role TEXT;
BEGIN
    -- Konfigürasyondan bildirim rolünü al
    v_role := backup_mgmt.get_config('alert_role');

    -- Alert geçmişine kaydet
    INSERT INTO backup_mgmt.alert_log
        (log_id, alert_type, alert_message, notified_to)
    VALUES
        (p_log_id, p_alert_type, p_message, v_role);

    -- DBeaver / psql konsoluna uyarı bas (log yerine geçer)
    RAISE WARNING '[BACKUP ALERT] Tip: % | Mesaj: % | Rol: %',
        p_alert_type, p_message, v_role;

    -- pg_notify ile harici uygulama/script dinleyebilir
    PERFORM pg_notify(
        'backup_alerts',
        json_build_object(
            'log_id',     p_log_id,
            'alert_type', p_alert_type,
            'message',    p_message,
            'role',       v_role,
            'time',       NOW()
        )::text
    );
END;
$$;

-- Fonksiyonların oluşturulduğunu doğrula
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'backup_mgmt'
ORDER BY routine_name;
