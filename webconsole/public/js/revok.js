angular.element(document).ready(function() {
     angular.bootstrap(document,['Revok']);
   });

var revok = angular.module('Revok',['ngDialog', 'checklist-model']);
revok.config(['$routeProvider', function($routeProvider) {
    $routeProvider.otherwise({redirectTo:'/'});
    $routeProvider.when('/',{templateUrl:'welcome.html'});
    $routeProvider.when('/about_us',{templateUrl:'about_us.html'});
    $routeProvider.when('/change_log',{templateUrl:'change_log.html'});
    $routeProvider.when('/basic',{controller:'loginInfoController',templateUrl:'basic.html'});
    $routeProvider.when('/normal',{controller:'manualLoginController',templateUrl:'normal.html'});
    $routeProvider.when('/getpic',{controller: 'graphicController', templateUrl:'getpic.html'});
    $routeProvider.when('/confirm',{controller: 'confirmController', templateUrl:'confirm.html'});
    $routeProvider.when('/scan',{controller: 'scanController',templateUrl:'scan.html'});
  }]);

revok.directive('loda', function(){
    return {
        restrict: 'A',
        link: function (scope,elem,attrs){
            elem.lodaButton();
        }
    }
});
revok.directive('ngBlur', function() {
  return function( scope, elem, attrs ) {
    elem.bind('blur', function() {
      scope.$apply(attrs.ngBlur);
    });
  };
});
