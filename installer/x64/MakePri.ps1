# This file is part of MagiskOnWSALocal.
#
# MagiskOnWSALocal is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# MagiskOnWSALocal is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with MagiskOnWSALocal.  If not, see <https://www.gnu.org/licenses/>.
#
# Copyright (C) 2023 LSPosed Contributors
#

$MakePri = Join-Path $PSScriptRoot "makepri.exe"

New-Item -Path "." -Name "priinfo" -ItemType "directory" | Out-Null
if (Test-Path .\resources.pri) {
    New-Item -Path "." -Name "pri" -ItemType "directory" -Force | Out-Null
    Copy-Item .\resources.pri -Destination ".\pri\resources.pri" | Out-Null
}
$AppxManifestFile = Join-Path $PSScriptRoot "AppxManifest.xml"
$PriItem = Get-Item ".\pri\*" -Include "*.pri"
Write-Output "Dumping resources..."
$Processes = foreach ($Item in $PriItem) {
    Start-Process -PassThru -WindowStyle Hidden $MakePri -Args "dump /if $($Item | Resolve-Path -Relative) /o /es .\pri\resources.pri /of .\priinfo\$($Item.Name).xml /dt detailed"
}
if ($Processes) {
    $Processes | Wait-Process
}

Write-Output "Creating pri from dumps...."
$ProcNewFromDump = Start-Process -PassThru -NoNewWindow $MakePri -Args "new /pr .\priinfo /cf .\xml\priconfig.xml /of .\resources.pri /mn $AppxManifestFile /o"
$ProcNewFromDump.WaitForExit()
Remove-Item 'priinfo' -Recurse -Force
if ($ProcNewFromDump.ExitCode -ne 0) {
    Write-Error "Failed to create resources from priinfos"
    exit 1
}

$ProjectXml = [xml](Get-Content $AppxManifestFile)
$ProjectResources = $ProjectXml.Package.Resources;
$(Get-Item .\xml\* -Exclude "priconfig.xml" -Include "*.xml") | ForEach-Object {
    $($([xml](Get-Content $_)).Package.Resources.Resource) | ForEach-Object {
        $ProjectResources.AppendChild($($ProjectXml.ImportNode($_, $true)))
    }
}
$ProjectXml.Save($AppxManifestFile)

Remove-Item 'pri' -Recurse -Force
Remove-Item 'xml' -Recurse -Force
Remove-Item (Join-Path $PSScriptRoot 'makepri.exe') -Force
Remove-Item (Join-Path $PSScriptRoot 'filelist-pri.txt') -Force
Remove-Item $PSCommandPath -Force
exit 0
