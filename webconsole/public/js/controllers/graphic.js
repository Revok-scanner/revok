revok.controller('graphicController', function($scope,$timeout,$http) {

    function ovoid(ctx,x,y,size) {
      pts = [2.525549999999999,24.836054999999998,0.801499999999999,49.931205,0.801499999999999,49.931205,0.801499999999999,49.931205,2.525549999999999,75.027805,9.00415,79.347355,15.474049999999998,83.67560499999999,50.0,86.27110499999999,50.0,86.27110499999999,50.0,86.27110499999999,84.5274,83.67560499999999,90.9944,79.347355,97.47445,75.027805,99.1985,49.93120499999999,99.1985,49.93120499999999,99.1985,49.93120499999999,97.47444999999999,24.834604999999993,90.9944,20.51650499999999,84.5274,16.185355,50,13.589855,50,13.589855,50,13.589855,15.474049999999998,16.185355,9.004150000000003,20.516505000000002];

      ctx.save();
        ctx.translate(x-size/2,y-size/2);
        ctx.scale(size/100,size/100);
        ctx.beginPath();
        ctx.moveTo(9.00415, 20.516505)
        for (var i = 0; i < pts.length; i = i + 6) {
          ctx.bezierCurveTo(pts[i],pts[i+1],pts[i+2],pts[i+3],pts[i+4],pts[i+5]);
        }
        ctx.closePath();
        ctx.fillStyle = "blue";
        ctx.fill();
      ctx.restore();
    }

    function diamond(ctx,x,y,size) {
        ctx.save();
            ctx.translate(x-size/2,y-size/2);
            ctx.scale(size/100,size/100);
            ctx.beginPath();
            ctx.moveTo(0,50);
            ctx.lineTo(50,0);
            ctx.lineTo(100,50);
            ctx.lineTo(50,100);
            ctx.closePath();
            ctx.fillStyle = "red";
            ctx.fill();
        ctx.restore();
    }

    function circle(ctx,x,y,size) {
        ctx.save();
            ctx.beginPath();
            ctx.translate(x-size/2,y-size/2);
            ctx.scale(size/100,size/100);
            ctx.arc(50,50,50,0,2*Math.PI);
            ctx.fillStyle = "yellow";
            ctx.fill();
            ctx.closePath();
        ctx.restore();
    }

    function shapes(ctx,size) {
      diamond(ctx,$scope.state.positions.username.x,$scope.state.positions.username.y,size);
      ovoid(ctx,$scope.state.positions.password.x,$scope.state.positions.password.y,size);
      if ($scope.state.login_button) {
        circle(ctx,$scope.state.positions.button.x,$scope.state.positions.button.y,size);
      }
    }
    //model
    $scope.help = "";
    $scope.attempts = 0;
    $scope.guru_meditation = "";
    $scope.startDragMouseX = 0;
    $scope.startDragMouseY = 0;
    $scope.startDragUserX = 0;
    $scope.startDragUserY = 0;
    $scope.startDragPasswdX = 0;
    $scope.startDragPasswdY = 0;
    $scope.startDragBtnX = 0;
    $scope.startDragBtnY = 0;
    $scope.picNumber = 0; //0-username,1-password,2-button


    function handleResult() {
      var data = $scope.state.pic.result;
      if (data['result'] == 'PASSED'){
        $scope.prev_button_style = "btn-prev";
        $scope.next_button_style = "btn-next";
        $scope.prev_icon_style = "btn-icon icon-arrow-left";
        $scope.next_icon_style = "btn-icon icon-arrow-right";
        $scope.state.getting_pic = false;
        $scope.getpic_success = true;       //for button status(enable/disable)
        $scope.state.pic.data = data['pic']; //base64
        $scope.state.pic.url = $scope.state.login;

        $scope.message = "Please mark UI elements";
        $scope.help = "Please drag and drop the following icons onto the correct fields in the screenshot. Adjust the positions freely if they not properly placed over the fields. <br/>";

        var screenshot = $('#screenshot_placeholder');
        var canvas = $('<canvas id="screenshot" class="screenshot" width=640 height=400 style="z-index=0"/>');
        screenshot.replaceWith(canvas);
        
        var username = $('#username_point');
        var username_pic = $('<div id="username"><img id="username_pic" draggable="true" style="cursor:move" src="../imgs/username.png"/>Username</div>');
        username.replaceWith(username_pic);
        
        
        var password = $('#password_point');
        var password_pic = $('<div id="password"><img id="password_pic" draggable="true" style="cursor:move" src="../imgs/password.png"/>Password</div>');
        password.replaceWith(password_pic);
        
        
        if ($scope.state.login_button) {
        var button = $('#button_point');
        var button_pic = $('<div id="button">&nbsp;<img id="button_pic" draggable="true" style="cursor:move" src="../imgs/button.png"/>&nbsp;&nbsp;Login</div>');
        button.replaceWith(button_pic);
        }
        

        var ctx = canvas[0].getContext('2d');
        var ox = canvas.offset().left;
        var oy = canvas.offset().top;
        var w = 640;
        var h = 400;

        var img_username = new Image();
        img_username.onload = function(){
            username_pic[0].ondragstart =  function (evt){
              $scope.picNumber = 0;
          }
        }
        img_username.src = "../imgs/username.png";

        var img_password= new Image();
        img_password.onload = function(){
            password_pic[0].ondragstart =  function (evt){
              $scope.picNumber = 1;
          }
        }
        img_password.src = "../imgs/password.png";

        var img_button= new Image();
        img_button.onload = function(){
            button_pic[0].ondragstart =  function (evt){
              $scope.picNumber = 2;
          }
        }
        img_button.src = "../imgs/button.png";

        canvas[0].ondragover = function (evt){
          evt.preventDefault();
        }
        canvas[0].ondrop = function (evt){
          evt.preventDefault();
          var canvasMouseX=evt.pageX - ox;
          var canvasMouseY=evt.pageY - oy;
          switch($scope.picNumber){
            case 0:
              $scope.state.positions.username.x = canvasMouseX;
              $scope.state.positions.username.y = canvasMouseY;
              ctx.clearRect(0,0,w,h);
              ctx.drawImage(img,0,0);
              shapes(ctx,12);
              break;
            case 1:
              $scope.state.positions.password.x = canvasMouseX;
              $scope.state.positions.password.y = canvasMouseY;
              ctx.clearRect(0,0,w,h);
              ctx.drawImage(img,0,0);
              shapes(ctx,12);
              break;
            case 2:
              $scope.state.positions.button.x = canvasMouseX;
              $scope.state.positions.button.y = canvasMouseY;
              ctx.clearRect(0,0,w,h);
              ctx.drawImage(img,0,0);
              shapes(ctx,12);
              break;
          }
        }

        canvas[0].onmousedown = function (evt){
            var canvasMouseX=evt.pageX - ox;
            var canvasMouseY=evt.pageY - oy;
            if(canvasMouseX>=$scope.state.positions.username.x-6&&canvasMouseX<$scope.state.positions.username.x+12&&canvasMouseY>=$scope.state.positions.username.y-6&&canvasMouseY<$scope.state.positions.username.y+12){
              canvas[0].onmousemove = function (evt){
                var canvasMouseX=evt.pageX - ox;
                var canvasMouseY=evt.pageY - oy;
                $scope.state.positions.username.x = $scope.startDragUserX + canvasMouseX - $scope.startDragMouseX;
                $scope.state.positions.username.y = $scope.startDragUserY + canvasMouseY - $scope.startDragMouseY;
                ctx.clearRect(0,0,w,h);
                ctx.drawImage(img,0,0);
                shapes(ctx,12);
              }
            }
            if(canvasMouseX>=$scope.state.positions.password.x-6&&canvasMouseX<$scope.state.positions.password.x+12&&canvasMouseY>=$scope.state.positions.password.y-6&&canvasMouseY<$scope.state.positions.password.y+12){
              canvas[0].onmousemove = function (evt){
                var canvasMouseX=evt.pageX - ox;
                var canvasMouseY=evt.pageY - oy;
                $scope.state.positions.password.x = $scope.startDragPasswdX + canvasMouseX - $scope.startDragMouseX;
                $scope.state.positions.password.y = $scope.startDragPasswdY + canvasMouseY - $scope.startDragMouseY;
                ctx.clearRect(0,0,w,h);
                ctx.drawImage(img,0,0);
                shapes(ctx,12);
              }
            }
            if(canvasMouseX>=$scope.state.positions.button.x-6&&canvasMouseX<$scope.state.positions.button.x+12&&canvasMouseY>=$scope.state.positions.button.y-6&&canvasMouseY<$scope.state.positions.button.y+12){
              canvas[0].onmousemove = function (evt){
                var canvasMouseX=evt.pageX - ox;
                var canvasMouseY=evt.pageY - oy;
                $scope.state.positions.button.x = $scope.startDragBtnX + canvasMouseX - $scope.startDragMouseX;
                $scope.state.positions.button.y = $scope.startDragBtnY + canvasMouseY - $scope.startDragMouseY;
                ctx.clearRect(0,0,w,h);
                ctx.drawImage(img,0,0);
                shapes(ctx,12);
              }
            }
            $scope.startDragMouseX = canvasMouseX;
            $scope.startDragMouseY = canvasMouseY;
            $scope.startDragUserX = $scope.state.positions.username.x;
            $scope.startDragUserY = $scope.state.positions.username.y;
            $scope.startDragPasswdX = $scope.state.positions.password.x;
            $scope.startDragPasswdY = $scope.state.positions.password.y;
            $scope.startDragBtnX = $scope.state.positions.button.x;
            $scope.startDragBtnY = $scope.state.positions.button.y;
          }
        canvas[0].onmouseup = function (evt){
          canvas[0].onmousemove = null;
          }

        var img = new Image();
        img.onload = function() {
          ctx.clearRect(0,0,w,h);
          ctx.drawImage(img,0,0);
          shapes(ctx,12);
        }
        img.src = $scope.state.pic.data;
      } else {
        problem(data);
      }
    }

    function problem(data) {
      $('#spinner').remove();
      $scope.state.getting_pic = false;
      $scope.prev_button_style = "btn-prev"; //for button status (enable/disable)
      $scope.prev_icon_style = "btn-icon icon-arrow-left";
      $scope.message = "Problem (see below)";
      $scope.help = "Revok has encountered an issue trying to retrieve and analyze this page. You are welcome to try again. If the problem persist, please contact <a href=\"mailto:revok-scanner-users@googlegroups.com\">revok-scanner-users@googlegroups.com</a>. ";
      if ($scope.guru_meditation.length > 0) {
        //$scope.help += "You can provide us with this guru meditation #: " + $scope.guru_meditation + ".";
      }
      $scope.state.pic.url = "d5244fa09c0f";
      window.data = data;
      $scope.prev_button_style = "btn-prev"; //for button status (enable/disable)
      $scope.prev_icon_style = "btn-icon icon-arrow-left";
    }

    function exhausted() {
      $scope.state.getting_pic = false;
      $scope.prev_button_style = "btn-prev"; //for button status (enable/disable)
      $scope.prev_icon_style = "btn-icon icon-arrow-left";
      $scope.message = "Operation timed out.";
      $scope.help = "The cluster may be under heave load. If this problem persist, please contact <a href=\"mailto:revok-scanner-users@googlegroups.com\">revok-scanner-users@googlegroups.com</a>.";
    }

    if ($scope.state.pic.url != $scope.state.login) {
      $scope.state.getting_pic = true;
      $scope.message = "Examining login page...";
      $scope.help = "An initial scan of this login page is being performed. This may take up to a minute, depending on server load.";

      function attempt(uid) {
        if ($scope.attempts++ > 30) {
          return exhausted();
        }
        $http.get('/screenshot?uid=' + uid)
        .success(function(data, status, headers, config) {
          $scope.state.pic.result = data;
          handleResult();
        })
        .error(function(data, status, headers, config) {
          if (status == 404) {
            $timeout(function() {attempt(uid)},4000);
          } else {
            problem(data);
          }
        });
      }

      $http.post('/screenshot',{"target":$scope.state.login})
      .success(function(data, status, headers, config) {
        $scope.guru_meditation = data['uid'];
        $timeout(function() {attempt(data['uid'])},4000);
      })
      .error(function(data, status, headers, config) {
        problem(data);
      });
    } else {
      handleResult();
    }

    //deal with the navigation and button status(enable or disable)
    if ($scope.state.getting_pic != false)
      $scope.state.getting_pic = true;

    $scope.getpic_success = false;
    if ($scope.state.pic.url == $scope.state.login){
      $scope.prev_button_style = "btn-prev";
      $scope.next_button_style = "btn-next";
      $scope.prev_icon_style = "btn-icon icon-arrow-left";
      $scope.next_icon_style = "btn-icon icon-arrow-right";
    }
    else{
      $scope.prev_button_style = "btn-prev btn-disable";
      $scope.next_button_style = "btn-next btn-disable";
      $scope.prev_icon_style = "btn-icon icon2-arrow-left";
      $scope.next_icon_style = "btn-icon icon2-arrow-right";
    }

    $scope.pic_prev = function (){
      if ($scope.state.getting_pic == false){
        $scope.action.nav('/normal');
      }    
    };
    $scope.pic_next = function (){
      if ($scope.state.pic.url == $scope.state.login){
        $scope.action.nav('/confirm');
      }
    };

  });

