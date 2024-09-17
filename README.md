# armaReforgerInstaller
Install baseline Arma Reforger server on Ubuntu Server.

The main idea is to save time doing the initial build out of the linux server. 
Will start by checking free space, and if there is less than 20GB will not run. 20 is the min as the server files alone are 8 GB, and just a few mods in, you will be at 12-15. 
This can be changed, as it is defined at the top as MIN_FREE_SPACE
You will input the name of the service that will be created, the port that it will run on, the name of the public server, if you want a password, and the admin password.

This will install all the packages that need to be there, and will fully update everything. 
Will then install steamcmd and Arma Reforger. 
Then will create the configuration files, the service, and the launcher ( run.sh ), as well as a debug launcher ( run.sh.CONSOLE_LOG )


This is WIP and is not perfect. 

The next steps are to isolate the data to the $armaservice user and the servermanager groups. 

If you run this script multiple times, it will create multiple users and instances of the data, so you can use this to create many services on one host OS.
There is no shared resources, as I have not had success with sharing game files among different instances. 
Feel free to download and make any changes or fork as nessesary. 
