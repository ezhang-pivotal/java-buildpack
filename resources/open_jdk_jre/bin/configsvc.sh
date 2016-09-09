## config esg
echo ${CF_INSTANCE_IP}
echo ${CF_INSTANCE_PORT}
JQ=jq

CONTEXT_PATH=`echo ${JBP_CONFIG_TOMCAT} | $JQ '.tomcat.context_path'`
if [ -z "$CONTEXT_PATH" ]; then 
  CONTEXT_PATH="ROOT"
fi

REGISTRY_URL=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("esg"))|.credentials.registryURL'|sed 's/"//g'`
if [ -n "$REGISTRY_URL" ]; then 
  echo "bind esg $REGISTRY_URL"
  sed -i "s/^esg.rest.port.*/esg.rest.port=${CF_INSTANCE_PORT}/" /home/vcap/app/.java-buildpack/tomcat/webapps/${CONTEXT_PATH}/WEB-INF/classes/esg.properties
  sed -i "/esg.rest.port/a\esg.rest.host=${CF_INSTANCE_IP}" /home/vcap/app/.java-buildpack/tomcat/webapps/${CONTEXT_PATH}/WEB-INF/classes/esg.properties
  sed -i "s/^esg.registryURL.*/esg.registryURL=${REGISTRY_URL}/" /home/vcap/app/.java-buildpack/tomcat/webapps/${CONTEXT_PATH}/WEB-INF/classes/esg.properties
fi

## config UM
UM=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("um"))|.'`
if [ -n "$UM" ]; then
  classname=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name=="um")|.credentials.classname'|sed 's/"//g'`
  localdatasource=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name=="um")|.credentials.localdatasource'|sed 's/"//g'`
  datasourcename=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name=="um")|.credentials.datasourcename'|sed 's/"//g'`
  ldapurl=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name=="um")|.credentials.ldapurl'|sed 's/"//g'`
  usersdn=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name=="um")|.credentials.usersdn'|sed 's/"//g'`
  admindn=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name=="um")|.credentials.admindn'|sed 's/"//g'`
  adminpwd=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name=="um")|.credentials.adminpwd'|sed 's/"//g'`
  partnerdn=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name=="um")|.credentials.partnerdn'|sed 's/"//g'`
  echo "bind UM $ldapurl"
  sed -i "/Host>/i\<Context docBase='${CONTEXT_PATH}' path='' reloadable='false' source='org.eclipse.jst.jee.server:dolphin'/>" /home/vcap/app/.java-buildpack/tomcat/conf/server.xml
  sed -i "/<Host/i\<realm classname='${classname}' debug='99' localdatasource='${localdatasource}' datasourcename='${datasourcename}' ldapurl='${ldapurl}' ldapctxfactory='com.sun.jndi.ldap.ldapctxfactory' usersdn='${usersdn}' admindn='${admindn}' adminpwd='${adminpwd}' partnerdn='${partnerdn}' getrolesql='${getrolesql}' />"  /home/vcap/app/.java-buildpack/tomcat/conf/server.xml
fi 
## config pafa

## config DB
dbnames=`echo $VCAP_SERVICES | $JQ '.["user-provided"][]|select (.name|contains("db"))|.name'|sed 's/"//g'`
for dbname in $dbnames 
do
  url=`echo $VCAP_SERVICES | $JQ --arg db $dbname '.["user-provided"][]|select (.name==$db)|.credentials.url'|sed 's/"//g'`
  user=`echo $VCAP_SERVICES | $JQ --arg db $dbname '.["user-provided"][]|select (.name==$db)|.credentials.user'|sed 's/"//g'`
  paasword=`echo $VCAP_SERVICES | $JQ --arg db $dbname '.["user-provided"][]|select (.name==$db)|.credentials.paasword'|sed 's/"//g'`
  jndi=`echo $VCAP_SERVICES | $JQ --arg db $dbname '.["user-provided"][]|select (.name==$db)|.credentials.jndi'|sed 's/"//g'`
  driverClassName=`echo $VCAP_SERVICES | $JQ --arg db $dbname '.["user-provided"][]|select (.name==$db)|.credentials.driverClassName'|sed 's/"//g'`
  echo "bind service $db url:$url jndi:$jndi"
  sed -i "/Resources/a\<Resource auth='Container' driverClassName='$driverClassName' maxActive='10' maxIdle='4' maxWait='5000' name='$jndi' password='$password' type='javax.sql.DataSource' url='$url' username='$user'/>"  /home/vcap/app/.java-buildpack/tomcat/conf/context.xml
done