# Weekly Client Progress Report – CSP451 2026F

Copy this file to `docs/progress/week-<NN>.md` in your **team** repository, complete every section, export it to PDF, and submit it on Blackboard as `CSP451_2026F_PR<week>_<TeamName>.pdf`.

One report per teaching week, **Week 2 through Week 13**, due **Friday at 5:00 PM**. The Week 8 Study Week report is optional. Confirm all dates on Blackboard.

The **Client Liaison** submits the report. The instructor forwards a weekly digest of all team reports to Allymon, so write it for a business reader who is not in your lab. Keep it to one page. The client answers your questions either in writing before the next report or at the next Q&A and sharing session in Weeks 3, 5, 7, 9, 11, and 13.

Two rules carry over from the rest of the course. Everything in the report is your own work on synthetic data, and nothing confidential from Allymon is repeated back into a document that leaves the team repository. Do not paste secrets, connection strings, or keys into a report.

---

## Template

### Header

| Field | Value |
|---|---|
| Team name | |
| Week number | |
| Week dates, Monday to Sunday | |
| Client Liaison for this report | |
| Report submitted on | |

### 1. Done this week

Three to six bullets. Each bullet states what is now working, not what you worked on, and carries an evidence link to a pull request, commit, board item, or deployed resource.

- Item, with evidence link
- Item, with evidence link
- Item, with evidence link

### 2. Planned for next week

Three to five bullets. Name the owner of each item.

- Item, owner
- Item, owner
- Item, owner

### 3. Risks, blockers, and decisions needed

Every row needs an owner and a date. A blocker with no owner is not being worked on. Write "None this week" if the table is empty.

| Item | Type: risk, blocker, or decision | Impact if unresolved | Owner | Needed by |
|---|---|---|---|---|
| | | | | |

### 4. Questions for Allymon

Up to three questions, phrased so a business reader can answer them without opening the code. These become the team's questions at the next Q&A session. Write "None this week" if you have none.

1.
2.
3.

### 5. Azure spend to date versus estimate

One line: spend to date, the estimate for the same point in the term, and the reason for any gap.

### 6. Contribution table

| Member | Hours this week | Main items delivered |
|---|---|---|
| | | |
| | | |
| **Total** | | |

---

## Worked example

The example below is a completed Week 5 report for a fictional team. Use it for length and tone, not as content to copy.

### Header

| Field | Value |
|---|---|
| Team name | team07 |
| Week number | 5 |
| Week dates, Monday to Sunday | October 5 to October 11, 2026 |
| Client Liaison for this report | A. Okafor |
| Report submitted on | Friday, October 9, 2026, 4:20 PM |

### 1. Done this week

- The loan-risk API is deployed to App Service B1 and returns a stubbed decision through the staging slot. PR #61.
- The Functions worker is deployed and reaches the mock bureau over the private address, confirmed from the App Service console. PR #63.
- VNet integration is enabled on both the App Service and the Function app, so no traffic to the bureau leaves the virtual network. PR #64.
- The Pricing Calculator estimate for the full environment is exported and committed at `docs/cost/estimate-2026-10-08.pdf`.
- The Milestone 1 dossier is assembled and ready for the Tuesday, October 13 deadline, including the logical and deployment diagrams, the ERD, and the IaaS versus PaaS comparison.

### 2. Planned for next week

- Convert the hand-built environment to Bicep modules and run `what-if` against the dev resource group. Owner: R. Bhatt.
- Add the GitHub Actions deploy workflow with OIDC federated credentials, plus a teardown job. Owner: L. Nguyen.
- Assign the three Azure Policy definitions for required tags, allowed locations, and allowed VM sizes. Owner: M. Silva.
- Close the two review comments Allymon raised on the decision response shape. Owner: A. Okafor.

### 3. Risks, blockers, and decisions needed

| Item | Type: risk, blocker, or decision | Impact if unresolved | Owner | Needed by |
|---|---|---|---|---|
| The App Service F1 free tier does not support VNet integration, so we are on B1 at roughly 13 USD per month | Decision | Raises monthly spend by about 13 USD, which is 13% of the term credit | R. Bhatt | Week 6 lab |
| The reason-code list in the brief has 9 codes; the rules catalogue version 1.0.0 defines 7 | Decision | Two adverse conditions have no code, so the decision response cannot explain them | A. Okafor | Week 9 |
| Bastion was left running for 40 minutes on October 6 | Risk | Roughly 4 USD of unplanned spend; a full weekend would be about 30 USD | M. Silva | Closed, deleted same day |

### 4. Questions for Allymon

1. When an application is routed to manual review, how long does an underwriter usually have before the applicant expects an answer? We want to set the queue service level target from a real number.
2. Should a thin file with no delinquencies be a manual review, or a decline with a reason code? The current rules send it to manual review.
3. For the ROI metrics, is the comparison baseline a fully manual underwriting process, or an existing tool you already pay for?

### 5. Azure spend to date versus estimate

Spend to date is 21.40 USD against an estimate of 18.00 USD at the end of Week 5. The 3.40 USD gap is the Bastion session on October 6 and the B1 App Service upgrade, both explained above.

### 6. Contribution table

| Member | Hours this week | Main items delivered |
|---|---|---|
| A. Okafor | 7 | Milestone 1 dossier assembly, client questions, decision response review |
| R. Bhatt | 8 | App Service deployment, staging slot, VNet integration |
| L. Nguyen | 6 | Functions worker deployment, private bureau call verification |
| M. Silva | 6 | Pricing Calculator estimate, cost write-up, Bastion cleanup |
| D. Farah | 5 | ERD, data model section of the dossier |
| **Total** | **32** | |
