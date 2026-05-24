-- ============================================================
-- BLM4522 — Proje 7: Veritabanı Yedekleme ve Otomasyon
-- BÖLÜM 4: TEMEL YEDEKLEME FONKSİYONU
-- BÖLÜM 5: ESKİ YEDEKLERİ TEMİZLEME
-- Veritabanı: Northwind | Platform: PostgreSQL + DBeaver
-- ============================================================

-- ============================================================
-- BÖLÜM 4: TEMEL YEDEKLEME FONKSİYONU
-- ============================================================

-- 4.1 pg_dump komutunu COPY PROGRAM üzerinden çalıştırır.
--     Başarı/hata sonucu log ve alert tablolarına yazılır.
--
--     KULLANIM:
--       SELECT backup_mgmt.take_backup('FULL');
--       SELECT backup_mgmt.take_backup('SCHEMA');
--       SELECT backup_mgmt.take_backup('TABLE', 'orders');
CREATE OR REPLACE FUNCTION backup_mgmt.take_backup(
    p_type       VARCHAR DEFAULT 'FULL',   -- 'FULL' | 'SCHEMA' | 'TABLE'
    p_table_name VARCHAR DEFAULT NULL      -- sadece TABLE tipinde kullanılır
)
RETURNS TABLE (
    log_id      INT,
    status      VARCHAR,
    backup_path TEXT,
    message     TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_db        TEXT;
    v_base_path TEXT;
    v_filename  TEXT;
    v_full_path TEXT;
    v_cmd       TEXT;
    v_log_id    INT;
BEGIN
    -- Konfigürasyondan ayarları oku
    v_db        := backup_mgmt.get_config('db_name');
    v_base_path := backup_mgmt.get_config('backup_base_path');

    -- Dosya adını oluştur: northwind_FULL_20250524_153000.sql
    v_filename  := v_db || '_' || p_type || '_'
                   || TO_CHAR(NOW(), 'YYYYMMDD_HH24MISS') || '.sql';
    v_full_path := v_base_path || '/' || v_filename;

    -- Yedek tipine göre pg_dump komutunu hazırla
    CASE p_type
        WHEN 'FULL' THEN
            -- Tüm veritabanını yedekle (tablo + veri + şema)
            v_cmd := 'pg_dump -U postgres -d ' || v_db
                     || ' -f ' || v_full_path;

        WHEN 'SCHEMA' THEN
            -- Sadece şema yapısını yedekle (veri yok)
            v_cmd := 'pg_dump -U postgres -d ' || v_db
                     || ' --schema-only -f ' || v_full_path;

        WHEN 'TABLE' THEN
            -- Tek tablo yedekle
            IF p_table_name IS NULL THEN
                RAISE EXCEPTION 'TABLE tipi için p_table_name zorunludur.';
            END IF;
            v_cmd := 'pg_dump -U postgres -d ' || v_db
                     || ' -t ' || p_table_name
                     || ' -f ' || v_full_path;

        ELSE
            RAISE EXCEPTION 'Geçersiz yedek tipi: %. FULL|SCHEMA|TABLE olmalı.', p_type;
    END CASE;

    -- Log kaydını aç
    v_log_id := backup_mgmt.start_backup_log(p_type, v_db, v_full_path);

    BEGIN
        -- Shell komutunu çalıştır (PostgreSQL COPY PROGRAM mekanizması)
        EXECUTE format('COPY (SELECT 1) TO PROGRAM %L', v_cmd);

        -- Başarılı: log'u güncelle
        PERFORM backup_mgmt.finish_backup_log(v_log_id, 'SUCCESS', 0);

        -- Başarı bildirimi gönder
        PERFORM backup_mgmt.send_alert(
            v_log_id, 'BACKUP_SUCCESS',
            p_type || ' yedeği başarıyla alındı: ' || v_full_path
        );

        RETURN QUERY SELECT v_log_id, 'SUCCESS'::VARCHAR, v_full_path,
                            'Yedek başarıyla alındı.'::TEXT;

    EXCEPTION WHEN OTHERS THEN
        -- Hata: log'a hata mesajını yaz
        PERFORM backup_mgmt.finish_backup_log(
            v_log_id, 'FAILED', 0, SQLERRM
        );

        -- BAŞARISIZ bildirim gönder (proje maddesi: otomatik uyarı)
        PERFORM backup_mgmt.send_alert(
            v_log_id, 'BACKUP_FAILED',
            p_type || ' yedeği BAŞARISIZ! Hata: ' || SQLERRM
        );

        RETURN QUERY SELECT v_log_id, 'FAILED'::VARCHAR, v_full_path,
                            ('Hata: ' || SQLERRM)::TEXT;
    END;
END;
$$;


-- ============================================================
-- BÖLÜM 5: ESKİ YEDEKLERİ TEMİZLEME
-- ============================================================

-- 5.1 Retention politikasına göre eski log kayıtlarını temizler.
--     Dosya silme işlemi harici shell script ile yapılmalıdır.
--     Bu fonksiyon log tablosunu temizler ve rapor üretir.
CREATE OR REPLACE FUNCTION backup_mgmt.cleanup_old_logs()
RETURNS TABLE (
    deleted_count INT,
    oldest_kept   TIMESTAMP
)
LANGUAGE plpgsql AS $$
DECLARE
    v_days   INT;
    v_cutoff TIMESTAMP;
    v_count  INT;
BEGIN
    v_days   := backup_mgmt.get_config('retention_days')::INT;
    v_cutoff := NOW() - (v_days || ' days')::INTERVAL;

    -- Eski başarılı yedek loglarını sil (başarısızlar inceleme için kalır)
    DELETE FROM backup_mgmt.backup_log
    WHERE started_at < v_cutoff
      AND status = 'SUCCESS';

    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN QUERY
    SELECT v_count,
           MIN(started_at)
    FROM backup_mgmt.backup_log;
END;
$$;
