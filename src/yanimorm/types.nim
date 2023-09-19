import std/[
  strutils,
]

type
  Po* = seq[string]

type
  TimeRange* = tuple
    fromTime, toTime: int64

type
  DateRange* = tuple
    fromDate, toDate: string

type
  ListOptions* = ref object of RootObj
    page*: int
    pageSize*: int = 10

proc toBool*(v: string): bool {.inline.} =
  v.toLowerAscii == "true"

proc fromBool*(v: bool): string {.inline.} =
  if v: "true" else: "false"
