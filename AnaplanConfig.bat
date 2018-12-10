:: Only Specify only ONE of the below 
:: EITHER 
:: Basic Authentication  
:: OR 
:: Certification Authority based Certificate  
:: NOT Both

:: Set username and password here for Basic Authentication
set AnaplanUser="username:password"

:: Certification Authority based Certificate loaded into a Java KeyStore
set Keystore=".\java_keystore\keystore_file.jks"
set KeystoreAlias="Keystore_Alias"
set KeystorePassword="Keystore_Password"

:: Anaplan Authentication services
set ServiceLocation="https://api.anaplan.com/"
set AuthenticationLocation="https://auth.anaplan.com"
