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

            # 1. Insert into Staff
            cursor.execute("""
                INSERT INTO Staff (amka, first_name, last_name, birth_date, email, phone, hire_date, staff_type)
                VALUES (%s, %s, %s, %s, %s, %s, %s, 'doctor')
            """, (amka, first_name, last_name, birth_date, email, phone, hire_date))
            
            staff_id = cursor.lastrowid
            
            # 2. Insert into Doctors
            cursor.execute("""
                INSERT INTO Doctors (staff_id, license_number, specialty, rank)
                VALUES (%s, %s, %s, %s)
            """, (staff_id, license_number, specialty, rank))
            
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
            SELECT s.first_name, s.last_name, d.specialty, d.rank, d.license_number
            FROM Staff s
            JOIN Doctors d ON s.id = d.staff_id
            WHERE s.staff_type = 'doctor'
            ORDER BY s.last_name ASC
        """)
        doctors_list = cursor.fetchall()
    except Error as e:
        flash(f"Σφάλμα κατά την ανάκτηση ιατρών: {e}", "danger")
        doctors_list = []
    
    cursor.close()
    conn.close()
    return render_template('doctors.html', doctors=doctors_list)

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

if __name__ == '__main__':
    app.run(debug=True)
