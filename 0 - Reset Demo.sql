-- RUN THIS SCRIPT IN SQLCMD MODE

!!if not exist "C:\Temp\EKM" mkdir C:\Temp\EKM
!!del C:\Temp\EKM\*.* /q

USE master;
GO

IF NOT EXISTS (SELECT 'x' FROM sys.symmetric_keys WHERE [name] = '##MS_DatabaseMasterKey##')
	CREATE MASTER KEY
		ENCRYPTION BY PASSWORD = 'cyD;8xtcNYC@9ja';

IF EXISTS (SELECT 'x' FROM sys.databases WHERE [name] = 'EkmDemo')
	DROP DATABASE EkmDemo;

IF NOT EXISTS (SELECT 'x' FROM sys.certificates WHERE [name] = 'cerDemoTde1')
	CREATE CERTIFICATE cerDemoTde1
		WITH SUBJECT = 'Demo certificate',
			 EXPIRY_DATE = '12/31/2018';

IF EXISTS (SELECT 'x' FROM sys.certificates WHERE [name] = 'cerDemoTde2')
	DROP CERTIFICATE cerDemoTde2;

CREATE DATABASE EkmDemo;
GO

USE EkmDemo;

CREATE MASTER KEY
	ENCRYPTION BY PASSWORD = 'cyD;8xtcNYC@9ja';

CREATE CERTIFICATE cerDemo2
	WITH SUBJECT = 'Demo certificate',
		 EXPIRY_DATE = '12/31/2018';

CREATE SYMMETRIC KEY skDemo
	WITH ALGORITHM = AES_256
	ENCRYPTION BY CERTIFICATE cerDemo2;

CREATE DATABASE ENCRYPTION KEY
	WITH ALGORITHM = AES_256
	ENCRYPTION BY SERVER CERTIFICATE cerDemoTde1;
ALTER DATABASE EkmDemo
	SET ENCRYPTION ON;
GO

USE master;

IF EXISTS (SELECT 'x' FROM sys.databases WHERE [name] = 'ekmtde')
	DROP DATABASE ekmtde;
IF EXISTS (SELECT 'x' FROM sys.server_principals WHERE [name] = 'ekmTdeDemo1') BEGIN
	ALTER LOGIN ekmTdeDemo1
		DROP CREDENTIAL crd_EkmTdeDemo1;
	DROP LOGIN ekmTdeDemo1;
END;
IF EXISTS (SELECT 'x' FROM sys.credentials WHERE [name] = 'crd_EkmTdeDemo1')
	DROP CREDENTIAL crd_EkmTdeDemo1;
IF EXISTS (SELECT 'x' FROM sys.asymmetric_keys WHERE [name] = 'TestKey1')
	DROP ASYMMETRIC KEY TestKey1;
IF EXISTS (SELECT 'x' FROM sys.asymmetric_keys WHERE [name] = 'TestKey2')
	DROP ASYMMETRIC KEY TestKey2;
IF EXISTS (SELECT 'x' FROM sys.credentials WHERE [name] = 'crd_kvEkmDemo1') BEGIN
	ALTER LOGIN sa
		DROP CREDENTIAL crd_kvEkmDemo1;
	DROP CREDENTIAL crd_kvEkmDemo1;
END;
IF EXISTS (SELECT 'x' FROM sys.cryptographic_providers WHERE [name] = 'kvEkmDemo1')
	DROP CRYPTOGRAPHIC PROVIDER kvEkmDemo1;
GO

EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
EXECUTE sp_configure 'EKM provider enabled', 0;
RECONFIGURE;
GO
EXECUTE sp_configure 'show advanced options', 0;
RECONFIGURE;
GO
