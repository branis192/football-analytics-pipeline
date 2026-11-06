from datetime import datetime, timezone
import json
import boto3
import urllib3

API_KEY = "56edc4d2808043828119faf22993956d"
BUCKET_NAME = "football-analytics-branish"
LEAGUE_CODE = "PL"
REGION_NAME = "eu-north-1"


def lambda_handler(event, context):
  http = urllib3.PoolManager()
  url = f"https://api.football-data.org/v4/competitions/{LEAGUE_CODE}/standings"
  headers = {"X-Auth-Token": API_KEY}

  response = http.request("GET", url, headers=headers)

  if response.status == 200:
    payload = json.loads(response.data.decode("utf-8"))

    now = datetime.now(timezone.utc)
    s3_key = (
        f"raw/standings/year={now.year}/month={now.month:02d}/"
        f"{LEAGUE_CODE}_{now.strftime('%Y-%m-%d_%H%M%S')}.json"
    )

    s3_client = boto3.client("s3", region_name=REGION_NAME)
    s3_client.put_object(
        Bucket=BUCKET_NAME,
        Key=s3_key,
        Body=json.dumps(payload, ensure_ascii=False),
        ContentType="application/json",
    )

    return {
        "statusCode": 200,
        "body": json.dumps(
            f"Fichier déposé sur S3 : s3://{BUCKET_NAME}/{s3_key}"
        ),
    }

  return {
      "statusCode": response.status,
      "body": json.dumps("Erreur lors de l'appel API"),
  }