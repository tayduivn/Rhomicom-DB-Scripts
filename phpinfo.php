<?php
echo "<div style=\"float:center;text-align:center;width:100%;\">";
echo "<br/><br/>Test rho-redis Docker Container Server";
$host = "rho-redis";
$port = 6379;
if (fsockopen($host, $port)) {
    print "<br/>I CAN reach port $port on $host";
} else {
    print "<br/>I CANNOT reach port $port on $host";
}
echo "<br/><br/>Test rho-pgdb Docker Container Server";
$host = "rho-pgdb";
$port = 5432;
if (fsockopen($host, $port)) {
    print "<br/>I CAN reach port $port on $host";
} else {
    print "<br/>I CANNOT reach port $port on $host";
}
echo "<br/><br/>Test rho-api Docker Container Server";
$host = "rho-api";
$port = 3000;
if (fsockopen($host, $port)) {
    print "<br/>I CAN reach port $port on $host";
} else {
    print "<br/>I CANNOT reach port $port on $host";
}
echo "</div>";
echo phpinfo();
?>
