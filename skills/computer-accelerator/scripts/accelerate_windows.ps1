[CmdletBinding()]
param(
    [ValidateSet('Snapshot', 'Apply', 'Verify', 'Optimize', 'Monitor', 'Schedule', 'RestoreSchedule', 'InstallTools')]
    [string]$Mode = 'Snapshot',
    [switch]$StopReadonlyScans,
    [switch]$StopObservedDiskScanners,
    [int]$SettleSeconds = 8,
    [int]$DurationSeconds = 60,
    [int]$MonitorIntervalSeconds = 3,
    [string]$OutputPath
)

$ErrorActionPreference = 'SilentlyContinue'

function Get-CounterAverage {
    param([string[]]$CounterPaths)

    try {
        $samples = (Get-Counter -Counter $CounterPaths -SampleInterval 1 -MaxSamples 2 -ErrorAction Stop).CounterSamples
        return @($samples | Group-Object Path | ForEach-Object {
            [pscustomobject]@{
                Path = $_.Name
                Average = [math]::Round((($_.Group | Measure-Object -Property CookedValue -Average).Average), 3)
            }
        })
    } catch {
        return @()
    }
}

function Get-TopMemoryProcesses {
    $rows = foreach ($process in (Get-Process -ErrorAction SilentlyContinue)) {
        try {
            [pscustomobject]@{
                Name = $process.ProcessName
                Id = $process.Id
                MemoryMB = [math]::Round($process.WorkingSet64 / 1MB, 0)
                CpuSeconds = if ($null -ne $process.CPU) { [math]::Round($process.CPU, 1) } else { 0 }
            }
        } catch {
        }
    }
    return @($rows | Sort-Object MemoryMB -Descending | Select-Object -First 15)
}

function Get-TopIoProcesses {
    try {
        $metadata = @{}
        foreach ($process in (Get-CimInstance Win32_Process -ErrorAction Stop)) {
            $metadata[[int]$process.ProcessId] = $process
        }
        $rows = foreach ($sample in (Get-CimInstance Win32_PerfFormattedData_PerfProc_Process -ErrorAction Stop)) {
            $id = [int]$sample.IDProcess
            $dataBytes = [double]$sample.IODataBytesPersec
            if ($id -gt 0 -and $dataBytes -gt 262144 -and $metadata.ContainsKey($id)) {
                $process = $metadata[$id]
                [pscustomobject]@{
                    Name = [string]$sample.Name
                    Id = $id
                    DataMBps = [math]::Round($dataBytes / 1MB, 2)
                    ReadMBps = [math]::Round(([double]$sample.IOReadBytesPersec) / 1MB, 2)
                    WriteMBps = [math]::Round(([double]$sample.IOWriteBytesPersec) / 1MB, 2)
                    CpuPercent = [math]::Round([double]$sample.PercentProcessorTime, 1)
                    CommandLine = [string]$process.CommandLine
                    ParentProcessId = [int]$process.ParentProcessId
                }
            }
        }
        return @($rows | Sort-Object DataMBps -Descending | Select-Object -First 15)
    } catch {
        return @()
    }
}

function Get-TopCpuProcesses {
    try {
        $metadata = @{}
        foreach ($process in (Get-CimInstance Win32_Process -ErrorAction Stop)) {
            $metadata[[int]$process.ProcessId] = $process
        }
        $rows = foreach ($sample in (Get-CimInstance Win32_PerfFormattedData_PerfProc_Process -ErrorAction Stop)) {
            $id = [int]$sample.IDProcess
            $cpuPercent = [double]$sample.PercentProcessorTime
            if ($id -gt 0 -and $cpuPercent -gt 1 -and $metadata.ContainsKey($id)) {
                $process = $metadata[$id]
                [pscustomobject]@{
                    Name = [string]$sample.Name
                    Id = $id
                    CpuPercent = [math]::Round($cpuPercent, 1)
                    DataMBps = [math]::Round(([double]$sample.IODataBytesPersec) / 1MB, 2)
                    CommandLine = [string]$process.CommandLine
                    MayBeMeasurementOverhead = ([string]$sample.Name -match '^(WmiPrvSE|powershell|pwsh)(#\d+)?$')
                }
            }
        }
        return @($rows | Sort-Object CpuPercent -Descending | Select-Object -First 15)
    } catch {
        return @()
    }
}

function Get-ReadonlyRobocopyScans {
    $rows = foreach ($process in (Get-CimInstance Win32_Process -Filter "Name='robocopy.exe'")) {
        $commandLine = [string]$process.CommandLine
        if ($commandLine -match '(?i)\s/L(\s|$)' -and
            $commandLine -match '(?i)\s/S(\s|$)' -and
            $commandLine -match '(?i)\s/BYTES(\s|$)') {
            $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$($process.ParentProcessId)"
            [pscustomobject]@{
                ProcessId = $process.ProcessId
                ParentProcessId = $process.ParentProcessId
                AgeSeconds = [math]::Round(((Get-Date) - $process.CreationDate).TotalSeconds, 0)
                CommandLine = $commandLine
                ParentCommandLine = [string]$parent.CommandLine
            }
        }
    }
    return @($rows)
}

function Get-ReadonlyCodexDriveSearches {
    $rows = foreach ($process in (Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match '^(pwsh|powershell)(\.exe)?$' -and
        $_.CommandLine -match '(?i)Get-ChildItem' -and
        $_.CommandLine -match '(?i)-Recurse' -and
        $_.CommandLine -match '(?i)(-LiteralPath|-Path)\s+[\"'']?[A-Z]:\\[\"'']?'
    })) {
        $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$($process.ParentProcessId)"
        if ([string]$parent.Name -match '(?i)^codex(\.exe)?$|codex-code-mode-host') {
            [pscustomobject]@{
                ScanType = 'Codex recursive drive search'
                ProcessId = $process.ProcessId
                ParentProcessId = $process.ParentProcessId
                AgeSeconds = [math]::Round(((Get-Date) - $process.CreationDate).TotalSeconds, 0)
                CommandLine = [string]$process.CommandLine
                ParentCommandLine = [string]$parent.CommandLine
            }
        }
    }
    return @($rows)
}

function Get-ReadonlyCodexScans {
    $scans = @()
    $scans += @(Get-ReadonlyRobocopyScans | ForEach-Object {
        $_ | Add-Member -NotePropertyName ScanType -NotePropertyValue 'Codex robocopy read-only scan' -PassThru
    })
    $scans += @(Get-ReadonlyCodexDriveSearches)
    return @($scans)
}

function Get-ObservedDiskScanners {
    $knownNames = @('WizTree', 'WizTree64', 'Krokiet')
    $rows = foreach ($process in (Get-Process -ErrorAction SilentlyContinue | Where-Object { $knownNames -contains $_.ProcessName })) {
        try {
            [pscustomobject]@{
                ProcessId = $process.Id
                ProcessName = $process.ProcessName
                MemoryMB = [math]::Round($process.WorkingSet64 / 1MB, 0)
                StartTime = $process.StartTime
                Reason = 'Known disk analyzer observed during high disk pressure diagnosis'
            }
        } catch {
        }
    }
    return @($rows)
}

function Get-ScheduleRole {
    param([string]$CommandLine)

    $rules = @(
        [pscustomobject]@{ Role = 'Niannian bridge watcher'; Pattern = '(?i)niannian_controller_bridge\.js.*--watch' },
        [pscustomobject]@{ Role = 'Niannian bridge launcher'; Pattern = '(?i)run_bridge\.ps1.*-Watch' },
        [pscustomobject]@{ Role = 'Codex thread log watcher'; Pattern = '(?i)resume-codex-app-threads\.ps1.*-Watch' },
        [pscustomobject]@{ Role = 'Codex log query'; Pattern = '(?i)(?=.*\bsqlite3(?:\.exe)?\b)(?=.*logs_2\.sqlite)(?=.*session_loop).*' }
    )
    $rule = $rules | Where-Object { $CommandLine -match $_.Pattern } | Select-Object -First 1
    if ($rule) {
        return [string]$rule.Role
    }
    return $null
}

function Get-SchedulableWatchers {
    $rows = foreach ($process in (Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
        $commandLine = [string]$process.CommandLine
        $role = Get-ScheduleRole -CommandLine $commandLine
        if ($role) {
            $priorityClass = $null
            try {
                $priorityClass = [string](Get-Process -Id ([int]$process.ProcessId) -ErrorAction Stop).PriorityClass
            } catch {
                $priorityClass = $null
            }
            [pscustomobject]@{
                ProcessId = [int]$process.ProcessId
                ParentProcessId = [int]$process.ParentProcessId
                ProcessName = [string]$process.Name
                Role = $role
                PriorityClass = $priorityClass
                CommandLine = $commandLine
            }
        }
    }
    return @($rows | Sort-Object ProcessId -Unique)
}

function Get-ScheduleStatePath {
    return (Join-Path ([System.IO.Path]::GetTempPath()) 'computer-accelerator-schedule-state.json')
}

function Read-ScheduleState {
    $path = Get-ScheduleStatePath
    if (-not (Test-Path -LiteralPath $path)) {
        return @()
    }
    try {
        $document = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        return @($document.Entries)
    } catch {
        return @()
    }
}

function Write-ScheduleState {
    param([object[]]$Entries)

    $path = Get-ScheduleStatePath
    [pscustomobject]@{
        Schema = 'computer-accelerator.schedule-state.v1'
        UpdatedAt = (Get-Date).ToString('o')
        Entries = @($Entries)
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $path -Encoding UTF8
    return $path
}

function Schedule-BackgroundWatchers {
    $statePath = Get-ScheduleStatePath
    $existing = @(Read-ScheduleState)
    $targets = @(Get-SchedulableWatchers)
    $actions = @()
    $newEntries = @()

    foreach ($target in $targets) {
        try {
            $process = Get-Process -Id $target.ProcessId -ErrorAction Stop
            $currentPriority = [string]$process.PriorityClass
            $previousEntry = $existing | Where-Object {
                [int]$_.ProcessId -eq $target.ProcessId -and [string]$_.CommandLine -ceq $target.CommandLine
            } | Select-Object -First 1
            $originalPriority = if ($previousEntry) { [string]$previousEntry.OriginalPriorityClass } else { $currentPriority }
            $changed = $false
            if ($currentPriority -ne 'BelowNormal') {
                $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
                $changed = $true
            }
            $newEntries += [pscustomobject]@{
                ProcessId = $target.ProcessId
                ProcessName = $target.ProcessName
                Role = $target.Role
                CommandLine = $target.CommandLine
                OriginalPriorityClass = $originalPriority
                ScheduledPriorityClass = 'BelowNormal'
                SavedAt = if ($previousEntry) { [string]$previousEntry.SavedAt } else { (Get-Date).ToString('o') }
            }
            $actions += [pscustomobject]@{
                ProcessId = $target.ProcessId
                ProcessName = $target.ProcessName
                Role = $target.Role
                Action = if ($changed) { 'Set background watcher priority to BelowNormal' } else { 'Background watcher already BelowNormal' }
                PreviousPriority = $currentPriority
                NewPriority = [string]$process.PriorityClass
                Changed = $changed
                Success = $true
                CommandLine = $target.CommandLine
            }
        } catch {
            $actions += [pscustomobject]@{
                ProcessId = $target.ProcessId
                ProcessName = $target.ProcessName
                Role = $target.Role
                Action = 'Set background watcher priority to BelowNormal'
                Changed = $false
                Success = $false
                Error = $_.Exception.Message
                CommandLine = $target.CommandLine
            }
        }
    }

    if ($targets.Count -eq 0) {
        $actions += [pscustomobject]@{
            Action = 'No exact background watcher matched'
            Changed = $false
            Success = $false
            Reason = 'Only the four evidence-backed command-line patterns are schedulable'
        }
    }

    $merged = @()
    foreach ($entry in $existing) {
        $replacement = $newEntries | Where-Object {
            [int]$_.ProcessId -eq [int]$entry.ProcessId -and [string]$_.CommandLine -ceq [string]$entry.CommandLine
        } | Select-Object -First 1
        if ($replacement) {
            $merged += $replacement
        } else {
            $merged += $entry
        }
    }
    foreach ($entry in $newEntries) {
        $known = $merged | Where-Object {
            [int]$_.ProcessId -eq [int]$entry.ProcessId -and [string]$_.CommandLine -ceq [string]$entry.CommandLine
        } | Select-Object -First 1
        if (-not $known) {
            $merged += $entry
        }
    }
    Write-ScheduleState -Entries $merged | Out-Null
    return @($actions)
}

function Restore-BackgroundWatcherSchedule {
    $statePath = Get-ScheduleStatePath
    $entries = @(Read-ScheduleState)
    $remaining = @()
    $actions = @()

    foreach ($entry in $entries) {
        $live = Get-CimInstance Win32_Process -Filter "ProcessId=$([int]$entry.ProcessId)" -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $live) {
            $actions += [pscustomobject]@{
                ProcessId = [int]$entry.ProcessId
                Role = [string]$entry.Role
                Action = 'Process is no longer running; no restore needed'
                Success = $true
                Restored = $false
            }
            continue
        }
        if ([string]$live.CommandLine -cne [string]$entry.CommandLine) {
            $remaining += $entry
            $actions += [pscustomobject]@{
                ProcessId = [int]$entry.ProcessId
                Role = [string]$entry.Role
                Action = 'Refused restore because PID command line changed'
                Success = $false
                Restored = $false
                CurrentCommandLine = [string]$live.CommandLine
                SavedCommandLine = [string]$entry.CommandLine
            }
            continue
        }
        try {
            $process = Get-Process -Id ([int]$entry.ProcessId) -ErrorAction Stop
            $desiredPriority = [System.Enum]::Parse([System.Diagnostics.ProcessPriorityClass], [string]$entry.OriginalPriorityClass)
            $currentPriority = [string]$process.PriorityClass
            if ($currentPriority -ne [string]$entry.OriginalPriorityClass) {
                $process.PriorityClass = $desiredPriority
            }
            $actions += [pscustomobject]@{
                ProcessId = [int]$entry.ProcessId
                ProcessName = [string]$entry.ProcessName
                Role = [string]$entry.Role
                Action = 'Restored original process priority'
                PreviousPriority = $currentPriority
                NewPriority = [string]$process.PriorityClass
                Success = $true
                Restored = $true
            }
        } catch {
            $remaining += $entry
            $actions += [pscustomobject]@{
                ProcessId = [int]$entry.ProcessId
                Role = [string]$entry.Role
                Action = 'Restore original process priority'
                Success = $false
                Restored = $false
                Error = $_.Exception.Message
            }
        }
    }

    Write-ScheduleState -Entries $remaining | Out-Null
    if ($entries.Count -eq 0) {
        $actions += [pscustomobject]@{
            Action = 'No saved background watcher schedule found'
            Success = $true
            Restored = $false
        }
    }
    return @($actions)
}

function Get-ToolStatus {
    $localToolRoot = Join-Path $env:LOCALAPPDATA 'ComputerAccelerator\tools'
    $candidates = @(
        @{ Name = 'System Informer'; Paths = @('C:\Program Files\SystemInformer\SystemInformer.exe', 'C:\Program Files\SystemInformer\x86\SystemInformer.exe') },
        @{ Name = 'LibreHardwareMonitor'; Paths = @((Join-Path $localToolRoot 'LibreHardwareMonitor\LibreHardwareMonitor.exe')) },
        @{ Name = 'Mem Reduct'; Paths = @('C:\Program Files\Mem Reduct\memreduct.exe', 'C:\Program Files\Mem Reduct\memreduct64.exe') }
    )
    $commands = foreach ($candidate in $candidates) {
        $path = $candidate.Paths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if ($path) {
            [pscustomobject]@{ Name = $candidate.Name; Available = $true; Source = $path }
        }
    }
    return @($commands)
}

function Get-StorageHealth {
    $rows = foreach ($disk in (Get-PhysicalDisk -ErrorAction SilentlyContinue)) {
        [pscustomobject]@{
            FriendlyName = [string]$disk.FriendlyName
            SerialNumber = [string]$disk.SerialNumber
            MediaType = [string]$disk.MediaType
            BusType = [string]$disk.BusType
            HealthStatus = [string]$disk.HealthStatus
            OperationalStatus = [string]$disk.OperationalStatus
            SizeGB = [math]::Round(([double]$disk.Size / 1GB), 1)
        }
    }
    return @($rows)
}

function Get-SystemFaultSignals {
    $providers = @('disk', 'storahci', 'stornvme', 'iaStorA', 'iaStorAVC', 'volmgr', 'Ntfs', 'WHEA-Logger')
    $rows = foreach ($event in (Get-WinEvent -FilterHashtable @{ LogName = 'System'; StartTime = (Get-Date).AddDays(-7); Level = 1, 2, 3 } -ErrorAction SilentlyContinue | Where-Object {
        $_.ProviderName -in $providers -or $_.ProviderName -like 'Microsoft-Windows-WHEA*'
    } | Select-Object -First 30)) {
        $message = [string]$event.Message -replace '\s+', ' '
        if ($message.Length -gt 240) {
            $message = $message.Substring(0, 240)
        }
        [pscustomobject]@{
            TimeCreated = $event.TimeCreated
            Id = $event.Id
            ProviderName = $event.ProviderName
            Level = $event.LevelDisplayName
            Message = $message
        }
    }
    return @($rows)
}

function Get-CodexLogHealth {
    $logPath = Join-Path $env:USERPROFILE '.codex\logs_2.sqlite'
    $log = Get-Item -LiteralPath $logPath -ErrorAction SilentlyContinue
    $watchers = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -match '(?i)resume-codex-app-threads\.ps1' -and $_.CommandLine -match '(?i)-Watch'
    } | ForEach-Object {
        [pscustomobject]@{
            ProcessId = $_.ProcessId
            ParentProcessId = $_.ParentProcessId
            Name = $_.Name
            CreationDate = $_.CreationDate
            CommandLine = [string]$_.CommandLine
        }
    })
    [pscustomobject]@{
        Path = $logPath
        Exists = ($null -ne $log)
        SizeGB = if ($log) { [math]::Round($log.Length / 1GB, 2) } else { 0 }
        LastWriteTime = if ($log) { $log.LastWriteTime } else { $null }
        LargeLog = ($null -ne $log -and $log.Length -ge 512MB)
        WatcherCount = $watchers.Count
        Watchers = @($watchers)
    }
}

function Get-Snapshot {
    $os = Get-CimInstance Win32_OperatingSystem
    $processor = Get-CimInstance Win32_Processor | Select-Object -First 1
    $counterPaths = @(
        '\Processor(_Total)\% Processor Time',
        '\Memory\Available MBytes',
        '\Memory\Pages/sec',
        '\Memory\Page Reads/sec',
        '\Memory\Pages Input/sec',
        '\Memory\% Committed Bytes In Use',
        '\Processor(_Total)\% DPC Time',
        '\Processor(_Total)\% Interrupt Time',
        '\LogicalDisk(*)\Current Disk Queue Length',
        '\LogicalDisk(*)\Avg. Disk sec/Transfer'
    )
    $counterRows = Get-CounterAverage -CounterPaths $counterPaths
    $diskCounters = foreach ($row in $counterRows) {
        if ($row.Path -match '\\LogicalDisk\(([^)]+)\)\\([^\\]+)$') {
            [pscustomobject]@{
                Volume = $Matches[1]
                Counter = $Matches[2]
                Average = $row.Average
            }
        }
    }
    $volumes = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        [pscustomobject]@{
            Volume = $_.DeviceID
            SizeGB = [math]::Round($_.Size / 1GB, 1)
            FreeGB = [math]::Round($_.FreeSpace / 1GB, 1)
            FreePercent = [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
        }
    }
    $cpuCounter = $counterRows | Where-Object { $_.Path -match '\\Processor\(_Total\)\\% Processor Time$' } | Select-Object -First 1
    $memoryCounter = $counterRows | Where-Object { $_.Path -match '\\Memory\\Available MBytes$' } | Select-Object -First 1
    $memoryPages = $counterRows | Where-Object { $_.Path -match '\\Memory\\Pages/sec$' } | Select-Object -First 1
    $memoryPageReads = $counterRows | Where-Object { $_.Path -match '\\Memory\\Page Reads/sec$' } | Select-Object -First 1
    $memoryPagesInput = $counterRows | Where-Object { $_.Path -match '\\Memory\\Pages Input/sec$' } | Select-Object -First 1
    $memoryCommit = $counterRows | Where-Object { $_.Path -match '\\Memory\\% Committed Bytes In Use$' } | Select-Object -First 1
    $dpcCounter = $counterRows | Where-Object { $_.Path -match '\\Processor\(_Total\)\\% DPC Time$' } | Select-Object -First 1
    $interruptCounter = $counterRows | Where-Object { $_.Path -match '\\Processor\(_Total\)\\% Interrupt Time$' } | Select-Object -First 1

    [pscustomobject]@{
        Schema = 'computer-accelerator.snapshot.v1'
        Mode = $Mode
        Timestamp = (Get-Date).ToString('o')
        Computer = $env:COMPUTERNAME
        OS = $os.Caption
        LastBoot = $os.LastBootUpTime
        CpuLoadPercent = if ($cpuCounter) { $cpuCounter.Average } else { $processor.LoadPercentage }
        CurrentClockMHz = $processor.CurrentClockSpeed
        MaxClockMHz = $processor.MaxClockSpeed
        AvailableMemoryMB = if ($memoryCounter) { $memoryCounter.Average } else { [math]::Round($os.FreePhysicalMemory / 1KB, 0) }
        MemorySignals = [pscustomobject]@{
            PagesPerSec = if ($memoryPages) { $memoryPages.Average } else { $null }
            PageReadsPerSec = if ($memoryPageReads) { $memoryPageReads.Average } else { $null }
            PagesInputPerSec = if ($memoryPagesInput) { $memoryPagesInput.Average } else { $null }
            CommittedBytesPercent = if ($memoryCommit) { $memoryCommit.Average } else { $null }
        }
        ProcessorSignals = [pscustomobject]@{
            DpcPercent = if ($dpcCounter) { $dpcCounter.Average } else { $null }
            InterruptPercent = if ($interruptCounter) { $interruptCounter.Average } else { $null }
        }
        Volumes = @($volumes)
        DiskCounters = @($diskCounters)
        TopMemoryProcesses = @(Get-TopMemoryProcesses)
        TopIoProcesses = @(Get-TopIoProcesses)
        TopCpuProcesses = @(Get-TopCpuProcesses)
        ReadonlyCodexScans = @(Get-ReadonlyCodexScans)
        ReadonlyRobocopyScans = @(Get-ReadonlyCodexScans | Where-Object { $_.ScanType -eq 'Codex robocopy read-only scan' })
        ObservedDiskScanners = @(Get-ObservedDiskScanners)
        StorageHealth = @(Get-StorageHealth)
        SystemFaultSignals = @(Get-SystemFaultSignals)
        CodexLogHealth = Get-CodexLogHealth
        ToolStatus = @(Get-ToolStatus)
    }
}

function Get-BottleneckClassification {
    param([psobject]$Snapshot)

    $diskQueueRows = @($Snapshot.DiskCounters | Where-Object { $_.Counter -eq 'current disk queue length' -and $_.Volume -notin @('_total', 'harddiskvolume5') })
    $diskLatencyRows = @($Snapshot.DiskCounters | Where-Object { $_.Counter -eq 'avg. disk sec/transfer' -and $_.Volume -notin @('_total', 'harddiskvolume5') })
    $diskQueue = if ($diskQueueRows) { [double](($diskQueueRows | Measure-Object -Property Average -Maximum).Maximum) } else { 0 }
    $diskLatencySeconds = if ($diskLatencyRows) { [double](($diskLatencyRows | Measure-Object -Property Average -Maximum).Maximum) } else { 0 }
    $cpuPressure = [double]$Snapshot.CpuLoadPercent -ge 85
    $memoryPressure = [double]$Snapshot.AvailableMemoryMB -lt 2048
    $pagingPressure = [double]$Snapshot.AvailableMemoryMB -lt 4096 -and [double]$Snapshot.MemorySignals.PageReadsPerSec -gt 20
    $diskPressure = $diskQueue -gt 2 -or $diskLatencySeconds -gt 0.02
    $codexLogPressure = $diskPressure -and $Snapshot.CodexLogHealth.LargeLog -and [int]$Snapshot.CodexLogHealth.WatcherCount -gt 0
    $readonlyPressure = @($Snapshot.ReadonlyCodexScans).Count -gt 0
    $staleReadonlyPressure = @($Snapshot.ReadonlyCodexScans | Where-Object { [double]$_.AgeSeconds -ge 30 }).Count -gt 0
    $observedScannerPressure = @($Snapshot.ObservedDiskScanners).Count -gt 0

    [pscustomobject]@{
        CpuPressure = $cpuPressure
        MemoryPressure = $memoryPressure
        PagingPressure = $pagingPressure
        CodexLogPressure = $codexLogPressure
        DiskPressure = $diskPressure
        ReadonlyScanPressure = $readonlyPressure
        StaleReadonlyScanPressure = $staleReadonlyPressure
        ObservedScannerPressure = $observedScannerPressure
        MaxDiskQueue = [math]::Round($diskQueue, 2)
        MaxDiskLatencyMs = [math]::Round($diskLatencySeconds * 1000, 1)
        AvailableMemoryMB = [math]::Round([double]$Snapshot.AvailableMemoryMB, 0)
        CpuLoadPercent = [math]::Round([double]$Snapshot.CpuLoadPercent, 1)
    }
}

function Get-RootCauseCandidates {
    param(
        [psobject]$Snapshot,
        [psobject]$Classification
    )

    $candidates = @()
    if ($Classification.DiskPressure) {
        foreach ($process in @($Snapshot.TopIoProcesses | Select-Object -First 5)) {
            $candidates += [pscustomobject]@{
                Resource = 'Disk I/O'
                Process = $process.Name
                ProcessId = $process.Id
                Evidence = "Data $($process.DataMBps) MB/s; read $($process.ReadMBps) MB/s; write $($process.WriteMBps) MB/s"
                CommandLine = $process.CommandLine
                SafeAutomaticAction = ($process.Name -in @('Krokiet', 'WizTree', 'WizTree64')) -or ($null -ne (Get-ScheduleRole -CommandLine $process.CommandLine))
                ActionHint = if ($null -ne (Get-ScheduleRole -CommandLine $process.CommandLine)) { 'Lower the exact watcher priority to BelowNormal and keep it running' } elseif ($process.CommandLine -match '(?i)(--watch|\s-Watch)') { 'Review or pause the long-running watcher after confirming its project role' } else { $null }
            }
        }
        foreach ($scan in @($Snapshot.ReadonlyCodexScans)) {
            $candidates += [pscustomobject]@{
                Resource = 'Disk I/O'
                Process = $scan.ScanType
                ProcessId = $scan.ProcessId
                Evidence = 'Codex-launched recursive read-only scan'
                CommandLine = $scan.CommandLine
                SafeAutomaticAction = $true
            }
        }
    }
    if ($Classification.CpuPressure) {
        foreach ($process in @($Snapshot.TopCpuProcesses | Where-Object { -not $_.MayBeMeasurementOverhead } | Select-Object -First 5)) {
            $candidates += [pscustomobject]@{
                Resource = 'CPU'
                Process = $process.Name
                ProcessId = $process.Id
                Evidence = "CPU $($process.CpuPercent)%; I/O $($process.DataMBps) MB/s"
                CommandLine = $process.CommandLine
                SafeAutomaticAction = ($process.Name -in @('Krokiet', 'WizTree', 'WizTree64')) -or ($null -ne (Get-ScheduleRole -CommandLine $process.CommandLine))
                ActionHint = if ($null -ne (Get-ScheduleRole -CommandLine $process.CommandLine)) { 'Lower the exact watcher priority to BelowNormal and keep it running' } elseif ($process.CommandLine -match '(?i)(--watch|\s-Watch)') { 'Review or pause the long-running watcher after confirming its project role' } else { $null }
            }
        }
    }
    if ($Classification.CodexLogPressure) {
        foreach ($watcher in @($Snapshot.CodexLogHealth.Watchers)) {
            $candidates += [pscustomobject]@{
                Resource = 'Background log I/O'
                Process = $watcher.Name
                ProcessId = $watcher.ProcessId
                Evidence = "logs_2.sqlite size $($Snapshot.CodexLogHealth.SizeGB) GB; watcher active since $($watcher.CreationDate)"
                CommandLine = $watcher.CommandLine
                SafeAutomaticAction = ($null -ne (Get-ScheduleRole -CommandLine $watcher.CommandLine))
                ActionHint = if ($null -ne (Get-ScheduleRole -CommandLine $watcher.CommandLine)) { 'Lower the exact log watcher priority to BelowNormal and keep it running' } else { 'Review log retention or stop the watcher only with explicit user approval' }
            }
        }
    }
    if ($Classification.MemoryPressure -or $Classification.PagingPressure) {
        foreach ($process in @($Snapshot.TopMemoryProcesses | Select-Object -First 5)) {
            $candidates += [pscustomobject]@{
                Resource = 'Memory'
                Process = $process.Name
                ProcessId = $process.Id
                Evidence = "Working set $($process.MemoryMB) MB"
                CommandLine = $null
                SafeAutomaticAction = $false
            }
        }
    }
    return @($candidates | Select-Object -First 15)
}

function Stop-ReadonlyScans {
    $actions = foreach ($scan in (Get-ReadonlyCodexScans)) {
        try {
            Stop-Process -Id $scan.ProcessId -ErrorAction Stop
            [pscustomobject]@{ ProcessId = $scan.ProcessId; Action = "Stopped $($scan.ScanType)"; Success = $true }
        } catch {
            [pscustomobject]@{ ProcessId = $scan.ProcessId; Action = "Stop $($scan.ScanType)"; Success = $false; Error = $_.Exception.Message }
        }

        $parentCommandLine = $scan.ParentCommandLine
        if ($scan.ScanType -eq 'Codex robocopy read-only scan' -and
            $parentCommandLine -match '(?i)robocopy\.exe' -and
            $parentCommandLine -match '(?i)/L' -and
            $parentCommandLine -match '(?i)/S' -and
            $parentCommandLine -match '(?i)/BYTES') {
            try {
                Stop-Process -Id $scan.ParentProcessId -ErrorAction Stop
                [pscustomobject]@{ ProcessId = $scan.ParentProcessId; Action = 'Stopped parent read-only scan loop'; Success = $true }
            } catch {
                [pscustomobject]@{ ProcessId = $scan.ParentProcessId; Action = 'Stop parent read-only scan loop'; Success = $false; Error = $_.Exception.Message }
            }
        }
    }
    return @($actions)
}

function Stop-ObservedDiskScanners {
    $actions = foreach ($scanner in (Get-ObservedDiskScanners)) {
        try {
            Stop-Process -Id $scanner.ProcessId -Force -ErrorAction Stop
            [pscustomobject]@{ ProcessId = $scanner.ProcessId; ProcessName = $scanner.ProcessName; Action = 'Stopped observed disk analyzer'; Success = $true }
        } catch {
            [pscustomobject]@{ ProcessId = $scanner.ProcessId; ProcessName = $scanner.ProcessName; Action = 'Stop observed disk analyzer'; Success = $false; Error = $_.Exception.Message }
        }
    }
    return @($actions)
}

function Get-OptimizationVerification {
    param(
        [psobject]$Before,
        [psobject]$After,
        [psobject]$BeforeClassification,
        [psobject]$AfterClassification,
        [object[]]$Actions
    )

    $pressureBefore = @(
        if ($BeforeClassification.CpuPressure) { 'CPU' }
        if ($BeforeClassification.MemoryPressure) { 'Memory' }
        if ($BeforeClassification.PagingPressure) { 'Paging' }
        if ($BeforeClassification.CodexLogPressure) { 'CodexLog' }
        if ($BeforeClassification.DiskPressure) { 'Disk' }
    )
    $pressureAfter = @(
        if ($AfterClassification.CpuPressure) { 'CPU' }
        if ($AfterClassification.MemoryPressure) { 'Memory' }
        if ($AfterClassification.PagingPressure) { 'Paging' }
        if ($AfterClassification.CodexLogPressure) { 'CodexLog' }
        if ($AfterClassification.DiskPressure) { 'Disk' }
    )
    $cleared = @($pressureBefore | Where-Object { $_ -notin $pressureAfter })
    $safeActions = @($Actions | Where-Object { $_.Success -eq $true })
    $outcome = if ($pressureBefore.Count -eq 0) {
        'NoOptimizationNeeded'
    } elseif ($cleared.Count -gt 0) {
        'Improved'
    } elseif ($safeActions.Count -eq 0) {
        'NoSafeAction'
    } else {
        'NotResolved'
    }
    $nextAction = switch ($outcome) {
        'NoOptimizationNeeded' { 'Continue normal use; no measured pressure required intervention.'; break }
        'Improved' { 'Keep the stopped scan tasks closed and observe the live counters.'; break }
        'NoSafeAction' { 'Use System Informer and LibreHardwareMonitor to inspect the named CPU, memory, or thermal source.'; break }
        default { 'Repeat a focused diagnosis; do not apply broader system tweaks automatically.' }
    }

    [pscustomobject]@{
        Outcome = $outcome
        PressureBefore = @($pressureBefore)
        PressureAfter = @($pressureAfter)
        ClearedPressure = @($cleared)
        ActionsSucceeded = $safeActions.Count
        Before = $BeforeClassification
        After = $AfterClassification
        NextAction = $nextAction
    }
}

function Optimize-Computer {
    $before = Get-Snapshot
    $beforeClassification = Get-BottleneckClassification -Snapshot $before
    $actions = @()

    $after = $before
    $maxPasses = 3
    $scheduleApplied = $false
    for ($pass = 1; $pass -le $maxPasses; $pass++) {
        $current = if ($pass -eq 1) { $before } else { $after }
        $classification = if ($pass -eq 1) { $beforeClassification } else { Get-BottleneckClassification -Snapshot $current }
        if (-not ($classification.CpuPressure -or $classification.DiskPressure)) {
            break
        }

        $passActions = @()
        if (-not $scheduleApplied) {
            $passActions += Schedule-BackgroundWatchers
            $scheduleApplied = $true
        }
        if ($classification.ReadonlyScanPressure -and ($classification.DiskPressure -or $classification.StaleReadonlyScanPressure)) {
            $passActions += Stop-ReadonlyScans
        }
        if ($classification.ObservedScannerPressure) {
            $passActions += Stop-ObservedDiskScanners
        }
        $actions += $passActions
        if (@($passActions).Count -eq 0) {
            break
        }

        $settle = [math]::Max(0, [math]::Min($SettleSeconds, 30))
        if ($settle -gt 0) {
            Start-Sleep -Seconds $settle
        }
        $after = Get-Snapshot
    }

    $afterClassification = Get-BottleneckClassification -Snapshot $after
    [pscustomobject]@{
        Schema = 'computer-accelerator.optimize.v1'
        Timestamp = (Get-Date).ToString('o')
        MaxPasses = $maxPasses
        Actions = @($actions)
        Diagnosis = $beforeClassification
        RootCauseCandidates = @(Get-RootCauseCandidates -Snapshot $before -Classification $beforeClassification)
        Verification = Get-OptimizationVerification -Before $before -After $after -BeforeClassification $beforeClassification -AfterClassification $afterClassification -Actions $actions
        Before = $before
        After = $after
    }
}

function Monitor-Computer {
    $duration = [math]::Max(20, [math]::Min($DurationSeconds, 300))
    $interval = [math]::Max(0, [math]::Min($MonitorIntervalSeconds, 30))
    $started = Get-Date
    $samples = @()
    do {
        $samples += Get-Snapshot
        $elapsed = ((Get-Date) - $started).TotalSeconds
        if ($elapsed -lt $duration -and $interval -gt 0) {
            Start-Sleep -Seconds ([math]::Min($interval, [math]::Max(0, $duration - $elapsed)))
        }
    } while (((Get-Date) - $started).TotalSeconds -lt $duration)

    $cpuValues = @($samples | ForEach-Object { [double]$_.CpuLoadPercent })
    $memoryValues = @($samples | ForEach-Object { [double]$_.AvailableMemoryMB })
    $queueValues = @($samples | ForEach-Object {
        $_.DiskCounters | Where-Object { $_.Counter -eq 'current disk queue length' -and $_.Volume -notin @('_total', 'harddiskvolume5') } | ForEach-Object { [double]$_.Average }
    })
    $latencyValues = @($samples | ForEach-Object {
        $_.DiskCounters | Where-Object { $_.Counter -eq 'avg. disk sec/transfer' -and $_.Volume -notin @('_total', 'harddiskvolume5') } | ForEach-Object { [double]$_.Average * 1000 }
    })
    $pageReadValues = @($samples | ForEach-Object { [double]$_.MemorySignals.PageReadsPerSec })
    $dpcValues = @($samples | ForEach-Object { [double]$_.ProcessorSignals.DpcPercent })
    $interruptValues = @($samples | ForEach-Object { [double]$_.ProcessorSignals.InterruptPercent })
    $peakCpu = if ($cpuValues) { ($cpuValues | Measure-Object -Maximum).Maximum } else { 0 }
    $minMemory = if ($memoryValues) { ($memoryValues | Measure-Object -Minimum).Minimum } else { 0 }
    $peakQueue = if ($queueValues) { ($queueValues | Measure-Object -Maximum).Maximum } else { 0 }
    $peakLatency = if ($latencyValues) { ($latencyValues | Measure-Object -Maximum).Maximum } else { 0 }
    $peakPageReads = if ($pageReadValues) { ($pageReadValues | Measure-Object -Maximum).Maximum } else { 0 }
    $peakDpc = if ($dpcValues) { ($dpcValues | Measure-Object -Maximum).Maximum } else { 0 }
    $peakInterrupt = if ($interruptValues) { ($interruptValues | Measure-Object -Maximum).Maximum } else { 0 }
    $pressurePeaks = @(
        if ($peakCpu -ge 85) { 'CPU' }
        if ($peakQueue -gt 2 -or $peakLatency -gt 20) { 'Disk' }
        if ($minMemory -lt 2048) { 'Memory' }
        if ($minMemory -lt 4096 -and $peakPageReads -gt 20) { 'Paging' }
    )
    $latest = $samples | Select-Object -Last 1
    [pscustomobject]@{
        Schema = 'computer-accelerator.monitor.v1'
        Mode = 'Monitor'
        Timestamp = (Get-Date).ToString('o')
        DurationSeconds = [math]::Round(((Get-Date) - $started).TotalSeconds, 1)
        SampleCount = @($samples).Count
        Outcome = if ($pressurePeaks.Count -gt 0) { 'IntermittentPressureDetected' } else { 'NoPressureDetected' }
        PeakSignals = [pscustomobject]@{
            CpuLoadPercent = [math]::Round([double]$peakCpu, 1)
            AvailableMemoryMBMinimum = [math]::Round([double]$minMemory, 0)
            MaxDiskQueue = [math]::Round([double]$peakQueue, 2)
            MaxDiskLatencyMs = [math]::Round([double]$peakLatency, 1)
            MaxPageReadsPerSec = [math]::Round([double]$peakPageReads, 1)
            MaxDpcPercent = [math]::Round([double]$peakDpc, 2)
            MaxInterruptPercent = [math]::Round([double]$peakInterrupt, 2)
        }
        PressurePeaks = @($pressurePeaks)
        PeakIoProcesses = @($samples | ForEach-Object { $_.TopIoProcesses } | Sort-Object DataMBps -Descending | Select-Object -First 15)
        MeasurementOverheadProcesses = @($samples | ForEach-Object { $_.TopCpuProcesses } | Where-Object { $_.MayBeMeasurementOverhead } | Sort-Object CpuPercent -Descending | Select-Object -First 10)
        PeakCpuProcesses = @($samples | ForEach-Object { $_.TopCpuProcesses } | Where-Object { -not $_.MayBeMeasurementOverhead } | Sort-Object CpuPercent -Descending | Select-Object -First 15)
        LatestSnapshot = $latest
    }
}

function Install-Tools {
    $packages = @(
        'WinsiderSS.SystemInformer',
        'LibreHardwareMonitor.LibreHardwareMonitor',
        'Henry++.MemReduct'
    )
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        return @([pscustomobject]@{ Success = $false; Error = 'winget is unavailable' })
    }
    $results = foreach ($package in $packages) {
        $output = & winget install --id $package --exact --source winget --accept-source-agreements --accept-package-agreements 2>&1
        $exitCode = $LASTEXITCODE
        $result = [pscustomobject]@{ Package = $package; ExitCode = $exitCode; Success = ($exitCode -eq 0); Output = (($output | Out-String).Trim()) }
        $result

        if ($package -eq 'LibreHardwareMonitor.LibreHardwareMonitor' -and $exitCode -ne 0) {
            $localToolRoot = Join-Path $env:LOCALAPPDATA 'ComputerAccelerator\tools\LibreHardwareMonitor'
            $zipPath = Join-Path $env:TEMP 'LibreHardwareMonitor-latest.zip'
            try {
                New-Item -ItemType Directory -Force $localToolRoot | Out-Null
                $release = Invoke-RestMethod -Headers @{ 'User-Agent' = 'Codex computer-accelerator' } -Uri 'https://api.github.com/repos/LibreHardwareMonitor/LibreHardwareMonitor/releases/latest'
                $asset = $release.assets | Where-Object { $_.name -eq 'LibreHardwareMonitor.zip' } | Select-Object -First 1
                if (-not $asset) { throw 'LibreHardwareMonitor.zip was not found in the latest release' }
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath
                Expand-Archive -LiteralPath $zipPath -DestinationPath $localToolRoot -Force
                $exe = Get-ChildItem -LiteralPath $localToolRoot -Filter 'LibreHardwareMonitor.exe' -Recurse | Select-Object -First 1
                [pscustomobject]@{ Package = $package; Method = 'GitHub ZIP fallback'; ExitCode = 0; Success = ($null -ne $exe); Path = if ($exe) { $exe.FullName } else { $null } }
            } catch {
                [pscustomobject]@{ Package = $package; Method = 'GitHub ZIP fallback'; ExitCode = 1; Success = $false; Error = $_.Exception.Message }
            }
        }
    }
    return @($results)
}

if ($Mode -eq 'InstallTools') {
    $result = [pscustomobject]@{
        Schema = 'computer-accelerator.install.v1'
        Timestamp = (Get-Date).ToString('o')
        Actions = @(Install-Tools)
        Snapshot = Get-Snapshot
    }
} elseif ($Mode -eq 'Apply') {
    $before = Get-Snapshot
    $actions = @()
    if ($StopReadonlyScans) {
        $actions += Stop-ReadonlyScans
    }
    if ($StopObservedDiskScanners) {
        $actions += Stop-ObservedDiskScanners
    }
    $after = Get-Snapshot
    $result = [pscustomobject]@{
        Schema = 'computer-accelerator.apply.v1'
        Timestamp = (Get-Date).ToString('o')
        Actions = @($actions)
        Before = $before
        After = $after
    }
} elseif ($Mode -eq 'Optimize') {
    $result = Optimize-Computer
} elseif ($Mode -eq 'Monitor') {
    $result = Monitor-Computer
} elseif ($Mode -eq 'Schedule') {
    $result = [pscustomobject]@{
        Schema = 'computer-accelerator.schedule.v1'
        Mode = 'Schedule'
        Timestamp = (Get-Date).ToString('o')
        StatePath = Get-ScheduleStatePath
        Actions = @(Schedule-BackgroundWatchers)
    }
} elseif ($Mode -eq 'RestoreSchedule') {
    $result = [pscustomobject]@{
        Schema = 'computer-accelerator.restore-schedule.v1'
        Mode = 'RestoreSchedule'
        Timestamp = (Get-Date).ToString('o')
        StatePath = Get-ScheduleStatePath
        Actions = @(Restore-BackgroundWatcherSchedule)
    }
} else {
    $result = Get-Snapshot
}

$json = $result | ConvertTo-Json -Depth 8
if ($OutputPath) {
    $json | Set-Content -LiteralPath $OutputPath -Encoding UTF8
}
Write-Output $json
