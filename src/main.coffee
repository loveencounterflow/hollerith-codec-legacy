


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'HOLLERITH/CODEC'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
#...........................................................................................................
CND.shim()


#-----------------------------------------------------------------------------------------------------------
@[ 'typemarkers' ]  = {}
#...........................................................................................................
tm_lo               = @[ 'typemarkers'  ][ 'lo'         ] = 0x00
tm_null             = @[ 'typemarkers'  ][ 'null'       ] = 'B'.codePointAt 0
tm_false            = @[ 'typemarkers'  ][ 'false'      ] = 'C'.codePointAt 0
tm_true             = @[ 'typemarkers'  ][ 'true'       ] = 'D'.codePointAt 0
tm_list             = @[ 'typemarkers'  ][ 'list'       ] = 'E'.codePointAt 0
tm_date             = @[ 'typemarkers'  ][ 'date'       ] = 'G'.codePointAt 0
tm_ninfinity        = @[ 'typemarkers'  ][ 'ninfinity'  ] = 'J'.codePointAt 0
tm_nnumber          = @[ 'typemarkers'  ][ 'nnumber'    ] = 'K'.codePointAt 0
tm_pnumber          = @[ 'typemarkers'  ][ 'pnumber'    ] = 'L'.codePointAt 0
tm_pinfinity        = @[ 'typemarkers'  ][ 'pinfinity'  ] = 'M'.codePointAt 0
tm_text             = @[ 'typemarkers'  ][ 'text'       ] = 'T'.codePointAt 0
tm_private          = @[ 'typemarkers'  ][ 'private'    ] = 'Z'.codePointAt 0
tm_hi               = @[ 'typemarkers'  ][ 'hi'         ] = 0xff

#-----------------------------------------------------------------------------------------------------------
@[ 'bytecounts' ]     = {}
bytecount_singular    = @[ 'bytecounts'   ][ 'singular'   ] = 1
bytecount_typemarker  = @[ 'bytecounts'   ][ 'typemarker' ] = 1
bytecount_number      = @[ 'bytecounts'   ][ 'number'     ] = 9
bytecount_date        = @[ 'bytecounts'   ][ 'date'       ] = bytecount_number + 1

#-----------------------------------------------------------------------------------------------------------
@[ 'sentinels' ]  = {}
#...........................................................................................................
### http://www.merlyn.demon.co.uk/js-datex.htm ###
@[ 'sentinels' ][ 'firstdate' ] = new Date -8640000000000000
@[ 'sentinels' ][ 'lastdate'  ] = new Date +8640000000000000

#-----------------------------------------------------------------------------------------------------------
@[ 'keys' ]  = {}
#...........................................................................................................
@[ 'keys' ][ 'lo' ] = new Buffer [ @[ 'typemarkers' ][ 'lo' ] ]
@[ 'keys' ][ 'hi' ] = new Buffer [ @[ 'typemarkers' ][ 'hi' ] ]

#-----------------------------------------------------------------------------------------------------------
@[ 'symbols' ]  = {}
symbol_fallback = @[ 'fallback' ] = Symbol 'fallback'


#===========================================================================================================
# RESULT BUFFER (RBUFFER)
#-----------------------------------------------------------------------------------------------------------
rbuffer_min_size        = 1024
rbuffer_max_size        = 65536
rbuffer                 = new Buffer rbuffer_min_size

#-----------------------------------------------------------------------------------------------------------
grow_rbuffer = ->
  factor      = 2
  new_size    = Math.floor rbuffer.length * factor + 0.5
  # warn "growing rbuffer to #{new_size} bytes"
  new_result_buffer = new Buffer new_size
  rbuffer.copy new_result_buffer
  rbuffer           = new_result_buffer
  return null

#-----------------------------------------------------------------------------------------------------------
release_extraneous_rbuffer_bytes = ->
  if rbuffer.length > rbuffer_max_size
    # warn "shrinking rbuffer to #{rbuffer_max_size} bytes"
    rbuffer = new Buffer rbuffer_max_size
  return null


#===========================================================================================================
# VARIANTS
#-----------------------------------------------------------------------------------------------------------
write_singular = ( idx, value ) ->
  grow_rbuffer() until rbuffer.length >= idx + bytecount_singular
  if      value is null   then typemarker = tm_null
  else if value is false  then typemarker = tm_false
  else if value is true   then typemarker = tm_true
  else throw new Error "unable to encode value of type #{CND.type_of value}"
  rbuffer[ idx ] = typemarker
  return idx + bytecount_singular

#-----------------------------------------------------------------------------------------------------------
read_singular = ( buffer, idx ) ->
  switch typemarker = buffer[ idx ]
    when tm_null  then value = null
    when tm_false then value = false
    when tm_true  then value = true
    else throw new Error "unable to decode 0x#{typemarker.toString 16} at index #{idx} (#{rpr buffer})"
  return [ idx + bytecount_singular, value, ]


#===========================================================================================================
# PRIVATES
#-----------------------------------------------------------------------------------------------------------
write_private = ( idx, value ) ->
  grow_rbuffer() until rbuffer.length >= idx + 3 * bytecount_typemarker
  #.........................................................................................................
  rbuffer[ idx ]  = tm_private
  idx            += bytecount_typemarker
  #.........................................................................................................
  rbuffer[ idx ]  = tm_list
  idx            += bytecount_typemarker
  #.........................................................................................................
  type            = value[ 'type' ] ? 'private'
  wrapped_value   = [ type, value[ 'value' ], ]
  idx             = _encode wrapped_value, idx
  #.........................................................................................................
  rbuffer[ idx ]  = tm_lo
  idx            += bytecount_typemarker
  #.........................................................................................................
  return idx

#-----------------------------------------------------------------------------------------------------------
read_private = ( buffer, idx, private_handler ) ->
  idx                        += bytecount_typemarker
  [ idx, [ type,  value, ] ]  = read_list buffer, idx
  if private_handler?
    R = private_handler type, value, symbol_fallback
    throw new Error "encountered illegal value `undefined` when reading private type" if R is undefined
  if R is symbol_fallback or not private_handler?
    R = { type, value, }
  return [ idx, R, ]


#===========================================================================================================
# NUMBERS
#-----------------------------------------------------------------------------------------------------------
write_number = ( idx, number ) ->
  grow_rbuffer() until rbuffer.length >= idx + bytecount_number
  if number < 0
    type    = tm_nnumber
    number  = -number
  else
    type    = tm_pnumber
  rbuffer[ idx ] = type
  rbuffer.writeDoubleBE number, idx + 1
  _invert_buffer rbuffer, idx if type is tm_nnumber
  return idx + bytecount_number

#-----------------------------------------------------------------------------------------------------------
write_infinity = ( idx, number ) ->
  grow_rbuffer() until rbuffer.length >= idx + bytecount_singular
  rbuffer[ idx ] = if number is -Infinity then tm_ninfinity else tm_pinfinity
  return idx + bytecount_singular

#-----------------------------------------------------------------------------------------------------------
read_nnumber = ( buffer, idx ) ->
  throw new Error "not a negative number at index #{idx}" unless buffer[ idx ] is tm_nnumber
  copy = _invert_buffer ( new Buffer buffer.slice idx, idx + bytecount_number ), 0
  return [ idx + bytecount_number, -( copy.readDoubleBE 1 ), ]

#-----------------------------------------------------------------------------------------------------------
read_pnumber = ( buffer, idx ) ->
  throw new Error "not a positive number at index #{idx}" unless buffer[ idx ] is tm_pnumber
  return [ idx + bytecount_number, buffer.readDoubleBE idx + 1, ]

#-----------------------------------------------------------------------------------------------------------
_invert_buffer = ( buffer, idx ) ->
  buffer[ i ] = ~buffer[ i ] for i in [ idx + 1 .. idx + 8 ]
  return buffer


#===========================================================================================================
# DATES
#-----------------------------------------------------------------------------------------------------------
write_date = ( idx, date ) ->
  grow_rbuffer() until rbuffer.length >= idx + bytecount_date
  number          = +date
  rbuffer[ idx ]  = tm_date
  return write_number idx + 1, number

#-----------------------------------------------------------------------------------------------------------
read_date = ( buffer, idx ) ->
  throw new Error "not a date at index #{idx}" unless buffer[ idx ] is tm_date
  switch type = buffer[ idx + 1 ]
    when tm_nnumber    then [ idx, value, ] = read_nnumber    buffer, idx + 1
    when tm_pnumber    then [ idx, value, ] = read_pnumber    buffer, idx + 1
    else throw new Error "unknown date type marker 0x#{type.toString 16} at index #{idx}"
  return [ idx, ( new Date value ), ]


#===========================================================================================================
# TEXTS
#-----------------------------------------------------------------------------------------------------------
write_text = ( idx, text ) ->
  text                                = text.replace /\x01/g, '\x01\x02'
  text                                = text.replace /\x00/g, '\x01\x01'
  bytecount_text                      = ( Buffer.byteLength text, 'utf-8' ) + 2
  grow_rbuffer() until rbuffer.length >= idx + bytecount_text
  rbuffer[ idx ]                      = tm_text
  rbuffer.write text, idx + 1
  rbuffer[ idx + bytecount_text - 1 ] = tm_lo
  return idx + bytecount_text

#-----------------------------------------------------------------------------------------------------------
read_text = ( buffer, idx ) ->
  # urge '©J2d6R', buffer[ idx ], buffer[ idx ] is tm_text
  throw new Error "not a text at index #{idx}" unless buffer[ idx ] is tm_text
  stop_idx = idx
  loop
    stop_idx += +1
    break if ( byte = buffer[ stop_idx ] ) is tm_lo
    throw new Error "runaway string at index #{idx}" unless byte?
  R = buffer.toString 'utf-8', idx + 1, stop_idx
  R = R.replace /\x01\x02/g, '\x01'
  R = R.replace /\x01\x01/g, '\x00'
  return [ stop_idx + 1, R, ]


#===========================================================================================================
# LISTS
#-----------------------------------------------------------------------------------------------------------
read_list = ( buffer, idx ) ->
  throw new Error "not a list at index #{idx}" unless buffer[ idx ] is tm_list
  R     = []
  idx  += +1
  loop
    break if ( byte = buffer[ idx ] ) is tm_lo
    [ idx, value, ] = _decode buffer, idx, true
    R.push value[ 0 ]
    throw new Error "runaway list at index #{idx}" unless byte?
  return [ idx + 1, R, ]


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
write = ( idx, value ) ->
  switch type = CND.type_of value
    when 'text'       then return write_text     idx, value
    when 'number'     then return write_number   idx, value
    when 'jsinfinity' then return write_infinity idx, value
    when 'jsdate'     then return write_date     idx, value
  #.........................................................................................................
  return write_private  idx, value if CND.isa_pod value
  return write_singular idx, value


#===========================================================================================================
# PUBLIC API
#-----------------------------------------------------------------------------------------------------------
@encode = ( key, encoder ) ->
  rbuffer.fill 0x00
  throw new Error "expected a list, got a #{type}" unless ( type = CND.type_of key ) is 'list'
  idx = _encode key, 0
  R   = new Buffer idx
  rbuffer.copy R, 0, 0, idx
  release_extraneous_rbuffer_bytes()
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@encode_plus_hi = ( key, encoder ) ->
  ### TAINT code duplication ###
  rbuffer.fill 0x00
  throw new Error "expected a list, got a #{type}" unless ( type = CND.type_of key ) is 'list'
  idx = _encode key, 0
  #.........................................................................................................
  if extra_byte?
    grow_rbuffer() until rbuffer.length >= idx + 1
    rbuffer[ idx ]  = tm_hi
    idx            += +1
  #.........................................................................................................
  R = new Buffer idx
  rbuffer.copy R, 0, 0, idx
  release_extraneous_rbuffer_bytes()
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
_encode = ( key, idx ) ->
  last_element_idx = key.length - 1
  for element, element_idx in key
    try
      if CND.isa_list element
        rbuffer[ idx ]  = tm_list
        idx            += +1
        for sub_element in element
          idx = _encode [ sub_element, ], idx
        rbuffer[ idx ]  = tm_lo
        idx            += +1
      else
        idx = write idx, element
    catch error
      key_rpr = []
      for element in key
        if CND.isa_jsbuffer element
          key_rpr.push "#{@rpr_of_buffer null, key[ 2 ]}"
        else
          key_rpr.push rpr element
      warn "detected problem with key [ #{rpr key_rpr.join ', '} ]"
      throw error
  #.........................................................................................................
  return idx

#-----------------------------------------------------------------------------------------------------------
@decode = ( buffer, private_handler ) ->
  return ( _decode buffer, 0, false, private_handler )[ 1 ]

#-----------------------------------------------------------------------------------------------------------
_decode = ( buffer, idx, single, private_handler ) ->
  R         = []
  last_idx  = buffer.length - 1
  loop
    break if idx > last_idx
    switch type = buffer[ idx ]
      when tm_list       then [ idx, value, ] = read_list       buffer, idx
      when tm_text       then [ idx, value, ] = read_text       buffer, idx
      when tm_nnumber    then [ idx, value, ] = read_nnumber    buffer, idx
      when tm_ninfinity  then [ idx, value, ] = [ idx + 1, -Infinity, ]
      when tm_pnumber    then [ idx, value, ] = read_pnumber    buffer, idx
      when tm_pinfinity  then [ idx, value, ] = [ idx + 1, +Infinity, ]
      when tm_date       then [ idx, value, ] = read_date       buffer, idx
      when tm_private    then [ idx, value, ] = read_private    buffer, idx, private_handler
      else                    [ idx, value, ] = read_singular   buffer, idx
    R.push value
    break if single
  #.........................................................................................................
  return [ idx, R ]


# debug ( require './dump' ).rpr_of_buffer null, buffer = @encode [ 'aaa', [], ]
# debug '©tP5xQ', @decode buffer

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@encodings =

  #.........................................................................................................
  dbcs2: """
    ⓪①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳㉑㉒㉓㉔㉕㉖㉗㉘㉙㉚㉛
    ㉜！＂＃＄％＆＇（）＊＋，－．／０１２３４５６７８９：；＜＝＞？
    ＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ［＼］＾＿
    ｀ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ｛｜｝～㉠
    ㉝㉞㉟㊱㊲㊳㊴㊵㊶㊷㊸㊹㊺㊻㊼㊽㊾㊿㋐㋑㋒㋓㋔㋕㋖㋗㋘㋙㋚㋛㋜㋝
    ㋞㋟㋠㋡㋢㋣㋤㋥㋦㋧㋨㋩㋪㋫㋬㋭㋮㋯㋰㋱㋲㋳㋴㋵㋶㋷㋸㋹㋺㋻㋼㋽
    ㋾㊊㊋㊌㊍㊎㊏㊐㊑㊒㊓㊔㊕㊖㊗㊘㊙㊚㊛㊜㊝㊞㊟㊠㊡㊢㊣㊤㊥㊦㊧㊨
    ㊩㊪㊫㊬㊭㊮㊯㊰㊀㊁㊂㊃㊄㊅㊆㊇㊈㊉㉈㉉㉊㉋㉌㉍㉎㉏⓵⓶⓷⓸⓹〓
    """
  #.........................................................................................................
  aleph: """
    БДИЛЦЧШЭЮƆƋƏƐƔƥƧƸψŐőŒœŊŁłЯɔɘɐɕəɞ
    ␣!"#$%&'()*+,-./0123456789:;<=>?
    @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_
    `abcdefghijklmnopqrstuvwxyz{|}~ω
    ΓΔΘΛΞΠΣΦΨΩαβγδεζηθικλμνξπρςστυφχ
    Ж¡¢£¤¥¦§¨©ª«¬Я®¯°±²³´µ¶·¸¹º»¼½¾¿
    ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß
    àáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ
    """
  #.........................................................................................................
  rdctn: """
    ∇≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡
    ␣!"#$%&'()*+,-./0123456789:;<=>?
    @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_
    `abcdefghijklmnopqrstuvwxyz{|}~≡
    ∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃∃
    ∃∃¢£¤¥¦§¨©ª«¬Я®¯°±²³´µ¶·¸¹º»¼½¾¿
    ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß
    àáâãäåæçèéêëìíîïðñò≢≢≢≢≢≢≢≢≢≢≢≢Δ
    """


#-----------------------------------------------------------------------------------------------------------
@rpr_of_buffer = ( buffer, encoding ) ->
  return ( rpr buffer ) + ' ' +  @_encode_buffer buffer, encoding

#-----------------------------------------------------------------------------------------------------------
@_encode_buffer = ( buffer, encoding = 'rdctn' ) ->
  ### TAINT use switch, emit error if `encoding` not list or known key ###
  encoding = @encodings[ encoding ] unless CND.isa_list encoding
  return ( encoding[ buffer[ idx ] ] for idx in [ 0 ... buffer.length ] ).join ''

#-----------------------------------------------------------------------------------------------------------
@_compile_encodings = ->
  #.........................................................................................................
  chrs_of = ( text ) ->
    text = text.split /([\ud800-\udbff].|.)/
    return ( chr for chr in text when chr isnt '' )
  #.........................................................................................................
  for name, encoding of @encodings
    encoding = chrs_of encoding.replace /\n+/g, ''
    unless ( length = encoding.length ) is 256
      throw new Error "expected 256 characters, found #{length} in encoding #{rpr name}"
    @encodings[ name ] = encoding
  return null
@_compile_encodings()
