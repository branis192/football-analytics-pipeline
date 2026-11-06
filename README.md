# ⚽ End-to-End Serverless Football Analytics Pipeline on AWS

An automated, cloud-native data pipeline designed to collect, store, and analyze European football league data using a fully serverless AWS architecture.

This project demonstrates how to build a scalable data ingestion pipeline following an ELT (Extract, Load, Transform) approach, leveraging AWS managed services to automate data collection and prepare football data for analytical workloads and business intelligence dashboards.

---

## 📌 Architecture Overview

The pipeline automatically retrieves football data from the [football-data.org API](https://www.football-data.org/), stores raw JSON responses in Amazon S3, and makes the data available for querying and analytics through AWS Athena and AWS Glue.

### Architecture Diagram

```text
                  ┌─────────────────────────┐
                  │   football-data.org     │
                  │       REST API          │
                  └────────────┬────────────┘
                               │
                               ▼
                  ┌─────────────────────────┐
                  │    AWS Lambda           │
                  │    Python 3.12          │
                  │    Data Ingestion       │
                  └────────────┬────────────┘
                               ▲
                               │
                  ┌────────────┴────────────┐
                  │   Amazon EventBridge    │
                  │   Daily at 22:00 UTC    │
                  └─────────────────────────┘
                               │
                               ▼
                  ┌─────────────────────────┐
                  │      Amazon S3          │
                  │       Data Lake         │
                  │       Raw Layer         │
                  └────────────┬────────────┘
                               │
                               ▼
                  ┌─────────────────────────┐
                  │     AWS Glue Catalog    │
                  │      Metadata Layer     │
                  └────────────┬────────────┘
                               │
                               ▼
                  ┌─────────────────────────┐
                  │      Amazon Athena      │
                  │      SQL Analytics      │
                  └────────────┬────────────┘
                               │
                               ▼
                  ┌─────────────────────────┐
                  │     BI Dashboard        │
                  │  Power BI / Looker      │
                  └─────────────────────────┘
```

### AWS Components

| Component | Technology | Responsibility |
|---|---|---|
| Data Source | football-data.org API | Provides football standings, fixtures and match data |
| Compute | AWS Lambda (Python 3.12) | Executes serverless data ingestion |
| Orchestration | Amazon EventBridge | Triggers daily ingestion automatically |
| Storage | Amazon S3 | Stores raw JSON data in a data lake |
| Data Catalog | AWS Glue | Manages table metadata and schemas |
| Query Engine | Amazon Athena | Enables serverless SQL analytics |
| Visualization | Power BI / Looker Studio | Displays football performance indicators |

### Data Architecture

The project follows a raw data lake architecture, with data organized using time-based partitions.

Example S3 structure:

```text
football-analytics/
│
└── raw/
    ├── standings/
    │   └── year=2026/
    │       └── month=11/
    │           └── standings_2026-11-06.json
    │
    ├── fixtures/
    │   └── year=2026/
    │       └── month=11/
    │           └── fixtures_2026-11-06.json
    │
    └── matches/
        └── year=2026/
            └── month=11/
                └── matches_2026-11-06.json
```

This partitioning strategy improves data organization and prepares the lake for efficient querying with Amazon Athena.

---

## 📁 Project Structure

```text
football-analytics/
│
├── src/
│   ├── local_ingest.py       # Local ingestion and data validation
│   └── lambda_function.py    # AWS Lambda production handler
│
├── .gitignore                # Excludes secrets and local files
├── requirements.txt          # Python dependencies
└── README.md                 # Project documentation
```

---

## 🚀 Getting Started

### Prerequisites

Before running the project, make sure you have:

- Python 3.10 or higher.
- An AWS account.
- AWS CLI installed and configured.
- An API key from [football-data.org](https://www.football-data.org/).
- Basic knowledge of AWS Lambda, Amazon S3 and IAM.

### 1. Clone the Repository

```bash
git clone https://github.com/<your-username>/football-analytics-pipeline.git

cd football-analytics-pipeline
```

### 2. Create a Virtual Environment

```bash
python3 -m venv venv
```

Activate the environment:

**Linux / macOS**

```bash
source venv/bin/activate
```

**Windows**

```bash
venv\Scripts\activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables

Set your API key and AWS configuration.

```bash
export FOOTBALL_DATA_API_KEY="your_api_key"
export AWS_DEFAULT_REGION="eu-west-3"
```

On Windows PowerShell:

```powershell
$env:FOOTBALL_DATA_API_KEY="your_api_key"
$env:AWS_DEFAULT_REGION="eu-west-3"
```

AWS credentials should be configured securely using the AWS CLI or an IAM role.

```bash
aws configure
```

**Security note:** Never commit API keys, AWS credentials or other sensitive information to GitHub.

### 5. Run Local Ingestion

Execute the local ingestion script to test API connectivity and validate data extraction.

```bash
python3 src/local_ingest.py
```

---

## ⚙️ AWS Configuration and Deployment

### 1. Amazon S3 – Data Lake Storage

Create an S3 general-purpose bucket:

```text
football-analytics-<your-unique-id>
```

Recommended security configuration:

- Block all public access.
- Enable server-side encryption using SSE-S3.
- Enable bucket versioning (recommended).
- Apply least-privilege access policies.
- Organize data using year and month partitions.

### 2. AWS IAM – Permissions and Security

Create an IAM execution role for AWS Lambda.

Attach the following managed policy:

- `AWSLambdaBasicExecutionRole`: Provides permissions to write execution logs to Amazon CloudWatch Logs.

Add a custom S3 policy granting the Lambda function permission to write objects to the target bucket.

Example IAM policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::football-analytics-<your-id>/raw/*"
    }
  ]
}
```

Use AWS Secrets Manager or Lambda environment variables with appropriate protection to manage the football-data.org API key.

### 3. AWS Lambda – Serverless Ingestion

Create an AWS Lambda function with the following configuration:

| Setting | Value |
|---|---|
| Runtime | Python 3.12 |
| Architecture | x86_64 or arm64 |
| Handler | lambda_function.lambda_handler |
| Execution timeout | 15 seconds |
| Memory | 256 MB |
| Execution role | Custom IAM role |

The Lambda function is responsible for:

1. Connecting to the football-data.org REST API.
2. Authenticating using the API key.
3. Extracting football standings, fixtures and match data.
4. Processing the API responses.
5. Uploading raw JSON files to Amazon S3.
6. Logging execution details and potential errors in CloudWatch.

### 4. Amazon EventBridge – Automated Scheduling

Create an EventBridge scheduled rule to trigger the Lambda function once per day.

Cron expression:

```text
cron(0 22 * * ? *)
```

This schedule triggers the ingestion process daily at **22:00 UTC**.

Make sure EventBridge has permission to invoke the Lambda function.

---

## 📊 Data Analytics and Querying

The next stage of the project focuses on making raw football data accessible for analytical workloads.

### AWS Glue Data Catalog

Create a Glue database to organize the football datasets.

Example:

```sql
CREATE DATABASE football_analytics;
```

Define the corresponding table schemas and configure the S3 locations.

### Amazon Athena

Use Athena to query football data directly from Amazon S3 without managing infrastructure.

Example analytical queries:

**1. Retrieve league standings**

```sql
SELECT
    team_name,
    played_games,
    won,
    draw,
    lost,
    points,
    goal_difference
FROM football_standings
ORDER BY points DESC;
```

**2. Identify teams with the highest goal difference**

```sql
SELECT
    team_name,
    goal_difference
FROM football_standings
ORDER BY goal_difference DESC
LIMIT 10;
```

*These queries illustrate the intended analytical layer and require the corresponding Glue tables and column schemas to be created first.*

---

## 📈 Roadmap

The project is being developed incrementally, following a serverless data engineering approach.

- [x] Set up the Python ingestion scripts.
- [x] Integrate football-data.org API authentication.
- [x] Implement automated raw data ingestion into Amazon S3.
- [x] Configure AWS Lambda for serverless execution.
- [x] Schedule daily ingestion using Amazon EventBridge.
- [ ] Create AWS Glue databases and table schemas.
- [ ] Configure Amazon Athena for SQL-based analytics.
- [ ] Implement data transformation and modeling using dbt.
- [ ] Design a dimensional model using a Star Schema.
- [ ] Build an interactive football analytics dashboard.
- [ ] Implement data quality checks and monitoring.
- [ ] Add automated testing and CI/CD deployment.

---

## 🎯 Key Learning Objectives

This project provides hands-on experience with:

- **Cloud Data Engineering:** Building serverless data pipelines on AWS.
- **Python Development:** Developing API integrations and automated ingestion scripts.
- **ELT Architecture:** Separating raw data ingestion from transformation.
- **Data Lake Design:** Structuring and partitioning data in Amazon S3.
- **AWS Serverless Services:** Working with Lambda, EventBridge, Glue and Athena.
- **SQL Analytics:** Querying and analyzing structured football datasets.
- **Data Modeling:** Designing analytical models using dimensional modeling and dbt.
- **Business Intelligence:** Turning football data into actionable insights.

---

## 🔐 Security Considerations

Security is an important part of the architecture.

The project follows these principles:

- No hardcoded API keys or AWS credentials.
- S3 buckets remain private.
- IAM permissions follow the principle of least privilege.
- Sensitive credentials are managed securely.
- Server-side encryption is enabled for stored data.
- Application logs are monitored through Amazon CloudWatch.

---

## 👨‍💻 Author

**<Your Name>**

Data Engineering | Python | SQL | AWS | Cloud Computing

GitHub: [https://github.com/<your-username>](https://github.com/<your-username>)

---

## 📄 License

This project is intended for educational and portfolio purposes.

Data provided by [football-data.org](https://www.football-data.org/) is subject to its API terms of use and licensing conditions.
