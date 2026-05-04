# Trust Service Criteria Reference

The five SOC 2 Trust Service Criteria (TSC) categories defined by the AICPA. Security is mandatory; the others are selected based on business need. The IDs below match the IDs that `scripts/control_matrix_builder.py` emits and `scripts/gap_analyzer.py` checks for.

## Security — Common Criteria (CC1-CC9)

Mandatory for every SOC 2 report. Aligned to the COSO 2013 internal-control framework.

| ID | Criterion | Example evidence |
|----|-----------|------------------|
| CC1.1 | Integrity and ethical values | Code of conduct, ethics policy, signed acknowledgments |
| CC1.2 | Board oversight | Board meeting minutes, oversight committee charters |
| CC1.3 | Organizational structure | Org charts, RACI matrices, role descriptions |
| CC1.4 | Competence commitment | Training records, competency assessments, HR policies |
| CC1.5 | Accountability | Performance reviews, disciplinary policy, accountability matrix |
| CC2.1 | Information quality | Information classification policy, data flow diagrams |
| CC2.2 | Internal communication | Internal communications, policy distribution records |
| CC2.3 | External communication | Customer notifications, external communication policy |
| CC3.1 | Risk objectives | Risk assessment methodology, risk register |
| CC3.2 | Risk identification | Risk assessment report, threat modeling documentation |
| CC3.3 | Fraud risk consideration | Fraud risk assessment, anti-fraud controls |
| CC3.4 | Change risk assessment | Change impact assessments, environmental scan reports |
| CC4.1 | Monitoring evaluations | Monitoring dashboards, automated alert configurations |
| CC4.2 | Deficiency communication | Deficiency tracking log, management reports |
| CC5.1 | Control activities selection | Control matrix, risk treatment plans |
| CC5.2 | Technology controls | IT general controls documentation, technology policies |
| CC5.3 | Policy deployment | Policy library, procedure documents, acknowledgment records |
| CC6.1 | Logical access security | Access control policy, IAM configuration, SSO/MFA settings |
| CC6.2 | Access provisioning | Provisioning tickets, role matrix, access request approvals |
| CC6.3 | Access removal | Deprovisioning tickets, termination checklists |
| CC6.4 | Access review | Access review reports, user entitlement listings |
| CC6.5 | Physical access | Badge access logs, visitor logs, physical security configuration |
| CC6.6 | Encryption | TLS configuration, encryption settings, certificate inventory |
| CC6.7 | Data transmission restrictions | DLP configuration, network segmentation, firewall rules |
| CC6.8 | Unauthorized software prevention | Endpoint protection config, software whitelist, malware scans |
| CC7.1 | Vulnerability management | Vulnerability scan reports, remediation SLAs, patch records |
| CC7.2 | Anomaly monitoring | SIEM configuration, alert rules, monitoring dashboards |
| CC7.3 | Event evaluation | Incident classification criteria, triage procedures |
| CC7.4 | Incident response | Incident response plan, incident tickets, postmortems |
| CC7.5 | Incident recovery | Recovery records, lessons learned documentation |
| CC8.1 | Change management | Change tickets, approval records, test results, deployment logs |
| CC9.1 | Vendor risk management | Vendor risk assessments, vendor register, vendor SOC 2 reports |
| CC9.2 | Risk mitigation/transfer | Insurance policies, risk transfer documentation |

## Availability (A1)

| ID | Criterion | Example evidence |
|----|-----------|------------------|
| A1.1 | Capacity and performance management | Capacity dashboards, scaling policies, uptime/SLA reports |
| A1.2 | Backup and recovery | Backup logs, DR plan, BCP plan, communication tree |
| A1.3 | Recovery testing | DR test results, RTO/RPO measurements, failover test records |

## Confidentiality (C1)

| ID | Criterion | Example evidence |
|----|-----------|------------------|
| C1.1 | Confidential data identification | Data classification policy, data inventory, data flow diagrams |
| C1.2 | Confidential data protection | Encryption configuration, access control lists, DLP alerts |
| C1.3 | Confidential data disposal | Disposal procedures, sanitization certificates, retention compliance |

## Processing Integrity (PI1)

| ID | Criterion | Example evidence |
|----|-----------|------------------|
| PI1.1 | Processing accuracy | Validation rules, reconciliation reports, checksum verification |
| PI1.2 | Processing completeness | Transaction logs, completeness dashboards, error handling procedures |
| PI1.3 | Processing timeliness | SLA reports, processing time metrics, batch job monitoring |
| PI1.4 | Processing authorization | Authorization matrix, segregation-of-duties controls, approval workflows |

## Privacy (P1-P8)

| ID | Criterion | Example evidence |
|----|-----------|------------------|
| P1.1 | Privacy notice | Privacy policy, data collection notices, purpose statements |
| P2.1 | Choice and consent | Consent records, opt-in/opt-out mechanisms, preference center |
| P3.1 | Data collection | Data collection audit, lawful basis records |
| P4.1 | Use and purpose limitation | Data use policy, purpose limitation controls, access restrictions |
| P4.2 | Retention and disposal | Retention schedule, deletion logs, disposal certificates |
| P5.1 | Access rights (DSAR) | DSAR log, response records, processing timelines |
| P5.2 | Correction rights | Correction request records, data update logs |
| P6.1 | Disclosure controls | Data sharing agreements, third-party inventory, DPAs |
| P6.2 | Breach notification | Breach response plan, notification templates, incident records |
| P7.1 | Data quality | Data quality reports, accuracy checks, correction logs |
| P8.1 | Privacy monitoring and enforcement | Privacy audits, compliance dashboards, complaint tracking |
