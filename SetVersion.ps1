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
$isDecmialMajorMinorOrPatch = [Regex]::Match($version, '^\d+\.\d+(\.\d+)?')
if ( $isSemVer.success || $isDecmialMajorMinorOrPatch.success )
{
	if ( $isDecmialMajorMinorOrPatch.success ) 
	{
		if( $useBuildNumber )
		{
			$version = $isDecmialMajorMinorOrPatch.Value + '.' + $runNumber
		}
		else
		{
			$version = $isDecmialMajorMinorOrPatch.Value
		}
	}
	else
	{
		$major = $isSemVer.Groups[0].Value
		$minor = $isSemVer.Groups[1].Value
		$patch = $isSemVer.Groups[2].Value
		
		$decimalMajor = [Regex]::Match($major, '[\d\.\d]+')
		$decimalMinor = [Regex]::Match($minor, '[\d\.\d]+')
		$decimalPatch = [Regex]::Match($patch, '[\d\.\d]+')
		
		if( $useBuildNumber )
		{
			$version = $decimalMajor.Value + '.' + $decimalMinor.Value + '.' $decimalPatch.Value + '.' + $runNumber
		}
		else
		{
			$version = $decimalMajor.Value + '.' + $decimalMinor.Value + '.' $decimalPatch.Value
		}	
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


