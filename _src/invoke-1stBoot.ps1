Start-Transcript -path C:\bb\setup_transcript.txt -IncludeInvocationHeader -Append
"Invoke-1stBoot.ps1: Start"

    # remove page file at all for compacting .VHDX in Hyper-V
    Set-CimInstance -Query "SELECT * FROM Win32_ComputerSystem" -Property @{AutomaticManagedPagefile="False"}
    (Get-WmiObject -Class Win32_PageFileSetting).Delete()

    Set-WinSystemLocale uk-UA
    Set-Culture uk-UA
    $culture = Get-Culture
    $culture.DateTimeFormat.DateSeparator = '-'
    $culture.DateTimeFormat.LongDatePattern = 'dddd, d MMMM yyyy'
    $culture.DateTimeFormat.LongTimePattern = 'HH:mm:ss'
    $culture.DateTimeFormat.ShortDatePattern = 'yyyy-MM-dd'
    $culture.DateTimeFormat.ShortTimePattern = 'H:mm'
    $culture.NumberFormat.CurrencyDecimalSeparator = '.'
    $culture.NumberFormat.CurrencyGroupSeparator = ' '
    $culture.NumberFormat.CurrencyNegativePattern = 1
    $culture.NumberFormat.CurrencyPositivePattern = 0
    $culture.NumberFormat.CurrencySymbol = '₴'
    $culture.NumberFormat.NumberDecimalSeparator = '.'
    $culture.NumberFormat.NumberGroupSeparator = ' '
    $culture.NumberFormat.NumberNegativePattern = 1
    $culture.NumberFormat.PercentDecimalSeparator = '.'
    $culture.NumberFormat.PercentGroupSeparator = ' '
    Set-Culture $culture


    Copy-Item c:\bb\assets\hexagram-1.bmp c:\Windows\OEMlogo.bmp -force
    $RegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
    Set-ItemProperty -path $RegKey -name  Logo         -value "c:\Windows\OEMlogo.bmp"
    Set-ItemProperty -path $RegKey -name  Manufacturer -value "ƋБ ★ Berkovets Brotherhood"
    Set-ItemProperty -path $RegKey -name  Model        -value "BIG⛧BRO"     # ☸♈✡☩★⛧ 
    Set-ItemProperty -path $RegKey -name  SupportHours -value "00:00 - 24:00, lunch time 13:00 - 14:30 UTC"
    Set-ItemProperty -path $RegKey -name  SupportPhone -value "+380 (66) 6667666"
    Set-ItemProperty -path $RegKey -name  SupportUrl   -value "https://www.facebook.com/Берковецкое-братство-175435306115/"

    $inputLanguages = New-WinUserLanguageList 'en-US'
    $inputLanguages[0].InputMethodTips.Clear()
    $inputLanguages[0].InputMethodTips.Add('0409:00020409')
    $inputLanguages.Add('ua-UK')
    Set-WinUserLanguageList $inputLanguages -force
    $inputLanguages = Get-WinUserLanguageList
#    $inputLanguages[1].InputMethodTips.Clear()
    if ('0422:00020422' -notIn $inputLanguages[1].InputMethodTips) {
        $inputLanguages[1].InputMethodTips.Add('0422:00020422')
    }
    if ('0422:00000419' -notIn $inputLanguages[1].InputMethodTips) {
        $inputLanguages[1].InputMethodTips.Add('0422:00000419')
    }
    Set-WinUserLanguageList $inputLanguages -force

    $RegKey = "HKCU:\Keyboard Layout\Toggle"
    Set-ItemProperty -path $RegKey -name HotKey -value 2
    Set-ItemProperty -path $RegKey -name "Language HotKey" -value 2
    Set-ItemProperty -path $RegKey -name "Layout HotKey" -value 3

    Set-WinLanguageBarOption -useLegacySwitchMode:$False -useLegacyLanguageBar:$False

    Set-WinHomeLocation -geoId 244             # https://msdn.microsoft.com/en-us/library/dd374073.aspx


"Invoke-1stBoot.ps1: Finish"
Stop-Transcript