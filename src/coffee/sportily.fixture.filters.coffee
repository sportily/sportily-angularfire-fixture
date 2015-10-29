module = angular.module 'sportily.fixture.filters', []


ucfirst = (str) ->
    str.charAt(0).toUpperCase() + str.slice(1).toLowerCase()


padLeft = (str, ch, len) ->
    if str.length >= len then str else padLeft(ch + str, ch, len)


module.filter 'person', ->
    (input) ->
        ucfirst(input.given_name) + " " + ucfirst(input.family_name)


module.filter 'gameTime', ->
    (input) ->
        duration = moment.duration input
        hours = '' + duration.hours()
        minutes = '' + duration.minutes()
        seconds = '' + duration.seconds()
        str = padLeft(minutes, '0', 2) + ':' + padLeft(seconds, '0', 2)
        str = hours + ':' + str if duration.hours() > 0
        str


module.filter 'reverse', ->
    (input) ->
        input.slice().reverse() if input
