---
name: google-cloud
description: "Plan, build, secure, and operate Google Cloud workloads across AlloyDB, BigQuery, Cloud SQL, Cloud Run, Firebase, GKE, and Gemini APIs. Use this for architecture, configuration, troubleshooting, and Google AIP/Well-Architected workflows."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: gcp, google-cloud, alloydb, bigquery, cloud-run, cloud-sql, firebase, gke, gemini, vertex-ai, agent-platform, iam, networking, waf, well-architected, aip, api-design
---

# Google Cloud

Umbrella skill covering Google Cloud services, the Gemini API on Agent Platform, Google AIP API conventions, and the Well-Architected Framework. Pick the branch that matches the task; load multiple branches when the work spans services (e.g., a Cloud Run service hitting BigQuery uses both).

## Routing

| When the task involves… | Read |
| --- | --- |
| AlloyDB for PostgreSQL — clusters, instances, backups, the AlloyDB MCP server | [references/alloydb-basics.md](./references/alloydb-basics.md) |
| BigQuery — datasets, tables, jobs, SQL, BigQuery ML/BQML, Gemini-in-BigQuery | [references/bigquery-basics.md](./references/bigquery-basics.md) |
| Cloud SQL — MySQL, PostgreSQL, or SQL Server instances and databases | [references/cloud-sql-basics.md](./references/cloud-sql-basics.md) |
| Cloud Run — services (HTTP), jobs (event/scheduled), worker pools (always-on background) | [references/cloud-run-basics.md](./references/cloud-run-basics.md) |
| Firebase — mobile and web app development | [references/firebase-basics.md](./references/firebase-basics.md) |
| GKE — cluster creation, networking, security, scaling, observability, AI/ML inference, cost, upgrades | [references/gke-basics.md](./references/gke-basics.md) |
| Gemini API on Agent Platform (Vertex AI) — SDKs, Live API, tools, multimedia, caching, batch, tuning | [references/gemini-api.md](./references/gemini-api.md) |
| Google AIP API design — resource models, standard vs custom methods, field behavior, versioning | [references/google-aip-adoption.md](./references/google-aip-adoption.md) |
| Authentication and authorization — IAM, principals, ADC, service identities, secure access patterns | [references/google-cloud-recipe-auth.md](./references/google-cloud-recipe-auth.md) |
| Networking observability — VPC Flow Logs, NAT, firewall and threat logs, Connectivity Tests, latency/throughput metrics | [references/google-cloud-recipe-networking-observability.md](./references/google-cloud-recipe-networking-observability.md) |
| First steps on Google Cloud — account, billing, projects, deploying a first resource | [references/google-cloud-recipe-onboarding.md](./references/google-cloud-recipe-onboarding.md) |
| Well-Architected Framework — Cost Optimization pillar | [references/google-cloud-waf-cost-optimization.md](./references/google-cloud-waf-cost-optimization.md) |
| Well-Architected Framework — Reliability pillar | [references/google-cloud-waf-reliability.md](./references/google-cloud-waf-reliability.md) |
| Well-Architected Framework — Security pillar (IAM, network, data protection, ops security) | [references/google-cloud-waf-security.md](./references/google-cloud-waf-security.md) |

Each branch carries its own deeper reference set under `references/<branch>/` (core concepts, CLI, client libraries, MCP usage, IaC, IAM/security, and service-specific deep dives). Follow the branch's intra-document links when you need that depth.

## Prerequisites

Most workflows assume:

- An authenticated `gcloud` CLI and an active project. If unset, see `references/google-cloud-recipe-auth.md` and `references/google-cloud-recipe-onboarding.md`.
- The relevant API enabled (`gcloud services enable <api>`).
- Permissions appropriate for the action; per-service IAM detail lives in each branch's `references/<branch>/iam-security.md`.
