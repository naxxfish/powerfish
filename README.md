powerfish
=========

Some silly Powershell scripts that I find useful

pingy.ps1
---------

Usage:
  .\pingy.ps1 <hostname> [-quiet]

Pings a host, and notes if it goes down.  Unless you specify -quiet, it will also make a ping noise and use Text to Speech to tell you what it's up to.

Why? Because it's handy to monitor something in the background whilst you do something else - especially if you're waiting for something to reboot :-)
