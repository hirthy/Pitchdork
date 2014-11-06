/**
 *
 * Created by Kevin Eder.
 */

var pitchdork = angular.module('pitchdork',['ui.bootstrap']);

pitchdork.service('searchService', ['$http', function($http){
    /**
     * Calls the API with a query and filters.
     * @param text - String to query.
     * @param checkedFacets - Facets to filter by.
     */
    this.search = function(text, checkedFacets){
        return $http({ method: 'GET', url: '/api/v1/reviews/', params: {q: text, filter: checkedFacets} })
    };
}]);

pitchdork.controller('SearchController', ['$scope', '$modal', 'searchService', function($scope, $modal, searchService) {
    /**
     * Sets newFacets checked states to match oldFacets.
     * @param oldFacets - List containing checked states.
     * @param newFacets - List containing facets to be rechecked.
     */
    var checkFacetItems = function(oldFacets, newFacets) {
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

    /**
     * Finds facets which have been checked.
     * @param facets - Facets to search.
     */
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
    };

    /**
     * Executes query using the searchService.
     */
    $scope.searchClick = function() {
        var checkedFacets = (typeof $scope.facets != 'undefined') ? getCheckedFacets($scope.facets) : {};
        var result = searchService.search($scope.searchText, checkedFacets);
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

    /**
     * Opens Facet dialog, saves away current facet checked states in case the dialog is dismissed.
     * @param facetName - Name of facet the user is opening a dialog for.
     */
    $scope.open = function (facetName) {
        var origFacets = {};
        angular.copy($scope.facets, origFacets);

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
            $scope.facets = origFacets;
        });
    }
}]);

/**
 * Handles the facet modal logic.
 */
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
        };

        $scope.cancel = function () {
            $modalInstance.dismiss('cancel');
        };
    }
]);




