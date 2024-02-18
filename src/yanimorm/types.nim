import std/[
  strutils,
  options,
]

export options



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
    ids*: Option[seq[string]]

proc toBool*(v: string): bool {.inline.} =
  v.toLowerAscii != "0"

proc fromBool*(v: bool): string {.inline.} =
  if v: "1" else: "0"
