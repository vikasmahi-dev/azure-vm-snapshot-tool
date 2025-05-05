<#
.SYNOPSIS
    Azure VM Snapshot Creator for Multiple Subscriptions with Reporting

.DESCRIPTION
    Logs into Azure, loops through provided VM names and subscriptions,
    creates snapshots for each VM's disks, and generates a detailed CSV report.

.PARAMETER VmListPath
    Path to the file containing VM names (one per line).

.PARAMETER TicketId
    Ticket or identifier to include in snapshot names.

.PARAMETER LogPath
    Path to log file for transcript logging (optional).

.EXAMPLE
    .\Take-VMSnapshot.ps1 -VmListPath ".\vmnames.txt" -TicketId "INC123456"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$VmListPath,

    [Parameter(Mandatory)]
    [string]$TicketId,

    [Parameter()]
    [string]$LogPath = ".\snapshot_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

# Constants
$reportPath = ".\Snapshot_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$maxSnapshotLength = 82
$report = [System.Collections.Generic.List[PSObject]]::new()

# Start Logging
Start-Transcript -Path $LogPath -Append

# Validate VM list file
if (-not (Test-Path $VmListPath)) {
    Write-Error "VM list not found at path: $VmListPath"
    Stop-Transcript
    exit 1
}

# Connect to Azure
try {
    Write-Host "Connecting to Azure..." -ForegroundColor Yellow
    Connect-AzAccount -ErrorAction Stop | Out-Null
    Write-Host "Connected to Azure." -ForegroundColor Green
} catch {
    Write-Error "Azure login failed: $_"
    Stop-Transcript
    exit 1
}

# Retrieve and validate subscriptions
$subscriptions = Get-AzSubscription | Where-Object {
    $_.Id -match '^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$'
}

if (-not $subscriptions) {
    Write-Error "No valid Azure subscriptions found."
    Stop-Transcript
    exit 1
}

$vmNames = Get-Content $VmListPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

foreach ($sub in $subscriptions) {
    $subscriptionId = $sub.Id
    try {
        Set-AzContext -SubscriptionId $subscriptionId -ErrorAction Stop | Out-Null
        Write-Host "`n[✓] Context set to Subscription: $subscriptionId" -ForegroundColor Cyan
    } catch {
        Write-Warning "[×] Failed to set context for subscription: $subscriptionId"
        continue
    }

    foreach ($vmName in $vmNames) {
        try {
            $vm = Get-AzVM -Name $vmName.Trim() -Status -ErrorAction Stop
        } catch {
            $report.Add([PSCustomObject]@{
                Timestamp       = Get-Date
                SubscriptionID  = $subscriptionId
                VMName          = $vmName
                DiskName        = "N/A"
                SnapshotName    = "N/A"
                Status          = "NotFound"
                ErrorMessage    = "VM not found"
                OperationTicket = $TicketId
            })
            Write-Warning "[×] VM not found: $vmName"
            continue
        }

        $resourceGroup = $vm.ResourceGroupName
        $disks = @($vm.StorageProfile.OsDisk) + $vm.StorageProfile.DataDisks
        $location = $vm.Location

        foreach ($disk in $disks) {
            $diskName = $disk.Name.Trim()
            $ticketPart = $TicketId.Trim()
            $maxDiskLength = $maxSnapshotLength - $ticketPart.Length - 1
            $truncatedDisk = if ($maxDiskLength -gt 0) {
                $diskName.Substring(0, [Math]::Min($diskName.Length, $maxDiskLength))
            } else {
                $diskName
            }

            $snapshotName = "${truncatedDisk}_${ticketPart}"
            $snapshotName = $snapshotName.Substring(0, [Math]::Min($snapshotName.Length, $maxSnapshotLength))

            $entry = [PSCustomObject]@{
                Timestamp       = Get-Date
                SubscriptionID  = $subscriptionId
                VMName          = $vmName
                DiskName        = $diskName
                SnapshotName    = $snapshotName
                Status          = $null
                ErrorMessage    = $null
                OperationTicket = $TicketId
            }

            try {
                Write-Host "Creating snapshot: $snapshotName..." -ForegroundColor Yellow
                $snapshotConfig = New-AzSnapshotConfig -SourceUri $disk.ManagedDisk.Id -Location $location -CreateOption Copy
                New-AzSnapshot -Snapshot $snapshotConfig -SnapshotName $snapshotName -ResourceGroupName $resourceGroup -ErrorAction Stop
                $entry.Status = "Success"
                Write-Host "Snapshot created: $snapshotName" -ForegroundColor Green
            } catch {
                $entry.Status = "Failed"
                $entry.ErrorMessage = $_.Exception.Message
                Write-Warning "[×] Snapshot failed: $($_.Exception.Message)"
            } finally {
                $report.Add($entry)
            }
        }
    }
}

# Export Report
$report | Export-Csv -Path $reportPath -NoTypeInformation

# Show Summary
$success = ($report | Where-Object Status -eq 'Success').Count
$failed = ($report | Where-Object Status -eq 'Failed').Count
$notFound = ($report | Where-Object Status -eq 'NotFound').Count

Write-Host "`n┌──────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│         Summary Report        │" -ForegroundColor Cyan
Write-Host "├────────────────┬─────────────┤" -ForegroundColor Cyan
Write-Host "│ Successful     │ $($success.ToString().PadLeft(11)) │" -ForegroundColor Green
Write-Host "├────────────────┼─────────────┤" -ForegroundColor Cyan
Write-Host "│ Failed         │ $($failed.ToString().PadLeft(11)) │" -ForegroundColor Red
Write-Host "├────────────────┼─────────────┤" -ForegroundColor Cyan
Write-Host "│ Not Found      │ $($notFound.ToString().PadLeft(11)) │" -ForegroundColor Yellow
Write-Host "└────────────────┴─────────────┘" -ForegroundColor Cyan

Write-Host "`n[✓] Snapshot Report saved to: $reportPath" -ForegroundColor Green

Stop-Transcript
