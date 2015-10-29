module = angular.module 'sportily.fixture.state', []

module.factory 'FixtureState', [
    '$interval'

    ($interval) ->

        class FixtureState

            #
            # Create a new instance, and begin watching the list of events for
            # updates.
            #
            constructor: (@fixture) ->
                @fixture.events.$watch => @update()


            #
            # Reassess the current state of the game by evaluating the entire list
            # of events for the fixture.
            #
            update: ->
                @inProgress = false
                @started = false
                @startedAt = null
                @finished = false
                @paused = false
                @pausedAt = null
                @pausedFor = 0
                @gameTime = null
                @scores = home: 0, away: 0

                lookup = {}
                happendAt = null
                isHome = false

                @fixture.events.forEach (event) =>
                    lookup[event.id] = event

                    happenedAt = moment event.happened_at
                    isHome = event.entry_id == @fixture.details.home_entry.division_entry_id

                    switch event.type
                        when 'game_start'
                            @started = true
                            @startedAt = happenedAt
                            @_startTimer()

                        when 'game_finish'
                            @finished = true
                            @paused = true
                            @_stopTimer()

                        when 'game_pause'
                            @paused = true
                            @pausedAt = happenedAt
                            @_stopTimer()

                        when 'game_resume'
                            @paused = false
                            @pausedFor += happenedAt.diff @pausedAt
                            @pausedAt = null
                            @_startTimer()

                        when 'goal'
                            if isHome then @scores.home++ else @scores.away++

                        when 'own_goal'
                            if isHome then @scores.away++ else @scores.home++


                    event.game_time = happenedAt.diff(@startedAt) - @pausedFor
                    event.scores = home: @scores.home, away: @scores.away

                    if event.parent_id
                        parent = lookup[event.parent_id]
                        parent.children = [] unless parent.childre
                        parent.children.push event


                # the game is considered in progress when it's started, but not yet
                # finished, regardless of whether it's paused.
                @inProgress = @started && !@finished

                # ensure the game time starts off correctly.
                @_updateGameTime()


            #
            # Updates the game time, based on the difference between the start of
            # the game and now, taking into account any periods where the game was
            # paused. Or, if there is an event with a greater game time, use that.
            #
            _updateGameTime: =>
                # calculate the regular game time, assuming real-time input.
                now = @pausedAt ? moment()
                @gameTime = now.diff(@startedAt) - @pausedFor

                # if there is an event with a greater game time, use that.
                [..., event] = @fixture.events
                @gameTime = Math.max @gameTime, event.game_time if event?


            #
            # Start the game timer ticking up.
            #
            _startTimer: ->
                @timer = $interval @_updateGameTime, 500 unless @timer


            #
            # Stop the game timer ticking up.
            #
            _stopTimer: ->
                $interval.cancel @timer if @timer
                @timer = undefined


        #
        # Factory function to create a new FixtureState instance.
        #
        (fixture) -> new FixtureState fixture

]
