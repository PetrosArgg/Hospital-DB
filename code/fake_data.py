import random
import csv
import os
from faker import Faker
from datetime import timedelta

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

ranks_doctor = ['Ειδικευόμενος', 'Επιμελητής Β΄', 'Επιμελητής Α΄', 'Διευθυντής']
ranks_nurse = ['Βοηθός Νοσηλευτή', 'Νοσηλευτής', 'Προϊστάμενος']
genders = ['Male', 'Female', 'Other']
insurance = ['ΕΦΚΑ', 'ιδιωτική ασφάλεια', 'ανασφάλιστος']



def load_ids_from_csv(filename, col_index=0):
    ids = []
    if os.path.exists(filename):
        with open(filename, 'r', encoding='utf-8') as f:
            reader = csv.reader(f, delimiter=';')
            next(reader, None) # skip header
            for row in reader:
                if row and len(row) > col_index:
                    ids.append(row[col_index])
    return ids

# Φορτώνουμε τους πραγματικούς κωδικούς (αν υπάρχουν τα αρχεία)
icd10_codes = load_ids_from_csv('icd10.csv', 0)
if not icd10_codes: icd10_codes = load_ids_from_csv('ICD10_Ref.csv', 0)
if not icd10_codes: icd10_codes = ['A00']

ken_codes = load_ids_from_csv('KEN_Ref.csv', 0)
if not ken_codes: ken_codes = ['KEN01']

lab_codes = load_ids_from_csv('LabExam_Ref.csv', 0)
if not lab_codes: lab_codes = ['LAB01']

act_codes = load_ids_from_csv('MedicalAct_Ref.csv', 0)
if not act_codes: act_codes = ['ACT01']

substance_ids = load_ids_from_csv('Active_Substances.csv', 0)
if not substance_ids: substance_ids = list(range(1, 21))

medication_ids = load_ids_from_csv('Medications.csv', 0)
if not medication_ids: medication_ids = list(range(1, 51))

def escape_str(val):
    if val is None or val == r'\N':
        return "NULL"
    if isinstance(val, (int, float)):
        return str(val)
    # Escape single quotes for SQL
    return f"'{str(val).replace(chr(39), chr(39)+chr(39))}'"

def write_inserts(f, table_name, data):
    if not data: return
    f.write(f"INSERT INTO {table_name} VALUES\n")
    lines = []
    for row in data:
        lines.append("(" + ", ".join(escape_str(v) for v in row) + ")")
    f.write(",\n".join(lines) + ";\n\n")

with open('fake_data_inserts.sql', 'w', encoding='utf-8') as f:
    f.write("SET FOREIGN_KEY_CHECKS = 0;\n")
    f.write("SET NAMES utf8mb4;\n\n")

    # Departments
    depts_data = []
    names = ['Καρδιολογία', 'Χειρουργική', 'ΜΕΘ','Παθολογικό', 'Ορθοπεδικό', 'Παιδιατρικό', 'Νευρολογικό', 'Ουρολογικό', 'Οφθαλμολογικό', 'ΩΡΛ', 'Δερματολογικό', 'Γυναικολογικό', 'Ψυχιατρικό', 'Ακτινολογικό']
    for i in range(1, NUM_DEPARTMENTS + 1):
        depts_data.append([i, names[i-1], f"Περιγραφή τμήματος {names[i-1]}", random.randint(10, 40), f"Όροφος {random.randint(0,4)}", random.randint(1, 10), 3, 6, 2])
    write_inserts(f, 'Departments', depts_data)

    # Operating Rooms
    op_rooms = []
    for i in range(1, NUM_OPERATING_ROOMS + 1):
        op_rooms.append([i, f"Χειρουργείο {i}", "Γενική Χειρουργική"])
    write_inserts(f, 'Operating_Rooms', op_rooms)

    # Beds
    beds_data = []
    for i in range(1, NUM_BEDS + 1):
        beds_data.append([i, f"B{i:03d}", random.choice(['ΜΕΘ', 'μονόκλινο', 'πολύκλινο']), 'Διαθέσιμη', random.randint(1, NUM_DEPARTMENTS)])
    write_inserts(f, 'Beds', beds_data)

    # Staff
    staff_data = []
    for i in range(1, NUM_DOCTORS + NUM_NURSES + NUM_ADMINS + 1):
        stype = 'doctor' if i <= NUM_DOCTORS else ('nurse' if i <= NUM_DOCTORS + NUM_NURSES else 'admin')
        staff_data.append([
            i, fake.numerify('###########'), fake.first_name(), fake.last_name(),
            fake.date_of_birth(minimum_age=25, maximum_age=65), fake.unique.email(),
            fake.phone_number()[:15], fake.date_between(start_date='-10y', end_date='today'), stype,
            fake.date_time_this_month(), fake.date_time_this_month(), 1
        ])
    write_inserts(f, 'Staff', staff_data)

    # Doctors
    doctors_data = []
    directors = list(range(1, 11))
    others = list(range(11, 61))
    residents = list(range(61, 81))
    for i in range(1, NUM_DOCTORS + 1):
        license = f"LIC-{1000+i}"
        spec = random.choice(['Καρδιολογία', 'Χειρουργική', 'ΜΕΘ', 'Επείγοντα'])
        if i in directors:
            rank, supervisor = 'Διευθυντής', None
        elif i in residents:
            rank, supervisor = 'Ειδικευόμενος', random.choice(directors + others)
        else:
            rank, supervisor = random.choice(['Επιμελητής Α΄', 'Επιμελητής Β΄']), random.choice(directors)
        doctors_data.append([i, license, spec, rank, supervisor])
    write_inserts(f, 'Doctors', doctors_data)

    # Nurses
    nurses_data = []
    for i in range(NUM_DOCTORS + 1, NUM_DOCTORS + NUM_NURSES + 1):
        nurses_data.append([i, random.choice(ranks_nurse), random.randint(1, NUM_DEPARTMENTS)])
    write_inserts(f, 'Nurses', nurses_data)

    # Administrative_Staff
    admins_data = []
    duty_roles = ['Γραμματέας', 'Λογιστής', 'Υπάλληλος Γραφείου', 'Υπεύθυνος Ανθρώπινου Δυναμικού']
    for i in range(NUM_DOCTORS + NUM_NURSES + 1, NUM_DOCTORS + NUM_NURSES + NUM_ADMINS + 1):
        admins_data.append([i, random.choice(duty_roles), f"Γραφείο {random.randint(101, 505)}", random.randint(1, NUM_DEPARTMENTS)])
    write_inserts(f, 'Administrative_Staff', admins_data)

    # Patients
    patients_data = []
    for i in range(1, NUM_PATIENTS + 1):
        patients_data.append([
            i, fake.numerify('###########'), fake.first_name(), fake.last_name(), fake.first_name(),
            fake.date_of_birth(minimum_age=1, maximum_age=95), random.choice(genders),
            round(random.uniform(40, 120), 1), round(random.uniform(1.40, 2.00), 2),
            fake.address().replace('\n', ', '), fake.phone_number()[:15], fake.email(),
            fake.job(), 'Ελληνική', random.choice(insurance),
            fake.date_time_this_month(), fake.date_time_this_month()
        ])
    write_inserts(f, 'Patients', patients_data)

    # Patient_Allergies
    allergic_patients = random.sample(range(1, NUM_PATIENTS + 1), int(NUM_PATIENTS * 0.4))
    allergies_data = []
    for p_id in allergic_patients:
        num_allergies = random.randint(1, 3)
        # Χρησιμοποιεί τους πραγματικούς κωδικούς ουσιών
        substances = random.sample(substance_ids, min(num_allergies, len(substance_ids)))
        for s_id in substances:
            allergies_data.append([p_id, s_id])
    write_inserts(f, 'Patient_Allergies', allergies_data)

    # Triage_Entries
    triage_data = []
    for i in range(1, NUM_HOSPITALIZATIONS + 1):
        p_id = random.randint(1, NUM_PATIENTS)
        arrival = fake.date_time_between(start_date='-2y', end_date='now')
        level = random.randint(1, 5)
        triage_data.append([i, p_id, arrival, "Συμπτώματα ασθενούς...", level, 'Hospitalization'])
    write_inserts(f, 'Triage_Entries', triage_data)

    # Hospitalizations
    hosp_data = []
    for i in range(1, NUM_HOSPITALIZATIONS + 1):
        p_id = triage_data[i-1][1]
        entry = triage_data[i-1][2]
        exit_d = fake.date_time_between(start_date=entry, end_date=entry + timedelta(days=20))
        icd_entry = random.choice(icd10_codes)
        icd_exit = random.choice(icd10_codes)
        ken = random.choice(ken_codes)
        hosp_data.append([i, p_id, random.randint(1, NUM_BEDS), random.randint(1, NUM_DEPARTMENTS), entry, exit_d, icd_entry, icd_exit, ken, round(random.uniform(500, 5000), 2), i])
    write_inserts(f, 'Hospitalizations', hosp_data)

    # Doctor_Departments
    doc_depts = []
    for i in range(1, NUM_DOCTORS + 1):
        doc_depts.append([i, random.randint(1, NUM_DEPARTMENTS)])
    write_inserts(f, 'Doctor_Departments', doc_depts)

    # Emergency_Contacts
    em_contacts = []
    for i in range(1, NUM_PATIENTS + 1):
        if random.random() > 0.3:
            em_contacts.append([i, i, fake.first_name(), fake.last_name(), fake.phone_number()[:15], random.choice(['Γονέας', 'Σύζυγος', 'Αδερφός'])])
    write_inserts(f, 'Emergency_Contacts', em_contacts)

    # Medication_Substances
    med_substances = []
    for i in medication_ids:
        num_sub = random.randint(1, 2)
        subs = random.sample(substance_ids, min(num_sub, len(substance_ids)))
        for s in subs:
            med_substances.append([i, s])
    write_inserts(f, 'Medication_Substances', med_substances)

    # Prescriptions
    prescriptions = []
    prescribing_docs_by_hosp = {}
    seen_presc = set()
    i = 1
    while i <= NUM_PRESCRIPTIONS:
        hosp_id = random.randint(1, NUM_HOSPITALIZATIONS)
        p_id = hosp_data[hosp_id - 1][1]  # patient_id from hosp_data
        doc_id = random.randint(1, NUM_DOCTORS)
        med_id = random.choice(medication_ids)
        start_d = fake.date_this_year()
        
        unique_key = (doc_id, p_id, med_id, start_d)
        if unique_key not in seen_presc:
            seen_presc.add(unique_key)
            if hosp_id not in prescribing_docs_by_hosp:
                prescribing_docs_by_hosp[hosp_id] = []
            prescribing_docs_by_hosp[hosp_id].append(doc_id)
            
            end_d = start_d + timedelta(days=random.randint(5, 30))
            prescriptions.append([i, doc_id, p_id, med_id, hosp_id, start_d, end_d, "1 χάπι", "Κάθε 8 ώρες"])
            i += 1
    write_inserts(f, 'Prescriptions', prescriptions)

    # LabExam
    lab_exams = []
    for i in range(1, NUM_LAB_EXAMS + 1):
        lab = random.choice(lab_codes)
        lab_exams.append([i, lab, fake.date_time_this_year(), "Φυσιολογικό", 5.5, "mg/dL", 25.00, random.randint(1, NUM_DOCTORS), random.randint(1, NUM_HOSPITALIZATIONS)])
    write_inserts(f, 'LabExam', lab_exams)

    # Medical_Acts
    medical_acts = []
    for i in range(1, NUM_MEDICAL_ACTS + 1):
        sched = fake.date_time_this_year()
        act = random.choice(act_codes)
        medical_acts.append([i, act, random.randint(30, 180), 500.00, sched, random.randint(1, NUM_HOSPITALIZATIONS), random.randint(1, NUM_OPERATING_ROOMS), random.randint(1, NUM_DOCTORS)])
    write_inserts(f, 'Medical_Acts', medical_acts)

    # Medical_Act_Assistants
    act_assistants = []
    for i in range(1, NUM_MEDICAL_ACTS + 1):
        act_assistants.append([i, random.randint(NUM_DOCTORS+1, NUM_DOCTORS+NUM_NURSES)])
    write_inserts(f, 'Medical_Act_Assistants', act_assistants)

    # Shifts
    shifts = []
    shift_id = 1
    for dept in range(1, NUM_DEPARTMENTS + 1):
        shifts.append([shift_id, dept, 'Morning', fake.date_this_month(), fake.date_time_this_month(), fake.date_time_this_month(), 'completed'])
        shift_id += 1
    write_inserts(f, 'Shifts', shifts)

    # Staff_Shifts
    staff_shifts = []
    for i in range(1, shift_id):
        docs = random.sample(range(1, NUM_DOCTORS+1), 3)
        nurs = random.sample(range(NUM_DOCTORS+1, NUM_DOCTORS+NUM_NURSES+1), 6)
        adms = random.sample(range(NUM_DOCTORS+NUM_NURSES+1, NUM_DOCTORS+NUM_NURSES+NUM_ADMINS+1), 2)
        for d in docs + nurs + adms:
            staff_shifts.append([d, i, "07:00:00", "15:00:00", fake.date_this_month()])
    write_inserts(f, 'Staff_Shifts', staff_shifts)

    # Ratings
    hosp_ratings = []
    doc_ratings = []
    # 50% of hospitalizations will be rated
    for h_id in range(1, NUM_HOSPITALIZATIONS + 1):
        if random.random() > 0.5:
            hosp_ratings.append([h_id, random.randint(3,5), random.randint(3,5), random.randint(3,5), random.randint(3,5), random.randint(3,5)])
            # Only rate a doctor if they actually prescribed medication for this hospitalization
            if h_id in prescribing_docs_by_hosp:
                doc_to_rate = random.choice(prescribing_docs_by_hosp[h_id])
                doc_ratings.append([h_id, doc_to_rate, random.randint(3,5)])
    write_inserts(f, 'Hospitalization_Ratings', hosp_ratings)
    write_inserts(f, 'Doctor_Ratings', doc_ratings)

    # Images (για Τμήματα, Ιατρούς, Χειρουργεία)
    images = []
    img_id = 1
    # Εικόνες τμημάτων
    for dept_id in range(1, NUM_DEPARTMENTS + 1):
        images.append([img_id, f"http://example.com/dept_{dept_id}.jpg", f"Φωτογραφία Τμήματος {dept_id}", None, None, None, dept_id, None, None])
        img_id += 1
    # Εικόνες ιατρών
    for doc_id in range(1, NUM_DOCTORS + 1):
        images.append([img_id, f"http://example.com/doc_{doc_id}.jpg", f"Πορτρέτο Ιατρού {doc_id}", doc_id, None, None, None, None, None])
        img_id += 1
    # Εικόνες χειρουργείων/εξοπλισμού
    for room_id in range(1, NUM_OPERATING_ROOMS + 1):
        images.append([img_id, f"http://example.com/room_{room_id}.jpg", f"Εξοπλισμός Χειρουργείου {room_id}", None, None, None, None, None, room_id])
        img_id += 1
    write_inserts(f, 'Images', images)

    f.write("SET FOREIGN_KEY_CHECKS = 1;\n")
    print("Το αρχείο fake_data_inserts.sql δημιουργήθηκε επιτυχώς!")