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

  this["codec accepts private type (1)"] = function(T) {
    var key, key_bfr;
    key = [
      {
        type: 'price',
        value: 'abc'
      }
    ];
    key_bfr = CODEC.encode(key);
    return T.eq(key, CODEC.decode(key_bfr));
  };

  this["codec accepts private type (2)"] = function(T) {
    var key, key_bfr;
    key = [
      123, 456, {
        type: 'price',
        value: 'abc'
      }, 'xxx'
    ];
    key_bfr = CODEC.encode(key);
    return T.eq(key, CODEC.decode(key_bfr));
  };

  this["codec decodes private type with custom decoder"] = function(T) {
    var decoded_key, encoded_value, key, key_bfr, matcher, value;
    value = '/usr/local/lib/node_modules/coffee-script/README.md';
    matcher = [value];
    encoded_value = value.split('/');
    key = [
      {
        type: 'route',
        value: encoded_value
      }
    ];
    key_bfr = CODEC.encode(key);
    decoded_key = CODEC.decode(key_bfr, function(type, value) {
      if (type === 'route') {
        return value.join('/');
      }
      throw new Error("unknown private type " + (rpr(type)));
    });
    return T.eq(matcher, decoded_key);
  };

  this["private type takes default shape when handler returns use_fallback"] = function(T) {
    var decoded_key, key, key_bfr, matcher;
    matcher = [
      84, {
        type: 'bar',
        value: 108
      }
    ];
    key = [
      {
        type: 'foo',
        value: 42
      }, {
        type: 'bar',
        value: 108
      }
    ];
    key_bfr = CODEC.encode(key);
    decoded_key = CODEC.decode(key_bfr, function(type, value, use_fallback) {
      if (type === 'foo') {
        return value * 2;
      }
      return use_fallback;
    });
    return T.eq(matcher, decoded_key);
  };

  this._main = function() {
    return test(this, {
      'timeout': 2500
    });
  };

}).call(this);

//# sourceMappingURL=../sourcemaps/tests.js.map