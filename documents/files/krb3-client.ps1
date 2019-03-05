## recup du nom host en param
param ([string]$hostname,[int]$start,[int]$end)


## si argument existe
if ($hostname -and $start -and $end) 
{
    ## test formatage hostname en argument
    $test = $hostname | select-string -Pattern "XX" -CaseSensitive
    
    ##si argument correct
    if ($test)
    {
    
        ## boucle incrementation
        for ($j = $start; $j -le $end; $j++)
        {
            
            ## transformation 1 -> 01
            $numero = "{0:00}" -f $j
              
            ## creation du nom du poste traité          
            $nom = $hostname.replace("XX",$numero)
            $linux = $nom+"l"

	        ## user krb
	        $user = "nfs-$linux"
	        $userKRB = "CN=nfs-$linux,OU=kerberos,OU=DSI,DC=iut,DC=local"

	
	        ## mot de passe aleatoire
	        $pwd = -join ((48..122) | Get-Random -Count 17 | % {[char]$_})
	
            ## test existance user
            $userAD = $(dsquery user $userKRB)
    
            if ( $userAD -match $userKRB )
            {
                ## modif du pwd de user
                dsmod user $userKRB -pwd $pwd -pwdneverexpires yes
                ## generer keytab
	            ktpass -princ nfs/$linux.iut.local@IUT.LOCAL -pass $pwd -mapuser IUT\$user -pType KRB5_NT_PRINCIPAL -out c:\TMP\krb\$user.keytab -crypto rc4-hmac-nt
            }

            else 
            {
                ## creation dans AD user krb
	            dsadd user $userKRB -samid $user -pwd $pwd -pwdneverexpires yes

	            ## compte services
	            setspn -A host/$linux $user
	            setspn -A host/$linux.iut.local $user
	            setspn -A host/$linux.iut.local@IUT.LOCAL $user
	            setspn -A nfs/$linux $user
	            setspn -A nfs/$linux.iut.local $user
	            setspn -A nfs/$linux.iut.local@IUT.LOCAL $user

	            ## generer keytab
	            ktpass -princ nfs/$linux.iut.local@IUT.LOCAL -pass $pwd -mapuser IUT\$user -pType KRB5_NT_PRINCIPAL -out c:\TMP\krb\$user.keytab -crypto rc4-hmac-nt
            }
        }
    }
    else { echo "format hostname incorrect : iutclinfa18XX" }
}

else { echo "Speficier les arguments comme cet exemple : [nom machine fini par XX] [id permier poste] [id dernier poste] -->  \krb3.ps1 iutclinfa18XX 1 16 " }