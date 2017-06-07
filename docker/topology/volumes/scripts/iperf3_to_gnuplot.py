#!/usr/bin/env python

"""
Extract iperf data from json blob and format for gnuplot.
"""

import json
import os
import sys
import argparse

class Iperf3ToGnuplotException(Exception):
    pass

def get_t0(json):
    """Get baseline time in UNIX format"""
    return json['start']['timestamp']['timesecs']

def get_test_type(json):
    return json['start']['test_start']['protocol']

def generate_csv_for_udp_test(json, options):
    """CSV format a UDP report using server view"""
    csv_header = '# {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}\n'.format(
        'reltime',
        'abstime',
        'socket',
        'bytes_transferred',
        'bits_per_second',
        'packets',
        'lost_packets',
        'lost_percent',
        'jitter_ms',
    )
    yield csv_header

    t0 = get_t0(json['server_output_json'])

    for interval in json['server_output_json']['intervals']:
        for stream in interval['streams']:
            abs_ts = t0 + stream['start']
            row = '{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}\n'.format(
                stream['start'],
                abs_ts,
                stream['socket'],
                stream['bytes'],
                stream['bits_per_second'],
                stream['packets'],
                stream['lost_packets'],
                stream['lost_percent'],
                stream['jitter_ms']
            )
            yield row

def generate_csv_for_tcp_test(json, options):
    """CSV format a TCP report using client view"""
    csv_header = '# {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}\n'.format(
        'reltime',
        'abstime',
        'socket',
        'bytes_transferred',
        'bits_per_second',
        'retransmits',
        'snd_cwnd_bytes',
        'rtt_ms'
    )
    yield csv_header

    t0 = get_t0(json)

    for interval in json['intervals']:
        for stream in interval['streams']:
            abs_ts = t0 + stream['start']
            rtt_ms = stream['rtt'] / 1000
            row = '{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}\n'.format(
                stream['start'],
                abs_ts,
                stream['socket'],
                stream['bytes'],
                stream['bits_per_second'],
                stream['retransmits'],
                stream['snd_cwnd'],
                rtt_ms
            )
            yield row

def main():
    """Convert iperf3 reports from JSON to CSV"""
    parser = argparse.ArgumentParser(description='Convert iperf3 reports from JSON to CSV.')
    parser.add_argument('-f', '--file', metavar='FILE',
                       dest='filename',
                       help='Input filename.')
    parser.add_argument('-o', '--output', metavar='OUT',
                       dest='output',
                       help='Optional file to append output to.')
    options = parser.parse_args()

    if not options.filename:
        parser.error('Filename is required.')

    file_path = os.path.normpath(options.filename)

    if not os.path.exists(file_path):
        parser.error('{f} does not exist'.format(f=file_path))

    with open(file_path, 'r') as fh:
        data = fh.read()

    try:
        iperf = json.loads(data)
    except Exception as ex:  # pylint: disable=broad-except
        parser.error('Could not parse JSON from file (ex): {0}'.format(str(ex)))

    if options.output:
        absp = os.path.abspath(options.output)
        output_dir, _ = os.path.split(absp)
        if not os.path.exists(output_dir):
            parser.error('Output file directory path {0} does not exist'.format(output_dir))
        fh = open(absp, 'a')
    else:
        fh = sys.stdout

    test_type = get_test_type(iperf)
    if test_type == "TCP":
        fmt = generate_csv_for_tcp_test
    elif test_type == "UDP":
        fmt = generate_csv_for_udp_test
    else:
        raise Iperf3ToGnuplotException("unknown test type %s" % test_type)

    for i in fmt(iperf, options):
        fh.write(i)


if __name__ == '__main__':
    main()
