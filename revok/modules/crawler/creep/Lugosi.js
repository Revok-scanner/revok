var Lugosi = (function () {
  var module = {};

  module.confirmation = 'a274bda9c14e';
  module.cnc_base = "http://172.16.0.1/";
  module.conf = {};
  module.fresh_tags = false;
  module.state = "stopped";
  module.fields = [];
  module.id_count = 0;
  module.attempts = 4; //default
  module.delay = 1000;
  module.timer = null;
  module.bail_timer = null;
  module.ticks = 0;
  module.login = false;
  module.location = '';

  module.request = function(req) {
    var img = new Image();
    img.src = module.cnc_base + encodeURIComponent(JSON.stringify(req));
  }

  module.scan_for_fields = function() {
    module.fields = Array();
    LugosiZepto('textarea,input[type="password"],input[type="search"],input[type="text"]').filter(function() {
      return LugosiZepto(this).attr('sated') != "true";
    }).each(function() {
      var offset = LugosiZepto(this).offset();
      offset.width = LugosiZepto(this).width();
      offset.height = LugosiZepto(this).height();
      var field = {
        'x': Math.round(offset.left),
        'y': Math.round(offset.top),
        'width': Math.round(offset.width),
        'height': Math.round(offset.height),
        'id' : LugosiZepto(this).prop('id'),
        'name' : LugosiZepto(this).prop('name'),
        'type': LugosiZepto(this).attr('type'),
        'distinguished_id': module.id_count,
      }
      module.fields.push(field);
      LugosiZepto(this).attr('distinguished_id',module.id_count++);
      LugosiZepto(this).attr('sated',true);
    });
  }

  module.click = function() {
    var link_hotspots = Array();
    var button_hotspots = Array();
    var input_hotspots = Array();
    var submit_hotspots = Array();
    LugosiZepto('a,button,input[type="checkbox"],input[type="radio"],input[type="submit"]').each(function () {
      var offset = LugosiZepto(this).offset();
      offset.width = LugosiZepto(this).width();
      offset.height = LugosiZepto(this).height();
      if (LugosiZepto(this).prop('tagName') == "A" && LugosiZepto(this).children().length) {
        offset = LugosiZepto(LugosiZepto(this).children()[0]).offset();
        offset.width = LugosiZepto(LugosiZepto(this).children()[0]).width();
        offset.height = LugosiZepto(LugosiZepto(this).children()[0]).height();
      }
      var hotspot = {
        'x': offset.left,
        'y': offset.top,
        'width': offset.width,
        'height': offset.height,
        'href': LugosiZepto(this).attr('href'),
        'tagName' : LugosiZepto(this).prop('tagName'),
        'id' : LugosiZepto(this).prop('id'),
        'name' : LugosiZepto(this).prop('name'),
        'class' : LugosiZepto(this).prop('class'),
        'type': LugosiZepto(this).attr('type'),
      }
      if (hotspot['x'] < 1 && hotspot['y'] < 1) return true;
      if (hotspot['type'] != undefined && hotspot['type'].toLowerCase() == 'submit') {
        submit_hotspots.push(hotspot)
      } else {
        if (hotspot['tagName'].toLowerCase() == 'input') {
          input_hotspots.push(hotspot);
        } else {
          if (hotspot['tagName'].toLowerCase() == 'button') {
            button_hotspots.push(hotspot);
          } else {
            link_hotspots.push(hotspot);
          }
        }
      }
    });

    if (!link_hotspots.length && !button_hotspots.length && !input_hotspots.length && !submit_hotspots.length) return;

    var hotspot = null;
    if (hotspot == null && submit_hotspots.length && Math.floor(Math.random()*2) > 0) hotspot = submit_hotspots[Math.floor(Math.random() * submit_hotspots.length)];
    if (hotspot == null && input_hotspots.length && Math.floor(Math.random()*2) > 0) hotspot = input_hotspots[Math.floor(Math.random() * input_hotspots.length)];
    if (hotspot == null && button_hotspots.length && Math.floor(Math.random()*2) > 0) hotspot = button_hotspots[Math.floor(Math.random() * button_hotspots.length)];
    if (hotspot == null) hotspot = link_hotspots[Math.floor(Math.random() * link_hotspots.length)];
    if (hotspot == null) hotspot = submit_hotspots[Math.floor(Math.random() * submit_hotspots.length)];
    if (hotspot == null) hotspot = input_hotspots[Math.floor(Math.random() * input_hotspots.length)];
    if (hotspot == null) hotspot = button_hotspots[Math.floor(Math.random() * button_hotspots.length)];
    hotspot['event'] = 'click';
    module.request(hotspot);
  }

  module.set_conf = function(conf) {
    module.conf = JSON.parse(conf);
    module.attempts = module.conf['attempts'];
    module.rest_attempts = module.attempts;
    module.delay = module.conf['delay'];
    if (module.conf['initial_delay'] != undefined) {
      module.initial_delay = module.conf['initial_delay'];
    } else {
      module.initial_delay = 15*1000;
    }
  }

  module.tick = function() {
    var img = new Image();
    img.src = 'http://file.bne.redhat.com/~tjay/serve/img/pixel.png?sync=' + module.ticks++;

    if (--module.rest_attempts < 0) {
      module.request({'event':'restart'});
      return;
    }

    var loc = window.location + ''
    if (loc != module.location) {
      module.location = loc;
      module.reset();
    }

    //console.log('tick');

    switch(module.state) {
      case "stopped":
        break;

      case "running":
        module.scan_for_fields();
        if (module.fields.length) {
          module.request({'event':'fields','fields':module.fields});
          module.state = "waiting_for_tags";
        } else {
          module.click();
        }
        clearTimeout(module.timer);
        module.timer = setTimeout(module.tick,module.delay);
        break;

      case "login":
        module.request({'event':'login'});
        module.state = "waiting_for_login";
        clearTimeout(module.timer);
        module.timer = setTimeout(module.tick,module.initial_delay);
        break;

      case "waiting_for_login":
        clearTimeout(module.timer);
        if (!module.login) {
          module.state = "running";
          module.timer = setTimeout(module.tick,module.initial_delay);
        } else {
          module.timer = setTimeout(module.tick,module.delay);
        }
        break;

      case "waiting_for_tags":
        if (module.fresh_tags) {
          module.state = "running";
        }
        clearTimeout(module.timer);
        module.timer = setTimeout(module.tick,module.delay);
        break;

      default:
        break;

    }
  }

  module.reset = function() {
    module.rest_attempts = module.attempts;
    clearTimeout(module.bail_timer);
    module.bail_timer = setTimeout(function() {
      if (typeof window.callPhantom == 'function') {
        window.callPhantom({a:1});
      } else {
        console.log("Having to bail!");
      }
    },module.delay*(module.attempts*2)+1);
  }

  module.start = function(login) {
    module.login = login;
    if (!module.login) {
      module.state = "running";
      clearTimeout(module.timer);
      if (Math.floor(Math.random()*7) > 5) {
        console.log('Waiting for JS with delay of ' + module.initial_delay + 'ms...');
        module.timer = setTimeout(module.tick,module.initial_delay);
      } else {
        module.timer = setTimeout(module.tick,module.delay);
      }
    } else {
      module.state = "login";
      clearTimeout(module.timer);
      console.log('Waiting for JS with delay of ' + module.initial_delay + 'ms...');
      module.timer = setTimeout(module.tick,module.initial_delay);
    }
    module.reset();
  };

  return module;
}());
