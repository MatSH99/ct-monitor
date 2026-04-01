# ct-monitor
Main repository for a CT monitoring infrastructure. It handles the deployment and orchestration of custom API and Indexer tools, leveraging specialized forks of Google's Tesseract and CT-Go to support AWS-native features, IAM authentication, and high-performance log scanning.

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

## Infrastructure Setup

Before running the services, you must provision the AWS resources using the provided Terragrunt configurations located in the deployment/ or test/ directories.
