import csv
import os

input_path = 'LabExam_MedicalActs.csv'

if not os.path.exists(input_path):
    print("Could not find LabExam_MedicalActs.csv")
    exit(1)

medical_path = 'MedicalAct_Ref.csv'
lab_path = 'LabExam_Ref.csv'

with open(input_path, 'r', encoding='utf-8') as fin, \
     open(medical_path, 'w', encoding='utf-8', newline='') as fmed, \
     open(lab_path, 'w', encoding='utf-8', newline='') as flab:
     
    reader = csv.reader(fin, delimiter=';')
    writer_med = csv.writer(fmed, delimiter=';')
    writer_lab = csv.writer(flab, delimiter=';')
    
    current_target = 'med'
    
    for row in reader:
        if not row:
            continue
            
        first_col = row[0].strip()
        
        # Check category headers
        if first_col.startswith(('Γ.', 'Δ.', 'Ε.')):
            current_target = 'lab'
        elif first_col.startswith(('Α.', 'Β.')):
            current_target = 'med'
        elif first_col.startswith(('ΣΤ.', 'Ζ.', 'Η.', 'Θ.', 'Ι.', 'Κ.', 'Λ.', 'Μ.', 'Ν.', 'Ξ.', 'Ο.', 'Π.', 'Ρ.', 'Σ.')):
            current_target = 'ignore'
            
        # Write headers to both
        if first_col == 'ΕΛΛΗΝΙΚΗ ΟΝΟΜΑΤΟΛΟΓΙΑ ΚΑΙ ΚΩΔΙΚΟΠΟΙΗΣΗ ΤΩΝ ΙΑΤΡΙΚΩΝ ΠΡΑΞΕΩΝ' or first_col == 'Α/α':
            writer_med.writerow(row)
            writer_lab.writerow(row)
        else:
            if current_target == 'med':
                writer_med.writerow(row)
            elif current_target == 'lab':
                writer_lab.writerow(row)

print("Successfully split LabExam_MedicalActs.csv into MedicalAct_Ref.csv and LabExam_Ref.csv (ignoring categories after E)")
