# Manual WSL installation steps for LIQUIDMETALS app
* Installation is case dependent. Open Windows Command Prompt or PowerShell and run ``wsl --status`` to check which one.

## 1) Install WSL on Windows
* Windows recognizes ``wsl`` command in Windows Command Prompt and PowerShell but initially does not conatain full installation.
* NOTE: Older Windows 10 versions doesn't recognize ``wsl`` command. This might be the case also for latsest update of Windows 10 if ``wsl`` has been installed during one of earlier versions and disabled. WSL can be enabled manually with ``powershell dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart``
* System needs to be restarted afterwards.
* If ``wsl --status`` returns nothing, then WSL has not been used on the current system before and system will need to restart during install.
** 1.1) Open Windows Command Prompt or PowerShell in administrator mode and run ``wsl --install``
** 1.2) Restart your system
** Make sure you have have latest WSL version
** ``wsl --update``
** ``wsl --set-default-version 2``

## 2) Install Ubuntu-22.04 on WSL##
* 2a) If ``wsl --status`` returns distribution names and Ubuntu-22.04 is one of them, then previous installation must be removed and new installed in place. 
** (optional) If the previous installation contains important files, it can be exported without losing them. To export run ``wsl --export Ubuntu-22.04 %USERPROFILE%\Ubuntu-22.04-backup.vhdx --vhd``, where optionally you can choose other preferable directory instead of ``%USERPROFILE%``.
** Remove previous Ubuntu-22.04 installation from WSL: ``wsl --unregister Ubuntu-22.04``
** If you are reinstalling cenos liquidmetals, then also remove previous installation from WSL: ``wsl --unregister cenos-liquidmetals``
* 2b) If ``wsl --status`` returns at least version number, then WSL has been installed on your system. If it also returns distribution names but Ubuntu-22.04 is not one of them, then you can perform clean Ubuntu-22.04 installation.
** Install "Ubuntu-22.04" distribution: ``wsl --install -d Ubuntu-22.04 --no-launch``
** Install root user ``powershell Ubuntu-22.04 install --root``
** Create new user "cenos" and give root privileges: ``wsl -d Ubuntu-22.04 -u root adduser --gecos 'cenos' --disabled-password cenos``
** Disable password requirement for the new user ``echo 'cenos ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers``

## 3) Install all solver software on WSL##
* Open Ubuntu-22.04 from terminal ``wsl -d Ubuntu-22.04 -u cenos``
* Run the following lines from the opened linux terminal.
* First install all required packages.
```
sudo apt-get update
sudo apt-get install build-essential cmake git gmsh gfortran libblas-dev liblapack-dev -y
sudo apt-get install python3-pip python3 python3-numpy -y
pip install elmer-circuitbuilder
sudo apt-get update
```
* Install OpenFOAM.
```
sudo sh -c "wget -O - http://dl.openfoam.org/gpg.key | apt-key add -"
sudo add-apt-repository http://dl.openfoam.org/ubuntu -y
sudo apt-get update
sudo apt-get install openfoam10 -y
```
* Install Elmer with max threads of your system (example on last line with 16)
```
cd $HOME
mkdir elmer
cd elmer
git clone https://github.com/ElmerCSC/elmerfem
mkdir build
cd build
cmake -Wno-dev -DWITH_MPI=TRUE -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../install ../elmerfem
make -j 16 install
```
* Install EOF-Library.
```
cd $HOME
git clone https://github.com/jvencels/EOF-Library
. EOF-Library/etc/bashrc
source /opt/openfoam10/etc/bashrc
export ELMER_HOME=$HOME/elmer/install/
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ELMER_HOME/lib
export PATH=$PATH:$ELMER_HOME/bin
export EOF_HOME=$HOME/EOF-Library
eofCompile
```
* Install MHDsolvers.
```
git clone https://github.com/CENOS-Platform/MHDsolvers
chmod +x MHDsolvers/Allwmake
./MHDsolvers/Allwmake
```
* Change OpenFOAM debug switches for more reasonable amount of solver output.
```
mkdir -p $HOME/.OpenFOAM/$WM_PROJECT_VERSION
cp $WM_PROJECT_DIR/etc/controlDict $HOME/.OpenFOAM/$WM_PROJECT_VERSION/
sed -i "s/GAMGAgglomeration [^;]*/GAMGAgglomeration 0/" $HOME/.OpenFOAM/$WM_PROJECT_VERSION/controlDict
sed -i "s/lduMatrix [^;]*/lduMatrix 0/" $HOME/.OpenFOAM/$WM_PROJECT_VERSION/controlDict
sed -i "s/SolverPerformance [^;]*/SolverPerformance 0/" $HOME/.OpenFOAM/$WM_PROJECT_VERSION/controlDict
```
* Update environment variables.
sudo printf 'source /opt/openfoam10/etc/bashrc''%%s\n' >> /home/cenos/.bashrc
sudo printf 'export ELMER_HOME=/home/%newUserName%/elmer/install/''%%s\n' >> /home/cenos/.bashrc
sudo printf 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ELMER_HOME/lib''%%s\n' >> /home/cenos/.bashrc
sudo printf 'export PATH=$PATH:$ELMER_HOME/bin''%%s\n' >> /home/cenos/.bashrc
sudo printf 'export EOF_HOME=/home/%newUserName%/EOF-Library''%%s\n' >> /home/cenos/.bashrc
sudo printf 'source $EOF_HOME/etc/bashrc''%%s\n' >> /home/cenos/.bashrc

## 4) Configure the prepared installation##
* Export the prepared Ubuntu-22.04 installation as a virtual drive that can be used on other systems.
** Make sure WSL is not running(might need to wait up to 8 seconds after the command): ``wsl --shutdown``
** Export the prepared virtual drive ``wsl --export Ubuntu-22.04 %USERPROFILE%\cenos-liquidmetals.vhdx --vhd``
** Import the prepared virtual drive as a new distribution "cenos-liquidmetals" ``wsl --import-in-place cenos-liquidmetals %USERPROFILE%\cenos-liquidmetals.vhdx``
** Remove the previous distribution``wsl --unregister Ubuntu-22.04``

## 5) (optional) Import the backed-up WSL virtual drive##
* If a previous version of Ubuntu-22.04 distro was backed up in the beginning of the installation, it can now be imported back.
** ``wsl --import Ubuntu-22.04 %USERPROFILE%\Ubuntu-22.04 %USERPROFILE%\Ubuntu-22.04-backup.vhdx --vhd``

