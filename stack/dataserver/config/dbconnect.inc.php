<?
function Zotero_dbConnectAuth($db) {
	$charset = '';
	
	$host = 'mariadb';
	$port = 3306;
	$user = getenv('MARIADB_USER');
	$pass = getenv('MARIADB_PASSWORD');
	
	if (!$user || !$pass) {
		throw new Exception("MARIADB_USER and MARIADB_PASSWORD must be set");
	}
	
	if ($db == 'master') {
		$replicas = [];
		$db = 'zotero_master';
		$state = 'up'; // 'up', 'readonly', 'down'
	}
	else if ($db == 'shard') {
		$db = 'zotero_shard_1';
	}
	else if ($db == 'id1') {
		$db = 'zotero_ids';
	}
	else if ($db == 'id2') {
		$db = 'zotero_ids';
	}
	else if ($db == 'www1') {
		$db = 'zotero_www';
	}
	else if ($db == 'www2') {
		$db = 'zotero_www';
	}
	else {
		throw new Exception("Invalid db '$db'");
	}
	return [
		'host' => $host,
		'replicas' => !empty($replicas) ? $replicas : [],
		'port' => $port,
		'db' => $db,
		'user' => $user,
		'pass' => $pass,
		'charset' => $charset,
		'state' => !empty($state) ? $state : 'up'
	];
}
?>
