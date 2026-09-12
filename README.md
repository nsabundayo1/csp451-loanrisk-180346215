# csp451-loanrisk-starter

Course-owned starter kit for **CSP451 – Cloud Service Platforms (Azure), Fall 2026**, Seneca Polytechnic. It supports the Allymon FinTech Loan Risk Engine case.

Fork this repository in Week 1. Do not clone it directly, and do not push to it.

> **Synthetic data only.** Every applicant identifier, income figure, credit score, and bureau response in this repository is fabricated by the course. There is no real bureau behind the mock service, no real applicant behind any row of the dataset, and nothing here makes a lending decision. Using real personal information anywhere in this course is an academic integrity matter, not a style problem.

## 1. What is in the kit

| Path | What it is | First used |
|---|---|---|
| `mock-bureau/server.js` | The deterministic mock credit bureau. Node 20, Express. | Week 3, deployed to the bureau VM |
| `mock-bureau/openapi-bureau.yaml` | OpenAPI 3.0.3 contract for the mock bureau | Week 3, referenced again in Week 7 |
| `mock-bureau/package.json` | Dependencies and scripts | Week 3 |
| `mock-bureau/test/bureau.test.js` | Determinism, range, and no-PII tests, run with `node --test` | Week 2, in your first pipeline |
| `data/synthetic_applicants.csv` | 60 synthetic loan applicants | Week 3 onward, seed data from Week 9 |
| `data/decision_test_vectors.json` | 12 decision test vectors, rules version 1.0.0 | Week 9, and every week after it |
| `rules/rules-reference.md` | The deterministic rules catalogue, version 1.0.0 | Week 9 |
| `docs/team-charter-template.md` | Team charter to complete in the Week 1 lab | Week 1 |
| `docs/admin-journal-template.md` | Weekly admin journal, feeds three separate marks | Week 1 through Week 14 |
| `docs/weekly-progress-report-template.md` | One-page client progress report, due Friday 5:00 PM each week | Week 2 through Week 13 |
| `.github/workflows/ci.yml` | Lint, unit tests, and course-data validation | Week 2 |
| `.gitignore` | Secrets, build output, and editor noise | Week 1 |

## 2. Clone and set up

Fork this repository to your own GitHub account in the web interface first, then:

```bash
git clone https://github.com/<your-github-user>/csp451-loanrisk-starter.git
cd csp451-loanrisk-starter

# Keep a link back to the course repository so you can pull instructor updates.
git remote add upstream https://github.com/<course-org>/csp451-loanrisk-starter.git
git remote -v

# Later in the term, when the instructor announces an update:
git checkout main
git pull upstream main
```

Requirements: Node 20 or later, Python 3.10 or later for the data checks, Git, and the Azure CLI from Week 3 onward.

```bash
node --version    # expect v20 or later
python3 --version
az version
```

## 3. Run the mock bureau locally

```bash
cd mock-bureau
npm install
npm start          # listens on 0.0.0.0:8080, override with PORT and HOST
```

In a second terminal:

```bash
# Liveness.
curl -s http://localhost:8080/health | python3 -m json.tool

# One applicant, versioned path. This is the path deployed on the VM in Week 3.
curl -s http://localhost:8080/bureau/v1/applicants/APP-0001 | python3 -m json.tool

# The same applicant through the short alias. Identical payload.
curl -s http://localhost:8080/bureau/APP-0001 | python3 -m json.tool

# A consented pull. Both fields are required.
curl -s -X POST http://localhost:8080/bureau/query \
  -H 'content-type: application/json' \
  -d '{"applicantId":"APP-0001","consentReference":"CONSENT-2026F-0001"}' | python3 -m json.tool

# Correlation ID: send one and watch it come back.
curl -sD - -o /dev/null http://localhost:8080/bureau/v1/applicants/APP-0001 \
  -H 'x-correlation-id: 6a1f2c8e-1c2a-4f77-9c4d-53f0a6b1d2e3' | grep -i correlation

# Structured errors, not stack traces.
curl -s http://localhost:8080/bureau/v1/applicants/not_a_valid_id   # 400
curl -s http://localhost:8080/nope                                  # 404
```

Stop the service with Ctrl+C.

### Why it is deterministic

Every field is derived from a SHA-256 hash of the applicant identifier. `APP-0001` returns the same credit score on your laptop, on your teammate's laptop, and on the marker's virtual machine. Only `retrievedAt` changes between calls. That property is what lets the whole cohort share one set of decision test vectors, and it is why you must not replace the seeding with a random number generator.

### Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Liveness, returns the data version |
| GET | `/bureau/v1/applicants/{applicantId}` | Canonical lookup. Use this one in your code. |
| GET | `/bureau/{applicantId}` | Convenience alias, identical payload |
| POST | `/bureau/query` | Lookup against a recorded synthetic consent reference |

Every response carries an `x-correlation-id` header, echoed from the request when you send one. Week 7 sets it at the API Management gateway, Week 9 writes it to the audit record, and Week 11 traces it through Application Insights. One identifier, end to end.

## 4. Run the tests

```bash
cd mock-bureau
node --check server.js     # syntax lint
node --test                # unit tests
```

The tests assert determinism, that every numeric field stays inside its documented range, and that the payload exposes no personally identifiable field. The last one is a guardrail: if someone adds a `name` field to the bureau payload, the build fails.

Validate the course data files:

```bash
python3 -c "import json; d=json.load(open('data/decision_test_vectors.json')); print(len(d['vectors']), 'vectors')"
python3 -c "import csv; print(len(list(csv.DictReader(open('data/synthetic_applicants.csv')))), 'applicants')"
```

The same checks run in `.github/workflows/ci.yml` on every push.

## 5. The synthetic applicant dataset

`data/synthetic_applicants.csv`, 60 rows, one header row.

| Column | Type | Notes |
|---|---|---|
| `applicant_id` | text | `APP-0001` through `APP-0060`. This is the identifier the mock bureau seeds from. |
| `age_band` | text | `18-24`, `25-34`, `35-44`, `45-54`, `55-64`, `65+`. A band, never a date of birth. |
| `province` | text | Two-letter Canadian province code |
| `annual_income` | integer | CAD per year |
| `monthly_debt_payments` | integer | CAD per month, the numerator of the debt-to-income ratio |
| `requested_amount` | integer | CAD |
| `term_months` | integer | 12, 24, 36, 48, or 60 |
| `employment_type` | text | `FULL_TIME`, `PART_TIME`, `SELF_EMPLOYED`, `CONTRACT`, `UNEMPLOYED` |
| `months_at_address` | integer | Stability signal, no address is stored |
| `has_delinquency_12m` | boolean | `true` or `false`, as declared on the application |
| `thin_file` | boolean | `true` or `false`, as declared on the application |

There are deliberately **no** names, social insurance numbers, street addresses, postal codes, emails, phone numbers, or dates of birth. If your schema needs an applicant name for the encryption exercise in Week 9, generate an obviously fictional one such as `Jordan Sample` and encrypt it. Never use a classmate's name.

The dataset spans the decision space on purpose: applicants below the income minimum, applicants above the debt-to-income ceiling, thin files, delinquencies, and requests above half of income are all represented. `employment_type` includes `CONTRACT`, which the version 1.0.0 rules treat the same as any status other than `UNEMPLOYED`.

The application row is only half the input. The other half is the bureau snapshot, which you fetch from the mock bureau using `applicant_id`.

## 6. The decision test vectors

`data/decision_test_vectors.json`, 12 vectors, rules version 1.0.0. These are the contract your rules engine must satisfy from Week 9 onward.

Structure of one vector:

| Field | Meaning |
|---|---|
| `id` | `V01` through `V12` |
| `note` | What the vector is testing, and why |
| `rules_version` | `1.0.0`. Vectors are pinned to a rules version. |
| `input` | The applicant fields plus the bureau fields the engine reads |
| `expectedBureauSnapshot` | What the bureau half of the input should look like when stored |
| `expect` | `outcome`, `riskTier`, `score`, `dtiRatio`, the three ranked `drivers`, and the adverse `reasonCodes` |

Note that the engine returns the field as `rulesVersion`, in camel case, while the vector file records it as `rules_version` alongside `id`. Compare the values, not the key names.

`V01` through `V06` are the six vectors printed in `Week9/Week9_Learning_Notes.md`, so you can check your engine against the notes before you pull. `V07` through `V12` are boundary cases: credit score exactly 720, exactly 640, and exactly 580; debt-to-income exactly 0.30 and exactly 0.42; annual income exactly 25000; a requested amount exactly half of income; a thin file; one delinquency and two; and in `V11` a tie between two drivers at the same contribution.

**`drivers` always has exactly three entries and `reasonCodes` may be empty.** They are different things. `drivers` is the ranked explanation an underwriter reads, adverse or supporting, and every decision has three. `reasonCodes` lists only the adverse codes that fired, so a clean approval such as `V01`, `V07`, `V08`, `V10` and `V11` returns an empty array there and three supporting `P` codes in `drivers`.

All 12 vectors have been run against the reference engine printed in `Week9/Week9_Learning_Notes.md` and pass. Section 8 of `rules/rules-reference.md` records the known limitations of version 1.0.0.

A minimal Jest runner, once you have written `src/rules/engine.ts`:

```typescript
import { vectors } from "../data/decision_test_vectors.json";
import { evaluate } from "../src/rules/engine";

describe.each(vectors)("vector $id", (v: any) => {
  const actual = evaluate(v.input);
  it("outcome", () => expect(actual.outcome).toBe(v.expect.outcome));
  it("risk tier", () => expect(actual.riskTier).toBe(v.expect.riskTier));
  it("always three drivers", () => expect(actual.drivers).toHaveLength(3));
  it("drivers in order", () => expect(actual.drivers).toEqual(v.expect.drivers));
  it("adverse reason codes", () => expect(actual.reasonCodes).toEqual(v.expect.reasonCodes));
});
```

## 7. Folder layout to grow into

The kit ships the course-owned pieces. Your team repository grows around them, and the Week 14 documentation package expects these paths:

```text
.
├── api/openapi.yaml              # your loan-risk API contract, from Week 7
├── data/                         # course synthetic dataset and vectors  (shipped)
├── docs/
│   ├── admin-journal-<studentID>.md
│   ├── architecture/             # logical and deployment diagrams
│   ├── contributions.md
│   ├── decision-log.md
│   ├── limitations.md            # model governance, fairness, limitations
│   ├── progress/                 # weekly client progress reports, week-02.md onward
│   ├── reason-codes.md
│   ├── runbook.md
│   ├── security-summary.md
│   ├── team-charter.md
│   └── underwriter-manual.md
├── infra/                        # Bicep modules and parameters, from Week 6
├── mock-bureau/                  # the course mock bureau                (shipped)
├── rules/                        # the rules catalogue                   (shipped)
├── src/                          # your API and rules engine
├── tests/                        # your unit, contract, and vector tests
└── .github/workflows/            # CI from Week 2, deploy from Week 6
```

## 8. Rules of use

1. **Synthetic only.** Do not add real data of any kind to this repository or to anything derived from it.
2. **Do not make the bureau random.** The seeded hash is the contract. A random score breaks the shared vectors for the whole cohort.
3. **Do not edit the vectors to make your engine pass.** Fix the engine. Marking uses the course copy.
4. **Do not commit secrets.** The `.gitignore` is a safety net, not a control. Run a secret scan before every push, and enable GitHub secret scanning and push protection on your fork.
5. **Pull upstream changes** when the instructor announces them, rather than copying files by hand.
6. **Course use only.** Do not redistribute the kit outside the cohort, and do not send it to Allymon. The partner handoff is arranged by the instructor.
7. **Attribute anything you did not write**, including code you adapt from Microsoft Learn or elsewhere.

## 9. Where to look next

| Question | File |
|---|---|
| How does the course work, and what is due when? | `Admin/CSP451_2026F_Student_Guide.md` |
| What exactly does this week's CheckPoint want? | `WeekN/WeekN_Deliverables_and_Requirements.md` |
| How is it marked? | `WeekN/WeekN_Marking_Matrix.md` |
| How do the rules decide? | `rules/rules-reference.md` and `Week9/Week9_Learning_Notes.md` |
| What goes in the weekly client progress report? | `docs/weekly-progress-report-template.md` |
| How is the bureau deployed on a VM? | `Week3/Week3_Learning_Notes.md`, section 7 |
| What does the loan-risk API contract look like? | `Week7/Week7_Learning_Notes.md`, section 4 |
