module = angular.module 'sportily.fixture.events', ['firebase']

module.factory 'LiveEvents', [
    '$firebaseArray'

    ($firebaseArray) ->

        (id) ->
            base = 'https://blistering-fire-4761.firebaseio.com/fixtures/'
            ref = new Firebase base + id + '/events'
            $firebaseArray ref

]
