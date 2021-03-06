Scripts
=======

All scripts in this folder use ksh as interpreter which is not installed on most modern Linux distributions, but is default shell for some UNIXes.

Scripts have been tested on following Linux / UNIX distributions:
 1. Linux
  * CentOS 5
  * CentOS 6
 2. UNIX
  * AIX 7.1

Scripts should work for:
 1. Linux
  * RHEL 5
  * RHEL 6
 2. Unix
  * AIX 6.1

Scripts have been tested and used with Informix versions
 * 11.50xC8 or greater
 * 11.70xC4 or greater
 * 12.10xC1 or greater

===
#### AIX note: 
Scripts require some software installed from [IBM AIX Toolbox](http://www-03.ibm.com/systems/power/software/aix/linux/toolbox/download.html)

  * sed-4.1.1-1
  * grep-2.5.1-1
  * findutils-4.1-3

Adjust PATH variable so /opt/freeware/bin executables are before standard AIX executables

===
#### Linux note:
Most modern Linux distributions don't install ksh by default, install ksh or pdksh package for your distribution
