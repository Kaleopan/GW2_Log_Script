@ECHO OFF
SETLOCAL EnableDelayedExpansion

:: vvvv Update this path to the correct paths on your machine vvvv

SET arcdps_logs_folder=asd


:: ^^^^ Update this path to the correct paths on your machine ^^^^

:: INFO
:: arcdps_logs_folder format should end without slashes: \arcdps\arcdps.cbtlogs\EVTC
:: A separate folder from default ArcDPS save location is recommended to parse specific logs
:: INFO END


















:: vvvv Don't touch these vvvv
::Strings
SET tool_path=%~dp0GW2_Log_Script
SET arcdps_logs_folder_savefile=%tool_path%\Path.txt

IF EXIST "%arcdps_logs_folder_savefile%" (
SET /P arcdps_logs_folder=<"%arcdps_logs_folder_savefile%"
)

IF "%arcdps_logs_folder%" == "asd" (
ECHO.
ECHO MISSING PATH arcdps_logs_folder=
ECHO.
ECHO Insert logs path at line 6 of this script
ECHO.
GOTO EOF
)

IF "%arcdps_logs_folder%" == "" GOTO NO_PATH
(ECHO %arcdps_logs_folder%) > "%arcdps_logs_folder_savefile%"
:NO_PATH

SET arcdps_logs_path_all=
SET arcdps_logs_archive=%arcdps_logs_folder%\DONE
SET elite_insights_parser_output_folder=%tool_path%\PARSED

SET GW2_log_script_api=https://github.com/Kaleopan/GW2_Log_Script/releases/download/Release/GW2_Log_Script.bat
SET GW2_log_script_name=GW2_Log_Script

SET elite_insights_parser_name=GW2EICLI
SET elite_insights_parser_path=%tool_path%\%elite_insights_parser_name%\GuildWars2EliteInsights-CLI.exe
SET elite_insights_parser_api=https://api.github.com/repos/baaron4/GW2-Elite-Insights-Parser/releases/latest
SET elite_insights_parser_config_path=%tool_path%\EI-CLI.conf

FOR /F "delims=" %%A IN ('powershell get-date -format "{yyyy_MM_dd}"') DO @set _dtm=%%A
FOR /F "delims=" %%A IN ('powershell ^(Get-Date^).ToString^('ddd'^, [CultureInfo]'de-DE'^)') DO @set weekday=%%A
SET html_name=%_dtm%_%weekday%.html

SET EI_log_combiner_name=GW2EILC
SET EI_log_combiner_folder=%tool_path%\%EI_log_combiner_name%
SET EI_log_combiner_folder_api=https://api.github.com/repos/Drevarr/GW2_EI_log_combiner/releases/latest
SET EI_log_combiner_config_path=%tool_path%\EI_log_combiner.ini
SET EI_log_combiner_template=%EI_log_combiner_folder%\example_output\Top_Stats_Index.html

SET EI_log_combiner_template_destination_temp=%tool_path%\%html_name%
SET EI_log_combiner_template_destination=%~dp0%html_name%

SET saved_html_file_path=C:\Users\%USERNAME%\Downloads\%html_name%

SET timestamp_path=%tool_path%\Timestamp.txt
SET timestamp=

::Numbers
SET count_logs=0
SET count_logs_current=0
SET count_parsed=0
SET count_progress=0
SET count_retry=0

ECHO.
ECHO 1. When you run this script for the first time,
ECHO update this path (line 6) in this file to the correct path for your system
ECHO arcdps_logs_folder=
ECHO %arcdps_logs_folder%
ECHO.
ECHO Then close and rerun this file
ECHO.
ECHO If you wish to change the logs path in the future, delete or edit:
ECHO %arcdps_logs_folder_savefile%
ECHO.
ECHO.
ECHO --Make sure you--
ECHO.
ECHO 2. Have installed: python 3.13 or higher
ECHO Browser: https://www.python.org/downloads/
ECHO.
ECHO 3. Have installed: python packages
ECHO Console/cmd: py -m pip install xlrd xlutils xlwt jsons requests xlsxwriter glicko2
ECHO.
ECHO 4. Your ArcDPS logs are at:
ECHO %arcdps_logs_folder%
ECHO.

PAUSE
CLS

::Create folders
MKDIR "%arcdps_logs_archive%"
MKDIR "%elite_insights_parser_output_folder%"
CLS

IF EXIST "%timestamp_path%" (
set /p timestamp=<"%timestamp_path%"
) ELSE ( 
GOTO YES_UPDATE
)

SET timestamp=%timestamp: =%

::Force updates if parser not found
IF NOT EXIST "%elite_insights_parser_path%" (
GOTO YES_UPDATE
)

IF NOT EXIST "%tool_path%\%EI_log_combiner_name%" (
GOTO YES_UPDATE
)

IF "%_dtm%" == "%timestamp%" GOTO NO_UPDATE

:YES_UPDATE
::UPDATE GW2_Log_Script

ECHO.
ECHO Updating:
ECHO.

ECHO.
echo Downloading... %GW2_log_script_api%
ECHO.

curl -kOL "%GW2_log_script_api%"

::Update elite_insights_parser
:update_elite_insights_parser
RD /S /Q "%tool_path%\%elite_insights_parser_name%"

GOTO HOTFIX

FOR /f "tokens=1,* delims=:" %%A IN ('curl -ks %elite_insights_parser_api% ^| findstr /C:"/%elite_insights_parser_name%.zip"') DO (
SET download_filename=%%B
GOTO LOOPEND2
)
:LOOPEND2
set download_filename=%download_filename: =%
set download_filename=%download_filename:"=%
set download_filename=%download_filename:.sig=%

IF %count_retry% GTR 3 (
GOTO GITHUB
)

IF "x%download_filename:.zip=%"=="x%download_filename%" (
SET /A count_retry=count_retry+1
ECHO Update failed. Github API did not return a valid response. Retry.
PING 127.0.0.1 -n 10 > NUL
GOTO update_elite_insights_parser
)

SET count_retry=0

:HOTFIX
SET download_filename=https://github.com/Kaleopan/GW2_Log_Script/releases/download/Hotfix/GW2EICLI.zip

ECHO.
echo Downloading... %download_filename%
ECHO.

curl -kOL "%download_filename%"

powershell Expand-Archive -Force '%~dp0%elite_insights_parser_name%.zip' -DestinationPath '%tool_path%\%elite_insights_parser_name%'

DEL "%~dp0%elite_insights_parser_name%.zip"

::Update EI_log_combiner
:update_EI_log_combiner
RD /S /Q "%tool_path%\%EI_log_combiner_name%"

FOR /f "tokens=1,* delims=:" %%A IN ('curl -ks %EI_log_combiner_folder_api% ^| findstr "tag_name"') DO (
SET tagname=%%B
)
SET tagname=%tagname: =%
SET tagname=%tagname:"=%
SET tagname=%tagname:,=%

IF %count_retry% GTR 3 (
GOTO GITHUB
)

IF "x%tagname:.=%"=="x%tagname%" (
SET /A count_retry=count_retry+1
ECHO Update failed. Github API did not return a valid response. Retry.
PING 127.0.0.1 -n 10 > NUL
GOTO update_EI_log_combiner
)

ECHO.
echo Downloading... %download_filename%
ECHO.

curl -kOL "https://github.com/Drevarr/GW2_EI_log_combiner/archive/refs/tags/%tagname%.zip"

powershell Expand-Archive -Force '%~dp0%tagname%.zip' -DestinationPath '%~dp0%tagname%'

FOR /F %%G IN ('dir /b "%~dp0%tagname%"') DO SET GW2EILC_folder=%~dp0%tagname%\%%G

MOVE /Y "%GW2EILC_folder%" "%tool_path%\%EI_log_combiner_name%"

DEL "%~dp0%tagname%.zip"
RD /S /Q "%~dp0%tagname%"
CLS

(ECHO %_dtm%) > "%timestamp_path%"

start "" %GW2_log_script_name%.bat
EXIT

:NO_UPDATE

IF NOT EXIST "%elite_insights_parser_path%" (
ECHO.
ECHO ERROR: 
ECHO %elite_insights_parser_path% 
ECHO not found.
ECHO.
GOTO GITHUB
)

IF NOT EXIST "%tool_path%\%EI_log_combiner_name%" (
ECHO.
ECHO ERROR: 
ECHO %tool_path%\%EI_log_combiner_name% 
ECHO not found.
ECHO.
GOTO GITHUB
)

:: Generate EI Parser Config File
(
ECHO HtmlCompressJson=False
ECHO AutoParse=False
ECHO SaveOutCSV=False
ECHO UploadToRaidar=False
ECHO LightTheme=False
ECHO Outdated=False
ECHO IndentJSON=True
ECHO HtmlExternalScriptsPath=
ECHO SaveOutTrace=False
ECHO PopulateHourLimit=0
ECHO CustomTooShort=15000
ECHO SaveAtOut=False
ECHO SendSimpleMessageToWebhook=False
ECHO ParseCombatReplay=True
ECHO ApplicationTraces=False
ECHO UploadToWingman=False
ECHO IndentXML=True
ECHO ComputeDamageModifiers=True
ECHO MemoryLimit=0
ECHO DPSReportUserToken=
ECHO HtmlExternalScriptsCdn=
ECHO CompressRaw=False
ECHO SaveOutHTML=False
ECHO AutoDiscordBatch=False
ECHO AutoAdd=False
ECHO AddPoVProf=False
ECHO AutoAddPath=
ECHO RawTimelineArrays=True
ECHO UploadToDPSReports=True
ECHO DetailledWvW=True
ECHO WebhookURL=
ECHO ParsePhases=True
ECHO HtmlExternalScripts=False
ECHO SendEmbedToWebhook=False
ECHO SaveOutJSON=True
ECHO SingleThreaded=False
ECHO OutLocation=%elite_insights_parser_output_folder%
ECHO ParseMultipleLogs=True
ECHO SaveOutXML=False
ECHO SkipFailedTries=False
ECHO Anonymous=False
ECHO AddDuration=False
) > "%elite_insights_parser_config_path%"

:: Generate EI Log Combiner Config File
(
ECHO [TopStatsCfg]
ECHO guild_name =
ECHO guild_id =
ECHO api_key = None
ECHO input_directory =
ECHO output_filename = None
ECHO json_output_filename = None
ECHO db_output_filename = TopStats.db
ECHO db_path = .
ECHO write_all_data_to_json = false
ECHO db_update = false
ECHO fight_data_charts = true
ECHO write_excel = false
ECHO excel_output_filename = Top_Stats.xlsx
ECHO excel_path = .
ECHO skill_casts_by_role_limit = 100
ECHO hide_columns = false
ECHO Boons_Detailed = true
ECHO Offensive_Detailed = true
ECHO Defenses_Detailed = true
ECHO Support_Detailed = true
ECHO Sort_Mode = Total
ECHO [Boon_Weights]
ECHO Aegis = 1
ECHO Alacrity = 1
ECHO Fury = 1
ECHO Might = 1
ECHO Protection = 1
ECHO Quickness = 1
ECHO Regeneration = 1
ECHO Resistance = 1
ECHO Resolution = 1
ECHO Stability = 1
ECHO Swiftness = 1
ECHO Vigor = 1
ECHO Superspeed = 1
ECHO [Condition_Weights]
ECHO Bleed = 1
ECHO Burning = 1
ECHO Confusion = 1
ECHO Poisoned = 1
ECHO Torment = 1
ECHO Blinded = 1
ECHO Chilled = 1
ECHO Crippled = 1
ECHO Fear = 1
ECHO Immobilized = 1
ECHO Slow = 1
ECHO Taunt = 1
ECHO Weakness = 1
ECHO Vulnerability = 1
ECHO [skill_casts_by_role_limit]
) > "%EI_log_combiner_config_path%"

:: Count .zevtc files
FOR %%i IN ("%arcdps_logs_folder%\*.zevtc") DO (
SET /A count_logs=count_logs+1
)

::End if no logs
IF %count_logs% GTR 0 GOTO YES_FILES
:NO_FILES
CLS
ECHO.
ECHO ERROR: 
ECHO No log files in
ECHO %arcdps_logs_folder%
ECHO.
GOTO EOF

:YES_FILES

:: Parse .zevtc files in blocks of 12
DEL /Q "%elite_insights_parser_output_folder%\*.*"

ECHO 1: Elite Insights Parser
ECHO.
ECHO Logs: %count_logs%
ECHO Processing... 0%%

FOR %%i in ("%arcdps_logs_folder%\*.zevtc") DO (
SET arcdps_logs_path_all=!arcdps_logs_path_all! "%%i"
SET /A count_logs_current=count_logs_current+1
SET /A count_parsed=count_parsed+1

IF !count_parsed! GEQ 12 (
"%elite_insights_parser_path%" -c "%elite_insights_parser_config_path%" !arcdps_logs_path_all! > NUL
SET arcdps_logs_path_all=
SET /A count_parsed=0
SET /A count_progress=!count_logs_current!*100/%count_logs%
CLS
ECHO 1: Elite Insights Parser
ECHO.
ECHO Logs: %count_logs%
ECHO Processing... !count_progress!%%
IF %count_logs% GEQ 25 (
IF !count_progress! LSS 100 (
PING 127.0.0.1 -n 30 > NUL
)
)
)
)

"%elite_insights_parser_path%" -c "%elite_insights_parser_config_path%" %arcdps_logs_path_all% > NUL
SET /a count_parsed=0

CLS
ECHO 1: Elite Insights Parser
ECHO.
ECHO Logs: %count_logs%
ECHO Processing... 100%%
ECHO.

::Move Processed .zevtc files
FOR %%i in ("%arcdps_logs_folder%\*.zevtc") DO (
MOVE "%%i" "%arcdps_logs_archive%" > NUL
)

ECHO.
ECHO Moved logs to %arcdps_logs_archive%
ECHO.

:top_stats
:: Process .json files
FOR %%i in ("%elite_insights_parser_output_folder%\*.json") DO (
SET /A count_parsed=count_parsed+1
)

IF %count_parsed% EQU 0 GOTO eof

ECHO 2: ArcDPS Top Stats Parser
CD "%EI_log_combiner_folder%" 

py tw5_top_stats.py -c "%EI_log_combiner_config_path%" -i "%elite_insights_parser_output_folder%" > NUL

COPY /Y "%EI_log_combiner_template%" "%EI_log_combiner_template_destination_temp%" > NUL

:: Delete garbage
FOR %%i in ("%elite_insights_parser_output_folder%\*.txt") DO (
DEL /F "%%i" > NUL
)
FOR %%i in ("%elite_insights_parser_output_folder%\*kill.json") DO (
DEL /F "%%i" > NUL
)
FOR %%i in ("%elite_insights_parser_output_folder%\*.xls") DO (
DEL /F "%%i" > NUL
)


::Open .tid folder and HTML Wiki
START "" "%EI_log_combiner_template_destination_temp%"
START "" "%elite_insights_parser_output_folder%"
CLS

ECHO.
ECHO Import (Drag and Drop) the Drag_and_Drop_Log_Summary_for_.json file into the Tiddler Wiki 5 page (%html_name%) in your browser.
ECHO Press the red save button at the top right.
ECHO Then press a button in this window.
ECHO.
ECHO The script will attempt to copy the saved HTML file from
ECHO %saved_html_file_path%
ECHO to
ECHO %EI_log_combiner_template_destination%
ECHO.
ECHO Works for most default browser settings
ECHO If you have manually saved the .html file to a different location, you will need to get it from there manually.
ECHO.

PAUSE

:: Delete garbage
FOR %%i in ("%tool_path%\*.html") DO (
DEL /F "%%i" > NUL
)

::Copy saved HTML back to script location for convenience
COPY /y "%saved_html_file_path%" "%EI_log_combiner_template_destination%" > NUL
PING 127.0.0.1 -n 2 > NUL
DEL /F "%EI_log_combiner_template_destination_temp%" > NUL
IF EXIST "%saved_html_file_path%" (
DEL /F "%saved_html_file_path%" > NUL
)


CLS
ECHO.
ECHO DONE
ECHO.
GOTO EOF

:GITHUB
ECHO.
ECHO Update failed. Github API did not return a valid response. Please try again later.
ECHO.

:EOF
PAUSE
EXIT