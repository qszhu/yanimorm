type
  Po* = seq[string]

type
  TimeRange* = tuple
    fromTime, toTime: int64

type
  ListOptions* = ref object of RootObj
    page*, pageSize*: int
