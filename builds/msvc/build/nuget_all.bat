@ECHO OFF
ECHO Downloading libbitcoin vs2017 dependencies from NuGet
CALL nuget.exe install ..\vs2017\libbitcoin-system\packages.config
CALL nuget.exe install ..\vs2017\libbitcoin-system-examples\packages.config
CALL nuget.exe install ..\vs2017\libbitcoin-system-test\packages.config
REM ECHO.
REM ECHO Downloading libbitcoin vs2015 dependencies from NuGet
REM CALL nuget.exe install ..\vs2015\libbitcoin-system\packages.config
REM CALL nuget.exe install ..\vs2015\libbitcoin-system-examples\packages.config
REM CALL nuget.exe install ..\vs2015\libbitcoin-system-test\packages.config
REM ECHO.
REM ECHO Downloading libbitcoin vs2013 dependencies from NuGet
REM CALL nuget.exe install ..\vs2013\libbitcoin-system\packages.config
REM CALL nuget.exe install ..\vs2013\libbitcoin-system-examples\packages.config
REM CALL nuget.exe install ..\vs2013\libbitcoin-system-test\packages.config
