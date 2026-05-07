DROP DATABASE IF EXISTS hospitaldb;
CREATE DATABASE hospitaldb;
use hospitaldb;

-- Tables Creation
CREATE TABLE Staff (
    id INT AUTO_INCREMENT PRIMARY KEY, 
    amka CHAR(11) NOT NULL UNIQUE, 
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15) NOT NULL,
    hire_date DATE NOT NULL,
    staff_type VARCHAR(15) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    active BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_staff_type CHECK (staff_type IN ('doctor', 'nurse', 'admin'))
);

CREATE TABLE Patients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    amka CHAR(11) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    father_name VARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL,
    gender VARCHAR(10) NOT NULL,
    weight DECIMAL(5,2) NOT NULL,
    height DECIMAL(3,2) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100),
    profession VARCHAR(100),
    nationality VARCHAR(50) NOT NULL,
    insurance_provider VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT chk_gender CHECK (gender IN ('Male', 'Female', 'Other'))
);

CREATE TABLE Doctors (
    staff_id INT PRIMARY KEY,
    license_number VARCHAR(20) NOT NULL UNIQUE,    
    specialty VARCHAR(50) NULL,
    rank VARCHAR(30) NOT NULL,    
    supervisor_id INT,

    FOREIGN KEY (staff_id) REFERENCES Staff(id) ON DELETE CASCADE,
    FOREIGN KEY (supervisor_id) REFERENCES Doctors(staff_id) ON DELETE SET NULL,

    CONSTRAINT chk_doctor_rank CHECK (rank IN ('Ειδικευόμενος', 'Επιμελητής Β΄', 'Επιμελητής Α΄', 'Διευθυντής')),
    
    CONSTRAINT chk_supervisor CHECK (
        (rank = 'Ειδικευόμενος' AND supervisor_id IS NOT NULL) OR
        (rank = 'Διευθυντής' AND supervisor_id IS NULL) OR
        (rank NOT IN ('Ειδικευόμενος', 'Διευθυντής'))
    )
);

CREATE TABLE Departments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE, 
    description TEXT, 
    bed_count INT NOT NULL DEFAULT 0, 
    location VARCHAR(100),
    head_doctor_id INT, 
    min_doctors INT DEFAULT 3,
    min_nurses INT DEFAULT 6,
    min_admins INT DEFAULT 2,

    FOREIGN KEY (head_doctor_id) REFERENCES Doctors(staff_id) ON DELETE SET NULL
);

CREATE TABLE Nurses (
    staff_id INT PRIMARY KEY,
    rank VARCHAR(50) NOT NULL,
    department_id INT NOT NULL,
    FOREIGN KEY (staff_id) REFERENCES Staff(id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES Departments(id) ON DELETE RESTRICT,
    
    CONSTRAINT chk_nurse_rank CHECK (rank IN ('Βοηθός Νοσηλευτή', 'Νοσηλευτής', 'Προϊστάμενος'))
);

CREATE TABLE Administrative_Staff (
    staff_id INT PRIMARY KEY,
    duty_role VARCHAR(100) NOT NULL,
    office_location VARCHAR(50),    
    department_id INT NOT NULL,    
    FOREIGN KEY (staff_id) REFERENCES Staff(id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES Departments(id) ON DELETE RESTRICT
);

CREATE TABLE Doctor_Departments (
    doctor_id INT NOT NULL,
    department_id INT NOT NULL,
    
    PRIMARY KEY (doctor_id, department_id),
    
    FOREIGN KEY (doctor_id) REFERENCES Doctors(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES Departments(id) ON DELETE CASCADE
);

CREATE TABLE Beds (
    id INT AUTO_INCREMENT PRIMARY KEY,    
    bed_number VARCHAR(20) NOT NULL UNIQUE,
    bed_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Διαθέσιμη',
    department_id INT NOT NULL,

    FOREIGN KEY (department_id) REFERENCES Departments(id) ON DELETE RESTRICT,
    
    CONSTRAINT chk_bed_status CHECK (status IN ('Διαθέσιμη', 'Κατειλημμένη', 'Υπό συντήρηση'))
);

CREATE TABLE Emergency_Contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    relationship VARCHAR(50),
    FOREIGN KEY (patient_id) REFERENCES Patients(id) ON DELETE CASCADE
);

CREATE TABLE KEN_Ref (
    code VARCHAR(10) PRIMARY KEY,
    base_cost DECIMAL(10,2) NOT NULL,
    mdn_days INT NOT NULL
);

CREATE TABLE ICD10_Ref (
    code VARCHAR(10) PRIMARY KEY,
    description TEXT NOT NULL
);

CREATE TABLE Triage_Entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    nurse_id INT NOT NULL,
    service_time DATETIME,
    arrival_time DATETIME NOT NULL,
    symptoms TEXT,
    urgency_level INT CHECK (urgency_level BETWEEN 1 AND 5),
    referral_status VARCHAR(50),
    FOREIGN KEY (patient_id) REFERENCES Patients(id) ON DELETE RESTRICT,
    FOREIGN KEY (nurse_id) REFERENCES Nurses(staff_id) ON DELETE RESTRICT,
    CONSTRAINT chk_referal CHECK (referral_status IN ('Exit', 'Hospitalization'))  
);

CREATE TABLE Hospitalizations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    bed_id INT NOT NULL,
    department_id INT NOT NULL,
    entry_date DATETIME NOT NULL,
    exit_date DATETIME,
    icd10_entry_code VARCHAR(10),
    icd10_exit_code VARCHAR(10),
    ken_code VARCHAR(10),
    total_cost DECIMAL(10,2),
    triage_id INT NOT NULL,
    
    FOREIGN KEY (patient_id) REFERENCES Patients(id) ON DELETE RESTRICT,
    FOREIGN KEY (bed_id) REFERENCES Beds(id) ON DELETE RESTRICT,
    FOREIGN KEY (department_id) REFERENCES Departments(id) ON DELETE RESTRICT,
    FOREIGN KEY (icd10_entry_code) REFERENCES ICD10_Ref(code) ON DELETE RESTRICT,
    FOREIGN KEY (icd10_exit_code) REFERENCES ICD10_Ref(code) ON DELETE RESTRICT,
    FOREIGN KEY (ken_code) REFERENCES KEN_Ref(code) ON DELETE RESTRICT,
    FOREIGN KEY (triage_id) REFERENCES Triage_Entries(id) ON DELETE RESTRICT
);

CREATE TABLE Active_Substances (
    id INT AUTO_INCREMENT PRIMARY KEY,
    substance_name VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE Medications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL
);

-- Ενδιάμεσος πίνακας (M to M)
CREATE TABLE Medication_Substances (
    medication_id INT NOT NULL,
    substance_id INT NOT NULL,
    PRIMARY KEY (medication_id, substance_id),
    FOREIGN KEY (medication_id) REFERENCES Medications(id) ON DELETE CASCADE,
    FOREIGN KEY (substance_id) REFERENCES Active_Substances(id) ON DELETE RESTRICT
);

CREATE TABLE Patient_Allergies (
    patient_id INT NOT NULL,
    substance_id INT NOT NULL,
    PRIMARY KEY (patient_id, substance_id),
    FOREIGN KEY (patient_id) REFERENCES Patients(id) ON DELETE CASCADE,
    FOREIGN KEY (substance_id) REFERENCES Active_Substances(id) ON DELETE RESTRICT
);

CREATE TABLE Prescriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id INT NOT NULL,
    patient_id INT NOT NULL,
    medication_id INT NOT NULL,
    hospitalization_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    dosage VARCHAR(50),
    frequency VARCHAR(50),
    FOREIGN KEY (doctor_id) REFERENCES Doctors(staff_id) ON DELETE RESTRICT,
    FOREIGN KEY (patient_id) REFERENCES Patients(id) ON DELETE RESTRICT,
    FOREIGN KEY (medication_id) REFERENCES Medications(id) ON DELETE RESTRICT,
    FOREIGN KEY (hospitalization_id) REFERENCES Hospitalizations(id) ON DELETE RESTRICT,
    UNIQUE KEY unique_prescription (doctor_id, patient_id, medication_id, start_date)
);

CREATE TABLE Shifts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    shift_type VARCHAR(9) NOT NULL,
    shift_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    shift_status VARCHAR(10) NOT NULL DEFAULT 'scheduled',
    
    UNIQUE KEY department_shift_date (department_id, shift_date, shift_type),
    FOREIGN KEY (department_id) REFERENCES Departments(id) ON DELETE RESTRICT,
    CONSTRAINT chk_shifttype CHECK (shift_type IN ('Morning', 'Afternoon', 'Night')),
    CONSTRAINT chk_shiftstatus CHECK (shift_status IN ('scheduled', 'ongoing', 'completed', 'cancelled'))
);

CREATE TABLE Staff_Shifts (
    staff_id INT NOT NULL,
    shift_id INT NOT NULL,
    start_time TIME,
    end_time TIME,
    started_date DATE,
    PRIMARY KEY (staff_id, shift_id),
    FOREIGN KEY (staff_id) REFERENCES Staff(id) ON DELETE CASCADE,
    FOREIGN KEY (shift_id) REFERENCES Shifts(id) ON DELETE CASCADE
);

CREATE TABLE Shift_Monthly_Limits (
    id INT PRIMARY KEY AUTO_INCREMENT,
    staff_id INT NOT NULL,
    ml_year INT NOT NULL,
    ml_month INT NOT NULL CHECK (ml_month BETWEEN 1 AND 12),
    ml_num INT DEFAULT 0,
    FOREIGN KEY (staff_id) REFERENCES Staff(id) ON DELETE CASCADE,
    UNIQUE KEY staff_ml_month (staff_id, ml_year, ml_month)
);


CREATE TABLE LabExam_Ref (
    code VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL
);

CREATE TABLE LabExam (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL,
    exam_date DATETIME NOT NULL,
    result TEXT,
    result_value DECIMAL(10,3),   
    result_unit VARCHAR(20),      
    cost DECIMAL(10,2) NOT NULL,
    doctor_id INT, 
    hospitalization_id INT NOT NULL,
    FOREIGN KEY (code) REFERENCES LabExam_Ref(code) ON DELETE RESTRICT,
    FOREIGN KEY (doctor_id) REFERENCES Doctors(staff_id) ON DELETE SET NULL, 
    FOREIGN KEY (hospitalization_id) REFERENCES Hospitalizations(id) ON DELETE RESTRICT
);

CREATE TABLE Operating_Rooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    room_type TEXT NOT NULL
);

-- Προσθέτω πίνακα για τους κωδικούς των επεμβάσεων
CREATE TABLE MedicalAct_Ref (
    code VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(30) NOT NULL,
    CONSTRAINT chk_act_ref_category
    CHECK (category IN ('Χειρουργική', 'Διαγνωστική', 'Θεραπευτική'))
);

CREATE TABLE Medical_Acts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    act_code VARCHAR(20) NOT NULL, 
    duration_minutes INT NOT NULL,
    cost DECIMAL(10,2) NOT NULL, 
    scheduled_time DATETIME NOT NULL,
    hospitalization_id INT NOT NULL,
    room_id INT NOT NULL,
    main_doctor_id INT NOT NULL,
    FOREIGN KEY (hospitalization_id) REFERENCES Hospitalizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (room_id) REFERENCES Operating_Rooms(id) ON DELETE RESTRICT,
    FOREIGN KEY (main_doctor_id) REFERENCES Doctors(staff_id) ON DELETE RESTRICT,
    FOREIGN KEY (act_code) REFERENCES MedicalAct_Ref(code) ON DELETE RESTRICT
);

-- Πίνακας γέφυρα για βοηθούς  επέμβασης (M:N)
CREATE TABLE Medical_Act_Assistants (
    act_id INT NOT NULL,
    staff_id INT NOT NULL,
    PRIMARY KEY (act_id, staff_id),
    FOREIGN KEY (act_id) REFERENCES Medical_Acts(id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES Staff(id) ON DELETE CASCADE
);

CREATE TABLE Hospitalization_Ratings (
    hospitalization_id INT PRIMARY KEY,
    nursing_care_quality TINYINT CHECK (nursing_care_quality BETWEEN 1 AND 5),
    cleanliness TINYINT CHECK (cleanliness BETWEEN 1 AND 5),
    food_quality TINYINT CHECK (food_quality BETWEEN 1 AND 5),
    overall_experience TINYINT CHECK (overall_experience BETWEEN 1 AND 5),
    FOREIGN KEY (hospitalization_id) REFERENCES Hospitalizations(id) ON DELETE RESTRICT
);

CREATE TABLE Doctor_Ratings (
    hospitalization_id INT,
    doctor_id INT,
    medical_care_quality TINYINT CHECK (medical_care_quality BETWEEN 1 AND 5),
    PRIMARY KEY (hospitalization_id, doctor_id),
    FOREIGN KEY (hospitalization_id) REFERENCES Hospitalizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (doctor_id) REFERENCES Doctors(staff_id) ON DELETE RESTRICT
);

CREATE TABLE Images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    image_url VARCHAR(255) NOT NULL,
    description TEXT,
    doctor_id INT,
    nurse_id INT,
    admin_id INT,
    department_id INT,
    patient_id INT,
    room_id INT,

    FOREIGN KEY (doctor_id) REFERENCES Doctors(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (nurse_id) REFERENCES Nurses(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (admin_id) REFERENCES Administrative_Staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES Departments(id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES Patients(id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES Operating_Rooms(id) ON DELETE CASCADE,

    CONSTRAINT chk_image_entity CHECK (
        (doctor_id IS NOT NULL) +
        (nurse_id IS NOT NULL) +
        (admin_id IS NOT NULL) +
        (department_id IS NOT NULL) +
        (patient_id IS NOT NULL) +
        (room_id IS NOT NULL) = 1
    )
);

-- INDEXES
-- Staff
CREATE INDEX idx_staff_name ON Staff(last_name, first_name);
CREATE INDEX idx_staff_type ON Staff(staff_type);
-- Patients
CREATE INDEX idx_patients_name ON Patients(last_name, first_name);
CREATE INDEX idx_patients_insurance ON Patients(insurance_provider);
-- Doctors
CREATE INDEX idx_doctors_specialty ON Doctors(specialty);
CREATE INDEX idx_doctors_rank ON Doctors(rank);
CREATE INDEX idx_doctors_supervisor ON Doctors(supervisor_id);
-- Departments
CREATE INDEX idx_departments_head ON Departments(head_doctor_id);
-- Beds
CREATE INDEX idx_beds_status ON Beds(status);
CREATE INDEX idx_beds_department ON Beds(department_id);
-- Triage_Entries
CREATE INDEX idx_triage_patient ON Triage_Entries(patient_id);
CREATE INDEX idx_triage_urgency ON Triage_Entries(urgency_level);
CREATE INDEX idx_triage_arrival ON Triage_Entries(arrival_time);
-- Hospitalizations
CREATE INDEX idx_hosp_patient ON Hospitalizations(patient_id);
CREATE INDEX idx_hosp_department ON Hospitalizations(department_id);
CREATE INDEX idx_hosp_dates ON Hospitalizations(entry_date, exit_date);
CREATE INDEX idx_hosp_ken ON Hospitalizations(ken_code);
CREATE INDEX idx_hosp_icd10 ON Hospitalizations(icd10_entry_code);
-- Shifts
CREATE INDEX idx_shifts_date ON Shifts(shift_date);
CREATE INDEX idx_shifts_type ON Shifts(shift_type);
CREATE INDEX idx_shifts_department ON Shifts(department_id, shift_date);
-- Staff_Shifts
CREATE INDEX idx_staff_shifts_staff ON Staff_Shifts(staff_id);
CREATE INDEX idx_staff_shifts_shift ON Staff_Shifts(shift_id);
-- Shift_Monthly_Limits
CREATE INDEX idx_sml_staff_date ON Shift_Monthly_Limits(staff_id, ml_year, ml_month);
-- Prescriptions
CREATE INDEX idx_presc_doctor ON Prescriptions(doctor_id);
CREATE INDEX idx_presc_patient ON Prescriptions(patient_id);
CREATE INDEX idx_presc_medication ON Prescriptions(medication_id);
CREATE INDEX idx_presc_hospitalization ON Prescriptions(hospitalization_id);
CREATE INDEX idx_presc_dates ON Prescriptions(start_date, end_date);
-- Medications & Substances
CREATE INDEX idx_medsubst_medication ON Medication_Substances(medication_id);
CREATE INDEX idx_medsubst_substance ON Medication_Substances(substance_id);
-- Patient_Allergies
CREATE INDEX idx_allergies_patient ON Patient_Allergies(patient_id);
CREATE INDEX idx_allergies_substance ON Patient_Allergies(substance_id);
-- Medical_Acts
CREATE INDEX idx_medacts_doctor ON Medical_Acts(main_doctor_id);
CREATE INDEX idx_medacts_room ON Medical_Acts(room_id);
CREATE INDEX idx_medacts_time ON Medical_Acts(scheduled_time);
-- LabExam
CREATE INDEX idx_labexam_date ON LabExam(exam_date);
CREATE INDEX idx_labexam_hospitalization ON LabExam(hospitalization_id);
CREATE INDEX idx_labexam_doctor ON LabExam(doctor_id);
-- Doctor_Ratings
CREATE INDEX idx_docrat_doctor ON Doctor_Ratings(doctor_id);
CREATE INDEX idx_docrat_hosp ON Doctor_Ratings(hospitalization_id);
-- Hospitalization_Ratings
CREATE INDEX idx_hosprat_hosp ON Hospitalization_Ratings(hospitalization_id);


-- FUNCTIONS
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
    DECLARE v_num_nurses  INT DEFAULT 0;
    DECLARE v_num_admins  INT DEFAULT 0;
    DECLARE v_min_docs    INT;
    DECLARE v_min_nurs    INT;
    DECLARE v_min_adm     INT;

    SELECT d.min_doctors, d.min_nurses, d.min_admins
    INTO   v_min_docs, v_min_nurs, v_min_adm
    FROM   Shifts s
    JOIN   Departments d ON s.department_id = d.id
    WHERE  s.id = p_shift_id;

    SELECT
        SUM(CASE WHEN st.staff_type = 'doctor' THEN 1 ELSE 0 END),
        SUM(CASE WHEN st.staff_type = 'nurse'  THEN 1 ELSE 0 END),
        SUM(CASE WHEN st.staff_type = 'admin'  THEN 1 ELSE 0 END)
    INTO v_num_doctors, v_num_nurses, v_num_admins
    FROM Staff_Shifts ss
    JOIN Staff st ON ss.staff_id = st.id
    WHERE ss.shift_id = p_shift_id;

    CASE p_new_staff_type
        WHEN 'doctor' THEN SET v_num_doctors = v_num_doctors + 1;
        WHEN 'nurse'  THEN SET v_num_nurses  = v_num_nurses  + 1;
        WHEN 'admin'  THEN SET v_num_admins  = v_num_admins  + 1;
    END CASE;

    RETURN (
        v_num_doctors >= v_min_docs AND
        v_num_nurses  >= v_min_nurs AND
        v_num_admins  >= v_min_adm
    );
END$$

DROP FUNCTION IF EXISTS check_resident_supervisor$$

CREATE FUNCTION check_resident_supervisor(p_shift_id INT, p_new_staff_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_has_resident   BOOLEAN DEFAULT FALSE;
    DECLARE v_has_supervisor BOOLEAN DEFAULT FALSE;
    DECLARE v_new_rank       VARCHAR(30) DEFAULT NULL;

    SELECT d.rank INTO v_new_rank
    FROM   Doctors d
    WHERE  d.staff_id = p_new_staff_id;

    SELECT EXISTS (
        SELECT 1
        FROM   Staff_Shifts ss
        JOIN   Doctors d ON d.staff_id = ss.staff_id
        WHERE  ss.shift_id = p_shift_id
          AND  d.rank = 'Ειδικευόμενος'
    ) INTO v_has_resident;

    IF v_new_rank = 'Ειδικευόμενος' THEN
        SET v_has_resident = TRUE;
    END IF;

    IF v_has_resident THEN
        SELECT EXISTS (
            SELECT 1
            FROM   Staff_Shifts ss
            JOIN   Doctors d ON d.staff_id = ss.staff_id
            WHERE  ss.shift_id = p_shift_id
              AND  d.rank IN ('Επιμελητής Α΄', 'Διευθυντής')
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
    DECLARE v_staff_type     VARCHAR(15);
    DECLARE v_max_limit      INT;
    DECLARE v_current_shifts INT DEFAULT 0;

    SELECT staff_type INTO v_staff_type
    FROM   Staff
    WHERE  id = p_staff_id;

    CASE v_staff_type
        WHEN 'doctor' THEN SET v_max_limit = 15;
        WHEN 'nurse'  THEN SET v_max_limit = 20;
        WHEN 'admin'  THEN SET v_max_limit = 25;
        ELSE               SET v_max_limit = 999;
    END CASE;

    SELECT COALESCE(ml_num, 0) INTO v_current_shifts
    FROM   Shift_Monthly_Limits
    WHERE  staff_id = p_staff_id
      AND  ml_year  = YEAR(p_date)
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
    DECLARE v_shift_date    DATE;
    DECLARE v_shift_type    VARCHAR(9);
    DECLARE v_check_date    DATE;
    DECLARE v_count_prev    INT DEFAULT 0;
    DECLARE v_count_next    INT DEFAULT 0;
    DECLARE v_found         BOOLEAN;

    SELECT shift_date, shift_type
    INTO   v_shift_date, v_shift_type
    FROM   Shifts
    WHERE  id = p_shift_id;

    IF v_shift_type != 'Night' THEN
        RETURN TRUE;
    END IF;

    SET v_check_date = DATE_SUB(v_shift_date, INTERVAL 1 DAY);
    SET v_found = TRUE;

    WHILE v_found DO
        SELECT EXISTS (
            SELECT 1
            FROM   Staff_Shifts ss
            JOIN   Shifts s ON ss.shift_id = s.id
            WHERE  ss.staff_id  = p_staff_id
              AND  s.shift_date = v_check_date
              AND  s.shift_type = 'Night'
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
            FROM   Staff_Shifts ss
            JOIN   Shifts s ON ss.shift_id = s.id
            WHERE  ss.staff_id  = p_staff_id
              AND  s.shift_date = v_check_date
              AND  s.shift_type = 'Night'
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
        WHEN 'Morning'   THEN TIMESTAMP(p_shift_date, '07:00:00')
        WHEN 'Afternoon' THEN TIMESTAMP(p_shift_date, '15:00:00')
        WHEN 'Night'     THEN TIMESTAMP(p_shift_date, '23:00:00')
    END;
END$$

DROP FUNCTION IF EXISTS get_shift_end$$

CREATE FUNCTION get_shift_end(p_shift_date DATE, p_shift_type VARCHAR(9))
RETURNS DATETIME
DETERMINISTIC
BEGIN
    RETURN CASE p_shift_type
        WHEN 'Morning'   THEN TIMESTAMP(p_shift_date, '15:00:00')
        WHEN 'Afternoon' THEN TIMESTAMP(p_shift_date, '23:00:00')
        WHEN 'Night'     THEN TIMESTAMP(DATE_ADD(p_shift_date, INTERVAL 1 DAY), '07:00:00')
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
    INTO   v_prev_end
    FROM   Staff_Shifts ss
    JOIN   Shifts s ON ss.shift_id = s.id
    WHERE  ss.staff_id = p_staff_id
      AND  get_shift_end(s.shift_date, s.shift_type) <= v_new_start
    ORDER BY get_shift_end(s.shift_date, s.shift_type) DESC
    LIMIT 1;

    SELECT get_shift_start(s.shift_date, s.shift_type)
    INTO   v_next_start
    FROM   Staff_Shifts ss
    JOIN   Shifts s ON ss.shift_id = s.id
    WHERE  ss.staff_id = p_staff_id
      AND  get_shift_start(s.shift_date, s.shift_type) >= v_new_end
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
    INTO   v_shift_date, v_shift_status
    FROM   Shifts
    WHERE  id = NEW.shift_id;

    SELECT staff_type INTO v_staff_type
    FROM   Staff
    WHERE  id = NEW.staff_id;

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
    FROM   Shifts
    WHERE  id = NEW.shift_id;

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
    FROM   Staff
    WHERE  id = NEW.staff_id;

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
    FROM   Staff
    WHERE  id = NEW.staff_id;

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
    FROM   Staff
    WHERE  id = NEW.staff_id;

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
    FROM   Hospitalizations
    WHERE  bed_id    = NEW.bed_id
      AND  exit_date IS NULL;

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
    FROM   Hospitalizations
    WHERE  id = NEW.hospitalization_id;

    IF v_exit_date IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Αξιολόγηση ιατρού επιτρέπεται μόνο για ολοκληρωμένες νοσηλείες.';
    END IF;
END$$

DELIMITER ;

-- DELIMITER $$

-- DROP EVENT IF EXISTS evt_check_daily_coverage$$

-- CREATE EVENT evt_check_daily_coverage
-- ON SCHEDULE EVERY 1 DAY
-- STARTS CURRENT_DATE + INTERVAL 1 DAY
-- DO
-- BEGIN
--     -- Εισάγει αυτόματα τις βάρδιες που λείπουν για κάθε τμήμα
--     INSERT IGNORE INTO Shifts (department_id, shift_type, shift_date, shift_status)
--     SELECT d.id, t.shift_type, CURRENT_DATE, 'scheduled'
--     FROM   Departments d
--     CROSS JOIN (
--         SELECT 'Morning'   AS shift_type UNION ALL
--         SELECT 'Afternoon' UNION ALL
--         SELECT 'Night'
--     ) t
--     WHERE NOT EXISTS (
--         SELECT 1 FROM Shifts s
--         WHERE  s.department_id = d.id
--           AND  s.shift_date    = CURRENT_DATE
--           AND  s.shift_type    = t.shift_type
--     );
-- END$$

-- DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_check_medical_act_conflicts$$

CREATE TRIGGER trg_check_medical_act_conflicts
BEFORE INSERT ON Medical_Acts
FOR EACH ROW
BEGIN
    DECLARE v_end_time      DATETIME;
    DECLARE v_room_conflict INT;
    DECLARE v_doctor_conflict INT;

    SET v_end_time = DATE_ADD(NEW.scheduled_time, INTERVAL NEW.duration_minutes MINUTE);

    SELECT COUNT(*) INTO v_room_conflict
    FROM   Medical_Acts
    WHERE  room_id = NEW.room_id
      AND  (
            -- Η νέα αρχίζει μέσα σε υπάρχουσα
            (NEW.scheduled_time >= scheduled_time 
             AND NEW.scheduled_time < DATE_ADD(scheduled_time, INTERVAL duration_minutes MINUTE))
            OR
            -- Η νέα τελειώνει μέσα σε υπάρχουσα
            (v_end_time > scheduled_time 
             AND v_end_time <= DATE_ADD(scheduled_time, INTERVAL duration_minutes MINUTE))
            OR
            -- Η νέα περιέχει εξολοκλήρου μια υπάρχουσα
            (NEW.scheduled_time <= scheduled_time 
             AND v_end_time >= DATE_ADD(scheduled_time, INTERVAL duration_minutes MINUTE))
           );

    IF v_room_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ο χώρος επέμβασης είναι ήδη κατειλημμένος αυτή την ώρα.';
    END IF;

    SELECT COUNT(*) INTO v_doctor_conflict
    FROM   Medical_Acts
    WHERE  main_doctor_id = NEW.main_doctor_id
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
    INTO   v_new_start, v_new_end
    FROM   Medical_Acts
    WHERE  id = NEW.act_id;

    SELECT COUNT(*) INTO v_conflict
    FROM   Medical_Act_Assistants maa
    JOIN   Medical_Acts ma ON maa.act_id = ma.id
    WHERE  maa.staff_id = NEW.staff_id
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
            SET v_extra_days  = v_actual_days - v_mdn_days;
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
