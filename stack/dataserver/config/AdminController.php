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
	// DELETE /admin/users/{id} - Delete user
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
		else if ($this->method == 'DELETE') {
			$this->deleteUser();
		}
		else {
			$this->e405();
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
			$rows = Zotero_DB::query($sql);
			
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
	
	// GET /admin/items - List all items across all users/groups
	public function items() {
		if (!$this->permissions->isSuper()) {
			$this->e403("Super user access required");
		}
		
		if ($this->method != 'GET') {
			$this->e405();
		}
		
		try {
			$limit = isset($this->queryParams['limit']) ? intval($this->queryParams['limit']) : 50;
			$limit = min($limit, 100);
			
			// Get all libraries from master database
			$sql = "SELECT libraryID FROM libraries WHERE libraryType IN ('user', 'group') LIMIT ?";
			$libraries = Zotero_DB::query($sql, [$limit]);
			
			$items = [];
			foreach ($libraries as $lib) {
				try {
					$libraryID = $lib['libraryID'];
					
					// Get items for this library with proper params
					$params = [
						'limit' => 10,
						'start' => 0,
						'format' => null,
						'includeTrashed' => false,
						'itemKey' => []
					];
					$itemRows = Zotero_Items::search($libraryID, false, $params);
					
					foreach ($itemRows['results'] as $item) {
						if ($item) {
							$items[] = [
								'key' => $item->key,
								'title' => $item->getDisplayTitle(),
								'itemType' => Zotero_ItemTypes::getName($item->itemTypeID),
								'createdByUserID' => $item->createdByUserID ?? null,
								'libraryID' => $libraryID
							];
						}
					}
				} catch (Exception $e) {
					error_log("Items fetch error for library $libraryID: " . $e->getMessage());
					continue;
				}
			}
			
			header('Content-Type: application/json');
			echo json_encode($items);
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
			$exists = Zotero_WWW_DB_1::valueQuery($sql, [$username]);
			if ($exists) {
				$this->e400("Username already exists");
			}
			
			// Check email exists
			$sql = "SELECT COUNT(*) FROM users_email WHERE email = ?";
			$exists = Zotero_WWW_DB_1::valueQuery($sql, [$email]);
			if ($exists) {
				$this->e400("Email already exists");
			}
			
			// Create user in www database
			Zotero_WWW_DB_1::beginTransaction();
			
			$sql = "INSERT INTO users (username, password) VALUES (?, MD5(?))";
			Zotero_WWW_DB_1::query($sql, [$username, $password]);
			
			$userID = Zotero_WWW_DB_1::valueQuery("SELECT LAST_INSERT_ID()");
			
			if ($userID == 1) {
				Zotero_WWW_DB_1::rollback();
				$this->e500("UserID 1 is reserved");
			}
			
			$sql = "INSERT INTO users_email (userID, email) VALUES (?, ?)";
			Zotero_WWW_DB_1::query($sql, [$userID, $email]);
			
			Zotero_WWW_DB_1::commit();
			
			// Create library in master shard
			$shardID = 1;
			Zotero_DB::beginTransaction();
			
			$sql = "INSERT INTO libraries (libraryType, shardID) VALUES ('user', ?)";
			Zotero_DB::query($sql, [$shardID]);
			
			$libraryID = Zotero_DB::valueQuery("SELECT LAST_INSERT_ID()");
			
			// Insert into shardLibraries in the SHARD database
			$sql = "INSERT INTO shardLibraries (libraryID, libraryType) VALUES (?, 'user')";
			Zotero_DB::query($sql, [$libraryID], $shardID);
			
			// Insert into users table in MASTER database (not shard)
			$sql = "INSERT INTO users (userID, libraryID, username) VALUES (?, ?, ?)";
			Zotero_DB::query($sql, [$userID, $libraryID, $username]);
			
			Zotero_DB::commit();
			
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
			Zotero_WWW_DB_1::rollback();
			Zotero_DB::rollback();
			$this->handleException($e);
		}
	}
	
	private function listUsers() {
		try {
			$sql = "SELECT u.userID, u.username, e.email, u.role 
					FROM users u 
					LEFT JOIN users_email e ON u.userID = e.userID 
					WHERE u.role != 'deleted'
					ORDER BY u.userID";
			$rows = Zotero_WWW_DB_1::query($sql);
			
			$users = [];
			foreach ($rows as $row) {
				$users[] = [
					'userID' => $row['userID'],
					'username' => $row['username'],
					'email' => $row['email'],
					'enabled' => ($row['role'] == 'normal')
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
	
	private function deleteUser() {
		try {
			$userID = (int) $this->objectUserID;
			
			if (!$userID) {
				$this->e400("User ID required");
			}
			
			// Mark user as deleted first
			$sql = "UPDATE users SET role='deleted' WHERE userID=?";
			Zotero_WWW_DB_1::query($sql, [$userID]);
			
			// Delete user data
			$deleted = Zotero_Users::deleteUser($userID);
			
			if ($deleted) {
				$this->e204();
			} else {
				$this->e500("Failed to delete user");
			}
		}
		catch (Exception $e) {
			$this->handleException($e);
		}
	}
}
