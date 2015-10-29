module = angular.module 'sportily.fixture', [
    'sportily.fixture.filters'
    'sportily.fixture.service'
    'sportily.fixture.templates'
]

module.directive 'sportilyFixture', [ 'Fixture', (Fixture) ->
    restrict: 'A'
    scope: true

    link: (scope, element, attrs) ->
        if attrs.sportilyFixture
            scope.fixture = Fixture attrs.sportilyFixture

]


module.directive 'sportilyTimeline', ->
    restrict: 'E'
    require: '^sportilyFixture'
    templateUrl: 'templates/sportily/fixture/timeline.html'


module.directive 'sportilyScores', ->
    restrict: 'E'
    require: '^sportilyFixture'
    templateUrl: 'templates/sportily/fixture/scores.html'
