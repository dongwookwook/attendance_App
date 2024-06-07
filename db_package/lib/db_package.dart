library db_package;

import 'package:mysql_client/mysql_client.dart';

class DBPackage {
  MySQLConnection? _conn;

  Future<void> connect() async {
    _conn = await MySQLConnection.createConnection(
      host: 'database-1.c94ekcsyeo6o.us-east-2.rds.amazonaws.com',
      port: 3306,
      userName: 'admin',
      password: '04040404',
      databaseName: 'student_information',
    );
    await _conn!.connect();
  }

  Future<Map<String, dynamic>?> getDataByStudentId(String studentId) async {
    var result = await _conn!.execute(
      "SELECT * FROM student WHERE student_id = :value",
      {"value": studentId},
    );
    if (result.rows.isNotEmpty) {
      return result.rows.first.assoc();
    } else {
      return null;
    }
  }

  Future<void> close() async {
    await _conn?.close();
  }
}
