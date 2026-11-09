if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }

# Import-Bucket-Tests.ps1 defaults -BucketPath to $MyInvocation.PSScriptRoot,
# which is always empty when the script is invoked or dot-sourced; an empty path
# makes Get-ChildItem scan the current directory instead of this repository.
# Pass the bucket root explicitly so the tests do not depend on the caller's CWD.
$BucketPath = $PSScriptRoot

# This repository is a jj/git colocated working copy, so it carries a .jj
# directory with Jujutsu's internal metadata. Scoop's file tests scan the bucket
# root with Get-ChildItem (without -Force) and rely on the Hidden attribute to
# skip .git; do the same for .jj while the tests are discovered, then restore the
# original attribute. The attribute is local state and is not part of a commit.
$jjDir = Join-Path $PSScriptRoot '.jj'
$jjHidden = $false
$jj = $null
if (Test-Path -LiteralPath $jjDir) {
    $jj = Get-Item -LiteralPath $jjDir -Force
    if (-not ($jj.Attributes -band [IO.FileAttributes]::Hidden)) {
        $jj.Attributes = $jj.Attributes -bor [IO.FileAttributes]::Hidden
        $jjHidden = $true
    }
}

try {
    . "$env:SCOOP_HOME\test\Import-Bucket-Tests.ps1" -BucketPath $BucketPath
} finally {
    if ($jjHidden) {
        $jj.Attributes = $jj.Attributes -band (-bnot [IO.FileAttributes]::Hidden)
    }
}
