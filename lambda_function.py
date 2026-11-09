from datetime import datetime, timezone
import json
import time
import boto3
import urllib3

# Paramètres
API_KEY = "56edc4d2808043828119faf22993956d"
BUCKET_NAME = "football-analytics-branish"
LEAGUE_CODE = "PL"
REGION_NAME = "eu-north-1"

# Endpoints ciblés : classements et résultats/calendrier des matchs
ENDPOINTS = {
    "standings": f"https://api.football-data.org/v4/competitions/{LEAGUE_CODE}/standings",
    "fixtures": f"https://api.football-data.org/v4/competitions/{LEAGUE_CODE}/matches"
}

def lambda_handler(event, context):
    http = urllib3.PoolManager()
    headers = {"X-Auth-Token": API_KEY}
    s3_client = boto3.client("s3", region_name=REGION_NAME)
    
    now = datetime.now(timezone.utc)
    year = now.year
    month = f"{now.month:02d}"
    timestamp = now.strftime('%Y-%m-%d_%H%M%S')
    
    results = {}

    for endpoint_type, url in ENDPOINTS.items():
        print(f"Extraction de {endpoint_type} depuis {url}...")
        response = http.request("GET", url, headers=headers)
        
        if response.status == 200:
            payload = json.loads(response.data.decode("utf-8"))
            
            s3_key = f"raw/{endpoint_type}/year={year}/month={month}/{LEAGUE_CODE}_{endpoint_type}_{timestamp}.json"
            
            s3_client.put_object(
                Bucket=BUCKET_NAME,
                Key=s3_key,
                Body=json.dumps(payload, ensure_ascii=False),
                ContentType="application/json"
            )
            
            results[endpoint_type] = f"s3://{BUCKET_NAME}/{s3_key}"
            print(f"Succès pour {endpoint_type} : {s3_key}")
        else:
            print(f"Erreur pour {endpoint_type} ({response.status}) : {response.data}")
            results[endpoint_type] = f"Error {response.status}"
            
        # Petite pause pour ne pas saturer le rate-limiting de l'API
        time.sleep(1)

    return {
        "statusCode": 200,
        "body": json.dumps(results)
    }