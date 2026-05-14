from flask import Flask, render_template, request, redirect, url_for, flash
import mysql.connector
from mysql.connector import Error

app = Flask(__name__)
app.secret_key = "hospital_secret_key"

# Config
db_config = {
    'host': 'localhost', #127.0.0.1:5000
    'user': 'root',
    'password': '',
    'database': 'hospitaldb'
}

QUERIES_INFO = {
    'Q1': {
        'title': 'Έσοδα ανά Τμήμα & Έτος',
        'description': 'Συνολικά έσοδα του νοσοκομείου ανά τμήμα και ανά έτος, με ανάλυση ανά ΚΕΝ κωδικό και κατανομή νοσηλειών ανά ασφαλιστικό φορέα.',
        'file': 'sql/Q01.sql'
    },
    'Q2': {
        'title': 'Ιατροί ανά Ειδικότητα',
        'description': 'Βρείτε όλους τους ιατρούς που ανήκουν σε μια συγκεκριμένη ειδικότητα, με ένδειξη αν είχαν εφημερία το τρέχον έτος.',
        'file': 'sql/Q02.sql',
        'params': [
            {'name': 'specialty', 'label': 'Ειδικότητα', 'type': 'select', 'options_key': 'specialties'}
        ]
    },
    'Q3': {
        'title': 'Πολλαπλές Νοσηλείες',
        'description': 'Ασθενείς που έχουν νοσηλευτεί περισσότερες από 3 φορές στο ίδιο τμήμα.',
        'file': 'sql/Q03.sql'
    },
    'Q4': {
        'title': 'Αξιολόγηση Ιατρού',
        'description': 'Μέσος όρος αξιολογήσεων των ασθενών για έναν συγκεκριμένο ιατρό.',
        'file': 'sql/Q04a.sql',
        'params': [
            {'name': 'doctor_id', 'label': 'ID Ιατρού', 'type': 'number', 'placeholder': 'π.χ. 1', 'default': '1'}
        ]
    },
    'Q5': {
        'title': 'Νέοι Χειρουργοί (<35)',
        'description': 'Νέοι ιατροί με τις περισσότερες χειρουργικές επεμβάσεις.',
        'file': 'sql/Q05.sql'
    },
    'Q6': {
        'title': 'Ιστορικό Νοσηλειών Ασθενή',
        'description': 'Ιστορικό νοσηλειών για συγκεκριμένο ασθενή, με διαγνώσεις, κόστος και αξιολογήσεις.',
        'file': 'sql/Q06a.sql',
        'params': [
            {'name': 'patient_id', 'label': 'ID Ασθενή', 'type': 'number', 'placeholder': 'π.χ. 1', 'default': '1'}
        ]
    },
    'Q7': {
        'title': 'Αλλεργίες ανά Δραστική Ουσία',
        'description': 'Αριθμός ασθενών με αλλεργία και αριθμός φαρμάκων ανά δραστική ουσία.',
        'file': 'sql/Q07.sql'
    },
    'Q8': {
        'title': 'Μη Προγραμματισμένο Προσωπικό',
        'description': 'Προσωπικό χωρίς εφημερία σε συγκεκριμένη ημερομηνία και τμήμα.',
        'file': 'sql/Q08.sql',
        'params': [
            {'name': 'shift_date', 'label': 'Ημερομηνία', 'type': 'date', 'default': '2026-05-01'},
            {'name': 'dept_name', 'label': 'Τμήμα', 'type': 'select', 'options_key': 'departments'}
        ]
    },
    'Q9': {
        'title': 'Σταθερή Διάρκεια Νοσηλείας',
        'description': 'Ασθενείς που νοσηλεύτηκαν τον ίδιο αριθμό ημερών.',
        'file': 'sql/Q09.sql'
    },
    'Q10': {
        'title': 'Top-3 Συνδυασμοί Φαρμάκων',
        'description': 'Top-3 ζεύγη δραστικών ουσιών που συνταγογραφήθηκαν ταυτόχρονα.',
        'file': 'sql/Q10.sql'
    },
    'Q11': {
        'title': 'Ιατροί με Χαμηλή Συμμετοχή',
        'description': 'Ιατροί με τουλάχιστον 5 λιγότερες επεμβάσεις από τον κορυφαίο.',
        'file': 'sql/Q11.sql'
    },
    'Q12': {
        'title': 'Απαιτήσεις Προσωπικού ανά Εβδομάδα',
        'description': 'Αριθμός προσωπικού ανά τμήμα και βάρδια για συγκεκριμένη εβδομάδα.',
        'file': 'sql/Q12.sql',
        'params': [
            {'name': 'start_date', 'label': 'Από Ημερομηνία', 'type': 'date', 'default': '2026-05-04'},
            {'name': 'end_date', 'label': 'Έως Ημερομηνία', 'type': 'date', 'default': '2026-05-10'}
        ]
    },
    'Q13': {
        'title': 'Ιεραρχία Εποπτείας',
        'description': 'Ιεραρχία εποπτείας από επόπτη έως Διευθυντή.',
        'file': 'sql/Q13.sql'
    },
    'Q14': {
        'title': 'Σταθερότητα ICD-10 ανά Έτος',
        'description': 'Κατηγορίες ICD-10 με ίδιο αριθμό εισαγωγών σε δύο συνεχόμενα έτη.',
        'file': 'sql/Q14.sql'
    },
    'Q15': {
        'title': 'Ανάλυση Triage',
        'description': 'Κατανομή triage ανά επίπεδο επείγοντος.',
        'file': 'sql/Q15.sql'
    }
}

def get_db_connection():
    try:
        conn = mysql.connector.connect(**db_config)
        return conn
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/docs/<path:filename>')
def serve_docs(filename):
    import os
    from flask import send_from_directory
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    docs_dir = os.path.join(project_root, 'docs')
    return send_from_directory(docs_dir, filename)

@app.route('/doctors', methods=['GET', 'POST'])
def doctors():
    conn = get_db_connection()
    if not conn:
        flash("Η σύνδεση με τη βάση δεδομένων απέτυχε!", "danger")
        return render_template('doctors.html', doctors=[])

    cursor = conn.cursor(dictionary=True)

    if request.method == 'POST':
        # Doctor Logic
        try:
            amka = request.form['amka']
            first_name = request.form['first_name']
            last_name = request.form['last_name']
            birth_date = request.form['birth_date']
            email = request.form['email']
            phone = request.form['phone']
            hire_date = request.form['hire_date']
            license_number = request.form['license_number']
            specialty = request.form['specialty']
            rank = request.form['rank']
            supervisor_id = request.form.get('supervisor_id')
            if not supervisor_id:
                supervisor_id = None

            # 1. Insert into Staff
            cursor.execute("""
                INSERT INTO Staff (amka, first_name, last_name, birth_date, email, phone, hire_date, staff_type)
                VALUES (%s, %s, %s, %s, %s, %s, %s, 'doctor')
            """, (amka, first_name, last_name, birth_date, email, phone, hire_date))
            
            staff_id = cursor.lastrowid
            
            # 2. Insert into Doctors
            cursor.execute("""
                INSERT INTO Doctors (staff_id, license_number, specialty, rank, supervisor_id)
                VALUES (%s, %s, %s, %s, %s)
            """, (staff_id, license_number, specialty, rank, supervisor_id))
            
            conn.commit()
            flash("Ο ιατρός προστέθηκε επιτυχώς!", "success")
        except Error as e:
            conn.rollback()
            flash(f"Σφάλμα κατά την προσθήκη ιατρού: {e}", "danger")
        except Exception as e:
            flash(f"Παρουσιάστηκε ένα μη αναμενόμενο σφάλμα: {e}", "danger")
        
        return redirect(url_for('doctors'))

    # Doctor list
    try:
        cursor.execute("""
            SELECT s.first_name, s.last_name, d.specialty, d.rank, d.license_number, i.image_url
            FROM Staff s
            JOIN Doctors d ON s.id = d.staff_id
            LEFT JOIN Images i ON d.staff_id = i.doctor_id
            WHERE s.staff_type = 'doctor'
            ORDER BY s.last_name ASC
        """)
        doctors_list = cursor.fetchall()
    except Error as e:
        flash(f"Σφάλμα κατά την ανάκτηση ιατρών: {e}", "danger")
        doctors_list = []
    
    # Fetch potential supervisors
    try:
        cursor.execute("""
            SELECT d.staff_id, s.last_name, s.first_name, d.rank
            FROM Doctors d
            JOIN Staff s ON d.staff_id = s.id
            WHERE d.rank != 'Ειδικευόμενος'
            ORDER BY s.last_name ASC
        """)
        supervisors = cursor.fetchall()
    except Error as e:
        supervisors = []

    cursor.close()
    conn.close()
    return render_template('doctors.html', doctors=doctors_list, supervisors=supervisors)

@app.route('/patients', methods=['GET', 'POST'])
def patients():
    conn = get_db_connection()
    if not conn:
        flash("Η σύνδεση με τη βάση δεδομένων απέτυχε!", "danger")
        return render_template('patients.html', patients=[])

    cursor = conn.cursor(dictionary=True)

    if request.method == 'POST':
        # Patient Logic
        try:
            amka = request.form['amka']
            first_name = request.form['first_name']
            last_name = request.form['last_name']
            father_name = request.form['father_name']
            birth_date = request.form['birth_date']
            gender = request.form['gender']
            weight = request.form['weight']
            height = request.form['height']
            address = request.form['address']
            phone = request.form['phone']
            email = request.form['email']
            profession = request.form['profession']
            nationality = request.form['nationality']
            insurance_provider = request.form['insurance_provider']

            cursor.execute("""
                INSERT INTO Patients (amka, first_name, last_name, father_name, birth_date, gender, weight, height, address, phone, email, profession, nationality, insurance_provider)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (amka, first_name, last_name, father_name, birth_date, gender, weight, height, address, phone, email, profession, nationality, insurance_provider))
            conn.commit()
            flash("Ο ασθενής προστέθηκε επιτυχώς!", "success")
        except Error as e:
            conn.rollback()
            flash(f"Σφάλμα κατά την προσθήκη ασθενή: {e}", "danger")
        except Exception as e:
            flash(f"Παρουσιάστηκε ένα μη αναμενόμενο σφάλμα: {e}", "danger")
            
        return redirect(url_for('patients'))

    # List Patients
    try:
        cursor.execute("SELECT first_name, last_name, amka, phone, insurance_provider FROM Patients ORDER BY last_name ASC")
        patients_list = cursor.fetchall()
    except Error as e:
        flash(f"Σφάλμα κατά την ανάκτηση ασθενών: {e}", "danger")
        patients_list = []

    cursor.close()
    conn.close()
    return render_template('patients.html', patients=patients_list)

@app.route('/queries', methods=['GET', 'POST'])
def queries():
    conn = get_db_connection()
    if not conn:
        flash("Η σύνδεση με τη βάση δεδομένων απέτυχε!", "danger")
        return redirect(url_for('index'))

    cursor = conn.cursor(dictionary=True)
    
    # Fetch dynamic options
    departments = []
    specialties = []
    try:
        cursor.execute("SELECT DISTINCT name FROM Departments ORDER BY name")
        departments = [row['name'] for row in cursor.fetchall()]
        
        cursor.execute("SELECT DISTINCT specialty FROM Doctors WHERE specialty IS NOT NULL ORDER BY specialty")
        specialties = [row['specialty'] for row in cursor.fetchall()]
    except Error as e:
        print(f"Error fetching dynamic options: {e}")

    query_id = request.args.get('id')
    results = None
    headers = []
    
    if request.method == 'POST':
        query_id = request.form.get('query_id')
        if query_id and query_id in QUERIES_INFO:
            try:
                # Read SQL from file
                import os
                current_dir = os.path.dirname(os.path.abspath(__file__))
                project_root = os.path.dirname(current_dir)
                file_path = os.path.join(project_root, QUERIES_INFO[query_id]['file'])
                with open(file_path, 'r', encoding='utf-8') as f:
                    sql_code = f.read()

                # Remove EXPLAIN ANALYZE if it exists in the assignment files so the UI doesn't crash
                sql_code = sql_code.replace("EXPLAIN ANALYZE", "").replace("EXPLAIN", "")

                # Handle Parameters
                params_values = []
                if query_id == 'Q2':
                    val = request.form.get('specialty', 'Χειρουργική')
                    sql_code = sql_code.replace("'Χειρουργική'", "%s")
                    params_values.append(val)
                elif query_id == 'Q4':
                    val = request.form.get('doctor_id', '1')
                    sql_code = sql_code.replace("= 1", "= %s")
                    params_values.append(val)
                elif query_id == 'Q6':
                    val = request.form.get('patient_id', '1')
                    sql_code = sql_code.replace("= 1", "= %s")
                    params_values.append(val)
                elif query_id == 'Q8':
                    date_val = request.form.get('shift_date', '2026-05-1')
                    dept_val = request.form.get('dept_name', 'Χειρουργική')
                    sql_code = sql_code.replace("'2026-05-1'", "%s").replace("'Χειρουργική'", "%s")
                    params_values.extend([dept_val, date_val])
                elif query_id == 'Q12':
                    start_val = request.form.get('start_date', '2026-05-04')
                    end_val = request.form.get('end_date', '2026-05-10')
                    sql_code = sql_code.replace("'2026-05-04'", "%s").replace("'2026-05-10'", "%s")
                    params_values.extend([start_val, end_val, start_val, end_val, start_val, end_val])

                cursor = conn.cursor(dictionary=True)
                if params_values:
                    cursor.execute(sql_code, params_values)
                else:
                    cursor.execute(sql_code)
                
                results = cursor.fetchall()
                if results:
                    headers = results[0].keys()
                cursor.close()
            except Error as e:
                flash(f"Σφάλμα SQL: {e}", "danger")
            except Exception as e:
                flash(f"Παρουσιάστηκε σφάλμα: {e}", "danger")

    conn.close()
    return render_template('queries.html', 
                           queries=QUERIES_INFO, 
                           selected_id=query_id, 
                           results=results,
                           headers=headers,
                           departments=departments,
                           specialties=specialties)

if __name__ == '__main__':
    app.run(debug=True)
