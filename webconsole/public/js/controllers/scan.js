revok.controller('scanController', function($scope,$http) {

    $scope.message = "Requesting scan...";

    if (!$scope.state.scanning) {
      var config = {
        target:$scope.state.target,
        login:$scope.state.login,
        login_button:$scope.state.login_button,
        logtype:$scope.state.logtype,
        positions:{
          username:{
            x:Math.round($scope.state.positions.username.x/640*1280)-6,
            y:Math.round($scope.state.positions.username.y/400*800)-6,
          },
          password:{
            x:Math.round($scope.state.positions.password.x/640*1280)-6,
            y:Math.round($scope.state.positions.password.y/400*800)-6,
          },
          button:{
            x:Math.round($scope.state.positions.button.x/640*1280)-6,
            y:Math.round($scope.state.positions.button.y/400*800)-6,
          }
        },
        username:$scope.state.username,
        password:$scope.state.password,
        email:$scope.state.email,
        modules:$scope.state.modules
      };
      if ($scope.state.has_whitelist) {
        config['whitelist'] = $scope.state.whitelist;
      } else {
        config['whitelist'] = [];
      }
    }

    $http.post('/scan',config)
    .success(function(data, status, headers, config) {
      $scope.message = "Your scan request has been received. You can check ** $revok_home/report/ ** to view the report when the scan is finished.";
    })
    .error(function(data, status, headers, config) {
      $scope.message = "There was a problem requesting this scan.";
    });

    $scope.state.scanning = true;
  });

