# Azure VM Snapshot Tool 🛡️

PowerShell script to automate OS & data disk snapshots across **multiple Azure subscriptions**, with built-in reporting and ticket-based naming.

---

## 🔍 Features

- **Multi-subscription support**: loops through all subscriptions you’ve access to  
- **OS & data disk snapshots**: captures both disk types for each VM  
- **Ticket-based naming**: appends your ticket/incident ID to each snapshot name  
- **Smart truncation**: keeps names within Azure’s 80-character limit  
- **CSV reporting**: generates `<timestamp>_Snapshot_Report.csv` with Success / Failed / NotFound entries  
- **Logging**: detailed transcript and error log for audit/troubleshooting  

---

## ⚙️ Prerequisites

- **PowerShell 5.1+** or **PowerShell 7+**  
- **Az PowerShell modules** installed:
  ```powershell
  Install-Module Az -Scope CurrentUser -Force
  ```
  Permissions: “Reader” on VMs & “Contributor” on snapshots in each subscription
  ---
  🚀 Usage

   1. Clone repo
  ```
  git clone https://github.com/vikasmahi-dev/azure-vm-snapshot-tool.git
  cd azure-vm-snapshot-tool
  ```
  2. Prepare VM list (vmnames.txt):
  ```
  web-vm-01
  sql-vm-02
  infra-vm-03
  ```
  3. Run script:
  ```
  .\Take-VMSnapshot.ps1 `
  -VmListPath ".\vmnames.txt" `
  -TicketId "INC123456"
  
  Note: When selecting a tenant and subscription, simply press Enter. This will check all subscriptions to locate the VM wherever you have access.
  ```

---

🔧 **Parameters**

    -VmListPath (string)
    Path to a newline-separated file of VM names.

    -TicketId (string)
    Your ticket or change-request ID to embed in snapshot names.

    -ReportDir (optional)
    Folder for CSV & logs (defaults to script folder).

📄 **Output**

    CSV report: Snapshot_Report_YYYYMMDD_HHMMSS.csv

    Log transcript: snapshot_YYYYMMDD_HHMMSS.log

Each row in the CSV includes:

SubscriptionId, VMName, DiskName, SnapshotName, Status, ErrorMessage

---

⚠️ Tips & Best Practices

    Run in a non-interactive context via Azure Automation or Task Scheduler using a Service Principal.

    Validate your vmnames.txt against Get-AzVM before running.

    Clean up old snapshots periodically to control costs.

---

👨‍💻 Author

Vikas Mahi – Infrastructure Architect & Technical Lead | AWS • Azure • VMware • Automation

---

📜 License

MIT © Vikas Mahi

