-- To manually delete a node in the QSR rather than through the QMC
-- ServerNodeConfigurations
---- AppAvailabilities
-------- Blank out:
-------- App_ID
-------- AppDataSegment
-------- ServerNodeConfiguration_ID
---- CustomPropertyValues
-------- A lot, do a select to see if you need to fiddle with it
---- EngineServices
-------- CustomPropertyValues <--- do a Select on EngineService_ID
-------- EngineServiceSettings
------------- Uses EngineServices ID
-------- EngineServiceTags <-- Null
---- PrintingServices
-------- CustomPropertiesValue <-- Same
-------- PrintingServiceSettings
-------- PrintingServiceTags
---- ProxyServices
-------- CustomerPropertyValues
-------- ProxyServiceSettings
-------- ProxyServiceTags
---- RepositoryServices
-------- CustomPropertyValues
-------- RepositoryServiceSettings
-------- RepositoryServiceTags
---- SchedulerServices
-------- CustomPropertyValues
-------- ExecutionSessions
-------- SchedulerServiceSettings
-------- SchedulerServiceTags
---- ServerNodeConfigurationTags
---- ServiceStatus
---- SyncSessions
---- VirtualProxyConfigServerNodeConfigurations
-------- VirtualProxyConfigs
-- Handling the EngineServices for the Node
UPDATE "EngineServiceSettings" SET "Deleted"=TRUE WHERE "ID" IN (SELECT "ID" FROM "EngineServices" WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643');
UPDATE "EngineServices" SET "Deleted"=TRUE WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643';
DELETE FROM "EngineServiceSettings" WHERE "Deleted"=TRUE;
DELETE FROM "EngineServices" WHERE "Deleted"=TRUE;
-- Handling the PrintingServices for the Node
UPDATE "PrintingServiceSettings" SET "Deleted"=TRUE WHERE "ID" IN (SELECT "ID" FROM "PrintingServices" WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643');
UPDATE "PrintingServices" SET "Deleted"=TRUE WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643';
DELETE FROM "PrintingServiceSettings" WHERE "Deleted"=TRUE;
DELETE FROM "PrintingServices" WHERE "Deleted"=TRUE;
-- Handling the ProxyServices for the Node
UPDATE "ProxyServiceSettings" SET "Deleted"=TRUE WHERE "ID" IN (SELECT "ID" FROM "ProxyServices" WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643');
UPDATE "ProxyServiceSettingsLogVerbosities" SET "Deleted"=TRUE WHERE "ID" IN (SELECT "ID" FROM "ProxyServices" WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643');
UPDATE "ProxyServices" SET "Deleted"=TRUE WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643';
DELETE FROM "ProxyServiceSettingsLogVerbosities" WHERE "Deleted"=TRUE;
DELETE FROM "ProxyServiceSettings" WHERE "Deleted"=TRUE;
DELETE FROM "ProxyServices" WHERE "Deleted"=TRUE;
-- Handling the RepositoryServices for the Node
UPDATE "RepositoryServiceSettingsLogVerbosities" SET "Deleted"=TRUE WHERE "ID" IN (SELECT "ID" FROM "RepositoryServiceSettings" WHERE "ID" IN (SELECT "ID" FROM "RepositoryServices" WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643'));
UPDATE "RepositoryServiceSettingsCleaningAgents" SET "Deleted"=TRUE WHERE "ID" IN (SELECT "ID" FROM "RepositoryServiceSettings" WHERE "ID" IN (SELECT "ID" FROM "RepositoryServices" WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643'));
UPDATE "RepositoryServiceSettingsExternalCertificates" SET "Deleted"=TRUE WHERE "ID" IN (SELECT "ID" FROM "RepositoryServiceSettings" WHERE "ID" IN (SELECT "ID" FROM "RepositoryServices" WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643'));
UPDATE "RepositoryServiceSettingsSynchronizations" SET "Deleted"=TRUE WHERE "ID" IN (SELECT "ID" FROM "RepositoryServiceSettings" WHERE "ID" IN (SELECT "ID" FROM "RepositoryServices" WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643'));
UPDATE "RepositoryServiceSettings" SET "Deleted"=TRUE WHERE "ID" IN (SELECT "ID" FROM "RepositoryServices" WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643');
UPDATE "RepositoryServices" SET "Deleted"=TRUE WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643';
DELETE FROM "RepositoryServiceSettingsLogVerbosities" WHERE "Deleted"=TRUE;
DELETE FROM "RepositoryServiceSettingsCleaningAgents" WHERE "Deleted"=TRUE;
DELETE FROM "RepositoryServiceSettingsExternalCertificates" WHERE "Deleted"=TRUE;
DELETE FROM "RepositoryServiceSettingsSynchronizations" WHERE "Deleted"=TRUE;
DELETE FROM "RepositoryServiceSettings" WHERE "Deleted"=TRUE;
DELETE FROM "RepositoryServices" WHERE "Deleted"=TRUE;
-- Handling the SchedulerServices for the Node
UPDATE "SchedulerServiceSettings" SET "Deleted"=TRUE WHERE "ID" IN (SELECT "ID" FROM "SchedulerServices" WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643');
UPDATE "SchedulerServiceSettingsLogVerbosities" SET "Deleted"=TRUE WHERE "ID" IN (SELECT "ID" FROM "SchedulerServices" WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643');
UPDATE "SchedulerServices" SET "Deleted"=TRUE WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643';
DELETE FROM "SchedulerServiceSettingsLogVerbosities" WHERE "Deleted"=TRUE;
DELETE FROM "SchedulerServiceSettings" WHERE "Deleted"=TRUE;
DELETE FROM "SchedulerServices" WHERE "Deleted"=TRUE;
-- Handling the ServiceStatus for the Node
UPDATE "ServiceStatus" SET "Deleted"=TRUE WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643';
DELETE FROM "ServiceStatus" WHERE "Deleted"=TRUE;
-- Handling the SyncSessions for the Node
UPDATE "SyncSessions" SET "Deleted"=TRUE WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643';
DELETE FROM "SyncSessions" WHERE "Deleted"=TRUE;
-- Handling the VirtualProxyConfigServerNodeConfigurations for the Node
DELETE FROM "VirtualProxyConfigServerNodeConfigurations" WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643';
-- Handling AppAvailabilities
UPDATE "AppAvailabilities" SET "Deleted"=TRUE WHERE "ServerNodeConfiguration_ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643';
DELETE FROM "AppAvailabilities" WHERE "Deleted"=TRUE;
-- Finally nuking the ServerNode
DELETE FROM "ServerNodeConfigurations" WHERE "ID"='107fd2d0-8e3b-4ef5-9fea-da08fb83c643';