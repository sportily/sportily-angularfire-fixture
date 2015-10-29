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

    (Fixtures, Participants, FixtureState, LiveEvents) ->

        class Fixture

            constructor: (@id) ->
                @_initDetails()
                @_initParticipants()
                @_initEvents()
                @_initState()

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
