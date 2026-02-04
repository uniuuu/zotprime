<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\GroupController;

// Authentication routes
Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'login']);
Route::get('/2fa', [AuthController::class, 'show2fa'])->name('2fa');
Route::post('/2fa', [AuthController::class, 'verify2fa']);
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

// Protected routes (require authentication)
Route::middleware('auth')->group(function () {
    Route::get('/', [UserController::class, 'dashboard'])->name('dashboard');
    
    // User management
    Route::get('/users', [UserController::class, 'index'])->name('users.index');
    Route::post('/users', [UserController::class, 'create'])->name('users.create');
    Route::post('/users/{id}/disable', [UserController::class, 'disable'])->name('users.disable');
    Route::post('/users/{id}/enable', [UserController::class, 'enable'])->name('users.enable');
    Route::post('/users/{id}/quota', [UserController::class, 'setQuota'])->name('users.quota');
    
    // Group management
    Route::get('/groups', [GroupController::class, 'index'])->name('groups.index');
    Route::post('/groups', [GroupController::class, 'create'])->name('groups.create');
    Route::delete('/groups/{id}', [GroupController::class, 'delete'])->name('groups.delete');
    Route::post('/groups/{id}/members', [GroupController::class, 'addMember'])->name('groups.addMember');
    Route::delete('/groups/{id}/members/{userId}', [GroupController::class, 'removeMember'])->name('groups.removeMember');
});
