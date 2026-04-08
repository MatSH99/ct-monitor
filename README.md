# ct-monitor
Main repository for a CT monitoring infrastructure. It handles the deployment and orchestration of custom API and Indexer tools, leveraging specialized forks of Google's Tesseract and CT-Go to support AWS-native features, IAM authentication and high-performance log scanning.

## System Architecture

The system is designed for AWS cloud-native environments:
- **Log Storage:** AWS S3 (Artifacts, Tiles, Checkpoints).
- **Log State & Antispam:** AWS Aurora MySQL.
- **Certificate Index:** AWS DynamoDB (Primary Key: `domain_name`, Sort Key: `cert_index`).
- **Cryptographic Signer:** AWS Secrets Manager (storing ECDSA P-256 keys).
- **IaC:** Terragrunt / OpenTofu (Terraform).

## Service Components

### 1. Domain Indexer
The indexer processes certificate bundles and stores entries in DynamoDB for fast lookups.
* **Logic:** It tracks the `last_index` in a special DynamoDB item (`INTERNAL_STATE`) to resume scanning after restarts.
* **Parsing:** Uses a custom `lax509` parser to handle malformed certificates often found in CT logs.
* **Precertificates:** Specifically detects and extracts domains from the `TBSCertificate` of precertificates.

### 2. Search API
Provides a RESTful interface for the indexed data.
* **Endpoint:** `GET /search?q=example.com`, `GET /certificate?index=123456`
* **Caching:** Implements an LRU-style cache for log tiles to reduce S3 GET requests.
* **Efficiency:** Uses DynamoDB Query operations on the `domain_name` partition key for O(1) lookups.

## Prerequisites

Before deployment, ensure your environment (EC2) has the following installed:

* **AWS CLI**: Authenticated with an IAM identity that has full access to S3, DynamoDB, RDS and Secrets Manager.
* **Docker & Docker Compose**: (v2.20+ recommended).
* **Terraform (v1.5+) & Terragrunt (v0.50+)**: For Infrastructure as Code management.
* **jq**: Required for the `start.sh` automation script.
* **Git**: To manage submodules.
* **Go**: Required to compile.

## Setup & Deployment

Follow these steps in order to ensure the Monitor correctly attaches to the Tesseract core outputs.

---

### 1. Initialize Repository

Clone the suite and initialize the Tesseract submodule:
```bash
git clone --recursive https://github.com/MatSH99/ct-monitor.git (--recursive is mandatory to automatically download the required Tesseract and CT-Go forks)
cd ct-monitor
```

### 2. Core Deployment (TesseraCT)

Deploy the storage and log server first. This provides the S3 bucket and Aurora credentials needed by the Monitor.
```bash
# Navigate to Tesseract's deployment folder
cd tesseract/deployment/live/aws/test

# Deploy core storage and database
terragrunt apply
```

### 3. Indexing Deployment (DynamoDB)

Deploy the DynamoDB table. This module automatically fetches the environment prefix from the Tesseract deployment via Terragrunt dependencies.
```bash
cd ../../../infrastructure/live

# Apply DynamoDB infrastructure
terragrunt apply
```

#### Configuration:
* Partition Key: domain_name (S)
* Sort Key: cert_index (N)
* GSI: RootIndex (PK: root_name)

### 4. Build and Launch

Build the Docker images (which compile the Go binaries for Tesseract, Indexer, API, and Preloader) and start the suite using the automated bridge script.
```bash
cd ../../../

make build
chmod +x start.sh
```

**Pass Docker commands you want**
The suite is divided into two ingestion streams: Live and History. You can run them individually, together, or with custom overrides.
* **Start only Real-time monitoring:** To start monitoring logs from their current size (Real-time only):
  ./start.sh up -d preloaders-live
* **Start only Historical backfilling:** To start downloading all certificates from index 0:
  ./start.sh up -d preloaders-history
* **Hybrid Mode:** To track new certificates in real-time while simultaneously recovering the past in the background:
  ./start.sh up -d preloaders-live preloaders-history
* **Precision Strike (Custom Flags & Overrides):** If you want total freedom to decide the starting index and performance flags for a specific run:
  // Start from index 50M with 20 workers and a huge batch size
  ./start.sh run --rm preloaders-history --start_index=50000000 --num_workers=20 --batch_size=5000

## Operational Logic

### Smart Start-Index Detection

The internal run_preloaders.sh orchestrator follows this priority:
* **Manual Override:** If you pass --start_index=X, it forces that index.
* **Live Tip:** If no index is provided, it automatically fetches the current Log Size (STH) and starts from there.
* **Transparency:** Any additional flag (e.g., --num_workers, --batch_size) is passed directly to the preloader binaries

### Dependency Chain

The system uses Docker depends_on logic. Launching a preloader will automatically trigger:

* **setup-discovery:** Downloads Trusted Roots.
* **tesseract:** Starts the core server.
* **indexer:** Starts the S3-to-DynamoDB processing.

## Operational Workflow

* **Log Discovery:** setup_discovery.sh fetches the latest log_list.json from Google, identifies usable logs, and downloads their Trusted Root Certificates to /shared.
* **Tesseract Startup:** The server initializes using the shared roots and connects to the Aurora instance.
* **Parallel Preloading:** run_preloaders.sh launches a dedicated preloader for every discovered log. It retrieves the current index from the log's STH or Checkpoint and starts feeding data to Tesseract.
* **Asynchronous Indexing:** The indexer service watches the S3 bucket. As soon as Tesseract writes a new "Tile", the indexer parses the certificates and updates the DynamoDB table.
* **Search:** Users can query the API to find all certificates associated with a specific domain. To do so:
  http://[EC2-public-IP]:8080/v1/search?q=example.com (or just example)
  http://[EC2-public-IP]:8080/v1/certificate?q=[index]

## Maintenance
* Check status: docker compose ps
* Live logs: make logs
* Stop all services: make down
* Wipe temporary data: make clean (Deletes downloaded roots and setup flags)
