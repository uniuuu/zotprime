<?
require('mvc/Router.inc.php');
$router = new Router();

// Set controller to 404 to block access to an action via a particular URL

$router->map('/', ['controller' => 'Api', 'action' => 'noop']);

// Admin endpoints (must be before other routes)
$router->map('/admin/users', ['controller' => 'Admin', 'action' => 'users']);
$router->map('/admin/users/i:objectUserID/status', ['controller' => 'Admin', 'action' => 'userStatus']);
$router->map('/admin/groups', ['controller' => 'Admin', 'action' => 'groups']);

// Global items
$router->map('/globalitems', ['controller' => 'GlobalItems', 'extra' => ['globalItems' => true]]);
$router->map('/globalitems/:objectGlobalItemID/items', ['controller' => 'Items', 'extra' => ['globalItems' => true]]);

// Groups
$router->map('/groups/i:objectGroupID', array('controller' => 'Groups'));
$router->map('/groups/i:scopeObjectID/users/i:objectID', array('controller' => 'Groups', 'action' => 'groupUsers'));

// Top-level objects
$router->map('/users/i:objectUserID/publications/items/top', ['controller' => 'Items', 'extra' => ['subset' => 'top', 'publications' => true]]);
$router->map('/users/i:objectUserID/:controller/top', array('extra' => array('subset' => 'top')));
$router->map('/groups/i:objectGroupID/:controller/top', array('extra' => array('subset' => 'top')));

// Attachment files
$router->map('/users/i:objectUserID/laststoragesync', array('controller' => 'Storage', 'action' => 'laststoragesync', 'extra' => array('auth' => true)));
$router->map('/groups/i:objectGroupID/laststoragesync', array('controller' => 'Storage', 'action' => 'laststoragesync', 'extra' => array('auth' => true)));
$router->map('/users/i:objectUserID/storageadmin', array('controller' => 'Storage', 'action' => 'storageadmin'));
$router->map('/storagepurge', array('controller' => 'Storage', 'action' => 'storagepurge'));
$router->map('/users/i:objectUserID/removestoragefiles', ['controller' => 'Storage', 'action' => 'removestoragefiles']);
$router->map('/users/i:objectUserID/items/:objectKey/file', ['controller' => 'Items', 'extra' => ['file' => true]]);
$router->map('/users/i:objectUserID/items/:objectKey/file/view', ['controller' => 'Items', 'extra' => ['file' => true, 'view' => true]]);
$router->map('/users/i:objectUserID/items/:objectKey/file/view/url', ['controller' => 'Items', 'extra' => ['file' => true, 'viewurl' => true]]);
$router->map('/users/i:objectUserID/publications/items/:objectKey/file', ['controller' => 'Items', 'extra' => ['file' => true, 'publications' => true]]);
$router->map('/users/i:objectUserID/publications/items/:objectKey/file/view', ['controller' => 'Items', 'extra' => ['file' => true, 'view' => true, 'publications' => true]]);
$router->map('/users/i:objectUserID/publications/items/:objectKey/file/view/url', ['controller' => 'Items', 'extra' => ['file' => true, 'viewurl' => true, 'publications' => true]]);
$router->map('/groups/i:objectGroupID/items/:objectKey/file', ['controller' => 'Items', 'extra' => ['file' => true]]);
$router->map('/groups/i:objectGroupID/items/:objectKey/file/view', ['controller' => 'Items', 'extra' => ['file' => true, 'view' => true]]);
$router->map('/groups/i:objectGroupID/items/:objectKey/file/view/url', ['controller' => 'Items', 'extra' => ['file' => true, 'viewurl' => true]]);

// Full-text content
$router->map('/users/i:objectUserID/items/:objectKey/fulltext', array('controller' => 'FullText', 'action' => 'itemContent'));
//$router->map('/users/i:objectUserID/publications/items/:objectKey/fulltext', ['controller' => 'FullText', 'action' => 'itemContent', 'extra' => ['publications' => true]]);
$router->map('/groups/i:objectGroupID/items/:objectKey/fulltext', array('controller' => 'FullText', 'action' => 'itemContent'));
$router->map('/users/i:objectUserID/fulltext', array('controller' => 'FullText', 'action' => 'fulltext'));
//$router->map('/users/i:objectUserID/publications/fulltext', ['controller' => 'FullText', 'action' => 'fulltext', 'extra' => ['publications' => true]]);
$router->map('/groups/i:objectGroupID/fulltext', array('controller' => 'FullText', 'action' => 'fulltext'));

// All trashed items
$router->map('/users/i:objectUserID/items/trash', array('controller' => 'Items', 'extra' => array('subset' => 'trash')));
$router->map('/groups/i:objectGroupID/items/trash', array('controller' => 'Items', 'extra' => array('subset' => 'trash')));

// Subcollections, single and multiple
$router->map('/users/i:objectUserID/collections/:scopeObjectKey/collections/:objectKey', array('controller' => 'Collections', 'extra' => array('scopeObject' => 'collections')));
$router->map('/groups/i:objectGroupID/collections/:scopeObjectKey/collections/:objectKey', array('controller' => 'Collections','extra' => array('scopeObject' => 'collections')));

// Deleted items in a collection
$router->map('/users/i:objectUserID/:scopeObject/:scopeObjectKey/items/trash', array('controller' => 'Items', 'extra' => array('subset' => 'trash')));

// Tags, which have names instead of ids
$router->map('/users/i:objectUserID/tags/:scopeObjectName/items/:objectName/:subset', array('controller' => 'Items', 'extra' => array('scopeObject' => 'tags')));
$router->map('/groups/i:objectGroupID/tags/:scopeObjectName/items/:objectName/:subset', array('controller' => 'Items', 'extra' => array('scopeObject' => 'tags')));
$router->map('/users/i:objectUserID/tags/:objectName/:subset', array('controller' => 'Tags'));
//$router->map('/users/i:objectUserID/publications/tags/:objectName/:subset', ['controller' => 'Tags', 'extra' => ['publications' => true]]);
$router->map('/groups/i:objectGroupID/tags/:objectName/:subset', array('controller' => 'Tags'));

// Tags within items
$router->map('/users/i:objectUserID/items/tags', ['controller' => 'Tags', 'extra' => ['scopeObject' => 'items']]);
$router->map('/groups/i:objectGroupID/items/tags', ['controller' => 'Tags', 'extra' => ['scopeObject' => 'items']]);
$router->map('/users/i:objectUserID/items/top/tags', ['controller' => 'Tags', 'extra' => ['scopeObject' => 'items', 'subset' => 'top']]);
$router->map('/groups/i:objectGroupID/items/top/tags', ['controller' => 'Tags', 'extra' => ['scopeObject' => 'items', 'subset' => 'top']]);
$router->map('/users/i:objectUserID/items/trash/tags', ['controller' => 'Tags', 'extra' => ['scopeObject' => 'items', 'subset' => 'trash']]);
$router->map('/groups/i:objectGroupID/items/trash/tags', ['controller' => 'Tags', 'extra' => ['scopeObject' => 'items', 'subset' => 'trash']]);
// Tags within items within a collection
$router->map('/users/i:objectUserID/collections/:scopeObjectKey/items/tags', ['controller' => 'Tags', 'extra' => ['scopeObject' => 'collection-items']]);
$router->map('/groups/i:objectGroupID/collections/:scopeObjectKey/items/tags', ['controller' => 'Tags', 'extra' => ['scopeObject' => 'collection-items']]);
$router->map('/users/i:objectUserID/collections/:scopeObjectKey/items/top/tags', ['controller' => 'Tags', 'extra' => ['scopeObject' => 'collection-items', 'subset' => 'top']]);
$router->map('/groups/i:objectGroupID/collections/:scopeObjectKey/items/top/tags', ['controller' => 'Tags', 'extra' => ['scopeObject' => 'collection-items', 'subset' => 'top']]);
// Tags within items within My Publications
$router->map('/users/i:objectUserID/publications/items/tags', ['controller' => 'Tags', 'extra' => ['scopeObject' => 'items', 'publications' => true]]);

// Tags within something else
//$router->map('/users/i:objectUserID/publications/items/:scopeObjectKey/tags/:objectKey/:subset', ['controller' => 'Tags', 'extra' => ['publications' => true]]);
$router->map('/users/i:objectUserID/:scopeObject/:scopeObjectKey/tags/:objectName/:subset', array('controller' => 'Tags'));
$router->map('/groups/i:objectGroupID/:scopeObject/:scopeObjectKey/tags/:objectName/:subset', array('controller' => 'Tags'));

// Searches
$router->map('/users/i:objectUserID/publications/searches/:objectKey', ['controller' => 'Searches', 'extra' => ['publications' => true]]);

// Items within something else
$router->map('/users/i:objectUserID/publications/items/:scopeObjectKey/items/:objectKey/:subset', ['controller' => 'Items', 'extra' => ['publications' => true]]);
$router->map('/users/i:objectUserID/:scopeObject/:scopeObjectKey/items/:objectKey/:subset', array('controller' => 'Items'));
$router->map('/groups/i:objectGroupID/:scopeObject/:scopeObjectKey/items/:objectKey/:subset', array('controller' => 'Items'));

// Collections within something else
$router->map('/users/i:objectUserID/:scopeObject/:scopeObjectKey/collections/:objectKey/:subset', array('controller' => 'Collections'));
$router->map('/groups/i:objectGroupID/:scopeObject/:scopeObjectKey/collections/:objectKey/:subset', array('controller' => 'Collections'));

// Searches within something else
$router->map('/users/i:objectUserID/:scopeObject/:scopeObjectKey/searches/:objectKey/:subset', array('controller' => 'Searches'));
$router->map('/groups/i:objectGroupID/:scopeObject/:scopeObjectKey/searches/:objectKey/:subset', array('controller' => 'Searches'));

// Items within a collection
$router->map('/users/i:objectUserID/collections/:scopeObjectKey/items/top', ['controller' => 'Items', 'extra' => ['scopeObject' => 'collections', 'subset' => 'top']]);
$router->map('/groups/i:objectGroupID/collections/:scopeObjectKey/items/top', ['controller' => 'Items', 'extra' => ['scopeObject' => 'collections', 'subset' => 'top']]);
$router->map('/users/i:objectUserID/collections/:scopeObjectKey/items', ['controller' => 'Items', 'extra' => ['scopeObject' => 'collections']]);
$router->map('/groups/i:objectGroupID/collections/:scopeObjectKey/items', ['controller' => 'Items', 'extra' => ['scopeObject' => 'collections']]);

// Publications
$router->map('/users/i:objectUserID/publications/items/:objectKey/children', ['controller' => 'Items', 'extra' => ['publications' => true, 'subset' => 'children']]);
$router->map('/users/i:objectUserID/publications/items/:objectKey', ['controller' => 'Items', 'extra' => ['publications' => true]]);

// Other top-level URLs, with an optional key and subset
$router->map('/users/i:objectUserID/:controller/:objectKey/:subset');
$router->map('/groups/i:objectGroupID/:controller/:objectKey/:subset');

$router->map('/itemTypes', array('controller' => 'Mappings', 'extra' => array('subset' => 'itemTypes')));
$router->map('/itemTypeFields', array('controller' => 'Mappings', 'extra' => array('subset' => 'itemTypeFields')));
$router->map('/itemFields', array('controller' => 'Mappings', 'extra' => array('subset' => 'itemFields')));
$router->map('/itemTypeCreatorTypes', array('controller' => 'Mappings', 'extra' => array('subset' => 'itemTypeCreatorTypes')));
$router->map('/creatorFields', array('controller' => 'Mappings', 'extra' => array('subset' => 'creatorFields')));
$router->map('/items/new', array('controller' => 'Mappings', 'action' => 'newItem'));

// 4.0 sync warning
$router->map('/login', ['controller' => 'Api', 'action' => 'noop']);

$router->map('/test/setup', array('controller' => 'Api', 'action' => 'testSetup'));

return $router->match($_SERVER['REQUEST_URI']);
