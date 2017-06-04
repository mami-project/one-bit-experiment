#!/usr/bin/awk -f
#
# Example record:
# 1496570039.588035872
# qdisc hfsc 1: root refcnt 2 default 999
#  Sent 739715786 bytes 489092 pkt (dropped 3673, overlimits 467858 requeues 0)
#  backlog 0b 0p requeues 0
# qdisc sfq 100: parent 1:100 limit 127p quantum 1500b depth 127 divisor 1024 perturb 10sec
#  Sent 379847332 bytes 250910 pkt (dropped 1808, overlimits 0 requeues 0)
#  backlog 0b 0p requeues 0
# qdisc sfq 200: parent 1:200 limit 127p quantum 1500b depth 127 divisor 1024 perturb 10sec
#  Sent 359825152 bytes 237736 pkt (dropped 1865, overlimits 0 requeues 0)
#  backlog 0b 0p requeues 0
# qdisc sfq 999: parent 1:999 limit 127p quantum 1500b depth 127 divisor 1024 perturb 10sec
#  Sent 43302 bytes 446 pkt (dropped 0, overlimits 0 requeues 0)
#  backlog 0b 0p requeues 0

BEGIN {
  STATE="on-timestamp"

  qdisc[0] = "root"
  qdisc[1] = "lo"
  qdisc[2] = "la"
  qdisc[3] = "default"

  var[0] = "cumulative_sent_bytes"
  var[1] = "cumulative_sent_packets"
  var[2] = "cumulative_dropped_packets"
  var[3] = "backlog_bytes"
  var[4] = "backlog_packets"
  var[5] = "requeues"

  # initialise STATS to all zeroes
  for (i in qdisc) {
    for (j in var) {
      STATS[qdisc[i], var[j]] = "0"
    }
  }

  print_csv_header()
}

function print_csv_header()
{
  csv_header = "# timestamp, "

  for (i in qdisc) {
    for (j in var) {
      csv_header = csv_header qdisc[i] "_" var[j] ", "
    }
  }

  printf("%s\n", csv_header)
}

function print_csv_line()
{
  csv_line = timestamp ", "

  for (i in qdisc) {
    for (j in var) {
      val = STATS[qdisc[i], var[j]]
      csv_line = csv_line val ", "
    }
  }

  printf("%s\n", csv_line)
}

function read_timestamp(ln)
{
  timestamp = ln
}

function parse_qdisc_line_2(qdisc, sent_bytes, sent_packets, dropped_packets)
{
  STATS[qdisc, "cumulative_sent_bytes"] = sent_bytes
  STATS[qdisc, "cumulative_sent_packets"] = sent_packets

  # remove trailing comma
  gsub(",", "", dropped_packets)
  STATS[qdisc, "cumulative_dropped_packets"] = dropped_packets
}

function parse_qdisc_line_3(qdisc, backlog_bytes, backlog_packets, requeues)
{
  # remove trailing 'b'
  gsub("b", "", backlog_bytes)
  STATS[qdisc, "backlog_bytes"] = backlog_bytes
  # remove trailing 'p'
  gsub("p", "", backlog_packets)
  STATS[qdisc, "backlog_packets"] = backlog_packets
  STATS[qdisc, "requeues"] = requeues
}

# main
{
  if (STATE == "on-timestamp") {
    read_timestamp($1)
    STATE = "on-root-qdisc-1"
  } else if (STATE == "on-root-qdisc-1") {
    STATE = "on-root-qdisc-2"
  } else if (STATE == "on-root-qdisc-2") {
    parse_qdisc_line_2("root", $2, $4, $7)
    STATE = "on-root-qdisc-3"
  } else if (STATE == "on-root-qdisc-3") {
    parse_qdisc_line_3("root", $2, $3, $5)
    STATE = "on-la-qdisc-1"
  } else if (STATE == "on-la-qdisc-1") {
    STATE = "on-la-qdisc-2"
  } else if (STATE == "on-la-qdisc-2") {
    parse_qdisc_line_2("la", $2, $4, $7)
    STATE = "on-la-qdisc-3"
  } else if (STATE == "on-la-qdisc-3") {
    parse_qdisc_line_3("la", $2, $3, $5)
    STATE = "on-lo-qdisc-1"
  } else if (STATE == "on-lo-qdisc-1") {
    STATE = "on-lo-qdisc-2"
  } else if (STATE == "on-lo-qdisc-2") {
    parse_qdisc_line_2("lo", $2, $4, $7)
    STATE = "on-lo-qdisc-3"
  } else if (STATE == "on-lo-qdisc-3") {
    parse_qdisc_line_3("lo", $2, $3, $5)
    STATE = "on-default-qdisc-1"
  } else if (STATE == "on-default-qdisc-1") {
    STATE = "on-default-qdisc-2"
  } else if (STATE == "on-default-qdisc-2") {
    parse_qdisc_line_2("default", $2, $4, $7)
    STATE = "on-default-qdisc-3"
  } else if (STATE == "on-default-qdisc-3") {
    parse_qdisc_line_3("default", $2, $3, $5)
    print_csv_line()
    STATE = "on-timestamp"
  }
}

# vim: ai ts=2 sw=2 et sts=2 ft=awk


