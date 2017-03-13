﻿function Get-WorkdayWorkerPhone {
<#
.SYNOPSIS
    Returns a Worker's phone numbers.

.DESCRIPTION
    Returns a Worker's phone numbers as custom Powershell objects.

.PARAMETER EmployeeId
    The Worker's Employee Id at Workday. This cmdlet does not currently
    support Contengent Workers or referencing workers by WID.

.PARAMETER Human_ResourcesUri
    Human_Resources Endpoint Uri for the request. If not provided, the value
    stored with Set-WorkdayEndpoint -Endpoint Human_Resources is used.

.PARAMETER Username
    Username used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.PARAMETER Password
    Password used to authenticate with Workday. If empty, the value stored
    using Set-WorkdayCredential will be used.

.EXAMPLE
    
Get-WorkdayWorkerPhone -EmpoyeeId 123

WorkerWid        : 00000000000000000000000000000000
WorkerDescriptor : Example Worker (1)
Type             : Work/Landline
Number           : +1 (517) 123-4567
Primary          : True
Public           : True

#>

	[CmdletBinding(DefaultParametersetName='Search')]
    [OutputType([PSCustomObject])]
	param (
		[Parameter(Mandatory = $true,
            ParameterSetName="Search")]
		[ValidateNotNullOrEmpty()]
		[string]$EmployeeId,
        [Parameter(ParameterSetName="Search")]
		[string]$Human_ResourcesUri,
        [Parameter(ParameterSetName="Search")]
		[string]$Username,
        [Parameter(ParameterSetName="Search")]
		[string]$Password,
        [Parameter(ParameterSetName="NoSearch")]
        [xml]$WorkerXml
	)

    if ([string]::IsNullOrWhiteSpace($Human_ResourcesUri)) { $Human_ResourcesUri = $WorkdayConfiguration.Endpoints['Human_Resources'] }

    if ($PsCmdlet.ParameterSetName -eq 'NoSearch') {
        $w = $WorkerXml
    } else {
        try {
            $w = Get-WorkdayWorker -EmployeeId $EmployeeId -IncludePersonal -Human_ResourcesUri $Human_ResourcesUri -Username:$Username -Password:$Password -ErrorAction Stop
        }
        catch {
            throw
        }
    }


    $numberTemplate = [pscustomobject][ordered]@{
        WorkerWid        = $w.Get_Workers_Response.Response_Data.Worker.Worker_Reference.ID | where {$_.type -eq 'WID'} | select -ExpandProperty '#text'
        WorkerDescriptor = $w.Get_Workers_Response.Request_References.Worker_Reference.Descriptor
        Type    = $null
        Number  = $null
        Primary = $null
        Public  = $null
    }

    $w.Get_Workers_Response.Response_Data.FirstChild.Worker_Data.Personal_Data.Contact_Data.Phone_Data | foreach {
        $o = $numberTemplate.PsObject.Copy()
        $o.Type = $_.Usage_Data.Type_Data.Type_Reference.Descriptor + '/' + $_.Phone_Device_Type_Reference.Descriptor
        $o.Number = $_.Formatted_Phone
        $o.Primary = [bool]$_.Usage_Data.Type_Data.Primary
        $o.Public = [bool]$_.Usage_Data.Public
        Write-Output $o
    }
}
