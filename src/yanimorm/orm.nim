import std/[
  sequtils,
  strformat,
  strutils,
]

export sequtils



type FieldType* = enum
  INTEGER = "INTEGER"
  REAL = "REAL"
  TEXT = "TEXT"

type
  DbField* = ref object
    name*: string
    fieldType*: FieldType
    isPrimary*: bool
    isUnique*: bool
    isNull*: bool
    isIndex*: bool

  DbTable* = ref object
    name*: string
    fields*: seq[DbField]

  DbQuery* = tuple
    sql: string
    args: seq[string]

proc newDbQuery*(sql: string, args: seq[string] = @[]): DbQuery {.inline.} =
  (sql, args)

proc fieldNames*(self: DbTable, excludeId = false): seq[string] {.inline.} =
  if excludeId:
    self.fields.filterIt(it.name != "id").mapIt(it.name)
  else:
    self.fields.mapIt(it.name)

proc dropTableQuery*(self: DbTable): DbQuery {.inline.} =
  newDbQuery(&"DROP TABLE IF EXISTS {self.name}")

proc createIndexQuery*(self: DbTable): seq[DbQuery] {.inline.} =
  self.fields.filterIt(it.isIndex)
    .mapIt(newDbQuery(&"CREATE INDEX idx_{self.name}_{it.name} ON {self.name}({it.name})"))

proc createTableQuery*(self: DbTable): seq[DbQuery] =
  proc createTableFieldClause(self: DbField): string =
    var res = @[self.name, $(self.fieldType)]
    if self.isPrimary:
      res.add "PRIMARY KEY"
    else:
      if self.isNull:
        res.add "NULL"
      else:
        res.add "NOT NULL"
    res.join " "

  var fields = self.fields.mapIt(it.createTableFieldClause).join(", ")
  let uniques = self.fields.filterIt(it.isUnique).mapIt(it.name)
  if uniques.len > 0:
    fields &= ", UNIQUE(" & uniques.join(", ") & ")"
  newDbQuery(&"CREATE TABLE {self.name} ({fields})") & self.createIndexQuery

proc insertQuery*(self: DbTable, po: seq[string]): DbQuery =
  let fieldNames = self.fieldNames.join(", ")
  let fieldPlaceholders = "?".repeat(self.fields.len).join(", ")
  let sql = &"INSERT INTO {self.name} ({fieldNames}) values ({fieldPlaceholders})"
  newDbQuery(sql, po)

proc updateQuery*(self: DbTable, po: seq[string]): DbQuery =
  let fields = self.fieldNames(excludeId = true)
  let setFields = fields.mapIt(it & " = ?").join(", ")
  let sql = &"UPDATE {self.name} SET {setFields} WHERE id = ?"
  let args = po[1 .. ^1] & po[0]
  newDbQuery(sql, args)



type
  WhereExpr* = ref object of RootObj
    name: string

  EqualsExpr = ref object of WhereExpr
    val: string

  LessThanExpr = ref object of WhereExpr
    val: string

  LikeExpr = ref object of WhereExpr
    val: string

  InExpr = ref object of WhereExpr
    vals: seq[string]

  BetweenExpr = ref object of WhereExpr
    a, b: string

  UnaryExpr = ref object of WhereExpr
    exp: WhereExpr

  NotExpr = ref object of UnaryExpr

  BinaryExpr = ref object of WhereExpr
    lhs, rhs: WhereExpr

  AndExpr = ref object of BinaryExpr

  OrExpr = ref object of BinaryExpr

  TrueExpr = ref object of WhereExpr

  FalseExpr = ref object of WhereExpr

method query*(self: WhereExpr): DbQuery {.base.} =
  discard

method query*(self: EqualsExpr): DbQuery =
  newDbQuery(&"{self.name} = ?", @[self.val])

method query*(self: LessThanExpr): DbQuery =
  newDbQuery(&"{self.name} < ?", @[self.val])

method query*(self: LikeExpr): DbQuery =
  newDbQuery(&"{self.name} LIKE ?", @[self.val])

method query*(self: InExpr): DbQuery =
  let placeHolders = "?".repeat(self.vals.len).join(", ")
  newDbQuery(&"{self.name} IN ({placeHolders})", self.vals)

method query*(self: BetweenExpr): DbQuery =
  newDbQuery(&"{self.name} BETWEEN ? AND ?", @[self.a, self.b])

method query*(self: NotExpr): DbQuery =
  let (sql, args) = self.exp.query
  newDbQuery(&"NOT ({sql})", args)

method query*(self: AndExpr): DbQuery =
  let (sql1, args1) = self.lhs.query
  let (sql2, args2) = self.rhs.query
  newDbQuery(&"({sql1}) AND ({sql2})", args1 & args2)

method query*(self: OrExpr): DbQuery =
  let (sql1, args1) = self.lhs.query
  let (sql2, args2) = self.rhs.query
  newDbQuery(&"({sql1}) OR ({sql2})", args1 & args2)

method query*(self: TrueExpr): DbQuery =
  newDbQuery("1 = 1")

method query*(self: FalseExpr): DbQuery =
  newDbQuery("1 != 1")

let TRUE* = TrueExpr()
let FALSE* = FalseExpr()

proc `===`*(name, val: string): EqualsExpr =
  result.new
  result.name = name
  result.val = val

proc `===`*(name: string, val: int): EqualsExpr =
  result.new
  result.name = name
  result.val = $val

proc `===`*(name: string, val: bool): EqualsExpr =
  result.new
  result.name = name
  result.val = if val: "1" else: "0"

proc `<<`*(name, val: string): LessThanExpr =
  result.new
  result.name = name
  result.val = val

proc `and`*(a, b: WhereExpr): AndExpr =
  result.new
  result.lhs = a
  result.rhs = b

proc `between`*(name, a, b: string): BetweenExpr =
  result.new
  result.name = name
  result.a = a
  result.b = b

proc `like`*(name, val: string): LikeExpr =
  result.new
  result.name = name
  result.val = val

proc `in`*(name: string, vals: seq[string]): InExpr =
  result.new
  result.name = name
  result.vals = vals



type Order* = enum
  ASC = "ASC"
  DESC = "DESC"



type
  SelectQuery* = ref object
    table: DbTable
    where: WhereExpr
    orderBy: seq[tuple[name: string, order: Order]]
    offset, limit: int

proc newSelectQuery*(table: DbTable): SelectQuery =
  result.new
  result.table = table
  result.where = TRUE
  result.limit = -1

proc where*(self: SelectQuery, where: WhereExpr): SelectQuery =
  self.where = where
  self

proc orderBy*(self: SelectQuery, name: string, order: Order): SelectQuery =
  self.orderBy.add (name, order)
  self

proc offset*(self: SelectQuery, offset: int): SelectQuery =
  self.offset = offset
  self

proc limit*(self: SelectQuery, limit: int): SelectQuery =
  self.limit = limit
  self

proc query*(self: SelectQuery): DbQuery =
  let fields = self.table.fieldNames.join(", ")
  let (whereSql, whereArgs) = self.where.query

  var sql = &"SELECT {fields} FROM {self.table.name} WHERE {whereSql}"

  if self.orderBy.len > 0:
    let orders = self.orderBy.mapIt(&"{it[0]} {it[1]}").join(", ")
    sql &= &" ORDER BY {orders}"

  sql &= &" LIMIT {self.limit} OFFSET {self.offset}"

  let args = whereArgs
  newDbQuery(sql, args)
