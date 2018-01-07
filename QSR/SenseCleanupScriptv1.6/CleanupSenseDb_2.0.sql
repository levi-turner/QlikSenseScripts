/* ##############################################################################################################################
   Script Name: CleanupSenseDb_2.0
   Description: the script IS intended to delete all entities marked as soft deleted in QRS database
   Caution: PLEASE BACKUP the whole QRS database before execute the script, in case error occurs, restore the backup, find out
            the data descrepancy, fix then execute again
   Revision history:
   Version     Date         Author    Change Notes
   # 1.4.0     2016-08-22   Vijay Vekariya  
   # 1.4.1     2016-08-24   Vijay Vekariya Commented out the extended deletion of SyncSessions
   # 1.6.0     2016-10-10   Vijay Vekariya Removed SQL commands that will be handled by recurse_cleanup.sql
   ##############################################################################################################################
 */
 
 
 /* Step 1. Remove relations between tables
   ##############################################################################################################################
 */
UPDATE "UserAttributes" SET "User_ID" = NULL, "Deleted" = TRUE WHERE "User_ID" IN (SELECT "ID" FROM "Users" WHERE "Deleted" = TRUE);
UPDATE "LicenseUserAccessUsages" SET "UserAccessType_ID" = NULL, "Deleted" = TRUE WHERE "UserAccessType_ID" IN (SELECT "ID" FROM "LicenseUserAccessTypes"  WHERE "Deleted" = TRUE);
UPDATE "LicenseUserAccessTypes" SET "User_ID" = NULL, "Quarantined" = TRUE, "Deleted" = TRUE WHERE "User_ID" IN (SELECT "ID" FROM "Users" WHERE "Deleted" = TRUE);
UPDATE "CompositeEventTimeConstraints" SET "Deleted" = TRUE WHERE "ID" IN  (SELECT "ID" FROM "CompositeEvents" WHERE "Deleted" = TRUE) AND "Deleted" = FALSE;
UPDATE "CompositeEventTimeConstraints" SET "ModifiedDate" = date_trunc('hour', TIMESTAMP '2001-01-01 00:00:00'), "CreatedDate" = date_trunc('hour', TIMESTAMP '2001-01-01 00:00:00') WHERE "ID" IN (SELECT "ID" FROM "CompositeEvents" WHERE "Deleted" IS TRUE AND "ModifiedDate" < Now() - INTERVAL '3 days');
UPDATE "CompositeEventTimeConstraints" SET "Deleted" = TRUE WHERE "ID" IN (SELECT "ID" FROM "CompositeEvents" WHERE "Deleted" IS TRUE);
UPDATE "CompositeEventRules" SET "ModifiedDate" = date_trunc('hour', TIMESTAMP '2001-01-01 00:00:00') WHERE "CompositeEvent_ID" IN (SELECT "ID" FROM "CompositeEvents" WHERE "Deleted" IS TRUE AND "ModifiedDate" < Now() - INTERVAL '3 days');
UPDATE "CompositeEventRules" SET "CompositeEvent_ID" = NULL ,"Deleted" = TRUE WHERE "CompositeEvent_ID" IN (SELECT "ID" FROM "CompositeEvents" WHERE "Deleted" IS TRUE);
UPDATE "AppStatus" SET "App_ID" = NULL, "Deleted" = TRUE WHERE "App_ID" IN (SELECT "ID" FROM "Apps" WHERE "Deleted" = TRUE);

/* Step 2. Hard delete records older than 3 days
   ##############################################################################################################################
 */
--DELETE FROM "SyncSessions" WHERE "SyncState" IN (2,3) AND "ModifiedDate" < Now() - INTERVAL '7 days';
DELETE FROM "FileReferenceStaticContentReferences" WHERE "StaticContentReference_ID" NOT IN (SELECT "ID" FROM "StaticContentReferences" WHERE "ID" IS NOT NULL);
DELETE FROM "ExecutionResults" WHERE "ID" NOT IN (SELECT "LastExecutionResult_ID" FROM "ReloadTaskOperationals") AND "ModifiedDate" < Now() - INTERVAL '3 days';
DELETE FROM "AppObjects" WHERE "App_ID" NOT IN (SELECT "ID" FROM "Apps" WHERE "ID" IS NOT NULL);

/* Step 3. Hard delete of FileReferences records for Archived Logs and orphaned Filereferences
   ##############################################################################################################################
 */
DELETE FROM "FileReferences" WHERE "FileType" = 1 AND "ModifiedDate" < Now() - INTERVAL '3 days';
DELETE FROM "FileReferences" WHERE "ID" NOT IN (SELECT "FileReference_ID" FROM "StaticContentReferenceFileReferences" WHERE "FileReference_ID" IS NOT NULL) AND "FileType"=2;
DELETE FROM "FileReferences" WHERE "ID" NOT IN (SELECT "File_ID" FROM "AppObjects" WHERE "File_ID" IS NOT NULL) AND "FileType"=3;
DELETE FROM "FileReferences" WHERE "ID" NOT IN (SELECT "File_ID" FROM "AppDataSegments" WHERE "File_ID" IS NOT NULL) AND "FileType"=4;

/* Step 4. Hard delete of Scheduler task results records older than 3 days
   ##############################################################################################################################
 */
DELETE FROM "ExecutionResultDetailExecutionResults" WHERE "ExecutionResult_ID" IN (SELECT "ID" FROM "ExecutionResults" WHERE "ModifiedDate" < Now() - INTERVAL '3 days');
DELETE FROM "ExecutionResultDetails" WHERE "ID" NOT IN (SELECT "ExecutionResultDetail_ID" FROM "ExecutionResultDetailExecutionResults");