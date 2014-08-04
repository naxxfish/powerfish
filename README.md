powerfish
=========

Some silly Powershell scripts that I find useful

pingy.ps1
---------

Usage:
  .\pingy.ps1 <hostname> [-quiet]

Pings a host, and notes if it goes down.  Unless you specify -quiet, it will also make a ping noise and use Text to Speech to tell you what it's up to.

Why? Because it's handy to monitor something in the background whilst you do something else - especially if you're waiting for something to reboot :-)

watchy.ps1
----------

Usage:
   .\watchy.ps1 -Folder <path to watch>
   
Uses FileSystemWatcher to watch a directory for changes.  

Why? It's handy when you're debugging some sort of interface that uses the fileystem as a method of transferring messages / work. 