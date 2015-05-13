var JQUERY = './resources/jquery-1.7.2.js';
var WEB_CRAWLER_TIME_OUT = 180*1000;
var CRAWLER_TIME_OUT = 15*1000;
var START_DELAY = 60*1000;
/**
 * Just crawl the http requests which belong to the entranceURL hostname .
 */
var HOSTNAME = '';
var PROTOCOL = '';
/**
 * all http requests opened by page.open(url).
 */
var all_http_requests = new Array();
/**
 * all http requests visited by page.open(url).
 */
var all_http_visited = new Array();
/**
 * all_form_post
 */
var all_form_post = new Array();
/**
 * all injected url
 */
var injected_list = new Array();
/**
 * all inject tags
 */
var tags_list = new Array();

var pages = new Array();
var constant = {'normal':'normal','inject':'inject','defaulthost':'localhost'};
var config = {};
var LOGIN_LOAD = false;

/**
 * Web crawler engine and manager.
 * @author ltian
 * @since 2014-03-25
 */
var WebCrawler = function(){
	this.entranceURL = '';
	this.HOSTNAME = '';
	this.init();
};

WebCrawler.prototype.WebCrawler = WebCrawler;

WebCrawler.prototype.init = function(){
	var conf = '';
	while(line = phantomJS.system.stdin.readLine()) {
		conf += line;
	}
	config = JSON.parse(conf);
	
	config['crawlresources'] = false;
	config['capture'] = false;
	
	var reg=new RegExp("^https",'i');
	if(reg.test(config['target'])){
		PROTOCOL = 'https:';
	}else{
		PROTOCOL = 'http:';
	}
	
	if(config['logtype'] == 'normal'){
		this.login();
	}
	
	var $this = this;
	setTimeout(function(){$this.start();},START_DELAY);
	setTimeout(function(){$this.stop();},WEB_CRAWLER_TIME_OUT);
};

WebCrawler.prototype.login = function(){
	try{
		//log('Start to log in from the URL : '+config['login']);
		new Crawler( new HttpURL(config['login']),'login' );
	}catch(e){
		//log('errors... '+e);
	}
};

/**
 * Web crawler started form the entrance URL.
 */
WebCrawler.prototype.start = function(){
	try{
		this.entranceURL = config['target'];
		//log('Start to crawl from the begin URL : '+this.entranceURL);
		new Crawler( new HttpURL(this.entranceURL) );
	}catch(e){
		//log('errors... '+e);
	}
	
};

/**
 * close/release all pages and stop PhantomJS engine.  
 */
WebCrawler.prototype.stop = function(){
	this.printLog();
	for(var i = 0 ; i < pages.length ; i++ ){
		var page = pages[i];
		if(page != null && page != undefined){
			try{
				page.close();
			}catch(e){}
		}
	}
	//log('Web Crawler is stopped.');
	phantomJS.exit();
};

WebCrawler.prototype.printLog = function(){
	var tag_str = '';
	for(var i = 0 ; i < tags_list.length ; i++ ){
		var id = i+1;
		var tag = tags_list[i];
		if(i == tags_list.length - 1){
			tag_str += '"' + id + '"'+" : " + '"'+tag+'"';
		}else{ 
			tag_str += '"' + id + '"'+" : " + '"'+tag+'"'+', ';
		}
	}
	var tags = '{"tags":{'+ tag_str +'}';

	var ticks_str = '';
	for(var i = 0 ; i < all_http_requests.length ; i++ ){
		var url = all_http_requests[i].url;
		url = decodeURI(url)
		url = url.replace(/\?crawlerforminject=true/,'').replace(/&crawlerforminject=true/,'').replace(eval("/"+confirmation+".*$/"),'').replace(/"/,'\\"');
		if(i == all_http_requests.length - 1){
			ticks_str += '{"url"'+":" + '"'+url+'"}';
		}else{ 
			ticks_str += '{"url"'+":" + '"'+url+'"}' + ', ';
		}
	}
	var ticks = '"ticks":['+ ticks_str +']}';
	log(tags + ',\n' + ticks);
};

/**
 * Crawler to crawl every web page.
 * @author ltian
 * @since 2014-03-25
 */
function Crawler(httpURL,type){
	this.url = httpURL.url;
	this.type = type;
	this.page;
	this.locations;
	this.forms = new Array();
	this.links = new Array();
	this.fields = new Array();
	this.webResources = new Array();
	
	var $this = this;

	this.init = function(){
		/*
		 * if the current URL is not opened by Phantom page,crawl the page.
		 * else do nothing.
		 */
		if( (httpURL.normal && ! crawlerCheck(httpURL)) || !httpURL.normal ){
			//log('[new Crawler]   ' + this.url);
			this.page = phantomJS.createPage();
			pages.push(this.page);
			if(this.type == 'login'){this.page.viewportSize = { width: config['width'], height: config['height'] };}
			if(this.type != 'login'){
				all_http_requests.push(httpURL);//log('all_http_requests length: ' + all_http_requests.length);
			}
			if(httpURL.normal){
				if(httpURL.needInject){
					new Crawler( new HttpURL(httpURL.injectUrl,constant.inject) );
					injected_list.push(httpURL.uniqueUrlStr);
				}
				this.page.onInitialized = function() {
			    	if(HOSTNAME == ''){//record the unique crawl HOSTNAME.
			        	HOSTNAME = $this.page.evaluate(function(){return document.location.hostname;});
			        	if(HOSTNAME == ''){
			        		HOSTNAME = constant.defaulthost;
			        	}
			        }else{
			        	var hostname = $this.page.evaluate(function(){return document.location.hostname;});
			        	if(HOSTNAME != constant.defaulthost && HOSTNAME != hostname){
			        		this.close();
			        	}
			        }
				};
				this.page.onLoadStarted = function() {};
				this.page.onLoadFinished = function(status) {
					$this.page.injectJs(JQUERY);
					$this.initLocation();
					if($this.type == 'login'){
			        		if(!LOGIN_LOAD){
		        				LOGIN_LOAD = true;
		        				//log('login page loaded..' );
		        				$this.scanLink('login');
			        		}else{
			        			//log('login successful..' );
			        		}
		        			$this.page.sendEvent('click',config['positions']['username']['x'],config['positions']['username']['y'],'left');
		        			$this.page.sendEvent('keypress', $this.page.event.key.A, null, null, 0x04000000);
		        			$this.page.sendEvent('keypress',config['username']);
			        		$this.page.sendEvent('click',config['positions']['password']['x'],config['positions']['password']['y'],'left');
			        		$this.page.sendEvent('keypress', $this.page.event.key.A, null, null, 0x04000000);
			        		$this.page.sendEvent('keypress',config['password']);
		        			$this.page.render('/home/dev/login.png');
			    			if (config['login_button'] == true) {
			    				$this.page.sendEvent('click',config['positions']['button']['x'],config['positions']['button']['y'],'left');
			    				$this.page.sendEvent('click',config['positions']['button']['x'],config['positions']['button']['y'],'left');
				    		}else {
				    			$this.page.sendEvent('keypress',$this.page.event.key.Enter);
				    		}
		        		}else{
					        $this.scanPage();
				        	setTimeout(function(){$this.close();},CRAWLER_TIME_OUT);
		        		}	
			        	if(status == 'success'){
			        		if(config['capture']){
			        			$this.page.render($this.url+'.png');
			        		}
					}
				};
				if(this.type != 'login'){
			    		this.page.onUrlChanged = function(targetUrl) {
				    		var currentURL = $this.url;
					    	targetUrl = $this.fixUrlEnd(targetUrl);
					    	if(targetUrl != currentURL){
                					//$this.close();
						}
					};
					this.page.onNavigationRequested = function(url, type, willNavigate, main) {
				    		try{
				    			if(url.indexOf('logout') >= 0){
				    				//log('this is logout : '+url);
								$this.page.close();
								return;
							}
							url = $this.fixUrlEnd(url);
				    		
							if(HOSTNAME != ''){
								var httpReg=new RegExp("^"+PROTOCOL + "//" + HOSTNAME);
								if(!httpReg.test(url)){
									$this.page.close();
									return;
								}
							}
							if(url.indexOf('crawlerforminject=true') < 0){
				    			/**
				    			 * Almostly , form get submit, window.location.href is.
				    			 * 
				    			 */
								if(url != $this.url){
									var url_ = new HttpURL(url);
									if(! crawlerCheck(url_)){
										new Crawler(url_);//Start a new crawler on the navigation URL.
						    			}else{
						    			/**
						    			 * if the URL will be Navigation is a visited URL,then stop.
						    			 */
						    				if( crawlerCheckVisited(url)){
							    				$this.page.close();
							    				return;
							    			}
						    			}
						    		}else{
						    			if( crawlerCheckVisited(url)){
						    				$this.page.close();
						    				return;
						    			}
						    		}
							}else{// form post submit
				    				if(!crawlerCheckFormPost(url)){
				    					all_form_post.push(url);
					    				injected_list.push(url);
					    				var url_ = new HttpURL(url);
					    				all_http_requests.push(url_);//log('all_http_requests length: ' + all_http_requests.length);
					    			}else{
					    				$this.close();
					    				return;
					    			}
				    			}
					    		if(type == 'FormSubmitted' && main){
				    				//$this.close();
				    			}
				    		}catch(e){}
				    	};
				}
				this.page.onResourceReceived = function(response) {};
				this.page.onAlert = function() {/*log('alert');*/};
				this.page.onError = function(msg, trace) {/*log('page.onError' + $this.url);*/};
			}
			this.page.onResourceRequested = function(requestData, networkRequest) {
				var old = requestData.url.replace(/#.*/,'');
				var url = old + confirmation + encodeURIComponent(JSON.stringify({'tick':tick()}));;
				networkRequest.changeUrl(url);
			};
			this.start();
		}
	};
	this.start = function(){
		try{
			this.page.open(this.url, function(status) {
				if($this.type != 'login'){
					all_http_visited.push($this.url);
				}
			});
		}catch(e){}
	};
	this.initLocation = function(){
		this.locations = this.page.evaluate(function(){
			var location = {};
			location.hostname = (document.location.hostname === "" ? "localhost" : document.location.hostname);
			location.protocol = (window.location.protocol == 'https:' ? 'https:' : 'http:');
			location.pathname = document.location.pathname;
			location.href = document.location.href;
			location.path = location.pathname.substring(0,location.pathname.lastIndexOf('/'));
			location.link_host = location.protocol + "//" + location.hostname + (document.location.port != "" ? ":" + document.location.port : "");
			return location;
		});
	};
	this.reBuildURL = function(base,url){
		var httpReg = new RegExp('^http','i');
		if(httpReg.test(url)){
			return url;
		}
		var reg = new RegExp('^\\.\\.\\/\\.\\.\\/\\.\\.\\/');// ../../../
		if(reg.test(url)){
			base = base.substring(0,base.lastIndexOf('/'));
			base = base.substring(0,base.lastIndexOf('/'));
			base = base.substring(0,base.lastIndexOf('/'));
			var lastURL = url.substring(url.lastIndexOf('./')+1,url.length);
			var real_url = base + lastURL;
			return this.fixUrlEnd(real_url);
		}
		reg = new RegExp('^\\.\\.\\/\\.\\.\\/');// ../../
		if(reg.test(url)){
			base = base.substring(0,base.lastIndexOf('/'));
			base = base.substring(0,base.lastIndexOf('/'));
			var lastURL = url.substring(url.lastIndexOf('./')+1,url.length);
			var real_url = base + lastURL;
			return this.fixUrlEnd(real_url);
		}
		reg = new RegExp('^\\.\\.\\/');// ../
		if(reg.test(url)){
			base = base.substring(0,base.lastIndexOf('/'));
			var lastURL = url.substring(url.lastIndexOf('./')+1,url.length);
			var real_url = base + lastURL;
			return this.fixUrlEnd(real_url);
		}
		reg = new RegExp('^\\.\\/');// ./
		if(reg.test(url)){
			var lastURL = url.substring(url.lastIndexOf('./')+1,url.length);
			var real_url = base + lastURL;
			return this.fixUrlEnd(real_url);
		}
		reg = new RegExp('^\\?');// ?searchstr
		if(reg.test(url)){
			var real_url = this.url + url;
			return this.fixUrlEnd(real_url);
		}
		
		return this.fixUrlEnd(base + '/' + url);
	};
	this.fixUrlEnd = function(url){
		var path = url.split('?')[0];
		var para = url.split('?')[1];
		var reg = new RegExp('\\/\\.*$');
		
		if(reg.test(path)){
			path = path.substring(0,path.lastIndexOf('/'));
		}
		if(para != null && para != undefined){
			url = path + '?' + para;
		}else{
			url = path;
		}
		return url;
	};
	this.scanPage = function(){
		this.scanLink();
		this.scanButton();
		this.scanForm();
		this.scanImage();
		this.scanEvents();
	};
	this.scanLink = function(type) {
		this.links = this.page.evaluate(function(host,locations){
			var links = new Array();
			$('a').each(function(){
				var href = $(this).attr('href');
				if(href != '#' && $.trim(href) != '' && href.indexOf('mailto') < 0 && href.indexOf('logout') < 0 && href.indexOf('javascript') < 0){

					var absoluteLinkReg = new RegExp("^(https?|ftps?|file|javascript|mailto|data:image)","i");
					var baseHref = "";

					//Only relative links
					if(!absoluteLinkReg.test(href)){
						//There is base tag defined
						if($("base").length > 0 && (baseHref = $("base").attr("href")) != "")
							href = baseHref + (baseHref.match(/\/$/)? href : "/"+href);
						else
							href = locations.path+"/"+href;
					}

					var httpReg = new RegExp('^http','i');
					if( ! httpReg.test(href) ){
						var reg=new RegExp("^/");    
						if(reg.test(href)){
							href = locations.link_host+href;
						}else{
							links.push(href);
						}
					}
					if( httpReg.test(href)){
						httpReg=new RegExp("^"+locations.protocol + "//" + host);//finally ,test the href if belongs to the hostname.
						if(httpReg.test(href)){
							links.push(href);
						}
					}
				}
			});
			return links;
		},HOSTNAME,this.locations);
		
		for(var i = 0 ; i < this.links.length ; i++){
			url_ = this.reBuildURL(this.locations.link_host +this.locations.path, this.links[i]);
			var url = new HttpURL(url_);
			if(! crawlerCheck(url)){
				new Crawler(url,type); //Start a new crawler with the link href.
			}
		}
	};
	this.scanButton = function() {
		this.page.evaluate(function(){
			$(' input[type="button"],button ').each(function(i){
				var button = $(this);
				var t = i*20 + 100;
				setTimeout(function(){button.click();},t);
			});
		});
	};
	this.scanForm = function() {
		//var forms = this.page.evaluate(function(locations,injected_list){
		var tags = this.page.evaluate(function(locations,injected_list){
			var forms = new Array();
			var tags = new Array();
			$(' form ').each(function(i){
				var form = $(this);
				if(form.attr('style') != undefined && form.attr('style').indexOf('display:none') >= 0){
					return true  
				}
				if(form.attr('id') == undefined || form.attr('id') == ''){
					form.attr('id','crawker_form_'+i);
				}
				if(form.attr('action') == '' || form.attr('action') == '#' || form.attr('action') == undefined){
					form.attr('action',locations.href);
				}
				if(form.attr('onsubmit') != ''){
					form.attr('onsubmit','');
				}
				if(form.attr('method') == 'POST' || form.attr('method') == 'post'){
					var action = form.attr('action');
					if(action.indexOf('crawlerforminject=true') < 0){
						if(action.split('?')[1] != undefined){
							form.attr('action',action+'&crawlerforminject=true');
						}else{
							form.attr('action',action+'?crawlerforminject=true');
						}
						var b = crawlerCheckInjected(form.attr('action'));
						$("#"+form.attr('id')+" input ,textarea").each(function(){
							 var tag = uuid();
							 if( !b ){
								 tags.push(tag);
							 }
							 $(this).val(tag);
							 if($(this).attr('type') == 'submit'){
							   $("#"+form.attr('id')).append("<input value='"+tag+"' type='hidden' name='"+$(this).attr('name')+"'></input>");  
							 }
						});
						$("#"+form.attr('id')+" select ").each(function(){
							var tag = uuid();
							 if( !b ){
								 tags.push(tag);
							 }
							$(this).empty();
							$(this).append("<option value='"+tag+"'></option>");  
						});
						form.submit();
						forms.push(form.attr('action'));
					}
				}else{
					$("#"+form.attr('id')+" input ").each(function(){
						if($(this).attr('type') == 'submit' && $(this).attr('name') != undefined){
							$("#"+form.attr('id')).append("<input value='"+$(this).attr('value')+"' type='hidden' name='"+$(this).attr('name')+"'></input>");
						}
					});
					form.submit();
				}
				function uuid(){
					var s = [];
					var hexDigits = "0123456789abcdef";
					for (var i = 0; i < 36; i++) {
						s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1);
					}
					s[14] = "4";
					s[19] = hexDigits.substr((s[19] & 0x3) | 0x8, 1);
					s[8] = s[13] = s[18] = s[23] = "-";
					var uuid = s.join("");
					return uuid;
				}
				function crawlerCheckInjected(url){
					for (var i = 0; i < injected_list.length; i++) {
						if ( url == injected_list[i] ) {
							return true;
						}
					}
					return false;
				}
				
			});
			return tags;
		},this.locations,injected_list);
		for(var i = 0 ; i < tags.length ; i++){
			tags_list.push(tags[i]);
		}
	};
	this.scanImage = function() {
		this.page.evaluate(function(){
			$(' img ').each(function(i){
				var img = $(this);
				var t = i*50 + 100;
				setTimeout(function(){img.click();},t);
			});
		});
	};
	this.scanField = function() {
		this.fields = this.page.evaluate(function(){
			var fields = new Array();
			$(' input[type="checkbox"],input[type="radio"],input[type="submit"] ').each(function(){
				var f = $(this);
				var t = i*50 + 100;
				setTimeout(function(){f.click();},t);
			});
			return fields;
		});
	};
	this.crawlResources = function(){
		for(var i = 0 ; i < this.webResources.length ; i++){
			var url = new HttpURL(this.webResources[i]);
			if(! crawlerCheck(url)){
				new Crawler(url);//Start a new crawler on the navigation URL.
			}
		}
	};
	this.scanEvents = function(){
		this.page.onConsoleMessage = function(msg){};
		this.page.injectJs(JQUERY);
		//console.log("[OID] URL: "+this.page.url);

		var objectSelectors = Array("div", "li", "span");//, "p", "tr", "td", "radio");

		for(k = 0; k < objectSelectors.length; k++){
			var objectSelector = objectSelectors[k];

			//Get all oids
			var objects = this.page.evaluate(function(objectSelector){
				var objects = Array();

				$(objectSelector).each(function(i){
					var oid = $(this).attr('id');

					if(oid == undefined){
						oid = "revok-internal-id"+i;
					}
					objects.push(oid);
				});
				return objects;
			},objectSelector);

			//There are objects
			if(objects.length > 0){
				var events = Array("click", "mouseout", "mouseover", "mousedown"); //"mouseup");
				for(i = 0; i < events.length; i++){
					for(j = 0; j < objects.length; j++){
						this.page.evaluate(function(objectSelector, id, ev){

							//Get oids once again
							$(objectSelector).each(function(i){
								var oid = $(this).attr('id');

								if(oid == undefined){
									oid = "revok-internal-id"+i;
								}

								if(id == oid){
									var o = $(this);
									console.log("[OID] "+id+"."+ev+" ("+objectSelector+")");
									setTimeout(function(){ o[ev](); }, 250);
								}
							});
						}, objectSelector, objects[j], events[i]);
					}
				}
			}
		}

	};
	this.close = function(){
		try{
			this.page.close();
		}catch(e){}
	};
	
	this.init();
}

function HttpURL(url,type){
	this.url = url;
	this.injectUrl = '';
	this.uniqueUrlStr = ''; 
	this.normal = (type == null || type == undefined ? true :false);
	this.needInject = false;
	this.path = '';
	this.search = '';
	this.parameterNames = new Array();
	this.para = {};
	this.paraTag = {};
	
	this.parse = function(){
		this.url = fixURL(this.url);
		if(this.normal){
			this.path = this.url.split('?')[0];
			this.search = this.url.split('?')[1];
			if(this.search != null && this.search.length > 0){
				this.needInject = true;
			}
			
			this.genUniqueUrlStr();
			this.genInjectUrl();
		}
	};
	this.compareTo = function(o){
		return this.uniqueUrlStr == o.uniqueUrlStr ? true : false;
	};
	this.genUniqueUrlStr = function(){
		this.para = this.parseQueryString();
		for(var name in this.para){
			if(name.indexOf('!')<0){
				this.parameterNames.push(name);
			}
		}
		this.parameterNames.sort();
		this.uniqueUrlStr = this.path +'?'+this.parameterNames;
	};
	this.genInjectUrl = function(){
		var str = '';
		var b = crawlerCheckInjected(this.uniqueUrlStr);
		for(var i = 0 ; i < this.parameterNames.length ; i++ ){
			var p_name = this.parameterNames[i];
			var tag = this.uuid();
			if( !b ){
				tags_list.push(tag);
			}
			if( i < this.parameterNames.length -1 ){
				str += p_name + '=' + tag + '&';
			}else{
				str += p_name + '=' + tag;
			}
		}
		this.injectUrl = this.path + '?' + str;
	};
	this.parseQueryString = function() {  
		var result = {};  
		if(this.search != null && this.search.length > 0){
			var str = this.search, items = str.split("&");  
			var arr;  
			for (var i = 0; i < items.length; i++) {
				arr = items[i].split("=");  
				result[arr[0]] = arr[1];  
			}  
		}
	    return result;  
	};
	this.uuid = function() {
	    return uuid();
	};
	
	this.parse();
}

function log(msg){
	console.log(msg);
}
/**
 * a very important method.
 * @param element
 */
function crawlerCheck(url){
	for (var i = 0; i < all_http_requests.length; i++) {
		if (url.compareTo(all_http_requests[i]) ) {
			return true;
		}
	}
	return false;
}

function crawlerCheckVisited(url){
	for (var i = 0; i < all_http_visited.length; i++) {
		if ( url == all_http_visited[i] ) {
			return true;
		}
	}
	return false;
}

function crawlerCheckFormPost(url){
	for (var i = 0; i < all_form_post.length; i++) {
		if (url == all_form_post[i] ) {
			return true;
		}
	}
	return false;
}

function crawlerCheckInjected(url){
	if(url.indexOf('crawlerforminject') >= 0){
		return true;
	}
	for (var i = 0; i < injected_list.length; i++) {
		if ( url == injected_list[i] ) {
			return true;
		}
	}
	return false;
}

function startWith(str,char) {
	var reg = new RegExp("^" + char);
	return reg.test(str);
}

function endWith(str,char) {
	var reg = new RegExp(char+'$');
	return reg.test(str);
}

function fixURL(url){
	if(endWith(url,'\\?')){
		url = url.substring(0,url.length - 1);
	}
	if(endWith(url,'\\/')){
		url = url.substring(0,url.length - 1);
	}
	if(endWith(url,'\\/\\.')){
		url = url.substring(0,url.length - 2);
	}
	return url;
};

function uuid(){
	var s = [];
	var hexDigits = "0123456789abcdef";
	for (var i = 0; i < 36; i++) {
		s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1);
	}
	s[14] = "4";
	s[19] = hexDigits.substr((s[19] & 0x3) | 0x8, 1);
	s[8] = s[13] = s[18] = s[23] = "-";
	var uuid = s.join("");
	return uuid;
}

/**
 * PhantomJS Wrapper Class.
 * 
 * @author ltian
 * @since 2014-03-25
 */
function PhantomJS(){
	this.system = require('system');
	this.fs = require('fs');
	this.createPage = function(){
		var page = require("webpage").create();
		if(config['logtype'] == 'basic'){
			page.customHeaders={'Authorization': 'Basic '+btoa(config['username'] + ':' + config['password'])};	
		}
		return page;
	};
	this.exit = function(){
		phantom.exit();
	};
}

function tick() {
	return tick.clock++;
};

tick.clock = 1;
var confirmation = 'a274bda9c14e';

var phantomJS = new PhantomJS();

new WebCrawler();//Start Web crawler engine.
