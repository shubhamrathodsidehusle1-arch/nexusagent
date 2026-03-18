/// NexusAgent Database Service
/// SQLite local storage

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  /// Initialize database
  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nexusagent.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    print('Database initialized: $path');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        role TEXT DEFAULT 'member',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Agents table
    await db.execute('''
      CREATE TABLE agents (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        model TEXT,
        tools TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Channels table
    await db.execute('''
      CREATE TABLE channels (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        enabled INTEGER DEFAULT 1,
        config TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        agent_id TEXT,
        channel TEXT,
        sender_id TEXT,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        FOREIGN KEY (agent_id) REFERENCES agents(id)
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        session_id TEXT,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions(id)
      )
    ''');

    // Workflows table
    await db.execute('''
      CREATE TABLE workflows (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        nodes TEXT,
        enabled INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Cron jobs table
    await db.execute('''
      CREATE TABLE cron_jobs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        schedule TEXT NOT NULL,
        task TEXT NOT NULL,
        params TEXT,
        enabled INTEGER DEFAULT 1,
        last_run TEXT,
        next_run TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    print('Database tables created');
  }

  // ============ Users ============

  Future<int> insertUser(Map<String, dynamic> user) async {
    return await _db!.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUser(String id) async {
    final results = await _db!.query('users', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final results = await _db!.query('users', where: 'email = ?', whereArgs: [email]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    return await _db!.query('users');
  }

  Future<int> updateUser(String id, Map<String, dynamic> user) async {
    return await _db!.update('users', user, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(String id) async {
    return await _db!.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Agents ============

  Future<int> insertAgent(Map<String, dynamic> agent) async {
    return await _db!.insert('agents', agent);
  }

  Future<Map<String, dynamic>?> getAgent(String id) async {
    final results = await _db!.query('agents', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getAgents() async {
    return await _db!.query('agents', orderBy: 'created_at DESC');
  }

  Future<int> updateAgent(String id, Map<String, dynamic> agent) async {
    return await _db!.update('agents', agent, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAgent(String id) async {
    return await _db!.delete('agents', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Channels ============

  Future<int> insertChannel(Map<String, dynamic> channel) async {
    return await _db!.insert('channels', channel);
  }

  Future<Map<String, dynamic>?> getChannel(String id) async {
    final results = await _db!.query('channels', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getChannels() async {
    return await _db!.query('channels', orderBy: 'created_at DESC');
  }

  Future<int> updateChannel(String id, Map<String, dynamic> channel) async {
    return await _db!.update('channels', channel, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteChannel(String id) async {
    return await _db!.delete('channels', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Sessions ============

  Future<int> insertSession(Map<String, dynamic> session) async {
    return await _db!.insert('sessions', session);
  }

  Future<List<Map<String, dynamic>>> getSessions({int limit = 50}) async {
    return await _db!.query('sessions', orderBy: 'started_at DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    return await _db!.query('sessions', where: 'ended_at IS NULL');
  }

  Future<int> endSession(String id) async {
    return await _db!.update(
      'sessions',
      {'ended_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ Messages ============

  Future<int> insertMessage(Map<String, dynamic> message) async {
    return await _db!.insert('messages', message);
  }

  Future<List<Map<String, dynamic>>> getMessages(String sessionId, {int limit = 100}) async {
    return await _db!.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // ============ Workflows ============

  Future<int> insertWorkflow(Map<String, dynamic> workflow) async {
    return await _db!.insert('workflows', workflow);
  }

  Future<Map<String, dynamic>?> getWorkflow(String id) async {
    final results = await _db!.query('workflows', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getWorkflows() async {
    return await _db!.query('workflows', orderBy: 'created_at DESC');
  }

  Future<int> updateWorkflow(String id, Map<String, dynamic> workflow) async {
    return await _db!.update('workflows', workflow, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteWorkflow(String id) async {
    return await _db!.delete('workflows', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Cron Jobs ============

  Future<int> insertCronJob(Map<String, dynamic> job) async {
    return await _db!.insert('cron_jobs', job);
  }

  Future<List<Map<String, dynamic>>> getCronJobs() async {
    return await _db!.query('cron_jobs', orderBy: 'created_at DESC');
  }

  Future<int> updateCronJob(String id, Map<String, dynamic> job) async {
    return await _db!.update('cron_jobs', job, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCronJob(String id) async {
    return await _db!.delete('cron_jobs', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Settings ============

  Future<void> setSetting(String key, String value) async {
    await _db!.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final results = await _db!.query('settings', where: 'key = ?', whereArgs: [key]);
    return results.isNotEmpty ? results.first['value'] as String : null;
  }

  // ============ Analytics ============

  Future<Map<String, dynamic>> getAnalytics() async {
    final agents = await getAgents();
    final channels = await getChannels();
    final sessions = await getSessions(limit: 1000);
    final activeSessions = await getActiveSessions();

    int totalMessages = 0;
    for (final session in sessions) {
      final messages = await getMessages(session['id'] as String);
      totalMessages += messages.length;
    }

    return {
      'totalAgents': agents.length,
      'activeAgents': agents.where((a) => a['status'] == 'active').length,
      'totalChannels': channels.length,
      'activeChannels': channels.where((c) => c['enabled'] == 1).length,
      'totalSessions': sessions.length,
      'activeSessions': activeSessions.length,
      'totalMessages': totalMessages,
    };
  }

  /// Close database
  Future<void> close() async {
    await _db?.close();
  }
}
