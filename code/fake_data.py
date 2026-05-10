import random
import csv
import os
from faker import Faker
from datetime import timedelta, datetime

fake = Faker('el_GR')

NUM_DOCTORS = 80
NUM_NURSES = 50
NUM_ADMINS = 20
NUM_PATIENTS = 200
NUM_HOSPITALIZATIONS = 500
NUM_DEPARTMENTS = 14
NUM_BEDS = 100
NUM_PRESCRIPTIONS = 300
NUM_LAB_EXAMS = 200
NUM_OPERATING_ROOMS = 10
NUM_MEDICAL_ACTS = 150

RANKS_DOCTOR = ['Ειδικευόμενος', 'Επιμελητής Β΄', 'Επιμελητής Α΄', 'Διευθυντής']
RANKS_NURSE = ['Βοηθός Νοσηλευτή', 'Νοσηλευτής', 'Προϊστάμενος']
GENDERS = ['Male', 'Female', 'Other']
INSURANCE = ['ΕΦΚΑ', 'ιδιωτική ασφάλεια', 'ανασφάλιστος']

def escape_str(val):
    if val is None or val == r'\N' or val == '':
        return "NULL"
    if isinstance(val, (int, float)):
        return str(val)
    if isinstance(val, bool):
        return "TRUE" if val else "FALSE"
    # Escape single quotes for SQL
    return f"'{str(val).replace(chr(39), chr(39)+chr(39))}'"

def write_inserts(f, table_name, data):
    if not data: return
    f.write(f"INSERT INTO {table_name} VALUES\n")
    lines = []
    for row in data:
        lines.append("(" + ", ".join(escape_str(v) for v in row) + ")")
    f.write(",\n".join(lines) + ";\n\n")

# --- Reference Data Loading Functions ---
def load_icd10():
    data = []
    path = 'code/icd10.csv'
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8-sig') as f:
            reader = csv.reader(f, delimiter=';')
            for i, row in enumerate(reader, 1):
                if row and len(row) >= 2:
                    data.append([i, row[0].strip(), row[1].strip()])
    else:
        data.append([1, 'A00', 'Cholera'])
    return data

def load_ken_ref():
    data = []
    path = 'code/KEN_Ref.csv'
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8-sig') as f:
            reader = csv.reader(f, delimiter=';')
            next(reader, None) # skip header
            for i, row in enumerate(reader, 1):
                if row and len(row) >= 4:
                    code = row[0].strip().replace('\xa0', '')
                    if not code or code == '-': continue
                    # Cleanup cost string
                    cost_str = row[2].replace('€', '').replace('\xa0', '').replace(' ', '').replace('.', '').replace(',', '.')
                    try:
                        cost = float(cost_str)
                    except:
                        cost = 1000.0
                    days = int(row[3].strip()) if row[3].strip().isdigit() else 7
                    data.append([len(data)+1, code, cost, days])
    else:
        data.append([1, 'K01', 1500.0, 5])
    return data

def load_meds_and_subs():
    subs_map = {} # name -> id
    meds = [] # [id, product_name]
    bridge = [] # [med_id, sub_id]
    path = 'code/Medications.csv'
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8-sig') as f:
            reader = csv.reader(f, delimiter=';')
            # Skip metadata and header lines (exactly 16 lines for Medications.csv)
            for _ in range(16): next(reader, None)
            
            sub_id_counter = 1
            med_id_counter = 1
            for row in reader:
                if len(row) < 2: continue
                prod_name = row[0].strip()
                sub_name = row[1].strip()
                if not prod_name or 'Product name' in prod_name: continue
                
                if sub_name and sub_name not in subs_map:
                    subs_map[sub_name] = sub_id_counter
                    sub_id_counter += 1
                
                meds.append([med_id_counter, prod_name])
                if sub_name:
                    bridge.append([med_id_counter, subs_map[sub_name]])
                
                med_id_counter += 1
                if med_id_counter > 2000: break # Cap for speed/size
    else:
        subs_map = {'Paracetamol': 1}
        meds = [[1, 'Panadol']]
        bridge = [[1, 1]]
    
    subs_data = [[v, k] for k, v in subs_map.items()]
    return subs_data, meds, bridge

def load_split_refs(path, target_type):
    data = []
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8-sig') as f:
            reader = csv.reader(f, delimiter=';')
            # Skip 3 lines of headers
            for _ in range(3): next(reader, None) 
            for i, row in enumerate(reader, 1):
                if row and len(row) >= 3:
                    code = row[1].strip()
                    name = row[2].strip()
                    if not code: continue
                    if target_type == 'lab':
                        data.append([i, code, name, "Laboratory"])
                    else:
                        data.append([i, code, name, "Χειρουργική"])
    else:
        data.append([1, 'REF01', 'Default Ref', 'General'])
    return data

# --- Main Generation ---
icd10_ref = load_icd10()
ken_ref = load_ken_ref()
active_subs, medications, med_substances = load_meds_and_subs()
lab_ref = load_split_refs('code/LabExam_Ref.csv', 'lab')
medact_ref = load_split_refs('code/MedicalAct_Ref.csv', 'medact')

with open('load.sql', 'w', encoding='utf-8') as f:
    f.write("SET FOREIGN_KEY_CHECKS = 0;\n")
    f.write("SET NAMES utf8mb4;\n\n")

    write_inserts(f, 'Active_Substances', active_subs)
    write_inserts(f, 'Medications', medications)
    write_inserts(f, 'ICD10_Ref', icd10_ref)
    write_inserts(f, 'KEN_Ref', ken_ref)
    write_inserts(f, 'LabExam_Ref', lab_ref)
    write_inserts(f, 'MedicalAct_Ref', medact_ref)

    # Departments
    depts_data = []
    dept_names = ['Καρδιολογία', 'Χειρουργική', 'ΜΕΘ','Παθολογικό', 'Ορθοπεδικό', 'Παιδιατρικό', 'Νευρολογικό', 'Ουρολογικό', 'Οφθαλμολογικό', 'ΩΡΛ', 'Δερματολογικό', 'Γυναικολογικό', 'Ψυχιατρικό', 'Ακτινολογικό']
    for i in range(1, NUM_DEPARTMENTS + 1):
        depts_data.append([i, dept_names[i-1], f"Περιγραφή τμήματος {dept_names[i-1]}", random.randint(10, 40), f"Όροφος {random.randint(0,4)}", None, 3, 6, 2])
    write_inserts(f, 'Departments', depts_data)

    # Operating Rooms
    op_rooms = []
    for i in range(1, NUM_OPERATING_ROOMS + 1):
        op_rooms.append([i, f"Χειρουργείο {i}", "Γενική Χειρουργική"])
    write_inserts(f, 'Operating_Rooms', op_rooms)

    # Staff
    staff_data = []
    for i in range(1, NUM_DOCTORS + NUM_NURSES + NUM_ADMINS + 1):
        stype = 'doctor' if i <= NUM_DOCTORS else ('nurse' if i <= NUM_DOCTORS + NUM_NURSES else 'admin')
        staff_data.append([
            i, fake.numerify('###########'), fake.first_name(), fake.last_name(),
            fake.date_of_birth(minimum_age=25, maximum_age=65), fake.email(),
            fake.phone_number()[:15], fake.date_between(start_date='-10y', end_date='today'), stype,
            fake.date_time_this_month(), fake.date_time_this_month(), True
        ])
    write_inserts(f, 'Staff', staff_data)

    # Patients
    patients_data = []
    for i in range(1, NUM_PATIENTS + 1):
        patients_data.append([
            i, fake.numerify('###########'), fake.first_name(), fake.last_name(), fake.first_name(),
            fake.date_of_birth(minimum_age=1, maximum_age=95), random.choice(GENDERS),
            round(random.uniform(40, 120), 1), round(random.uniform(1.40, 2.00), 2),
            fake.address().replace('\n', ', '), fake.phone_number()[:15], fake.email(),
            fake.job(), 'Ελληνική', random.choice(INSURANCE),
            fake.date_time_this_month(), fake.date_time_this_month()
        ])
    write_inserts(f, 'Patients', patients_data)
    # Doctors (FK: Staff)
    doctors_data = []
    directors = list(range(1, 11))
    for i in range(1, NUM_DOCTORS + 1):
        lic = f"LIC-{1000+i}"
        spec = random.choice(['Καρδιολογία', 'Χειρουργική', 'ΜΕΘ', 'Επείγοντα'])
        if i in directors:
            rank, supervisor = 'Διευθυντής', None
        else:
            rank, supervisor = random.choice(['Επιμελητής Α΄', 'Επιμελητής Β΄', 'Ειδικευόμενος']), random.choice(directors)
        doctors_data.append([i, lic, spec, rank, supervisor])
    write_inserts(f, 'Doctors', doctors_data)

    # Nurses
    nurses_data = []
    for i in range(NUM_DOCTORS + 1, NUM_DOCTORS + NUM_NURSES + 1):
        nurses_data.append([i, random.choice(RANKS_NURSE), random.randint(1, NUM_DEPARTMENTS)])
    write_inserts(f, 'Nurses', nurses_data)

    # Admin Staff
    admins_data = []
    roles = ['Γραμματέας', 'Λογιστής', 'Υπάλληλος Γραφείου']
    for i in range(NUM_DOCTORS + NUM_NURSES + 1, NUM_DOCTORS + NUM_NURSES + NUM_ADMINS + 1):
        admins_data.append([i, random.choice(roles), f"Γραφείο {random.randint(101, 505)}", random.randint(1, NUM_DEPARTMENTS)])
    write_inserts(f, 'Administrative_Staff', admins_data)

    # Beds
    beds_data = []
    for i in range(1, NUM_BEDS + 1):
        beds_data.append([i, f"B{i:03d}", random.choice(['ΜΕΘ', 'μονόκλινο', 'πολύκλινο']), 'Διαθέσιμη', random.randint(1, NUM_DEPARTMENTS)])
    write_inserts(f, 'Beds', beds_data)

    # Emergency Contacts
    em_contacts = []
    for i in range(1, NUM_PATIENTS + 1):
        if random.random() > 0.3:
            em_contacts.append([i, i, fake.first_name(), fake.last_name(), fake.phone_number()[:15], random.choice(['Γονέας', 'Σύζυγος', 'Αδερφός'])])
    write_inserts(f, 'Emergency_Contacts', em_contacts)

    # Bridge Tables
    write_inserts(f, 'Medication_Substances', med_substances)
    
    allergies_data = []
    for p_id in range(1, NUM_PATIENTS + 1):
        if random.random() > 0.4:
            if active_subs:
                subs = random.sample(active_subs, min(len(active_subs), random.randint(1, 2)))
                for s in subs: allergies_data.append([p_id, s[0]])
    write_inserts(f, 'Patient_Allergies', allergies_data)

    # Doctor Departments
    doc_depts = []
    for i in range(1, NUM_DOCTORS + 1):
        doc_depts.append([i, random.randint(1, NUM_DEPARTMENTS)])
    write_inserts(f, 'Doctor_Departments', doc_depts)

    # Triage Entries
    triage_data = []
    for i in range(1, NUM_HOSPITALIZATIONS + 1):
        p_id = random.randint(1, NUM_PATIENTS)
        n_id = random.randint(NUM_DOCTORS + 1, NUM_DOCTORS + NUM_NURSES)
        arrival = fake.date_time_between(start_date='-1y', end_date='now')
        service = arrival + timedelta(minutes=random.randint(10, 60))
        triage_data.append([i, p_id, n_id, service, arrival, "Περιγραφή συμπτωμάτων...", random.randint(1, 5), 'Hospitalization'])
    write_inserts(f, 'Triage_Entries', triage_data)

    # Hospitalizations
    hosp_data = []
    icd_codes = [r[1] for r in icd10_ref]
    ken_codes = [r[1] for r in ken_ref]
    for i in range(1, NUM_HOSPITALIZATIONS + 1):
        tr = triage_data[i-1]
        p_id, entry = tr[1], tr[4]
        exit_d = entry + timedelta(days=random.randint(1, 15))
        hosp_data.append([i, p_id, random.randint(1, NUM_BEDS), random.randint(1, NUM_DEPARTMENTS), entry, exit_d, random.choice(icd_codes), random.choice(icd_codes), random.choice(ken_codes), round(random.uniform(500, 5000), 2), i])
    write_inserts(f, 'Hospitalizations', hosp_data)

    # Shifts
    shifts_data = []
    for d in range(1, NUM_DEPARTMENTS + 1):
        for day in range(30):
            date = datetime.now().date() - timedelta(days=day)
            for stype in ['Morning', 'Afternoon', 'Night']:
                shifts_data.append([len(shifts_data)+1, d, stype, date, datetime.now(), datetime.now(), 'completed'])
    write_inserts(f, 'Shifts', shifts_data)

    # Shift Monthly Limits
    ml_data = []
    for s_id in range(1, NUM_DOCTORS + NUM_NURSES + NUM_ADMINS + 1):
        ml_data.append([s_id, s_id, 2026, 5, 20])
    write_inserts(f, 'Shift_Monthly_Limits', ml_data)

    # Lab Exams
    lab_exams = []
    lab_codes = [r[1] for r in lab_ref]
    for i in range(1, NUM_LAB_EXAMS + 1):
        h_id = random.randint(1, NUM_HOSPITALIZATIONS)
        lab_exams.append([i, random.choice(lab_codes), fake.date_time_this_year(), "Φυσιολογικό", 5.0, "mg/dL", 30.0, random.randint(1, NUM_DOCTORS), h_id])
    write_inserts(f, 'LabExam', lab_exams)

    # Medical Acts
    medical_acts = []
    act_codes = [r[1] for r in medact_ref]
    for i in range(1, NUM_MEDICAL_ACTS + 1):
        h_id = random.randint(1, NUM_HOSPITALIZATIONS)
        medical_acts.append([i, random.choice(act_codes), random.randint(30, 180), 600.0, fake.date_time_this_year(), h_id, random.randint(1, NUM_OPERATING_ROOMS), random.randint(1, NUM_DOCTORS)])
    write_inserts(f, 'Medical_Acts', medical_acts)

    # Prescriptions
    presc_data = []
    med_ids = [m[0] for m in medications]
    for i in range(1, NUM_PRESCRIPTIONS + 1):
        h_id = random.randint(1, NUM_HOSPITALIZATIONS)
        p_id = hosp_data[h_id-1][1]
        presc_data.append([i, random.randint(1, NUM_DOCTORS), p_id, random.choice(med_ids), h_id, fake.date_this_year(), fake.date_this_year(), "1 χάπι", "8 ώρες"])
    write_inserts(f, 'Prescriptions', presc_data)

    # Ratings
    hosp_ratings = []
    for i in range(1, NUM_HOSPITALIZATIONS + 1):
        if random.random() > 0.5:
            hosp_ratings.append([i, random.randint(3,5), random.randint(3,5), random.randint(3,5), random.randint(3,5)])
    write_inserts(f, 'Hospitalization_Ratings', hosp_ratings)

    # Images
    images_data = []
    for i in range(1, 51):
        target = random.choice(['doctor', 'nurse', 'admin', 'dept', 'room'])
        row = [i, f"http://example.com/img{i}.jpg", "Description", None, None, None, None, None]
        if target == 'doctor': row[3] = random.randint(1, NUM_DOCTORS)
        elif target == 'nurse': row[4] = random.randint(NUM_DOCTORS+1, NUM_DOCTORS+NUM_NURSES)
        elif target == 'admin': row[5] = random.randint(NUM_DOCTORS+NUM_NURSES+1, NUM_DOCTORS+NUM_NURSES+NUM_ADMINS)
        elif target == 'dept': row[6] = random.randint(1, NUM_DEPARTMENTS)
        else: row[7] = random.randint(1, NUM_OPERATING_ROOMS)
        images_data.append(row)
    write_inserts(f, 'Images', images_data)

    staff_shifts = []
    for s_id in range(1, len(shifts_data) + 1):
        if random.random() > 0.7: # Sample some shifts
            staff_shifts.append([random.randint(1, NUM_DOCTORS+NUM_NURSES+NUM_ADMINS), s_id, "08:00", "16:00", fake.date_this_month()])
    write_inserts(f, 'Staff_Shifts', staff_shifts)

    # Medical Act Assistants
    act_assts = []
    for i in range(1, NUM_MEDICAL_ACTS + 1):
        act_assts.append([i, random.randint(NUM_DOCTORS+1, NUM_DOCTORS+NUM_NURSES)])
    write_inserts(f, 'Medical_Act_Assistants', act_assts)

    f.write("SET FOREIGN_KEY_CHECKS = 1;\n")