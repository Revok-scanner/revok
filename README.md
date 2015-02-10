# Revok

## Introduction
Revok is an online self-service web app security scanner, finding common web security issues with minimal cost. If you are unsure of the security of your application, enter its URL into the Revok scanner and a diagnosis of the sites security will follow. Copyright © 2014 Revok Team, released under the GNU AGPLv3.

## Download
The binary version which has self-contained operating environment can be downloaded from [Revok homepage](http://revok-scanner.github.io/revok).
The source code can be cloned from [Revok git repo](https://github.com/Revok-scanner/revok).

## Architecture overview
###  Components
Revok consists of the following components. They can be deployed in both centralized (single node) and distributed (multiple nodes) environment.

* Web console  
Revok web console provides the user interface for submitting scan tasks.

* REST API  
Revok REST APIs are defined to receive and handle requests from the web console.

* Messaging server  
Messaging server stores scan requests and distributes them to Caroline nodes. When requests were received, new messages would be produced and kept in a queue until Caroline nodes consume messages from the queue.

* Caroline nodes  
Revok Caroline nodes (working nodes) run scans with a group of testing modules and generate final scan reports.

* Database  
Details for all scan tasks are recorded in the database. It can be used for data query or statistic.

### Communication among components
The messaging flow among Revok components is as below.
![Alt text](http://revok-scanner.github.io/revok/images/revok_arch.png)

## Quick start guide (all in one)
Step 1: download and decompress the binary package
```
$ wget http://example.com
$ tar xJvf revok-0.8.1_x86_64.tar.xz
```
Step 2: initialize Revok
```
$ cd revok-0.8.1_x86_64
$ ./revokd init
```
Step 3: run Revok
```
$ ./revokd start
```
Other commands for revokd:
```
$ ./revokd
Usage: ./revokd {init|start|stop|status|restart}
```
Step 4: access the web console to submit a scan at <http://localhost:3030>

## Use Revok to scan a target
Step 1: input a target URL to be scanned

Step 2: provide authentication information

Step 3: confirm and submit

Step 4: monitor scan progress from log file (var/log/carolined.log) and check report (report/report_$time.html) when scan is finished


## Deploy Revok with source code
You can deploy web console, REST API server, messaging server, Caroline nodes (working nodes) and database server on the same host or separated hosts. In addition, you can add more than one working nodes to support parallel scans. Please refer to the installation guide for detailed steps to deploy Revok with source code.

## Documents
Find more documents in [docs directory](https://github.com/Revok-scanner/revok/tree/master/docs).

## Issues tracker
Issues for Revok is listed at [issues page](https://github.com/Revok-scanner/revok/issues).


## Contact us
* Mailing lists  
[revok-scanner-users@googlegroups.com](https://groups.google.com/forum/#!forum/revok-scanner-users/join) (for users)
[revok-scanner-devel@googlegroups.com](https://groups.google.com/forum/#!forum/revok-scanner-devel/join) (for developers)
[revok-scanner-announce@googlegroups.com](https://groups.google.com/forum/#!forum/revok-scanner-announce/join) (for release announcement)

* IRC discussion  
`#revok-scanner` (irc.freenode.net/6665)
