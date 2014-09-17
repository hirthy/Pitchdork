/**
 *
 * Created by keder on 9/16/14.
 */

var pitchdork = angular.module('pitchdork',[]);

pitchdork.controller('SearchController', ['$scope', '$http', function($scope, $http) {
 $http({ method: 'GET', url: '/api/v1/reviews/' }).
    success(function (data, status, headers, config) {
        console.log('success');
        console.log(data);
    }).
    error(function (data, status, headers, config) {
        console.log('failure');
        console.log(data);
    });

    $scope.greeting = 'hello!';
}]);


