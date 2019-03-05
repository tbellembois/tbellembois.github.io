## recupération du hostname en paramètre
param ([string]$hostname)

## si argument existe
if ($hostname) 
{
	## définition des utilisateurs AD
	## 1 utilisateur host + 1 utilisateur par service
	$userHOST = "host-$hostname"
	$userNFS = "nfs-$hostname"
    $userCIFS = "cifs-$hostname"
    $userHOSTdn = "CN=host-$hostname,OU=kerberos,OU=DSI,DC=iut,DC=local"
	$userNFSdn = "CN=nfs-$hostname,OU=kerberos,OU=DSI,DC=iut,DC=local"
	$userCIFSdn = "CN=cifs-$hostname,OU=kerberos,OU=DSI,DC=iut,DC=local"
	
    ## fichiers de sortie
    $kthost = "host-$hostname.keytab"
	$ktnfs = "nfs-$hostname.keytab"
	$ktcifs = "cifs-$hostname.keytab"
	
	## génération d'un mot de passe aleatoire
	$pwd = -join ((48..122) | Get-Random -Count 17 | ForEach-Object {[char]$_})
	
    ## test existance user
	##
	if ((dsquery user $userHostdn) -And (dsquery user $userNFSdn) -And (dsquery user $userCIFSdn))
	{
		## reset password des utilsateurs
		dsmod user $userHostdn -pwd $pwd -pwdneverexpires yes
		dsmod user $userNFSdn -pwd $pwd -pwdneverexpires yes
		dsmod user $userCIFSdn -pwd $pwd -pwdneverexpires yes
	}
	else {
        ## création dans l'AD des utilisateurs
		dsadd user $userHOSTdn -samid $userHOST -pwd $pwd -pwdneverexpires yes
		dsadd user $userNFSdn -samid $userNFS -pwd $pwd -pwdneverexpires yes
		dsadd user $userCIFSdn -samid $userCIFS -pwd $pwd -pwdneverexpires yes
				
		## initialisation des service principal names par utilisateur
		setspn -A host/$hostname $userHOST
		setspn -A host/$hostname.iut.local $userHOST
		setspn -A host/$hostname.iut.local@IUT.LOCAL $userHOST
		setspn -A nfs/$hostname $userNFS
		setspn -A nfs/$hostname.iut.local $userNFS
		setspn -A nfs/$hostname.iut.local@IUT.LOCAL $userNFS
		setspn -A cifs/$hostname $userCIFS
		setspn -A cifs/$hostname.iut.local $userCIFS
		setspn -A cifs/$hostname.iut.local@IUT.LOCAL $userCIFS
		setspn -A cifs/$hostname@IUT.LOCAL $userCIFS
	}

    ## génération des keytab
     ktpass -princ host/$hostname.iut.local@IUT.LOCAL -pass $pwd -mapuser IUT\$userHOST -pType KRB5_NT_PRINCIPAL -out c:\TMP\krb\$kthost -crypto rc4-hmac-nt
	ktpass -princ nfs/$hostname.iut.local@IUT.LOCAL -pass $pwd -mapuser IUT\$userNFS -pType KRB5_NT_PRINCIPAL -out c:\TMP\krb\$ktnfs -crypto rc4-hmac-nt
	ktpass -princ cifs/$hostname@IUT.LOCAL -pass $pwd -mapuser IUT\$userCIFS -pType KRB5_NT_PRINCIPAL -out c:\TMP\krb\$ktcifs -crypto rc4-hmac-nt
}

else { write-output "Speficier nom machine en argument : .\krb3.ps1 dublin" }