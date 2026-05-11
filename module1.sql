DROP TRIGGER IF EXISTS trg_set_patient_registered_date ON patients;

--FUNCTION--
CREATE OR REPLACE FUNCTION count_patients()
RETURNS INTEGER
AS $$
DECLARE
    total_patients INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO total_patients
    FROM patients;

    RETURN total_patients;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION module1.calculate_patient_age(p_dob DATE)
RETURNS INT
AS $$
BEGIN
    RETURN DATE_PART('year', AGE(p_dob));
END;
$$ LANGUAGE plpgsql;

--TRIGGER FUNCTION--
CREATE OR REPLACE FUNCTION set_patient_registered_date()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.date_registered IS NULL THEN
    NEW.date_registered = CURRENT_DATE;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--TRIGGER--
CREATE TRIGGER trg_set_patient_registered_date
BEFORE INSERT ON patients
FOR EACH ROW
EXECUTE FUNCTION set_patient_registered_date();

--PROCEDURE--
CREATE OR REPLACE PROCEDURE add_patient(
  p_first_name VARCHAR,
  p_last_name VARCHAR,
  p_address TEXT,
  p_phone VARCHAR,
  p_dob DATE,
  p_sex CHAR,
  p_marital_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO patients
  (first_name, last_name, address, phone, date_of_birth, sex, marital_status)
  VALUES
  (p_first_name, p_last_name, p_address, p_phone, p_dob, p_sex, p_marital_status);
END;
$$;

--TEST--
SELECT count_patients();

SELECT module1.calculate_patient_age('2000-01-01');

CALL add_patient(
  'Mark',
  'Santos',
  'Cagayan de Oro',
  '09111111111',
  '2001-03-15',
  'M',
  'Single'
);

SELECT *
FROM patients
ORDER BY patient_id DESC;