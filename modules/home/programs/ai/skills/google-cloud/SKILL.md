---
name: google-cloud
description: "Plan, build, secure, and operate Google Cloud workloads. Triggers: `gcloud`, AlloyDB, BigQuery / BQML, Cloud SQL, Cloud Run (services, jobs, worker pools), Firebase, GKE, Vertex AI / Agent Platform / Gemini API, Google AIP API conventions, Well-Architected Framework (Cost, Reliability, Security), VPC Flow Logs, IAM / ADC / service identities, `*.googleapis.com`, `gke-gcloud-auth-plugin`. Skip when: working on AWS, Azure, or cloud-agnostic design with no GCP-specific surface, or pure prompt-engineering for a Gemini model with no GCP infra."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: gcp, google-cloud, alloydb, bigquery, cloud-run, cloud-sql, firebase, gke, gemini, vertex-ai, agent-platform, iam, networking, waf, well-architected, aip, api-design
  version: 3
---

# Google Cloud

<purpose>
Umbrella skill covering Google Cloud services, the Gemini API on Agent Platform, Google AIP API conventions, and the Well-Architected Framework. Pick the branch that matches the task; load multiple branches when work spans services.
</purpose>

<scope>
  <use_when>
  - Designing, configuring, or troubleshooting Google Cloud workloads.
  - Building on the Gemini API or Agent Platform (Vertex AI).
  - Adopting Google AIP API conventions or the Well-Architected Framework.
  </use_when>

  <do_not_use_when>
  - Working with other clouds (AWS, Azure) or generic vendor-neutral concepts.
  - The task is pure prompt-engineering for a Gemini model unrelated to GCP infrastructure.
  </do_not_use_when>
</scope>

<governing_rule>
Route to the branch that matches the task, load multiple branches when work spans services, and let each branch's intra-document links carry the depth.
</governing_rule>

<section name="routing">
Pick the branch(es) matching the task and read the referenced file:

- AlloyDB for PostgreSQL (clusters, instances, backups, MCP server) → `references/alloydb-basics.md`
- BigQuery (datasets, tables, jobs, SQL, BQML, Gemini-in-BigQuery) → `references/bigquery-basics.md`
- Cloud SQL (MySQL, PostgreSQL, SQL Server) → `references/cloud-sql-basics.md`
- Cloud Run (services, jobs, worker pools) → `references/cloud-run-basics.md`
- Firebase (mobile and web app development) → `references/firebase-basics.md`
- GKE (clusters, networking, security, scaling, observability, AI/ML inference, cost, upgrades) → `references/gke-basics.md`
- Gemini API on Agent Platform / Vertex AI (SDKs, Live API, tools, multimedia, caching, batch, tuning) → `references/gemini-api.md`
- Google AIP API design (resource models, standard vs custom methods, field behavior, versioning) → `references/google-aip-adoption.md`
- IAM and authentication (principals, ADC, service identities, secure access) → `references/google-cloud-recipe-auth.md`
- Networking observability (VPC Flow Logs, NAT, firewall logs, Connectivity Tests, latency metrics) → `references/google-cloud-recipe-networking-observability.md`
- First steps on Google Cloud (account, billing, projects, first deploy) → `references/google-cloud-recipe-onboarding.md`
- Well-Architected Framework: Cost Optimization → `references/google-cloud-waf-cost-optimization.md`
- Well-Architected Framework: Reliability → `references/google-cloud-waf-reliability.md`
- Well-Architected Framework: Security → `references/google-cloud-waf-security.md`

Each branch carries deeper references under `references/<branch>/` (core concepts, CLI, client libraries, MCP usage, IaC, IAM/security, service-specific deep dives). Follow the branch's intra-document links when more depth is needed.
</section>

<section name="prerequisites">
Most workflows assume:
- Authenticated `gcloud` CLI with an active project. If unset, read `references/google-cloud-recipe-auth.md` and `references/google-cloud-recipe-onboarding.md`.
- The relevant API enabled via `gcloud services enable <api>`.
- Permissions appropriate for the action; per-service IAM detail lives in each branch's `references/<branch>/iam-security.md`.
</section>
