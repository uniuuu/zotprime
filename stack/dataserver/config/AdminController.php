<?php
/*
    ***** BEGIN LICENSE BLOCK *****
    
    This file is part of the Zotero Data Server.
    
    Copyright © 2026 ZotPrime
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.
    
    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    ***** END LICENSE BLOCK *****
*/

require('ApiController.php');

class AdminController extends ApiController {
	
	// POST /admin/users - Create user
	// GET /admin/users - List all users
	// PUT /admin/users/{id}/status - Enable/disable user
	public function users() {
		if (!$this->permissions->isSuper()) {
			$this->e403("Super user access required");
		}
		
		if ($this->method == 'POST') {
			$this->createUser();
		}
		else if ($this->method == 'GET') {
			$this->listUsers();
		}
		else {
			$this->e405();
		}
	}
	
	// PUT /admin/users/{id}/status
	public function userStatus() {
		if (!$this->permissions->isSuper()) {
			$this->e403("Super user access required");
		}
		
		if ($this->method != 'PUT') {
			$this->e405();
		}
		
		$userID = $this->objectUserID;
		if (!$userID) {
			$this->e400("User ID required");
		}
		
		try {
			$data = json_decode($this->body, true);
			if (!isset($data['enabled'])) {
				$this->e400("enabled field required (true/false)");
			}
			
			$enabled = $data['enabled'] ? 1 : 0;
			
			$sql = "UPDATE users SET enabled = ? WHERE userID = ?";
			Zotero_DB_Query($sql, [$enabled, $userID], 0);
			
			$this->e204();
		}
		catch (Exception $e) {
			$this->handleException($e);
		}
	}
	
	// GET /admin/groups - List all groups
	public function groups() {
		if (!$this->permissions->isSuper()) {
			$this->e403("Super user access required");
		}
		
		if ($this->method != 'GET') {
			$this->e405();
		}
		
		try {
			$sql = "SELECT groupID, libraryID FROM groups";
			$rows = Zotero_DB_Query($sql, false, Zotero_Shards::getNextShard());
			
			$groups = [];
			foreach ($rows as $row) {
				$group = Zotero_Groups::get($row['groupID']);
				if ($group) {
					$groups[] = [
						'id' => $group->id,
						'name' => $group->name,
						'type' => $group->type,
						'owner' => $group->ownerUserID,
						'libraryID' => $row['libraryID']
					];
				}
			}
			
			header('Content-Type: application/json');
			echo json_encode($groups);
			exit;
		}
		catch (Exception $e) {
			$this->handleException($e);
		}
	}
	
	private function createUser() {
		try {
			$data = json_decode($this->body, true);
			
			if (!isset($data['username']) || !isset($data['email']) || !isset($data['password'])) {
				$this->e400("username, email, and password required");
			}
			
			$username = $data['username'];
			$email = $data['email'];
			$password = $data['password'];
			
			// Check username exists
			$sql = "SELECT COUNT(*) FROM users WHERE username = ?";
			$exists = Zotero_DB_ValueQuery($sql, $username, 0);
			if ($exists) {
				$this->e400("Username already exists");
			}
			
			// Check email exists
			$sql = "SELECT COUNT(*) FROM users_email WHERE email = ?";
			$exists = Zotero_DB_ValueQuery($sql, $email, 0);
			if ($exists) {
				$this->e400("Email already exists");
			}
			
			// Create user in www database
			Zotero_DB_Query("BEGIN", false, 0);
			
			$sql = "INSERT INTO users (username, password) VALUES (?, MD5(?))";
			Zotero_DB_Query($sql, [$username, $password], 0);
			
			$userID = Zotero_DB_ValueQuery("SELECT LAST_INSERT_ID()", false, 0);
			
			if ($userID == 1) {
				Zotero_DB_Query("ROLLBACK", false, 0);
				$this->e500("UserID 1 is reserved");
			}
			
			$sql = "INSERT INTO users_email (userID, email) VALUES (?, ?)";
			Zotero_DB_Query($sql, [$userID, $email], 0);
			
			Zotero_DB_Query("COMMIT", false, 0);
			
			// Create library in master
			$shardID = 1;
			Zotero_DB_Query("BEGIN", false, Zotero_Shards::getByUserID(0));
			
			$sql = "INSERT INTO libraries (libraryType, shardID) VALUES ('user', ?)";
			Zotero_DB_Query($sql, $shardID, Zotero_Shards::getByUserID(0));
			
			$libraryID = Zotero_DB_ValueQuery("SELECT LAST_INSERT_ID()", false, Zotero_Shards::getByUserID(0));
			
			$sql = "INSERT INTO users (userID, libraryID, username) VALUES (?, ?, ?)";
			Zotero_DB_Query($sql, [$userID, $libraryID, $username], Zotero_Shards::getByUserID(0));
			
			Zotero_DB_Query("COMMIT", false, Zotero_Shards::getByUserID(0));
			
			// Create shard entry
			$sql = "INSERT INTO shardLibraries (libraryID, libraryType) VALUES (?, 'user')";
			Zotero_DB_Query($sql, $libraryID, $shardID);
			
			// Return created user
			header('Content-Type: application/json');
			http_response_code(201);
			echo json_encode([
				'userID' => $userID,
				'username' => $username,
				'email' => $email,
				'libraryID' => $libraryID
			]);
			exit;
		}
		catch (Exception $e) {
			Zotero_DB_Query("ROLLBACK", false, 0);
			Zotero_DB_Query("ROLLBACK", false, Zotero_Shards::getByUserID(0));
			$this->handleException($e);
		}
	}
	
	private function listUsers() {
		try {
			$sql = "SELECT u.userID, u.username, e.email, u.enabled 
					FROM users u 
					LEFT JOIN users_email e ON u.userID = e.userID 
					ORDER BY u.userID";
			$rows = Zotero_DB_Query($sql, false, 0);
			
			$users = [];
			foreach ($rows as $row) {
				$users[] = [
					'userID' => $row['userID'],
					'username' => $row['username'],
					'email' => $row['email'],
					'enabled' => $row['enabled'] == 1
				];
			}
			
			header('Content-Type: application/json');
			echo json_encode($users);
			exit;
		}
		catch (Exception $e) {
			$this->handleException($e);
		}
	}
}
