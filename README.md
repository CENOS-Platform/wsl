# WSL installation for LIQUIDMETALS app
* To install, just run install_liquidmetals_app.bat
* Installation process is briefly described below

## 1) Install WSL with Ubuntu-22.04##
* Install "Ubuntu-22.04" distro version and make new username "cenos"
* Installation is case dependent. Open cmd and run ``wsl --status`` to check which one.
** If ``wsl --status`` returns nothing, then WSL has not been used on the current system before and system will need to restart during install.
** If ``wsl --status`` returns at least version number, then WSL has been used on the current system.
** If ``wsl --status`` returns distribution names and Ubuntu-22.04 is one of them, then previous installation must be removed and new installed in place. 

## 2) Install all solver software on WSL##
* Install all required software inside the WSL.
* This step could be improved by checking that no errors (e.g. internet connection issues) were during package (OpenFOAM, Elmer, etc.) installation before proceeding to next one.

## 3) Export the prepared installation##
* Export the prepared Ubuntu-22.04 installation as a virtual drive that can be used on other systems.
** Optional: Compress virtual drive for exporting to other system. (Virtual drive size is approx. 5GB, whereas the 7zip archived version is only 1.5GB.)

## 4) Import the prepared WSL virtual drive##
* Import the prepared virtual drive as a new WSL distribution and name it "cenos-liquidmetals".
* If a previous version of Ubuntu-22.04 distro was backed up in the beginning of the installation, it will now be installed back.

