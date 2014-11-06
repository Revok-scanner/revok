revok.controller('loginInfoController', function($scope,$timeout,$http) {
    $scope.titleMessage = "";
    $scope.URLInfo = ""
    $scope.username_input = "form-group";
    $scope.password_input = "form-group";

    $scope.btn_next_style = "btn-next";

    if($scope.state.logtype == "normal"){
        $scope.titleMessage = "Form authentication";
        $scope.URLInfo = $scope.state.login;
    }
    else{
        $scope.titleMessage = "Basic authentication";
        $scope.URLInfo = $scope.state.target;
    }

    $scope.basic_next= function(){
      if ($scope.state.password != $scope.state.repeated){
        $scope.state.valid_pass = true;
        $scope.password_input = "form-group has-error";
        }
      else{
        $scope.state.valid_pass = false;
        $scope.password_input = "form-group";
        }

      if ($scope.state.username == ""){
        $scope.state.valid_user = true;
        $scope.username_input = "form-group has-error";
        }
      else{
        $scope.state.valid_user = false;
        $scope.username_input = "form-group";
        }

      if (($scope.state.valid || $scope.state.valid_pass || $scope.state.valid_user) == false)
        $scope.action.nav('/confirm');
    };
});

