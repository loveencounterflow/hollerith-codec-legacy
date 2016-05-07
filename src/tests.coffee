

############################################################################################################
# njs_path                  = require 'path'
# # njs_fs                    = require 'fs'
# join                      = njs_path.join
#...........................................................................................................
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
# suspend                   = require 'coffeenode-suspend'
# step                      = suspend.step
# ### TAINT experimentally using `later` in place of `setImmediate` ###
# later                     = suspend.immediately
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
  ### TAINT doen't work for (sub-) elements that are sets or maps ###
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
  debug CODEC.rpr_of_buffer key_bfr
  debug CODEC.decode key_bfr
  debug decoded_key
  debug matcher
  T.ok @_sets_are_equal matcher[ 0 ], decoded_key[ 0 ]

#-----------------------------------------------------------------------------------------------------------
@_main = ->
  test @, 'timeout': 2500







