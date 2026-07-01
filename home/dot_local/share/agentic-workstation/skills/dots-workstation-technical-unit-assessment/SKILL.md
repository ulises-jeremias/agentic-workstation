---
name: dots-workstation-technical-unit-assessment
description: >-
  WHAT - Evidence-based technical unit assessment for repositories, platforms,
  frontend, backend, infrastructure, data, UI/UX, and AI-native structural readiness.
---

# Technical Unit Assessment (WHAT)

Use this skill to assess a technical unit: frontend app, backend API, data platform, infrastructure/IaC scope, mobile app, AI/ML pipeline, or another technical workload.

Run **`dots-workstation-project-assessment-evidence`** first and use **`dots-workstation-project-assessment`** as the router when the assessment spans multiple units.

## Default guardrails

1. Apply **`dots-workstation-output-handshake`** before final scorecards or reports.
2. Ask where each evidence source lives before scoring.
3. Score only indicators that match the unit type and available evidence.
4. Mark every score with evidence links and confidence.
5. Use **Not assessed** when evidence is missing or the indicator is out of scope.

## Unit intake

Ask:

- What is the technical unit name?
- What type of unit is it?
- Which repositories, services, infrastructure scopes, data pipelines, design assets, or environments are included?
- Who owns technical decisions: agentic-workstation users, client/team counterpart, shared ownership, or unknown?
- What period should the assessment cover?
- Which systems are authoritative for code, docs, CI/CD, releases, incidents, observability, architecture, security, and data quality?

## Indicator groups

Use only the groups that match the unit.

### General technical indicators

- Repository links
- Unit type
- Unit name
- Documentation links
- Technical decision responsibility
- Code quality
- Deployment tools
- Development experience
- Monitoring and observability
- Security awareness
- Technical debt volume
- Workflow definition
- Testing

### Frontend indicators

- Frontend languages
- Responsiveness
- Accessibility
- Performance
- UI/UX design
- Frontend testing coverage
- Frontend dependency management

### Backend indicators

- Backend frameworks and libraries
- API documentation
- Databases and storage
- Backend languages
- Backend testing coverage
- API versioning
- Scalability
- Error handling
- Backend dependency management

### Cloud infrastructure and DevSecOps indicators

- Security testing
- Compliance
- CI/CD
- Infrastructure as Code
- Automated environment bootstrapping
- Environment consistency and isolation
- Secrets management
- Role-based access control
- Backup, retention, and recovery
- Disaster recovery and resilience
- Infrastructure monitoring
- Pipeline infrastructure monitoring
- Cost monitoring and budget controls
- Incident response and postmortems
- Continuous security

### Cloud data engineering indicators

- Data sources
- Data architecture documentation
- Data modeling and schema management
- Pipeline orchestration and reliability
- Data quality management
- Data lineage and traceability
- Storage strategy and optimization
- Data governance and access control
- Security and compliance
- Monitoring and observability for data pipelines
- Scalability and performance
- Testing and validation coverage for data workflows
- Documentation of business rules and metrics
- Data delivery and consumption readiness

### UI/UX indicators

- User interface design
- Responsiveness
- Accessibility
- User-centered design
- Usability
- Visual aesthetics

For deep UI review, delegate to **`ui-ux-pro-max`** and bring back findings as evidence.

### AI-native structural readiness

This does not measure tool usage. It measures whether AI assistance can safely understand and modify the system:

- Codebase explicitness and architectural clarity
- Deterministic build and delivery systems
- Observability and operational transparency
- Testability and validation density
- Dependency and change impact transparency

## Scoring rules

- Use the 1 to 5 maturity scale.
- Score 1 means low, reactive, implicit, undocumented, or highly variable.
- Score 3 means defined, observable, or partially mature with consistency gaps.
- Score 5 means explicit, repeatable, measurable, and evidence-driven.
- Do not average unrelated indicators without explaining weighting.
- For subjective scores, request a validator and record consensus status.

## Output

Use `references/default-template.md` for the technical unit scorecard. `references/example-frontend-assessment.md` — example assessment for a frontend engineering team.

## References

- `references/default-template.md` - default technical unit template
- `dots-workstation-project-assessment-evidence` - evidence map
- `dots-workstation-project-assessment` - multi-unit router
- `dots-workstation-assistant` - repository discovery
- `ui-ux-pro-max` - deep UI/UX review when needed
