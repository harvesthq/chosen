@echo off
set version=0.9.5-alpha1-880a30d
NuGet pack chosen.nuspec -Properties version=%version%
NuGet pack chosen.jquery.nuspec -Properties version=%version%
@pause
