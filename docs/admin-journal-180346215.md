# Admin Journal — Entry 1 (Week 1)

**What I did this week:** Missed both Week 1 sessions and the team enrollment window. Emailed the instructor Friday evening to accept a zero on team-dependent Week 1 deliverables and request placement for Week 2. Completed all individual CP1 work solo: created the private GitHub repository, branched, added my README profile, opened a pull request, verified the .gitignore, enabled MFA, wrote the problem statement, and built the naming/tagging plan.

**What blocked me:** No team to review my pull request, so it remains open and unmerged. No team charter or Allymon questions to link, since those are in group I don't yet have access to.

**What's next:** Once placed on a team, get the pull request reviewed and merged, join the team charter and Allymon questions docs, and catch up on anything from Client Session 1 through the posted scribe notes.

### Week 2: Git collaboration, discovery research and cloud service models  (week of Sep 14 to Sep 20, 2026)
**What I did.**
- Added a `lint-and-test` job to `.github/workflows/ci.yml` in my own repository (Node 22, ESLint 9, Jest 29) beside the kit's two jobs, on branch `feature/180346215-ci-lint-test`, and opened a pull request for it.
- Wrote `src/lib/ratios.js` and `test/ratios.test.js` with three tests, including two invalid-input cases, then broke one expectation on purpose to get a failing run and reverted it for a passing run.
- Created a merge conflict on purpose in `docs/service-models.md` from two branches, read both sides, resolved it by combining them and completed the merge.
- Created and pushed `release/week2` from main.
- Filled in the service model worksheet and the stack decision record, and reviewed a teammate's pull request.
- Checked the cost of my lab resource group Student-RG-2400807 with the read-only Cost Management query and got an empty result.
**What blocked me and how I resolved it.**
I did not start Week 2 on time because I had also missed Week 1, so everything here was completed late on 2026-10-08. I caught up by running the pipeline work myself from scripts I had tested first, and I asked my teammate to be added to my repository and to review my pull request because the review needs a second person.
**What I will do next week.**
- Move the kit's Node 20 CI step to Node 22 in the Week 3 pull request.
- Finish the CP3 provisioning work and record a real cost check.
- Get the Week 1 evidence that is still missing (NDA receipt, rendered README screenshot) into my repository.
**Contribution evidence.**
| Artifact | Link or identifier |
|---|---|
| Commits | 4eba264, 30255c7, df75068, f09b2c6, 0d4856d, 82dd620, 922fd76 |
| Pull requests raised | #2, #3, #4, #5, #6 |
| Pull requests reviewed | #7 (nsabundayo1/csp451-loanrisk-180346215) |
| Issues or board items moved | none |
**Azure cost check-in.**
| Field | Value |
|---|---|
| Date checked | 2026-10-08 |
| Month-to-date cost, lab resource group | Empty result, no charges (Student-RG-2400807) |
| Where I read it | Cost Management query run with az rest |
| Largest cost line this week | none |
| Budget alerts received | none |
| End-of-week cost control action taken | none needed |
**Governance check.**
- Tags on every resource I created this week: not applicable
- Auto-shutdown on every VM I created: not applicable
- Secret scan clean on my branch: yes, the diff and tracked files were searched for password, secret, key and connection string patterns and nothing matched
**AI-tool use this week.**
| Tool | What I used it for | What I verified or changed myself |
|---|---|---|
| Claude (Anthropic) | Drafted the helper scripts for the CI job, the failing and passing runs, the conflict exercise and the release branch, the test and ratio function code, and first drafts of the worksheet, decision record and write-ups | I ran every script myself, checked the worksheet and classifications against the Week 2 walkthrough, and edited the wording |
**Reflection.**
I should have started the week with the Week 1 setup instead of leaving it, because the review steps need a teammate and that waiting is what costs the most time.
