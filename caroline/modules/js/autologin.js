var system = require('system');
var stderr = system.stderr;
var log = stderr.writeLine;
var confirm = "da98083a2371";

var ws = require('webserver');
var srv = ws.create();
var cac = srv.listen('127.0.0.1:4447', function(req,rsp) {
  rsp.statusCode = 444;
  rsp.close();
  phantom.exit();
});

log('Processing configuration...');
conf = '';
while(line = system.stdin.readLine()) {
  conf += line;
}
conf = JSON.parse(conf);
log('done');

var page = require('webpage').create();
page.viewportSize = { width: 1280, height: 800 };
page.clipRect = { top: 0, left: 0, width: 1280, height: 800 };

var state = 0;
page.onConsoleMessage = function(msg, line, src) {
  if (msg.indexOf(confirm) == -1) return;
  switch(state) {
    case 0:
      log('found password');
      msg = msg.match(/da98083a2371(.*)da98083a2371/)[1];
      msg = JSON.parse(msg);
      msg.x = msg.x + Math.floor(msg.width/2);
      msg.y = msg.y + Math.floor(msg.height/2);
      conf['positions']['password']['x'] = msg.x;
      conf['positions']['password']['y'] = msg.y;
      page.sendEvent('click',msg.x,msg.y,'left');
      page.evaluate(function() {
        setTimeout(function() {
          console.log('da98083a2371');
        },1000);
      });
      break;
    case 1:
      log('press');
      page.sendEvent('keypress', page.event.key.Tab, null, null, 0x02000000);
      page.evaluate(function() {
        setTimeout(function() {
          console.log('da98083a2371');
        },1000);
      });
      break;
    case 2:
      log('active?');
      page.evaluate(function() {
        setTimeout(function() {
          var username = document.activeElement;
          var offset = username.getBoundingClientRect();
          var spot = {
            'x': offset.left,
            'y': offset.top,
            'width': offset.width,
            'height': offset.height,
          };
          console.log('da98083a2371' + JSON.stringify(spot) + 'da98083a2371');
        },1000);
      });
      break;
    case 3:
      log('done');
      msg = msg.match(/da98083a2371(.*)da98083a2371/)[1];
      msg = JSON.parse(msg);
      msg.x = msg.x + Math.floor(msg.width/2);
      msg.y = msg.y + Math.floor(msg.height/2);
      conf['positions']['username']['x'] = msg.x;
      conf['positions']['username']['y'] = msg.y;
      conf['login_button'] = false;
      conf['logtype'] = 'normal';
      conf['auto'] = true;
      console.log(JSON.stringify(conf));
      phantom.exit();
      break;
  }
  state++;
};

page.open(conf['login'], function(status) {
  log("status: " + status);
  page.evaluate(function() {
    function da98083a2371_password() {
      var passwords = [];
      var inputs = document.getElementsByTagName('input');
      for (var i = 0; i < inputs.length; i++) {
        if (inputs[i].type == 'password') {
          passwords = [inputs[i]];
        }
      }

      if (passwords.length < 1) {
        setTimeout(da98083a2371_password,1000);
        return;
      }
      var password = passwords[0];
      var offset = password.getBoundingClientRect();
      var spot = {
        'x': offset.left,
        'y': offset.top,
        'width': offset.width,
        'height': offset.height,
      };
      console.log('da98083a2371' + JSON.stringify(spot) + 'da98083a2371');
    }
    setTimeout(da98083a2371_password,1000);
  });
});
