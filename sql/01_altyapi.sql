-- ============================================================
-- BLM4522 — Proje 7: Veritabanı Yedekleme ve Otomasyon
-- BÖLÜM 1: ALTYAPI HAZIRLIĞI
-- Veritabanı: Northwind | Platform: PostgreSQL + DBeaver
-- ============================================================

-- 1.1 pgAgent extension'ı etkinleştir (job scheduler için zorunlu)
CREATE EXTENSION IF NOT EXISTS pgagent;

-- 1.2 Yedekleme loglarını tutacak şema oluştur
CREATE SCHEMA IF NOT EXISTS backup_mgmt;

-- 1.3 Her yedekleme işleminin kaydını tutacak ana log tablosu
CREATE TABLE IF NOT EXISTS backup_mgmt.backup_log (
    log_id          SERIAL PRIMARY KEY,
    backup_type     VARCHAR(20)  NOT NULL,  -- 'FULL' | 'SCHEMA' | 'TABLE'
    db_name         VARCHAR(100) NOT NULL,  -- yedeklenen veritabanı adı
    backup_path     TEXT         NOT NULL,  -- dosyanın kaydedileceği yol
    started_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    finished_at     TIMESTAMP,              -- işlem bitince güncellenir
    status          VARCHAR(20)  NOT NULL DEFAULT 'RUNNING', -- RUNNING | SUCCESS | FAILED
    file_size_bytes BIGINT,                 -- oluşan dosya boyutu
    error_message   TEXT,                   -- hata varsa buraya yazılır
    created_by      VARCHAR(100) DEFAULT CURRENT_USER
);

-- 1.4 Bildirim (uyarı) geçmişini tutacak tablo
CREATE TABLE IF NOT EXISTS backup_mgmt.alert_log (
    alert_id      SERIAL PRIMARY KEY,
    log_id        INT REFERENCES backup_mgmt.backup_log(log_id),
    alert_time    TIMESTAMP NOT NULL DEFAULT NOW(),
    alert_type    VARCHAR(50),   -- 'BACKUP_FAILED' | 'BACKUP_SUCCESS' | 'DISK_WARNING'
    alert_message TEXT,
    notified_to   VARCHAR(200)   -- bildirim gönderilen rol/kullanıcı
);

-- 1.5 Yedekleme ayarlarını merkezi tutan konfigürasyon tablosu
CREATE TABLE IF NOT EXISTS backup_mgmt.backup_config (
    config_key   VARCHAR(100) PRIMARY KEY,
    config_value TEXT NOT NULL,
    description  TEXT
);

-- 1.6 Varsayılan konfigürasyon değerlerini ekle
INSERT INTO backup_mgmt.backup_config (config_key, config_value, description)
VALUES
    ('backup_base_path',  '/tmp/northwind_backups',  'Yedeklerin kaydedileceği ana klasör'),
    ('db_name',           'northwind',               'Yedeklenecek veritabanı adı'),
    ('retention_days',    '7',                       'Yedek dosyaların kaç gün saklanacağı'),
    ('alert_role',        'pg_monitor',              'Başarısız yedekte bildirim gönderilecek rol'),
    ('min_backup_size',   '1024',                    'Geçerli sayılacak min dosya boyutu (byte)')
ON CONFLICT (config_key) DO NOTHING;

-- Konfigürasyon tablosunu doğrula
SELECT * FROM backup_mgmt.backup_config;
