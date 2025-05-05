# Azure VM Snapshot Tool 🛡️

Automates Azure VM OS/Data disk snapshots across **multiple Azure subscriptions** using PowerShell — includes detailed reporting and smart, ticket-based naming.

---

## 🚀 Features

- 🔁 Automatically processes multiple Azure subscriptions
- 💽 Creates snapshots of both OS and data disks
- 📄 Generates detailed CSV reports (Success, Failure, Not Found)
- 🏷️ Appends custom ticket IDs to snapshot names for traceability
- ✂️ Smart name truncation to comply with Azure length limits
- 📦 Modular, clean PowerShell codebase
- 🔐 Includes safety checks and logging
---

## 📂 Repository Contents

```
azure-vm-snapshot-tool/
│
├── Take-VMSnapshot.ps1 # Main snapshot script
├── .gitignore # Optional: to exclude logs/reports
└── README.md # This documentation
```


---

## 📋 Prerequisites

- PowerShell 5.1+ or PowerShell Core (v7+)
- Azure PowerShell Module

```powershell
Install-Module Az -Scope CurrentUser -Repository PSGallery -Force
```

Azure account with appropriate permissions: Read VM and disk resources, Create snapshots

---
🛠️ How to Use
1. Clone the Repository
2. git clone https://github.com/akshatmahi/azure-vm-snapshot-tool.git
cd azure-vm-snapshot-tool

2. Prepare the VM List
Create or edit a .txt file with one VM name per line, for example:
```
vmnames.txt
-----------
web-vm-01
sql-vm-02
infra-vm-03
```

3. Run the Script
Open PowerShell and run the following:
```
.\Take-VMSnapshot.ps1 -VmListPath ".\vmnames.txt" -TicketId "INC123456"
```
Parameters:
* VmListPath: Path to your VM list file
* TicketId: Reference like a JIRA or ServiceNow ticket — used in snapshot names
---
📊 Output Files

✅ CSV Report: Snapshot_Report_YYYYMMDD_HHMMSS.csv

* Transcript Log: snapshot_YYYYMMDD_HHMMSS.log

```
Each report entry includes:
Timestamp
Subscription ID
VM Name
Disk Name
Snapshot Name
Status (Success / Failed / NotFound)
Error message
Ticket reference

```
---
✅ Sample Output

```
┌──────────────────────────────┐
│         Summary Report       │
├────────────────┬─────────────┤
│ Successful     │           12│
├────────────────┼─────────────┤
│ Failed         │            2│
├────────────────┼─────────────┤
│ Not Found      │            1│
└────────────────┴─────────────┘
```
---
💡 Tips
Use with Task Scheduler or Azure Automation for backups

Supports multi-subscription environments

Ideal for DevOps, SRE, and platform teams

Works great in CI/CD if run with a service principal

---

👨‍💻 Author

Developed and maintained by Vikas Mahi

💬 Contributions, issues, and feedback are welcome!

---

📄 License
MIT License – free to use, adapt, and distribute.
