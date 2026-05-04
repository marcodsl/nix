# Evidence Collection Guide

How to collect, organize, and automate the evidence an auditor will request. The categories below align with the controls emitted by `scripts/control_matrix_builder.py`.

## Evidence types by control area

| Control area | Primary evidence | Secondary evidence | Concrete tooling examples |
|--------------|------------------|--------------------|---------------------------|
| Access management | User access reviews, provisioning tickets | Role matrix, access logs | Okta access-review export, AWS IAM Access Analyzer report, Jira ticket query |
| Change management | Change tickets, approval records | Deployment logs, test results | GitHub PR audit log, ArgoCD/Spinnaker deployment history, Jira CR workflow |
| Incident response | Incident tickets, postmortems | Runbooks, escalation records | PagerDuty incident export, Jira/Linear incident project, Confluence postmortem template |
| Vulnerability management | Scan reports, patch records | Remediation timelines | Tenable/Qualys/Nessus reports, GitHub Dependabot/CodeQL, AWS Inspector findings |
| Encryption | Configuration screenshots, certificate inventory | Key rotation logs | AWS KMS key rotation events, Cloudflare/ACME cert renewals, TLS scan via testssl.sh |
| Backup & recovery | Backup logs, DR test results | Recovery time measurements | AWS Backup vault reports, restore-test runbook output, Velero backup logs |
| Monitoring | Alert configurations, dashboard screenshots | On-call schedules, escalation records | Datadog/Grafana monitor export, PagerDuty schedules, Splunk/SIEM saved searches |
| Policy management | Signed policies, version history | Training completion records | Vanta/Drata policy library, KnowBe4/HRIS training completion, Git-tracked policy repo |
| Vendor management | Vendor assessments, SOC 2 reports | Contract reviews, risk registers | Vanta vendor inventory, signed DPAs in DocuSign, vendor SOC 2 PDFs in evidence vault |

## Automation opportunities

Move from a once-a-year scramble to evidence that the system collects on its own.

| Area | Approach | Concrete tooling examples |
|------|----------|---------------------------|
| Access reviews | Trigger reviews quarterly, integrate IAM with the ticketing system | Okta + Jira automation, AWS IAM Access Analyzer + EventBridge, Vanta access-review workflow |
| Configuration evidence | IaC snapshots, compliance-as-code, drift detection | AWS Config conformance packs, Terraform state in S3 with versioning, Open Policy Agent |
| Vulnerability scans | Scheduled scanning with auto-generated reports | GitHub Advanced Security weekly digest, Trivy in CI, Snyk weekly summaries |
| Change management | Git-based audit trail (commits, PRs, approvals) | Required reviewers + branch protection, signed commits, GitHub Audit Log API |
| Uptime monitoring | Automated SLA dashboards with historical data | Datadog SLOs, Grafana SLO dashboards, Pingdom/StatusCake reports |
| Backup verification | Automated restore tests with success/failure logging | AWS Backup restore-tests, weekly cron job that exercises the restore runbook and writes results |

## Continuous monitoring

Aim for evidence that already exists when the auditor asks, rather than evidence that is reconstructed during the engagement.

1. **Automated evidence gathering** — scripts and scheduled jobs that pull evidence from each system on a known cadence and drop the result, with timestamp, into the evidence repository.
2. **Control dashboards** — one place where every control owner can see the current state of their controls, with red/yellow/green status.
3. **Alert-based monitoring** — alerts that fire when a control drifts (failed backup, expired cert, missed access review) and route to the owner immediately.
4. **Evidence repository** — a central, versioned, timestamped store of evidence (S3 with object lock, a dedicated Drive folder, or a compliance platform). Every artifact must be traceable to a control ID.

## Operational notes

- Prefer system-of-record exports over screenshots; screenshots are valid but harder to reproduce on demand.
- Capture timestamps inside the evidence (file metadata is not enough) so an auditor can verify the artifact covers the observation period.
- Keep evidence for the audit observation window plus the standard retention period (typically 7 years for financial-context controls).
