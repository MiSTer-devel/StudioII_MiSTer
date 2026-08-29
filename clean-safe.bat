@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem Always run relative to this script's directory.
pushd "%~dp0" || exit /b 1

if not exist "rbf_archive" mkdir "rbf_archive"
if errorlevel 1 goto :archive_failed

rem Use an invariant, 24-hour timestamp: YYYYMMDD-HHmmss.
for /f %%T in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "RBF_TIMESTAMP=%%T"
if not defined RBF_TIMESTAMP goto :archive_failed

echo Archiving generated RBF files with timestamp %RBF_TIMESTAMP%...

if exist "output_files" (
    for /r "output_files" %%F in (*.rbf) do (
        call :archive_rbf "%%~fF"
        if errorlevel 1 goto :archive_failed
    )
)

rem Quartus DSE output directories can appear at different levels and with
rem different names, so include every directory whose name contains "dse".
for /d /r %%D in (*dse*) do (
    for /r "%%~fD" %%F in (*.rbf) do (
        call :archive_rbf "%%~fF"
        if errorlevel 1 goto :archive_failed
    )
)

echo RBF archive complete. Starting normal cleanup...
call "%~dp0clean.bat"
set "CLEAN_RESULT=%ERRORLEVEL%"
popd
exit /b %CLEAN_RESULT%

:archive_rbf
set "RBF_SOURCE=%~1"
set "RBF_TARGET=rbf_archive\%~n1_%RBF_TIMESTAMP%%~x1"
set /a RBF_COPY_NUMBER=1

:find_available_name
if not exist "%RBF_TARGET%" goto :copy_rbf
set /a RBF_COPY_NUMBER+=1
set "RBF_TARGET=rbf_archive\%~n1_%RBF_TIMESTAMP%-%RBF_COPY_NUMBER%%~x1"
goto :find_available_name

:copy_rbf
echo   "%RBF_SOURCE%" ^> "%RBF_TARGET%"
copy /y "%RBF_SOURCE%" "%RBF_TARGET%" >nul
exit /b %ERRORLEVEL%

:archive_failed
echo ERROR: RBF archival failed. Cleanup was not started.
popd
exit /b 1
