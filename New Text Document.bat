@echo off

call _internal\venv\Scripts\activate.bat

python _internal\run.py --execution-provider cuda
