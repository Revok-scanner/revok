# FAQ

**Q: What is Revok?**  
**A:** Revok is an online web application security scanner, which automatically finds vulnerabilities and weaknesses of a given web app and provides remedy advice. It currently supports apps with no authentication, basic authentication, and form-based authentication.

**Q: Whom is Revok for?**  
**A:** It is designed for software engineers or engineering managers who want to understand the security posture of their web application products constantly and, in turn, eliminate common vulnerabilities and weaknesses.

**Q: Why do you create a new web app security scanner?**  
**A:** One of the most dissatisfying features of existing web app security scanners is that they are hard to use, providing complex configurations and user interfaces. Most existing scanners were created for security engineers, making them not user friendly for software engineers. With these in mind, we decided to create an ease-of-use and developer-centric web app security scanner, which can be used constantly and throughout the software development life cycle.

**Q: What differentiates Revok from other scanners?**  
**A:** Revok aims at making security an easy service, reachable for developers of varying levels of security awareness. It has four highlights:

* easy to use - SaaS removes installation or maintenance pain; No prior knowledge of web app security is required.
* user in mind - "Smart detection" auto-detects application authentication type and login URL.
* a built-in JavaScript-aware website crawler - built on PhantomJS, a headless WebKit.
* REST API for Continuous Integration (planned)

Firstly, as Revok is extremely easy to use. With a SaaS solution, software developers can focus on checking the security posture of their applications constantly when code changes and don't worry about software upgrade or infrastructure. No prior knowledge of web app security is required. You can scan first, learn from the reports, and understand the security issues one by one. Secondly, Revok cares about users heartily: "Smart detection" auto-detects application authentication type and login URL. Thirdly, a JavaScript-aware crawler built on PhantomJS, a headless WebKit, enables Revok to understand not just normal html web pages, but also JavaScript rich applications. Finally, Revok plans to offer REST API so that securit review can become an integral part of any existing Continuous Integration environments.

**Q: What vulnerabilities does Revok check?**  
**A:** Top web vulnerabilities such as XSS, SQL injection, etc.. Check the complete list in [FEATURES](https://github.com/Revok-scanner/revok/blob/master/docs/FEATURES.md).

**Q: Is there a quickstart?**  
**A:** See [README](https://github.com/Revok-scanner/revok/blob/master/README.md).

**Q: Can I use Revok to test any web targets?**  
**A:** No. Revok injects data during scan and may corrupt your database. So the targets are limited to **test environments** of your application. Revok currently does not support AJAX heavy apps such as apps built with GWT.

**Q: Is there a roadmap?**  
**A:** Yes, pls check the [ROADMAP](https://github.com/Revok-scanner/revok/blob/master/docs/ROADMAP.md).

**Q: How to communicate with Revok team?**  
**A:** If you have interest in contributing to Revok, or questions/suggestions, please email <revok-scanner-users@googlegroups.com> (for user) or <revok-scanner-devel@googlegroups.com> (for developer).
