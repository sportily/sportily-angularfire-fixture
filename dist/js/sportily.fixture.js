(function() {
  var module;

  module = angular.module('sportily.fixture', ['sportily.fixture.filters', 'sportily.fixture.service', 'sportily.fixture.templates']);

  module.directive('sportilyFixture', [
    'Fixture', function(Fixture) {
      return {
        restrict: 'A',
        scope: true,
        link: function(scope, element, attrs) {
          if (attrs.sportilyFixture) {
            return scope.fixture = Fixture(attrs.sportilyFixture);
          }
        }
      };
    }
  ]);

  module.directive('sportilyTimeline', function() {
    return {
      restrict: 'E',
      require: '^sportilyFixture',
      templateUrl: 'templates/sportily/fixture/timeline.html'
    };
  });

  module.directive('sportilyScores', function() {
    return {
      restrict: 'E',
      require: '^sportilyFixture',
      templateUrl: 'templates/sportily/fixture/scores.html'
    };
  });

}).call(this);

(function() {
  var module;

  module = angular.module('sportily.fixture.events', ['firebase']);

  module.factory('LiveEvents', [
    '$firebaseArray', function($firebaseArray) {
      return function(id) {
        var base, ref;
        base = 'https://blistering-fire-4761.firebaseio.com/fixtures/';
        ref = new Firebase(base + id + '/events');
        return $firebaseArray(ref);
      };
    }
  ]);

}).call(this);

(function() {
  var module, padLeft, ucfirst;

  module = angular.module('sportily.fixture.filters', []);

  ucfirst = function(str) {
    return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
  };

  padLeft = function(str, ch, len) {
    if (str.length >= len) {
      return str;
    } else {
      return padLeft(ch + str, ch, len);
    }
  };

  module.filter('person', function() {
    return function(input) {
      return ucfirst(input.given_name) + " " + ucfirst(input.family_name);
    };
  });

  module.filter('gameTime', function() {
    return function(input) {
      var duration, hours, minutes, seconds, str;
      duration = moment.duration(input);
      hours = '' + duration.hours();
      minutes = '' + duration.minutes();
      seconds = '' + duration.seconds();
      str = padLeft(minutes, '0', 2) + ':' + padLeft(seconds, '0', 2);
      if (duration.hours() > 0) {
        str = hours + ':' + str;
      }
      return str;
    };
  });

  module.filter('reverse', function() {
    return function(input) {
      if (input) {
        return input.slice().reverse();
      }
    };
  });

}).call(this);

(function() {
  var module;

  module = angular.module('sportily.fixture.service', ['sportily.api', 'sportily.fixture.events', 'sportily.fixture.state']);

  module.factory('Fixture', [
    'Fixtures', 'Participants', 'FixtureState', 'LiveEvents', '$q', function(Fixtures, Participants, FixtureState, LiveEvents, $q) {
      var Fixture;
      Fixture = (function() {
        function Fixture(id1) {
          var p1, p2;
          this.id = id1;
          p1 = this._initDetails();
          p2 = this._initParticipants();
          $q.all([p1, p2]).then((function(_this) {
            return function() {
              return _this._initEvents();
            };
          })(this));
        }

        Fixture.prototype._initDetails = function() {
          return Fixtures.one(this.id).get().then((function(_this) {
            return function(details) {
              return _this.details = details;
            };
          })(this));
        };

        Fixture.prototype._initParticipants = function() {
          return Participants.getList({
            fixture_id: this.id
          }).then((function(_this) {
            return function(participants) {
              return _this.participants = participants;
            };
          })(this));
        };

        Fixture.prototype._initEvents = function() {
          this.events = LiveEvents(this.id);
          return this.events.$loaded((function(_this) {
            return function() {
              return _this._initState();
            };
          })(this));
        };

        Fixture.prototype._initState = function() {
          this.state = FixtureState(this);
          return this.state.update();
        };

        return Fixture;

      })();
      return function(id) {
        return new Fixture(id);
      };
    }
  ]);

}).call(this);

(function() {
  var module,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  module = angular.module('sportily.fixture.state', []);

  module.factory('FixtureState', [
    '$interval', function($interval) {
      var FixtureState;
      FixtureState = (function() {
        function FixtureState(fixture1) {
          this.fixture = fixture1;
          this._updateGameTime = bind(this._updateGameTime, this);
          this.fixture.events.$watch((function(_this) {
            return function() {
              return _this.update();
            };
          })(this));
        }

        FixtureState.prototype.update = function() {
          var happendAt, isHome, lookup;
          this.inProgress = false;
          this.started = false;
          this.startedAt = null;
          this.finished = false;
          this.paused = false;
          this.pausedAt = null;
          this.pausedFor = 0;
          this.gameTime = null;
          this.scores = {
            home: 0,
            away: 0
          };
          lookup = {};
          happendAt = null;
          isHome = false;
          this.fixture.events.forEach((function(_this) {
            return function(event) {
              var happenedAt, parent;
              lookup[event.id] = event;
              happenedAt = moment(event.happened_at);
              isHome = event.entry_id === _this.fixture.details.home_entry.division_entry_id;
              switch (event.type) {
                case 'game_start':
                  _this.started = true;
                  _this.startedAt = happenedAt;
                  _this._startTimer();
                  break;
                case 'game_finish':
                  _this.finished = true;
                  _this.paused = true;
                  _this._stopTimer();
                  break;
                case 'game_pause':
                  _this.paused = true;
                  _this.pausedAt = happenedAt;
                  _this._stopTimer();
                  break;
                case 'game_resume':
                  _this.paused = false;
                  _this.pausedFor += happenedAt.diff(_this.pausedAt);
                  _this.pausedAt = null;
                  _this._startTimer();
                  break;
                case 'goal':
                  if (isHome) {
                    _this.scores.home++;
                  } else {
                    _this.scores.away++;
                  }
                  break;
                case 'own_goal':
                  if (isHome) {
                    _this.scores.away++;
                  } else {
                    _this.scores.home++;
                  }
              }
              event.game_time = happenedAt.diff(_this.startedAt) - _this.pausedFor;
              event.scores = {
                home: _this.scores.home,
                away: _this.scores.away
              };
              if (event.parent_id) {
                parent = lookup[event.parent_id];
                if (!parent.childre) {
                  parent.children = [];
                }
                return parent.children.push(event);
              }
            };
          })(this));
          this.inProgress = this.started && !this.finished;
          return this._updateGameTime();
        };

        FixtureState.prototype._updateGameTime = function() {
          var event, now, ref, ref1;
          now = (ref = this.pausedAt) != null ? ref : moment();
          this.gameTime = now.diff(this.startedAt) - this.pausedFor;
          ref1 = this.fixture.events, event = ref1[ref1.length - 1];
          if (event != null) {
            return this.gameTime = Math.max(this.gameTime, event.game_time);
          }
        };

        FixtureState.prototype._startTimer = function() {
          if (!this.timer) {
            return this.timer = $interval(this._updateGameTime, 500);
          }
        };

        FixtureState.prototype._stopTimer = function() {
          if (this.timer) {
            $interval.cancel(this.timer);
          }
          return this.timer = void 0;
        };

        return FixtureState;

      })();
      return function(fixture) {
        return new FixtureState(fixture);
      };
    }
  ]);

}).call(this);
