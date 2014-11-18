var system = require('system');

var page = require('webpage').create();
page.viewportSize = { width: 1280, height: 800 };
page.clipRect = { top: 0, left: 0, width: 1280, height: 800 };

var url = system.stdin.read().split('\n')[0];
page.settings.resourceTimeout = 60*1000;

page.onCallback = function(data) {
  page.render(system.args[1]);
  phantom.exit();
};

page.onLoadFinished = function(status) {
  console.log("status: " + status);
  page.evaluate(function(timeout) {
    setTimeout(function() {
      window.callPhantom({a:'1'});
    },timeout);
  },system.args[2]);
};

page.open(url);
