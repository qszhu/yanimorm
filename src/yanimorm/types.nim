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
    page*, pageSize*: int
