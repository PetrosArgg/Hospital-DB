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
NUM_DEPARTMENTS = 15
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
    # Escape backslashes and single quotes for SQL
    return f"'{str(val).replace('\\', '\\\\').replace(chr(39), chr(39)+chr(39))}'"

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
    path = 'csv/icd10.csv'
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
    path = 'csv/KEN_Ref.csv'
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
    path = 'csv/Medications.csv'
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
                sub_raw = row[1].strip()
                if not prod_name or 'Product name' in prod_name: continue
                
                meds.append([med_id_counter, prod_name])
                
                if sub_raw:
                    # Split by | for multiple substances
                    sub_names = [s.strip() for s in sub_raw.split('|') if s.strip()]
                    for sn in sub_names:
                        if sn not in subs_map:
                            subs_map[sn] = sub_id_counter
                            sub_id_counter += 1
                        bridge.append([med_id_counter, subs_map[sn]])
                
                med_id_counter += 1

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
lab_ref = load_split_refs('csv/LabExam_Ref.csv', 'lab')
medact_ref = load_split_refs('csv/MedicalAct_Ref.csv', 'medact')

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
    dept_names = ['Καρδιολογία', 'Χειρουργική', 'ΜΕΘ','Παθολογικό', 'Ορθοπεδικό', 'Παιδιατρικό', 'Νευρολογικό', 'Ουρολογικό', 'Οφθαλμολογικό', 'ΩΡΛ', 'Δερματολογικό', 'Γυναικολογικό', 'Ψυχιατρικό', 'Ακτινολογικό', 'Επείγοντα']
    for i in range(1, NUM_DEPARTMENTS + 1):
        head_doc = random.randint(1, 10) # Picking from the directors pool
        depts_data.append([i, dept_names[i-1], f"Περιγραφή τμήματος {dept_names[i-1]}", random.randint(10, 40), f"Όροφος {random.randint(0,4)}", head_doc, 3, 6, 2])
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
    directors_ids = list(range(1, 11))
    epi_a_ids = list(range(11, 31))
    epi_b_ids = list(range(31, 56))
    residents_ids = list(range(56, 81))

    for i in range(1, NUM_DOCTORS + 1):
        lic = f"LIC-{1000+i}"
        spec = random.choice(['Καρδιολογία', 'Χειρουργική', 'ΜΕΘ', 'Επείγοντα'])
        
        if i in directors_ids:
            rank, supervisor = 'Διευθυντής', None
        elif i in epi_a_ids:
            rank, supervisor = 'Επιμελητής Α΄', random.choice(directors_ids)
        elif i in epi_b_ids:
            rank, supervisor = 'Επιμελητής Β΄', random.choice(directors_ids + epi_a_ids)
        elif i in residents_ids:
            rank, supervisor = 'Ειδικευόμενος', random.choice(directors_ids + epi_a_ids + epi_b_ids)
            
        doctors_data.append([i, lic, spec, rank, supervisor])
    write_inserts(f, 'Doctors', doctors_data)

    doctor_rank_by_id = {row[0]: row[3] for row in doctors_data}

    # Nurses
    nurses_data = []
    for i in range(NUM_DOCTORS + 1, NUM_DOCTORS + NUM_NURSES + 1):
        # Ensure some nurses are in the 'Επείγοντα' department (ID 15)
        if i <= NUM_DOCTORS + 15:
            dept_id = 15
        else:
            dept_id = random.randint(1, NUM_DEPARTMENTS - 1)
        nurses_data.append([i, random.choice(RANKS_NURSE), dept_id])
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
    emergency_nurses = [n[0] for n in nurses_data if n[2] == 15]
    for i in range(1, NUM_HOSPITALIZATIONS + 1):
        p_id = random.randint(1, NUM_PATIENTS)
        n_id = random.choice(emergency_nurses)
        arrival = fake.date_time_between(start_date='-1y', end_date='now')
        service = arrival + timedelta(minutes=random.randint(10, 60))
        triage_data.append([i, p_id, n_id, service, arrival, "Περιγραφή συμπτωμάτων...", random.randint(1, 5), 'Hospitalization'])
    write_inserts(f, 'Triage_Entries', triage_data)

    # Hospitalizations
    hosp_data = []
    icd_codes = [r[1] for r in icd10_ref]
    ken_codes = [r[1] for r in ken_ref]
    all_categories = sorted(list(set(c[:3] for c in icd_codes if len(c) >= 3)))
    target_categories = all_categories[:3]
    
    counts_2025 = {cat: 0 for cat in target_categories}
    counts_2026 = {cat: 0 for cat in target_categories}

    random_icd_pool = [c for c in icd_codes if c[:3] not in target_categories]

    for i in range(1, NUM_HOSPITALIZATIONS + 1):
        tr = triage_data[i-1]
        p_id, entry = tr[1], tr[4]
        exit_d = entry + timedelta(days=random.randint(1, 15))
        year = entry.year
        
        icd_in = None
        if year in [2025, 2026]:
            for cat in target_categories:
                if (year == 2025 and counts_2025[cat] < 10) or (year == 2026 and counts_2026[cat] < 10):
                    icd_in = next(c for c in icd_codes if c.startswith(cat))
                    if year == 2025: counts_2025[cat] += 1
                    else: counts_2026[cat] += 1
                    break
        
        if not icd_in:
            icd_in = random.choice(random_icd_pool)
            
        hosp_data.append([i, p_id, random.randint(1, NUM_BEDS), random.randint(1, NUM_DEPARTMENTS), entry, exit_d, icd_in, random.choice(icd_codes), random.choice(ken_codes), round(random.uniform(500, 5000), 2), i])
    write_inserts(f, 'Hospitalizations', hosp_data)

    # Shifts
    shifts_data = []
    for d in range(1, NUM_DEPARTMENTS + 1):
        for day in range(30):
            date = datetime.now().date() - timedelta(days=day)
            for stype in ['Morning', 'Afternoon', 'Night']:
                shifts_data.append([len(shifts_data)+1, d, stype, date, datetime.now(), datetime.now(), 'scheduled'])
    write_inserts(f, 'Shifts', shifts_data)

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
    room_busy_slots = {}
    doctor_busy_slots = {}

    for i in range(1, NUM_MEDICAL_ACTS + 1):
        for _ in range(100):
            h_id = random.randint(1, NUM_HOSPITALIZATIONS)
            h_info = hosp_data[h_id-1]
            h_start, h_end = h_info[4], h_info[5]
            
            duration = random.randint(30, 180)
            # Pick a random time within hospitalization period
            time_diff = int((h_end - h_start).total_seconds())
            if time_diff > duration * 60:
                start_time = h_start + timedelta(seconds=random.randint(0, time_diff - duration * 60))
            else:
                start_time = h_start
                
            end_time = start_time + timedelta(minutes=duration)
            room_id = random.randint(1, NUM_OPERATING_ROOMS)
            if random.random() < 0.35:
                doc_id = random.randint(1, 5) 
            else:
                doc_id = random.randint(1, NUM_DOCTORS)
            
            # Check room conflict
            r_conflict = False
            for s, e in room_busy_slots.get(room_id, []):
                if not (end_time <= s or start_time >= e):
                    r_conflict = True
                    break
            if r_conflict: continue
            
            # Check doctor conflict
            d_conflict = False
            for s, e in doctor_busy_slots.get(doc_id, []):
                if not (end_time <= s or start_time >= e):
                    d_conflict = True
                    break
            if d_conflict: continue
            
            # Save if no conflict
            room_busy_slots.setdefault(room_id, []).append((start_time, end_time))
            doctor_busy_slots.setdefault(doc_id, []).append((start_time, end_time))
            medical_acts.append([i, random.choice(act_codes), duration, 600.0, start_time, h_id, room_id, doc_id])
            break
        else:
            # Fallback (unlikely given density)
            medical_acts.append([i, random.choice(act_codes), 60, 600.0, datetime.now(), 1, 1, 1])
    
    write_inserts(f, 'Medical_Acts', medical_acts)

    # Prescriptions
    presc_data = []
    med_ids = [m[0] for m in medications]
    
    # Pre-map medications to their active substances for faster lookup
    med_to_subs = {}
    for med_id, sub_id in med_substances:
        med_to_subs.setdefault(med_id, set()).add(sub_id)
        
    # Pre-map patients to their allergic substances
    patient_allergies = {}
    for p_id, sub_id in allergies_data:
        patient_allergies.setdefault(p_id, set()).add(sub_id)

    for i in range(1, NUM_PRESCRIPTIONS + 1):
        h_id = random.randint(1, NUM_HOSPITALIZATIONS)
        p_id = hosp_data[h_id-1][1]
        
        # Pick a medication that the patient is NOT allergic to
        safe_med_found = False
        for _ in range(50): # Retry to find a safe medication
            m_id = random.choice(med_ids)
            # Check if the medication's substances intersect with the patient's allergies
            if not (med_to_subs.get(m_id, set()) & patient_allergies.get(p_id, set())):
                safe_med_found = True
                break
        
        if safe_med_found:
            presc_data.append([i, random.randint(1, NUM_DOCTORS), p_id, m_id, h_id, fake.date_this_year(), fake.date_this_year(), "1 χάπι", "8 ώρες"])
        else:
            # Fallback to a random medication if retry fails (unlikely given density)
            presc_data.append([i, random.randint(1, NUM_DOCTORS), p_id, random.choice(med_ids), h_id, fake.date_this_year(), fake.date_this_year(), "1 χάπι", "8 ώρες"])
            
    write_inserts(f, 'Prescriptions', presc_data)

    # Ratings
    hosp_ratings = []
    for i in range(1, NUM_HOSPITALIZATIONS + 1):
        if random.random() > 0.5:
            hosp_ratings.append([i, random.randint(3,5), random.randint(3,5), random.randint(3,5), random.randint(3,5)])
    write_inserts(f, 'Hospitalization_Ratings', hosp_ratings)

    # Doctor Ratings
    doctor_ratings = []
    seen_doctor_hosp = set()
    for p in presc_data:
        # p = [id, doctor_id, patient_id, med_id, hospitalization_id, ...]
        doc_id, h_id = p[1], p[4]
        if (h_id, doc_id) not in seen_doctor_hosp and random.random() > 0.4:
            doctor_ratings.append([h_id, doc_id, random.randint(3, 5)])
            seen_doctor_hosp.add((h_id, doc_id))
    write_inserts(f, 'Doctor_Ratings', doctor_ratings)

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

    # To prevent rest period, consecutive nights, and monthly limit conflicts.
    staff_shifts = []
    shift_staff = {}
    staff_busy_slots = {} # staff_id -> (last_end_time, consecutive_nights_count)
    staff_monthly_count = {} # staff_id -> {month: count}

    def get_max_limit(st_id):
        if st_id <= NUM_DOCTORS: return 15
        if st_id <= NUM_DOCTORS + NUM_NURSES: return 20
        return 25

    def has_supervisor_on_shift(s_id):
        return any(
            staff_id <= NUM_DOCTORS and doctor_rank_by_id.get(staff_id) in ['Επιμελητής Α΄', 'Διευθυντής']
            for staff_id in shift_staff.get(s_id, [])
        )

    def get_shift_times(s_date, stype):
        if hasattr(s_date, 'date'): s_date = s_date.date()
        if stype == 'Morning':
            start = datetime.combine(s_date, datetime.min.time().replace(hour=7))
            end = datetime.combine(s_date, datetime.min.time().replace(hour=15))
        elif stype == 'Afternoon':
            start = datetime.combine(s_date, datetime.min.time().replace(hour=15))
            end = datetime.combine(s_date, datetime.min.time().replace(hour=23))
        else: # Night
            start = datetime.combine(s_date, datetime.min.time().replace(hour=23))
            end = datetime.combine(s_date + timedelta(days=1), datetime.min.time().replace(hour=7))
        return start, end

    stype_order = {'Morning': 0, 'Afternoon': 1, 'Night': 2}
    sorted_shifts = sorted(shifts_data, key=lambda x: (x[3], stype_order[x[2]]))

    for s_info in sorted_shifts:
        s_id, d_id, stype, s_date = s_info[0], s_info[1], s_info[2], s_info[3]
        s_start, s_end = get_shift_times(s_date, stype)
        month_key = (s_date.year, s_date.month)
        
        if random.random() > 0.7:
            for _ in range(100): # More retries
                st_id = random.randint(1, NUM_DOCTORS + NUM_NURSES + NUM_ADMINS)
                
                # Prevent assigning a resident to a shift without an existing supervisor.
                if st_id <= NUM_DOCTORS and doctor_rank_by_id.get(st_id) == 'Ειδικευόμενος' and not has_supervisor_on_shift(s_id):
                    continue

                # Check monthly limit
                limit = get_max_limit(st_id)
                current_count = staff_monthly_count.get(st_id, {}).get(month_key, 0)
                if current_count >= limit - 1: # -1 to be safe against trigger logic
                    continue

                last_end, night_count = staff_busy_slots.get(st_id, (datetime.min, 0))
                
                # Check rest period (min 8 hours)
                if s_start < last_end + timedelta(hours=8):
                    continue
                
                # Check consecutive nights (max 3)
                new_night_count = (night_count + 1) if stype == 'Night' else 0
                if new_night_count > 3:
                    continue
                
                # Success
                staff_busy_slots[st_id] = (s_end, new_night_count)
                staff_monthly_count.setdefault(st_id, {})[month_key] = current_count + 1
                staff_shifts.append([st_id, s_id, s_start.strftime('%H:%M'), s_end.strftime('%H:%M'), s_date])
                shift_staff.setdefault(s_id, []).append(st_id)
                break
    
    write_inserts(f, 'Staff_Shifts', staff_shifts)

    # Medical Act Assistants
    act_assts = []
    assistant_busy_slots = {} # staff_id -> list of (start, end)
    for i in range(1, NUM_MEDICAL_ACTS + 1):
        act_info = medical_acts[i-1]
        start_time = act_info[4]
        end_time = start_time + timedelta(minutes=act_info[2])
        
        for _ in range(100):
            asst_id = random.randint(NUM_DOCTORS+1, NUM_DOCTORS+NUM_NURSES)
            
            # Check assistant conflict
            conflict = False
            for s, e in assistant_busy_slots.get(asst_id, []):
                if not (end_time <= s or start_time >= e):
                    conflict = True
                    break
            if conflict: continue
            
            assistant_busy_slots.setdefault(asst_id, []).append((start_time, end_time))
            act_assts.append([i, asst_id])
            break
        else:
            act_assts.append([i, NUM_DOCTORS + 1])
    write_inserts(f, 'Medical_Act_Assistants', act_assts)

    f.write("SET FOREIGN_KEY_CHECKS = 1;\n")