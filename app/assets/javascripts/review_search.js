/**
 *
 * Created by keder on 9/16/14.
 */

var pitchdork = angular.module('pitchdork',[]);

pitchdork.service('searchService', ['$http', function($http){
    this.search = function(text){
        return $http({ method: 'GET', url: '/api/v1/reviews/', params: {q: text} })
    };
}]);

pitchdork.controller('SearchController', ['$scope', 'searchService', function($scope, searchService) {
    $scope.searchClick = function() {
        var result = searchService.search($scope.searchText);
        result.then(function(response) {
            $scope.results = response.data
            console.log(response);
        }, function(reason) {
            console.log('fail: ' + reason);
        });
    };
}]);



