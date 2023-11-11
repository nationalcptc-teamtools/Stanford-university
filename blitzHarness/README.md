# nmapHarness
cptc blitz scan harness

DESC:

This script runs optimizes netowrk discovery by doing 4 different types of sweeps to catch hosts behind different types of firewalls, narrows the host list to just live hosts instead of the whole subnet, then determines which ports are open, and then from those ports does an 'nmap -sVC -A' scan for all non-brittle portrs.  Each action has parallelization via background process in order to optimize the time efficecny of the script - this does mean that there is a large spike in network traffic each time a script is run, so note that this script is not sneaky, but very fast.

USAGE:

./parallelDiscovery.sh \
./parallelPorts.sh \
./brittleDepth.sh

KNOWN ISSUES:

Brittle Depth does not properly wait for nmap to return even with wait call - workable as long as you just 
leave the terminal untouched until final ip's run is complete.

TODO:

- Add speed decrease option for known brittle subnets.
- Potentially fix known issues.
- If desired, pipe into nmapAutomater for nonbrittle hosts.
- UDP?
- More than top 1000 ports?

