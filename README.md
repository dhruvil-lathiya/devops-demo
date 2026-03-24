# DevOps Demo - Portfolio+ Technical Assessment

A containerized Node.js web application deployed on Amazon ECS (EC2 launch type) that displays a unique, incrementing node identifier and configurable application version.

## Architecture

```
                         ┌──────────────┐
                         │  Cloudflare  │
                         │ demo.lathiya │
                         │    .com      │
                         └──────┬───────┘
                                │
                         ┌──────▼───────┐
                    ┌────┤     ALB      ├────┐
                    │    │  (HTTPS:443) │    │
                    │    └──────────────┘    │
                    │                        │
              ┌─────▼──────┐          ┌─────▼──────┐
              │  EC2 (AZ1) │          │  EC2 (AZ2) │
              │ ┌────────┐ │          │ ┌────────┐ │
              │ │Node-01 │ │          │ │Node-02 │ │
              │ │  :3000  │ │          │ │  :3000  │ │
              │ └────────┘ │          │ └────────┘ │
              └─────┬──────┘          └─────┬──────┘
                    │     Private Subnets    │
                    │    ┌──────────────┐    │
                    └────┤   RDS Postgres├────┘
                         │  (node IDs)  │
                         └──────────────┘
```

**Key Components:**
- **VPC**: 2 public subnets + 2 private subnets across 2 AZs
- **ECS Cluster (EC2)**: Auto Scaling Group with `distinctInstance` placement — each container runs on a separate EC2 instance
- **ALB**: HTTPS termination with HTTP→HTTPS redirect
- **RDS PostgreSQL**: Stores node ID assignments for persistent, incrementing identifiers
- **Cloudflare**: DNS management and proxying
- **ACM**: TLS certificate with DNS validation via Cloudflare
- **ECR**: Container image registry with lifecycle policies
- **CloudWatch**: Centralized logging for ECS tasks

## Prerequisites

- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with credentials
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Docker](https://docs.docker.com/get-docker/)
- A Cloudflare account with your domain and an [API token](https://dash.cloudflare.com/profile/api-tokens) (Zone:DNS:Edit permission)

## Project Structure

```
devops-demo/
├── app/                       # Application code
│   ├── server.js              # Express server
│   ├── views/index.ejs        # Web UI template
│   ├── package.json           # Node.js dependencies
│   └── Dockerfile             # Multi-stage Docker build
├── terraform/                 # Infrastructure as Code
│   ├── providers.tf           # AWS + Cloudflare provider config
│   ├── variables.tf           # Input variables
│   ├── vpc.tf                 # VPC, subnets, NAT
│   ├── security-groups.tf     # Security groups
│   ├── iam.tf                 # IAM roles and policies
│   ├── ecr.tf                 # ECR repository
│   ├── ecs.tf                 # ECS cluster, ASG, service
│   ├── alb.tf                 # Load balancer
│   ├── rds.tf                 # PostgreSQL database
│   ├── acm.tf                 # TLS certificate
│   ├── cloudflare.tf          # Cloudflare DNS records
│   ├── cloudwatch.tf          # Log groups
│   ├── outputs.tf             # Output values
│   └── terraform.tfvars.example
├── .github/workflows/
│   ├── deploy.yml             # Build, push, and deploy to ECS
│   └── rollback.yml           # Rollback to a previous version
└── README.md
```

## Quick Start

### 1. Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. Build and Push Initial Image

Trigger the **Deploy** workflow manually from GitHub Actions (Actions > Deploy > Run workflow) with version `v1.0`, or push a change to `app/` on `main`.

### 4. Verify

Visit `https://demo.lathiya.com` (or your configured subdomain). Refresh to see the ALB round-robin between Node-01 and Node-02.

## Running Locally

```bash
cd app
npm install

# Without database (uses fallback node ID):
APP_VERSION=v1.0 node server.js

# With a local PostgreSQL:
DB_HOST=localhost DB_PORT=5432 DB_NAME=devops_demo \
DB_USER=postgres DB_PASSWORD=postgres \
APP_VERSION=v1.0 node server.js
```

Then open `http://localhost:3000`.

## CI/CD Pipelines

All deployment and rollback is managed entirely through GitHub Actions -- no scripts needed.

**Setup**: Add `AWS_ROLE_ARN` as a GitHub Actions secret (OIDC-based authentication — no long-lived AWS keys).

### Deploy (`deploy.yml`)

- **Auto-triggers** on push to `main` when `app/` files change
- **Manual trigger** via Actions UI with a version input (e.g., `v2.0`)
- Steps: build Docker image, push to ECR, render new task definition, deploy to ECS with zero-downtime rolling update

### Rollback (`rollback.yml`)

- **Manual trigger only** via Actions UI
- Optionally specify a task definition revision (defaults to previous)
- Validates the target revision exists, then updates the ECS service and waits for stability

## Design Decisions

| Decision | Rationale |
|---|---|
| **ECS EC2 launch type** | Assessment requires containers on "different ECS worker nodes." EC2 with `distinctInstance` placement satisfies this literally. |
| **Bridge networking + dynamic ports** | Standard pattern for ECS EC2. ALB handles port mapping transparently. |
| **RDS for node IDs** | Provides persistent, auto-incrementing IDs that survive container restarts. Also fulfills the RDS bonus requirement. |
| **Single NAT Gateway** | Cost optimization for a demo. Production would use one per AZ. |
| **Secrets Manager for DB creds** | Credentials never stored in code or task definition. ECS injects them at runtime. |
| **`ignore_changes` on task_definition** | Prevents Terraform from reverting deployments made via CI/CD. |
| **OIDC for GitHub Actions** | No long-lived AWS access keys stored in GitHub. |

## Security

- Non-root Docker user
- RDS in private subnets, only accessible from ECS security group
- DB credentials in AWS Secrets Manager
- TLS 1.3 enforced at ALB
- ECR image scanning on push
- SSM agent on EC2 instances (no SSH keys needed)
- Minimal IAM policies (least privilege)

## Costs

Uses free-tier eligible instances (2x `t2.micro` EC2, 1x `db.t2.micro` RDS). Non-free-tier resources (ALB, NAT Gateway) cost ~$5-6 for 3 days.
- Terminate with `terraform destroy` when not in use

## Cleanup

```bash
cd terraform
terraform destroy
```
