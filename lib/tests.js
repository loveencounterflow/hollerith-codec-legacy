(function() {
  var CND, CODEC, alert, badge, debug, echo, help, info, log, rpr, test, urge, warn, whisper, ƒ;

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'HOLLERITH-CODEC/tests';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  echo = CND.echo.bind(CND);

  test = require('guy-test');

  CODEC = require('./main');

  ƒ = CND.format_number;

  this["codec encodes and decodes numbers"] = function(T) {
    var key, key_bfr;
    key = ['foo', 1234, 5678];
    key_bfr = CODEC.encode(key);
    T.eq(key, CODEC.decode(key_bfr));
    return whisper("key length: " + key_bfr.length);
  };

  this["codec encodes and decodes dates"] = function(T) {
    var key, key_bfr;
    key = ['foo', new Date(), 5678];
    key_bfr = CODEC.encode(key);
    T.eq(key, CODEC.decode(key_bfr));
    return whisper("key length: " + key_bfr.length);
  };

  this["codec accepts long numbers"] = function(T) {
    var i, key, key_bfr;
    key = [
      'foo', (function() {
        var j, results;
        results = [];
        for (i = j = 0; j <= 1000; i = ++j) {
          results.push(i);
        }
        return results;
      })(), 'bar'
    ];
    key_bfr = CODEC.encode(key);
    T.eq(key, CODEC.decode(key_bfr));
    return whisper("key length: " + key_bfr.length);
  };

  this["codec accepts long texts"] = function(T) {
    var key, key_bfr, long_text;
    long_text = (new Array(1e4)).join('#');
    key = ['foo', [long_text, long_text, long_text, long_text], 42];
    key_bfr = CODEC.encode(key);
    T.eq(key, CODEC.decode(key_bfr));
    return whisper("key length: " + key_bfr.length);
  };

  this["codec accepts private type"] = function(T) {
    var key, key_bfr, markers;
    markers = CODEC['typemarkers'];
    key = [markers['private'], 'foo'];
    key_bfr = CODEC.encode(key);
    debug('©ehT4A', key_bfr, debug('©ialgj', CODEC.rpr_of_buffer(key_bfr)));
    debug('©XCwLq', CODEC.decode(key_bfr));
    T.eq(key, CODEC.decode(key_bfr));
    return whisper("key length: " + key_bfr.length);
  };

  this._main = function() {
    return test(this, {
      'timeout': 2500
    });
  };

}).call(this);

//# sourceMappingURL=../sourcemaps/tests.js.map