# ⚽ End-to-End Serverless Football Analytics Pipeline on AWS

An end-to-end **serverless Data Engineering project** designed to collect, ingest, transform, orchestrate, and analyze European football data using AWS cloud services.

This project implements a production-oriented ELT (Extract, Load, Transform) architecture leveraging **AWS Lambda, Amazon S3, Amazon EventBridge, AWS Step Functions, AWS Glue, and Amazon Athena**.

The pipeline automatically extracts football standings and match data from the [football-data.org API](https://www.football-data.org/), stores raw JSON records in Amazon S3, transforms them into optimized Parquet datasets, and prepares analytical tables for downstream BI applications.

The main objective is to demonstrate how to design and implement a scalable, automated, and cost-efficient cloud-native data platform.

---

## 📌 1. Project Overview

The project follows a serverless architecture organized around two main data lake layers:

- **Raw Layer:** Stores original API responses in JSON format, preserving the ingested data.
- **Curated Layer:** Contains cleaned, transformed, compressed, and partitioned Parquet datasets optimized for analytical queries.

AWS Step Functions coordinates the execution of the different pipeline stages, while EventBridge triggers automated daily executions.

### Architecture Diagram

```text
                 ┌──────────────────────────┐
                 │    football-data.org     │
                 │        REST API          │
                 └────────────┬─────────────┘
                              │
                              ▼
                 ┌──────────────────────────┐
                 │    Amazon EventBridge    │
                 │     Daily Scheduler      │
                 └────────────┬─────────────┘
                              │
                              ▼
                 ┌──────────────────────────┐
                 │     AWS Step Functions   │
                 │    Pipeline Orchestrator │
                 └────────────┬─────────────┘
                              │
                              ▼
                 ┌──────────────────────────┐
                 │       AWS Lambda         │
                 │       Python 3.12        │
                 │     Data Ingestion       │
                 └────────────┬─────────────┘
                              │
                              ▼
                 ┌──────────────────────────┐
                 │        Amazon S3         │
                 │       RAW LAYER          │
                 │        JSON              │
                 └────────────┬─────────────┘
                              │
                              ▼
                 ┌──────────────────────────┐
                 │       AWS Glue           │
                 │       Data Catalog       │
                 └────────────┬─────────────┘
                              │
                              ▼
                 ┌──────────────────────────┐
                 │      Amazon Athena       │
                 │   SQL Transformations    │
                 │      CTAS Queries        │
                 └────────────┬─────────────┘
                              │
                              ▼
                 ┌──────────────────────────┐
                 │        Amazon S3         │
                 │      CURATED LAYER       │
                 │    Parquet + Snappy      │
                 │  Partitioned Datasets   │
                 └────────────┬─────────────┘
                              │
                              ▼
                 ┌──────────────────────────┐
                 │     BI & Analytics       │
                 │  Power BI / Looker       │
                 └──────────────────────────┘
```

---

## 🛠️ 2. Technologies & AWS Services

| Category | Technology | Responsibility |
|---|---|---|
| Programming | Python 3.12 | Data ingestion and processing |
| Data Source | football-data.org API | Football standings and fixtures |
| Cloud Platform | AWS | Cloud infrastructure |
| Data Ingestion | AWS Lambda | Serverless API extraction |
| Object Storage | Amazon S3 | Raw and curated data storage |
| Orchestration | AWS Step Functions | Pipeline execution and dependencies |
| Scheduling | Amazon EventBridge | Automated daily execution |
| Metadata Management | AWS Glue Catalog | Table schemas and metadata |
| Data Transformation | Amazon Athena | SQL transformations and CTAS |
| Data Format | Apache Parquet | Columnar analytical storage |
| Compression | Snappy | Storage and query optimization |
| Analytics | SQL | Football performance analysis |
| Version Control | Git / GitHub | Source code management |

---

## 🏗️ 3. Data Lake Architecture

The data lake is hosted in Amazon S3 using a multi-layer architecture.

**S3 Bucket:**

```text
s3://football-analytics-branish/
```

### 3.1 Raw Layer — JSON

The Raw Layer stores the original API responses retrieved from football-data.org.

Its main purpose is to preserve the source data and provide a foundation for reproducible transformations.

```text
football-analytics-branish/
│
├── raw/
│   ├── standings/
│   │   └── year=2026/
│   │       └── month=11/
│   │           └── ...
│   │
│   └── fixtures/
│       └── year=2026/
│           └── month=11/
│               └── ...
```

Key characteristics:

- Original JSON payloads.
- Time-based folder organization.
- Separation between standings and fixtures.
- Historical data preservation.
- Independent ingestion and transformation layers.

### 3.2 Curated Layer — Parquet

The Curated Layer contains transformed datasets designed for analytical workloads.

Raw JSON records are processed through Athena SQL queries and materialized using CTAS (CREATE TABLE AS SELECT).

The resulting datasets use:

- Apache Parquet columnar format.
- Snappy compression.
- Partitioned storage.
- Cleaned and structured records.
- Athena-compatible schemas.

```text
football-analytics-branish/
│
├── curated/
│   ├── standings/
│   │   └── ...
│   │
│   └── matches/
│       ├── status=FINISHED/
│       ├── status=SCHEDULED/
│       └── ...
│
└── athena-query-results/
```

**Why Parquet and Snappy?**

Compared with raw JSON, Parquet provides several advantages:

- Columnar storage.
- Efficient compression.
- Reduced data scanning for analytical queries.
- Faster filtering and aggregation.
- Better integration with Athena and BI tools.

Partitioning the matches dataset by `status` also enables partition pruning, reducing unnecessary data reads when queries filter by match status.

---

## ⚙️ 4. Data Pipeline Workflow

The pipeline is coordinated through AWS Step Functions.

Each execution follows a sequence of ingestion, metadata management, and transformation tasks.

### Step 1 — Automated Trigger

Amazon EventBridge schedules the pipeline execution.

```text
EventBridge
    |
    ▼
Step Functions State Machine
```

The scheduler triggers the workflow automatically according to the configured schedule.

### Step 2 — Data Ingestion

AWS Lambda executes the Python ingestion logic.

The Lambda function:

1. Calls the football-data.org REST API.
2. Retrieves standings and fixtures.
3. Processes the API responses.
4. Organizes the output by dataset and ingestion date.
5. Uploads the raw JSON files to Amazon S3.

```text
football-data.org API
         |
         ▼
    AWS Lambda
         |
         ▼
    Amazon S3
      RAW JSON
```

### Step 3 — Metadata Management

AWS Glue Data Catalog manages the metadata associated with the analytical tables.

Athena uses the catalog to identify table schemas, locations, and available columns.

SQL definitions are used to create external tables and analytical views.

### Step 4 — Data Cleaning and Transformation

Amazon Athena executes SQL transformations to prepare clean datasets.

The pipeline uses analytical views such as:

- `v_matches_clean`
- `v_standings_latest`

These views provide structured access to the ingested data.

### Step 5 — Curated Data Materialization

Athena CTAS queries materialize the cleaned datasets into physical Parquet tables.

Example configuration:

```sql
WITH (
    format = 'PARQUET',
    write_compression = 'SNAPPY',
    external_location = 's3://football-analytics-branish/curated/matches/',
    partitioned_by = ARRAY['status']
)
```

The result is a compressed, columnar, partitioned dataset optimized for downstream analytical queries.

### Step 6 — Orchestration and Execution Management

AWS Step Functions coordinates the different pipeline stages.

The state machine manages:

- Lambda invocation.
- Task dependencies.
- Athena query execution.
- Metadata cleanup.
- Transformation sequencing.
- Workflow execution status.

This centralizes pipeline orchestration and makes the execution process easier to monitor and maintain.

---

## 🔄 5. AWS Step Functions Orchestration

The pipeline uses an AWS Step Functions State Machine to coordinate the end-to-end workflow.

The orchestration layer separates data extraction from analytical transformations.

Conceptually, the execution follows:

```text
START
  |
  ▼
TriggerLambdaIngestion
  |
  ▼
DropExistingCuratedTables
  |
  ▼
RunStandingsCTAS
  |
  ▼
RunMatchesCTAS
  |
  ▼
SUCCESS
```

The actual state machine is maintained in:

```text
orchestration/
└── step_functions_pipeline.json
```

This approach provides a centralized execution layer and allows individual pipeline stages to be monitored independently.

---

## 📊 6. Analytical SQL Queries

The Curated Layer provides a foundation for football performance analysis.

The following examples demonstrate some of the analytical queries developed with Amazon Athena.

### 6.1 Teams Unbeaten at Home

Identify teams that have not lost any completed home matches.

```sql
SELECT
    home_team,
    COUNT(*) AS total_home_matches,

    COUNT(
        CASE WHEN winner = 'HOME_TEAM'
        THEN 1 END
    ) AS home_wins,

    COUNT(
        CASE WHEN winner = 'DRAW'
        THEN 1 END
    ) AS home_draws,

    COUNT(
        CASE WHEN winner = 'AWAY_TEAM'
        THEN 1 END
    ) AS home_losses

FROM football_analytics.v_matches_clean

WHERE status = 'FINISHED'

GROUP BY home_team

HAVING COUNT(
    CASE WHEN winner = 'AWAY_TEAM'
    THEN 1 END
) = 0

ORDER BY home_wins DESC;
```

### 6.2 High-Scoring Matches

Identify matches with at least four goals.

```sql
SELECT
    match_date,
    home_team,
    home_score,
    away_team,
    away_score,

    (home_score + away_score) AS total_goals

FROM football_analytics.v_matches_clean

WHERE (home_score + away_score) >= 4
  AND UPPER(status) = 'FINISHED'

ORDER BY total_goals DESC;
```

### 6.3 Analytical Use Cases

The datasets can also support:

- League standings analysis.
- Home and away performance comparisons.
- Team scoring statistics.
- Match outcome distributions.
- High-scoring match detection.
- Historical match analysis.
- League-level performance indicators.

---

## 📁 7. Repository Structure

```text
football-analytics-pipeline/
│
├── orchestration/
│   └── step_functions_pipeline.json
│       # AWS Step Functions state machine
│
├── sql/
│   ├── ddl_views.sql
│   │   # External tables and analytical views
│   │
│   ├── curated_parquet_ctas.sql
│   │   # CTAS transformations and Parquet materialization
│   │
│   └── analytics_queries.sql
│       # Football analytical SQL queries
│
├── src/
│   └── local_ingest.py
│       # Local ingestion testing
│
├── lambda_function.py
│   # AWS Lambda production handler
│
├── requirements.txt
│   # Python dependencies
│
├── .gitignore
│
└── README.md
```

---

## 🚀 8. Getting Started

### Prerequisites

Before running the project, make sure you have:

- Python 3.12+
- An AWS account.
- AWS CLI configured.
- Appropriate IAM permissions.
- An API token from football-data.org.
- Access to Amazon S3, Lambda, Athena, Glue, EventBridge, and Step Functions.

### 8.1 Clone the Repository

```bash
git clone https://github.com/branis192/football-analytics-pipeline.git

cd football-analytics-pipeline
```

### 8.2 Create a Virtual Environment

```bash
python3 -m venv venv
```

Activate it:

**Linux / macOS**

```bash
source venv/bin/activate
```

**Windows**

```powershell
venv\Scripts\activate
```

### 8.3 Install Dependencies

```bash
pip install -r requirements.txt
```

### 8.4 Configure AWS Credentials

Configure your AWS CLI:

```bash
aws configure
```

Provide the required credentials and AWS region.

The Lambda function should retrieve the football-data.org API token from a secure configuration mechanism such as AWS Secrets Manager or an encrypted Lambda environment variable.

Never commit API tokens, AWS credentials, or other secrets to GitHub.

### 8.5 Run Local Ingestion Tests

```bash
python src/local_ingest.py
```

This script can be used to test the extraction logic before deploying it to AWS Lambda.

---

## ☁️ 9. AWS Deployment

The project relies on AWS managed services.

The main deployment steps are:

1. Create the S3 bucket and configure the data lake folders.
2. Deploy the Lambda ingestion function.
3. Configure the required IAM permissions.
4. Create the Glue database and register the external tables.
5. Execute the SQL definitions in Athena.
6. Deploy the Step Functions state machine.
7. Configure the EventBridge schedule.
8. Validate the end-to-end execution.

### S3 Bucket

```text
football-analytics-branish
```

### Athena Database

```text
football_analytics
```

### SQL Resources

```text
sql/
├── ddl_views.sql
├── curated_parquet_ctas.sql
└── analytics_queries.sql
```

### Orchestration Resource

```text
orchestration/
└── step_functions_pipeline.json
```

---

## 📈 10. Performance & Cost Optimization

Several design decisions were made to improve analytical performance and control cloud costs.

| Optimization | Implementation | Benefit |
|---|---|---|
| Columnar storage | Apache Parquet | Efficient analytical reads |
| Compression | Snappy | Reduced storage footprint |
| Partitioning | `status` | Partition pruning |
| SQL transformations | Athena CTAS | Materialized datasets |
| Serverless compute | Lambda and Athena | No permanent compute infrastructure |
| Workflow orchestration | Step Functions | Centralized execution management |
| Automated scheduling | EventBridge | Reduced manual operations |

**Important:** Actual query cost and performance improvements depend on dataset size, query patterns, partition selectivity, and the amount of data scanned. They should be measured through Athena execution statistics rather than assumed.

---

## 🗺️ 11. Project Roadmap

### ✅ Completed

- [x] Connect to the football-data.org API.
- [x] Develop Python ingestion scripts for standings and fixtures.
- [x] Implement local ingestion testing.
- [x] Deploy AWS Lambda for automated data extraction.
- [x] Store raw JSON records in Amazon S3.
- [x] Organize the Raw Layer using time-based folders.
- [x] Create AWS Glue Catalog metadata.
- [x] Define Athena external tables.
- [x] Develop SQL analytical views.
- [x] Implement `v_standings_latest`.
- [x] Implement `v_matches_clean`.
- [x] Create Curated Layer using Athena CTAS.
- [x] Materialize datasets in Apache Parquet format.
- [x] Enable Snappy compression.
- [x] Implement partitioning by match status.
- [x] Develop analytical SQL queries.
- [x] Implement AWS Step Functions orchestration.
- [x] Integrate Lambda and Athena execution stages.
- [x] Configure EventBridge scheduling.

### 🚧 Next Steps

- [ ] Connect Amazon Athena to Power BI or Looker Studio.
- [ ] Build interactive football analytics dashboards.
- [ ] Implement automated data quality checks.
- [ ] Add schema validation and ingestion error handling.
- [ ] Implement CI/CD using GitHub Actions.
- [ ] Automate AWS infrastructure deployment using Terraform or AWS CDK.
- [ ] Add pipeline execution alerts using Amazon SNS.
- [ ] Implement historical data backfills.
- [ ] Improve monitoring and observability.

---

## 🎯 12. Key Data Engineering Skills Demonstrated

This project demonstrates practical experience across several areas of modern Data Engineering.

**Data Ingestion**
- REST API integration.
- Python-based extraction.
- Serverless ingestion with AWS Lambda.
- JSON data handling.

**Cloud Data Engineering**
- Amazon S3 Data Lake architecture.
- Raw and Curated storage layers.
- AWS Glue Data Catalog.
- Amazon Athena.

**Data Transformation**
- SQL-based data cleaning.
- Analytical views.
- CTAS materialization.
- Parquet conversion.
- Snappy compression.
- Partition pruning.

**Cloud Orchestration**
- AWS Step Functions.
- Amazon EventBridge.
- Serverless workflow automation.
- Multi-stage pipeline execution.

**Analytics**
- Football performance analysis.
- SQL aggregations.
- Match outcome analysis.
- BI-ready datasets.

---

## 👨‍💻 13. Author

**Branis HOUCHI**

Data Engineering | Python | SQL | AWS | Cloud Computing

GitHub: [@branis192](https://github.com/branis192)

Repository: [football-analytics-pipeline](https://github.com/branis192/football-analytics-pipeline)

---

## ⭐ Final Thoughts

This project demonstrates how to build a complete serverless data pipeline using AWS managed services, from raw API ingestion to optimized analytical datasets.

By combining Python, SQL, Amazon S3, Lambda, Glue, Athena, Step Functions, and EventBridge, the project showcases essential Data Engineering skills:

**Data Ingestion → Data Lake → Data Transformation → Orchestration → Analytics**

The next objective is to extend this platform with interactive BI dashboards, automated data quality validation, infrastructure as code, and CI/CD deployment.

If you find this project useful, feel free to ⭐ the repository!
