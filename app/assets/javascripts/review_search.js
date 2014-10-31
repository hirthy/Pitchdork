/**
 *
 * Created by keder on 9/16/14.
 */

var pitchdork = angular.module('pitchdork',['ui.bootstrap']);

pitchdork.service('searchService', ['$http', function($http){
    this.search = function(text, checkedFacets){
        return $http({ method: 'GET', url: '/api/v1/reviews/', params: {q: text, filter: checkedFacets} })
    };
}]);

pitchdork.controller('SearchController', ['$scope', '$modal', 'searchService', function($scope, $modal, searchService) {
    var checkFacetItems = function(oldFacets, newFacets) {

        // Recheck facet checkboxes
        for (var key in oldFacets) {
            var facetOptions = oldFacets[key];
            if (!newFacets.hasOwnProperty(key)) {
                continue;
            }

            for (var i = 0; i < facetOptions.length; i++) {
                var facetOption = facetOptions[i];
                if (facetOption.checked) {
                    var newFacetOptions = newFacets[key];

                    for (var j = 0; j < newFacetOptions.length; j++) {
                        var newFacetOption = newFacetOptions[j];

                        if (newFacetOption.term === facetOption.term) {
                            newFacets[key][j].checked = true;
                        }
                    }
                }
            }
        }

        return newFacets;
    };

    var getCheckedFacets = function(facets) {
        var results = {};

        for (var key in facets) {
            var facetOptions = facets[key];

            for (var i = 0; i < facetOptions.length; i++) {
                var facetOption = facetOptions[i];

                if (facetOption.checked) {
                    if (key in results) {
                        results[key].push(facetOption.term)
                    }
                    else {
                        results[key] = [facetOption.term];
                    }
                }
            }
        }

        return results;
    }

    $scope.searchClick = function() {
        var checkedFacets = (typeof $scope.facets != 'undefined') ? getCheckedFacets($scope.facets) : {};
        var result = searchService.search($scope.searchText, checkedFacets);
        console.log(result);
        result.then(function(response) {
            $scope.results = response.data.hits;
            var oldFacets = $scope.facets;
            $scope.facets = response.data.facets;

            if (!angular.isUndefined(oldFacets)) {
                checkFacetItems(oldFacets, $scope.facets);
            }

        }, function(reason) {
            console.log('fail: ' + reason);
        });
    };

    $scope.open = function (facetName) {
        var backupFacets = $scope.facets;

        var modalInstance = $modal.open({
            templateUrl: 'facetModal.html',
            scope: $scope,
            controller: 'FacetModalController',
            resolve : {
                facetName: function() {
                    return facetName;
                }
            }
        });

        modalInstance.result.then(function() {
            $scope.searchClick();
        }, function () {
            $scope.facets = backupFacets;
        });
    }
}]);

pitchdork.controller('FacetModalController', ['$scope', '$modalInstance', 'facetName',
    function($scope, $modalInstance, facetName) {
        $scope.facetName = facetName;

        for (var key in $scope.facets) {
            if (key === facetName) {
                $scope.modalFacetKey = key;
            }
        }

        $scope.close = function () {
            $modalInstance.close();
        }
    }
]);




