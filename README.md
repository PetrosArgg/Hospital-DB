# Υγειόπολης - Hospital DB
## Database Management Systems Project 2026 - NTUΑ

Welcome to the **Υγειόπολης** Hospital Management Database! This project models a fully functional general hospital, covering everything from patient admissions and staff scheduling to lab exams, medical acts, and billing. This repository contains all the necessary files for setting up and running the Υγειόπολης database, along with an interactive web app for exploring and visualizing the data.

## Overview

- **Database Management**: Uses MariaDB to store and manage all hospital data reliably.
- **Data Generation**: Real-world reference data (KEN codes, ICD-10 diagnoses, lab exams, medical acts and medications) is imported into the database from provided CSV files using Python. All the other data is generated and loaded using Python's Faker library.
- **Triggers**: Uses MariaDB triggers to automatically enforce business rules and keep the data consistent.
- **Web Interface**: A simple web app to browse hospital data, run queries, and view results.

## Core Features

- **Patient Management**: Store detailed information about patients, including personal data, allergies, triage status, and emergency contacts.
- **Staff Management**: Manage medical staff and admins in a role-based hierarchy, including a supervision chain among doctors.
- **Hospitalization Tracking**: Manage patient admissions and discharges, linked to ICD-10 diagnoses, KEN billing codes, lab exams, and medical acts.
- **Shift Scheduling**: Record and validate staff shift assignments, with triggers automatically checking staffing and rest-period rules.
- **Billing System**: Calculate hospitalization costs based on KEN rates, including extra daily charges for extended stays.

## Design Decisions

1. Patient age is not stored directly - it is computed dynamically from `birth_date`.
2. All staff share a common base record, while doctors, nurses, and admins each have their own table for role-specific data.
3. Each doctor can belong to one or more departments.
4. A patient may have multiple hospitalizations over time, but only one active at a time.
5. Diagnoses are recorded using real ICD-10 codes and billing is based on KEN codes - each with a base cost and an extra daily charge for stays that go beyond the median duration.
6. Shift rules are enforced automatically via triggers: every shift needs at least 3 doctors, 6 nurses, and 2 admins. Residents can't be scheduled without a senior doctor present. Each staff member is subject to monthly shift caps, an 8-hour minimum rest between shifts, and no more than 3 night shifts in a row.
7. Emergency contacts are stored in a separate table, apart from the patient record.

## Implementation

- **MariaDB 10.4.32** — Handles all data storage and management, and is used to run the project's SQL queries.
- **Python 3.14.3** — Used for developing the application and generating dummy data through the `fake_data.py` script.
- **Flask 3.0.3** — The web server framework.
- **Jinja2** — Used to dynamically generate HTML pages on the server side.
- **HTML/CSS** — Used to develop the user interface.
- **mysql-connector-python 8.4.0** — Python connector for MariaDB.
- **Faker 25.8.0** — Used to generate realistic dummy data.

## Setup

1. **Clone the repository**:
```bash
   git clone https://github.com/PetrosArgg/Hospital-DB.git
   cd Hospital-DB
```

2. **Initialize the database**:
   Import `install.sql` to create all tables, constraints, and triggers. To also load sample data, run `load.sql` as well.
```bash
   mysql -u root -p hospitaldb < install.sql
   mysql -u root -p hospitaldb < load.sql
```

3. **Install dependencies**:
```bash
   pip install -r requirements.txt
```

4. **Launch the app**:
```bash
   python app.py
```
   The app will be available at `http://127.0.0.1:5000`.
