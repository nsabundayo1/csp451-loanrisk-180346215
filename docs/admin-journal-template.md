# Admin Journal – CSP451 2026F

**Name:** <full name>  **Student ID:** <studentID>  **Team:** <team name>  **Role:** <your role this half of the term>

## How to use this file

Copy it to `docs/admin-journal-<studentID>.md` in your own fork, and add one entry every teaching week. It is the evidence base for three separate marks, so it is not optional housekeeping.

| What it feeds | Where |
|---|---|
| The appendix in every CheckPoint PDF | An extract of that week's entry, half a page maximum |
| Azure Budget Management, 5%, individual | The weekly cost check-in line, Week 3 through Week 14 |
| The individual reflection, part of the Final Project, 5% | CLO6 asks you to reflect on your own work patterns. You cannot do that in Week 14 from memory |

Rules that markers actually check:

1. **One entry per teaching week**, written that week. Week 8 is Study Week and needs only the cost line. Twelve entries back-filled on December 10 do not satisfy requirement 33 of the Week 14 deliverables.
2. **The cost check-in is mandatory from Week 3 onward.** Name the spend to date, the remaining credit, and the action you took.
3. **No secrets.** No connection strings, keys, tokens, or passwords, even in a command you are quoting. Write `<redacted>`.
4. **No real personal information**, yours or anyone else's, beyond your own name, student ID, and Seneca email.
5. **Declare AI-tool use** in the entry for the week you used it: which tool, what for, and what you changed or verified yourself.
6. Commit each entry in its own commit. The Git history is the timestamp evidence.

## Weekly entry template

Copy this block for each week. Keep entries to roughly half a page.

---

### Week <N>: <topic>  (week of <Mon DD> to <Sun DD>, 2026)

**What I did.**
<Three to six bullets. Be specific: name the resource, the command, the pull request, or the document. "Worked on the VM" is not markable. "Deployed vm-bureau-team07 with az vm create, restricted SSH to my own address, and installed the mock bureau as a systemd unit" is.>

**What blocked me and how I resolved it.**
<The symptom, what you tried, what actually fixed it. If it is still blocking you, say who you asked and when.>

**What I will do next week.**
<Two or three concrete items, each one you could tick or fail to tick next week.>

**Contribution evidence.**

| Artifact | Link or identifier |
|---|---|
| Commits | <short SHAs or a compare link> |
| Pull requests raised | <numbers> |
| Pull requests reviewed | <numbers> |
| Issues or board items moved | <identifiers> |

**Azure cost check-in.** *(required from Week 3 onward)*

| Field | Value |
|---|---|
| Date checked | <YYYY-MM-DD> |
| Spend, month to date | <amount and currency> |
| Remaining credit | <amount and currency> |
| Largest cost line this week | <resource and amount> |
| Budget alerts received | <none, or which threshold> |
| Action taken | <stopped the PostgreSQL server, deleted rg-csp451-...-scratch, confirmed auto-shutdown fired, or none needed> |

**Governance check.** *(one line each, from Week 3 onward)*

- Tags on every resource I created this week: <yes / no, and what I fixed>
- Auto-shutdown on every VM I created: <yes / no / not applicable>
- Secret scan clean on my branch: <yes / no, and what I rotated>

**AI-tool use this week.** *(required if you used one; write "none" if you did not)*

| Tool | What I used it for | What I verified or changed myself |
|---|---|---|
| | | |

**Reflection, one or two sentences.**
<What you would do differently. This is the raw material for the Week 14 reflection, so write the honest version.>

---

## Week 14: one work pattern, in depth

The individual reflection asks for **one** work pattern you changed, not a list. Start collecting evidence for it well before Week 14.

| Prompt | Your notes |
|---|---|
| The pattern before | <what you habitually did, with a week and an artifact that shows it> |
| The trigger | <the specific event that made you change it> |
| The pattern after | <what you do now, with a week and an artifact that shows it> |
| Evidence it actually changed | <commits, review comments, a runbook section, a checklist you now use> |
| The IT administration practice it maps to | <change control, least privilege, evidence-based diagnosis, cost governance, documentation as a deliverable> |
