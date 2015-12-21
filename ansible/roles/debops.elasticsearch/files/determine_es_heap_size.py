#!/usr/bin/python

'''
This script is used to determine the ES_HEAP_SIZE on a 
ElasticSearch server during installation. 

It queries the total memory from /proc/meminfo, then does
calculations to determine a sane ES_HEAP_SIZE value. 

It is designed to be called by Ansible and have the value be set
via a Jinja template. 
'''

import re

# Pattern matching 'MemTotal:        1016984 kB'
pattern = '^MemTotal:\s+([0-9]+)\skB'
regex = re.compile(pattern)
meminfo = ''

# read in /proc/meminfo
try:
    with open('/proc/meminfo', 'r') as f:
        meminfo = f.read()
except IOError:
    pass

# find MemTotal value from /proc/meminfo
results = regex.findall(meminfo)

if results:
    
    # turn result into an int
    mem_total_kilobytes = int(results[0])

    # 1048576 kB = 1GB
    if mem_total_kilobytes < 1048576:
        # mem less than 1G of mem, set ES_HEAP_SIZE to 
        # 256mb
        print("256m")
    # if total mem between 1gb and 2gb, use 25% for ES        
    elif mem_total_kilobytes >= 1048576 and mem_total_kilobytes <= 2097152:
        calculated_value = ( int(round((mem_total_kilobytes * .25) / 1024)))
        print("{0}m".format(calculated_value))
    # if total mem between 2gb and 59.5 gb, use 50% for ES
    elif mem_total_kilobytes >= 2097153 and mem_total_kilobytes <= 62390272:
        calculated_value = ( int(round((mem_total_kilobytes * .50) / 1024)))
        print("{0}m".format(calculated_value))
    # if total mem over 59.5 GB, set max value at 30.5 GB
    # https://goo.gl/ilHkld
    else:
        print("30500m")

else:
    # /proc/meminfo can't be read, set ES_HEAP_SIZE to 256mb
    print("256m")

