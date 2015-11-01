module = angular.module 'sportily.fixture.service', [
    'sportily.api'
    'sportily.fixture.events'
    'sportily.fixture.state'
]


module.factory 'Fixture', [
    'Fixtures'
    'Participants'
    'FixtureState'
    'LiveEvents'
    '$q'

    (Fixtures, Participants, FixtureState, LiveEvents, $q) ->

        class Fixture

            constructor: (@id) ->
                p1 = @_initDetails()
                p2 = @_initParticipants()
                $q.all([p1, p2]).then =>
                    @_initEvents()

            _initDetails: ->
                Fixtures.one(@id).get()
                    .then (details) => @details = details

            _initParticipants: ->
                Participants.getList fixture_id: @id
                    .then (participants) => @participants = participants

            _initEvents: ->
                @events = LiveEvents @id
                @events.$loaded => @_initState()

            _initState: ->
                @state = FixtureState @
                @state.update()


        (id) -> new Fixture id

]
