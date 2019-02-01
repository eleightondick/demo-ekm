USE EkmDemo;
GO

-- Backing up a certificate
CREATE CERTIFICATE cerDemo1
	WITH SUBJECT = 'Demo certificate',
		 EXPIRY_DATE = '12/31/2018';

BACKUP CERTIFICATE cerDemo1
	TO FILE = 'C:\Temp\EKM\cerDemo1_201810.cer'
	WITH PRIVATE KEY (FILE = 'C:\Temp\EKM\cerDemo1_201810.pvk',
					  ENCRYPTION BY PASSWORD = 'cyD;8xtcNYC@9ja');
GO

-- Restoring a certificate

DROP CERTIFICATE cerDemo1;

CREATE CERTIFICATE cerDemo1
	FROM FILE = 'C:\Temp\EKM\cerDemo1_201810.cer'
	WITH PRIVATE KEY (FILE = 'C:\Temp\EKM\cerDemo1_201810.pvk',
					  DECRYPTION BY PASSWORD = 'cyD;8xtcNYC@9ja');
GO

-- Backing up the database master key

--CREATE MASTER KEY
--	ENCRYPTION BY PASSWORD = 'cyD;8xtcNYC@9ja';

BACKUP MASTER KEY
	TO FILE = 'C:\Temp\EKM\mk_201810.cer'
	ENCRYPTION BY PASSWORD = 'cyD;8xtcNYC@9ja';
GO

-- Backing up the service master key

--ALTER SERVICE MASTER KEY
--	REGENERATE;
--GO

BACKUP SERVICE MASTER KEY
	TO FILE = 'C:\Temp\EKM\smk_201810.cer'
	ENCRYPTION BY PASSWORD = 'cyD;8xtcNYC@9ja';
GO

-- Restoring a master key to a restored database

RESTORE MASTER KEY
	FROM FILE = 'C:\Temp\EKM\mk_201810.cer'
	DECRYPTION BY PASSWORD = 'cyD;8xtcNYC@9ja'
	ENCRYPTION BY PASSWORD = 'cyD;8xtcNYC@9ja';
GO

RESTORE MASTER KEY
	FROM FILE = 'C:\Temp\EKM\mk_201810.cer'
	DECRYPTION BY PASSWORD = 'cyD;8xtcNYC@9ja'
	ENCRYPTION BY PASSWORD = 'cyD;8xtcNYC@9ja'
	FORCE;
GO