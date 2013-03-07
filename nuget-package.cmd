@echo off
set version=0.9.12
NuGet pack chosen.nuspec -Properties version=%version%
NuGet pack chosen.jquery.nuspec -Properties version=%version%
@pause
