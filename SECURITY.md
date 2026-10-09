# Security

`Update-Windows11.ps1` requires administrator privileges and can change Windows Update services, caches, packages and system state. Review the source and run `-WhatIf` first from an elevated PowerShell session. Preview writes logs/transcript files but does not install modules or winget, alter services, clear caches, or apply updates. Never pipe unreviewed remote code to `Invoke-Expression`.

`updatew11.ps1` is now a compatibility wrapper around the maintained script and forwards `-WhatIf`/`-Confirm` and update-selection options. The previous implementation—which elevated with `ExecutionPolicy Bypass`, deleted update-cache files and could reboot automatically—has been replaced; do not run old copies of it.

Report vulnerabilities privately to the repository maintainer and do not
include real logs, tokens or machine identifiers in public issues.
