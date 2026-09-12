# CSP451 – Fall 2026 – Deterministic Rules Catalogue, version 1.0.0

This is the course-owned decision policy for the Allymon Loan Risk Engine. It is the contract that `data/decision_test_vectors.json` checks. Your engine must reproduce it exactly.

The full teaching treatment, including the TypeScript reference implementation, is in `Week9/Week9_Learning_Notes.md`. Where a detail here and Week 9 disagree, Week 9 wins. All 12 vectors in `../data/decision_test_vectors.json` have been run against that reference implementation and pass.

**Synthetic data only.** No real applicant, no real bureau, no real credit score, no lending decision.

## 1. What the engine must be

| Property | Meaning | Why it is graded |
|---|---|---|
| Deterministic | No randomness, no clock, no network call inside the evaluation | The whole cohort shares one set of test vectors |
| Explainable | Every decision returns exactly three ranked drivers, not a bare score | Key Success Factor: decision transparency |
| Versioned | `rulesVersion` is returned with every decision and written to `audit_log` | A decision made under 1.0.0 must still be explainable after 1.1.0 ships |
| Total | Every input path returns a decision, never an exception | Key Success Factor: 0% unhandled exceptions on schema-valid JSON |

## 2. Inputs

| Field | Source | Type |
|---|---|---|
| `annualIncomeCad` | Application | number, CAD per year |
| `monthlyDebtCad` | Application | number, CAD per month |
| `requestedAmount` | Application | number, CAD |
| `employmentStatus` | Application | `FULL_TIME`, `PART_TIME`, `SELF_EMPLOYED`, `UNEMPLOYED` |
| `creditScore` | Bureau snapshot | integer 300 to 900, or `null` when no usable snapshot returned |
| `fileAgeMonths` | Bureau snapshot | integer, or `null` |
| `openTrades` | Bureau snapshot | integer |
| `delinquencies24m` | Bureau snapshot | integer |

Debt-to-income is derived, not supplied:

```text
dti = (monthlyDebtCad * 12) / annualIncomeCad        when annualIncomeCad > 0
dti = 1                                              when annualIncomeCad is 0
```

## 3. Code catalogue

Codes are stable. Once published, a code never changes meaning, because decisions already stored reference it. Publish the same tables as `docs/reason-codes.md` in your team repository.

The catalogue has two halves. **R codes are adverse** and are what a decision returns as `reasonCodes`. **P codes are supporting** and explain why an application was acceptable. Both carry a signed **contribution**, and the three with the largest absolute contribution are returned as `drivers` on every decision.

| Adverse code | Meaning | Contribution |
|---|---|---|
| `R01_LOW_CREDIT_SCORE` | Bureau score below the approval band | -100 below 580, -85 from 580 to 639 |
| `R02_HIGH_DTI` | Debt-to-income above the policy ceiling | -95 |
| `R03_INCOME_BELOW_MINIMUM` | Annual income below the product minimum | -98 |
| `R04_RECENT_DELINQUENCY` | Delinquencies in the last 24 months | -92 at two or more, -80 at one |
| `R05_THIN_FILE` | File under 12 months old, or fewer than 2 open trades | -75 |
| `R06_HIGH_LOAN_TO_INCOME` | Requested amount above the permitted multiple of income | -70 |
| `R07_UNSTABLE_EMPLOYMENT` | Employment status is unemployed | -88 |
| `R08_BUREAU_DATA_MISSING` | No usable bureau snapshot returned | -90 |

| Supporting code | Meaning | Contribution |
|---|---|---|
| `P01_STRONG_CREDIT_SCORE` | Score at or above the approval floor of 640 | +60 at 720 and above, +30 from 640 to 719 |
| `P02_LOW_DTI` | Debt-to-income at or under the ceiling | +55 at or under 0.30, +25 from 0.31 to 0.42 |
| `P03_STABLE_EMPLOYMENT` | Employment status other than unemployed | +45 full time, +30 otherwise |
| `P04_CLEAN_DELINQUENCY_HISTORY` | No delinquencies in the last 24 months | +50 |
| `P05_ESTABLISHED_FILE` | File 12 months or older with at least 2 open trades | +40 at 36 months and 3 trades or more, +20 otherwise |

`R09` was never issued. `R10_STRONG_CREDIT_SCORE` and `R11_LOW_DTI` are **retired** and are now `P01_STRONG_CREDIT_SCORE` and `P02_LOW_DTI`. A retired code is never reused for a different meaning.

## 4. Policy bands

Five **graded dimensions** each emit exactly one driver, whichever band the applicant falls in. That is what guarantees at least five drivers on every application and therefore three to rank. Boundaries matter: the test vectors sit on them on purpose.

| Dimension | Band | Driver | Contribution | Score delta | Effect |
|---|---|---|---|---|---|
| Credit score | no usable snapshot | `R08_BUREAU_DATA_MISSING` | -90 | 0 | refer |
| Credit score | `>= 720` | `P01_STRONG_CREDIT_SCORE` | +60 | +180 | none |
| Credit score | `>= 640` and `< 720` | `P01_STRONG_CREDIT_SCORE` | +30 | +60 | none |
| Credit score | `>= 580` and `< 640` | `R01_LOW_CREDIT_SCORE` | -85 | -60 | refer |
| Credit score | `< 580` | `R01_LOW_CREDIT_SCORE` | -100 | -160 | decline |
| Debt service | `> 0.42` | `R02_HIGH_DTI` | -95 | -140 | decline |
| Debt service | `<= 0.30` | `P02_LOW_DTI` | +55 | +90 | none |
| Debt service | `> 0.30` and `<= 0.42` | `P02_LOW_DTI` | +25 | 0 | none |
| Employment | `UNEMPLOYED` | `R07_UNSTABLE_EMPLOYMENT` | -88 | -80 | refer |
| Employment | `FULL_TIME` | `P03_STABLE_EMPLOYMENT` | +45 | 0 | none |
| Employment | any other status | `P03_STABLE_EMPLOYMENT` | +30 | 0 | none |
| Repayment history | `>= 2` delinquencies | `R04_RECENT_DELINQUENCY` | -92 | -130 | decline |
| Repayment history | `== 1` delinquency | `R04_RECENT_DELINQUENCY` | -80 | -70 | refer |
| Repayment history | none | `P04_CLEAN_DELINQUENCY_HISTORY` | +50 | 0 | none |
| File depth | `fileAgeMonths < 12` or `openTrades < 2` | `R05_THIN_FILE` | -75 | -40 | refer |
| File depth | `fileAgeMonths >= 36` and `openTrades >= 3` | `P05_ESTABLISHED_FILE` | +40 | 0 | none |
| File depth | anything else that is not thin | `P05_ESTABLISHED_FILE` | +20 | 0 | none |

Two **independent gates** add a driver when they fire and add nothing when they do not, so they never reduce the driver count below five.

| Gate | Condition | Driver | Contribution | Score delta | Effect |
|---|---|---|---|---|---|
| Income minimum | `annualIncomeCad < 25000` | `R03_INCOME_BELOW_MINIMUM` | -98 | -150 | decline |
| Loan to income | `requestedAmount > annualIncomeCad * 0.5` | `R06_HIGH_LOAN_TO_INCOME` | -70 | -50 | refer |

Contribution and score delta are deliberately different numbers. The **score delta** moves the numeric score, which sets the risk tier. The **contribution** ranks drivers for explanation. A driver can rank highly while moving the score not at all.

A `null` `fileAgeMonths` is treated as 0, so a missing bureau snapshot always also produces `R05_THIN_FILE`.

## 5. Outcome, score, and risk tier

```text
base score            = 500, then the deltas in the table above
score                 = clamp(base score, 0, 1000)

outcome = DENY           if any rule with effect Decline fired
        = MANUAL_REVIEW  else if any rule with effect Refer fired
        = APPROVE        otherwise

riskTier = LOW     if score >= 700
         = MEDIUM  if score >= 500 and score < 700
         = HIGH    if score < 500
```

Decline beats refer. A decline and a refer firing on the same application is a `DENY`.

Risk tier is a description of the score, not of the outcome. A `DENY` with a score of 420 is `HIGH` and a `DENY` with a score of 560 is `MEDIUM`. Do not derive the tier from the outcome.

## 6. Driver ordering and reason codes

1. Collect every driver: one from each of the five graded dimensions, plus any gate that fired.
2. Sort descending by the **absolute value** of the contribution, so an adverse driver and a supporting driver of the same magnitude rank equally before the tie break.
3. Break ties by code, ascending, using ordinary string comparison. `P01_STRONG_CREDIT_SCORE` sorts before `P03_STABLE_EMPLOYMENT`.
4. `drivers` is the first three of that ranked list. It always has exactly three entries.
5. `reasonCodes` is every code in the ranked list with a negative contribution, in the same order. It may be empty, and on a clean approval it is.

`drivers` is what an underwriter reads. `reasonCodes` is what a decline letter quotes. Do not conflate them, and do not put a `P` code in `reasonCodes`.

The sort must be stable and explicit. If your language's sort is unstable and you omit the tie break, two students' engines will disagree on vector `V11` and both will look correct locally.

## 7. Worked example, vector V12

| Step | Value |
|---|---|
| Input | income 34000, monthly debt 1250, requested 20000, `UNEMPLOYED`, score 612, file age 15, open trades 3, delinquencies 2 |
| Debt-to-income | `(1250 * 12) / 34000 = 0.4412` |
| Credit score | 612 is in `[580, 640)`, so `R01_LOW_CREDIT_SCORE` at -85, refer, score -60 |
| Debt service | `0.4412 > 0.42`, so `R02_HIGH_DTI` at -95, decline, score -140 |
| Employment | unemployed, so `R07_UNSTABLE_EMPLOYMENT` at -88, refer, score -80 |
| Repayment history | 2 delinquencies, so `R04_RECENT_DELINQUENCY` at -92, decline, score -130 |
| File depth | 15 months and 3 trades is not thin but not established, so `P05_ESTABLISHED_FILE` at +20 |
| Loan to income | `20000 > 34000 * 0.5 = 17000`, so `R06_HIGH_LOAN_TO_INCOME` at -70, refer, score -50 |
| Score | `500 - 60 - 140 - 80 - 130 - 50 = 40` |
| Risk tier | `40 < 500`, so `HIGH` |
| Outcome | a decline fired, so `DENY` |
| Ranked | 95, 92, 88, 85, 70, 20 |
| `drivers` | `R02_HIGH_DTI (-95)`, `R04_RECENT_DELINQUENCY (-92)`, `R07_UNSTABLE_EMPLOYMENT (-88)` |
| `reasonCodes` | `R02_HIGH_DTI`, `R04_RECENT_DELINQUENCY`, `R07_UNSTABLE_EMPLOYMENT`, `R01_LOW_CREDIT_SCORE`, `R06_HIGH_LOAN_TO_INCOME` |

Six drivers fired and three are returned in `drivers`. Compare vector `V10`, where nothing adverse fires at all: `reasonCodes` is empty and `drivers` is three supporting codes. Every decision explains itself, which is exactly what the partner asked for.

## 8. Known issues in version 1.0.0

Record these in your team decision log. The final report is expected to name them under limitations.

| # | Issue | What to do this term |
|---|---|---|
| 1 | `R07_UNSTABLE_EMPLOYMENT` fires only when the employment status is `UNEMPLOYED`. `PART_TIME`, `CONTRACT` and `SELF_EMPLOYED` all take the supporting `P03_STABLE_EMPLOYMENT` driver instead, at the lower +30 contribution. | Vector `V11` locks this in. Widening the rule needs a new rules version and new vectors. |
| 2 | The contributions are hand-set policy numbers, not fitted weights. They rank explanations; they are not evidence of predictive power. | Say so in `docs/limitations.md`. Do not present the driver ranking as model attribution. |
| 3 | `P01_STRONG_CREDIT_SCORE` covers the whole 640 and above range, so a score of 645 and a score of 850 differ only by the contribution, not by the code. | Acceptable for a proof of concept. A finer band split is a candidate for 1.1.0. |

## 9. Changing the rules

Rules are versioned, not edited in place.

1. Any change to a threshold, a weight, or the outcome logic requires a new `rulesVersion`, for example `1.1.0`.
2. The old version's behaviour must remain reproducible, because stored decisions reference it.
3. Add a decision-log entry naming the change, the reason, and the vectors that changed.
4. Add new vectors for the new boundaries. Do not delete old vectors; mark them as applying to the previous version.

## 10. Links

- Reference implementation and the audit record: `Week9/Week9_Learning_Notes.md`, sections 8 and 9. All 12 vectors have been run against it and pass.
- Schema for `decisions` and `audit_log`: `Week9/Week9_Learning_Notes.md`, section 5
- API contract that carries the decision to the client: `Week7/Week7_Learning_Notes.md`, section 4
- Test vectors: `../data/decision_test_vectors.json`
- Synthetic applicant dataset: `../data/synthetic_applicants.csv`
