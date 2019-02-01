/*
Prerequisites:
- Azure Active Directory
- Visual Studio C++ Redistributable (VS2013 or VS2015)

1. Add an application to AAD
	- Go to AAD
	- Click App Registrations
	- Fill in required values
		- Type: Web App/API
		- Sign-on URL: Can be anything
	- Select new app in list
		- Documentation refers to "Client ID" - Now called Application ID
	- Add a key (client secret)
		- Term - 1 or 2 years
		- Copy and paste the secret *now* - Can't retrieve it later
			- Prep - wfdscQtcnPJxrCfEsAMGWDaJo4SozDz9eqnDbR/wTSI=
2. Create an Azure Key Vault
	- Set basic properties
		- Pricing tier: Standard or Premium - Premium uses HSM
	- Add the application created above to the AKV
		- Minimum permissions: Get, List, Wrap Key, Unwrap Key
		- Will need the Application ID and secret created earlier if not using Azure portal
3. Create an asymmetric key
	- Keys are 2048-bit RSA, either software-protected or hardware-protected (HSM)
	- Key can be imported from external source
		- Importing allows the private key to be escrowed
		- Private keys created in AKV can never leave AKV
	- AKV versions keys by default, but versioned keys cannot be versioned or rolled to be used with SQL
4. Install SQL Server Connector
	- https://www.microsoft.com/en-us/download/details.aspx?id=45344
	- NOTE: Feb 2018 version has a bug: https://sysadmin-monkey.net/2018/03/errors-with-february-2018-sql-connector-for-azure-key-vault/
		- New registry key "HKLM\SOFTWARE\Microsoft\SQL Server Cryptographic Provider" required
		- Give full access to SQL Server service account
*/

/*
5. Configure SQL to use EKM
	- Enable 'EKM provider enabled' option using sp_configure
	- Create a cryptographic provider, pointed to the DLL installed in step 4
*/

USE master;
EXECUTE sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
EXECUTE sp_configure 'EKM provider enabled', 1;
RECONFIGURE;
GO

CREATE CRYPTOGRAPHIC PROVIDER kvEkmDemo1
	FROM FILE = 'C:\Program Files\SQL Server Connector for Microsoft Azure Key Vault\Microsoft.AzureKeyVaultService.EKM.dll';
GO

/*
6. Create a credential to connect to the AKV
	- Identity: Key Vault name
	- Secret/Password: Application ID (no hyphens) + client secret from step 1
	- Cryptographic provider: Name from step 5
*/

USE master;
CREATE CREDENTIAL crd_kvEkmDemo1
	WITH IDENTITY = 'kvMNPrep',
		 SECRET = '43464af1508b46849ca8e8b0b9e21e29mel0v3f8Gm02yz92U22dHBJhDB4xbPLudCOXBymaGFw='
	FOR CRYPTOGRAPHIC PROVIDER kvEkmDemo1;
GO

/*
7. Add the credential to the login that will use the AKV
	- Credential can only be mapped to one login
*/
	
ALTER LOGIN [sa]
	ADD CREDENTIAL crd_kvEkmDemo1;
GO

/*
8. Add the key from step 3 to SQL
*/

CREATE ASYMMETRIC KEY TestKey1
	FROM PROVIDER kvEkmDemo1
	WITH PROVIDER_KEY_NAME = 'prep1',
		 CREATION_DISPOSITION = OPEN_EXISTING;
GO

/*
9. Create a new key from SQL
	- Make sure the user in AKV has permissions - Error message is cryptic
	*** NOT WORKING YET ***
*/	

--CREATE ASYMMETRIC KEY TestKey2
--	FROM PROVIDER kvEkmDemo1
--	WITH PROVIDER_KEY_NAME = 'TestKey2',
--		 ALGORITHM = RSA_2048,
--		 CREATION_DISPOSITION = CREATE_NEW;
--GO

/*
10. Use key with TDE
	- Add a new credential
	- Add a new login for the asymmetric key, then associate it with the credential
*/

USE master;
CREATE CREDENTIAL crd_EkmTdeDemo1
	WITH IDENTITY = 'kvMNPrep',
		 SECRET = '43464af1508b46849ca8e8b0b9e21e29mel0v3f8Gm02yz92U22dHBJhDB4xbPLudCOXBymaGFw='
	FOR CRYPTOGRAPHIC PROVIDER kvEkmDemo1;
CREATE LOGIN ekmTdeDemo1
	FROM ASYMMETRIC KEY TestKey1;
ALTER LOGIN ekmTdeDemo1
	ADD CREDENTIAL crd_EkmTdeDemo1;
GO

CREATE DATABASE ekmtde;
GO

USE ekmtde;
CREATE DATABASE ENCRYPTION KEY
	WITH ALGORITHM = AES_256
	ENCRYPTION BY SERVER ASYMMETRIC KEY TestKey1;
GO