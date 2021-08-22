(function() {
  'use strict';
  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  this.Hollerith_codec = class Hollerith_codec {
    //---------------------------------------------------------------------------------------------------------
    constructor() {
      this.sign_delta = 0x80000000/* used to lift negative numbers to non-negative */
      this.u32_width = 4/* bytes per element */
      this.vnr_width = 5/* maximum elements in VNR vector */
      this.nr_min = -0x80000000/* smallest possible VNR element */
      this.nr_max = +0x7fffffff/* largest possible VNR element */
      return void 0;
    }

    //---------------------------------------------------------------------------------------------------------
    encode(vnr) {
      var R, i, idx, offset/* TAINT pre-compute constant */, ref, ref1, ref2;
      if (!((0 < (ref = vnr.length) && ref <= this.vnr_width))) {
        throw new Error(`^44798^ expected VNR to be between 1 and ${this.vnr_width} elements long, got length ${vnr.length}`);
      }
      R = Buffer.alloc(this.vnr_width * this.u32_width, 0x00);
      offset = -this.u32_width;
      for (idx = i = 0, ref1 = this.vnr_width; (0 <= ref1 ? i < ref1 : i > ref1); idx = 0 <= ref1 ? ++i : --i) {
        R.writeUInt32BE(((ref2 = vnr[idx]) != null ? ref2 : 0) + this.sign_delta, (offset += this.u32_width));
      }
      return R;
    }

    //---------------------------------------------------------------------------------------------------------
    _encode_bcd(vnr) {
      var R, base, dpe, i, idx, minus, nr, padder, plus, ref, ref1, sign, vnr_width;
      vnr_width = 5/* maximum elements in VNR vector */
      dpe = 4/* digits per element */
      base = 36;
      plus = '+';
      minus = '!';
      padder = '.';
      R = [];
      for (idx = i = 0, ref = vnr_width; (0 <= ref ? i < ref : i > ref); idx = 0 <= ref ? ++i : --i) {
        nr = (ref1 = vnr[idx]) != null ? ref1 : 0;
        sign = nr >= 0 ? plus : minus;
        R.push(sign + ((Math.abs(nr)).toString(base)).padStart(dpe, padder));
      }
      R = R.join(',');
      return R;
    }

  };

  //===========================================================================================================
  this.HOLLERITH_CODEC = new this.Hollerith_codec();

}).call(this);

//# sourceMappingURL=tng.js.map