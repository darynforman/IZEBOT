@echo off
echo Building iZEBOT Compiler (Vala modular)...
echo.
valac --version
echo.
valac --pkg glib-2.0 -o izebot.exe ^
  vala\token_types.vala ^
  vala\parse_tree.vala ^
  vala\lexer.vala ^
  vala\parser.vala ^
  vala\semantic_analyzer.vala ^
  vala\code_generator.vala ^
  vala\tree_visualizer.vala ^
  vala\grammar_display.vala ^
  vala\compiler.vala ^
  vala\main.vala

if %ERRORLEVEL% EQU 0 (
  echo.
  echo [OK] Build successful! Output: izebot.exe
  echo Run with: izebot.exe
) else (
  echo.
  echo [X] Build failed. Ensure MSYS2/MinGW toolchain and Vala are installed.
)

pause
