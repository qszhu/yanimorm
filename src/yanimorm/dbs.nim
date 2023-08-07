import std/[
  logging,
]
import db_connector/[
  db_sqlite,
]

import ./orm



type
  DbEngine* = ref object of RootObj

method close*(self: DbEngine) {.base.} =
  discard

method exec*(self: DbEngine, query: DbQuery) {.base.} =
  discard

method exec*(self: DbEngine, queries: seq[DbQuery]) {.base.} =
  for query in queries:
    self.exec query

method begin*(self: DbEngine) {.base.} =
  discard

method rollback*(self: DbEngine) {.base.} =
  discard

method commit*(self: DbEngine) {.base.} =
  discard

method resetTable*(self: DbEngine, schema: DbTable) {.base.} =
  self.exec schema.dropTableQuery
  self.exec schema.createTableQuery

method getRow*(self: DbEngine, query: DbQuery): Row {.base.} =
  discard

method getRows*(self: DbEngine, query: DbQuery): seq[Row] {.base.} =
  discard



type
  Sqlite3Engine* = ref object of DbEngine
    conn: DbConn

proc newSqlite3Engine*(connection: string, user = "", password = "", database = ""): Sqlite3Engine =
  result.new
  result.conn = open(connection, user, password, database)

method close*(self: Sqlite3Engine) =
  self.conn.close

method exec*(self: Sqlite3Engine, query: DbQuery) =
  logging.debug query
  self.conn.exec(query.sql.sql, query.args)

method begin*(self: Sqlite3Engine) =
  self.conn.exec sql"BEGIN"

method rollback*(self: Sqlite3Engine) =
  self.conn.exec sql"ROLLBACK"

method commit*(self: Sqlite3Engine) =
  self.conn.exec sql"COMMIT"

method getRow*(self: Sqlite3Engine, query: DbQuery): Row =
  logging.debug query
  self.conn.getRow(query.sql.sql, query.args)

method getRows*(self: Sqlite3Engine, query: DbQuery): seq[Row] =
  logging.debug query
  for row in self.conn.rows(query.sql.sql, query.args):
    result.add row
