@echo off
rem Fake asset program for the asset-command provider tests (fake_asset.sh is the same for POSIX): copies the file named by
rem %FAKE_ASSET_SOURCE% to the path in its first argument, and records every argument, one per line, in %FAKE_ARGV_FILE%.
rem FAKE_MODE=fail exits with code 3 and a message; FAKE_MODE=nothing exits 0 without writing a file.
if defined FAKE_ARGV_FILE (
  for %%a in (%*) do >>"%FAKE_ARGV_FILE%" echo %%~a
)
if "%FAKE_MODE%"=="fail" (
  echo the model is not loaded 1>&2
  exit /b 3
)
if "%FAKE_MODE%"=="nothing" exit /b 0
copy /y "%FAKE_ASSET_SOURCE%" %1 >nul
