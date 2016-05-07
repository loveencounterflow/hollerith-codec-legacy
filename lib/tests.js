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

  this["codec decodes private type with custom decoder (1)"] = function(T) {
    var decoded_key, encoded_value, key, key_bfr, matcher, value;
    value = '/etc/cron.d/anacron';
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

  this._sets_are_equal = function(a, b) {

    /* TAINT doen't work for (sub-) elements that are sets or maps */
    var a_done, a_keys, a_value, b_done, b_keys, b_value, ref, ref1;
    if (!((CND.isa(a, 'set')) && (CND.isa(b, 'set')))) {
      return false;
    }
    if (a.size !== b.size) {
      return false;
    }
    a_keys = a.keys();
    b_keys = b.keys();
    while (true) {
      ref = a_keys.next(), a_value = ref.value, a_done = ref.done;
      ref1 = b_keys.next(), b_value = ref1.value, b_done = ref1.done;
      if (a_done || b_done) {
        break;
      }
      if (!CND.equals(a_value, b_value)) {
        return false;
      }
    }
    return true;
  };

  this["codec decodes private type with custom decoder (2)"] = function(T) {
    var decoded_key, encoded_value, key, key_bfr, matcher, value;
    value = new Set('qwert');
    matcher = [value];
    encoded_value = Array.from(value);
    key = [
      {
        type: 'set',
        value: encoded_value
      }
    ];
    key_bfr = CODEC.encode(key);
    decoded_key = CODEC.decode(key_bfr, function(type, value) {
      if (type === 'set') {
        return new Set(value);
      }
      throw new Error("unknown private type " + (rpr(type)));
    });
    return T.ok(this._sets_are_equal(matcher[0], decoded_key[0]));
  };

  this["Support for Sets"] = function(T) {
    var decoded_key, key, key_bfr, matcher;
    key = [new Set('qwert')];
    matcher = [new Set('qwert')];
    key_bfr = CODEC.encode(key);
    decoded_key = CODEC.decode(key_bfr);
    debug(CODEC.rpr_of_buffer(key_bfr));
    debug(CODEC.decode(key_bfr));
    debug(decoded_key);
    debug(matcher);
    return T.ok(this._sets_are_equal(matcher[0], decoded_key[0]));
  };

  this._main = function() {
    return test(this, {
      'timeout': 2500
    });
  };

}).call(this);

//# sourceMappingURL=../sourcemaps/tests.js.map
