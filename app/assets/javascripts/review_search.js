/**
 *
 * Created by Kevin Eder. Edited by Mike Hirth.
 */

var pitchdork = angular.module('pitchdork',['ui.bootstrap','angularSpinner']);

pitchdork.service('searchService', ['$http', function($http){
    /**
     * Calls the API with a query and filters.
     * @param text - String to query.
     * @param checkedFacets - Facets to filter by.
     */
    this.search = function(text, checkedFacets){
        return $http({ method: 'GET', url: '/api/v1/artists/', params: {q: text, filter: checkedFacets} })
    };

    this.reviews = function(artist){
        return $http({ cache: true, method: 'GET', url: '/api/v1/reviews/', params: {artist: artist} })
    };
}]);

pitchdork.directive('usSpinner', ['$http', '$rootScope' ,function ($http, $rootScope){
    return {
      link: function (scope, elm, attrs) {
                elm.removeClass('ng-hide');
                scope.$on('Data_Ready', function () {
                    elm.addClass('ng-hide');
                });
            }
      };
    }]);

pitchdork.directive('metrics', ['$http', '$rootScope' ,function ($http, $rootScope){
    return {
      link: function (scope, elm, attrs) {
                elm.addClass('ng-hide');
                scope.$on('Data_Ready', function () {
                    elm.removeClass('ng-hide');
                });
            }
      };
    }]);

pitchdork.controller('SearchController', ['$scope', '$rootScope', '$modal', 'searchService', function($scope, $rootScope, $modal, searchService) {
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
        $scope.status.isopen = true;
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
     * Resets and redraws all charts.
     */
    $scope.resetAll = function() {
        dc.filterAll();
        dc.renderAll();
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

    $scope.items = [
      'The first choice!',
      'And another choice for you.',
      'but wait! A third!'
    ];

    $scope.status = {
      isopen: false
    }; 

    $scope.toggleDropdown = function($event) {
      $event.preventDefault();
      $event.stopPropagation();
      $scope.status.isopen = !$scope.status.isopen;
    };

    $scope.statsPull = function(artist) {
        reviewData = [];
        if (typeof artist !== 'undefined') {
            $scope.artist = artist;
            var result = searchService.reviews(artist);
            result.then(function(response) {
                $scope.createCharts(response.data, artist);
            }, function(reason) {
                console.log('fail: ' + reason);
            });
        } else {
            $scope.artist = 'All Artists';
            var result = searchService.reviews();
            result.then(function(response) {
                $scope.createCharts(response.data, artist);
                $scope.$broadcast('Data_Ready');
            }, function(reason) {
                console.log('fail: ' + reason);
            });
        }
    };

    $scope.createCharts = function(reviewData, artist) {
        var scoreChart = dc.lineChart("#score-chart");
        var dateChart = dc.barChart('#date-chart');
        var avgNum = dc.numberDisplay("#avg-num");
        var genreChart = dc.bubbleChart("#genre-chart");
        var distChart = dc.barChart("#dist-chart");
        var ndx                           = crossfilter(reviewData),
          reviews                         = ndx.dimension(function(d) {
            return d.score
          }),
          reviewsGroupAll                 = ndx.groupAll().reduce(
            function (p, v) {
                ++p.reviews;
                p.total += v.score;
                p.avg = (p.total / p.reviews).toFixed(2);
                return p;
            },
            function (p, v) {
                --p.reviews;
                p.total -= v.score;
                p.avg = p.reviews ? (p.total / p.reviews).toFixed(2) : 0;
                return p;
            },
            function () {
                return {reviews: 0, total: 0, avg: 0};
            }
          ),
          reviewsByDate                   = ndx.dimension(function(d) {
            return new Date(d.publish_date)
          }),
          reviewsByAvg                    = ndx.dimension(function(d) {
            return Math.floor(d.score)
          }),
          reviewsGroupRoundScore          = reviewsByAvg.group().reduce(
            function (p, v) {
                ++p.reviews;
                p.total += v.score;
                p.avg = Math.floor(p.total / p.reviews);
                return p;
            },
            function (p, v) {
                --p.reviews;
                p.total -= v.score;
                p.avg = p.reviews ? Math.floor(p.total / p.reviews) : 0;
                return p;
            },
            function () {
                return {reviews: 0, total: 0, avg: 0};
            }
          ),
          reviewsGroupByScore              = reviewsByDate.group().reduce(
            function (p, v) {
                ++p.reviews;
                p.total += v.score;
                p.avg = (p.total / p.reviews).toFixed(2);
                p.artist = v.artist;
                p.album = v.album_title;
                return p;
            },
            function (p, v) {
                --p.reviews;
                p.total -= v.score;
                p.avg = p.reviews ? (p.total / p.reviews).toFixed(2) : 0;
                p.artist = v.artist;
                p.album = v.album_title;
                return p;
            },
            function () {
                return {reviews: 0, total: 0, avg: 0, artist: "", album: ""};
            }
          ),
          reviewsByGenre                    = ndx.dimension(function(d) {
            var top_genres = ['rock','pop','rap','hip hop','electronic','indie','jazz','psychedelic','techno','noise','indie rock','lofi','r&b','indie pop','experimental'];
            var genre = d.genre;
            var i = top_genres.indexOf(d.genre);
            if(i >= 0) {
                genre = d.genre;  
            } else {
                genre = 'other';
            }
            return genre;
          }),
          genreReviewsGroupByTotal          = reviewsByGenre.group().reduceCount(),
          genreReviewsGroupByScore          = reviewsByGenre.group().reduce(
            function (p, v) {
                ++p.reviews;
                p.total += v.score;
                p.total_length += v.html.length;
                p.avg = (p.total / p.reviews).toFixed(2);
                p.len = (p.total_length / p.reviews).toFixed(2);
                var top_genres = ['rock','pop','rap','hip hop','electronic','indie','jazz','psychedelic','techno','noise','indie rock','lofi','r&b','indie pop','experimental'];
                var i = top_genres.indexOf(v.genre);
                if(i >= 0) {
                    p.genre = v.genre;  
                } else {
                    p.genre = 'other';
                }
                return p;
            },
            function (p, v) {
                --p.reviews;
                p.total -= v.score;
                p.total_length -= v.html.length;
                p.avg = p.reviews ? (p.total / p.reviews).toFixed(2) : 0;
                p.len = p.reviews ? (p.total_length / p.reviews).toFixed(2) : 0;
                p.genre = v.genre;
                var top_genres = ['rock','pop','rap','hip hop','electronic','indie','jazz','psychedelic','techno','noise','indie rock','lofi','r&b','indie pop','experimental'];
                var i = top_genres.indexOf(v.genre);
                if(i >= 0) {
                    p.genre = v.genre;  
                } else {
                    p.genre = 'other';
                }
                return p;
            },
            function () {
                return {reviews: 0, total: 0, avg: 0, genre: '', total_length: 0};
            }
          );

        scoreChart
        .width(570)
        .height(180)
        .x(d3.time.scale()
          .domain([new Date(reviewData[0].publish_date),new Date(reviewData[reviewData.length-1].publish_date)]))
        .ordering(function(d) { return d.key })
        .xUnits(d3.time.years)
        .y(d3.scale.linear().domain([0, 10.5]))
        .yAxisLabel("Average Score")
        .rangeChart(dateChart)
        .brushOn(false)
        .renderTitle(true)
        .title(function(d) {

            return [
                "Artist: " + d.data.value.artist,
                "Album: " + d.data.value.album,
                "Score: " + d.data.value.avg
            ].join("\n");
        })
        .dimension(reviewsByDate)
        .group(reviewsGroupByScore).valueAccessor(function (d) {
            return d.value.avg;
        });

        dateChart
        .width(570)
        .height(40)
        .margins({top: 0, right: 50, bottom: 20, left: 40})
        .dimension(reviewsByDate)
        .group(reviewsGroupByScore).valueAccessor(function (d) {
            return d.value.avg;
        })
        .centerBar(true)
        .gap(50)
        .x(d3.time.scale()
          .domain([new Date(reviewData[0].publish_date),new Date(reviewData[reviewData.length-1].publish_date)]))
        .xUnits(d3.time.months)
        .yAxis().ticks(0);

        avgNum
        .formatNumber(d3.format(".3s"))
        .group(reviewsGroupAll).valueAccessor(function (d) { 
          return d.avg;
        });

        genreChart
        .dimension(reviewsByGenre)
        .group(genreReviewsGroupByScore)
        .x(d3.scale.linear().domain([0, genreReviewsGroupByTotal.top(1)[0].value + 50]))
        .y(d3.scale.linear().domain([0, 10]))
        .colors(colorbrewer.RdYlGn[9])
        .colorDomain([0, 10])
        .colorAccessor(function (d){return d.value.avg;})
        .width(1140)
        .height(350)
        .margins({top: 10, right: 50, bottom: 50, left: 40})
        .elasticY(true)
        .elasticX(true)
        .yAxisPadding('10%')
        .xAxisPadding('10%')
        .maxBubbleRelativeSize(0.3)
        .xAxisLabel('Average Review Length (characters)')
        .yAxisLabel('Average Score')
        .label(function (p) {
            return p.value.genre;
        })
        .renderLabel(true)
        .title(function (p) {
            
            return [
                   "Echonest genre: " + p.value.genre,
                   "Number Reviews: " + p.value.reviews,
                   "Average Review Length: " + p.value.len,
                   "Average Score: " + p.value.avg,
                   ]
                   .join("\n");
        })
        .renderTitle(true)
        .renderHorizontalGridLines(true)
        .renderVerticalGridLines(true)
        .maxBubbleRelativeSize(0.3)
        .keyAccessor(function (p) {
            return p.value.len;
        })
        .valueAccessor(function (p) {
            return p.value.avg;
        })
        .radiusValueAccessor(function (p) {
            return p.value.reviews / 500;
        });

        distChart
        .width(570)
        .height(180)
        .margins({top: 10, right: 50, bottom: 40, left: 50})
        .x(d3.scale.ordinal().domain([0,1,2,3,4,5,6,7,8,9,10]))
        .xUnits(dc.units.ordinal)
        .xAxisLabel('Score')
        .yAxisLabel('Number Reviews') 
        .brushOn(false)
        .dimension(reviewsByAvg)
        .centerBar(true)
        .group(reviewsGroupRoundScore)
        .title(function (d) {
            return d.data.value.reviews + " reviews";
        })
        .renderTitle(true)
        .keyAccessor(function (d) {
            return d.value.avg;
        }).valueAccessor(function (d) {
            return d.value.reviews;
        });

        dc.renderAll();
    };

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



