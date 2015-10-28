module = angular.module 'sportily.fixture.service',  [
    'sportily.api'
    'firebase'
]

module.factory 'FixtureFactory', (Fixtures, $firebaseArray) ->

    class Fixture

        constructor: (@id) ->
            @_initDetails()
            @_initEvents()

        _initDetails: ->
            Fixtures.one(@id).get().then (details) -> @details = details

        _initEvents: ->
            ref = new Firebase 'https://blistering-fire-4761.firebaseio.com/fixtures/' + @id + '/events'
            @events = $firebaseArray ref


    class FixtureFactory

        constructor: () ->

        get: (id) ->
            new Fixture id


    new FixtureFactory()


###
#
# The fixture model object provides a convenient mechanism for working with
# fixtures and events of fixtures.
#
class Fixture

    constructor: (@q, @interval, @details, @events, @participants) ->
        #@_updateGameState()
        #@_linkEvent event for event in @events


    _linkEvent: (event) ->
        if event.parent_id
            parent = @events.lookup[event.parent_id]
            parent.children = [] unless parent.children
            parent.children.push event


    _updateGameTime: =>
        # calculate the regular game time, assuming real-time input.
        now = @state.pausedAt ? moment()
        @state.gameTime = now.diff(@state.startedAt) - @state.pausedFor

        # if there is an event with a greater game time, use that.
        [..., event] = @events
        @state.gameTime = Math.max @state.gameTime, event.game_time if event?


    _updateGameState: =>
        @state =
            inProgress: false
            started: false
            startedAt: null
            finished: false
            paused: false
            pausedAt: null
            pausedFor: 0
            gameTime: null

        happenedAt = null
        @events.forEach (event) =>
            happenedAt = moment event.happened_at

            switch event.type
                when 'game_start'
                    @state.started = true
                    @state.startedAt = happenedAt
                    @_startTimer()

                when 'game_finish'
                    @state.finished = true
                    @state.paused = true
                    @_stopTimer()

                when 'game_pause'
                    @state.paused = true
                    @state.pausedAt = happenedAt
                    @_stopTimer()

                when 'game_resume'
                    @state.paused = false
                    @state.pausedFor += happenedAt.diff @state.pausedAt
                    @state.pausedAt = null
                    @_startTimer()

            event.game_time = happenedAt.diff(@state.startedAt) - @state.pausedFor


        # the game is considered in progress when it's started, but not yet
        # finished, regardless of whether it's paused.
        @state.inProgress = @state.started && !@state.finished

        # ensure the game time starts off correctly.
        @_updateGameTime()


#
# The fixture service is responsible for fetching details and events for a
# fixture, then wrapping those details in a new fixture model object.
#
class FixtureService

    constructor: (@q, @interval, @Fixtures, @Events, @Participants) ->

    get: (id) ->
        promises =
            details: @_details id
            events: @_events id
            participants: @_participants id

        @q.all(promises).then (data) =>
            { details, events, participants } = data
            new Fixture @q, @interval, details, events, participants


    _details: (id) ->
        @Fixtures.one(id).get()


    _events: (id) ->
        @Events.getList fixture_id: id


    _participants: (id) ->
        @Participants.getList fixture_id: id


# expose the fixture service as an angular service.
module.service 'FixtureService', [
    '$q'
    '$interval'
    'Fixtures'
    'Events'
    'Participants'
    FixtureService
]###
