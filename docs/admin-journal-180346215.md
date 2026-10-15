# Admin Journal — Entry 1 (Week 1)

**What I did this week:** Missed both Week 1 sessions and the team enrollment window. Emailed the instructor Friday evening to accept a zero on team-dependent Week 1 deliverables and request placement for Week 2. Completed all individual CP1 work solo: created the private GitHub repository, branched, added my README profile, opened a pull request, verified the .gitignore, enabled MFA, wrote the problem statement, and built the naming/tagging plan.

**What blocked me:** No team to review my pull request, so it remains open and unmerged. No team charter or Allymon questions to link, since those are in group I don't yet have access to.

**What's next:** Once placed on a team, get the pull request reviewed and merged, join the team charter and Allymon questions docs, and catch up on anything from Client Session 1 through the posted scribe notes.

### Week 3: Azure Fundamentals, IaaS VM and mock bureau  (week of Sep 21 to Sep 27, 2026)

**What I did.**
- Merged the five course tags onto my lab group Student-RG-2400807 with az group update --set, so the lab tags stayed.
- Wrote infra/bicep/budget.bicep and deployed it from week3-provision.sh as budget-csp451-group6 (20 per month, alerts at 50, 80 and 100 percent actual and 100 percent forecast) with the action group ag-csp451-group6.
- Created vm-bureau-group6 (Standard_B1s, Ubuntu 22.04) inside the lab VNet, limited SSH to my own IP with a /32 rule, and set auto-shutdown to 23:00 Eastern.
- Installed Node.js 22 on the VM and ran the mock bureau as a systemd service under the bureau user on port 8080.
- Opened PR #9 for the script, the Bicep file and the CI move to Node 22. CI passed and I merged it. Shilin was not available to review it, so it was merged without a review.
- I did this work late, on 2026-10-09, not during the week of Sep 21.

**What blocked me and how I resolved it.**
My lab group and lab VNet are in canadaeast, not canadacentral like the course notes say. The first time I ran the script, the VM made its own network instead of joining the lab one. I deleted that VM stack and changed the script to use the lab group's region and name the lab VNet and subnet. After that the VM joined the lab VNet. The cost query also gave me a 429 rate limit error at first, so I waited and ran it again.

**What I will do next week.**
- Finish CP4 and the missing CP1 evidence.
- Remove the Week 3 VM stack with the five-type tag loop before I build anything for Week 4.
- Catch up the weekly progress reports with my team.

**Contribution evidence.**

| Artifact | Link or identifier |
|---|---|
| Commits | c7ba3f9, 501f4be |
| Pull requests raised | #9 |
| Pull requests reviewed | none this week |
| Issues or board items moved | none |

**Azure cost check-in.**

| Field | Value |
|---|---|
| Date checked | 2026-10-09 |
| Month-to-date cost, lab resource group | 0 for Student-RG-2400807 |
| Where I read it | Cost Management query at the lab group scope |
| Largest cost line this week | none recorded yet, the bureau VM is the only compute in the group |
| Budget alerts received | none |
| End-of-week cost control action taken | deallocated the bureau VM, auto-shutdown left on |

**Governance check.**

- Tags on every resource I created this week: yes
- Auto-shutdown on every VM I created: yes
- Secret scan clean on my branch: yes

**AI-tool use this week.**

| Tool | What I used it for | What I verified or changed myself |
|---|---|---|
| Claude | Helped run code on Git Bash on Windows, and drafted the evidence scripts| I ran every command myself, took the screenshots, checked the outputs, and ran the checks that showed my lab is in canadaeast

**Reflection, one or two sentences.**
I started this checkpoint way too late and had to rush it. Next time I will start the lab on day one so there is time to fix problems.

### Week 4: Azure networking and security, private bureau VM  (week of Sep 28 to Oct 4, 2026)

**What I did.**
- Removed the Week 3 VM stack (VM, NIC, disk, public IP, NSG) with the tag-based type loop, and kept the budget and the action group.
- Built vnet-csp451-group6-dev (10.20.0.0/16) with snet-bureau, snet-app (delegated to App Service) and snet-data (delegated to PostgreSQL), plus asg-bureau-group6, nsg-bureau-group6 and nsg-app-group6.
- Redeployed vm-bureau-group6 into snet-bureau with no public IP and no SSH, and installed the mock bureau on Node.js 22 with az vm run-command and ufw.
- Created the private DNS zone loanrisk.internal with the link link-bureau-group6 and an A record for bureau.
- Proved one allowed and two blocked flows with Network Watcher IP flow verify, and ran next hop, effective rules and connection troubleshoot.
- Committed week4-network.sh and the README section in pull request #11 (commit 2537ffb).
- I did this work late, on 2026-10-14 and 2026-10-15, not during the week of Sep 28.

**What blocked me and how I resolved it.**
My home PC was not available, so I installed the Azure CLI and Node.js again on a school laptop and signed in to the lab from there. Git then refused to commit because no name or email was set, and a line-ending setting made README.md look completely rewritten in the staged diff (232 deletions). I set the name and email for this repository, restored README.md and appended the section again, and the diff then showed only added lines. My teammate was not available to review the pull request, so I merged it myself.

**What I will do next week.**
- Finish CP5 and the missing CP1 evidence.
- Catch up the weekly progress reports with my team.

**Contribution evidence.**

| Artifact | Link or identifier |
|---|---|
| Commits | 2537ffb |
| Pull requests raised | #11 |
| Pull requests reviewed | none this week |
| Issues or board items moved | none |

**Azure cost check-in.**

| Field | Value |
|---|---|
| Date checked | 2026-10-15 at 17:58 EDT |
| Month-to-date cost, lab resource group | 0.96 USD for Student-RG-2400807 |
| Where I read it | Cost Management query at the lab group scope |
| Largest cost line this week | not broken down; the query returns the group total only |
| Budget alerts received | none; usage is far below the first threshold of 10 USD |
| End-of-week cost control action taken | deallocated the bureau VM, confirmed no public IP is left |

**Governance check.**

- Tags on every resource I created this week: yes; the only untagged items are the lab VNet and the NetworkWatcherAgentLinux extension, which the tagging commands do not cover
- Auto-shutdown on every VM I created: yes
- Secret scan clean on my branch: yes

**AI-tool use this week.**

| Tool | What I used it for | What I verified or changed myself |
|---|---|---|
| Claude | Adapted the course network script for Git Bash on Windows, wrote the evidence scripts, and helped draft the short answers and this document | I ran every command myself, took the screenshots, and checked the outputs |

**Reflection, one or two sentences.**
I did this late and had to redo my setup on another computer, which made it more stressful than it needed to be. Next time I will start the lab the week it is released.
