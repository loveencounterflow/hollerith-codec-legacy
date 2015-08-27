

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
@[ "codec decodes private type with custom decoder" ] = ( T ) ->
  value         = '/usr/local/lib/node_modules/coffee-script/README.md'
  matcher       = [ value, ]
  encoded_value = value.split '/'
  key           = [ { type: 'route', value: encoded_value, }, ]
  key_bfr       = CODEC.encode key
  #.........................................................................................................
  decoded_key   = CODEC.decode key_bfr, ( type, value ) ->
    return value.join '/' if type is 'route'
    throw new Error "unknown private type #{rpr type}"
  #.........................................................................................................
  T.eq matcher, decoded_key

# #-----------------------------------------------------------------------------------------------------------
# @[ "codec decodes private type with custom encoder and decoder" ] = ( T ) ->
#   value         = '/usr/local/lib/node_modules/coffee-script/README.md'
#   key           = [ { type: 'route', value: value, }, ]
#   matcher       = [ value, ]
#   #.........................................................................................................
#   encoder = ( type, value ) ->
#     return value.split '/' if type is 'route'
#     throw new Error "unknown private type #{rpr type}"
#   #.........................................................................................................
#   decoder = ( type, value ) ->
#     return value.join '/' if type is 'route'
#     throw new Error "unknown private type #{rpr type}"
#   #.........................................................................................................
#   key_bfr       = CODEC.encode key,     encoder
#   decoded_key   = CODEC.decode key_bfr, decoder
#   T.eq matcher, decoded_key

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
@_main = ->
  test @, 'timeout': 2500







