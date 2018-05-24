# SQLC2
SQLC2 is a PowerShell script for deploying and managing a command and control system that uses SQL Server as both the control server and the agent.

# Why Bother with a SQL Server Based C2?
More companies are starting to use Azure SQL Server databases. When those Azure SQL Server instances are created, they are made accessible via a subdomain of database.windows.net on port 1433. For example, I could create SQL Server instance named "mysupersqlserver.database.windows.net". As a result, some corporate network configurations allow outbound internet access to any "database.windows.net" subdomain on port 1433. 

So, the general idea is that as Azure SQL Server adoption grows, there will be more opportunity to use SQL Server as a control channel during pentests that looks kind of like normal traffic.  SQLPS is a pretty basic proof of concept, but I think it’s functional enough to illustrate the idea. I know there are quite a few improvements to be made, but if you end up playing with it, I’d love to hear any feedback you have. 

# User Functions
Below is a list of user functions that support the intended workflows.  For more information check out the SQLC2 blog at https://blog.netspi.com/.

|Function Name|Description |
|:--------------------------------|:-----------|
|Install-SQLC2Server|Install SQLC2 tables on target SQL Server/database.|
|Install-SQLC2AgentPs|Install an agent that uses an SQL Server agent job and server link.|
|Install-SQLC2AgentLink|Install an agent that uses a schedule task or registry key to execute PowerShell commands.|
|Set-SQLC2Command|Set operating system commands for agents to run.|
|Get-SQLC2Command|Get a list of pending operating system commands from the C2 for the agent.  This can also execute the pending command with the -Execute flag.|
|Get-SQLC2Agent|Get a list of agents registered on the SQLC2 server.| 
|Get-SQLC2Result|Get a list of pending and completed commands. Support servername, status, and cid filters.|
|Remove-SQLC2Agent|Remove agents registered on the SQLC2. Simply clears the history.|
|Remove-SQLC2Command|Remove the command history on the SQLC2 server.|
|Uninstall-SQLC2AgentLink|Uninstall SQLC2 agent that uses server links and an agent job.|
|Uninstall-SQLC2AgentPs|Uninstall all operating system based persistence methods.|
|Uninstall-SQLC2Server|Remove the SQLC2 tables from the target database.|

### Author and License
* Author: Scott Sutherland (@_nullbind), NetSPI - 2018
* License: BSD 3-Clause
* Required Dependencies: None
