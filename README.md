# SQLC2
SQLC2 is a PowerShell script for deploying and managing a command and control system that uses SQL Server as both the control server and the agent.

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

### Author, Contributors, and License
* Author: Scott Sutherland (@_nullbind), NetSPI - 2018
* License: BSD 3-Clause
* Required Dependencies: None
