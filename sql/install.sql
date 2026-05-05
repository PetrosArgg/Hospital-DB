-- Database creation
-- CREATE DATABASE `hospital_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;
DROP DATABASE IF EXISTS hospitaldb;
CREATE DATABASE hospitaldb;
use hospitaldb;

-- Tables Creation
CREATE TABLE Staff (
    -- Maybe it staff type will be needed for checking if shifts are valid
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'The internal table id, primary key', 
    amka CHAR(11) NOT NULL UNIQUE, 
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15),
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
    father_name VARCHAR(50),
    birth_date DATE NOT NULL,
    gender VARCHAR(10) NOT NULL,
    weight DECIMAL(5,2),
    height DECIMAL(3,2),
    address VARCHAR(255),
    phone VARCHAR(15),
    email VARCHAR(100),
    profession VARCHAR(100),
    nationality VARCHAR(50),
    insurance_provider VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT chk_gender CHECK (gender IN ('Male', 'Female', 'Other'))
);

CREATE TABLE Doctors (
    staff_id INT PRIMARY KEY,
    license_number VARCHAR(20) NOT NULL UNIQUE,    
    specialty VARCHAR(50) NOT NULL,
    rank VARCHAR(30) NOT NULL,    
    supervisor_id INT,

    FOREIGN KEY (staff_id) REFERENCES Staff(id) ON DELETE CASCADE,
    FOREIGN KEY (supervisor_id) REFERENCES Doctors(staff_id),

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
    FOREIGN KEY (department_id) REFERENCES Departments(id),
    
    CONSTRAINT chk_nurse_rank CHECK (rank IN ('Βοηθός Νοσηλευτή', 'Νοσηλευτής', 'Προϊστάμενος'))
);

CREATE TABLE Administrative_Staff (
    staff_id INT PRIMARY KEY,
    duty_role VARCHAR(100) NOT NULL,
    office_location VARCHAR(50),    
    department_id INT NOT NULL,    
    FOREIGN KEY (staff_id) REFERENCES Staff(id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES Departments(id)
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

    FOREIGN KEY (department_id) REFERENCES Departments(id) ON DELETE CASCADE,
    
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
    arrival_time DATETIME NOT NULL,
    symptoms TEXT,
    urgency_level INT CHECK (urgency_level BETWEEN 1 AND 5),
    referral_status VARCHAR(50),
    FOREIGN KEY (patient_id) REFERENCES Patients(id) ON DELETE CASCADE,
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
    
    FOREIGN KEY (patient_id) REFERENCES Patients(id),
    FOREIGN KEY (bed_id) REFERENCES Beds(id),
    FOREIGN KEY (department_id) REFERENCES Departments(id),
    FOREIGN KEY (icd10_entry_code) REFERENCES ICD10_Ref(code),
    FOREIGN KEY (icd10_exit_code) REFERENCES ICD10_Ref(code),
    FOREIGN KEY (ken_code) REFERENCES KEN_Ref(code),
    FOREIGN KEY (triage_id) REFERENCES Triage_Entries(id)
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
    FOREIGN KEY (substance_id) REFERENCES Active_Substances(id) ON DELETE CASCADE
);

CREATE TABLE Patient_Allergies (
    patient_id INT NOT NULL,
    substance_id INT NOT NULL,
    PRIMARY KEY (patient_id, substance_id),
    FOREIGN KEY (patient_id) REFERENCES Patients(id) ON DELETE CASCADE,
    FOREIGN KEY (substance_id) REFERENCES Active_Substances(id) ON DELETE CASCADE
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
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT,
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
    FOREIGN KEY (staff_id) REFERENCES Staff(id),
    FOREIGN KEY (shift_id) REFERENCES Shifts(id)
);

CREATE TABLE Shift_Monthly_Limits (
    id INT PRIMARY KEY AUTO_INCREMENT,
    staff_id INT NOT NULL,
    ml_year INT NOT NULL,
    ml_month INT NOT NULL CHECK (ml_month BETWEEN 1 AND 12),
    ml_num INT DEFAULT 0,
    FOREIGN KEY (staff_id) REFERENCES staff(id) ON DELETE CASCADE,
    UNIQUE KEY staff_ml_month (staff_id, ml_year, ml_month)
);



CREATE TABLE Prescriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id INT NOT NULL,
    patient_amka CHAR(11) NOT NULL,
    medication_id INT NOT NULL,
    hospitalization_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    dosage VARCHAR(50),
    frequency VARCHAR(50),
    FOREIGN KEY (doctor_id) REFERENCES Doctors(staff_id),
    FOREIGN KEY (patient_amka) REFERENCES Patients(amka),
    FOREIGN KEY (medication_id) REFERENCES Medications(id),
    FOREIGN KEY (hospitalization_id) REFERENCES Hospitalizations(id),
    UNIQUE KEY unique_prescription (doctor_id, patient_amka, medication_id, start_date)
);

CREATE TABLE Images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    image_url VARCHAR(255) NOT NULL,
    description TEXT,
    doctor_id INT,
    department_id INT,
    FOREIGN KEY (doctor_id) REFERENCES Doctors(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES Departments(id) ON DELETE CASCADE
);

-- Προσθέτω πίνακα για τους κωδικούς των εξετάσεων
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
    FOREIGN KEY (code) REFERENCES LabExam_Ref(code),
    FOREIGN KEY (doctor_id) REFERENCES Doctors(staff_id) ON DELETE SET NULL,
    FOREIGN KEY (hospitalization_id) REFERENCES Hospitalizations(id) ON DELETE CASCADE
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
    FOREIGN KEY (hospitalization_id) REFERENCES Hospitalizations(id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES Operating_Rooms(id),
    FOREIGN KEY (main_doctor_id) REFERENCES Doctors(staff_id),
    FOREIGN KEY (act_code) REFERENCES MedicalAct_Ref(code)
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
    medical_care_quality INT CHECK (medical_care_quality BETWEEN 1 AND 5),
    nursing_care_quality TINYINT CHECK (nursing_care_quality BETWEEN 1 AND 5),
    cleanliness TINYINT CHECK (cleanliness BETWEEN 1 AND 5),
    food_quality TINYINT CHECK (food_quality BETWEEN 1 AND 5),
    overall_experience TINYINT CHECK (overall_experience BETWEEN 1 AND 5),
    FOREIGN KEY (hospitalization_id) REFERENCES Hospitalizations(id) ON DELETE CASCADE
);

CREATE TABLE Doctor_Ratings (
    hospitalization_id INT,
    doctor_id INT,
    medical_care_quality TINYINT CHECK (medical_care_quality BETWEEN 1 AND 5),
    PRIMARY KEY (hospitalization_id, doctor_id),
    FOREIGN KEY (hospitalization_id) REFERENCES Hospitalizations(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES Doctors(staff_id) ON DELETE CASCADE
);

CREATE INDEX idx_patients_name ON Patients (last_name, first_name);
CREATE INDEX idx_staff_name ON Staff (last_name, first_name);

CREATE INDEX idx_hospitalizations_entry ON Hospitalizations (entry_date);
CREATE INDEX idx_hospitalizations_exit ON Hospitalizations (exit_date);

CREATE INDEX idx_medical_acts_time ON Medical_Acts (scheduled_time);

CREATE INDEX idx_prescriptions_dates ON Prescriptions (start_date, end_date);
CREATE INDEX idx_labexam_date ON LabExam (exam_date);

CREATE INDEX idx_beds_status ON Beds (status);

CREATE INDEX idx_triage_arrival ON Triage_Entries (arrival_time);

CREATE INDEX idx_shifts_date ON Shifts (shift_date);


-- FUNCTIONS
-- Fuction to detect cycles in supervising doctors
DROP FUNCTION IF EXISTS has_cycle;

CREATE FUNCTION has_cycle(new_doctor_id INT, supervisor_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE current_id INT;
    DECLARE depth INT DEFAULT 0;
    SET current_id = supervisor_id;

    WHILE current_id IS NOT NULL AND depth < 100 DO --change 100 later if needs modification i
        IF current_id = new_doctor_id THEN
            RETURN TRUE;
        END IF;

        SELECT d.supervisor_id INTO current_id
        FROM Doctors d
        WHERE d.staff_id = current_id;

        SET depth = depth + 1;
    END WHILE;

    RETURN FALSE; -- there isn't any cycle
END;

DROP TRIGGER IF EXISTS trg_doctor_insert_no_cycle;

CREATE TRIGGER trg_doctor_insert_no_cycle
BEFORE INSERT ON Doctors
FOR EACH ROW
BEGIN
    IF NEW.supervisor_id IS NOT NULL THEN
        IF has_cycle(NEW.staff_id, NEW.supervisor_id) THEN
            SIGNAL SQLSTATE '45000' --45000 is generic error from user
                SET MESSAGE_TEXT = 'Απαγορευμένη κυκλική αλυσίδα εποπτείας.';
        END IF;
    END IF;
END;

DROP TRIGGER IF EXISTS trg_doctor_update_no_cycle;

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
END;
    
    DROP TRIGGER IF EXISTS trg_check_allergy_before_prescription //

CREATE TRIGGER trg_check_allergy_before_prescription
BEFORE INSERT ON Prescriptions
FOR EACH ROW
BEGIN
    DECLARE allergy_count INT;

    SELECT COUNT(*) INTO allergy_count
    FROM Patient_Allergies pa
    JOIN Medication_Substances ms ON pa.substance_id = ms.substance_id
    WHERE pa.patient_amka = NEW.patient_amka
      AND ms.medication_id = NEW.medication_id;

    IF allergy_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ΑΚΥΡΩΣΗ ΣΥΝΤΑΓΟΓΡΑΦΗΣΗΣ: Ο ασθενής είναι αλλεργικός σε κάποια δραστική ουσία αυτού του φαρμάκου.';
    END IF;
END 

DELIMITER $$

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

    -- (μετράει +1 τον νέο)
    IF check_min_staff_per_shift(NEW.shift_id, v_staff_type) = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Η βάρδια δεν πληροί τον ελάχιστο αριθμό προσωπικού.';
    END IF;

    -- (μετράει +1 τον νέο)
    IF check_resident_supervisor(NEW.shift_id, NEW.staff_id) = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Παρουσία ειδικευόμενου χωρίς Επιμελητή Α΄ ή Διευθυντή στη βάρδια.';
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