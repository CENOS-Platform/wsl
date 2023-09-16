@REM ------------------------------------------------------------
@REM ----------WSL LIQUIDMETALS APP INSTALLATION-----------------
@REM ------------------------------------------------------------
@ECHO OFF
REM Define main paths and variables
SET newDistroName=cenos-liquidmetals
SET newUserName=cenos
SET batDir=%~dp0
SET distro_year=22
SET distroVersion=Ubuntu-%distro_year%.04
SET distroAppVersion=Ubuntu%distro_year%04
@REM Probably better to use %TEMP% in the final version
SET logPath=%USERPROFILE%
@REM Probably better to use %TEMP% in the final version
SET archivePath=%USERPROFILE%
@REM Probably not the best place.. 
@REM Could find the previous folder and put back in the same place:
@REM %USERPROFILE%\AppData\Local\Packages\CanonicalGroupLimited.%distroVersion%<some more non-trivial text here>\LocalState\ext4.vhdx
SET backupInstallPath=%USERPROFILE%\%distroVersion%
@REM ------------------------------------------------------------
ECHO Installing CENOS Liquidmetals App in Windows Subsystem for Linux.
REM Terminate all running WSL processes that could interrupt the install process
WSL --shutdown
@REM WSL shutdown can take few seconds. Better to wait a little bit, otherwise export command will fail.
TIMEOUT 8 > NUL /nobreak
@REM Sometimes it can return as a background process for some reason. Better call shutdown one more time.
WSL --shutdown
TIMEOUT 8 > NUL /nobreak
REM Check if returning to file after restart
IF EXIST %logPath%\liqm-return.txt (
REG DELETE HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v "%~n0" /f
DEL %logPath%\liqm-return.txt
)
REM Check WSL status and continue depending on case
@REM This could be improved by saving WSL --status output in local variable
WSL --status > %logPath%\WSL-status.log
FIND "Version" %logPath%\WSL-status.log
if %errorlevel%==0 (
REM WSL has been previously configured 
REM Let's check what distributions are installed
WSL --list --all > %logPath%\WSL-distribution-list.log
) else (
@REM This case represents situation when WSL has not been previously used on system
REM Looks like this is the first time WSL distro is installed on system.
REM The WSL app will first install all of it's features and then system will reboot.
@REM For older windows versions or if wsl has been installed before one of latest major Windows updates, add this line(might need to restart afterwards):
@REM powershell dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
WSL --install
REM Adding return registry
REG ADD HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v "%~n0" /d "%~dpnx0" /f
ECHO > %logPath%\liqm-return.txt
@REM restart system
ECHO Save all of your work and press enter to restart.
PAUSE
SHUTDOWN /r /t 0
)
FIND "%distroVersion%" %logPath%\WSL-distribution-list.log
if %errorlevel%==0 (
REM Clean distro version will be installed so the previous distro must be deleted first
@REM Possible option here is to create backup for the previous version and install it back after CENOS installation.
WSL --export %distroVersion% %archivePath%\%distroVersion%-backup.vhdx --vhd
WSL --unregister %distroVersion%
)
@REM Remove previous cenos WSL installation
FIND "%newDistroName%" %logPath%\WSL-distribution-list.log
if %errorlevel%==0 (
@REM Previous cenos distro will be deleted before installing new one
WSL --unregister %newDistroName%
)
@REM ------------------------------------------------------------
REM Installing new distro
WSL --update
WSL --set-default-version 2
WSL --install -d %distroVersion% --no-launch
powershell %distroAppVersion% install --root
REM Create new user and give root privileges
WSL -d %distroVersion% -u root adduser --gecos '%newUserName%' --disabled-password %newUserName%;^
 echo 'cenos ALL=(ALL) NOPASSWD: ALL' ^>^> /etc/sudoers
@REM ------------------------------------------------------------
REM Setting up new WSL distro
REM Installing necessary packages
SET package_install_lines=^
sudo apt-get update;^
sudo apt-get install build-essential cmake git gmsh gfortran libblas-dev liblapack-dev -y;^
sudo apt-get install python3-pip python3 python3-numpy -y;^
pip install elmer-circuitbuilder;^
sudo apt-get update;
REM Install OpenFOAM
@REM Couldn't find any flags to skip paraview install.
@REM Paraview takes about 500mb and not needed here, so in principle could be deleted.
SET openfoam_install_lines=^
sudo sh -c "wget -O - http://dl.openfoam.org/gpg.key | apt-key add -";^
sudo add-apt-repository http://dl.openfoam.org/ubuntu -y;^
sudo apt-get update;^
sudo apt-get install openfoam10 -y;
@REM sudo rm -R /opt/paraviewopenfoam510;
REM Install ThirdParty installation
@REM SET thirdparty_install_lines=^
@REM sudo wget -O - http://dl.openfoam.org/third-party/10 | sudo tar xvz;^
@REM sudo mv ThirdParty-10-version-10 ThirdParty-10;^
@REM cd ThirdParty-10;^
@REM source /opt/openfoam10/etc/bashrc;^
@REM ./Allwmake;
REM Install elmer
SET elmer_install_lines=^
cd $HOME;^
mkdir elmer;^
cd elmer;^
git clone https://github.com/ElmerCSC/elmerfem;^
mkdir build;^
cd build;^
cmake -Wno-dev -DWITH_MPI=TRUE -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../install ../elmerfem;^
make -j %NUMBER_OF_PROCESSORS% install;
REM Install EOF-Library
SET eof_install_lines=^
cd $HOME;^
git clone https://github.com/jvencels/EOF-Library;^
. EOF-Library/etc/bashrc;^
source /opt/openfoam10/etc/bashrc;^
export ELMER_HOME=$HOME/elmer/install/;^
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ELMER_HOME/lib;^
export PATH=$PATH:$ELMER_HOME/bin;^
export EOF_HOME=$HOME/EOF-Library;^
eofCompile;
REM Clone MHD solvers to home directory and compile
SET mhdsolver_install_lines=^
git clone https://github.com/CENOS-Platform/MHDsolvers;^
chmod +x MHDsolvers/Allwmake;^
./MHDsolvers/Allwmake;
REM Minimize OpenFOAM output by setting debug switches to 0
SET debugswitches_install_lines=^
mkdir -p $HOME/.OpenFOAM/$WM_PROJECT_VERSION;^
cp $WM_PROJECT_DIR/etc/controlDict $HOME/.OpenFOAM/$WM_PROJECT_VERSION/;^
sed -i "s/GAMGAgglomeration [^;]*/GAMGAgglomeration 0/" $HOME/.OpenFOAM/$WM_PROJECT_VERSION/controlDict;^
sed -i "s/lduMatrix [^;]*/lduMatrix 0/" $HOME/.OpenFOAM/$WM_PROJECT_VERSION/controlDict;^
sed -i "s/SolverPerformance [^;]*/SolverPerformance 0/" $HOME/.OpenFOAM/$WM_PROJECT_VERSION/controlDict;
@REM ----the rest of debug switches
@REM sed -i "s/dimensionSet [^;]*/dimensionSet 0/" $HOME/.OpenFOAM/$WM_PROJECT_VERSION/controlDict
@REM sed -i "s/fileName [^;]*/fileName 0/" $HOME/.OpenFOAM/$WM_PROJECT_VERSION/controlDict
@REM sed -i "s/level [^;]*/level 0/" $HOME/.OpenFOAM/$WM_PROJECT_VERSION/controlDict
@REM sed -i "s/vtkUnstructuredReader [^;]*/vtkUnstructuredReader 0/" $HOME/.OpenFOAM/$WM_PROJECT_VERSION/controlDict
@REM ----
REM Add environment variables
@REM They are not read when passing arguments to 'WSL' command in cmd.
@REM However, can be useful to test or run calculations from WSL terminal.
SET environment_install_lines=sudo printf ^
'source /opt/openfoam10/etc/bashrc''%%s\n'^
'export ELMER_HOME=/home/%newUserName%/elmer/install/''%%s\n'^
'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ELMER_HOME/lib''%%s\n'^
'export PATH=$PATH:$ELMER_HOME/bin''%%s\n'^
'export EOF_HOME=/home/%newUserName%/EOF-Library''%%s\n'^
'source $EOF_HOME/etc/bashrc''%%s\n'^
 ^^^^^^^>^^^^^^^> /home/%newUserName%/.bashrc;
@REM ------------------------------------------------------------
@REM %thirdparty_install_lines% ^
@REM Execute all command lines as a regular user
SET user_command_lines=^
%package_install_lines% ^
%openfoam_install_lines% ^
%elmer_install_lines% ^
%eof_install_lines% ^
%mhdsolver_install_lines% ^
%debugswitches_install_lines% ^
%environment_install_lines%
WSL -d %distroVersion% -u %newUserName% %user_command_lines%
@REM ------------------------------------------------------------
REM WSL installation is finished
REM Shutting down all wsl distros
WSL --shutdown
@REM WSL shutdown can take few seconds. Better to wait a little bit, otherwise export command will fail.
TIMEOUT 8 > NUL /nobreak
@REM Sometimes it can return as a background process for some reason. Better call shutdown one more time.
WSL --shutdown
TIMEOUT 8 > NUL /nobreak
REM Creating new distro for cenos
@REM Export the prepared distribution as .vhdx file:
WSL --export %distroVersion% %archivePath%\%newDistroName%.vhdx --vhd
@REM Uncomment to compress for export
@REM SET pathToCenosDirectory=%batDir%\..\..\..
@REM SET pathTo7zip=%pathToCenosDirectory%\frontend\node_modules\7zip-bin\win\x64
@REM %pathTo7zip%\7za.exe a -mx9 -t7z cenos-liquidmetals.7z cenos-liquidmetals.vhdx
REM Importing previously prepared WSL distribution and installing with a new name
@REM Extract .vhdx file before import
@REM %pathTo7zip%\7za.exe e cenos-liquidmetals.7z
@REM First argument sets the name of the new distribution: cenos-liquidmetals
WSL --import-in-place %newDistroName% %archivePath%\%newDistroName%.vhdx
@REM check if WSL works with: WSL -d cenos-liquidmetals -u cenos
REM Cleanup. Deleting the distro that was used for installation
WSL --unregister %distroVersion%
@REM this is the part where previously saved version is imported back
IF EXIST %archivePath%\%distroVersion%-backup.vhdx (
REM Import back the previously saved distro version
WSL --import %distroVersion% %backupInstallPath% %archivePath%\%distroVersion%-backup.vhdx --vhd
REM Delete back-up file
DEL %archivePath%\%distroVersion%-backup.vhdx
)
@REM ------------------------------------------------------------
@REM -----WSL LIQUIDMETALS APP INSTALLATION COMPLETED------------
@REM ------------------------------------------------------------