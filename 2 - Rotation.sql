USE EkmDemo;
GO

-- Find expiration dates for certificates

SELECT [name] AS certificate_name, expiry_date, * FROM sys.certificates;
GO

CREATE TABLE #certExpirations 
	(server_name sysname,
	 database_name sysname,
	 certificate_name sysname,
	 expiry_date date);
INSERT INTO #certExpirations (server_name, database_name, certificate_name, expiry_date)
	EXECUTE sp_MSforeachdb N'SELECT @@SERVERNAME AS server_name, ''?'' AS database_name, [name] AS certificate_name, expiry_date FROM ?.sys.certificates';
SELECT server_name, database_name, certificate_name, expiry_date
	FROM #certExpirations
	WHERE certificate_name NOT LIKE '##MS%'
	ORDER BY expiry_date, database_name, certificate_name;
DROP TABLE #certExpirations;
GO

-- Column-level key rotation

SELECT sk.[name], sk.symmetric_key_id, ke.thumbprint, c.[name]
	FROM sys.symmetric_keys sk
		INNER JOIN sys.key_encryptions ke ON ke.key_id = sk.symmetric_key_id
		INNER JOIN sys.certificates c ON c.thumbprint = ke.thumbprint
	WHERE sk.[name] = 'skDemo';
GO

CREATE CERTIFICATE cerDemo3
	WITH SUBJECT = 'Demo certificate',
		 EXPIRY_DATE = '12/31/2018';
GO

OPEN SYMMETRIC KEY skDemo
	DECRYPTION BY CERTIFICATE cerDemo2;

ALTER SYMMETRIC KEY skDemo
	ADD ENCRYPTION BY CERTIFICATE cerDemo3;

CLOSE SYMMETRIC KEY skDemo;

SELECT sk.[name], sk.symmetric_key_id, ke.thumbprint, c.[name]
	FROM sys.symmetric_keys sk
		INNER JOIN sys.key_encryptions ke ON ke.key_id = sk.symmetric_key_id
		INNER JOIN sys.certificates c ON c.thumbprint = ke.thumbprint
	WHERE sk.[name] = 'skDemo';
GO

OPEN SYMMETRIC KEY skDemo
	DECRYPTION BY CERTIFICATE cerDemo3;

ALTER SYMMETRIC KEY	skDemo
	DROP ENCRYPTION BY CERTIFICATE cerDemo2;

CLOSE SYMMETRIC KEY skDemo;

SELECT sk.[name], sk.symmetric_key_id, ke.thumbprint, c.[name]
	FROM sys.symmetric_keys sk
		INNER JOIN sys.key_encryptions ke ON ke.key_id = sk.symmetric_key_id
		INNER JOIN sys.certificates c ON c.thumbprint = ke.thumbprint
	WHERE sk.[name] = 'skDemo';
GO

-- TDE key rotation

SELECT dek.database_id, DB_NAME(dek.database_id), dek.encryptor_thumbprint, c.[name]
	FROM sys.dm_database_encryption_keys dek
		INNER JOIN master.sys.certificates c ON c.thumbprint = dek.encryptor_thumbprint
	WHERE DB_NAME(dek.database_id) = 'EkmDemo';
GO

USE master;

CREATE CERTIFICATE cerDemoTde2
	WITH SUBJECT = 'Demo certificate',
		 EXPIRY_DATE = '12/31/2018';
GO

USE EkmDemo;

ALTER DATABASE ENCRYPTION KEY
	ENCRYPTION BY SERVER CERTIFICATE cerDemoTde2;
GO

SELECT dek.database_id, DB_NAME(dek.database_id), dek.encryptor_thumbprint, c.[name]
	FROM sys.dm_database_encryption_keys dek
		INNER JOIN master.sys.certificates c ON c.thumbprint = dek.encryptor_thumbprint
	WHERE DB_NAME(dek.database_id) = 'EkmDemo';
GO

-- Always Encrypted key rotation