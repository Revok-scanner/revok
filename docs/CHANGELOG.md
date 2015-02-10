# Changelog

### 0.8.1 (2015-02-10)
* Remove useless codes & modules
* New distributed deployment support
* SQLite support for storage
* Remove useless columns in database

### 0.8.0 (2014-12-16)
* Custom scan support
* New flexible framework
* New log and report generator
* Code refactoring
* Remove useless modules
* Remove report and log from database

### 0.7.6 (2014-08-12)
* Distribute self-contained version
* Add installation guide
* Define default configuration for activemq
* Create DB initializing script
* Remove DNS server from backend

### 0.7.5 (2014-07-09)
* Start backend services as daemons
* Remove redundant stuff from caroline and rest server
* Run screenshot without msf on work nodes
* Improve accuracy of time-based test in sqli module
* Bug fix: scan quits when crawler gets error
* Unify result flag of modules

### 0.7.4 (2014-06-25)
* Remove metasploit framework from back-end
* Apply the changes of module calling to caroline

### 0.7.3 (2014-06-13)
* A re-engineered crawler with stable results and improved efficiency
* Bug fix: lengthen waiting time to avoid blank screenshot
* Bug fix: false positive report of corss, path_traversal, passwd_auto_complete, ssl_check

### 0.7.2 (2014-04-22)
* Add SSL/TLS mis-configuration checking module (SSL testing criteria: original + new )
* Add error handling for modules: anti_reflection, bruteforce and redirs

### 0.7.1 (2014-04-01)
* HTML report
* Add tab and enter key to prev and next buttons
* Add up/down key to select URL dropdown items
* Redirect http to https without any error
* Minor updates for landing page

### 0.7 (2014-03-06)
* UI/UX improvement: Add smart detection of login type and login URL
* UI/UX improvement: Add auto complete prompt for URL
* Crawler auto login support
* XSS module: reduce running time, report specifies vulnerable parameters
* SQLi module: add error handling

### 0.6.2 (2014-02-13)
* UI/UX improvement: Lock footer at the bottom
* UI/UX improvement: Click Revok logo to go to homepage
* UI/UX improvement: enlarge Login snapshot for form-based authN

### 0.6.1 (2014-01-20)
* Bug fix: Modify session_exposed_in_url module for null cookie and filter the URLs not belongs to the app
* Bug fix: sqli still met error when scanning against errata tool
* Bug fix: Reduce loading time of the Revok landing page
* Discard credentials of target app (base64 encoded) on Revok to mitigate privacy concerns

### 0.6 (2014-01-09)
* UI/UX improvement: LogIn snapshot page drag-and-drop support
* UI/UX improvement: Landing page redesign
* UI/UX improvement: Remove whitelist page
* Crawler AJAX support (experimental)
* Add Null session module
* Add generic SQLi module
* Update XSS module to work with the new report engine
* Add Documentation: FAQ, Changelog, Revok Roadmap, Revok Feature List

### 0.5 (2013-12-06)
#### Epics
* revok advice list
* Implement New report using the reporting engine and template
* Revok vulnerability features (OWASP top 10, WASC)

#### Stories
* XSS report integration
* Session fixation report integration
* SQLi report integration
* Frame busting report integration
* CORs report integration
* Strict MIME Types report integration
* Method Check (TRACE) report integration
* SSL Check report integration
* SSL forcing report integration
* Secure Cookies report integration
* Path Travesal report integration
* Password Auto-complete enabled report integration
* Forcefully Access admin pages report integration
* Session ID reversion report integration
* Session ID exposure in URL report integration
* add sitemap to report
* Sitemap module

### 0.4 (2013-11-15)
#### Epics
* reporting engine

#### Stories
* report mockup
* Frame-busting
* Cross Origin Policy
* Strict MIME Types
* Method Check (TRACE, etc.)
* SSL Check
* SSL Forcing
* Secure Cookies
* Anti-reflection

### 0.1 (2013-07-09)
* Initial release with XSS and SQLi checks
