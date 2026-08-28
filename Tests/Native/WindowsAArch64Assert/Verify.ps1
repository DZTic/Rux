param(
    [string]$Rux = (Join-Path $PSScriptRoot "../../../Bin/rux.exe")
)

$ErrorActionPreference = "Stop"

$manifest = Join-Path $PSScriptRoot "Fixture.toml"
& $Rux --manifest $manifest build --release --target windows-aarch64 --quiet
if ($LASTEXITCODE -ne 0) {
    throw "Failed to build the Windows AArch64 assertion fixture"
}

$executable = Join-Path $PSScriptRoot "../../../Bin/Tests/Native/Release/Windows/AArch64/WindowsAArch64Assert.exe"
$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $executable
$startInfo.UseShellExecute = $false
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.CreateNoWindow = $true

$process = [System.Diagnostics.Process]::new()
$process.StartInfo = $startInfo
if (-not $process.Start()) {
    throw "Failed to start the Windows AArch64 assertion fixture"
}
$stdout = $process.StandardOutput.ReadToEnd()
$stderr = $process.StandardError.ReadToEnd()
$process.WaitForExit()

if ($process.ExitCode -eq 0) {
    throw "The failing assertion returned successfully"
}
if ($stdout.Length -ne 0) {
    throw "The failing assertion unexpectedly wrote to stdout: $stdout"
}

$normalized = [regex]::Replace(
    $stderr,
    "\([^)]*Src[/\\]Main\.rux:[0-9]+:[0-9]+\)",
    "(Src/Main.rux:<line>:<column>)"
)
$expected = "Assertion failed: native Windows ARM64 assertion fixture`n" +
    "  at Main (Src/Main.rux:<line>:<column>)`n"
if ($normalized -cne $expected) {
    throw "Unexpected assertion stderr:`n$stderr"
}
