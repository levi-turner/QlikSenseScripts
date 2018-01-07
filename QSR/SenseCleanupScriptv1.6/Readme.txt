###########################################################################################
###																						###
###																						###
###						Qlik Sense Cleanup script v1.6									###
###																						###
###																						###
###########################################################################################


Changelog:
v1.1 - Replaced console output into popup dialogues
v1.2 - Updated SQL script to remove wrong relations for License usages and UserAttributes before cleaning those up
v1.3 - Added a SQL script thatworks with Qlik Sense 3.0 and updated SenseCleanupScript.ps1 with the new version.
v1.4 - Refined script to handle relations between AppContent-StaticContent and AppObjects-FileReferences
v1.5 - Added recursive deletion of orphans script.
v1.6 - Removed the enforced version check to let it be executed on all versions of Sense. Also removed duplicate statements.

Requirements:
Windows Management Framework 4.0 or later (https://www.microsoft.com/en-us/download/details.aspx?id=40855)


Instructions:
1. Make backup of your current environment
2. Run SenseCleanupScript.cmd
3. Select path to where Qlik Sense is installed (default: C:\Program Files\Qlik\Sense)
4. You may need to enter the password for database administrator 'postgres'
5. Run this script on ALL nodes before starting up the Qlik Sense Services

NOTE: Always start up the Services on Central node first before starting up rest of the nodes

Verified on:
Win Server 2012 R2
Win Server 2008 R2
Win 7 Enterprise