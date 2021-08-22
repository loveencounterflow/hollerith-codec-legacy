

'use strict'


#===========================================================================================================
# 
#-----------------------------------------------------------------------------------------------------------
class @Hollerith_codec

  #---------------------------------------------------------------------------------------------------------
  constructor: ->
    @sign_delta  = 0x80000000  ### used to lift negative numbers to non-negative ###
    @u32_width   = 4           ### bytes per element ###
    @vnr_width   = 5           ### maximum elements in VNR vector ###
    @nr_min      = -0x80000000 ### smallest possible VNR element ###
    @nr_max      = +0x7fffffff ### largest possible VNR element ###
    return undefined

  #---------------------------------------------------------------------------------------------------------
  encode: ( vnr ) ->
    unless 0 < vnr.length <= @vnr_width
      throw new Error "^44798^ expected VNR to be between 1 and #{@vnr_width} elements long, got length #{vnr.length}"
    R           = Buffer.alloc @vnr_width * @u32_width, 0x00 ### TAINT pre-compute constant ###
    offset      = -@u32_width
    for idx in [ 0 ... @vnr_width ]
      R.writeUInt32BE ( vnr[ idx ] ? 0 ) + @sign_delta, ( offset += @u32_width )
    return R

  #---------------------------------------------------------------------------------------------------------
  _encode_bcd: ( vnr ) ->
    vnr_width   = 5           ### maximum elements in VNR vector ###
    dpe         = 4           ### digits per element ###
    base        = 36
    plus        = '+'
    minus       = '!'
    padder      = '.'
    R           = []
    for idx in [ 0 ... vnr_width ]
      nr    = vnr[ idx ] ? 0
      sign  = if nr >= 0 then plus else minus
      R.push sign + ( ( Math.abs nr ).toString base ).padStart dpe, padder
    R           = R.join ','
    return R

#===========================================================================================================
@HOLLERITH_CODEC = new @Hollerith_codec()



