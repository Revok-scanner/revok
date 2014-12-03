revok.controller('stateController',function($scope,$location,ngDialog) {

    $scope.root = "";

    if ($location.path() != '' && $location.path() != '/') {
      document.location = $scope.root;
    };

    $scope.state = {
      target:"",
      login:"",
      login_button:true,
      has_whitelist:true,
      whitelist:"1",
      logtype:"none",
      valid:false,
      valid_pass:false,
      valid_user:false,
      valid_email:false,
      positions:{
        username:{x:-100,y:-100},
        password:{x:-100,y:-100},
        button:{x:-100,y:-100},
      },
      username:"",
      password:"",
      repeated:"",
      email:"",
      getting_pic:true,
      pic:{
        url:'d5244fa09c0f',
        data:'',
        result:null,
      },
      login_message:"",
      auto_detect:false,
      modules:["all"]
    };

    $scope.action = {
      nav: function(url) {
        $location.path(url);
      },
      lognav: function() {
        $location.path(
          {
            'normal':'/normal',
            'basic':'/basic',
            'none':'/confirm',
          }[$scope.state.logtype]
        );
      },
      back: function() {
        if ($scope.state.auto_detect == true){
          $location.path('/basic');
        }
        else{
          $location.path(
            {
              'basic':'/basic',
              'normal':'/getpic',
              'none':'/normal',
            }[$scope.state.logtype]
          );
        }
      },
      backcred: function() {
        $location.path(
          {
            'basic':'/logtype',
            'normal':'/getpic',
          }[$scope.state.logtype]
        );
      },
    };

    $scope.$on("$locationChangeStart", function(event, next, current) {
      if ($scope.state.scanning) {
        event.preventDefault();
        $scope.state.scanning = false;
        document.location = $scope.root;
      }
    });

    $scope.next= function(){
      $scope.action.lognav();
      $scope.state.whitelist=[$scope.state.target.split('//')[1].split('/')[0].split(':')[0]];
      $scope.state.valid = false;
    };

  });

