revok.controller('confirmController', function($scope,$http,ngDialog) {
   $scope.state.confirm = false; 
   $scope.confirm_button_style = "btn-next btn-disable"; 
   $scope.icon_style = "btn-icon icon2-paperplane";
   $scope.hide_ani = false;
   $scope.loaded = true;
   var dialog;

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

   $scope.openModuleDialog = function () {
     if (!$scope.modules) {
       $http.get('/modules_list')
       .success(function(data, status, headers, config) {
         $scope.modules = data;
         $scope.choose = {
           modules: angular.copy($scope.modules)
         };
         $scope.hide_ani = true;
         $scope.loaded = false;
       });
     } else {
       $scope.loaded = false;
     }
     dialog = ngDialog.open({template: "module_dialog.html", scope: $scope});
   };

   $scope.batchSelect = function (element) {
     element.checked = !element.checked;
     if (!element.checked) {
       $scope.choose = {
         modules: angular.copy($scope.modules)
       };
     } else {
       $scope.choose = {
         modules: []
       };
     }
   };

   $scope.moduleConfirm = function () {
     var i;
     var modules = new Array();
     if ($scope.modules.length == $scope.choose.modules.length) {
       $scope.state.modules = ['all'];
       ngDialog.close(dialog.id);
       return;
     }
     for (i in $scope.choose.modules) {
       modules[i] = $scope.choose.modules[i].name;
     }
     $scope.state.modules = modules;
     ngDialog.close(dialog.id);
   };
});
