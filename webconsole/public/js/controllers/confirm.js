revok.controller('confirmController', function($scope,$http) {
   $scope.state.confirm = false; 
   $scope.confirm_button_style = "btn-next btn-disable"; 
   $scope.icon_style = "btn-icon icon2-paperplane"

   function check() {
     if($scope.state.confirm == false){
       $scope.confirm_button_style = "btn-next btn-disable";
       $scope.icon_style = "btn-icon icon2-paperplane"
     }
     else{
       $scope.confirm_button_style = "btn-next";
       $scope.icon_style = "btn-icon icon-paperplane"
     }
   };

   function valid_email(email) {
     var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
     return re.test(email);
   } 
 
   $scope.next= function(){
     $scope.state.email = "test@example.com";
     if (valid_email($scope.state.email)==false){
       $scope.state.valid_email = true;
       $scope.email_input = "form-group has-error";
     }
     else{
       $scope.state.valid_email = false;
       $scope.email_input = "form-group";
     }

     if ($scope.state.confirm == true && $scope.state.valid_email == false)
        $scope.action.nav('/scan');
   };
 
   $scope.check = check;
   
});
