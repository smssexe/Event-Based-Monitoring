##### Create a PowerShell Script to sending EMail in c:\ #####
New-Item C:\RDP-Logs_Send-Email.ps1 -Force
Set-Content C:\RDP-Logs_Send-Email.ps1 'Remove-Item C:\RDP-Logs.txt -Force
wevtutil qe "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" "/q:*[System [(EventID=21)]]" /f:text /rd:true /c:1 > C:\RDP-Logs.txt
wevtutil qe "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" "/q:*[System [(EventID=23)]]" /f:text /rd:true /c:1 >> C:\RDP-Logs.txt
wevtutil qe "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" "/q:*[System [(EventID=24)]]" /f:text /rd:true /c:1 >> C:\RDP-Logs.txt
wevtutil qe "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" "/q:*[System [(EventID=25)]]" /f:text /rd:true /c:1 >> C:\RDP-Logs.txt
## for action to sending Email:
$From = "Events@domain.com"
$To = "Email@domain.com"
#$CC = "Email@domain.com"
$Attachments = "C:\RDP-Logs.txt"
$SmtpServer = "mail.domain.com"
$Subject = $env:computername
$body = Get-Content C:\RDP-Logs.txt
Send-MailMessage -Attachments $Attachments -body ($body | Out-String) -From $from -To $to -SmtpServer $SmtpServer -Subject $Subject
### {qe | query-events} = Reads events from an event log, from a log file, or using a structured query. By default, you provide a log name for <Path>. However, if you use the /lf option, then <Path> must be a path to a log file. If you use the /sq parameter, <Path> must be a path to a file that contains a structured query.
### /f:<Format> = Specifies that the output should be either XML or text format. If <Format> is XML, the output is displayed in XML format. If <Format> is Text, the output is displayed without XML tags. The default is Text.
### /rd:<Direction> = Specifies the direction in which events are read. <Direction> can be true or false. If true, the most recent events are returned first.
### /c:<Count> = Sets the maximum number of events to read.'

##### Create a Scheduled Task for Event id 21, 23, 24, 25 (RDP Log in, RDP Log off, RDP Disconnect , RDP Reconnect) #####
## for store events information:
New-Item C:\RDP-Logs.txt -Force
## for creating scheduled task:

$name = 'Login'
$taskRunAsuser = "domain\user"
$taskRunasUserPwd = ""
$Hostname = $Env:computername

$Service = new-object -ComObject ("Schedule.Service")
$Service.Connect($Hostname)
$RootFolder = $Service.GetFolder("\")
$TaskDefinition = $Service.NewTask(0)
$regInfo = $TaskDefinition.RegistrationInfo
$regInfo.Description = "Send Email to Administrator when Any User Logs in or off"
$regInfo.Author = $taskRunAsuser
$settings = $taskDefinition.Settings
$settings.Enabled = $true
$settings.StartWhenAvailable = $true
$settings.AllowDemandStart = $false
$settings.Hidden = $false
$Triggers = $TaskDefinition.Triggers
$Trigger = $Triggers.Create(0) ## 0 is an event trigger

#$Trigger.Id = '21,23,24,25'
$Trigger.Subscription = "<QueryList><Query Id='0'><Select Path='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'>*[System[(Level=1  or Level=2 or Level=3 or Level=4 or Level=0 or Level=5) and (EventID=21 or EventID=23 or EventID=24 or EventID=25)]]</Select></Query></QueryList>"

$Trigger.Enabled = $true
$Action = $TaskDefinition.Actions.Create(0)
$Path = 'PowerShell.exe'
$Arguments = "-windowstyle hidden -ExecutionPolicy bypass -Command C:\RDP-Logs_Send-Email.ps1"
$Action.Path = $Path
$action.Arguments = $Arguments

$rootFolder.RegisterTaskDefinition('Login',$TaskDefinition,6,$taskRunAsuser,$taskRunasUserPwd,1)

$setting = New-ScheduledTaskSettingsSet -DisallowDemandStart -StartWhenAvailable -AllowStartIfOnBatteries -DontStopOnIdleEnd -Compatibility Win8
Set-ScheduledTask -TaskName Login -Settings $setting -User domain\user
