<?php
$usrID=posix_geteuid();
$userinfo = posix_getpwuid($usrID);

print_r($userinfo);

 echo phpinfo(); ?>

