from datetime import datetime, timezone
import json
import boto3
import requests

# 1. Paramètres
API_KEY = "56edc4d2808043828119faf22993956d"
BUCKET_NAME = "football-analytics-branish"  
LEAGUE_CODE = "PL"  # Premier League
REGION_NAME = "eu-north-1"

# 2. Récupération des données depuis l'API
url = f"https://api.football-data.org/v4/competitions/{LEAGUE_CODE}/standings"
headers = {"X-Auth-Token": API_KEY}

print(f"Extraction des données pour {LEAGUE_CODE}...")
response = requests.get(url, headers=headers)

if response.status_code == 200:
  payload = response.json()

  # 3. Formatage de la date en UTC (compatible Python 3.14)
  now = datetime.now(timezone.utc)
  s3_key = (
      f"raw/standings/year={now.year}/month={now.month:02d}/"
      f"{LEAGUE_CODE}_{now.strftime('%Y-%m-%d_%H%M%S')}.json"
  )

  # 4. Envoi direct vers S3 en forçant explicitement la région sans espace
  s3_client = boto3.client("s3", region_name=REGION_NAME)
  s3_client.put_object(
      Bucket=BUCKET_NAME,
      Key=s3_key,
      Body=json.dumps(payload, ensure_ascii=False),
      ContentType="application/json",
  )

  print(f"Succès ! Fichier déposé sur S3 : s3://{BUCKET_NAME}/{s3_key}")
else:
  print(f"Erreur API ({response.status_code}) : {response.text}")