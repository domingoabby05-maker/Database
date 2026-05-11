DROP FUNCTION get_appointments_by_date(date);
DROP TRIGGER IF EXISTS trg_validate_appointment ON appointments;

--FUNCTION--
CREATE OR REPLACE FUNCTION get_low_stock_drugs(min_stock INT)
RETURNS TABLE (
    drug_id INT,
    drug_name VARCHAR,
    quantity_in_stock INT
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.drug_id,
        d.name,
        d.quantity_in_stock
    FROM drugs d
    WHERE d.quantity_in_stock < min_stock;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_appointments_by_date(p_date DATE)
RETURNS TABLE (
  appointment_id INT,
  patient_id INT,
  consultant_id INT,
  appointment_time TIME,
  room VARCHAR
)
AS $$
BEGIN
  RETURN QUERY
  SELECT a.appointment_id, a.patient_id, a.consultant_id, a.appointment_time, a.room
  FROM appointments a
  WHERE a.appointment_date = p_date;
END;
$$ LANGUAGE plpgsql;

--TRIGGER FUNCTION--
CREATE OR REPLACE FUNCTION validate_appointment_time()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.appointment_time < '08:00:00' OR NEW.appointment_time > '17:00:00' THEN
    RAISE EXCEPTION 'Appointment time must be between 8AM and 5PM';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--TRIGGER--
CREATE TRIGGER trg_validate_appointment
BEFORE INSERT OR UPDATE ON appointments
FOR EACH ROW
EXECUTE FUNCTION validate_appointment_time();

--PROCEDURE--
CREATE OR REPLACE PROCEDURE create_appointment(
  p_patient_id INT,
  p_consultant_id INT,
  p_date DATE,
  p_time TIME,
  p_room VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO appointments
  (patient_id, consultant_id, appointment_date, appointment_time, room)
  VALUES
  (p_patient_id, p_consultant_id, p_date, p_time, p_room);
END;
$$;


--TEST--
SELECT * FROM get_low_stock_drugs(20);

SELECT * FROM get_appointments_by_date('2026-05-15');

--SHOULD WORK--
INSERT INTO appointments (
    patient_id,
    consultant_id,
    appointment_date,
    appointment_time,
    room
)
VALUES (
    1,
    1,
    '2026-05-20',
    '10:00:00',
    'Room 101'
);

--SHOULD FAIL--
INSERT INTO appointments (
    patient_id,
    consultant_id,
    appointment_date,
    appointment_time,
    room
)
VALUES (
    1,
    1,
    '2026-05-20',
    '19:00:00',
    'Room 101'
);

CALL create_appointment(
    1,
    1,
    '2026-05-21',
    '09:30:00',
    'Room 202'
);

SELECT * FROM appointments
ORDER BY appointment_id DESC;