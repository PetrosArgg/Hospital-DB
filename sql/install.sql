-- Database creation
-- CREATE DATABASE `hospital_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;
use hospital_db;

-- Tables Creation
CREATE TABLE Staff (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'The internal table id, priimary key', 
    amka CHAR(11) NOT NULL UNIQUE, 
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15),
    hire_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    
)

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
    -- Check how to forbid chain in supervising. Maybe I need triger
    -- Check also DepartmentsDoctors
);

CREATE TABLE Nurses (
    staff_id INT PRIMARY KEY,
    rank VARCHAR(50) NOT NULL,
    department_id INT NOT NULL,
    FOREIGN KEY (staff_id) REFERENCES Staff(id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES Departments(id)
    
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

CREATE TABLE Departments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE, 
    description TEXT, 
    bed_count INT NOT NULL DEFAULT 0, 
    location VARCHAR(100),
    head_doctor_id INT, 
    
    FOREIGN KEY (head_doctor_id) REFERENCES Doctors(staff_id) ON DELETE SET NULL
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
    status VARCHAR(50) NOT NULL DEFAULT 'Available',
    department_id INT NOT NULL,

    FOREIGN KEY (department_id) REFERENCES Departments(id) ON DELETE CASCADE,
    
    --CONSTRAINT chk_bed_type CHECK (bed_type IN ('ΜΕΘ', 'μονόκλινο', 'πολύκλινο')),
    
    CONSTRAINT chk_bed_status CHECK (status IN ('διαθέσιμη', 'κατειλημμένη', 'υπό συντήρηση')),
);