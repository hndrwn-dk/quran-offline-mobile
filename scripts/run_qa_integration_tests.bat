@echo off
REM Run emulator/device QA regression tests.
cd /d "%~dp0.."
call flutter pub get
if "%~1"=="" (
  flutter devices
  flutter test integration_test/qa_regression_test.dart
) else (
  flutter test integration_test/qa_regression_test.dart -d %~1
)
