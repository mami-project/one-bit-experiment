#!/usr/bin/awk -f
#
# $0 outfile=<filename> deltafile=<filename> dropfwdfile=<filename> <infile> 

function note_drop(pkt_id) { print pkt_id, "1" >> dropfwdfile }
function note_fwd(pkt_id) { print pkt_id, "0" >> dropfwdfile }
function note_delta(pkt_id, delta) { print pkt_id, delta >> deltafile }

{
  # There is a slight asymmetry here, as the first 'infiled' line is readily
  # available as $0.
  in_row = $0
  out_row = ""

  while (1) {
    # If we don't have a row from 'infile', then try get one.  Stop on EOF or
    # error.
    if (length(in_row) == 0) {
      rc = getline in_row
      if (rc <= 0) {
        exit rc == 0 ? 0 : 1
      }
    }

    split(in_row, in_rec);

    # If this is the first iteration, or if we have consumed a previous
    # 'outfile' row, then pull a new one up (if not at EOF or an error occurred
    # while reading from outfile).
    if (length(out_row) == 0) {
      if ((getline out_row < outfile) > 0) {
        split(out_row, out_rec)
      } else {
        # We have gone through 'outfile', every other remaining 'infile' row
        # goes to the dropped stash
        note_drop(in_rec[1])
        in_row = ""
        continue
      }
    }

    # '{in,out}_rec[1]' is the IP packet id which we need to join
    if (out_rec[1] == in_rec[1]) {
      delta = out_rec[2] - in_rec[2]
      note_delta(in_rec[1], delta)
      note_fwd(in_rec[1])
      out_row = ""
    } else {
      # Join failed, this packet was dropped.
      note_drop(in_rec[1])
      # Don't reset 'out_row', we need it for the next iteration
    }

    in_row = ""
  }
}

# vim: ai ts=2 sw=2 et sts=2
