<#
.SYNOPSIS
Generates concrete versions of *.placeholder.json files. For example, foo.placeholder.json will
be processed by this script and it will generate foo.generated.json as a result (removing "placeholder" from the name).
The placeholder files get checked in to the repo, the generated files do not. This script is run
during the build pipeline to ensure artifacts have the generated files.
#>

# Make sure this script causes the build to fail if there are any errors
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Returns the contents from the yaml file, escaping all line breaks and quote characters so that it
can be injected into an ARM template or parameter file.

.PARAMETER YamlFile
The file to get the contents for. This should be a path relative to the location of the placeholder file.
#>
function Get-EscapedYamlContents
{
    param(
        $YamlFile
    )

    $yamlContents = Get-Content $YamlFile -Raw

    # Escape line break characters. Note that we replace \r\n and \n so that this script will work regardless
    # of whether the cloud-config.yml file ends up with Windows or Linux line endings
    $yamlContents = ($yamlContents -replace "`r`n","\n") -replace "`n","\n"

    # Escape double quote characters
    $yamlContents = $yamlContents -replace "`"","\`""

    return $yamlContents
}

<#
.DESCRIPTION
Expands sentinel values like the following:
  ##YAML:path/to/file.yml## (escapes line breaks and quotes and inserts contents in it's place)

.PARAMETER OriginalFile
File to do the find-and-replace for
#>
function Build-GeneratedFile
{
    param($OriginalFile)

    # Move to the directory with the placeholder, so that snippet references can be relative to that file.
    Push-Location (Get-ChildItem $OriginalFile).Directory.FullName

    # Do a find-and-replace for the sentinel value in the original file
    $lines = Get-Content $OriginalFile
    for ($i = 0; $i -lt $lines.Length; ++$i)
    {
        $line = $lines[$i]
        if ($line -match "##YAML:(?<snippetFile>[^#]+)##")
        {
            foreach ($match in $Matches)
            {
                $snippetFile = $match.snippetFile
                $sentinelValue = "##YAML:" + $snippetFile + "##"

                Write-Host "Replacing '$sentinelValue' with contents from $snippetFile, the following value:" -ForegroundColor DarkGreen
                $escapedContents = Get-EscapedYamlContents -YamlFile $snippetFile
                Write-Host $escapedContents

                $lines[$i] = $line -replace "$sentinelValue",$escapedContents
            }
        }
    }

    $generatedFile = (Get-ChildItem $OriginalFile).FullName.Replace(".placeholder.json", ".generated.json")
    
    Write-Host "Writing generated contents to $generatedFile" -ForegroundColor Green
    $lines | Set-Content $generatedFile

    Pop-Location
}

$templateFiles = Get-ChildItem -Filter "*.placeholder.json" -Recurse
foreach ($file in $templateFiles)
{
    Write-Host "Processing $file..." -ForegroundColor Green
    Build-GeneratedFile -OriginalFile $file.FullName
}
