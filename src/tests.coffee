

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'HOLLERITH-CODEC/tests'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'
CODEC                     = require './main'
ƒ                         = CND.format_number


#-----------------------------------------------------------------------------------------------------------
@[ "codec encodes and decodes numbers" ] = ( T ) ->
  key     = [ 'foo', 1234, 5678, ]
  key_bfr = CODEC.encode key
  T.eq key, CODEC.decode key_bfr
  whisper "key length: #{key_bfr.length}"

#-----------------------------------------------------------------------------------------------------------
@[ "codec encodes and decodes dates" ] = ( T ) ->
  key     = [ 'foo', ( new Date() ), 5678, ]
  key_bfr = CODEC.encode key
  T.eq key, CODEC.decode key_bfr
  whisper "key length: #{key_bfr.length}"

#-----------------------------------------------------------------------------------------------------------
@[ "codec accepts long numbers" ] = ( T ) ->
  key     = [ 'foo', ( i for i in [ 0 .. 1000 ] ), 'bar', ]
  key_bfr = CODEC.encode key
  T.eq key, CODEC.decode key_bfr
  whisper "key length: #{key_bfr.length}"

#-----------------------------------------------------------------------------------------------------------
@[ "codec accepts long texts" ] = ( T ) ->
  long_text   = ( new Array 1e4 ).join '#'
  key         = [ 'foo', [ long_text, long_text, long_text, long_text, ], 42, ]
  key_bfr     = CODEC.encode key
  T.eq key, CODEC.decode key_bfr
  whisper "key length: #{key_bfr.length}"

#-----------------------------------------------------------------------------------------------------------
@[ "codec preserves critical escaped characters (roundtrip) (1)" ] = ( T ) ->
  text        = 'abc\x00\x00\x00\x00def'
  key         = [ 'xxx', [ text, ], 0, ]
  key_bfr     = CODEC.encode key
  T.eq key, CODEC.decode key_bfr

#-----------------------------------------------------------------------------------------------------------
@[ "codec preserves critical escaped characters (roundtrip) (2)" ] = ( T ) ->
  text        = 'abc\x01\x01\x01\x01def'
  key         = [ 'xxx', [ text, ], 0, ]
  key_bfr     = CODEC.encode key
  T.eq key, CODEC.decode key_bfr

#-----------------------------------------------------------------------------------------------------------
@[ "codec preserves critical escaped characters (roundtrip) (3)" ] = ( T ) ->
  text        = 'abc\x00\x01\x00\x01def'
  key         = [ 'xxx', [ text, ], 0, ]
  key_bfr     = CODEC.encode key
  T.eq key, CODEC.decode key_bfr

#-----------------------------------------------------------------------------------------------------------
@[ "codec preserves critical escaped characters (roundtrip) (4)" ] = ( T ) ->
  text        = 'abc\x01\x00\x01\x00def'
  key         = [ 'xxx', [ text, ], 0, ]
  key_bfr     = CODEC.encode key
  T.eq key, CODEC.decode key_bfr

#-----------------------------------------------------------------------------------------------------------
@[ "codec accepts private type (1)" ] = ( T ) ->
  key         = [ { type: 'price', value: 'abc', }, ]
  key_bfr     = CODEC.encode key
  T.eq key, CODEC.decode key_bfr

#-----------------------------------------------------------------------------------------------------------
@[ "codec accepts private type (2)" ] = ( T ) ->
  key         = [ 123, 456, { type: 'price', value: 'abc', }, 'xxx', ]
  key_bfr     = CODEC.encode key
  T.eq key, CODEC.decode key_bfr

#-----------------------------------------------------------------------------------------------------------
@[ "codec decodes private type with custom decoder (1)" ] = ( T ) ->
  value         = '/etc/cron.d/anacron'
  matcher       = [ value, ]
  encoded_value = value.split '/'
  key           = [ { type: 'route', value: encoded_value, }, ]
  key_bfr       = CODEC.encode key
  #.........................................................................................................
  decoded_key   = CODEC.decode key_bfr, ( type, value ) ->
    return value.join '/' if type is 'route'
    throw new Error "unknown private type #{rpr type}"
  #.........................................................................................................
  # debug CODEC.rpr_of_buffer key_bfr
  # debug CODEC.decode key_bfr
  # debug decoded_key
  T.eq matcher, decoded_key

#-----------------------------------------------------------------------------------------------------------
@_sets_are_equal = ( a, b ) ->
  ### TAINT doesn't work for (sub-) elements that are sets or maps ###
  return false unless ( CND.isa a, 'set' ) and ( CND.isa b, 'set' )
  return false unless a.size is b.size
  a_keys = a.keys()
  b_keys = b.keys()
  loop
    { value: a_value, done: a_done, } = a_keys.next()
    { value: b_value, done: b_done, } = b_keys.next()
    break if a_done or b_done
    return false unless CND.equals a_value, b_value
  return true

#-----------------------------------------------------------------------------------------------------------
@[ "codec decodes private type with custom decoder (2)" ] = ( T ) ->
  value         = new Set 'qwert'
  matcher       = [ value, ]
  encoded_value = Array.from value
  key           = [ { type: 'set', value: encoded_value, }, ]
  key_bfr       = CODEC.encode key
  #.........................................................................................................
  decoded_key   = CODEC.decode key_bfr, ( type, value ) ->
    return new Set value if type is 'set'
    throw new Error "unknown private type #{rpr type}"
  #.........................................................................................................
  # debug CODEC.rpr_of_buffer key_bfr
  # debug CODEC.decode key_bfr
  # debug decoded_key
  # debug matcher
  T.ok @_sets_are_equal matcher[ 0 ], decoded_key[ 0 ]

#-----------------------------------------------------------------------------------------------------------
@[ "Support for Sets" ] = ( T ) ->
  key           = [ ( new Set 'qwert' ), ]
  matcher       = [ ( new Set 'qwert' ), ]
  key_bfr       = CODEC.encode key
  decoded_key   = CODEC.decode key_bfr
  # debug CODEC.rpr_of_buffer key_bfr
  # debug CODEC.decode key_bfr
  # debug decoded_key
  # debug matcher
  T.ok @_sets_are_equal matcher[ 0 ], decoded_key[ 0 ]

#-----------------------------------------------------------------------------------------------------------
@[ "codec decodes private type with custom encoder and decoder (3)" ] = ( T ) ->
  route         = '/usr/local/lib/node_modules/coffee-script/README.md'
  parts         = route.split '/'
  key           = [ { type: 'route', value: route, }, ]
  matcher_1     = [ { type: 'route', value: parts, }]
  matcher_2     = [ route, ]
  #.........................................................................................................
  encoder = ( type, value ) ->
    return value.split '/' if type is 'route'
    throw new Error "unknown private type #{rpr type}"
  #.........................................................................................................
  decoder = ( type, value ) ->
    return value.join '/' if type is 'route'
    throw new Error "unknown private type #{rpr type}"
  #.........................................................................................................
  key_bfr       = CODEC.encode key,     encoder
  # debug '©T4WKz', CODEC.rpr_of_buffer key_bfr
  decoded_key_1 = CODEC.decode key_bfr
  T.eq matcher_1, decoded_key_1
  decoded_key_2 = CODEC.decode key_bfr, decoder
  T.eq matcher_2, decoded_key_2

#-----------------------------------------------------------------------------------------------------------
@[ "private type takes default shape when handler returns use_fallback" ] = ( T ) ->
  matcher       = [ 84, { type: 'bar', value: 108, }, ]
  key           = [ { type: 'foo', value: 42, }, { type: 'bar', value: 108, }, ]
  key_bfr       = CODEC.encode key
  #.........................................................................................................
  decoded_key   = CODEC.decode key_bfr, ( type, value, use_fallback ) ->
    return value * 2 if type is 'foo'
    return use_fallback
  #.........................................................................................................
  T.eq matcher, decoded_key

#-----------------------------------------------------------------------------------------------------------
@[ "test: flat file DB storage" ] = ( T ) ->
  probes = [
    [ 'foo', -Infinity, ]
    [ 'foo', -1e12, ]
    [ 'foo', -3, ]
    [ 'foo', -2, ]
    [ 'foo', -1, ]
    [ 'foo', 1, ]
    [ 'foo', 2, ]
    [ 'foo', 3, ]
    [ 'foo', 1e12, ]
    [ 'foo', Infinity, ]
    [ 'bar', 'blah', ]
    [ 'bar', 'gnu', ]
    [ 'a', ]
    [ 'b', ]
    [ 'c', ]
    [ 'A', ]
    [ 'B', ]
    [ 'C', ]
    [ '0', ]
    [ '1', ]
    [ '2', ]
    [ 'Number', Number.EPSILON,           'EPSILON',          ]
    [ 'Number', Number.MAX_SAFE_INTEGER,  'MAX_SAFE_INTEGER', ]
    [ 'Number', Number.MAX_VALUE,         'MAX_VALUE',        ]
    [ 'Number', 0,                        'ZERO',             ]
    [ 'Number', Number.MIN_SAFE_INTEGER,  'MIN_SAFE_INTEGER', ]
    [ 'Number', Number.MIN_VALUE,         'MIN_VALUE',        ]
    ]
  buffer_as_text = ( buffer ) ->
    R = []
    for idx in [ 0 ... buffer.length ]
      R.push String.fromCodePoint 0x2800 + buffer[ idx ]
    # R.push String.fromCodePoint 0x2800 while R.length < 32
    R.push ' ' while R.length < 32
    return R.join ''
  probes = ( [ ( buffer_as_text CODEC.encode probe ), JSON.stringify probe, ] for probe in probes )
  probes.sort ( a, b ) ->
    return -1 if a[ 0 ] < b[ 0 ]
    return +1 if a[ 0 ] > b[ 0 ]
    return  0
  for probe in probes
    urge probe.join ' - '
  # for probe in probes
  #   probe_txt = JSON.stringify probe
  #   key_txt   = buffer_as_text CODEC.encode probe
  #   debug '33301', "#{key_txt} - #{probe_txt}"
  return null

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@_prune = ->
  for name, value of @
    continue if name.startsWith '_'
    delete @[ name ] unless name in include
  return null

#-----------------------------------------------------------------------------------------------------------
@_main = ->
  test @, 'timeout': 2500

############################################################################################################
unless module.parent?
  # @_prune()
  @_main()


