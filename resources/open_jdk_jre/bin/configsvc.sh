## config esg
echo ${CF_INSTANCE_IP}
echo ${CF_INSTANCE_PORT}
JQ=jq

CONTEXT_PATH=`echo ${JBP_CONFIG_TOMCAT} | $JQ '.tomcat.context_path'|sed 's/"//g'`
if [ -z "$CONTEXT_PATH" ]; then 
  CONTEXT_PATH="ROOT"
fi

## config copy
#COPYS=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("copy"))|.name'|sed 's/"//g'`
#for copy in $COPYS
#do
#  from=`echo $VCAP_SERVICES | $JQ --arg copy $copy '.["user-provided"][]|select (.name==$copy)|.credentials.from'|sed 's/"//g'`
#  to=`echo $VCAP_SERVICES | $JQ --arg copy $copy '.["user-provided"][]|select (.name==$copy)|.credentials.to'|sed 's/"//g'`
#  cp 
#done

REGISTRY_URL=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("esg"))|.credentials.registryURL'|sed 's/"//g'`
if [ ! -z "$REGISTRY_URL" ]; then 
  echo "bind esg $REGISTRY_URL"
  sed -i "s/^esg.rest.port.*/esg.rest.port=${CF_INSTANCE_PORT}/" /home/vcap/app/.java-buildpack/tomcat/webapps/${CONTEXT_PATH}/WEB-INF/classes/esg.properties
  sed -i "/esg.rest.port/a\esg.rest.host=${CF_INSTANCE_IP}" /home/vcap/app/.java-buildpack/tomcat/webapps/${CONTEXT_PATH}/WEB-INF/classes/esg.properties
  sed -i "s/^esg.registryURL.*/esg.registryURL=${REGISTRY_URL}/" /home/vcap/app/.java-buildpack/tomcat/webapps/${CONTEXT_PATH}/WEB-INF/classes/esg.properties
fi



## config UM
UM=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("um"))|.name'`
if [ -n "$UM" ]; then
  classname=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("um"))|.credentials.classname'|sed 's/"//g'`
  localdatasource=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("um"))|.credentials.localdatasource'|sed 's/"//g'`
  datasourcename=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("um"))|.credentials.datasourcename'|sed 's/"//g'`
  ldapurl=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("um"))|.credentials.ldapurl'|sed 's/"//g'`
  usersdn=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("um"))|.credentials.usersdn'|sed 's/"//g'`
  admindn=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("um"))|.credentials.admindn'|sed 's/"//g'`
  adminpwd=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("um"))|.credentials.adminpwd'|sed 's/"//g'`
  partnerdn=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("um"))|.credentials.partnerdn'|sed 's/"//g'`
  getrolesql=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("um"))|.credentials.getrolesql'|sed 's/"//g'`

  echo "bind UM $ldapurl"

  sed -i "/<Host/i\<Realm className='${classname}' debug='99' localDataSource='${localdatasource}' dataSourceName='${datasourcename}' ldapUrl='${ldapurl}' ldapCtxFactory='com.sun.jndi.ldap.LdapCtxFactory' usersDn='${usersdn}' adminDn='${admindn}' adminPwd='${adminpwd}' partnerDn='${partnerdn}' getRoleSql=\"${getrolesql}\" />"  /home/vcap/app/.java-buildpack/tomcat/conf/server.xml
  
fi 
## config pafa

## config DB
dbnames=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("db"))|.name'|sed 's/"//g'`
if [ -z "`grep "Resources" /home/vcap/app/.java-buildpack/tomcat/conf/context.xml`" ]; then
  sed -i 's/<\/Context>/\n<\/Context>/' /home/vcap/app/.java-buildpack/tomcat/conf/context.xml
fi
for dbname in $dbnames 
do
  url=`echo $VCAP_SERVICES | $JQ --arg db $dbname '.["user-provided"][]|select (.name==$db)|.credentials.url'|sed 's/"//g'`
  user=`echo $VCAP_SERVICES | $JQ --arg db $dbname '.["user-provided"][]|select (.name==$db)|.credentials.user'|sed 's/"//g'`
  password=`echo $VCAP_SERVICES | $JQ --arg db $dbname '.["user-provided"][]|select (.name==$db)|.credentials.password'|sed 's/"//g'`
  jndi=`echo $VCAP_SERVICES | $JQ --arg db $dbname '.["user-provided"][]|select (.name==$db)|.credentials.jndi'|sed 's/"//g'`
  driverClassName=`echo $VCAP_SERVICES | $JQ --arg db $dbname '.["user-provided"][]|select (.name==$db)|.credentials.driverClassName'|sed 's/"//g'`
  echo "bind service $db url:$url jndi:$jndi"

    
done
