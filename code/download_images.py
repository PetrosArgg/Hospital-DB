# PEXELS_API_KEY is stored in .env but it's not uploaded for security reasons

import os
import requests
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv("PEXELS_API_KEY")

# Images
categories = {
    "doctors":("serious portrait of a doctor in white coat", 80, "doctor"),
    "nurses":("serious portrait of a nurse in scrubs", 50, "nurse"),
    "admins":("serious portrait of an administrator professional", 20, "admin"),
    "departments":("hospital ward interior", 14, "dept"),
    "rooms":("operating room interior", 10, "room")
}

for folder, data in categories.items():
    query = data[0]
    count = data[1]
    name = data[2]

    response = requests.get(
        "https://api.pexels.com/v1/search",
        headers={"Authorization": API_KEY},
        params={
            "query": query,
            "per_page": count
        }
    )

    photos = response.json().get("photos", [])

    # Folder
    save_folder = "../docs/" + folder

    if not os.path.exists(save_folder):
        os.makedirs(save_folder)

    # Save
    i = 1

    for photo in photos:
        url = photo["src"]["medium"]
        img_response = requests.get(url)

        if img_response.status_code == 200:
            filename = save_folder + "/" + name + "_" + str(i) + ".jpg"

            with open(filename, "wb") as file:
                file.write(img_response.content)

            i += 1