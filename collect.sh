#!/bin/bash
#
# Collects information about ephemeral port usage.
#
# The container needs ss and awk:
#   apk add iproute2

set -euo pipefail

# Sets minimal number of ports that have to be used for {local_ip + peer} group
# before showing it in the metrics list.
MIN_COUNT_TO_TRACK="${MIN_COUNT_TO_TRACK:-10}"

min_local_port=$(cut -f 1 /proc/sys/net/ipv4/ip_local_port_range)
max_local_port=$(cut -f 2 /proc/sys/net/ipv4/ip_local_port_range)

# Connections are in this format:
# State   Recv-Q   Send-Q   Local Address:Port   Peer Address::Port
# ESTAB   0        0        10.4.134.246:54060   172.20.0.1:443
fetch_connections() {
  ss --numeric \
     --no-header \
     --ipv4 \
     --tcp \
     state connected "( sport >= :$min_local_port and sport <= :$max_local_port )"
}

format_connection_to_local_ip_with_peer() {
  # Formats connection as "local_ip-peer_ip:peer_port"
  awk -F":|[ \t]+" '{print $4 "-" $6 ":" $7}'
}

print_metrics() {
  # Takes in lines of local ip with peer. We use uniques var to count each
  # occurrence and then print it out in OpenMetrics format
  #
  # This is similar to `sort -u | uniq -c | awk '...'` but using awk for
  # counting is a lot faster.
  awk -v min="$MIN_COUNT_TO_TRACK" '
    { uniques[$1]++ }
    END {
      for(key in uniques)
        if (uniques[key] >= min)
          printf("system_net_used_ports_count{local_ip_with_peer=\"%s\"} %s\n", key, uniques[key])
    }
  '
}

echo "# TYPE system_net_used_ports_max_count gauge"
echo "system_net_used_ports_max_count $((max_local_port-min_local_port))"

echo "# TYPE system_net_used_ports_count gauge"
fetch_connections | \
  format_connection_to_local_ip_with_peer | \
  print_metrics
