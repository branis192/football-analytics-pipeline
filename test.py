import json
import requests

API_KEY = "56edc4d2808043828119faf22993956d"
url = "https://api.football-data.org/v4/competitions/PL/standings"
headers = {"X-Auth-Token": API_KEY}

response = requests.get(url, headers=headers)

if response.status_code == 200:
  data = response.json()
  with open("test_standings.json", "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
  print("Succès ! Statut HTTP :", response.status_code)
  print("Fichier test_standings.json généré avec succès.")
else:
  print(f"Erreur {response.status_code} : {response.text}")