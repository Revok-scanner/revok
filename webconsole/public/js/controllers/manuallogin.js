revok.controller('manualLoginController', function($scope,$timeout) {
    $scope.username_input = "form-group";
    $scope.password_input = "form-group";
    $scope.login_input = "form-group";

    $scope.need_suggest = false;
    $scope.suggestion1 =  "http://";
    $scope.suggestion2 =  "https://";
    $scope.key=0;
    $scope.error_info = "";

    $scope.check_input = function() {
            $scope.state.valid = false;
            $scope.login_input = "form-group";
            if ($scope.state.login.indexOf('http://') == 0 || $scope.state.login.indexOf('https://') == 0 || $scope.state.valid_user || $scope.state.valid_pass || $scope.state.valid){
                $scope.need_suggest = false;
                $scope.key=0;
            }
            else{
                var i = $scope.state.login.length;
                if ((i<7 && 'http://'.substring(0,i) == $scope.state.login )||(i<8 && 'https://'.substring(0,i) == $scope.state.login)){
                        $scope.need_suggest = false;
                        $scope.key=0;
                    }
                else{
                    $scope.need_suggest = true;
                    $scope.suggestion1 = 'http://' + $scope.state.login;
                    $scope.suggestion2 = 'https://' + $scope.state.login;
                }
                }
        };
    $scope.select_http = function (){
            $scope.state.login = $scope.suggestion1;
            $scope.check_input();
            angular.element("#login_url").focus();
        };

    $scope.select_https = function (){
            $scope.state.login = $scope.suggestion2;
            $scope.check_input();
            angular.element("#login_url").focus();
        };
    function suggestion_appear(){
            $scope.need_suggest = true;
        }
    function suggestion_disappear(){
            $scope.need_suggest = false;
            $scope.key=0;
        }

    $scope.do_blur = function () {
           $timeout(suggestion_disappear, 130);
        };

    $scope.normal_next= function(){
      if ($scope.state.logtype == "none"){
        $scope.action.nav('/confirm');
      }
      else{
        if ($scope.state.login == ''){
            $scope.error_info = "login URL can not be empty";
            $scope.state.valid = true;
            $scope.login_input = "form-group has-error";
        }

        else if($scope.state.login.indexOf('http://') != 0 && $scope.state.login.indexOf('https://') != 0){
             $scope.error_info = "URL incorrect; specify http:// or https://";
             $scope.state.valid = true;
             $scope.login_input = "form-group has-error";
        }
        else{
          $scope.state.valid = false;
          $scope.login_input = "form-group";
        }
        

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
          $scope.action.nav('/getpic');
      }
    };


    $scope.keypress = function (e) {
        e.KeyCode = e.which || e.keyCode;
        if($scope.need_suggest){
              if($scope.key==0){
                    if(e.KeyCode == 0x26){
                        $scope.state.login = $scope.suggestion2;
                        $scope.https_suggestion = "selected_suggestion";
                         $scope.key=1;
                    }else if( e.KeyCode == 0x28){
                        $scope.state.login = $scope.suggestion1;
                        $scope.http_suggestion = "selected_suggestion";
                        $scope.key=1;
                    }else{
                        $scope.http_suggestion = "unselected_suggestion";
                        $scope.https_suggestion = "unselected_suggestion";
                    }        
              }else{
                    if(e.KeyCode == 0x26){
                        $scope.state.login = $scope.suggestion1;
                        $scope.https_suggestion = "unselected_suggestion";
                        $scope.http_suggestion = "selected_suggestion";
                    }
                    if( e.KeyCode == 0x28){
                        $scope.state.login = $scope.suggestion2;
                        $scope.http_suggestion = "unselected_suggestion";
                        $scope.https_suggestion = "selected_suggestion";
                    }
                    if(e.KeyCode == 13){
                        $scope.need_suggest = false;
                        $scope.key=0;
                    }
              }
        }

    };




});
