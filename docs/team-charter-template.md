# Team Charter – CSP451 2026F

Copy this file to `docs/team-charter.md` in your **team** repository, complete every section, and have every member commit their own acknowledgement line in section 7. Due by the end of the Week 1 lab and no later than Sunday, September 13, 2026. Confirm all dates on Blackboard.

The charter is not graded on its own in Week 1. It is an ungraded gate. It is then assessed indirectly in Milestone 1, due Tuesday, October 13, 2026, through the contribution table and the repository history, which are checked against what you promise here.

Fill in every cell. An empty cell is a decision your team has not made yet, and it will surface as an argument in Week 6.

## 1. Team identity

| Field | Value |
|---|---|
| Team name, lowercase, no spaces, used in every Azure resource name | |
| Team size, must be 5 to 7 | |
| Mission statement, one sentence | |
| Chosen stack: Node.js/TypeScript or Python | |
| Reason for the stack choice | |
| Team repository URL | |
| GitHub Projects board URL | |
| Member designated to host the shared team Azure subscription | |
| Primary communication channel | |

Teams outside the range of 5 to 7 are merged or split by the instructor in Week 2.

## 2. Roles

Assign every role. Teams of five combine roles, teams of seven split them. Rotate at least one role after Week 7 and record the rotation in section 8 of this file.

| Role | Member | Responsibilities | Backup member |
|---|---|---|---|
| Team Lead / PM and Docs | | Backlog, agenda, submissions, contribution table | |
| Cloud Infrastructure and IaC Lead | | Resource groups, Bicep, naming, tags | |
| Network and Security Lead | | VNet, NSG, RBAC, Key Vault, threat model | |
| Data and Database Lead | | Schema, migrations, seed data, backup and restore | |
| API and Rules Engine Lead | | OpenAPI contract, rules, reason codes, test vectors | |
| DevOps and Observability Lead | | GitHub Actions, telemetry, dashboards, alerts | |
| QA and Test/Release Lead | | Test suite, pull-request review discipline, release tagging | |
| Client Liaison | | Weekly client progress report, team questions for each client Q&A session, record of client answers. May be an added duty of the Team Lead. | |

## 3. Meeting cadence

| Field | Value |
|---|---|
| Weekly synchronous meeting: day, time, channel | |
| Stand-up format and frequency | |
| Who runs the meeting and who records decisions | |
| Where decisions are recorded | `docs/decision-log.md` |
| Expected response time to a team message | |
| What counts as an acceptable reason to miss a meeting | |

## 4. Branching policy

| Field | Value |
|---|---|
| Protected branches | `main` at minimum |
| Branch naming pattern | `feature/<studentID>-<description>`, `fix/...`, `docs/...` |
| Minimum approving reviews before merge | |
| Merge strategy, squash recommended | |
| Who may merge to `main` | |
| Policy on force pushes | Prohibited on protected branches |
| Frequency of syncing with the course upstream repository | |
| Release tags this term | `midterm` in Week 7, `rc1` in Week 13, `v1.0` in Week 14 |

## 5. Definition of done

A work item is done only when every line below is true. Edit the list to fit your team, but do not shorten it below these items.

1. The code or document is on a feature branch and merged through a reviewed pull request.
2. Automated checks pass, once the pipeline exists in Week 2.
3. The naming convention and all five tags are applied to any Azure resource created.
4. No secret, key, or connection string is present in the change.
5. Only synthetic data is used.
6. Documentation is updated in the same pull request as the change.
7. The work item on the GitHub Projects board is moved to Done with the pull request linked.

## 6. Conflict process

| Stage | Action | Time limit |
|---|---|---|
| 1 | Raise the issue directly with the person, in the team channel or a call | Within 2 working days |
| 2 | Team lead facilitates a short discussion, decision recorded in the decision log | Within 4 working days |
| 3 | Team escalates to the instructor with the decision log entry attached | Before the next submission deadline |

Complete these three as well. They are the ones teams regret not writing down.

| Question | Your team's answer |
|---|---|
| How is a non-contributing member handled? Name the warning, who gives it, and when the instructor is told. | |
| How is work redistributed when someone is ill or has an accommodation? | |
| How is the contribution table agreed before each team submission, and what happens if a member disputes it? | |

## 7. Acknowledgement

Every member adds their own line below, in their own commit, so the agreement is visible in the Git history.

| Name | Student ID | Date | Statement |
|---|---|---|---|
| | | | I have read and agreed to this charter. |

## 8. Role rotation log

Rotate at least one role after Week 7. Record every rotation here.

| Date | Member | Role before | Role after | Reason |
|---|---|---|---|---|
| | | | | |

## 9. Guardrails every member has agreed to

These are course rules, not team preferences. They are reproduced here so nobody can say they did not know.

- **Synthetic data only.** No real applicant information, no real credit-bureau data, no live bureau calls, no real funds, and no real personal information about anyone, including yourselves.
- **No secrets in the repository**, at any commit, ever. A leaked credential is rotated at the source, not deleted from the current files.
- **Cost discipline.** Low-cost SKUs only, all five tags on every resource, a budget with alerts, auto-shutdown on every virtual machine, and full teardown in Week 14.
- **No direct contact with Allymon.** All partner communication routes through the instructor and the scheduled client Q&A sessions, during the term and after it.
- **The signed NDA comes first.** No member receives partner brief materials or attends a client session before their signed confidentiality agreement is submitted on Blackboard, by Sunday, September 13, 2026, 11:59 PM.
- **A progress report every week from Week 2 to Week 13**, due Friday at 5:00 PM. Missing or late reports are deducted from the team's next assessment.
- **CheckPoints are individual work** in each member's own subscription and own fork. The charter, the milestones, and the presentations are team work.
