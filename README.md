# Υγειόπολης - Hospital DB
## Database Management Systems Project 2026 - NTUΑ

Welcome to the **Υγειόπολης** Hospital Management Database! This project models a fully functional general hospital, covering everything from patient admissions and staff scheduling to lab exams, medical acts, and billing. This repository contains all the necessary files for setting up and running the Υγειόπολης database, along with an interactive web app for exploring and visualizing the data.

## Overview

- **Database Management**: Uses MariaDB to store and manage all hospital data reliably.
- **Data Generation**: Includes a Python script using Faker to create and load dummy data for testing and development.
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

### Technologies Used

- **MariaDB**:  Handles all data storage and management. It is also used to run the project's SQL queries.
- **Python**: Used for developing the application and generating dummy data through the `fake_data.py` script.
- **Flask**: The web server was created using Flask, a micro web framework for Python.
- **Jinja2**: Used to dynamically generate HTML pages on the server side.
- **HTML/CSS**: Used to develop the user interface.

### Tech Stack

- **Python 3.14.3**
- **Flask 3.0.3**
- **MariaDB 10.4.32**
- **mysql-connector-python 8.4.0**
- **Faker 25.8.0**

## Setup

1. **Clone the repository**:

   ```bash
   git clone https://github.com/PetrosArgg/Hospital-DB.git
   cd Hospital-DB
   ```

2. **Set up the MariaDB database**:

   Create a MariaDB database and import the `install.sql` file to set up all tables, constraints, and triggers. Optionally, import `load.sql` to populate the database with dummy data.

   ```bash
   mysql -u root -p ygeiopolis < install.sql
   mysql -u root -p ygeiopolis < load.sql
   ```

3. **Install the required Python libraries**:

   ```bash
   pip install -r requirements.txt
   ```

4. **Run the app**:

   ```bash
   python app.py
   ```

   Open your browser and visit `http://127.0.0.1:5000` to start interacting with our hospital database.
