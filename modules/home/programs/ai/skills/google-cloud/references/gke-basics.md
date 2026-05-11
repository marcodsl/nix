
# Google Kubernetes Engine (GKE) Basics

GKE is a managed Kubernetes platform on Google Cloud for deploying, scaling, and operating containerized applications. This skill defaults to the **golden path Autopilot configuration** — see [gke-golden-path.md](./gke-basics/gke-golden-path.md) for defaults, rules, and guardrails.

## Quick Start

```bash
gcloud services enable container.googleapis.com
gcloud container clusters create-auto my-cluster --region=us-central1
gcloud container clusters get-credentials my-cluster --region=us-central1
kubectl create deployment hello-server \
  --image=us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0
```

## Reference Directory

Load the relevant reference based on trigger keywords. Prefer the most specific match; if ambiguous, ask the user to clarify.

| Scenario | Trigger Keywords | Reference |
|----------|-----------------|-----------|
| Core Concepts | Autopilot vs Standard, architecture, pricing, what is GKE | [core-concepts.md](./gke-basics/core-concepts.md) |
| Golden Path & Defaults | golden path, Day-0 checklist, production defaults, cluster defaults | [gke-golden-path.md](./gke-basics/gke-golden-path.md) |
| Cluster Creation | create cluster, new cluster, provision GKE | [gke-cluster-creation.md](./gke-basics/gke-cluster-creation.md) |
| Networking | private cluster, VPC, subnet, Gateway API, DNS, ingress, egress, datapath | [gke-networking.md](./gke-basics/gke-networking.md) |
| Security & IAM | Workload Identity, Secret Manager, RBAC, Binary Auth, hardening, audit, gVisor, IAM roles | [gke-security.md](./gke-basics/gke-security.md) |
| Scaling | HPA, VPA, autoscaler, autoscaling, NAP, scale pods, scale nodes | [gke-scaling.md](./gke-basics/gke-scaling.md) |
| Compute Classes | ComputeClass, machine family, Spot fallback, GPU node pool, node selection | [gke-compute-classes.md](./gke-basics/gke-compute-classes.md) |
| Cost | cost, savings, Spot VMs, rightsizing, CUD, optimize spend, budget | [gke-cost.md](./gke-basics/gke-cost.md) |
| AI/ML Inference | inference, model serving, LLM, GPU, TPU, GIQ, vLLM | [gke-inference.md](./gke-basics/gke-inference.md) |
| Upgrades | upgrade, maintenance window, release channel, patching, version | [gke-upgrades.md](./gke-basics/gke-upgrades.md) |
| Observability | monitoring, logging, Prometheus, Grafana, metrics, alerts, dashboards | [gke-observability.md](./gke-basics/gke-observability.md) |
| Multi-tenancy | multi-tenant, namespace isolation, team access, enterprise, RBAC planning | [gke-multitenancy.md](./gke-basics/gke-multitenancy.md) |
| Batch & HPC | batch, HPC, job queue, high performance, MPI, parallel | [gke-batch-hpc.md](./gke-basics/gke-batch-hpc.md) |
| App Onboarding | containerize, deploy app, Dockerfile, onboard, migrate to GKE | [gke-app-onboarding.md](./gke-basics/gke-app-onboarding.md) |
| Backup & DR | backup, restore, disaster recovery, CMEK | [gke-backup-dr.md](./gke-basics/gke-backup-dr.md) |
| Storage | storage, PVC, persistent volume, StorageClass, Filestore, GCS FUSE | [gke-storage.md](./gke-basics/gke-storage.md) |
| Reliability | PDB, health probe, liveness, readiness, topology spread, graceful shutdown | [gke-reliability.md](./gke-basics/gke-reliability.md) |
| Client Libraries | client library, client-go, kubernetes python, kubernetes java, kubernetes SDK | [client-library-usage.md](./gke-basics/client-library-usage.md) |
| Infrastructure as Code | Terraform, IaC, HCL, infrastructure as code | [iac-usage.md](./gke-basics/iac-usage.md) |
| MCP Server | MCP tools, MCP server, MCP setup | [mcp-usage.md](./gke-basics/mcp-usage.md) |
| CLI / Tools | gcloud, kubectl, commands, how to | [cli-reference.md](./gke-basics/cli-reference.md) |
| Production Audit | production readiness, compliance, golden path check | [gke-cluster-creation.md](./gke-basics/gke-cluster-creation.md) |

*If you need product information not found in these references, use the Developer Knowledge MCP server `search_documents` tool.*
