# CP2 service model worksheet
Name: Nathan Sabundayo  Student ID: 180346215
The resource names are the ones the course uses from Week 3 onward: `<team>` is the team name in lowercase (group6 until confirmed), `<sid4>` is 6215, and `<t7>` is the first seven letters and digits of the team name.
## Classification
| Component | IaaS / PaaS / SaaS | One-sentence justification |
|---|---|---|
| `vm-bureau-group6`, Ubuntu B1s running the course mock bureau service | IaaS | Microsoft only gives us the virtual machine, so we install Node, patch Ubuntu and run the service ourselves. |
| `app-loanrisk-group6-6215`, Azure App Service web app hosting the loan-risk API on the B1 plan `plan-loanrisk-group6` | PaaS | We upload code and settings while Microsoft runs the servers, the operating system and the web runtime. |
| `func-loanrisk-group6-6215`, Azure Functions worker processing queued applications, hosted on the same B1 plan | PaaS | We only supply the function code and Azure handles the host, the runtime and the triggers. |
| `sb-loanrisk-group6-6215`, Azure Service Bus queue | PaaS | The messaging broker is fully run by Microsoft and all we do is create queues and send or receive messages. |
| `psql-loanrisk-group6-6215`, Azure Database for PostgreSQL Flexible Server | PaaS | Microsoft runs the server, patching and automatic backups, and we only manage the schema, the data and who can connect. |
| `apim-loanrisk-group6-6215`, Azure API Management | PaaS | It is a managed gateway where we write the policies and Microsoft operates everything underneath. |
| `kv-loanrisk-group6-6215`, Azure Key Vault | PaaS | Microsoft runs the vault service and we decide what goes in it and who may read it. |
| Azure Blob Storage holding synthetic mock documents | PaaS | We just use containers and blobs while Microsoft owns the storage hardware and software. |
| The Loan Risk Engine API your team delivers to Allymon | SaaS | Allymon calls a finished service over HTTPS and never touches the servers, the runtime or the code. |
| GitHub, as your team uses it | SaaS | We log in and use a complete hosted product that GitHub builds, runs and updates for us. |
## Shared responsibility allocation
In this table Customer means our team, the party that builds and runs the loan-risk service.
| Responsibility | Mock bureau VM (IaaS) | App Service (PaaS) | The loan-risk API as delivered to Allymon (SaaS) |
|---|---|---|---|
| Physical datacentre and hardware | Microsoft | Microsoft | Microsoft |
| Hypervisor and host operating system | Microsoft | Microsoft | Microsoft |
| Guest operating system patching | Customer | Microsoft | Microsoft |
| Application runtime version | Customer | Shared: Microsoft patches the runtime, we pick the version and must move before it retires (Node.js 20 is the example) | Shared: same as App Service, because the API runs on it |
| Application code correctness | Customer | Customer | Customer |
| Network controls (NSG rules, IP restrictions) | Customer | Customer | Customer |
| Identity and access management | Customer | Customer | Customer |
| Encryption of data at rest | Microsoft (platform-managed keys by default) | Microsoft (platform-managed keys by default) | Microsoft (platform-managed keys by default) |
| What is written into an application log line | Customer | Customer | Customer |
| Availability of the underlying platform | Microsoft | Microsoft | Microsoft |
| Meeting the 3 second response target | Customer | Customer | Customer |
| Backup and restore of application data | Customer | Shared: the platform offers backups, we turn them on and test a restore | Customer |
