DROP TRIGGER IF EXISTS trg_validate_staff_salary ON staff;

CREATE OR REPLACE FUNCTION get_staff_qualifications()
RETURNS TABLE (
    staff_id INT,
    first_name VARCHAR,
    last_name VARCHAR,
    qualification_type VARCHAR,
    institution VARCHAR
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.staff_id,
        s.first_name,
        s.last_name,
        q.qualification_type,
        q.institution
    FROM staff s
    JOIN qualifications q
        ON s.staff_id = q.staff_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculate_annual_salary(monthly_salary DECIMAL)
RETURNS DECIMAL AS $$
BEGIN
  RETURN monthly_salary * 12;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_staff_salary()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.salary < 0 THEN
    RAISE EXCEPTION 'Salary cannot be negative';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_staff_salary
BEFORE INSERT OR UPDATE ON staff
FOR EACH ROW
EXECUTE FUNCTION validate_staff_salary();

DROP PROCEDURE IF EXISTS add_staff(
  VARCHAR, VARCHAR, TEXT, VARCHAR, DATE, CHAR, VARCHAR, VARCHAR, DECIMAL, VARCHAR
);

CREATE OR REPLACE PROCEDURE add_staff(
  p_first_name VARCHAR,
  p_last_name VARCHAR,
  p_address TEXT,
  p_phone VARCHAR,
  p_dob DATE,
  p_sex CHAR,
  p_nin VARCHAR,
  p_position VARCHAR,
  p_salary DECIMAL,
  p_salary_scale VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO staff
  (first_name, last_name, address, phone, date_of_birth, sex, nin, staff_position, salary, salary_scale)
  VALUES
  (p_first_name, p_last_name, p_address, p_phone, p_dob, p_sex, p_nin, p_position, p_salary, p_salary_scale);
END;
$$;

-- 1. Test annual salary function
SELECT calculate_annual_salary(18760.00);

-- 2. Test staff qualifications function
SELECT * FROM get_staff_qualifications();

INSERT INTO qualifications
(staff_id, qualification_type, institution, date_obtained)
VALUES
(1, 'Nursing Degree', 'University of Edinburgh', '1990-06-15');

SELECT * FROM get_staff_qualifications();

-- 3. Test add_staff procedure
SELECT setval(
    pg_get_serial_sequence('staff', 'staff_id'),
    COALESCE((SELECT MAX(staff_id) FROM staff), 0) + 1,
    false
);

CALL add_staff(
  'Anna',
  'Reyes',
  'Cagayan de Oro',
  '09123456789',
  '1995-04-10',
  'F',
  'NIN12345',
  'Staff Nurse',
  25000.00,
  'Scale 1'
);

SELECT * FROM staff ORDER BY staff_id DESC;

-- 4. Test salary trigger with invalid salary
SELECT *
FROM staff
WHERE first_name = 'Test'
AND last_name = 'Negative';

CALL add_staff(
  'Test',
  'Negative',
  'CDO',
  '09000000000',
  '1990-01-01',
  'M',
  'NIN99999',
  'Staff Nurse',
  -5000.00,
  'Scale 1'
);

SELECT * FROM staff;