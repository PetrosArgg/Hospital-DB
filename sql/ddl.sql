-- Database creation
-- CREATE DATABASE `hospital_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;
DROP DATABASE IF EXISTS hospitaldb;
CREATE DATABASE hospitaldb;
use hospitaldb;

-- Tables Creation
CREATE TABLE Staff (
    id INT AUTO_INCREMENT PRIMARY KEY, 
    amka CHAR(11) NOT NULL, 
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL,
    email VARCHAR(255) NOT NULL,
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
    amka CHAR(11) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    father_name VARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL,
    gender VARCHAR(10) NOT NULL,
    weight DECIMAL(5,2) NOT NULL,
    height DECIMAL(3,2) NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(255),
    profession VARCHAR(255),
    nationality VARCHAR(50) NOT NULL,
    insurance_provider VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT chk_gender CHECK (gender IN ('Male', 'Female', 'Other'))
);

CREATE TABLE Doctors (
    staff_id INT PRIMARY KEY,
    license_number VARCHAR(20) NOT NULL,    
    specialty VARCHAR(50),
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
    name VARCHAR(100) NOT NULL, 
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
    bed_number VARCHAR(20) NOT NULL,
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
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(100) NOT NULL,
    base_cost DECIMAL(10,2) NOT NULL,
    mdn_days INT NOT NULL,
    INDEX (code)
);

CREATE TABLE ICD10_Ref (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    INDEX (code)
);

CREATE TABLE Triage_Entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    nurse_id INT NOT NULL,
    service_time DATETIME,
    arrival_time DATETIME NOT NULL,
    symptoms TEXT NOT NULL,
    urgency_level INT NOT NULL CHECK (urgency_level BETWEEN 1 AND 5),
    referral_status VARCHAR(50) NOT NULL,
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
    icd10_entry_code VARCHAR(100),
    icd10_exit_code VARCHAR(100),
    ken_code VARCHAR(100),
    total_cost DECIMAL(10,2),
    triage_id INT NOT NULL UNIQUE,
    
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
    substance_name TEXT
);

CREATE TABLE Medications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_name TEXT
);

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
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(100) NOT NULL,
    name TEXT,
    category VARCHAR(255) NOT NULL,
    INDEX (code),
    CONSTRAINT chk_lab_ref_category
    CHECK (category IN (
        'Γ. ΑΠΕΙΚΟΝΙΣΗ – ΕΠΕΜΒΑΤΙΚΕΣ ΚΑΙ ΘΕΡΑΠΕΥΤΙΚΕΣ ΑΚΤΙΝΙΚΕΣ ΠΡΑΞΕΙΣ',
        'Δ. ΠΡΑΞΕΙΣ ΒΙΟΠΑΘΟΛΟΓΙΑΣ',
        'Ε. ΠΡΑΞΕΙΣ ΙΑΤΡΟΔΙΚΑΣΤΙΚΗΣ – ΠΑΘΟΛΟΓΙΚΗΣ ΑΝΑΤΟΜΙΚΗΣ – ΚΥΤΤΑΡΟΛΟΓΙΑΣ'
    ))
);

CREATE TABLE LabExam (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(100) NOT NULL,
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
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(100) NOT NULL,
    name TEXT,
    category VARCHAR(255) NOT NULL,
    INDEX (code),
    CONSTRAINT chk_act_ref_category
    CHECK (category IN (
        'Α. ΠΡΑΞΕΙΣ ΑΙΝΑΙΣΘΗΣΙΑΣ',
        'Β. ΠΡΑΞΕΙΣ ΧΕΙΡΟΥΡΓΙΚΕΣ – ΕΠΕΜΒΑΤΙΚΕΣ – ΕΝΔΟΣΚΟΠΙΚΕΣ'
    ))
);

CREATE TABLE Medical_Acts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    act_code VARCHAR(100) NOT NULL, 
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
    room_id INT,

    FOREIGN KEY (doctor_id) REFERENCES Doctors(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (nurse_id) REFERENCES Nurses(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (admin_id) REFERENCES Administrative_Staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES Departments(id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES Operating_Rooms(id) ON DELETE CASCADE,

    CONSTRAINT chk_image_entity CHECK (
        (doctor_id IS NOT NULL) +
        (nurse_id IS NOT NULL) +
        (admin_id IS NOT NULL) +
        (department_id IS NOT NULL) +
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