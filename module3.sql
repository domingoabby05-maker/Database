DROP TRIGGER IF EXISTS trg_update_bed_status ON admissions;
DROP FUNCTION IF EXISTS module3.count_beds_per_ward(INTEGER);

--FUNCTION--
CREATE OR REPLACE FUNCTION get_available_beds()
RETURNS TABLE (
    bed_id INT,
    ward_name VARCHAR,
    bed_number INT,
    status VARCHAR
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        b.bed_id,
        w.ward_name,
        b.bed_number,
        b.status
    FROM beds b
    JOIN wards w
        ON b.ward_id = w.ward_id
    WHERE LOWER(b.status) = 'available';
END;
$$ LANGUAGE plpgsql;

--TRIGGER FUNCTION--
CREATE OR REPLACE FUNCTION update_bed_status_after_admission()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE beds
  SET status = 'Occupied'
  WHERE bed_id = NEW.bed_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--TRIGGER--
CREATE TRIGGER trg_update_bed_status
AFTER INSERT ON admissions
FOR EACH ROW
EXECUTE FUNCTION update_bed_status_after_admission();

--PROCEDURE--
CREATE OR REPLACE PROCEDURE admit_patient(
  p_patient_id INT,
  p_ward_id INT,
  p_bed_id INT,
  p_expected_stay_days INT
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO admissions
  (patient_id, ward_id, bed_id, date_placed_on_waiting_list, expected_stay_days, date_admitted, expected_leave_date)
  VALUES
  (p_patient_id, p_ward_id, p_bed_id, CURRENT_DATE, p_expected_stay_days, CURRENT_DATE, CURRENT_DATE + p_expected_stay_days);
END;
$$;

--TEST--
-- Test available beds
SELECT * FROM get_available_beds();

-- Test count beds per ward
SELECT count_beds_per_ward(1);

-- Test procedure
CALL admit_patient(1, 1, 1, 5);

-- Check admissions
SELECT * FROM admissions ORDER BY admission_id DESC;

-- Check if trigger updated bed status
SELECT * FROM beds WHERE bed_id = 1;