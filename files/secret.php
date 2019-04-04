<?php
$pdo_dsn = 'mysql:host=localhost;dbname=racktables';
$db_username = 'rackuser';
$db_password = '<RACKPASSWORD>';

$user_auth_src = 'database';
$require_local_account = TRUE;

#$user_auth_src = 'ldap';
#$require_local_account = FALSE;

#$LDAP_options = array
#(
#  'server' => 'dbpwadsdc02.dnbint.net dbpwadsdc04.dnbint.net DBPWADSDCV12.dnbint.net',
#  'domain' => 'dnbint.net',
#  'search_attr' => 'sAMAccountName',
#  'search_dn' => 'OU=DNB,DC=dnbint,DC=net',
#  'displayname_attrs' => 'givenname sn',
#  'options' => array (LDAP_OPT_PROTOCOL_VERSION => 3, LDAP_OPT_REFERRALS => 0),
#);
?>