(function() {
  var CND, _decode, _encode, _invert_buffer, badge, bytecount_date, bytecount_number, bytecount_singular, bytecount_typemarker, debug, grow_rbuffer, rbuffer, rbuffer_max_size, rbuffer_min_size, read_date, read_list, read_nnumber, read_pnumber, read_private, read_singular, read_text, release_extraneous_rbuffer_bytes, rpr, symbol_fallback, tm_date, tm_false, tm_hi, tm_list, tm_lo, tm_ninfinity, tm_nnumber, tm_null, tm_pinfinity, tm_pnumber, tm_private, tm_text, tm_true, warn, write, write_date, write_infinity, write_number, write_private, write_singular, write_text;

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'HOLLERITH/CODEC';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  CND.shim();

  this['typemarkers'] = {};

  tm_lo = this['typemarkers']['lo'] = 0x00;

  tm_null = this['typemarkers']['null'] = 'B'.codePointAt(0);

  tm_false = this['typemarkers']['false'] = 'C'.codePointAt(0);

  tm_true = this['typemarkers']['true'] = 'D'.codePointAt(0);

  tm_list = this['typemarkers']['list'] = 'E'.codePointAt(0);

  tm_date = this['typemarkers']['date'] = 'G'.codePointAt(0);

  tm_ninfinity = this['typemarkers']['ninfinity'] = 'J'.codePointAt(0);

  tm_nnumber = this['typemarkers']['nnumber'] = 'K'.codePointAt(0);

  tm_pnumber = this['typemarkers']['pnumber'] = 'L'.codePointAt(0);

  tm_pinfinity = this['typemarkers']['pinfinity'] = 'M'.codePointAt(0);

  tm_text = this['typemarkers']['text'] = 'T'.codePointAt(0);

  tm_private = this['typemarkers']['private'] = 'Z'.codePointAt(0);

  tm_hi = this['typemarkers']['hi'] = 0xff;

  this['bytecounts'] = {};

  bytecount_singular = this['bytecounts']['singular'] = 1;

  bytecount_typemarker = this['bytecounts']['typemarker'] = 1;

  bytecount_number = this['bytecounts']['number'] = 9;

  bytecount_date = this['bytecounts']['date'] = bytecount_number + 1;

  this['sentinels'] = {};


  /* http://www.merlyn.demon.co.uk/js-datex.htm */

  this['sentinels']['firstdate'] = new Date(-8640000000000000);

  this['sentinels']['lastdate'] = new Date(+8640000000000000);

  this['keys'] = {};

  this['keys']['lo'] = new Buffer([this['typemarkers']['lo']]);

  this['keys']['hi'] = new Buffer([this['typemarkers']['hi']]);

  this['symbols'] = {};

  symbol_fallback = this['fallback'] = Symbol('fallback');

  rbuffer_min_size = 1024;

  rbuffer_max_size = 65536;

  rbuffer = new Buffer(rbuffer_min_size);

  grow_rbuffer = function() {
    var factor, new_result_buffer, new_size;
    factor = 2;
    new_size = Math.floor(rbuffer.length * factor + 0.5);
    new_result_buffer = new Buffer(new_size);
    rbuffer.copy(new_result_buffer);
    rbuffer = new_result_buffer;
    return null;
  };

  release_extraneous_rbuffer_bytes = function() {
    if (rbuffer.length > rbuffer_max_size) {
      rbuffer = new Buffer(rbuffer_max_size);
    }
    return null;
  };

  write_singular = function(idx, value) {
    var typemarker;
    while (!(rbuffer.length >= idx + bytecount_singular)) {
      grow_rbuffer();
    }
    if (value === null) {
      typemarker = tm_null;
    } else if (value === false) {
      typemarker = tm_false;
    } else if (value === true) {
      typemarker = tm_true;
    } else {
      throw new Error("unable to encode value of type " + (CND.type_of(value)));
    }
    rbuffer[idx] = typemarker;
    return idx + bytecount_singular;
  };

  read_singular = function(buffer, idx) {
    var typemarker, value;
    switch (typemarker = buffer[idx]) {
      case tm_null:
        value = null;
        break;
      case tm_false:
        value = false;
        break;
      case tm_true:
        value = true;
        break;
      default:
        throw new Error("unable to decode 0x" + (typemarker.toString(16)) + " at index " + idx + " (" + (rpr(buffer)) + ")");
    }
    return [idx + bytecount_singular, value];
  };

  write_private = function(idx, value, encoder) {
    var encoded_value, proper_value, ref, type, wrapped_value;
    while (!(rbuffer.length >= idx + 3 * bytecount_typemarker)) {
      grow_rbuffer();
    }
    rbuffer[idx] = tm_private;
    idx += bytecount_typemarker;
    rbuffer[idx] = tm_list;
    idx += bytecount_typemarker;
    type = (ref = value['type']) != null ? ref : 'private';
    proper_value = value['value'];
    if (encoder != null) {
      encoded_value = encoder(type, proper_value, symbol_fallback);
      if (encoded_value !== symbol_fallback) {
        proper_value = encoded_value;
      }
    } else if (type.startsWith('-')) {

      /* Built-in private types */
      switch (type) {
        case '-set':
          null;
          break;
        default:
          throw new Error("unknown built-in private type " + (rpr(type)));
      }
    }
    wrapped_value = [type, proper_value];
    idx = _encode(wrapped_value, idx);
    rbuffer[idx] = tm_lo;
    idx += bytecount_typemarker;
    return idx;
  };

  read_private = function(buffer, idx, decoder) {
    var R, ref, ref1, type, value;
    idx += bytecount_typemarker;
    ref = read_list(buffer, idx), idx = ref[0], (ref1 = ref[1], type = ref1[0], value = ref1[1]);
    if (decoder != null) {
      R = decoder(type, value, symbol_fallback);
      if (R === void 0) {
        throw new Error("encountered illegal value `undefined` when reading private type");
      }
      if (R === symbol_fallback) {
        R = {
          type: type,
          value: value
        };
      }
    } else if (type.startsWith('-')) {

      /* Built-in private types */
      switch (type) {
        case '-set':

          /* TAINT wasting bytes because wrapped twice */
          R = new Set(value[0]);
          break;
        default:
          throw new Error("unknown built-in private type " + (rpr(type)));
      }
    } else {
      R = {
        type: type,
        value: value
      };
    }
    return [idx, R];
  };

  write_number = function(idx, number) {
    var type;
    while (!(rbuffer.length >= idx + bytecount_number)) {
      grow_rbuffer();
    }
    if (number < 0) {
      type = tm_nnumber;
      number = -number;
    } else {
      type = tm_pnumber;
    }
    rbuffer[idx] = type;
    rbuffer.writeDoubleBE(number, idx + 1);
    if (type === tm_nnumber) {
      _invert_buffer(rbuffer, idx);
    }
    return idx + bytecount_number;
  };

  write_infinity = function(idx, number) {
    while (!(rbuffer.length >= idx + bytecount_singular)) {
      grow_rbuffer();
    }
    rbuffer[idx] = number === -Infinity ? tm_ninfinity : tm_pinfinity;
    return idx + bytecount_singular;
  };

  read_nnumber = function(buffer, idx) {
    var copy;
    if (buffer[idx] !== tm_nnumber) {
      throw new Error("not a negative number at index " + idx);
    }
    copy = _invert_buffer(new Buffer(buffer.slice(idx, idx + bytecount_number)), 0);
    return [idx + bytecount_number, -(copy.readDoubleBE(1))];
  };

  read_pnumber = function(buffer, idx) {
    if (buffer[idx] !== tm_pnumber) {
      throw new Error("not a positive number at index " + idx);
    }
    return [idx + bytecount_number, buffer.readDoubleBE(idx + 1)];
  };

  _invert_buffer = function(buffer, idx) {
    var i, j, ref, ref1;
    for (i = j = ref = idx + 1, ref1 = idx + 8; ref <= ref1 ? j <= ref1 : j >= ref1; i = ref <= ref1 ? ++j : --j) {
      buffer[i] = ~buffer[i];
    }
    return buffer;
  };

  write_date = function(idx, date) {
    var number;
    while (!(rbuffer.length >= idx + bytecount_date)) {
      grow_rbuffer();
    }
    number = +date;
    rbuffer[idx] = tm_date;
    return write_number(idx + 1, number);
  };

  read_date = function(buffer, idx) {
    var ref, ref1, type, value;
    if (buffer[idx] !== tm_date) {
      throw new Error("not a date at index " + idx);
    }
    switch (type = buffer[idx + 1]) {
      case tm_nnumber:
        ref = read_nnumber(buffer, idx + 1), idx = ref[0], value = ref[1];
        break;
      case tm_pnumber:
        ref1 = read_pnumber(buffer, idx + 1), idx = ref1[0], value = ref1[1];
        break;
      default:
        throw new Error("unknown date type marker 0x" + (type.toString(16)) + " at index " + idx);
    }
    return [idx, new Date(value)];
  };

  write_text = function(idx, text) {
    var bytecount_text;
    text = text.replace(/\x01/g, '\x01\x02');
    text = text.replace(/\x00/g, '\x01\x01');
    bytecount_text = (Buffer.byteLength(text, 'utf-8')) + 2;
    while (!(rbuffer.length >= idx + bytecount_text)) {
      grow_rbuffer();
    }
    rbuffer[idx] = tm_text;
    rbuffer.write(text, idx + 1);
    rbuffer[idx + bytecount_text - 1] = tm_lo;
    return idx + bytecount_text;
  };

  read_text = function(buffer, idx) {
    var R, byte, stop_idx;
    if (buffer[idx] !== tm_text) {
      throw new Error("not a text at index " + idx);
    }
    stop_idx = idx;
    while (true) {
      stop_idx += +1;
      if ((byte = buffer[stop_idx]) === tm_lo) {
        break;
      }
      if (byte == null) {
        throw new Error("runaway string at index " + idx);
      }
    }
    R = buffer.toString('utf-8', idx + 1, stop_idx);
    R = R.replace(/\x01\x01/g, '\x00');
    R = R.replace(/\x01\x02/g, '\x01');
    return [stop_idx + 1, R];
  };

  read_list = function(buffer, idx) {
    var R, byte, ref, value;
    if (buffer[idx] !== tm_list) {
      throw new Error("not a list at index " + idx);
    }
    R = [];
    idx += +1;
    while (true) {
      if ((byte = buffer[idx]) === tm_lo) {
        break;
      }
      ref = _decode(buffer, idx, true), idx = ref[0], value = ref[1];
      R.push(value[0]);
      if (byte == null) {
        throw new Error("runaway list at index " + idx);
      }
    }
    return [idx + 1, R];
  };

  write = function(idx, value, encoder) {
    var type;
    switch (type = CND.type_of(value)) {
      case 'text':
        return write_text(idx, value);
      case 'number':
        return write_number(idx, value);
      case 'infinity':
        return write_infinity(idx, value);
      case 'date':
        return write_date(idx, value);
      case 'set':

        /* TAINT wasting bytes because wrapped too deep */
        return write_private(idx, {
          type: '-set',
          value: [Array.from(value)]
        });
    }
    if (CND.isa_pod(value)) {
      return write_private(idx, value, encoder);
    }
    return write_singular(idx, value);
  };

  this.encode = function(key, encoder) {
    var R, idx, type;
    rbuffer.fill(0x00);
    if ((type = CND.type_of(key)) !== 'list') {
      throw new Error("expected a list, got a " + type);
    }
    idx = _encode(key, 0, encoder);
    R = new Buffer(idx);
    rbuffer.copy(R, 0, 0, idx);
    release_extraneous_rbuffer_bytes();
    return R;
  };

  this.encode_plus_hi = function(key, encoder) {

    /* TAINT code duplication */
    var R, idx, type;
    rbuffer.fill(0x00);
    if ((type = CND.type_of(key)) !== 'list') {
      throw new Error("expected a list, got a " + type);
    }
    idx = _encode(key, 0, encoder);
    while (!(rbuffer.length >= idx + 1)) {
      grow_rbuffer();
    }
    rbuffer[idx] = tm_hi;
    idx += +1;
    R = new Buffer(idx);
    rbuffer.copy(R, 0, 0, idx);
    release_extraneous_rbuffer_bytes();
    return R;
  };

  _encode = function(key, idx, encoder) {
    var element, element_idx, error, error1, j, k, key_rpr, l, last_element_idx, len, len1, len2, sub_element;
    last_element_idx = key.length - 1;
    for (element_idx = j = 0, len = key.length; j < len; element_idx = ++j) {
      element = key[element_idx];
      try {
        if (CND.isa_list(element)) {
          rbuffer[idx] = tm_list;
          idx += +1;
          for (k = 0, len1 = element.length; k < len1; k++) {
            sub_element = element[k];
            idx = _encode([sub_element], idx, encoder);
          }
          rbuffer[idx] = tm_lo;
          idx += +1;
        } else {
          idx = write(idx, element, encoder);
        }
      } catch (error1) {
        error = error1;
        key_rpr = [];
        for (l = 0, len2 = key.length; l < len2; l++) {
          element = key[l];
          if (CND.isa_jsbuffer(element)) {
            key_rpr.push("" + (this.rpr_of_buffer(null, key[2])));
          } else {
            key_rpr.push(rpr(element));
          }
        }
        warn("detected problem with key [ " + (rpr(key_rpr.join(', '))) + " ]");
        throw error;
      }
    }
    return idx;
  };

  this.decode = function(buffer, decoder) {
    return (_decode(buffer, 0, false, decoder))[1];
  };

  _decode = function(buffer, idx, single, decoder) {
    var R, last_idx, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, type, value;
    R = [];
    last_idx = buffer.length - 1;
    while (true) {
      if (idx > last_idx) {
        break;
      }
      switch (type = buffer[idx]) {
        case tm_list:
          ref = read_list(buffer, idx), idx = ref[0], value = ref[1];
          break;
        case tm_text:
          ref1 = read_text(buffer, idx), idx = ref1[0], value = ref1[1];
          break;
        case tm_nnumber:
          ref2 = read_nnumber(buffer, idx), idx = ref2[0], value = ref2[1];
          break;
        case tm_ninfinity:
          ref3 = [idx + 1, -Infinity], idx = ref3[0], value = ref3[1];
          break;
        case tm_pnumber:
          ref4 = read_pnumber(buffer, idx), idx = ref4[0], value = ref4[1];
          break;
        case tm_pinfinity:
          ref5 = [idx + 1, +Infinity], idx = ref5[0], value = ref5[1];
          break;
        case tm_date:
          ref6 = read_date(buffer, idx), idx = ref6[0], value = ref6[1];
          break;
        case tm_private:
          ref7 = read_private(buffer, idx, decoder), idx = ref7[0], value = ref7[1];
          break;
        default:
          ref8 = read_singular(buffer, idx), idx = ref8[0], value = ref8[1];
      }
      R.push(value);
      if (single) {
        break;
      }
    }
    return [idx, R];
  };

  this.encodings = {
    dbcs2: "⓪①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳㉑㉒㉓㉔㉕㉖㉗㉘㉙㉚㉛\n㉜！＂＃＄％＆＇（）＊＋，－．／０１２３４５６７８９：；＜＝＞？\n＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ［＼］＾＿\n｀ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ｛｜｝～㉠\n㉝㉞㉟㊱㊲㊳㊴㊵㊶㊷㊸㊹㊺㊻㊼㊽㊾㊿㋐㋑㋒㋓㋔㋕㋖㋗㋘㋙㋚㋛㋜㋝\n㋞㋟㋠㋡㋢㋣㋤㋥㋦㋧㋨㋩㋪㋫㋬㋭㋮㋯㋰㋱㋲㋳㋴㋵㋶㋷㋸㋹㋺㋻㋼㋽\n㋾㊊㊋㊌㊍㊎㊏㊐㊑㊒㊓㊔㊕㊖㊗㊘㊙㊚㊛㊜㊝㊞㊟㊠㊡㊢㊣㊤㊥㊦㊧㊨\n㊩㊪㊫㊬㊭㊮㊯㊰㊀㊁㊂㊃㊄㊅㊆㊇㊈㊉㉈㉉㉊㉋㉌㉍㉎㉏⓵⓶⓷⓸⓹〓",
    aleph: "БДИЛЦЧШЭЮƆƋƏƐƔƥƧƸψŐőŒœŊŁłЯɔɘɐɕəɞ\n␣!\"#$%&'()*+,-./0123456789:;<=>?\n@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\n`abcdefghijklmnopqrstuvwxyz{|}~ω\nΓΔΘΛΞΠΣΦΨΩαβγδεζηθικλμνξπρςστυφχ\nЖ¡¢£¤¥¦§¨©ª«¬Я®¯°±²³´µ¶·¸¹º»¼½¾¿\nÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß\nàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ",
    rdctn: "∇≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡\n␣!\"#$%&'()*+,-./0123456789:;<=>?\n@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\n`abcdefghijklmnopqrstuvwxyz{|}~≡\n∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃\n∃∃¢£¤¥¦§¨©ª«¬Я®¯°±²³´µ¶·¸¹º»¼½¾¿\nÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß\nàáâãäåæçèéêëìíîïðñò≢≢≢≢≢≢≢≢≢≢≢≢Δ"
  };

  this.rpr_of_buffer = function(buffer, encoding) {
    return (rpr(buffer)) + ' ' + this._encode_buffer(buffer, encoding);
  };

  this._encode_buffer = function(buffer, encoding) {
    var idx;
    if (encoding == null) {
      encoding = 'rdctn';
    }

    /* TAINT use switch, emit error if `encoding` not list or known key */
    if (!CND.isa_list(encoding)) {
      encoding = this.encodings[encoding];
    }
    return ((function() {
      var j, ref, results;
      results = [];
      for (idx = j = 0, ref = buffer.length; 0 <= ref ? j < ref : j > ref; idx = 0 <= ref ? ++j : --j) {
        results.push(encoding[buffer[idx]]);
      }
      return results;
    })()).join('');
  };

  this._compile_encodings = function() {
    var chrs_of, encoding, length, name, ref;
    chrs_of = function(text) {
      var chr;
      text = text.split(/([\ud800-\udbff].|.)/);
      return (function() {
        var j, len, results;
        results = [];
        for (j = 0, len = text.length; j < len; j++) {
          chr = text[j];
          if (chr !== '') {
            results.push(chr);
          }
        }
        return results;
      })();
    };
    ref = this.encodings;
    for (name in ref) {
      encoding = ref[name];
      encoding = chrs_of(encoding.replace(/\n+/g, ''));
      if ((length = encoding.length) !== 256) {
        throw new Error("expected 256 characters, found " + length + " in encoding " + (rpr(name)));
      }
      this.encodings[name] = encoding;
    }
    return null;
  };

  this._compile_encodings();

}).call(this);

//# sourceMappingURL=../sourcemaps/main.js.map
