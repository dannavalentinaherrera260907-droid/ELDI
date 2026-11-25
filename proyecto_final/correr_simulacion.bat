@echo off
REM Simulacion de EchoSpectrum con Icarus Verilog
REM Debe estar en la MISMA carpeta que Echospectrum.v y tb_Echospectrum.v
cd /d "%~dp0"
echo Borrando la simulacion anterior...
if exist sim.vvp del /q sim.vvp
if exist echospectrum.vcd del /q echospectrum.vcd
echo Compilando...
iverilog -g2012 -o sim.vvp Echospectrum.v tb_Echospectrum.v
if errorlevel 1 goto fin
echo Simulando...
vvp sim.vvp
echo.
echo Abriendo GTKWave...
gtkwave echospectrum.vcd
:fin
pause
