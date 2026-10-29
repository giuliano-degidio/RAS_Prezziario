-- Migrazione per installazioni che hanno gia' le tabelle scheduler precedenti.
BEGIN;

ALTER TABLE hcbi_utility.dwh_schedule_run
    ADD COLUMN IF NOT EXISTS trigger_source varchar(20);
ALTER TABLE hcbi_utility.dwh_schedule_run
    ADD COLUMN IF NOT EXISTS requested_by varchar(255);

UPDATE hcbi_utility.dwh_schedule_run
   SET trigger_source = 'SCHEDULED'
 WHERE trigger_source IS NULL;

ALTER TABLE hcbi_utility.dwh_schedule_run
    ALTER COLUMN trigger_source SET DEFAULT 'SCHEDULED';
ALTER TABLE hcbi_utility.dwh_schedule_run
    ALTER COLUMN trigger_source SET NOT NULL;

DO $block$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conrelid = 'hcbi_utility.dwh_schedule_run'::regclass
           AND conname = 'ck_dwh_schedule_run_trigger_source'
    ) THEN
        ALTER TABLE hcbi_utility.dwh_schedule_run
            ADD CONSTRAINT ck_dwh_schedule_run_trigger_source
            CHECK (trigger_source IN ('SCHEDULED', 'MANUAL_UI'));
    END IF;
END;
$block$;

COMMIT;
