DROP FUNCTION IF EXISTS has_cycle;

DELIMITER $$

CREATE FUNCTION has_cycle(new_doctor_id INT, supervisor_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE current_id INT;
    DECLARE depth INT DEFAULT 0;
    SET current_id = supervisor_id;

    WHILE current_id IS NOT NULL AND depth < 100 DO
        IF current_id = new_doctor_id THEN
            RETURN TRUE;
        END IF;

        SELECT d.supervisor_id INTO current_id
        FROM Doctors d
        WHERE d.staff_id = current_id;

        SET depth = depth + 1;
    END WHILE;

    RETURN FALSE;
END$$
DELIMITER ; 

DROP TRIGGER IF EXISTS trg_supervisor_deleted;
DELIMITER $$
CREATE TRIGGER trg_supervisor_deleted
BEFORE UPDATE ON Doctors
FOR EACH ROW
BEGIN
    IF OLD.supervisor_id IS NOT NULL 
       AND NEW.supervisor_id IS NULL
       AND NEW.rank = 'Ειδικευόμενος' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ειδικευόμενος δεν μπορεί να μείνει χωρίς supervisor. Αναθέστε νέο supervisor πρώτα.';
    END IF;
END$$
DELIMITER ; 

DROP TRIGGER IF EXISTS trg_doctor_insert_no_cycle;
DELIMITER $$
CREATE TRIGGER trg_doctor_insert_no_cycle
BEFORE INSERT ON Doctors
FOR EACH ROW
BEGIN
    IF NEW.supervisor_id IS NOT NULL THEN
        IF has_cycle(NEW.staff_id, NEW.supervisor_id) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Απαγορευμένη κυκλική αλυσίδα εποπτείας.';
        END IF;
    END IF;
END$$
DELIMITER ; 

DROP TRIGGER IF EXISTS trg_doctor_update_no_cycle;
DELIMITER $$
CREATE TRIGGER trg_doctor_update_no_cycle
BEFORE UPDATE ON Doctors
FOR EACH ROW
BEGIN
    IF NEW.supervisor_id IS NOT NULL THEN
        IF has_cycle(NEW.staff_id, NEW.supervisor_id) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Απαγορευμένη κυκλική αλυσίδα εποπτείας.';
        END IF;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_check_allergy_before_prescription ;
DELIMITER $$
CREATE TRIGGER trg_check_allergy_before_prescription
BEFORE INSERT ON Prescriptions
FOR EACH ROW
BEGIN
    DECLARE allergy_count INT;

    SELECT COUNT(*) INTO allergy_count
    FROM Patient_Allergies pa
    JOIN Medication_Substances ms ON pa.substance_id = ms.substance_id
    WHERE pa.patient_id = NEW.patient_id
      AND ms.medication_id = NEW.medication_id;

    IF allergy_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ΑΚΥΡΩΣΗ ΣΥΝΤΑΓΟΓΡΑΦΗΣΗΣ: Ο ασθενής είναι αλλεργικός σε κάποια δραστική ουσία αυτού του φαρμάκου.';
    END IF;
END$$ 

DROP FUNCTION IF EXISTS check_min_staff_per_shift$$

CREATE FUNCTION check_min_staff_per_shift(p_shift_id INT, p_new_staff_type VARCHAR(15))
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_num_doctors INT DEFAULT 0;
    DECLARE v_num_nurses INT DEFAULT 0;
    DECLARE v_num_admins INT DEFAULT 0;
    DECLARE v_min_docs INT;
    DECLARE v_min_nurs INT;
    DECLARE v_min_adm INT;

    SELECT d.min_doctors, d.min_nurses, d.min_admins
    INTO v_min_docs, v_min_nurs, v_min_adm
    FROM Shifts s
    JOIN Departments d ON s.department_id = d.id
    WHERE s.id = p_shift_id;

    SELECT
        SUM(CASE WHEN st.staff_type = 'doctor' THEN 1 ELSE 0 END),
        SUM(CASE WHEN st.staff_type = 'nurse' THEN 1 ELSE 0 END),
        SUM(CASE WHEN st.staff_type = 'admin' THEN 1 ELSE 0 END)
    INTO v_num_doctors, v_num_nurses, v_num_admins
    FROM Staff_Shifts ss
    JOIN Staff st ON ss.staff_id = st.id
    WHERE ss.shift_id = p_shift_id;

    CASE p_new_staff_type
        WHEN 'doctor' THEN SET v_num_doctors = v_num_doctors + 1;
        WHEN 'nurse' THEN SET v_num_nurses = v_num_nurses + 1;
        WHEN 'admin' THEN SET v_num_admins = v_num_admins + 1;
    END CASE;

    RETURN (
        v_num_doctors >= v_min_docs AND
        v_num_nurses >= v_min_nurs AND
        v_num_admins >= v_min_adm
    );
END$$

DROP FUNCTION IF EXISTS check_resident_supervisor$$

CREATE FUNCTION check_resident_supervisor(p_shift_id INT, p_new_staff_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_has_resident BOOLEAN DEFAULT FALSE;
    DECLARE v_has_supervisor BOOLEAN DEFAULT FALSE;
    DECLARE v_new_rank VARCHAR(30) DEFAULT NULL;

    SELECT d.rank INTO v_new_rank
    FROM Doctors d
    WHERE d.staff_id = p_new_staff_id;

    SELECT EXISTS (
        SELECT 1
        FROM Staff_Shifts ss
        JOIN Doctors d ON d.staff_id = ss.staff_id
        WHERE ss.shift_id = p_shift_id
          AND d.rank = 'Ειδικευόμενος'
    ) INTO v_has_resident;

    IF v_new_rank = 'Ειδικευόμενος' THEN
        SET v_has_resident = TRUE;
    END IF;

    IF v_has_resident THEN
        SELECT EXISTS (
            SELECT 1
            FROM Staff_Shifts ss
            JOIN Doctors d ON d.staff_id = ss.staff_id
            WHERE ss.shift_id = p_shift_id
              AND d.rank IN ('Επιμελητής Α΄', 'Διευθυντής')
        ) INTO v_has_supervisor;

        IF v_new_rank IN ('Επιμελητής Α΄', 'Διευθυντής') THEN
            SET v_has_supervisor = TRUE;
        END IF;

        RETURN v_has_supervisor;
    END IF;

    RETURN TRUE;
END$$

DROP FUNCTION IF EXISTS check_monthly_limit$$

CREATE FUNCTION check_monthly_limit(p_staff_id INT, p_date DATE)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_staff_type VARCHAR(15);
    DECLARE v_max_limit INT;
    DECLARE v_current_shifts INT DEFAULT 0;

    SELECT staff_type INTO v_staff_type
    FROM Staff
    WHERE id = p_staff_id;

    CASE v_staff_type
        WHEN 'doctor' THEN SET v_max_limit = 15;
        WHEN 'nurse' THEN SET v_max_limit = 20;
        WHEN 'admin' THEN SET v_max_limit = 25;
        ELSE SET v_max_limit = 999;
    END CASE;

    SELECT COALESCE(ml_num, 0) INTO v_current_shifts
    FROM Shift_Monthly_Limits
    WHERE  staff_id = p_staff_id
      AND  ml_year = YEAR(p_date)
      AND  ml_month = MONTH(p_date);

    RETURN v_current_shifts < v_max_limit;
END$$

DELIMITER $$

DROP FUNCTION IF EXISTS check_consecutive_nights$$

CREATE FUNCTION check_consecutive_nights(p_staff_id INT, p_shift_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_shift_date DATE;
    DECLARE v_shift_type VARCHAR(9);
    DECLARE v_check_date DATE;
    DECLARE v_count_prev INT DEFAULT 0;
    DECLARE v_count_next INT DEFAULT 0;
    DECLARE v_found BOOLEAN;

    SELECT shift_date, shift_type
    INTO v_shift_date, v_shift_type
    FROM Shifts
    WHERE id = p_shift_id;

    IF v_shift_type != 'Night' THEN
        RETURN TRUE;
    END IF;

    SET v_check_date = DATE_SUB(v_shift_date, INTERVAL 1 DAY);
    SET v_found = TRUE;

    WHILE v_found DO
        SELECT EXISTS (
            SELECT 1
            FROM Staff_Shifts ss
            JOIN Shifts s ON ss.shift_id = s.id
            WHERE ss.staff_id  = p_staff_id
              AND s.shift_date = v_check_date
              AND s.shift_type = 'Night'
        ) INTO v_found;

        IF v_found THEN
            SET v_count_prev = v_count_prev + 1;
            SET v_check_date = DATE_SUB(v_check_date, INTERVAL 1 DAY);
        END IF;
    END WHILE;

    SET v_check_date = DATE_ADD(v_shift_date, INTERVAL 1 DAY);
    SET v_found = TRUE;

    WHILE v_found DO
        SELECT EXISTS (
            SELECT 1
            FROM Staff_Shifts ss
            JOIN Shifts s ON ss.shift_id = s.id
            WHERE ss.staff_id = p_staff_id
              AND s.shift_date = v_check_date
              AND s.shift_type = 'Night'
        ) INTO v_found;

        IF v_found THEN
            SET v_count_next = v_count_next + 1;
            SET v_check_date = DATE_ADD(v_check_date, INTERVAL 1 DAY);
        END IF;
    END WHILE;

    IF (v_count_prev + 1 + v_count_next) > 3 THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END$$

DELIMITER ;

DELIMITER $$

DROP FUNCTION IF EXISTS get_shift_start$$

CREATE FUNCTION get_shift_start(p_shift_date DATE, p_shift_type VARCHAR(9))
RETURNS DATETIME
DETERMINISTIC
BEGIN
    RETURN CASE p_shift_type
        WHEN 'Morning' THEN TIMESTAMP(p_shift_date, '07:00:00')
        WHEN 'Afternoon' THEN TIMESTAMP(p_shift_date, '15:00:00')
        WHEN 'Night' THEN TIMESTAMP(p_shift_date, '23:00:00')
    END;
END$$

DROP FUNCTION IF EXISTS get_shift_end$$

CREATE FUNCTION get_shift_end(p_shift_date DATE, p_shift_type VARCHAR(9))
RETURNS DATETIME
DETERMINISTIC
BEGIN
    RETURN CASE p_shift_type
        WHEN 'Morning' THEN TIMESTAMP(p_shift_date, '15:00:00')
        WHEN 'Afternoon' THEN TIMESTAMP(p_shift_date, '23:00:00')
        WHEN 'Night' THEN TIMESTAMP(DATE_ADD(p_shift_date, INTERVAL 1 DAY), '07:00:00')
    END;
END$$


DROP FUNCTION IF EXISTS check_rest_period$$

CREATE FUNCTION check_rest_period(p_staff_id INT, p_shift_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_new_start DATETIME;
    DECLARE v_new_end DATETIME;
    DECLARE v_prev_end DATETIME;
    DECLARE v_next_start DATETIME;
    DECLARE v_shift_date DATE;
    DECLARE v_shift_type VARCHAR(9);

    SELECT s.shift_date, s.shift_type
    INTO   v_shift_date, v_shift_type
    FROM   Shifts s
    WHERE  s.id = p_shift_id;

    SET v_new_start = get_shift_start(v_shift_date, v_shift_type);
    SET v_new_end = get_shift_end(v_shift_date, v_shift_type);

    SELECT get_shift_end(s.shift_date, s.shift_type)
    INTO v_prev_end
    FROM Staff_Shifts ss
    JOIN Shifts s ON ss.shift_id = s.id
    WHERE ss.staff_id = p_staff_id
      AND get_shift_end(s.shift_date, s.shift_type) <= v_new_start
    ORDER BY get_shift_end(s.shift_date, s.shift_type) DESC
    LIMIT 1;

    SELECT get_shift_start(s.shift_date, s.shift_type)
    INTO v_next_start
    FROM Staff_Shifts ss
    JOIN Shifts s ON ss.shift_id = s.id
    WHERE ss.staff_id = p_staff_id
      AND get_shift_start(s.shift_date, s.shift_type) >= v_new_end
    ORDER BY get_shift_start(s.shift_date, s.shift_type) ASC
    LIMIT 1;

    IF v_prev_end IS NOT NULL THEN
        IF TIMESTAMPDIFF(HOUR, v_prev_end, v_new_start) < 8 THEN
            RETURN FALSE;
        END IF;
    END IF;

    IF v_next_start IS NOT NULL THEN
        IF TIMESTAMPDIFF(HOUR, v_new_end, v_next_start) < 8 THEN
            RETURN FALSE;
        END IF;
    END IF;

    RETURN TRUE;
END$$

DROP TRIGGER IF EXISTS trg_staff_shifts_before_insert$$

CREATE TRIGGER trg_staff_shifts_before_insert
BEFORE INSERT ON Staff_Shifts
FOR EACH ROW
BEGIN
    DECLARE v_shift_date   DATE;
    DECLARE v_shift_status VARCHAR(10);
    DECLARE v_staff_type   VARCHAR(15);

    SELECT shift_date, shift_status
    INTO v_shift_date, v_shift_status
    FROM Shifts
    WHERE id = NEW.shift_id;

    SELECT staff_type INTO v_staff_type
    FROM Staff
    WHERE id = NEW.staff_id;

    IF v_shift_status IN ('completed', 'cancelled') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Δεν μπορείτε να προσθέσετε προσωπικό σε ολοκληρωμένη ή ακυρωμένη βάρδια.';
    END IF;

    IF check_monthly_limit(NEW.staff_id, v_shift_date) = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Το προσωπικό έχει φτάσει το μηνιαίο όριο εφημεριών.';
    END IF;

    IF check_resident_supervisor(NEW.shift_id, NEW.staff_id) = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Παρουσία ειδικευόμενου χωρίς Επιμελητή Α΄ ή Διευθυντή στη βάρδια.';
    END IF;

    IF check_rest_period(NEW.staff_id, NEW.shift_id) = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Δεν έχει παρέλθει το ελάχιστο διάστημα ανάπαυσης 8 ωρών μεταξύ βαρδιών.';
    END IF;

    IF check_consecutive_nights(NEW.staff_id, NEW.shift_id) = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Υπέρβαση ορίου 3 συνεχόμενων νυχτερινών βαρδιών.';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_check_min_staff_on_shift_start$$

CREATE TRIGGER trg_check_min_staff_on_shift_start
BEFORE UPDATE ON Shifts
FOR EACH ROW
BEGIN
    IF OLD.shift_status != 'ongoing' AND NEW.shift_status = 'ongoing' THEN
        IF check_min_staff_per_shift(NEW.id, NULL) = FALSE THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Η βάρδια δεν έχει τον ελάχιστο αριθμό προσωπικού για να ξεκινήσει.';
        END IF;
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_update_monthly_limits$$

CREATE TRIGGER trg_update_monthly_limits
AFTER INSERT ON Staff_Shifts
FOR EACH ROW
BEGIN
    DECLARE v_shift_date DATE;

    SELECT shift_date INTO v_shift_date
    FROM Shifts
    WHERE id = NEW.shift_id;

    INSERT INTO Shift_Monthly_Limits (staff_id, ml_year, ml_month, ml_num)
    VALUES (NEW.staff_id, YEAR(v_shift_date), MONTH(v_shift_date), 1)
    ON DUPLICATE KEY UPDATE ml_num = ml_num + 1;
END$$

DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_check_staff_type_doctor_insert$$

CREATE TRIGGER trg_check_staff_type_doctor_insert
BEFORE INSERT ON Doctors
FOR EACH ROW
BEGIN
    DECLARE v_type VARCHAR(15);

    SELECT staff_type INTO v_type
    FROM Staff
    WHERE id = NEW.staff_id;

    IF v_type != 'doctor' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Staff type mismatch: ο υπάλληλος δεν είναι doctor.';
    END IF;
END$$


DROP TRIGGER IF EXISTS trg_check_staff_type_nurse_insert$$

CREATE TRIGGER trg_check_staff_type_nurse_insert
BEFORE INSERT ON Nurses
FOR EACH ROW
BEGIN
    DECLARE v_type VARCHAR(15);

    SELECT staff_type INTO v_type
    FROM Staff
    WHERE id = NEW.staff_id;

    IF v_type != 'nurse' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Staff type mismatch: ο υπάλληλος δεν είναι nurse.';
    END IF;
END$$


DROP TRIGGER IF EXISTS trg_check_staff_type_admin_insert$$

CREATE TRIGGER trg_check_staff_type_admin_insert
BEFORE INSERT ON Administrative_Staff
FOR EACH ROW
BEGIN
    DECLARE v_type VARCHAR(15);

    SELECT staff_type INTO v_type
    FROM Staff
    WHERE id = NEW.staff_id;

    IF v_type != 'admin' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Staff type mismatch: ο υπάλληλος δεν είναι admin.';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_check_bed_availability$$

CREATE TRIGGER trg_check_bed_availability
BEFORE INSERT ON Hospitalizations
FOR EACH ROW
BEGIN
    DECLARE v_occupied INT;

    SELECT COUNT(*) INTO v_occupied
    FROM Hospitalizations
    WHERE bed_id = NEW.bed_id
      AND exit_date IS NULL;

    IF v_occupied > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η κλίνη είναι ήδη κατειλημμένη.';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_bed_status_on_admission$$

CREATE TRIGGER trg_bed_status_on_admission
AFTER INSERT ON Hospitalizations
FOR EACH ROW
BEGIN
    UPDATE Beds SET status = 'Κατειλημμένη'
    WHERE id = NEW.bed_id;
END$$


DROP TRIGGER IF EXISTS trg_bed_status_on_discharge$$

CREATE TRIGGER trg_bed_status_on_discharge
AFTER UPDATE ON Hospitalizations
FOR EACH ROW
BEGIN
    IF OLD.exit_date IS NULL AND NEW.exit_date IS NOT NULL THEN
        UPDATE Beds SET status = 'Διαθέσιμη'
        WHERE id = NEW.bed_id;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_check_rating_on_completed_hospitalization$$

CREATE TRIGGER trg_check_rating_on_completed_hospitalization
BEFORE INSERT ON Hospitalization_Ratings
FOR EACH ROW
BEGIN
    DECLARE v_exit_date DATETIME;

    SELECT exit_date INTO v_exit_date
    FROM   Hospitalizations
    WHERE  id = NEW.hospitalization_id;

    IF v_exit_date IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Αξιολόγηση επιτρέπεται μόνο για ολοκληρωμένες νοσηλείες.';
    END IF;
END$$


DROP TRIGGER IF EXISTS trg_check_doctor_rating_on_completed_hospitalization$$

CREATE TRIGGER trg_check_doctor_rating_on_completed_hospitalization
BEFORE INSERT ON Doctor_Ratings
FOR EACH ROW
BEGIN
    DECLARE v_exit_date DATETIME;

    SELECT exit_date INTO v_exit_date
    FROM Hospitalizations
    WHERE id = NEW.hospitalization_id;

    IF v_exit_date IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Αξιολόγηση ιατρού επιτρέπεται μόνο για ολοκληρωμένες νοσηλείες.';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_check_medical_act_conflicts$$

CREATE TRIGGER trg_check_medical_act_conflicts
BEFORE INSERT ON Medical_Acts
FOR EACH ROW
BEGIN
    DECLARE v_end_time DATETIME;
    DECLARE v_room_conflict INT;
    DECLARE v_doctor_conflict INT;

    SET v_end_time = DATE_ADD(NEW.scheduled_time, INTERVAL NEW.duration_minutes MINUTE);

    SELECT COUNT(*) INTO v_room_conflict
    FROM   Medical_Acts
    WHERE  room_id = NEW.room_id
      AND  (
            (NEW.scheduled_time >= scheduled_time 
             AND NEW.scheduled_time < DATE_ADD(scheduled_time, INTERVAL duration_minutes MINUTE))
            OR
            (v_end_time > scheduled_time 
             AND v_end_time <= DATE_ADD(scheduled_time, INTERVAL duration_minutes MINUTE))
            OR
            (NEW.scheduled_time <= scheduled_time 
             AND v_end_time >= DATE_ADD(scheduled_time, INTERVAL duration_minutes MINUTE))
           );

    IF v_room_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο χώρος επέμβασης είναι ήδη κατειλημμένος αυτή την ώρα.';
    END IF;

    SELECT COUNT(*) INTO v_doctor_conflict
    FROM Medical_Acts
    WHERE main_doctor_id = NEW.main_doctor_id
      AND  (
            (NEW.scheduled_time >= scheduled_time 
             AND NEW.scheduled_time < DATE_ADD(scheduled_time, INTERVAL duration_minutes MINUTE))
            OR
            (v_end_time > scheduled_time 
             AND v_end_time <= DATE_ADD(scheduled_time, INTERVAL duration_minutes MINUTE))
            OR
            (NEW.scheduled_time <= scheduled_time 
             AND v_end_time >= DATE_ADD(scheduled_time, INTERVAL duration_minutes MINUTE))
           );

    IF v_doctor_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο κύριος ιατρός συμμετέχει ήδη σε άλλη επέμβαση αυτή την ώρα.';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_check_assistant_conflict$$

CREATE TRIGGER trg_check_assistant_conflict
BEFORE INSERT ON Medical_Act_Assistants
FOR EACH ROW
BEGIN
    DECLARE v_new_start DATETIME;
    DECLARE v_new_end DATETIME;
    DECLARE v_conflict INT;

    SELECT scheduled_time, 
           DATE_ADD(scheduled_time, INTERVAL duration_minutes MINUTE)
    INTO v_new_start, v_new_end
    FROM Medical_Acts
    WHERE id = NEW.act_id;

    SELECT COUNT(*) INTO v_conflict
    FROM Medical_Act_Assistants maa
    JOIN Medical_Acts ma ON maa.act_id = ma.id
    WHERE maa.staff_id = NEW.staff_id
      AND  (
            (v_new_start >= ma.scheduled_time 
             AND v_new_start < DATE_ADD(ma.scheduled_time, INTERVAL ma.duration_minutes MINUTE))
            OR
            (v_new_end > ma.scheduled_time 
             AND v_new_end <= DATE_ADD(ma.scheduled_time, INTERVAL ma.duration_minutes MINUTE))
            OR
            (v_new_start <= ma.scheduled_time 
             AND v_new_end >= DATE_ADD(ma.scheduled_time, INTERVAL ma.duration_minutes MINUTE))
           );

    IF v_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο βοηθός συμμετέχει ήδη σε άλλη επέμβαση αυτή την ώρα.';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_check_doctor_rating_prescribed$$

CREATE TRIGGER trg_check_doctor_rating_prescribed
BEFORE INSERT ON Doctor_Ratings
FOR EACH ROW
BEGIN
    DECLARE v_prescribed INT;

    SELECT COUNT(*) INTO v_prescribed
    FROM Prescriptions
    WHERE hospitalization_id = NEW.hospitalization_id
      AND doctor_id = NEW.doctor_id;

    IF v_prescribed = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Μπορείτε να αξιολογήσετε μόνο ιατρούς που συνταγογράφησαν κατά τη νοσηλεία σας.';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_calculate_total_cost$$

CREATE TRIGGER trg_calculate_total_cost
BEFORE UPDATE ON Hospitalizations
FOR EACH ROW
BEGIN
    DECLARE v_base_cost DECIMAL(10,2);
    DECLARE v_mdn_days INT;
    DECLARE v_actual_days INT;
    DECLARE v_extra_days INT;
    DECLARE v_daily_rate DECIMAL(10,2);

    IF OLD.exit_date IS NULL AND NEW.exit_date IS NOT NULL AND NEW.ken_code IS NOT NULL THEN

        SELECT base_cost, mdn_days
        INTO v_base_cost, v_mdn_days
        FROM KEN_Ref
        WHERE code = NEW.ken_code;

        SET v_actual_days = DATEDIFF(NEW.exit_date, NEW.entry_date);

        IF v_actual_days <= v_mdn_days THEN
            SET NEW.total_cost = v_base_cost;
        ELSE
            SET v_extra_days = v_actual_days - v_mdn_days;
            SET v_daily_rate  = v_base_cost / v_mdn_days;
            SET NEW.total_cost = v_base_cost + (v_extra_days * v_daily_rate);
        END IF;

    END IF;
END$$

DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_check_assistant_staff_type$$

CREATE TRIGGER trg_check_assistant_staff_type
BEFORE INSERT ON Medical_Act_Assistants
FOR EACH ROW
BEGIN
    DECLARE v_staff_type VARCHAR(15);

    SELECT staff_type INTO v_staff_type
    FROM Staff
    WHERE id = NEW.staff_id;

    IF v_staff_type NOT IN ('doctor', 'nurse') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Βοηθός επέμβασης μπορεί να είναι μόνο ιατρός ή νοσηλευτής.';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_check_triage_nurse_department$$

CREATE TRIGGER trg_check_triage_nurse_department
BEFORE INSERT ON Triage_Entries
FOR EACH ROW
BEGIN
    DECLARE v_department_name VARCHAR(100);

    SELECT d.name INTO v_department_name
    FROM Nurses n
    JOIN Departments d ON n.department_id = d.id
    WHERE n.staff_id = NEW.nurse_id;

    IF v_department_name != 'Επείγοντα' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο νοσηλευτής διαλογής πρέπει να ανήκει στο τμήμα Επειγόντων.';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_update_bed_count_on_insert$$

CREATE TRIGGER trg_update_bed_count_on_insert
AFTER INSERT ON Beds
FOR EACH ROW
BEGIN
    UPDATE Departments 
    SET bed_count = bed_count + 1
    WHERE id = NEW.department_id;
END$$

DROP TRIGGER IF EXISTS trg_update_bed_count_on_delete$$

CREATE TRIGGER trg_update_bed_count_on_delete
AFTER DELETE ON Beds
FOR EACH ROW
BEGIN
    UPDATE Departments 
    SET bed_count = bed_count - 1
    WHERE id = OLD.department_id;
END$$

DELIMITER ;