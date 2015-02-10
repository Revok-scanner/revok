# Installation Guide

## 1 Deployment
### 1.1 Start Revok with binary package
Step 1: download and decompress the binary package (http://revok-scanner.github.io/revok/)
```
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
Step 4: access the web console to submit a scan at <http://localhost:3030>

### 1.2 Deploy Revok with source code
Web console, REST API server, messaging server, Caroline nodes (working nodes) and database server can be deployed in both **centralized** (single node) and **distributed** (multiple nodes) environment. In addition, you can add more than one working nodes to support parallel scans.

### 1.2.1 Preparation
* Get source code  
The source code can be got from  [Revok git repo](https://github.com/Revok-scanner/revok). Clone it for each node in distributed environment.
* DNS settings [Optional]  
Add mapping of hostnames and IP addresses to the /etc/hosts file in distributed environment when hostnames are used to communicate.

### 1.2.2 Database server
PostgreSQL is the storage for Revok history data. Other database options may be added in the future.

Step 1: install and initialize PostgreSQL  
Download and install the suitable version of PostgreSQL for your OS (refer to <http://www.postgresql.org/download/>). Edit configuration file to set the listening IP address and port.
```
$ yum install -y postgresql-server postgresql
$ postgresql-setup initdb
$ vi /var/lib/pgsql/data/postgresql.conf
listen_addresses = '*'
port = 5432
$ systemctl enable postgresql.service
```
SSL configuration [Optional]  
a. Create self-signed certificate and private key for the server, then edit configuration file.
```
$ vi /var/lib/pgsql/data/postgresql.conf
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
```
b. Get the certificate and move it to ~/.postgresql/ on Caroline and REST nodes.
```
$ echo -n | openssl s_client -connect pg.example.com:5432 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > root.crt
```
Step 2: create user and database  
Start PostgreSQL service. Create database "revok_db" and user "revok".
```
$ systemctl start postgresql.service
$ su - postgres
$ psql
postgres=# create database revok_db;
postgres=# create user revok with password 'password';
```
Step 3: configure client authentication  
Edit the configuration file for client authentication. Apply MD5 authentication to revok user and restart the service.
```
$ vi /var/lib/pgsql/data/pg_hba.conf
# Add the following line in # IPv4 local connections section
host revok_db revok 0.0.0.0/0 md5
$ systemctl restart postgresql.service
```
Step 4: add iptables rule
```
# iptables -I INPUT 1 -p tcp -m tcp --dport 5432 -j ACCEPT
```

### 1.2.3 Message queue server
ActiveMQ works as the messaging server in Revok.

Step 1: install ActiveMQ  
Download from <http://activemq.apache.org/download.html> and unpack.
```
$ tar xzvf apache-activemq-5.10.0-bin.tar.gz
```
Step 2: configure ActiveMQ  
Edit configuration file to add authentication plugin, then start ActiveMQ service.
```
$ vi apache-activemq-5.10.0/conf/activemq.xml
<!-- Add the following lines in <broker></broker> section -->
<plugins>
    <simpleAuthenticationPlugin>
        <users>
            <authenticationUser username="caroline" password="password" groups="users"/>
        </users>
    </simpleAuthenticationPlugin>
</plugins>
$ apache-activemq-5.10.0/bin/activemq start
```
SSL configuration [Optional]   
a. Create certificate for the server (refer to http://activemq.apache.org/how-do-i-use-ssl.html), then edit configuration file.
```
$ vi apache-activemq-5.10.0/conf/activemq.xml
<!-- Add the following lines in <broker></broker> section -->
<transportConnectors>
    <transportConnector name="stomp+ssl" uri="stomp+ssl://0.0.0.0:61613"/>
</transportConnectors>
<sslContext>
    <sslContext keyStore="file:${activemq.conf}/broker.ks"
    keyStorePassword="${keystore.password}"/>
</sslContext>
```
b. Get the certificate and move it to activemq/ on Caroline and REST nodes.
```
$ echo -n | openssl s_client -connect activemq.example.com:61613 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > queue.pem
```
Step 3: add iptables rule
```
# iptables -I INPUT 1 -p tcp -m tcp --dport 61613 -j ACCEPT
```

### 1.2.4 REST API server

Step 1: copy files to server  
a. Making a basic directory on server.
```
$ mkdir -p revok/var/log
$ mkdir -p revok/var/pid
$ mkdir -p revok/var/lock
$ mkdir -p revok/var/run
```
b. Copying the files of directories below from source code package to "revok" folder on server
- bin/
- conf/
- rest/
- Gemfile

Step 2: prepare dependent packages  
The list of basic packages required by REST API server.
- ruby (>=2.1.0)
- ruby-devel
- rubygems

The list of required gems.
- bundle
- see 'Gemfile' for others
```
$ yum install -y ruby rubygems
$ gem install bundle
$ cd revok
$ bundle install
```
Step 3: update settings in the [global configuration file](https://github.com/Revok-scanner/revok/blob/master/conf/revok.conf)
```
# ActiveMQ config
MSG_QUEUE_USER=caroline
MSG_QUEUE_PASSWORD=password
MSG_QUEUE_HOST=queue.example.com
MSG_QUEUE_PORT=61613

# REST config
REST_USER=revok
REST_PASSWORD=password
REST_PORT=8443

# Log level
LOG=info
```
SSL configuration [Optional]  
a. Create self-signed certificate and private key for the server, then edit file [rest/rest_served.rb](https://github.com/Revok-scanner/revok/blob/master/rest/rest_served.rb).
```
$ vi rest/rest_served.rb
pkey = OpenSSL::PKey::RSA.new(File.open("#{REST_PATH}/revok.key",'r').read)
cert = OpenSSL::X509::Certificate.new(File.open("#{REST_PATH}/revok.crt",'r').read)
s = HTTPServer.new(
  :Port => port,
  :BindAddress => "0.0.0.0"
  :SSLEnable => true,
  :SSLCertificate => cert,
  :SSLPrivateKey => pkey,
)
```
b. Get the certificate and move it to webconsole/ on webconsole node, then modify [webconsole/config.ru](https://github.com/Revok-scanner/revok/blob/master/webconsole/config.ru).
```
$ echo -n | openssl s_client -connect rest.example.com:8443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' >revok.crt
$ vi webconsole/config.ru
$revok_http = lambda {
  uri = URI.parse("http://rest.example.com:8443")
  http = Net::HTTP.new(uri.host, uri.port)
  # If you want to enable SSL, make the below lines functional
  http.use_ssl = true
  http.ca_file = "revok.crt"
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http
}
```
Step 4: set environment variables that defined in the global configuration file
```
$ cd revok
$ source bin/setenv.sh
```
Step 5: start rest-served
```
$ rest/rest-served start
```
Step 6: add iptables rule
```
# iptables -I INPUT 1 -p tcp -m tcp --dport 8443 -j ACCEPT
```

### 1.2.5 Caroline nodes

Step 1: copy files to server  
a. Making a basic directory on server.
```
$ mkdir -p revok/var/log
$ mkdir -p revok/var/pid
$ mkdir -p revok/var/lock
$ mkdir -p revok/var/run
$ mkdir -p revok/report
```
b. Copying the files of directories below from source code package to "revok" folder on server
- bin/
- conf/
- caroline/
- db/
- Gemfile

Step 2: prepare dependent packages  
All dependent packages of REST API Server are required. Other dependency is as below.
- python (>=2.6)
- [pip](https://pip.pypa.io/en/latest/installing.html)
- [mitmdump](http://mitmproxy.org/doc/install.html)
- [phantomjs](http://phantomjs.org/download.html)
- ImageMagick
- openssl
- sslscan
- expect
- zip
- ruby (>=2.1.0)
- ruby-devel
- rubygems
- bundle
```
$ yum install -y ruby rubygems
$ gem install bundle
$ cd revok
$ bundle install
$ yum install -y python ImageMagick openssl sslscan expect
$ wget https://bootstrap.pypa.io/get-pip.py
$ python get-pip.py
$ pip install mitmproxy
$ wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.7-linux-x86_64.tar.bz2
$ tar xjvf phantomjs-1.9.7-linux-x86_64.tar.bz2
$ cp phantomjs-1.9.7-linux-x86_64/bin/phantomjs /usr/bin/
```

Step 3: update settings in the [global configuration file](https://github.com/Revok-scanner/revok/blob/master/conf/revok.conf)  
A SMTP server is needed to send scan reports to users.
```
# Report config
USE_SMTP=on
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_USER=username
SMTP_PASSWORD=password
EMAIL_ADDRESS=revok@example.com

# DB config
DB_TYPE=postgresql
DB_USER=revok
DB_PASSWORD=password
DB_HOST=db.example.com
DB_NAME=revok_db
DB_PORT=5435
DB_SSL=enable

# ActiveMQ config
MSG_QUEUE_USER=caroline
MSG_QUEUE_PASSWORD=password
MSG_QUEUE_HOST=queue.example.com
MSG_QUEUE_PORT=61613

# Log level
LOG=info
```
Step 4: set environment variables that defined in the global configuration file
```
$ cd revok
$ source bin/setenv.sh
```
Step 5: initialize the database
```
$ ruby db/db_init.rb
```
Step 6: start carolined
```
$ caroline/carolined start
```
### 1.2.6 Web console

* Start by WEBrick

Step 1: copy files to server  
a. Making a basic directory on server.
```
$ mkdir -p revok/var/log
$ mkdir -p revok/var/pid
$ mkdir -p revok/var/lock
$ mkdir -p revok/var/run
```
b. Copying the files of directories below from source code package to "revok" folder on server
- bin/
- conf/
- webconsole/
- Gemfile

Step 2: prepare dependent packages  
The list of basic packages required by REST API server.
- ruby (>=2.1.0)
- ruby-devel
- rubygems

The list of required gems.
- bundle
- see 'Gemfile' for others
```
$ yum install -y ruby rubygems
$ gem install bundle
$ cd revok
$ bundle install
```
Step 3: update web settings in the [global configuration file](https://github.com/Revok-scanner/revok/blob/master/conf/revok.conf)
```
# Web UI config
WEB_PORT=3030
```
Step 4: set environment variables that defined in the global configuration file
```
$ cd revok
$ source bin/setenv.sh
```
Step 5: start rackd
```
$ cd revok
$ webconsole/rackd start
```
Step 6: add iptables rule
```
# iptables -I INPUT 1 -p tcp -m tcp --dport 3030 -j ACCEPT
```
* Start Apache HTTP server

Step 1: prepare dependent packages  
All dependent packages of REST API Server are required. Other dependency is as below.
The list of required packages.
- httpd

The list of required gems.
- passenger
```
$ yum install -y httpd
$ gem install passenger
$ passenger-install-apache-module
```
Step 2: copy code to httpd data directory
```
$ cp -r revok/webconsole /var/www/html/revok
$ ln -s /var/www/html/revok/public /var/www/html/scanner
```
Step 3: configure httpd  
Add loadmodule option for passenger and vhost setting for the application to httpd.conf, then start httpd service.
```
$ vi /etc/httpd/conf/httpd.conf
(Add the following lines)
LoadModule passenger_module /usr/local/gems/ruby-1.9.3-p547/gems/passenger-4.0.48/buildout/apache2/mod_passenger.so
<IfModule mod_passenger.c>
    PassengerRoot /usr/local/gems/ruby-1.9.3-p547/gems/passenger-4.0.48
    PassengerDefaultRuby /usr/local/gems/ruby-1.9.3-p547/wrappers/ruby
</IfModule>
<VirtualHost *:3030>
    ServerName localhost
    RewriteEngine on
    RewriteRule ^/$ scanner/html/ [R]
    PassengerAppRoot /var/www/html/revok/public
    <Directory /var/www/html/revok/public>
        AllowOverride all
        Options -MultiViews
        Require all granted
        Order allow,deny
        Allow from all
    </Directory>
</VirtualHost>
$ systemctl start httpd.service
```
SSL configuration [Optional]  
Create self-signed certificate and private key for the server, then edit configuration file.
```
$ vi /etc/httpd/conf/httpd.conf
(Add the following lines)
LoadModule ssl_module modules/mod_ssl.so
<VirtualHost *:3030>
    ...
    SSLEngine on
    SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP
    SSLCertificateFile /etc/httpd/conf/ssl.crt/revok.crt
    SSLCertificateKeyFile /etc/httpd/conf/ssl.key/revok.key
    ...
</VirtualHost>
```
Step 4: add iptables rule
```
# iptables -I INPUT 1 -p tcp -m tcp --dport 3030 -j ACCEPT
```
Access the web console via URL <http://localhost:3030>.



## 2 Monitoring and troubleshooting

### 2.1 Service status
After startup, check service status to confirm all of the services are running.

* Status for ActiveMQ
```
$ activemq/activemqd status
```
* Status for Caroline
```
$ caroline/carolined status
```
* Status for REST service
```
$ rest/rest-served status
```
* Status for web console started by WEBrick
```
$ webconsole/rackd status
```

### 2.2 Log files
Turn to log files for detailed running information or for troubleshooting when error occurs.

* Log file for ActiveMQ: var/log/activemqd.log
* Log file for Caroline: var/log/carolined.log
* Log file for REST service: var/log/rest_served.log
* Log file for web console: var/log/rackd.log
