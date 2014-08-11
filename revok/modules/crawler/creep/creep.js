var system = require('system');
var fs = require('fs');
var stderr = system.stderr;
var log = stderr.writeLine;

var ws = require('webserver');
var srv = ws.create();
var cac = srv.listen('127.0.0.1:4447', function(req,rsp) {
  rsp.statusCode = 444;
  rsp.close();
  quit();
});


var schars = 
{
  "`":{"code":192,"meta":0},
  "~":{"code":192,"meta":0x02000000},
  "!":{"code":49,"meta":0x02000000},
  "@":{"code":50,"meta":0x02000000},
  "#":{"code":51,"meta":0x02000000},
  "$":{"code":52,"meta":0x02000000},
  "%":{"code":53,"meta":0x02000000},
  "^":{"code":54,"meta":0x02000000},
  "&":{"code":55,"meta":0x02000000},
  "*":{"code":56,"meta":0x02000000},
  "(":{"code":57,"meta":0x02000000},
  ")":{"code":48,"meta":0x02000000},
  "-":{"code":189,"meta":0},
  "_":{"code":189,"meta":0x02000000},
  "=":{"code":187,"meta":0},
  "+":{"code":187,"meta":0x02000000},
  "[":{"code":219,"meta":0},
  "]":{"code":221,"meta":0},
  "{":{"code":219,"meta":0x02000000},
  "}":{"code":221,"meta":0x02000000},
  "\\":{"code":220,"meta":0},
  "|":{"code":220,"meta":0x02000000},
  ";":{"code":186,"meta":0},
  ":":{"code":186,"meta":0x02000000},
  "'":{"code":222,"meta":0},
  "\"":{"code":222,"meta":0x02000000},
  ",":{"code":188,"meta":0},
  "<":{"code":188,"meta":0x02000000},
  ".":{"code":190,"meta":0},
  ">":{"code":190,"meta":0x02000000},
  "/":{"code":191,"meta":0},
  "?":{"code":191,"meta":0x02000000},
};

log('Processing configuration...');
conf = ''
while(line = system.stdin.readLine()) {
  conf += line;
}
conf = JSON.parse(conf);

conf['authenticated'] = false;
var confirmation = 'a274bda9c14e';
log("...done.\n");

function margin_pick(set, set_margins) {
  var choice = Math.floor(Math.random() * set_margins[set_margins.length - 1]);
  for (var i = 0; i < set_margins.length; i++) {
    if (choice < set_margins[i]) {
      choice = set[i];
      break;
    }
  }
  return choice;
}

function create_margins(set, initial_value, prop) {
  set.sort(function (a, b) {return a.length - b.length;});
  var margins = Array();
  for (var ele in set) {
    var last = initial_value;
    if (ele > 0) last = margins[ele - 1];
    margins.push(last + prop(set[ele]));
  }
  return margins;
}

//not quite Fisher-Yates
function shuffle(str) {
  var arr = str.split('');
  for (var i = arr.length; i >= 0; i--) {
    var rand_idx = Math.floor(Math.random() * i);
    var tmp = arr[i];
    arr[i] = arr[rand_idx];
    arr[rand_idx] = tmp;
  }
  return arr.join('');
}

log('Initializing insertion counters...');
function tag() {
  var chars = margin_pick(tag.char_sets, tag.char_sets_margins);
  var size_choice = margin_pick(tag.sizes, tag.size_margins);

  for (var i = size_choice - 1; i >= 0; i--) {
    tag.counters[chars][size_choice][i] = (tag.counters[chars][size_choice][i] + 1) % chars.length;
    if (tag.counters[chars][size_choice][i] != 0) break;
  }

  var tg = Array();
  for (var i = 0; i < size_choice; i++) tg.push(chars[tag.counters[chars][size_choice][i]]);

  tg = tg.join('');
  tag.tags[tick()] = tg;
  return tg;
}
tag.char_sets = [shuffle('0123456789'), shuffle('abcdefghijklmnopqrstuvwxyz')];
//tag.sizes = [4, 8, 16, 32];
tag.sizes = [8, 16, 32];
tag.size_margins = create_margins(tag.sizes, 0, function (c) {return c});
tag.char_sets_margins = create_margins(tag.char_sets, 0, function (c) {return c.length});
tag.counters = function () {
  var counters = Array();
  for (var char_index in tag.char_sets) {
    counters[tag.char_sets[char_index]] = Array();
    for (var size_index in tag.sizes) {
      counters[tag.char_sets[char_index]][tag.sizes[size_index]] = Array();
      for (var i = 0; i < tag.sizes[size_index]; i++) {
        counters[tag.char_sets[char_index]][tag.sizes[size_index]].push(Math.floor(Math.random() * tag.char_sets[char_index].length));
      }
    }
  }
  return counters;
}();
tag.tags = {};
log("...done.\n");

log('Setting vector clock and related counters...');
function tick() {
  tick.ticks.push({'session':page.session,'url':page.url,'depth':(conf.depth - page.depth -1)});
  return tick.clock++;
}
tick.clock = 1;
tick.ticks = [];
log("...done.\n");

var page = null;

log('Warming IO...');
console.log(new Array(1024).join(' '));

var quitting = false;
function quit() {
  if (quitting) return;
  quitting = true;
  //page.stop();
  page.close();
  log("Emitting report...");
  console.log(JSON.stringify({'tags':tag.tags,'ticks':tick.ticks}));
  console.log(new Array(1024).join(' '));
  log("...done.\n");
  log("Exiting...");
  phantom.exit();
}

var timely_click = false;
function left_click(click) {
  timely_click = true;
  var x = Math.floor(click['x']);
  var y = Math.floor(click['y']);
  var xd = Math.floor(Math.random()*click['width']);
  var yd = Math.floor(Math.random()*click['height']);
  var id = '' + click['id'];
  if (id == 'null' || id.length < 1) id = '' + click['name'];
  if (id == 'null' || id.length < 1) id = '' + click['href'];
  if (id != 'null' && id.length > 0) {
    id = " " + id;
  } else {
    id = '';
  }
  if (id.match(/log/i) != null || id.match(/register/i) != null) {
    return;
  }
  var typ = '' + click['type'];
  if (typ == 'null' || typ.length < 1) typ = '' + click['tagName'];
  typ = typ.toLowerCase();
  if (typ == 'a') typ = 'link';
  typ = " " + typ;
  log("\tClicking on" + id + typ + ' at coordinates: ' + (x+xd) + ',' + (y+yd) + '.');
  page.sendEvent('click',(x+xd),(y+yd),'left');
}

function stuff_fields(fields) {
  for (var i = 0; i < fields.length; i++) {
    var field = fields[i];
    var x = Math.floor(field['x']);
    var y = Math.floor(field['y']);
    var xd = Math.floor(Math.random()*field['width']);
    var yd = Math.floor(Math.random()*field['height']);
    page.sendEvent('click',(x+xd),(y+yd),'left');
    var tg = tag();
    var id = '' + field['id'];
    if (id == 'null' || id.length < 1) id = '' + field['name'];
    if (id != 'null' && id.length > 0) {
      id = " " + id;
    } else {
      id = '';
    }
    var typ = field['type'];
    typ = " " + typ;
    log("\tClearing the" + id + typ + ' field at coordinates: ' + (x+xd) + ',' + (y+yd) + '.');
    page.sendEvent('keypress', page.event.key.A, null, null, 0x04000000);
    log("\tInjecting " + tg + ' into the' + id + typ + ' field at coordinates: ' + (x+xd) + ',' + (y+yd) + '.');
    page.sendEvent('keypress',tg);
  }

  page.evaluate(function() {Lugosi.fresh_tags = true});
}

function login() {
  log('logging in...');
  page.sendEvent('click',conf['positions']['username']['x'],conf['positions']['username']['y'],'left');
  page.sendEvent('keypress', page.event.key.A, null, null, 0x04000000);
  page.sendEvent('keypress',conf['username']);
  page.sendEvent('click',conf['positions']['password']['x'],conf['positions']['password']['y'],'left');
  page.sendEvent('keypress', page.event.key.A, null, null, 0x04000000);
  page.sendEvent('keypress',conf['password']);
  page.render('/home/dev/login.png');
  if (conf['login_button'] == true) {
    page.sendEvent('click',conf['positions']['button']['x'],conf['positions']['button']['y'],'left');
  } else {
    page.sendEvent('keypress',page.event.key.Enter);
  }
  page.evaluate(function() {Lugosi.login = false});
}

function forceTimeout(func,delay) {
  var fired = false;
  var timers = new Array();
  function clear() {
    for (var i = 0; i < timers.length; i++) {
      clearTimeout(timers[i]);
    }
  }
  for (var i = 0; i < 100; i++) {
    timers.push(window.setTimeout(function() {
      if (fired) return;
      fired = true;
      clear();
      func();
    },delay+i));
  }
}

function restart(hard) {
  log("Visiting entry page...");
  var session = page.session;
  init_page(hard);
  page.depth = conf.depth;
  page.session = session;
  forceTimeout(function() {
    if (!started) restart();
  },conf['initial_delay']);
  forceTimeout(function() {
    if (!timely_click) {
      log("Hang?");
      restart();
    }
  },conf['initial_delay']*2);
  started = false;
  timely_click = false;
  page.open(conf['target']);
}

function start() {
  log("Starting crawl...");
  http://victim.com
  if (conf['login'] != undefined && conf['login'] != 'http://victim.com') {
    log("\nVisiting login page...\n");
    page.depth = conf.depth;
    page.session++;
    page.open(conf['login']);
  } else {
    restart()
  }
};

function press(str) {
  for (var i = 0; i < str.length; i++) {
    var chr = str[i];
    if (schars[chr] != undefined) {
      page.sendEvent('keypress', schars[chr]['code'], null, null, schars[chr]['meta']);
    } else {
      page.sendEvent('keypress', ("" + chr), null, null, 0);
    }
  }
}

phantom.onError = function(msg, trace) {
  log("\nPhantom Error: " + msg + "\n");
  restart(true);
  return true;
}

var started = false;
function init_page(hard) {
  if (page && hard != true) return;
  if (hard) console.log('restarting hard...');
  if (page) page.close();
  page = require('webpage').create();
  log('Initializing virtual browser and screen...');
  page.viewportSize = { width: conf['width'], height: conf['height'] };
  page.clipRect = { top: 0, left: 0, width: conf['width'], height: conf['height'] }
  page.session = 0;
  page.failures = 0;
  page.customHeaders={'Authorization': 'Basic '+btoa(conf['username'] + ':' + conf['password'])};
  log("...done.\n");

  page.onResourceRequested = function(requestData, networkRequest) {
    var command = requestData.url.match(/^http:\/\/172.16.0.1\/(.*)/);
    if (command) {
      networkRequest.abort();
      var evt = JSON.parse(decodeURIComponent(command[1]));
      switch(evt['event']) {
        case 'click':
          left_click(evt);
          break;
        case 'login':
          login();
          break;
        case 'fields':
          stuff_fields(evt['fields']);
          break;
        case 'restart':
          restart();
          break;
      }
      return;
    } 
    var old = requestData.url.replace(/#.*/,'');
    var url = old + confirmation + encodeURIComponent(JSON.stringify({'tick':tick()}));;
    networkRequest.changeUrl(url);
  }

  page.onResourceReceived = function(rsp) {
    for (var i = 0; i < rsp.headers.length; i++) {
      if (rsp.headers[i].name == 'Creep-Command' && rsp.headers[i].value == 'halt') {
        log("\nhalt command received.\n");
        quit();
      }
    }
  };

  page.onResourceError = function(err) {
    //log("Error retrieving " + err.url + ": " + err.errorString);
  }

  page.onNavigationRequested = function(url, typ, willNavigate, main) {
    if (url.indexOf('http') != 0 && main == true) restart();
  }

  page.onUrlChanged = function(targetUrl) {
    log("\nNow visiting: " + targetUrl);
    //page.render(tick() + '.png');
    var allowed = false;
    for (var i = 0; i < conf['whitelist'].length; i++) {
      if (!(targetUrl.indexOf(conf['whitelist'][i]) < 0)) {allowed = true};
    }
    if (conf['whitelist'].length == 0) {allowed = true};
    if (page.depth-- < 0 || !allowed) {
      if (!allowed) {
        log("\tDomain is not on whitelist.");
      } else {
        log("\tDepth exceeded.");
      }
      restart();
    } else {
      page.evaluate(function() {
        try {
          Lugosi.reset();
        } catch(err) {
          log("crash here?");
        }
      });
    }
  }

  page.onConsoleMessage = function(msg, line, src) {
    if (msg.match(/172.16.0.1/)) return; //insecure content
    if (msg.match(/pixel\.png\?sync=/) || msg == 'tick') {
      log('.');
    } else {
      log("\tconsole: " + msg);
    }
    if (msg == 'Having to bail!') restart();
  }

  page.onCallback = function(ign) {
    restart();
  };

  page.onError = function(msg, trace) {
    //log("\nError: " + msg + "\n");
    return true;
  };

  page.onConfirm = function(msg) {
    log("\tConfirmation box popped up with: " + msg);
    log("\tConfirming...");
    return true;
  }

  page.onLoadStarted = function() {
    started = true;
  }

  page.onLoadFinished = function(status) {
    log('Page load status: ' + status);
    if (status == "fail") {
      if (++page.failures > 7) {
        page.failures = 7;
        restart(true);
      }
      return;
    } else {
      page.failures = 0;
    }

    var login = false;

    if (conf['authenticated'] == false && conf['logtype'] == 'normal' && page.url.indexOf(conf['login']) != -1) {
      login = true;
      conf['authenticated'] = true;
    }

    page.injectJs('./resources/zepto.min.js');
    page.injectJs('./Lugosi.js');
    eval("page.evaluate(function() {Lugosi.set_conf('" + JSON.stringify(conf) + "')})");
    if (login) {
      page.evaluate(function() {
        Lugosi.start(true);
      });
    } else {
      page.evaluate(function() {
        Lugosi.start(false);
      });
    }
    if (page.evaluate(function() {return Lugosi.confirmation}) != confirmation) {restart()};
  }

}
init_page();

start();
forceTimeout(function() {
  quit();
},conf['duration']);
