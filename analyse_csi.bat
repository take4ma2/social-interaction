@echo off

echo %1

cd /d %~dp0

echo %CD%

if exist %1 goto EXECUTE else goto USAGE

:EXECUTE
ruby social_interaction.rb %1

goto EXIT

:USAGE
echo "Drag and Drop CSI result data on this batch file"

:EXIT
pause
