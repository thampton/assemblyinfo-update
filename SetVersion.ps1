$version = $Env:VERSION
$directory = $Env:DIRECTORY
$fileName = $Env:FILENAME
$recursive = [System.Convert]::ToBoolean($Env:RECURSIVE)
$runNumber = $Env:RUN_NUMBER
$useBuildNumber = [System.Convert]::ToBoolean($Env:USE_BUILD_NUMBER)
$githubOutput = $Env:GITHUB_OUTPUT

function SetVersion($file)
{
	$contents = [System.IO.File]::ReadAllText($file)
	$contents = [Regex]::Replace($contents, 'Version\("\d+\.\d+\.(\*|(\d+(\.\*|\.\d+)?))', 'Version("' + $version)
	$match = [Regex]::Match($contents, $version)
	if ($match.success)
	{
		$streamWriter = New-Object System.IO.StreamWriter($file, $false, [System.Text.Encoding]::GetEncoding("utf-8"))
		$streamWriter.Write($contents)
		$streamWriter.Close()

		Write-Output "version=$version" >> $githubOutput
		Write-Host "$file is now set to version $version"
	}
	else
	{
		Write-Host "Version has not been set correctly for $file"
	}
}

$isSemVer = [Regex]::Match($version, '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$')
if ($isSemVer.success)
{
	if( $useBuildNumber )
	{
		$version = $isSemVer.Value + '.' + $runNumber
	}
	else
	{
		$version = $isSemVer.Value
	}	
}
else
{
	Write-Host "Version number '$version' is invalid for use in assembly info versions"
}

if ($recursive)
{
	$assemblyInfoFiles = Get-ChildItem $directory -Recurse -Include $fileName
	foreach($file in $assemblyInfoFiles)
	{	
		SetVersion($file)
	}
}
else
{
	$file = Get-ChildItem $directory -Filter $fileName | Select-Object -First 1
	SetVersion($file)
}


