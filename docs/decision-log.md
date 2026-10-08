# Decision log
## Stack decision
| Field | Content |
|---|---|
| Decision ID and date | D-001, 2026-10-08 |
| Decision | Node.js/TypeScript on Node.js 22 LTS |
| Status | Accepted |
| Context: what forced the choice now | CI, the provisioning scripts and the Week 3 lab all depend on one runtime, so we have to pick before any of that is written. |
| Options considered and why each was or was not selected | Node.js/TypeScript was selected because it is the only stack the course tested on App Service and Azure Functions in the lab, and the starter kit's mock bureau and CI are already Node. Python 3.12 was not selected because Python on those two services was not tested in the lab, so we would be carrying the risk of platform surprises alone. |
| Consequences: what this makes easier and what it makes harder | It makes lab support, the kit's existing tests and the Week 6 deploy job easier since they all assume Node. It makes it harder for anyone on the team who prefers Python and it ties us to Node.js 22, which means moving the kit's Node 20 CI step in Week 3. |
| Team members who agreed | Nathan Sabundayo (proposed). Shilin Sun to confirm on the pull request. |
| Source or evidence cited | Week 2 Walkthrough, section "Git collaboration" CI step (Node.js/TypeScript is the only stack verified in the lab); Node.js release schedule, https://nodejs.org/en/about/previous-releases (Node.js 20 reached end of life on April 30, 2026). |
