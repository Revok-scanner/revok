revok.controller('loginDetectController', function($scope,$timeout,$http) {
        

        $scope.detectMessage=""; //for debug
        $scope.suggestion1 =  "";
        $scope.suggestion2 =  "";
        $scope.need_suggest = false;
        $scope.user_input_error = "";
        $scope.need_error_log = false;
        $scope.need_http_error_log = false;
        $scope.input_style = "form-group";
        $scope.button_style = "loda-btn";
        $scope.event=window.event;
        $scope.key=0;
        var working_flag = false;

        function check_input () {
            $scope.need_error_log = false;
            $scope.need_http_error_log = false;
            $scope.input_style = "form-group";
            var loda = $('.loda-btn');
            loda.lodaButton('stop');
            if ($scope.state.target.indexOf('http://') == 0 || $scope.state.target.indexOf('https://') == 0){
                $scope.need_suggest = false;
                $scope.key=0;
            }
            else{
                var i = $scope.state.target.length;
                if ((i<7 && 'http://'.substring(0,i) == $scope.state.target )||(i<8 && 'https://'.substring(0,i) == $scope.state.target)){
                        $scope.need_suggest = false;
                        $scope.key=0;
                    }
                else{
                    $scope.need_suggest = true;
                    $scope.suggestion1 = 'http://' + $scope.state.target;
                    $scope.suggestion2 = 'https://' + $scope.state.target;
                }
            }
        };

        function select_http(){
            $scope.state.target = $scope.suggestion1;
            check_input();
            angular.element("#target").focus();
        };

        function select_https(){
            $scope.state.target = $scope.suggestion2;
            check_input();
            angular.element("#target").focus();
        };
        function clear_userinfo(){
            $scope.state.username = "";
            $scope.state.password = "";
            $scope.state.repeated = "";
            $scope.state.login = "";
        };

        function send_request() {
            if(working_flag == true){
                return;
            }
            clear_userinfo();
            if ($scope.state.target == ''){
                $scope.input_style = "form-group has-error";
                $scope.user_input_error = "URL is empty.";
                $scope.need_error_log = true;
            }
            else if($scope.state.target.indexOf('http://') != 0 && $scope.state.target.indexOf('https://') != 0){
                $scope.need_http_error_log = true;
                $scope.input_style = "form-group has-error";
                $timeout(suggestion_appear,150);
            }
            else
            {
                working_flag = true;
                $('input').attr('readonly', true); //the jquery code
                $scope.button_style = "loda-btn loda-btn-disable";
                var loda = $('.loda-btn');
                loda.lodaButton('start');
                $scope.state.whitelist=[$scope.state.target.split('//')[1].split('/')[0].split(':')[0]];
                $scope.detectMessage="Detecting the login URL";
                $http.post('/login_detect', {"target":$scope.state.target})
                .success(function(data, status, headers, config) {
                    if(data['found'] == "true"){
                        if(data['logtype'] == "basic"){
                            $scope.state.logtype = data['logtype'];
                            $scope.state.login = data['login'];
                            $scope.state.auto_detect = true;
                            $scope.action.nav('/basic');
                        }
                        else{
                            var login_url = data['login'];
                            var login_type = data['logtype'];
                            $http.post('/login_fill',{"login":login_url,"username":"admin","password":"password"})
                            .success(function(data, status, headers, config) {
                                if(data['filled'] == "true"){
                                    $scope.state.login = login_url;
                                    $scope.state.logtype = login_type;
                                    $scope.state.login_message = data['msg'];
                                    $scope.state.auto_detect = true;
                                    $scope.action.nav('/basic');
                                }
                                else{
                                    $scope.state.logtype = login_type;
                                    $scope.state.login = login_url;
                                    $scope.state.auto_detect =  false;
                                    $scope.action.nav('/normal');
                                }
                            })
                            .error(function(data, status, headers, config) {
                                $scope.detectMessage = "Fill form wrong, Please try it again.";
                            });
                        }
                    }
                    else{
                        if(data['valid'] == 'false'){
                            $('input').attr('readonly', false);//jquery code
                            loda.lodaButton('stop');
                            $scope.button_style = "loda-btn";
                            $scope.input_style = "form-group has-error";
                            $scope.user_input_error = "Unreachable";
                            $scope.need_error_log = true;
                            working_flag = false;
                        }
                        else{
                            $scope.state.logtype = "none"
                            $scope.state.auto_detect = false;
                            $scope.action.nav('/normal');
                        }
                    }
                })
                .error(function(data, status, headers, config) {
                    $scope.detectMessage = "Servers Error, Please try again.";
                });
            }
        };
        function suggestion_appear(){
            $scope.need_suggest = true;
        }
        function suggestion_disappear(){
            $scope.need_suggest = false;
            $scope.key=0;
        }

        function do_blur() {
           $timeout(suggestion_disappear, 130);
        };

        function keypress(e) {
            e.KeyCode = e.which || e.keyCode;
            if(e.KeyCode == 13){
                send_request();
            }
            if($scope.need_suggest){
                if($scope.key==0){
                      if(e.KeyCode == 0x26){
                          $scope.state.target = $scope.suggestion2;
                          $scope.https_suggestion = "selected_suggestion";
                          $scope.key=1;
                      }else if( e.KeyCode == 0x28){

                          $scope.state.target = $scope.suggestion1;
                          $scope.http_suggestion = "selected_suggestion";
                          $scope.key=1;
                      }else{
                          $scope.http_suggestion = "unselected_suggestion";
                          $scope.https_suggestion = "unselected_suggestion";
                      }         
                }else{
                    if(e.KeyCode == 0x26){
                        $scope.state.target = $scope.suggestion1;
                        $scope.https_suggestion = "unselected_suggestion";
                        $scope.http_suggestion = "selected_suggestion";
                    }
                    if( e.KeyCode == 0x28){
                        $scope.state.target = $scope.suggestion2;
                        $scope.http_suggestion = "unselected_suggestion";
                        $scope.https_suggestion = "selected_suggestion";
                    }
                }
            }
            
        };

        $scope.keypress = keypress;
        $scope.request_detect = send_request;
        $scope.check_input = check_input;
        $scope.select_http = select_http;
        $scope.select_https = select_https;
        $scope.do_blur = do_blur;
    });
