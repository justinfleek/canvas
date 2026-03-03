var CanvasApp = (() => {
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __export = (target, all3) => {
    for (var name2 in all3)
      __defProp(target, name2, { get: all3[name2], enumerable: true });
  };
  var __copyProps = (to, from2, except, desc) => {
    if (from2 && typeof from2 === "object" || typeof from2 === "function") {
      for (let key of __getOwnPropNames(from2))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from2[key], enumerable: !(desc = __getOwnPropDesc(from2, key)) || desc.enumerable });
    }
    return to;
  };
  var __toCommonJS = (mod2) => __copyProps(__defProp({}, "__esModule", { value: true }), mod2);

  // output/Canvas.App/index.js
  var index_exports = {};
  __export(index_exports, {
    canvasApp: () => canvasApp,
    frameTimeMs: () => frameTimeMs,
    gravityScale: () => gravityScale,
    main: () => main,
    physicsTimestep: () => physicsTimestep
  });

  // output/Canvas.Easter.Confetti/foreign.js
  var unsafeIndex = (idx) => (arr) => {
    if (idx >= 0 && idx < arr.length) {
      return { tag: "Just", _1: arr[idx] };
    }
    return { tag: "Nothing" };
  };

  // output/Data.Array/foreign.js
  var rangeImpl = function(start, end) {
    var step = start > end ? -1 : 1;
    var result = new Array(step * (end - start) + 1);
    var i = start, n = 0;
    while (i !== end) {
      result[n++] = i;
      i += step;
    }
    result[n] = i;
    return result;
  };
  var replicateFill = function(count, value) {
    if (count < 1) {
      return [];
    }
    var result = new Array(count);
    return result.fill(value);
  };
  var replicatePolyfill = function(count, value) {
    var result = [];
    var n = 0;
    for (var i = 0; i < count; i++) {
      result[n++] = value;
    }
    return result;
  };
  var replicateImpl = typeof Array.prototype.fill === "function" ? replicateFill : replicatePolyfill;
  var fromFoldableImpl = /* @__PURE__ */ (function() {
    function Cons2(head2, tail) {
      this.head = head2;
      this.tail = tail;
    }
    var emptyList = {};
    function curryCons(head2) {
      return function(tail) {
        return new Cons2(head2, tail);
      };
    }
    function listToArray(list) {
      var result = [];
      var count = 0;
      var xs = list;
      while (xs !== emptyList) {
        result[count++] = xs.head;
        xs = xs.tail;
      }
      return result;
    }
    return function(foldr2, xs) {
      return listToArray(foldr2(curryCons)(emptyList)(xs));
    };
  })();
  var length = function(xs) {
    return xs.length;
  };
  var indexImpl = function(just, nothing, xs, i) {
    return i < 0 || i >= xs.length ? nothing : just(xs[i]);
  };
  var findIndexImpl = function(just, nothing, f, xs) {
    for (var i = 0, l = xs.length; i < l; i++) {
      if (f(xs[i])) return just(i);
    }
    return nothing;
  };
  var concat = function(xss) {
    if (xss.length <= 1e4) {
      return Array.prototype.concat.apply([], xss);
    }
    var result = [];
    for (var i = 0, l = xss.length; i < l; i++) {
      var xs = xss[i];
      for (var j = 0, m = xs.length; j < m; j++) {
        result.push(xs[j]);
      }
    }
    return result;
  };
  var filterImpl = function(f, xs) {
    return xs.filter(f);
  };
  var sortByImpl = /* @__PURE__ */ (function() {
    function mergeFromTo(compare4, fromOrdering, xs1, xs2, from2, to) {
      var mid;
      var i;
      var j;
      var k;
      var x;
      var y;
      var c;
      mid = from2 + (to - from2 >> 1);
      if (mid - from2 > 1) mergeFromTo(compare4, fromOrdering, xs2, xs1, from2, mid);
      if (to - mid > 1) mergeFromTo(compare4, fromOrdering, xs2, xs1, mid, to);
      i = from2;
      j = mid;
      k = from2;
      while (i < mid && j < to) {
        x = xs2[i];
        y = xs2[j];
        c = fromOrdering(compare4(x)(y));
        if (c > 0) {
          xs1[k++] = y;
          ++j;
        } else {
          xs1[k++] = x;
          ++i;
        }
      }
      while (i < mid) {
        xs1[k++] = xs2[i++];
      }
      while (j < to) {
        xs1[k++] = xs2[j++];
      }
    }
    return function(compare4, fromOrdering, xs) {
      var out;
      if (xs.length < 2) return xs;
      out = xs.slice(0);
      mergeFromTo(compare4, fromOrdering, out, xs.slice(0), 0, xs.length);
      return out;
    };
  })();
  var sliceImpl = function(s, e, l) {
    return l.slice(s, e);
  };

  // output/Data.Functor/foreign.js
  var arrayMap = function(f) {
    return function(arr) {
      var l = arr.length;
      var result = new Array(l);
      for (var i = 0; i < l; i++) {
        result[i] = f(arr[i]);
      }
      return result;
    };
  };

  // output/Control.Semigroupoid/index.js
  var semigroupoidFn = {
    compose: function(f) {
      return function(g) {
        return function(x) {
          return f(g(x));
        };
      };
    }
  };

  // output/Control.Category/index.js
  var identity = function(dict) {
    return dict.identity;
  };
  var categoryFn = {
    identity: function(x) {
      return x;
    },
    Semigroupoid0: function() {
      return semigroupoidFn;
    }
  };

  // output/Data.Boolean/index.js
  var otherwise = true;

  // output/Data.Function/index.js
  var flip = function(f) {
    return function(b) {
      return function(a) {
        return f(a)(b);
      };
    };
  };
  var $$const = function(a) {
    return function(v) {
      return a;
    };
  };

  // output/Data.Unit/foreign.js
  var unit = void 0;

  // output/Data.Functor/index.js
  var map = function(dict) {
    return dict.map;
  };
  var functorArray = {
    map: arrayMap
  };

  // output/Data.Semigroup/foreign.js
  var concatArray = function(xs) {
    return function(ys) {
      if (xs.length === 0) return ys;
      if (ys.length === 0) return xs;
      return xs.concat(ys);
    };
  };

  // output/Data.Semigroup/index.js
  var semigroupArray = {
    append: concatArray
  };
  var append = function(dict) {
    return dict.append;
  };

  // output/Control.Apply/foreign.js
  var arrayApply = function(fs) {
    return function(xs) {
      var l = fs.length;
      var k = xs.length;
      var result = new Array(l * k);
      var n = 0;
      for (var i = 0; i < l; i++) {
        var f = fs[i];
        for (var j = 0; j < k; j++) {
          result[n++] = f(xs[j]);
        }
      }
      return result;
    };
  };

  // output/Control.Apply/index.js
  var identity2 = /* @__PURE__ */ identity(categoryFn);
  var applyArray = {
    apply: arrayApply,
    Functor0: function() {
      return functorArray;
    }
  };
  var apply = function(dict) {
    return dict.apply;
  };
  var applySecond = function(dictApply) {
    var apply1 = apply(dictApply);
    var map9 = map(dictApply.Functor0());
    return function(a) {
      return function(b) {
        return apply1(map9($$const(identity2))(a))(b);
      };
    };
  };

  // output/Control.Applicative/index.js
  var pure = function(dict) {
    return dict.pure;
  };
  var liftA1 = function(dictApplicative) {
    var apply3 = apply(dictApplicative.Apply0());
    var pure1 = pure(dictApplicative);
    return function(f) {
      return function(a) {
        return apply3(pure1(f))(a);
      };
    };
  };

  // output/Control.Bind/foreign.js
  var arrayBind = typeof Array.prototype.flatMap === "function" ? function(arr) {
    return function(f) {
      return arr.flatMap(f);
    };
  } : function(arr) {
    return function(f) {
      var result = [];
      var l = arr.length;
      for (var i = 0; i < l; i++) {
        var xs = f(arr[i]);
        var k = xs.length;
        for (var j = 0; j < k; j++) {
          result.push(xs[j]);
        }
      }
      return result;
    };
  };

  // output/Control.Bind/index.js
  var bindArray = {
    bind: arrayBind,
    Apply0: function() {
      return applyArray;
    }
  };
  var bind = function(dict) {
    return dict.bind;
  };

  // output/Control.Monad/index.js
  var ap = function(dictMonad) {
    var bind2 = bind(dictMonad.Bind1());
    var pure4 = pure(dictMonad.Applicative0());
    return function(f) {
      return function(a) {
        return bind2(f)(function(f$prime) {
          return bind2(a)(function(a$prime) {
            return pure4(f$prime(a$prime));
          });
        });
      };
    };
  };

  // output/Data.Bounded/foreign.js
  var topInt = 2147483647;
  var bottomInt = -2147483648;
  var topChar = String.fromCharCode(65535);
  var bottomChar = String.fromCharCode(0);
  var topNumber = Number.POSITIVE_INFINITY;
  var bottomNumber = Number.NEGATIVE_INFINITY;

  // output/Data.Ord/foreign.js
  var unsafeCompareImpl = function(lt) {
    return function(eq4) {
      return function(gt) {
        return function(x) {
          return function(y) {
            return x < y ? lt : x === y ? eq4 : gt;
          };
        };
      };
    };
  };
  var ordIntImpl = unsafeCompareImpl;
  var ordNumberImpl = unsafeCompareImpl;
  var ordCharImpl = unsafeCompareImpl;

  // output/Data.Eq/foreign.js
  var refEq = function(r1) {
    return function(r2) {
      return r1 === r2;
    };
  };
  var eqIntImpl = refEq;
  var eqNumberImpl = refEq;
  var eqCharImpl = refEq;
  var eqStringImpl = refEq;

  // output/Data.Eq/index.js
  var eqString = {
    eq: eqStringImpl
  };
  var eqNumber = {
    eq: eqNumberImpl
  };
  var eqInt = {
    eq: eqIntImpl
  };
  var eqChar = {
    eq: eqCharImpl
  };
  var eq = function(dict) {
    return dict.eq;
  };

  // output/Data.Ordering/index.js
  var LT = /* @__PURE__ */ (function() {
    function LT2() {
    }
    ;
    LT2.value = new LT2();
    return LT2;
  })();
  var GT = /* @__PURE__ */ (function() {
    function GT2() {
    }
    ;
    GT2.value = new GT2();
    return GT2;
  })();
  var EQ = /* @__PURE__ */ (function() {
    function EQ2() {
    }
    ;
    EQ2.value = new EQ2();
    return EQ2;
  })();

  // output/Data.Ring/foreign.js
  var intSub = function(x) {
    return function(y) {
      return x - y | 0;
    };
  };

  // output/Data.Semiring/foreign.js
  var intAdd = function(x) {
    return function(y) {
      return x + y | 0;
    };
  };
  var intMul = function(x) {
    return function(y) {
      return x * y | 0;
    };
  };

  // output/Data.Semiring/index.js
  var semiringInt = {
    add: intAdd,
    zero: 0,
    mul: intMul,
    one: 1
  };

  // output/Data.Ring/index.js
  var ringInt = {
    sub: intSub,
    Semiring0: function() {
      return semiringInt;
    }
  };

  // output/Data.Ord/index.js
  var ordNumber = /* @__PURE__ */ (function() {
    return {
      compare: ordNumberImpl(LT.value)(EQ.value)(GT.value),
      Eq0: function() {
        return eqNumber;
      }
    };
  })();
  var ordInt = /* @__PURE__ */ (function() {
    return {
      compare: ordIntImpl(LT.value)(EQ.value)(GT.value),
      Eq0: function() {
        return eqInt;
      }
    };
  })();
  var ordChar = /* @__PURE__ */ (function() {
    return {
      compare: ordCharImpl(LT.value)(EQ.value)(GT.value),
      Eq0: function() {
        return eqChar;
      }
    };
  })();
  var compare = function(dict) {
    return dict.compare;
  };
  var comparing = function(dictOrd) {
    var compare32 = compare(dictOrd);
    return function(f) {
      return function(x) {
        return function(y) {
          return compare32(f(x))(f(y));
        };
      };
    };
  };
  var max = function(dictOrd) {
    var compare32 = compare(dictOrd);
    return function(x) {
      return function(y) {
        var v = compare32(x)(y);
        if (v instanceof LT) {
          return y;
        }
        ;
        if (v instanceof EQ) {
          return x;
        }
        ;
        if (v instanceof GT) {
          return x;
        }
        ;
        throw new Error("Failed pattern match at Data.Ord (line 181, column 3 - line 184, column 12): " + [v.constructor.name]);
      };
    };
  };
  var min = function(dictOrd) {
    var compare32 = compare(dictOrd);
    return function(x) {
      return function(y) {
        var v = compare32(x)(y);
        if (v instanceof LT) {
          return x;
        }
        ;
        if (v instanceof EQ) {
          return x;
        }
        ;
        if (v instanceof GT) {
          return y;
        }
        ;
        throw new Error("Failed pattern match at Data.Ord (line 172, column 3 - line 175, column 12): " + [v.constructor.name]);
      };
    };
  };

  // output/Data.Bounded/index.js
  var top = function(dict) {
    return dict.top;
  };
  var boundedInt = {
    top: topInt,
    bottom: bottomInt,
    Ord0: function() {
      return ordInt;
    }
  };
  var boundedChar = {
    top: topChar,
    bottom: bottomChar,
    Ord0: function() {
      return ordChar;
    }
  };
  var bottom = function(dict) {
    return dict.bottom;
  };

  // output/Data.Show/foreign.js
  var showIntImpl = function(n) {
    return n.toString();
  };
  var showNumberImpl = function(n) {
    var str = n.toString();
    return isNaN(str + ".0") ? str : str + ".0";
  };

  // output/Data.Show/index.js
  var showNumber = {
    show: showNumberImpl
  };
  var showInt = {
    show: showIntImpl
  };
  var showBoolean = {
    show: function(v) {
      if (v) {
        return "true";
      }
      ;
      if (!v) {
        return "false";
      }
      ;
      throw new Error("Failed pattern match at Data.Show (line 29, column 1 - line 31, column 23): " + [v.constructor.name]);
    }
  };
  var show = function(dict) {
    return dict.show;
  };

  // output/Data.Maybe/index.js
  var identity3 = /* @__PURE__ */ identity(categoryFn);
  var Nothing = /* @__PURE__ */ (function() {
    function Nothing2() {
    }
    ;
    Nothing2.value = new Nothing2();
    return Nothing2;
  })();
  var Just = /* @__PURE__ */ (function() {
    function Just2(value0) {
      this.value0 = value0;
    }
    ;
    Just2.create = function(value0) {
      return new Just2(value0);
    };
    return Just2;
  })();
  var maybe = function(v) {
    return function(v1) {
      return function(v2) {
        if (v2 instanceof Nothing) {
          return v;
        }
        ;
        if (v2 instanceof Just) {
          return v1(v2.value0);
        }
        ;
        throw new Error("Failed pattern match at Data.Maybe (line 237, column 1 - line 237, column 51): " + [v.constructor.name, v1.constructor.name, v2.constructor.name]);
      };
    };
  };
  var isJust = /* @__PURE__ */ maybe(false)(/* @__PURE__ */ $$const(true));
  var functorMaybe = {
    map: function(v) {
      return function(v1) {
        if (v1 instanceof Just) {
          return new Just(v(v1.value0));
        }
        ;
        return Nothing.value;
      };
    }
  };
  var map2 = /* @__PURE__ */ map(functorMaybe);
  var fromMaybe = function(a) {
    return maybe(a)(identity3);
  };
  var applyMaybe = {
    apply: function(v) {
      return function(v1) {
        if (v instanceof Just) {
          return map2(v.value0)(v1);
        }
        ;
        if (v instanceof Nothing) {
          return Nothing.value;
        }
        ;
        throw new Error("Failed pattern match at Data.Maybe (line 67, column 1 - line 69, column 30): " + [v.constructor.name, v1.constructor.name]);
      };
    },
    Functor0: function() {
      return functorMaybe;
    }
  };

  // output/Data.Either/index.js
  var Left = /* @__PURE__ */ (function() {
    function Left2(value0) {
      this.value0 = value0;
    }
    ;
    Left2.create = function(value0) {
      return new Left2(value0);
    };
    return Left2;
  })();
  var Right = /* @__PURE__ */ (function() {
    function Right2(value0) {
      this.value0 = value0;
    }
    ;
    Right2.create = function(value0) {
      return new Right2(value0);
    };
    return Right2;
  })();

  // output/Data.EuclideanRing/foreign.js
  var intDegree = function(x) {
    return Math.min(Math.abs(x), 2147483647);
  };
  var intDiv = function(x) {
    return function(y) {
      if (y === 0) return 0;
      return y > 0 ? Math.floor(x / y) : -Math.floor(x / -y);
    };
  };
  var intMod = function(x) {
    return function(y) {
      if (y === 0) return 0;
      var yy = Math.abs(y);
      return (x % yy + yy) % yy;
    };
  };

  // output/Data.CommutativeRing/index.js
  var commutativeRingInt = {
    Ring0: function() {
      return ringInt;
    }
  };

  // output/Data.EuclideanRing/index.js
  var euclideanRingInt = {
    degree: intDegree,
    div: intDiv,
    mod: intMod,
    CommutativeRing0: function() {
      return commutativeRingInt;
    }
  };
  var div = function(dict) {
    return dict.div;
  };

  // output/Data.Monoid/index.js
  var mempty = function(dict) {
    return dict.mempty;
  };

  // output/Effect/foreign.js
  var pureE = function(a) {
    return function() {
      return a;
    };
  };
  var bindE = function(a) {
    return function(f) {
      return function() {
        return f(a())();
      };
    };
  };

  // output/Effect/index.js
  var $runtime_lazy = function(name2, moduleName, init2) {
    var state2 = 0;
    var val;
    return function(lineNumber) {
      if (state2 === 2) return val;
      if (state2 === 1) throw new ReferenceError(name2 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
      state2 = 1;
      val = init2();
      state2 = 2;
      return val;
    };
  };
  var monadEffect = {
    Applicative0: function() {
      return applicativeEffect;
    },
    Bind1: function() {
      return bindEffect;
    }
  };
  var bindEffect = {
    bind: bindE,
    Apply0: function() {
      return $lazy_applyEffect(0);
    }
  };
  var applicativeEffect = {
    pure: pureE,
    Apply0: function() {
      return $lazy_applyEffect(0);
    }
  };
  var $lazy_functorEffect = /* @__PURE__ */ $runtime_lazy("functorEffect", "Effect", function() {
    return {
      map: liftA1(applicativeEffect)
    };
  });
  var $lazy_applyEffect = /* @__PURE__ */ $runtime_lazy("applyEffect", "Effect", function() {
    return {
      apply: ap(monadEffect),
      Functor0: function() {
        return $lazy_functorEffect(0);
      }
    };
  });

  // output/Data.Array.ST/foreign.js
  function unsafeFreezeThawImpl(xs) {
    return xs;
  }
  var unsafeFreezeImpl = unsafeFreezeThawImpl;
  function copyImpl(xs) {
    return xs.slice();
  }
  var thawImpl = copyImpl;
  var pushImpl = function(a, xs) {
    return xs.push(a);
  };

  // output/Control.Monad.ST.Uncurried/foreign.js
  var runSTFn1 = function runSTFn12(fn) {
    return function(a) {
      return function() {
        return fn(a);
      };
    };
  };
  var runSTFn2 = function runSTFn22(fn) {
    return function(a) {
      return function(b) {
        return function() {
          return fn(a, b);
        };
      };
    };
  };

  // output/Data.Array.ST/index.js
  var unsafeFreeze = /* @__PURE__ */ runSTFn1(unsafeFreezeImpl);
  var thaw = /* @__PURE__ */ runSTFn1(thawImpl);
  var withArray = function(f) {
    return function(xs) {
      return function __do3() {
        var result = thaw(xs)();
        f(result)();
        return unsafeFreeze(result)();
      };
    };
  };
  var push = /* @__PURE__ */ runSTFn2(pushImpl);

  // output/Data.Foldable/foreign.js
  var foldrArray = function(f) {
    return function(init2) {
      return function(xs) {
        var acc = init2;
        var len = xs.length;
        for (var i = len - 1; i >= 0; i--) {
          acc = f(xs[i])(acc);
        }
        return acc;
      };
    };
  };
  var foldlArray = function(f) {
    return function(init2) {
      return function(xs) {
        var acc = init2;
        var len = xs.length;
        for (var i = 0; i < len; i++) {
          acc = f(acc)(xs[i]);
        }
        return acc;
      };
    };
  };

  // output/Data.Tuple/index.js
  var Tuple = /* @__PURE__ */ (function() {
    function Tuple2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Tuple2.create = function(value0) {
      return function(value1) {
        return new Tuple2(value0, value1);
      };
    };
    return Tuple2;
  })();

  // output/Data.Foldable/index.js
  var foldr = function(dict) {
    return dict.foldr;
  };
  var traverse_ = function(dictApplicative) {
    var applySecond2 = applySecond(dictApplicative.Apply0());
    var pure4 = pure(dictApplicative);
    return function(dictFoldable) {
      var foldr2 = foldr(dictFoldable);
      return function(f) {
        return foldr2(function($454) {
          return applySecond2(f($454));
        })(pure4(unit));
      };
    };
  };
  var for_ = function(dictApplicative) {
    var traverse_1 = traverse_(dictApplicative);
    return function(dictFoldable) {
      return flip(traverse_1(dictFoldable));
    };
  };
  var foldl = function(dict) {
    return dict.foldl;
  };
  var foldMapDefaultR = function(dictFoldable) {
    var foldr2 = foldr(dictFoldable);
    return function(dictMonoid) {
      var append3 = append(dictMonoid.Semigroup0());
      var mempty2 = mempty(dictMonoid);
      return function(f) {
        return foldr2(function(x) {
          return function(acc) {
            return append3(f(x))(acc);
          };
        })(mempty2);
      };
    };
  };
  var foldableArray = {
    foldr: foldrArray,
    foldl: foldlArray,
    foldMap: function(dictMonoid) {
      return foldMapDefaultR(foldableArray)(dictMonoid);
    }
  };

  // output/Data.Function.Uncurried/foreign.js
  var runFn2 = function(fn) {
    return function(a) {
      return function(b) {
        return fn(a, b);
      };
    };
  };
  var runFn3 = function(fn) {
    return function(a) {
      return function(b) {
        return function(c) {
          return fn(a, b, c);
        };
      };
    };
  };
  var runFn4 = function(fn) {
    return function(a) {
      return function(b) {
        return function(c) {
          return function(d) {
            return fn(a, b, c, d);
          };
        };
      };
    };
  };

  // output/Data.Array/index.js
  var apply2 = /* @__PURE__ */ apply(applyMaybe);
  var map3 = /* @__PURE__ */ map(functorMaybe);
  var sortBy = function(comp) {
    return runFn3(sortByImpl)(comp)(function(v) {
      if (v instanceof GT) {
        return 1;
      }
      ;
      if (v instanceof EQ) {
        return 0;
      }
      ;
      if (v instanceof LT) {
        return -1 | 0;
      }
      ;
      throw new Error("Failed pattern match at Data.Array (line 897, column 38 - line 900, column 11): " + [v.constructor.name]);
    });
  };
  var snoc = function(xs) {
    return function(x) {
      return withArray(push(x))(xs)();
    };
  };
  var slice = /* @__PURE__ */ runFn3(sliceImpl);
  var singleton2 = function(a) {
    return [a];
  };
  var replicate = /* @__PURE__ */ runFn2(replicateImpl);
  var range2 = /* @__PURE__ */ runFn2(rangeImpl);
  var $$null = function(xs) {
    return length(xs) === 0;
  };
  var init = function(xs) {
    if ($$null(xs)) {
      return Nothing.value;
    }
    ;
    if (otherwise) {
      return new Just(slice(0)(length(xs) - 1 | 0)(xs));
    }
    ;
    throw new Error("Failed pattern match at Data.Array (line 351, column 1 - line 351, column 45): " + [xs.constructor.name]);
  };
  var index = /* @__PURE__ */ (function() {
    return runFn4(indexImpl)(Just.create)(Nothing.value);
  })();
  var last = function(xs) {
    return index(xs)(length(xs) - 1 | 0);
  };
  var unsnoc = function(xs) {
    return apply2(map3(function(v) {
      return function(v1) {
        return {
          init: v,
          last: v1
        };
      };
    })(init(xs)))(last(xs));
  };
  var head = function(xs) {
    return index(xs)(0);
  };
  var fromFoldable = function(dictFoldable) {
    return runFn2(fromFoldableImpl)(foldr(dictFoldable));
  };
  var foldl2 = /* @__PURE__ */ foldl(foldableArray);
  var findIndex = /* @__PURE__ */ (function() {
    return runFn4(findIndexImpl)(Just.create)(Nothing.value);
  })();
  var filter = /* @__PURE__ */ runFn2(filterImpl);
  var elemIndex = function(dictEq) {
    var eq22 = eq(dictEq);
    return function(x) {
      return findIndex(function(v) {
        return eq22(v)(x);
      });
    };
  };
  var elem2 = function(dictEq) {
    var elemIndex1 = elemIndex(dictEq);
    return function(a) {
      return function(arr) {
        return isJust(elemIndex1(a)(arr));
      };
    };
  };
  var concatMap = /* @__PURE__ */ flip(/* @__PURE__ */ bind(bindArray));
  var mapMaybe = function(f) {
    return concatMap((function() {
      var $189 = maybe([])(singleton2);
      return function($190) {
        return $189(f($190));
      };
    })());
  };

  // output/Data.Int/foreign.js
  var fromNumberImpl = function(just) {
    return function(nothing) {
      return function(n) {
        return (n | 0) === n ? just(n) : nothing;
      };
    };
  };
  var toNumber = function(n) {
    return n;
  };

  // output/Data.Number/foreign.js
  var isFiniteImpl = isFinite;
  var atan2 = function(y) {
    return function(x) {
      return Math.atan2(y, x);
    };
  };
  var cos = Math.cos;
  var floor = Math.floor;
  var pow = function(n) {
    return function(p) {
      return Math.pow(n, p);
    };
  };
  var sin = Math.sin;
  var sqrt = Math.sqrt;

  // output/Data.Number/index.js
  var pi = 3.141592653589793;

  // output/Data.Int/index.js
  var top2 = /* @__PURE__ */ top(boundedInt);
  var bottom2 = /* @__PURE__ */ bottom(boundedInt);
  var fromNumber = /* @__PURE__ */ (function() {
    return fromNumberImpl(Just.create)(Nothing.value);
  })();
  var unsafeClamp = function(x) {
    if (!isFiniteImpl(x)) {
      return 0;
    }
    ;
    if (x >= toNumber(top2)) {
      return top2;
    }
    ;
    if (x <= toNumber(bottom2)) {
      return bottom2;
    }
    ;
    if (otherwise) {
      return fromMaybe(0)(fromNumber(x));
    }
    ;
    throw new Error("Failed pattern match at Data.Int (line 72, column 1 - line 72, column 29): " + [x.constructor.name]);
  };
  var floor2 = function($39) {
    return unsafeClamp(floor($39));
  };

  // output/Data.String.Common/foreign.js
  var replaceAll = function(s1) {
    return function(s2) {
      return function(s3) {
        return s3.replace(new RegExp(s1.replace(/[-\/\\^$*+?.()|[\]{}]/g, "\\$&"), "g"), s2);
      };
    };
  };
  var joinWith = function(s) {
    return function(xs) {
      return xs.join(s);
    };
  };

  // output/Hydrogen.Render.Element.Types/index.js
  var SVG = /* @__PURE__ */ (function() {
    function SVG2() {
    }
    ;
    SVG2.value = new SVG2();
    return SVG2;
  })();
  var OnClick = /* @__PURE__ */ (function() {
    function OnClick2(value0) {
      this.value0 = value0;
    }
    ;
    OnClick2.create = function(value0) {
      return new OnClick2(value0);
    };
    return OnClick2;
  })();
  var OnMouseDown = /* @__PURE__ */ (function() {
    function OnMouseDown3(value0) {
      this.value0 = value0;
    }
    ;
    OnMouseDown3.create = function(value0) {
      return new OnMouseDown3(value0);
    };
    return OnMouseDown3;
  })();
  var OnMouseUp = /* @__PURE__ */ (function() {
    function OnMouseUp3(value0) {
      this.value0 = value0;
    }
    ;
    OnMouseUp3.create = function(value0) {
      return new OnMouseUp3(value0);
    };
    return OnMouseUp3;
  })();
  var OnMouseMove = /* @__PURE__ */ (function() {
    function OnMouseMove3(value0) {
      this.value0 = value0;
    }
    ;
    OnMouseMove3.create = function(value0) {
      return new OnMouseMove3(value0);
    };
    return OnMouseMove3;
  })();
  var OnTouchStart = /* @__PURE__ */ (function() {
    function OnTouchStart3(value0) {
      this.value0 = value0;
    }
    ;
    OnTouchStart3.create = function(value0) {
      return new OnTouchStart3(value0);
    };
    return OnTouchStart3;
  })();
  var OnTouchMove = /* @__PURE__ */ (function() {
    function OnTouchMove3(value0) {
      this.value0 = value0;
    }
    ;
    OnTouchMove3.create = function(value0) {
      return new OnTouchMove3(value0);
    };
    return OnTouchMove3;
  })();
  var OnTouchEnd = /* @__PURE__ */ (function() {
    function OnTouchEnd3(value0) {
      this.value0 = value0;
    }
    ;
    OnTouchEnd3.create = function(value0) {
      return new OnTouchEnd3(value0);
    };
    return OnTouchEnd3;
  })();
  var Attr = /* @__PURE__ */ (function() {
    function Attr2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Attr2.create = function(value0) {
      return function(value1) {
        return new Attr2(value0, value1);
      };
    };
    return Attr2;
  })();
  var AttrNS = /* @__PURE__ */ (function() {
    function AttrNS2(value0, value1, value2) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value2;
    }
    ;
    AttrNS2.create = function(value0) {
      return function(value1) {
        return function(value2) {
          return new AttrNS2(value0, value1, value2);
        };
      };
    };
    return AttrNS2;
  })();
  var Prop = /* @__PURE__ */ (function() {
    function Prop2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Prop2.create = function(value0) {
      return function(value1) {
        return new Prop2(value0, value1);
      };
    };
    return Prop2;
  })();
  var PropBool = /* @__PURE__ */ (function() {
    function PropBool2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    PropBool2.create = function(value0) {
      return function(value1) {
        return new PropBool2(value0, value1);
      };
    };
    return PropBool2;
  })();
  var Handler = /* @__PURE__ */ (function() {
    function Handler2(value0) {
      this.value0 = value0;
    }
    ;
    Handler2.create = function(value0) {
      return new Handler2(value0);
    };
    return Handler2;
  })();
  var Style = /* @__PURE__ */ (function() {
    function Style2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Style2.create = function(value0) {
      return function(value1) {
        return new Style2(value0, value1);
      };
    };
    return Style2;
  })();
  var Text = /* @__PURE__ */ (function() {
    function Text2(value0) {
      this.value0 = value0;
    }
    ;
    Text2.create = function(value0) {
      return new Text2(value0);
    };
    return Text2;
  })();
  var Element = /* @__PURE__ */ (function() {
    function Element2(value0) {
      this.value0 = value0;
    }
    ;
    Element2.create = function(value0) {
      return new Element2(value0);
    };
    return Element2;
  })();
  var Keyed = /* @__PURE__ */ (function() {
    function Keyed2(value0) {
      this.value0 = value0;
    }
    ;
    Keyed2.create = function(value0) {
      return new Keyed2(value0);
    };
    return Keyed2;
  })();
  var Lazy = /* @__PURE__ */ (function() {
    function Lazy2(value0) {
      this.value0 = value0;
    }
    ;
    Lazy2.create = function(value0) {
      return new Lazy2(value0);
    };
    return Lazy2;
  })();
  var Empty = /* @__PURE__ */ (function() {
    function Empty2() {
    }
    ;
    Empty2.value = new Empty2();
    return Empty2;
  })();

  // output/Hydrogen.Render.Element.Attributes/index.js
  var show2 = /* @__PURE__ */ show(showInt);
  var title = /* @__PURE__ */ (function() {
    return Attr.create("title");
  })();
  var tabIndex = function(i) {
    return new Attr("tabindex", show2(i));
  };
  var styles = /* @__PURE__ */ map(functorArray)(function(v) {
    return new Style(v.value0, v.value1);
  });
  var role = /* @__PURE__ */ (function() {
    return Attr.create("role");
  })();
  var id_ = /* @__PURE__ */ (function() {
    return Attr.create("id");
  })();
  var class_ = /* @__PURE__ */ (function() {
    return Attr.create("class");
  })();
  var attr = /* @__PURE__ */ (function() {
    return Attr.create;
  })();
  var ariaLive = /* @__PURE__ */ (function() {
    return Attr.create("aria-live");
  })();
  var ariaLabel = /* @__PURE__ */ (function() {
    return Attr.create("aria-label");
  })();
  var ariaAtomic = /* @__PURE__ */ (function() {
    return Attr.create("aria-atomic");
  })();

  // output/Hydrogen.Render.Element.Constructors/index.js
  var text = /* @__PURE__ */ (function() {
    return Text.create;
  })();
  var empty2 = /* @__PURE__ */ (function() {
    return Empty.value;
  })();
  var elementNS = function(ns) {
    return function(tag) {
      return function(attributes) {
        return function(children) {
          return new Element({
            namespace: new Just(ns),
            tag,
            attributes,
            children
          });
        };
      };
    };
  };
  var element = function(tag) {
    return function(attributes) {
      return function(children) {
        return new Element({
          namespace: Nothing.value,
          tag,
          attributes,
          children
        });
      };
    };
  };

  // output/Hydrogen.Render.Element.HTML/index.js
  var span_ = /* @__PURE__ */ element("span");
  var div_ = /* @__PURE__ */ element("div");
  var canvas_ = function(attrs) {
    return element("canvas")(attrs)([]);
  };
  var button_ = /* @__PURE__ */ element("button");

  // output/Canvas.Easter.Confetti/index.js
  var show3 = /* @__PURE__ */ show(showNumber);
  var max1 = /* @__PURE__ */ max(ordNumber);
  var append1 = /* @__PURE__ */ append(semigroupArray);
  var map4 = /* @__PURE__ */ map(functorArray);
  var div1 = /* @__PURE__ */ div(euclideanRingInt);
  var Square = /* @__PURE__ */ (function() {
    function Square2() {
    }
    ;
    Square2.value = new Square2();
    return Square2;
  })();
  var Circle = /* @__PURE__ */ (function() {
    function Circle2() {
    }
    ;
    Circle2.value = new Circle2();
    return Circle2;
  })();
  var Rectangle = /* @__PURE__ */ (function() {
    function Rectangle2() {
    }
    ;
    Rectangle2.value = new Rectangle2();
    return Rectangle2;
  })();
  var Star = /* @__PURE__ */ (function() {
    function Star2() {
    }
    ;
    Star2.value = new Star2();
    return Star2;
  })();
  var updateParticle = function(dt) {
    return function(gravity) {
      return function(drag) {
        return function(p) {
          var newRotation = p.rotation + p.angularVel * dt;
          var newAge = p.age + dt;
          var dragFactor = 1 - drag;
          var newVx = p.vx * dragFactor;
          var newX = p.x + newVx * dt;
          var newVy = p.vy * dragFactor + gravity * dt;
          var newY = p.y + newVy * dt;
          return {
            angularVel: p.angularVel,
            size: p.size,
            color: p.color,
            lifetime: p.lifetime,
            shape: p.shape,
            x: newX,
            y: newY,
            vx: newVx,
            vy: newVy,
            rotation: newRotation,
            age: newAge
          };
        };
      };
    };
  };
  var sinApprox = function(x) {
    var x3 = x * x * x;
    var x5 = x3 * x * x;
    var x7 = x5 * x * x;
    return x - x3 / 6 + x5 / 120 - x7 / 5040;
  };
  var renderParticle = function(p) {
    var width = (function() {
      if (p.shape instanceof Rectangle) {
        return p.size * 1.5;
      }
      ;
      return p.size;
    })();
    var transform = "translate(" + (show3(p.x) + ("px, " + (show3(p.y) + ("px) " + ("rotate(" + (show3(p.rotation * 57.3) + "deg)"))))));
    var opacity2 = max1(0)(1 - p.age / p.lifetime);
    var height = (function() {
      if (p.shape instanceof Rectangle) {
        return p.size * 0.6;
      }
      ;
      return p.size;
    })();
    var borderRadius = (function() {
      if (p.shape instanceof Circle) {
        return "50%";
      }
      ;
      if (p.shape instanceof Star) {
        return "2px";
      }
      ;
      return "2px";
    })();
    return div_(append1([class_("confetti-particle")])(styles([new Tuple("position", "absolute"), new Tuple("width", show3(width) + "px"), new Tuple("height", show3(height) + "px"), new Tuple("background-color", p.color), new Tuple("border-radius", borderRadius), new Tuple("transform", transform), new Tuple("opacity", show3(opacity2)), new Tuple("will-change", "transform, opacity")])))([]);
  };
  var render = function(state2) {
    if (state2.active) {
      return div_(append1([class_("confetti-container")])(styles([new Tuple("position", "fixed"), new Tuple("top", "0"), new Tuple("left", "0"), new Tuple("width", "100%"), new Tuple("height", "100%"), new Tuple("pointer-events", "none"), new Tuple("z-index", "9999"), new Tuple("overflow", "hidden")])))(map4(renderParticle)(state2.particles));
    }
    ;
    return empty2;
  };
  var isAlive = function(p) {
    return p.age < p.lifetime;
  };
  var update = function(dt) {
    return function(state2) {
      if (state2.active) {
        var updated = map4(updateParticle(dt)(state2.config.gravity)(state2.config.drag))(state2.particles);
        var alive = filter(isAlive)(updated);
        var stillActive = length(alive) > 0;
        return {
          config: state2.config,
          particles: alive,
          active: stillActive
        };
      }
      ;
      return state2;
    };
  };
  var intMod2 = function(a) {
    return function(b) {
      return a - (div1(a)(b) * b | 0) | 0;
    };
  };
  var indexArray = function(idx) {
    return function(arr) {
      var $35 = idx < 0;
      if ($35) {
        return Nothing.value;
      }
      ;
      var $36 = idx >= length(arr);
      if ($36) {
        return Nothing.value;
      }
      ;
      return unsafeIndex(idx)(arr);
    };
  };
  var indexOr = function(def) {
    return function(idx) {
      return function(arr) {
        var v = indexArray(idx)(arr);
        if (v instanceof Nothing) {
          return def;
        }
        ;
        if (v instanceof Just) {
          return v.value0;
        }
        ;
        throw new Error("Failed pattern match at Canvas.Easter.Confetti (line 429, column 23 - line 431, column 14): " + [v.constructor.name]);
      };
    };
  };
  var defaultConfig = {
    particleCount: 100,
    colors: ["#ff6b6b", "#4ecdc4", "#ffe66d", "#95e1d3", "#f38181", "#aa96da", "#fcbad3", "#a8d8ea"],
    gravity: 400,
    initialVelocity: 600,
    spread: 1.2,
    drag: 0.02,
    lifetime: 4,
    size: 10,
    sizeVariance: 0.5
  };
  var noConfetti = {
    particles: [],
    config: defaultConfig,
    active: false
  };
  var countOnes = function($copy_acc) {
    return function($copy_remaining) {
      var $tco_var_acc = $copy_acc;
      var $tco_done = false;
      var $tco_result;
      function $tco_loop(acc, remaining) {
        var $39 = remaining < 1;
        if ($39) {
          $tco_done = true;
          return acc;
        }
        ;
        $tco_var_acc = acc + 1 | 0;
        $copy_remaining = remaining - 1;
        return;
      }
      ;
      while (!$tco_done) {
        $tco_result = $tco_loop($tco_var_acc, $copy_remaining);
      }
      ;
      return $tco_result;
    };
  };
  var cosApprox = function(x) {
    var x2 = x * x;
    var x4 = x2 * x2;
    var x6 = x4 * x2;
    return 1 - x2 / 2 + x4 / 24 - x6 / 720;
  };
  var approximateInt = function(n) {
    return countOnes(0)(n);
  };
  var roundToInt = function(n) {
    var adjusted = n + 0.5;
    var $40 = adjusted < 1;
    if ($40) {
      return 0;
    }
    ;
    return approximateInt(adjusted);
  };
  var truncatePos = function(n) {
    var scaled = n * 1;
    var $41 = scaled > 2147483647;
    if ($41) {
      return 2147483647;
    }
    ;
    var $42 = scaled < 0;
    if ($42) {
      return 0;
    }
    ;
    return roundToInt(scaled);
  };
  var truncateNum = function(n) {
    var $43 = n < 0;
    if ($43) {
      return -truncatePos(-n) | 0;
    }
    ;
    return truncatePos(n);
  };
  var floorNum = function(n) {
    return n - (n - (n * 0 + toNumber(truncateNum(n))));
  };
  var pseudoRandom = function(seed) {
    var next = 1664525 * seed + 1013904223 - floorNum((1664525 * seed + 1013904223) / 4294967296) * 4294967296;
    return next / 4294967296;
  };
  var createParticle = function(idx) {
    return function(x) {
      return function(y) {
        return function(cfg) {
          var shape = (function() {
            var v = intMod2(idx)(4);
            if (v === 0) {
              return Square.value;
            }
            ;
            if (v === 1) {
              return Circle.value;
            }
            ;
            if (v === 2) {
              return Rectangle.value;
            }
            ;
            return Star.value;
          })();
          var seed = toNumber(idx);
          var rand5 = pseudoRandom(seed + 0.4);
          var rand4 = pseudoRandom(seed + 0.3);
          var rotation = rand4 * 6.283;
          var rand3 = pseudoRandom(seed + 0.2);
          var sizeVar = 1 + (rand3 - 0.5) * cfg.sizeVariance;
          var size2 = cfg.size * sizeVar;
          var rand2 = pseudoRandom(seed + 0.1);
          var speed = cfg.initialVelocity * (0.7 + rand2 * 0.6);
          var rand1 = pseudoRandom(seed);
          var colorIdx = intMod2(idx)(length(cfg.colors));
          var color = indexOr("#ffffff")(colorIdx)(cfg.colors);
          var angularVel = (rand5 - 0.5) * 10;
          var angle = (rand1 - 0.5) * cfg.spread - 1.5708;
          var vx = speed * cosApprox(angle);
          var vy = speed * sinApprox(angle);
          return {
            x,
            y,
            vx,
            vy,
            rotation,
            angularVel,
            size: size2,
            color,
            age: 0,
            lifetime: cfg.lifetime * (0.8 + rand1 * 0.4),
            shape
          };
        };
      };
    };
  };
  var explodeAt = function(x) {
    return function(y) {
      return function(cfg) {
        var indices = range2(0)(cfg.particleCount - 1 | 0);
        var particles = map4(function(i) {
          return createParticle(i)(x)(y)(cfg);
        })(indices);
        return {
          particles,
          config: cfg,
          active: true
        };
      };
    };
  };

  // output/Canvas.Easter.KonamiCode/index.js
  var toLowerCase = function(s) {
    if (s === "A") {
      return "a";
    }
    ;
    if (s === "B") {
      return "b";
    }
    ;
    return s;
  };
  var konamiSequence = ["ArrowUp", "ArrowUp", "ArrowDown", "ArrowDown", "ArrowLeft", "ArrowRight", "ArrowLeft", "ArrowRight", "b", "a"];
  var sequenceLength = /* @__PURE__ */ length(konamiSequence);
  var keyMatches = function(input) {
    return function(expected) {
      return input === expected || toLowerCase(input) === toLowerCase(expected);
    };
  };
  var resetIfWrong = function(key) {
    return function(state2) {
      var v = index(konamiSequence)(0);
      if (v instanceof Just) {
        var $15 = keyMatches(key)(v.value0);
        if ($15) {
          return {
            triggered: state2.triggered,
            lastKeyTime: state2.lastKeyTime,
            index: 1
          };
        }
        ;
        return {
          triggered: state2.triggered,
          lastKeyTime: state2.lastKeyTime,
          index: 0
        };
      }
      ;
      if (v instanceof Nothing) {
        return {
          triggered: state2.triggered,
          lastKeyTime: state2.lastKeyTime,
          index: 0
        };
      }
      ;
      throw new Error("Failed pattern match at Canvas.Easter.KonamiCode (line 167, column 3 - line 173, column 26): " + [v.constructor.name]);
    };
  };
  var isTriggered = function(state2) {
    return state2.triggered;
  };
  var initialState = {
    index: 0,
    triggered: false,
    lastKeyTime: 0
  };
  var reset = function(v) {
    return initialState;
  };
  var advanceSequence = function(state2) {
    var newIndex = state2.index + 1 | 0;
    var $18 = newIndex >= sequenceLength;
    if ($18) {
      return {
        lastKeyTime: state2.lastKeyTime,
        index: newIndex,
        triggered: true
      };
    }
    ;
    return {
      triggered: state2.triggered,
      lastKeyTime: state2.lastKeyTime,
      index: newIndex
    };
  };
  var checkKey = function(key) {
    return function(state2) {
      var v = index(konamiSequence)(state2.index);
      if (v instanceof Nothing) {
        return state2;
      }
      ;
      if (v instanceof Just) {
        var $20 = keyMatches(key)(v.value0);
        if ($20) {
          return advanceSequence(state2);
        }
        ;
        return resetIfWrong(key)(state2);
      }
      ;
      throw new Error("Failed pattern match at Canvas.Easter.KonamiCode (line 145, column 3 - line 153, column 36): " + [v.constructor.name]);
    };
  };
  var processKey = function(key) {
    return function(state2) {
      if (state2.triggered) {
        return state2;
      }
      ;
      return checkKey(key)(state2);
    };
  };

  // output/Canvas.Easter.ShakeDetector/index.js
  var sqrt2 = function(n) {
    if (n < 0) {
      return 0;
    }
    ;
    if (n < 1e-5) {
      return 0;
    }
    ;
    if (true) {
      var x0 = n / 2;
      var x1 = (x0 + n / x0) / 2;
      var x2 = (x1 + n / x1) / 2;
      var x3 = (x2 + n / x2) / 2;
      return x3;
    }
    ;
    throw new Error("Failed pattern match at Canvas.Easter.ShakeDetector (line 267, column 1 - line 267, column 25): " + [n.constructor.name]);
  };
  var reset2 = function(state2) {
    return {
      config: state2.config,
      lastShakeTime: state2.lastShakeTime,
      currentTime: state2.currentTime,
      lastMagnitude: state2.lastMagnitude,
      shakes: [],
      triggered: false,
      lastTriggerTime: state2.currentTime
    };
  };
  var isTriggered2 = function(state2) {
    return state2.triggered;
  };
  var initialStateWith = function(cfg) {
    return {
      config: cfg,
      shakes: [],
      triggered: false,
      lastTriggerTime: 0,
      lastShakeTime: 0,
      currentTime: 0,
      lastMagnitude: 0
    };
  };
  var defaultConfig2 = {
    threshold: 15,
    requiredShakes: 3,
    timeWindow: 1,
    cooldown: 2,
    debounce: 0.1
  };
  var initialState2 = /* @__PURE__ */ initialStateWith(defaultConfig2);
  var cleanupOldShakes = function(state2) {
    var cutoff = state2.currentTime - state2.config.timeWindow;
    var validShakes = filter(function(s) {
      return s.timestamp >= cutoff;
    })(state2.shakes);
    return {
      config: state2.config,
      triggered: state2.triggered,
      lastTriggerTime: state2.lastTriggerTime,
      lastShakeTime: state2.lastShakeTime,
      currentTime: state2.currentTime,
      lastMagnitude: state2.lastMagnitude,
      shakes: validShakes
    };
  };
  var addShake = function(magnitude) {
    return function(timestamp) {
      return function(state2) {
        var newShake = {
          timestamp,
          magnitude
        };
        var withShake = {
          config: state2.config,
          currentTime: state2.currentTime,
          lastMagnitude: state2.lastMagnitude,
          lastTriggerTime: state2.lastTriggerTime,
          triggered: state2.triggered,
          shakes: snoc(state2.shakes)(newShake),
          lastShakeTime: timestamp
        };
        var cleaned = cleanupOldShakes(withShake);
        var currentShakes = length(cleaned.shakes);
        var triggered = currentShakes >= state2.config.requiredShakes;
        return {
          config: cleaned.config,
          shakes: cleaned.shakes,
          lastTriggerTime: cleaned.lastTriggerTime,
          lastShakeTime: cleaned.lastShakeTime,
          currentTime: cleaned.currentTime,
          lastMagnitude: cleaned.lastMagnitude,
          triggered
        };
      };
    };
  };
  var processAcceleration = function(ax) {
    return function(ay) {
      return function(az) {
        return function(timestamp) {
          return function(state2) {
            var magnitude = sqrt2(ax * ax + ay * ay + az * az);
            var withTime = {
              config: state2.config,
              lastShakeTime: state2.lastShakeTime,
              lastTriggerTime: state2.lastTriggerTime,
              shakes: state2.shakes,
              triggered: state2.triggered,
              currentTime: timestamp,
              lastMagnitude: magnitude
            };
            var inDebounce = timestamp - state2.lastShakeTime < state2.config.debounce;
            var inCooldown = timestamp - state2.lastTriggerTime < state2.config.cooldown;
            if (state2.triggered) {
              return withTime;
            }
            ;
            if (inCooldown) {
              return withTime;
            }
            ;
            var $24 = magnitude > state2.config.threshold && timestamp - state2.lastShakeTime >= state2.config.debounce;
            if ($24) {
              return addShake(magnitude)(timestamp)(withTime);
            }
            ;
            return cleanupOldShakes(withTime);
          };
        };
      };
    };
  };
  var processMotion = function(motion) {
    return function(state2) {
      return processAcceleration(motion.accelerationX)(motion.accelerationY)(motion.accelerationZ)(motion.timestamp)(state2);
    };
  };

  // output/Canvas.Easter/index.js
  var updateConfetti = function(dt) {
    return function(state2) {
      return {
        konami: state2.konami,
        shake: state2.shake,
        confetti: update(dt)(state2.confetti)
      };
    };
  };
  var triggerConfetti = function(x) {
    return function(y) {
      return function(state2) {
        return {
          konami: state2.konami,
          shake: state2.shake,
          confetti: explodeAt(x)(y)(defaultConfig)
        };
      };
    };
  };
  var shakeTriggered = function(state2) {
    return isTriggered2(state2.shake);
  };
  var reset3 = function(state2) {
    return {
      konami: reset(state2.konami),
      shake: reset2(state2.shake),
      confetti: state2.confetti
    };
  };
  var renderConfetti = function(state2) {
    return render(state2.confetti);
  };
  var processMotion2 = function(motion) {
    return function(state2) {
      return {
        konami: state2.konami,
        confetti: state2.confetti,
        shake: processMotion(motion)(state2.shake)
      };
    };
  };
  var processKey2 = function(key) {
    return function(state2) {
      return {
        shake: state2.shake,
        confetti: state2.confetti,
        konami: processKey(key)(state2.konami)
      };
    };
  };
  var konamiTriggered = function(state2) {
    return isTriggered(state2.konami);
  };
  var initialState3 = {
    konami: initialState,
    shake: initialState2,
    confetti: noConfetti
  };

  // output/Canvas.Types/index.js
  var max3 = /* @__PURE__ */ max(ordInt);
  var min3 = /* @__PURE__ */ min(ordInt);
  var max12 = /* @__PURE__ */ max(ordNumber);
  var compare2 = /* @__PURE__ */ compare(ordInt);
  var BrushTool = /* @__PURE__ */ (function() {
    function BrushTool2() {
    }
    ;
    BrushTool2.value = new BrushTool2();
    return BrushTool2;
  })();
  var EraserTool = /* @__PURE__ */ (function() {
    function EraserTool2() {
    }
    ;
    EraserTool2.value = new EraserTool2();
    return EraserTool2;
  })();
  var EyedropperTool = /* @__PURE__ */ (function() {
    function EyedropperTool2() {
    }
    ;
    EyedropperTool2.value = new EyedropperTool2();
    return EyedropperTool2;
  })();
  var PanTool = /* @__PURE__ */ (function() {
    function PanTool2() {
    }
    ;
    PanTool2.value = new PanTool2();
    return PanTool2;
  })();
  var ZoomTool = /* @__PURE__ */ (function() {
    function ZoomTool2() {
    }
    ;
    ZoomTool2.value = new ZoomTool2();
    return ZoomTool2;
  })();
  var SelectionTool = /* @__PURE__ */ (function() {
    function SelectionTool2() {
    }
    ;
    SelectionTool2.value = new SelectionTool2();
    return SelectionTool2;
  })();
  var FillTool = /* @__PURE__ */ (function() {
    function FillTool2() {
    }
    ;
    FillTool2.value = new FillTool2();
    return FillTool2;
  })();
  var BlendNormal = /* @__PURE__ */ (function() {
    function BlendNormal2() {
    }
    ;
    BlendNormal2.value = new BlendNormal2();
    return BlendNormal2;
  })();
  var unwrapZIndex = function(v) {
    return v;
  };
  var unwrapLayerId = function(v) {
    return v;
  };
  var showTool = {
    show: function(v) {
      if (v instanceof BrushTool) {
        return "brush";
      }
      ;
      if (v instanceof EraserTool) {
        return "eraser";
      }
      ;
      if (v instanceof EyedropperTool) {
        return "eyedropper";
      }
      ;
      if (v instanceof PanTool) {
        return "pan";
      }
      ;
      if (v instanceof ZoomTool) {
        return "zoom";
      }
      ;
      if (v instanceof SelectionTool) {
        return "selection";
      }
      ;
      if (v instanceof FillTool) {
        return "fill";
      }
      ;
      throw new Error("Failed pattern match at Canvas.Types (line 283, column 1 - line 290, column 25): " + [v.constructor.name]);
    }
  };
  var mkZIndex = function(n) {
    return max3(0)(min3(999)(n));
  };
  var mkVec2D = function(vx) {
    return function(vy) {
      return {
        vx,
        vy
      };
    };
  };
  var mkPoint2D = function(px2) {
    return function(py) {
      return {
        x: px2,
        y: py
      };
    };
  };
  var mkLayerId = function(n) {
    return max3(0)(n);
  };
  var mkBounds = function(bx) {
    return function(by) {
      return function(bw) {
        return function(bh) {
          return {
            x: bx,
            y: by,
            width: max12(0)(bw),
            height: max12(0)(bh)
          };
        };
      };
    };
  };
  var eqZIndex = {
    eq: function(x) {
      return function(y) {
        return x === y;
      };
    }
  };
  var ordZIndex = {
    compare: function(x) {
      return function(y) {
        return compare2(x)(y);
      };
    },
    Eq0: function() {
      return eqZIndex;
    }
  };
  var eqTool = {
    eq: function(x) {
      return function(y) {
        if (x instanceof BrushTool && y instanceof BrushTool) {
          return true;
        }
        ;
        if (x instanceof EraserTool && y instanceof EraserTool) {
          return true;
        }
        ;
        if (x instanceof EyedropperTool && y instanceof EyedropperTool) {
          return true;
        }
        ;
        if (x instanceof PanTool && y instanceof PanTool) {
          return true;
        }
        ;
        if (x instanceof ZoomTool && y instanceof ZoomTool) {
          return true;
        }
        ;
        if (x instanceof SelectionTool && y instanceof SelectionTool) {
          return true;
        }
        ;
        if (x instanceof FillTool && y instanceof FillTool) {
          return true;
        }
        ;
        return false;
      };
    }
  };
  var eqLayerId = {
    eq: function(x) {
      return function(y) {
        return x === y;
      };
    }
  };
  var defaultLayerId = 1;
  var colorBlack = {
    r: 0,
    g: 0,
    b: 0,
    a: 1
  };
  var backgroundLayerId = 0;

  // output/Hydrogen.Schema.Brush.WetMedia.Atoms/index.js
  var max4 = /* @__PURE__ */ max(ordNumber);
  var min4 = /* @__PURE__ */ min(ordNumber);
  var unwrapWetness = function(v) {
    return v;
  };
  var unwrapViscosity = function(v) {
    return v;
  };
  var unwrapDryingRate = function(v) {
    return v;
  };
  var clampPercent = function(n) {
    return max4(0)(min4(100)(n));
  };
  var mkDryingRate = function(n) {
    return clampPercent(n);
  };
  var mkViscosity = function(n) {
    return clampPercent(n);
  };
  var mkWetness = function(n) {
    return clampPercent(n);
  };

  // output/Hydrogen.Schema.Brush.WetMedia.Dynamics/index.js
  var max5 = /* @__PURE__ */ max(ordNumber);
  var min5 = /* @__PURE__ */ min(ordNumber);
  var applyDrying = function(initialWetness) {
    return function(rate) {
      return function(deltaTime) {
        var w0 = unwrapWetness(initialWetness);
        var r = unwrapDryingRate(rate) / 100;
        var dt = max5(0)(min5(60)(deltaTime));
        var newWetness = w0 * pow(2.718281828)(-r * dt);
        return mkWetness(newWetness);
      };
    };
  };

  // output/Hydrogen.Schema.Physics.Fluid.Particle/index.js
  var kernelPoly6 = function(r) {
    return function(h) {
      var $58 = r >= h;
      if ($58) {
        return 0;
      }
      ;
      var r2 = r * r;
      var h2 = h * h;
      var diff = h2 - r2;
      var coeff = 315 / (64 * pi * pow(h)(9));
      return coeff * diff * diff * diff;
    };
  };
  var kernelLaplacianViscosity = function(r) {
    return function(h) {
      var $59 = r >= h;
      if ($59) {
        return 0;
      }
      ;
      var coeff = 45 / (pi * pow(h)(6));
      return coeff * (h - r);
    };
  };
  var kernelGradientSpiky = function(r) {
    return function(h) {
      var $60 = r >= h || r < 1e-4;
      if ($60) {
        return 0;
      }
      ;
      var diff = h - r;
      var coeff = -45 / (pi * pow(h)(6));
      return coeff * diff * diff;
    };
  };

  // output/Canvas.Paint.Particle/index.js
  var max6 = /* @__PURE__ */ max(ordNumber);
  var map5 = /* @__PURE__ */ map(functorArray);
  var div12 = /* @__PURE__ */ div(euclideanRingInt);
  var min6 = /* @__PURE__ */ min(ordNumber);
  var Watercolor = /* @__PURE__ */ (function() {
    function Watercolor3() {
    }
    ;
    Watercolor3.value = new Watercolor3();
    return Watercolor3;
  })();
  var OilPaint = /* @__PURE__ */ (function() {
    function OilPaint3() {
    }
    ;
    OilPaint3.value = new OilPaint3();
    return OilPaint3;
  })();
  var Acrylic = /* @__PURE__ */ (function() {
    function Acrylic3() {
    }
    ;
    Acrylic3.value = new Acrylic3();
    return Acrylic3;
  })();
  var Gouache = /* @__PURE__ */ (function() {
    function Gouache3() {
    }
    ;
    Gouache3.value = new Gouache3();
    return Gouache3;
  })();
  var Ink = /* @__PURE__ */ (function() {
    function Ink3() {
    }
    ;
    Ink3.value = new Ink3();
    return Ink3;
  })();
  var Honey = /* @__PURE__ */ (function() {
    function Honey2() {
    }
    ;
    Honey2.value = new Honey2();
    return Honey2;
  })();
  var systemParticles = function(sys) {
    return sys.particles;
  };
  var presetStiffness = function(v) {
    if (v instanceof Watercolor) {
      return 500;
    }
    ;
    if (v instanceof OilPaint) {
      return 2e3;
    }
    ;
    if (v instanceof Acrylic) {
      return 1e3;
    }
    ;
    if (v instanceof Gouache) {
      return 1200;
    }
    ;
    if (v instanceof Ink) {
      return 300;
    }
    ;
    if (v instanceof Honey) {
      return 5e3;
    }
    ;
    throw new Error("Failed pattern match at Canvas.Paint.Particle (line 518, column 1 - line 518, column 41): " + [v.constructor.name]);
  };
  var presetProperties = function(v) {
    if (v instanceof Watercolor) {
      return {
        wetness: mkWetness(80),
        viscosity: mkViscosity(15),
        dryingRate: mkDryingRate(25),
        bleedRate: 0.7,
        granulation: 0.5,
        opacity: 0.6
      };
    }
    ;
    if (v instanceof OilPaint) {
      return {
        wetness: mkWetness(60),
        viscosity: mkViscosity(75),
        dryingRate: mkDryingRate(5),
        bleedRate: 0.2,
        granulation: 0.1,
        opacity: 0.95
      };
    }
    ;
    if (v instanceof Acrylic) {
      return {
        wetness: mkWetness(70),
        viscosity: mkViscosity(50),
        dryingRate: mkDryingRate(60),
        bleedRate: 0.3,
        granulation: 0.2,
        opacity: 0.9
      };
    }
    ;
    if (v instanceof Gouache) {
      return {
        wetness: mkWetness(65),
        viscosity: mkViscosity(55),
        dryingRate: mkDryingRate(40),
        bleedRate: 0.25,
        granulation: 0.15,
        opacity: 1
      };
    }
    ;
    if (v instanceof Ink) {
      return {
        wetness: mkWetness(90),
        viscosity: mkViscosity(5),
        dryingRate: mkDryingRate(70),
        bleedRate: 0.8,
        granulation: 0,
        opacity: 1
      };
    }
    ;
    if (v instanceof Honey) {
      return {
        wetness: mkWetness(95),
        viscosity: mkViscosity(95),
        dryingRate: mkDryingRate(2),
        bleedRate: 0.05,
        granulation: 0,
        opacity: 0.85
      };
    }
    ;
    throw new Error("Failed pattern match at Canvas.Paint.Particle (line 467, column 1 - line 467, column 52): " + [v.constructor.name]);
  };
  var particleRadius = function(p) {
    return p.radius;
  };
  var particlePosition = function(p) {
    return mkPoint2D(p.x)(p.y);
  };
  var particleHeight = function(p) {
    return p.height;
  };
  var particleCount = function(sys) {
    return length(sys.particles);
  };
  var particleColor = function(p) {
    return p.color;
  };
  var mkPaintSystem = function(systemBounds1) {
    return function(paintPreset) {
      return {
        particles: [],
        bounds: systemBounds1,
        smoothingRadius: 15,
        restDensity: 1e3,
        stiffness: presetStiffness(paintPreset),
        gravityX: 0,
        gravityY: 0,
        nextId: 0,
        preset: paintPreset
      };
    };
  };
  var mkPaintParticle = function(pid) {
    return function(px2) {
      return function(py) {
        return function(pcolor) {
          return function(pwet) {
            return function(pvisc) {
              return {
                id: pid,
                x: px2,
                y: py,
                vx: 0,
                vy: 0,
                mass: 1,
                density: 1e3,
                pressure: 0,
                color: pcolor,
                wetness: pwet,
                viscosity: pvisc,
                dryingRate: mkDryingRate(10),
                radius: 3,
                height: 0.1,
                age: 0
              };
            };
          };
        };
      };
    };
  };
  var mkBrushDrag = function(cx) {
    return function(cy) {
      return function(px2) {
        return function(py) {
          return function(radius) {
            return function(pressure) {
              return {
                x: cx,
                y: cy,
                vx: (cx - px2) * 2,
                vy: (cy - py) * 2,
                radius,
                strength: pressure
              };
            };
          };
        };
      };
    };
  };
  var integrateParticles = function(sys) {
    return function(dt) {
      var integrate = function(p) {
        return {
          vx: p.vx,
          vy: p.vy,
          color: p.color,
          density: p.density,
          dryingRate: p.dryingRate,
          height: p.height,
          id: p.id,
          mass: p.mass,
          pressure: p.pressure,
          radius: p.radius,
          viscosity: p.viscosity,
          wetness: p.wetness,
          x: p.x + p.vx * dt,
          y: p.y + p.vy * dt,
          age: p.age + dt
        };
      };
      return {
        bounds: sys.bounds,
        smoothingRadius: sys.smoothingRadius,
        restDensity: sys.restDensity,
        stiffness: sys.stiffness,
        gravityX: sys.gravityX,
        gravityY: sys.gravityY,
        nextId: sys.nextId,
        preset: sys.preset,
        particles: map5(integrate)(sys.particles)
      };
    };
  };
  var enforceBounds = function(sys) {
    var maxX = sys.bounds.x + sys.bounds.width;
    var maxY = sys.bounds.y + sys.bounds.height;
    var enforceBoundary = function(p) {
      var p1 = (function() {
        var $64 = p.x < sys.bounds.x;
        if ($64) {
          return {
            y: p.y,
            vy: p.vy,
            age: p.age,
            color: p.color,
            density: p.density,
            dryingRate: p.dryingRate,
            height: p.height,
            id: p.id,
            mass: p.mass,
            pressure: p.pressure,
            radius: p.radius,
            viscosity: p.viscosity,
            wetness: p.wetness,
            x: sys.bounds.x,
            vx: (0 - p.vx) * 0.6
          };
        }
        ;
        var $65 = p.x > maxX;
        if ($65) {
          return {
            y: p.y,
            vy: p.vy,
            age: p.age,
            color: p.color,
            density: p.density,
            dryingRate: p.dryingRate,
            height: p.height,
            id: p.id,
            mass: p.mass,
            pressure: p.pressure,
            radius: p.radius,
            viscosity: p.viscosity,
            wetness: p.wetness,
            x: maxX,
            vx: (0 - p.vx) * 0.6
          };
        }
        ;
        return p;
      })();
      var p2 = (function() {
        var $66 = p1.y < sys.bounds.y;
        if ($66) {
          return {
            vx: p1.vx,
            x: p1.x,
            age: p1.age,
            color: p1.color,
            density: p1.density,
            dryingRate: p1.dryingRate,
            height: p1.height,
            id: p1.id,
            mass: p1.mass,
            pressure: p1.pressure,
            radius: p1.radius,
            viscosity: p1.viscosity,
            wetness: p1.wetness,
            y: sys.bounds.y,
            vy: (0 - p1.vy) * 0.6
          };
        }
        ;
        var $67 = p1.y > maxY;
        if ($67) {
          return {
            vx: p1.vx,
            x: p1.x,
            age: p1.age,
            color: p1.color,
            density: p1.density,
            dryingRate: p1.dryingRate,
            height: p1.height,
            id: p1.id,
            mass: p1.mass,
            pressure: p1.pressure,
            radius: p1.radius,
            viscosity: p1.viscosity,
            wetness: p1.wetness,
            y: maxY,
            vy: (0 - p1.vy) * 0.6
          };
        }
        ;
        return p1;
      })();
      return p2;
    };
    return {
      bounds: sys.bounds,
      smoothingRadius: sys.smoothingRadius,
      restDensity: sys.restDensity,
      stiffness: sys.stiffness,
      gravityX: sys.gravityX,
      gravityY: sys.gravityY,
      nextId: sys.nextId,
      preset: sys.preset,
      particles: map5(enforceBoundary)(sys.particles)
    };
  };
  var computePressures = function(sys) {
    var updatePressure = function(p) {
      var pressure = max6(0)(sys.stiffness * (p.density - sys.restDensity));
      return {
        density: p.density,
        age: p.age,
        color: p.color,
        dryingRate: p.dryingRate,
        height: p.height,
        id: p.id,
        mass: p.mass,
        radius: p.radius,
        viscosity: p.viscosity,
        vx: p.vx,
        vy: p.vy,
        wetness: p.wetness,
        x: p.x,
        y: p.y,
        pressure
      };
    };
    return {
      bounds: sys.bounds,
      smoothingRadius: sys.smoothingRadius,
      restDensity: sys.restDensity,
      stiffness: sys.stiffness,
      gravityX: sys.gravityX,
      gravityY: sys.gravityY,
      nextId: sys.nextId,
      preset: sys.preset,
      particles: map5(updatePressure)(sys.particles)
    };
  };
  var computeForces = function(sys) {
    var computeParticleForce = function(p) {
      var wetMod = unwrapWetness(p.wetness) / 100;
      var viscMod = unwrapViscosity(p.viscosity) / 100;
      var fPressure = foldl2(function(acc) {
        return function(neighbor) {
          var $68 = neighbor.id === p.id;
          if ($68) {
            return acc;
          }
          ;
          var dy = p.y - neighbor.y;
          var dx = p.x - neighbor.x;
          var r = sqrt(dx * dx + dy * dy);
          var gradW = kernelGradientSpiky(r)(sys.smoothingRadius);
          var dirY = (function() {
            var $69 = r > 1e-4;
            if ($69) {
              return dy / r;
            }
            ;
            return 0;
          })();
          var dirX = (function() {
            var $70 = r > 1e-4;
            if ($70) {
              return dx / r;
            }
            ;
            return 0;
          })();
          var avgPressure = (p.pressure + neighbor.pressure) / 2;
          var scale = (0 - neighbor.mass) * avgPressure / max6(1e-3)(neighbor.density) * gradW;
          return {
            fx: acc.fx + scale * dirX,
            fy: acc.fy + scale * dirY
          };
        };
      })({
        fx: 0,
        fy: 0
      })(sys.particles);
      var fGravityY = p.mass * sys.gravityY * wetMod;
      var fGravityX = p.mass * sys.gravityX * wetMod;
      var effectiveVisc = viscMod * wetMod * 0.5;
      var fViscosity = foldl2(function(acc) {
        return function(neighbor) {
          var $71 = neighbor.id === p.id;
          if ($71) {
            return acc;
          }
          ;
          var dy = p.y - neighbor.y;
          var dx = p.x - neighbor.x;
          var r = sqrt(dx * dx + dy * dy);
          var lapW = kernelLaplacianViscosity(r)(sys.smoothingRadius);
          var scale = effectiveVisc * neighbor.mass / max6(1e-3)(neighbor.density) * lapW;
          var dvy = neighbor.vy - p.vy;
          var dvx = neighbor.vx - p.vx;
          return {
            fx: acc.fx + scale * dvx,
            fy: acc.fy + scale * dvy
          };
        };
      })({
        fx: 0,
        fy: 0
      })(sys.particles);
      return {
        fx: fPressure.fx + fViscosity.fx + fGravityX,
        fy: fPressure.fy + fViscosity.fy + fGravityY
      };
    };
    var applyForce = function(p) {
      var f = computeParticleForce(p);
      return {
        age: p.age,
        color: p.color,
        density: p.density,
        dryingRate: p.dryingRate,
        height: p.height,
        id: p.id,
        mass: p.mass,
        pressure: p.pressure,
        radius: p.radius,
        viscosity: p.viscosity,
        wetness: p.wetness,
        x: p.x,
        y: p.y,
        vx: p.vx + f.fx / p.mass,
        vy: p.vy + f.fy / p.mass
      };
    };
    return {
      bounds: sys.bounds,
      smoothingRadius: sys.smoothingRadius,
      restDensity: sys.restDensity,
      stiffness: sys.stiffness,
      gravityX: sys.gravityX,
      gravityY: sys.gravityY,
      nextId: sys.nextId,
      preset: sys.preset,
      particles: map5(applyForce)(sys.particles)
    };
  };
  var computeDensities = function(sys) {
    var computeParticleDensity = function(p) {
      return foldl2(function(acc) {
        return function(neighbor) {
          var dy = p.y - neighbor.y;
          var dx = p.x - neighbor.x;
          var r = sqrt(dx * dx + dy * dy);
          var w = kernelPoly6(r)(sys.smoothingRadius);
          return acc + neighbor.mass * w;
        };
      })(0)(sys.particles);
    };
    var updateDensity = function(p) {
      return {
        age: p.age,
        color: p.color,
        dryingRate: p.dryingRate,
        height: p.height,
        id: p.id,
        mass: p.mass,
        pressure: p.pressure,
        radius: p.radius,
        viscosity: p.viscosity,
        vx: p.vx,
        vy: p.vy,
        wetness: p.wetness,
        x: p.x,
        y: p.y,
        density: computeParticleDensity(p)
      };
    };
    return {
      bounds: sys.bounds,
      smoothingRadius: sys.smoothingRadius,
      restDensity: sys.restDensity,
      stiffness: sys.stiffness,
      gravityX: sys.gravityX,
      gravityY: sys.gravityY,
      nextId: sys.nextId,
      preset: sys.preset,
      particles: map5(updateDensity)(sys.particles)
    };
  };
  var colorToHex = function(c) {
    var hexDigit = function(d) {
      if (d < 0) {
        return "0";
      }
      ;
      if (d === 0) {
        return "0";
      }
      ;
      if (d === 1) {
        return "1";
      }
      ;
      if (d === 2) {
        return "2";
      }
      ;
      if (d === 3) {
        return "3";
      }
      ;
      if (d === 4) {
        return "4";
      }
      ;
      if (d === 5) {
        return "5";
      }
      ;
      if (d === 6) {
        return "6";
      }
      ;
      if (d === 7) {
        return "7";
      }
      ;
      if (d === 8) {
        return "8";
      }
      ;
      if (d === 9) {
        return "9";
      }
      ;
      if (d === 10) {
        return "a";
      }
      ;
      if (d === 11) {
        return "b";
      }
      ;
      if (d === 12) {
        return "c";
      }
      ;
      if (d === 13) {
        return "d";
      }
      ;
      if (d === 14) {
        return "e";
      }
      ;
      if (otherwise) {
        return "f";
      }
      ;
      throw new Error("Failed pattern match at Canvas.Paint.Particle (line 325, column 5 - line 325, column 30): " + [d.constructor.name]);
    };
    var toHex2 = function(n) {
      var i = floor2(n * 255);
      var hi = div12(i)(16);
      var lo = i - (hi * 16 | 0) | 0;
      return hexDigit(hi) + hexDigit(lo);
    };
    return "#" + (toHex2(c.r) + (toHex2(c.g) + toHex2(c.b)));
  };
  var particleColorHex = function(p) {
    return colorToHex(p.color);
  };
  var clearParticles = function(sys) {
    return {
      bounds: sys.bounds,
      smoothingRadius: sys.smoothingRadius,
      restDensity: sys.restDensity,
      stiffness: sys.stiffness,
      gravityX: sys.gravityX,
      gravityY: sys.gravityY,
      preset: sys.preset,
      particles: [],
      nextId: 0
    };
  };
  var applyImpastoStacking = function(sys) {
    var computeStackingHeight = function(p) {
      return foldl2(function(acc) {
        return function(neighbor) {
          var $74 = neighbor.id === p.id;
          if ($74) {
            return acc;
          }
          ;
          var wetMod = unwrapWetness(neighbor.wetness) / 100;
          var viscMod = unwrapViscosity(neighbor.viscosity) / 100;
          var dy = p.y - neighbor.y;
          var dx = p.x - neighbor.x;
          var dist = sqrt(dx * dx + dy * dy);
          var overlapFactor = max6(0)(1 - dist / sys.smoothingRadius);
          var contribution = overlapFactor * overlapFactor * viscMod * wetMod * neighbor.height * 0.1;
          return acc + contribution;
        };
      })(0)(sys.particles);
    };
    var updateHeight = function(p) {
      var stackAdd = computeStackingHeight(p);
      var newHeight = p.height + stackAdd;
      var cappedHeight = min6(5)(newHeight);
      return {
        age: p.age,
        color: p.color,
        density: p.density,
        dryingRate: p.dryingRate,
        id: p.id,
        mass: p.mass,
        pressure: p.pressure,
        radius: p.radius,
        viscosity: p.viscosity,
        vx: p.vx,
        vy: p.vy,
        wetness: p.wetness,
        x: p.x,
        y: p.y,
        height: cappedHeight
      };
    };
    return {
      bounds: sys.bounds,
      smoothingRadius: sys.smoothingRadius,
      restDensity: sys.restDensity,
      stiffness: sys.stiffness,
      gravityX: sys.gravityX,
      gravityY: sys.gravityY,
      nextId: sys.nextId,
      preset: sys.preset,
      particles: map5(updateHeight)(sys.particles)
    };
  };
  var applyGravity = function(sys) {
    return function(gx) {
      return function(gy) {
        return {
          particles: sys.particles,
          bounds: sys.bounds,
          smoothingRadius: sys.smoothingRadius,
          restDensity: sys.restDensity,
          stiffness: sys.stiffness,
          nextId: sys.nextId,
          preset: sys.preset,
          gravityX: gx,
          gravityY: gy
        };
      };
    };
  };
  var applyDrying2 = function(sys) {
    return function(dt) {
      var dryParticle = function(p) {
        var newWetness = applyDrying(p.wetness)(p.dryingRate)(dt);
        return {
          dryingRate: p.dryingRate,
          age: p.age,
          color: p.color,
          density: p.density,
          height: p.height,
          id: p.id,
          mass: p.mass,
          pressure: p.pressure,
          radius: p.radius,
          viscosity: p.viscosity,
          vx: p.vx,
          vy: p.vy,
          x: p.x,
          y: p.y,
          wetness: newWetness
        };
      };
      return {
        bounds: sys.bounds,
        smoothingRadius: sys.smoothingRadius,
        restDensity: sys.restDensity,
        stiffness: sys.stiffness,
        gravityX: sys.gravityX,
        gravityY: sys.gravityY,
        nextId: sys.nextId,
        preset: sys.preset,
        particles: map5(dryParticle)(sys.particles)
      };
    };
  };
  var simulateStep = function(sys) {
    return function(dt) {
      var withDensities = computeDensities(sys);
      var withPressures = computePressures(withDensities);
      var withForces = computeForces(withPressures);
      var integrated = integrateParticles(withForces)(dt);
      var bounded = enforceBounds(integrated);
      var stacked = applyImpastoStacking(bounded);
      var dried = applyDrying2(stacked)(dt);
      return dried;
    };
  };
  var applyBrushDrag = function(brush) {
    return function(sys) {
      var applyDrag = function(p) {
        var wetMod = unwrapWetness(p.wetness) / 100;
        var viscResist = 1 - unwrapViscosity(p.viscosity) / 150;
        var viscMod = max6(0.1)(viscResist);
        var dy = p.y - brush.y;
        var dx = p.x - brush.x;
        var dist = sqrt(dx * dx + dy * dy);
        var inRange = dist < brush.radius;
        var falloff = (function() {
          if (inRange) {
            return (1 - dist / brush.radius) * (1 - dist / brush.radius);
          }
          ;
          return 0;
        })();
        var dragCoeff = falloff * wetMod * viscMod * brush.strength;
        var newVx = p.vx + brush.vx * dragCoeff;
        var newVy = p.vy + brush.vy * dragCoeff;
        var newX = p.x + brush.vx * dragCoeff * 0.1;
        var newY = p.y + brush.vy * dragCoeff * 0.1;
        var $76 = inRange && wetMod > 0.01;
        if ($76) {
          return {
            id: p.id,
            mass: p.mass,
            density: p.density,
            pressure: p.pressure,
            color: p.color,
            wetness: p.wetness,
            viscosity: p.viscosity,
            dryingRate: p.dryingRate,
            radius: p.radius,
            height: p.height,
            age: p.age,
            vx: newVx,
            vy: newVy,
            x: newX,
            y: newY
          };
        }
        ;
        return p;
      };
      return {
        bounds: sys.bounds,
        smoothingRadius: sys.smoothingRadius,
        restDensity: sys.restDensity,
        stiffness: sys.stiffness,
        gravityX: sys.gravityX,
        gravityY: sys.gravityY,
        nextId: sys.nextId,
        preset: sys.preset,
        particles: map5(applyDrag)(sys.particles)
      };
    };
  };
  var allParticles = systemParticles;
  var addParticle = function(sys) {
    return function(px2) {
      return function(py) {
        return function(pcolor) {
          var props = presetProperties(sys.preset);
          var newParticle = mkPaintParticle(sys.nextId)(px2)(py)(pcolor)(props.wetness)(props.viscosity);
          return {
            bounds: sys.bounds,
            smoothingRadius: sys.smoothingRadius,
            restDensity: sys.restDensity,
            stiffness: sys.stiffness,
            gravityX: sys.gravityX,
            gravityY: sys.gravityY,
            preset: sys.preset,
            particles: snoc(sys.particles)(newParticle),
            nextId: sys.nextId + 1 | 0
          };
        };
      };
    };
  };

  // output/Hydrogen.Schema.Canvas.Physics/index.js
  var max7 = /* @__PURE__ */ max(ordNumber);
  var min7 = /* @__PURE__ */ min(ordNumber);
  var mkGravityVector = function(gx) {
    return function(gy) {
      return function(gz) {
        return {
          x: gx,
          y: gy,
          z: gz
        };
      };
    };
  };
  var orientationToGravity = function(o) {
    var gammaRad = o.gamma * pi / 180;
    var gx = sin(gammaRad);
    var betaRad = o.beta * pi / 180;
    var gy = sin(betaRad) * cos(gammaRad);
    var gz = -(cos(betaRad) * cos(gammaRad));
    return mkGravityVector(gx)(gy)(gz);
  };
  var updateOrientation = function(newOrientation) {
    return function(physics) {
      return {
        gravityScale: physics.gravityScale,
        orientation: newOrientation,
        gravity: orientationToGravity(newOrientation)
      };
    };
  };
  var isGravitySignificant = function(g) {
    return function(threshold) {
      var mag2d = sqrt(g.x * g.x + g.y * g.y);
      return mag2d >= threshold;
    };
  };
  var gravityZ = function(g) {
    return g.z;
  };
  var gravityY = function(g) {
    return g.y;
  };
  var gravityX = function(g) {
    return g.x;
  };
  var gravityMagnitude = function(g) {
    return sqrt(g.x * g.x + g.y * g.y + g.z * g.z);
  };
  var gravity2D = function(g) {
    return {
      x: g.x,
      y: g.y
    };
  };
  var getGravityDirection = function(physics) {
    var mag = gravityMagnitude(physics.gravity);
    var $26 = mag > 1e-3;
    if ($26) {
      return mkGravityVector(physics.gravity.x / mag * physics.gravityScale)(physics.gravity.y / mag * physics.gravityScale)(physics.gravity.z / mag * physics.gravityScale);
    }
    ;
    return mkGravityVector(0)(0)(0);
  };
  var getGravity2D = function(physics) {
    var g = getGravityDirection(physics);
    return {
      x: g.x,
      y: g.y
    };
  };
  var clampAngle90 = function(a) {
    return max7(-90)(min7(90)(a));
  };
  var clampAngle360 = function($copy_a) {
    var $tco_done = false;
    var $tco_result;
    function $tco_loop(a) {
      if (a < 0) {
        $copy_a = a + 360;
        return;
      }
      ;
      if (a >= 360) {
        $copy_a = a - 360;
        return;
      }
      ;
      if (otherwise) {
        $tco_done = true;
        return a;
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Schema.Canvas.Physics (line 388, column 1 - line 388, column 34): " + [a.constructor.name]);
    }
    ;
    while (!$tco_done) {
      $tco_result = $tco_loop($copy_a);
    }
    ;
    return $tco_result;
  };
  var clampAngle180 = function($copy_a) {
    var $tco_done = false;
    var $tco_result;
    function $tco_loop(a) {
      if (a < -180) {
        $copy_a = a + 360;
        return;
      }
      ;
      if (a > 180) {
        $copy_a = a - 360;
        return;
      }
      ;
      if (otherwise) {
        $tco_done = true;
        return a;
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Schema.Canvas.Physics (line 395, column 1 - line 395, column 34): " + [a.constructor.name]);
    }
    ;
    while (!$tco_done) {
      $tco_result = $tco_loop($copy_a);
    }
    ;
    return $tco_result;
  };
  var mkDeviceOrientation = function(a) {
    return function(b) {
      return function(g) {
        return {
          alpha: clampAngle360(a),
          beta: clampAngle180(b),
          gamma: clampAngle90(g)
        };
      };
    };
  };
  var orientationPortrait = /* @__PURE__ */ mkDeviceOrientation(0)(90)(0);
  var mkCanvasPhysics = function(scale) {
    return {
      orientation: orientationPortrait,
      gravity: orientationToGravity(orientationPortrait),
      gravityScale: max7(0)(scale)
    };
  };

  // output/Canvas.Physics.Gravity/index.js
  var max8 = /* @__PURE__ */ max(ordNumber);
  var min8 = /* @__PURE__ */ min(ordNumber);
  var updateFromOrientation = function(alpha) {
    return function(beta) {
      return function(gamma) {
        return function(gs) {
          var newOrientation = mkDeviceOrientation(alpha)(beta)(gamma);
          var newPhysics = updateOrientation(newOrientation)(gs.physics);
          return {
            enabled: gs.enabled,
            scale: gs.scale,
            flowScale: gs.flowScale,
            flatThreshold: gs.flatThreshold,
            physics: newPhysics
          };
        };
      };
    };
  };
  var setGravityEnabled = function(en) {
    return function(gs) {
      return {
        physics: gs.physics,
        scale: gs.scale,
        flowScale: gs.flowScale,
        flatThreshold: gs.flatThreshold,
        enabled: en
      };
    };
  };
  var gravityEnabled = function(gs) {
    return gs.enabled;
  };
  var getGravity2D2 = function(gs) {
    if (gs.enabled) {
      var g2d = getGravity2D(gs.physics);
      return mkVec2D(g2d.x)(g2d.y);
    }
    ;
    return mkVec2D(0)(0);
  };
  var currentGravity = function(gs) {
    return gs.physics.gravity;
  };
  var isGravityActive = function(gs) {
    return gs.enabled && isGravitySignificant(currentGravity(gs))(gs.flatThreshold);
  };
  var clamp01 = function(n) {
    return max8(0)(min8(1)(n));
  };
  var mkGravityState = function(gravScale) {
    return {
      physics: mkCanvasPhysics(gravScale),
      enabled: true,
      scale: clamp01(gravScale),
      flowScale: 100,
      flatThreshold: 0.1
    };
  };
  var initialGravityState = /* @__PURE__ */ mkGravityState(1);

  // output/Canvas.Runtime.DOM/foreign.js
  var selectElementImpl = (selector) => () => {
    const el = document.querySelector(selector);
    return el || null;
  };
  var setInnerHTML = (el) => (html) => () => {
    el.innerHTML = html;
  };
  var requestAnimationFrameImpl = (callback) => () => {
    let lastTime = performance.now();
    let rafId = null;
    let running = true;
    const loop = (currentTime) => {
      if (!running) return;
      const deltaTime = currentTime - lastTime;
      lastTime = currentTime;
      callback(deltaTime)();
      rafId = requestAnimationFrame(loop);
    };
    rafId = requestAnimationFrame(loop);
    return () => {
      running = false;
      if (rafId !== null) {
        cancelAnimationFrame(rafId);
      }
    };
  };
  var newRef = (initial) => () => {
    return { value: initial };
  };
  var readRef = (ref) => () => {
    return ref.value;
  };
  var writeRef = (ref) => (value) => () => {
    ref.value = value;
  };
  var setGPUStatusTextImpl = (text2) => () => {
    const el = document.getElementById("gpu-backend");
    if (el) {
      el.textContent = text2;
    }
  };
  var setGlobalUnmountImpl = (unmountFn) => () => {
    window.__canvasUnmount = () => {
      console.log("Canvas: Unmounting...");
      unmountFn();
      console.log("Canvas: Animation loop stopped");
    };
  };
  var keyboardShortcutCallback = null;
  var addKeyboardShortcutListenerImpl = (callback) => () => {
    keyboardShortcutCallback = callback;
    const handler = (e) => {
      const shortcut = {
        key: e.key,
        ctrlKey: e.ctrlKey || e.metaKey,
        // Handle both Ctrl and Cmd (macOS)
        shiftKey: e.shiftKey,
        altKey: e.altKey
      };
      if (shortcut.ctrlKey) {
        const key = e.key.toLowerCase();
        if (key === "z" || key === "y" || key === "s" || key === "e") {
          e.preventDefault();
        }
      }
      callback(shortcut)();
    };
    document.addEventListener("keydown", handler);
    return () => {
      document.removeEventListener("keydown", handler);
      keyboardShortcutCallback = null;
    };
  };
  var exportCanvasPNGImpl = (canvasId) => () => {
    const canvas = document.getElementById(canvasId);
    if (!canvas) {
      console.error("Canvas not found:", canvasId);
      return;
    }
    try {
      const dataURL = canvas.toDataURL("image/png");
      const link = document.createElement("a");
      link.download = "canvas-export.png";
      link.href = dataURL;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      console.log("Canvas exported as PNG");
    } catch (err) {
      console.error("Failed to export canvas as PNG:", err);
    }
  };
  var exportCanvasSVGImpl = (svgId) => () => {
    const svg = document.getElementById(svgId);
    if (!svg) {
      console.error("SVG element not found:", svgId);
      return;
    }
    try {
      const svgClone = svg.cloneNode(true);
      svgClone.style.display = "block";
      const serializer = new XMLSerializer();
      const svgString = serializer.serializeToString(svgClone);
      const blob = new Blob([svgString], { type: "image/svg+xml" });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.download = "canvas-export.svg";
      link.href = url;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
      console.log("Canvas exported as SVG");
    } catch (err) {
      console.error("Failed to export canvas as SVG:", err);
    }
  };
  var canvasTexturePattern = null;
  var generateLinenTexture = (width, height) => {
    const offscreen = document.createElement("canvas");
    offscreen.width = width;
    offscreen.height = height;
    const ctx = offscreen.getContext("2d");
    ctx.fillStyle = "#f5f0e6";
    ctx.fillRect(0, 0, width, height);
    ctx.strokeStyle = "rgba(200, 190, 170, 0.3)";
    ctx.lineWidth = 1;
    for (let y = 0; y < height; y += 3) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      for (let x = 0; x < width; x += 4) {
        const offset = Math.sin(x * 0.1 + y * 0.05) * 0.5;
        ctx.lineTo(x, y + offset);
      }
      ctx.stroke();
    }
    ctx.strokeStyle = "rgba(180, 170, 150, 0.25)";
    for (let x = 0; x < width; x += 3) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      for (let y = 0; y < height; y += 4) {
        const offset = Math.sin(y * 0.1 + x * 0.05) * 0.5;
        ctx.lineTo(x + offset, y);
      }
      ctx.stroke();
    }
    const imageData = ctx.getImageData(0, 0, width, height);
    const data = imageData.data;
    for (let i = 0; i < data.length; i += 4) {
      const noise = (Math.random() - 0.5) * 8;
      data[i] = Math.min(255, Math.max(0, data[i] + noise));
      data[i + 1] = Math.min(255, Math.max(0, data[i + 1] + noise));
      data[i + 2] = Math.min(255, Math.max(0, data[i + 2] + noise));
    }
    ctx.putImageData(imageData, 0, 0);
    return offscreen;
  };
  var initCanvasTextureImpl = (canvasId) => () => {
    const canvas = document.getElementById(canvasId);
    if (!canvas) {
      console.warn("Canvas texture: element not found:", canvasId);
      return;
    }
    console.log("Canvas texture: Generating linen texture...");
    const textureSize = 128;
    const textureCanvas = generateLinenTexture(textureSize, textureSize);
    const ctx = canvas.getContext("2d");
    if (ctx) {
      canvasTexturePattern = ctx.createPattern(textureCanvas, "repeat");
      console.log("Canvas texture: Linen texture initialized");
    }
  };
  var renderCanvasTextureImpl = (canvasId) => () => {
    const canvas = document.getElementById(canvasId);
    if (!canvas || !canvasTexturePattern) {
      return;
    }
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    ctx.fillStyle = canvasTexturePattern;
    ctx.fillRect(0, 0, canvas.width, canvas.height);
  };

  // output/Effect.Class/index.js
  var monadEffectEffect = {
    liftEffect: /* @__PURE__ */ identity(categoryFn),
    Monad0: function() {
      return monadEffect;
    }
  };
  var liftEffect = function(dict) {
    return dict.liftEffect;
  };

  // output/Effect.Console/foreign.js
  var log2 = function(s) {
    return function() {
      console.log(s);
    };
  };

  // output/Effect.Class.Console/index.js
  var log3 = function(dictMonadEffect) {
    var $67 = liftEffect(dictMonadEffect);
    return function($68) {
      return $67(log2($68));
    };
  };

  // output/Hydrogen.Schema.Bounded/index.js
  var isFiniteNumber = function(n) {
    return !(n !== n) && (n !== 1 / 0 && n !== -1 / 0);
  };
  var clampNumber = function(minVal) {
    return function(maxVal) {
      return function(n) {
        if (!isFiniteNumber(n)) {
          return minVal;
        }
        ;
        if (n < minVal) {
          return minVal;
        }
        ;
        if (n > maxVal) {
          return maxVal;
        }
        ;
        if (otherwise) {
          return n;
        }
        ;
        throw new Error("Failed pattern match at Hydrogen.Schema.Bounded (line 207, column 1 - line 207, column 52): " + [minVal.constructor.name, maxVal.constructor.name, n.constructor.name]);
      };
    };
  };
  var clampInt = function(minVal) {
    return function(maxVal) {
      return function(n) {
        if (n < minVal) {
          return minVal;
        }
        ;
        if (n > maxVal) {
          return maxVal;
        }
        ;
        if (otherwise) {
          return n;
        }
        ;
        throw new Error("Failed pattern match at Hydrogen.Schema.Bounded (line 191, column 1 - line 191, column 37): " + [minVal.constructor.name, maxVal.constructor.name, n.constructor.name]);
      };
    };
  };

  // output/Hydrogen.Math.Core.Constants/index.js
  var pi2 = 3.141592653589793;
  var negativeInfinity = /* @__PURE__ */ (function() {
    return -1 / 0;
  })();
  var $$isNaN = function(x) {
    return x !== x;
  };
  var infinity2 = /* @__PURE__ */ (function() {
    return 1 / 0;
  })();

  // output/Hydrogen.Schema.Dimension.Device.Types/index.js
  var Pixel = function(x) {
    return x;
  };

  // output/Hydrogen.Schema.Dimension.Device.Operations/index.js
  var unwrapPixel = function(v) {
    return v;
  };
  var px = Pixel;

  // output/Hydrogen.GPU.Coordinates/index.js
  var unwrapScreenY = function(v) {
    return v;
  };
  var unwrapScreenX = function(v) {
    return v;
  };
  var unwrapPixelWidth = function(v) {
    return v;
  };
  var unwrapPixelHeight = function(v) {
    return v;
  };
  var minScreenCoord = /* @__PURE__ */ (function() {
    return -32768;
  })();
  var maxScreenCoord = 32768;
  var screenX = function(n) {
    return clampNumber(minScreenCoord)(maxScreenCoord)(n);
  };
  var screenY = function(n) {
    return clampNumber(minScreenCoord)(maxScreenCoord)(n);
  };
  var depthValue = function(n) {
    return clampNumber(0)(1)(n);
  };

  // output/Hydrogen.Schema.Geometry.Radius/index.js
  var RadiusPx = /* @__PURE__ */ (function() {
    function RadiusPx2(value0) {
      this.value0 = value0;
    }
    ;
    RadiusPx2.create = function(value0) {
      return new RadiusPx2(value0);
    };
    return RadiusPx2;
  })();
  var RadiusPercent = /* @__PURE__ */ (function() {
    function RadiusPercent2(value0) {
      this.value0 = value0;
    }
    ;
    RadiusPercent2.create = function(value0) {
      return new RadiusPercent2(value0);
    };
    return RadiusPercent2;
  })();
  var RadiusRem = /* @__PURE__ */ (function() {
    function RadiusRem2(value0) {
      this.value0 = value0;
    }
    ;
    RadiusRem2.create = function(value0) {
      return new RadiusRem2(value0);
    };
    return RadiusRem2;
  })();
  var RadiusFull = /* @__PURE__ */ (function() {
    function RadiusFull2() {
    }
    ;
    RadiusFull2.value = new RadiusFull2();
    return RadiusFull2;
  })();
  var RadiusNone = /* @__PURE__ */ (function() {
    function RadiusNone2() {
    }
    ;
    RadiusNone2.value = new RadiusNone2();
    return RadiusNone2;
  })();

  // output/Hydrogen.GPU.DrawCommand.Types/index.js
  var MoveTo = /* @__PURE__ */ (function() {
    function MoveTo2(value0) {
      this.value0 = value0;
    }
    ;
    MoveTo2.create = function(value0) {
      return new MoveTo2(value0);
    };
    return MoveTo2;
  })();
  var LineTo = /* @__PURE__ */ (function() {
    function LineTo2(value0) {
      this.value0 = value0;
    }
    ;
    LineTo2.create = function(value0) {
      return new LineTo2(value0);
    };
    return LineTo2;
  })();
  var QuadraticTo = /* @__PURE__ */ (function() {
    function QuadraticTo2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    QuadraticTo2.create = function(value0) {
      return function(value1) {
        return new QuadraticTo2(value0, value1);
      };
    };
    return QuadraticTo2;
  })();
  var CubicTo = /* @__PURE__ */ (function() {
    function CubicTo2(value0, value1, value2) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value2;
    }
    ;
    CubicTo2.create = function(value0) {
      return function(value1) {
        return function(value2) {
          return new CubicTo2(value0, value1, value2);
        };
      };
    };
    return CubicTo2;
  })();
  var ClosePath = /* @__PURE__ */ (function() {
    function ClosePath2() {
    }
    ;
    ClosePath2.value = new ClosePath2();
    return ClosePath2;
  })();
  var ClipRect = /* @__PURE__ */ (function() {
    function ClipRect2(value0) {
      this.value0 = value0;
    }
    ;
    ClipRect2.create = function(value0) {
      return new ClipRect2(value0);
    };
    return ClipRect2;
  })();
  var ClipPath = /* @__PURE__ */ (function() {
    function ClipPath2(value0) {
      this.value0 = value0;
    }
    ;
    ClipPath2.create = function(value0) {
      return new ClipPath2(value0);
    };
    return ClipPath2;
  })();
  var DrawRect = /* @__PURE__ */ (function() {
    function DrawRect2(value0) {
      this.value0 = value0;
    }
    ;
    DrawRect2.create = function(value0) {
      return new DrawRect2(value0);
    };
    return DrawRect2;
  })();
  var DrawQuad = /* @__PURE__ */ (function() {
    function DrawQuad2(value0) {
      this.value0 = value0;
    }
    ;
    DrawQuad2.create = function(value0) {
      return new DrawQuad2(value0);
    };
    return DrawQuad2;
  })();
  var DrawGlyph = /* @__PURE__ */ (function() {
    function DrawGlyph2(value0) {
      this.value0 = value0;
    }
    ;
    DrawGlyph2.create = function(value0) {
      return new DrawGlyph2(value0);
    };
    return DrawGlyph2;
  })();
  var DrawPath = /* @__PURE__ */ (function() {
    function DrawPath2(value0) {
      this.value0 = value0;
    }
    ;
    DrawPath2.create = function(value0) {
      return new DrawPath2(value0);
    };
    return DrawPath2;
  })();
  var DrawParticle = /* @__PURE__ */ (function() {
    function DrawParticle2(value0) {
      this.value0 = value0;
    }
    ;
    DrawParticle2.create = function(value0) {
      return new DrawParticle2(value0);
    };
    return DrawParticle2;
  })();
  var DrawImage = /* @__PURE__ */ (function() {
    function DrawImage2(value0) {
      this.value0 = value0;
    }
    ;
    DrawImage2.create = function(value0) {
      return new DrawImage2(value0);
    };
    return DrawImage2;
  })();
  var DrawVideo = /* @__PURE__ */ (function() {
    function DrawVideo2(value0) {
      this.value0 = value0;
    }
    ;
    DrawVideo2.create = function(value0) {
      return new DrawVideo2(value0);
    };
    return DrawVideo2;
  })();
  var Draw3D = /* @__PURE__ */ (function() {
    function Draw3D2(value0) {
      this.value0 = value0;
    }
    ;
    Draw3D2.create = function(value0) {
      return new Draw3D2(value0);
    };
    return Draw3D2;
  })();
  var PushClip = /* @__PURE__ */ (function() {
    function PushClip2(value0) {
      this.value0 = value0;
    }
    ;
    PushClip2.create = function(value0) {
      return new PushClip2(value0);
    };
    return PushClip2;
  })();
  var PopClip = /* @__PURE__ */ (function() {
    function PopClip2() {
    }
    ;
    PopClip2.value = new PopClip2();
    return PopClip2;
  })();
  var Noop = /* @__PURE__ */ (function() {
    function Noop2() {
    }
    ;
    Noop2.value = new Noop2();
    return Noop2;
  })();
  var DrawGlyphPath = /* @__PURE__ */ (function() {
    function DrawGlyphPath2(value0) {
      this.value0 = value0;
    }
    ;
    DrawGlyphPath2.create = function(value0) {
      return new DrawGlyphPath2(value0);
    };
    return DrawGlyphPath2;
  })();
  var DrawGlyphInstance = /* @__PURE__ */ (function() {
    function DrawGlyphInstance2(value0) {
      this.value0 = value0;
    }
    ;
    DrawGlyphInstance2.create = function(value0) {
      return new DrawGlyphInstance2(value0);
    };
    return DrawGlyphInstance2;
  })();
  var DrawWord = /* @__PURE__ */ (function() {
    function DrawWord2(value0) {
      this.value0 = value0;
    }
    ;
    DrawWord2.create = function(value0) {
      return new DrawWord2(value0);
    };
    return DrawWord2;
  })();
  var DefinePathData = /* @__PURE__ */ (function() {
    function DefinePathData2(value0) {
      this.value0 = value0;
    }
    ;
    DefinePathData2.create = function(value0) {
      return new DefinePathData2(value0);
    };
    return DefinePathData2;
  })();
  var UpdateAnimationState = /* @__PURE__ */ (function() {
    function UpdateAnimationState2(value0) {
      this.value0 = value0;
    }
    ;
    UpdateAnimationState2.create = function(value0) {
      return new UpdateAnimationState2(value0);
    };
    return UpdateAnimationState2;
  })();

  // output/Hydrogen.Schema.Color.Channel/index.js
  var unwrap2 = function(v) {
    return v;
  };
  var channel = function(n) {
    return clampInt(0)(255)(n);
  };

  // output/Hydrogen.Schema.Color.Opacity/index.js
  var toUnitInterval = function(v) {
    return toNumber(v) / 100;
  };
  var opacity = function(n) {
    return clampInt(0)(100)(n);
  };

  // output/Hydrogen.Schema.Color.RGB/index.js
  var show4 = /* @__PURE__ */ show(showInt);
  var show1 = /* @__PURE__ */ show(showNumber);
  var rgbaToLegacyCss = function(v) {
    var a$prime = toUnitInterval(v.alpha);
    return "rgba(" + (show4(unwrap2(v.red)) + (", " + (show4(unwrap2(v.green)) + (", " + (show4(unwrap2(v.blue)) + (", " + (show1(a$prime) + ")")))))));
  };
  var rgba = function(r) {
    return function(g) {
      return function(b) {
        return function(a) {
          return {
            red: channel(r),
            green: channel(g),
            blue: channel(b),
            alpha: opacity(a)
          };
        };
      };
    };
  };

  // output/Hydrogen.Target.GPU/foreign.js
  var getCanvas2DContextImpl = (canvasId) => () => {
    if (typeof document === "undefined") {
      return { Left: "document not available (not in browser)" };
    }
    const canvas = document.getElementById(canvasId);
    if (!canvas) {
      return { Left: `Canvas element not found: ${canvasId}` };
    }
    const ctx = canvas.getContext("2d");
    if (!ctx) {
      return { Left: `Could not get 2D context from: ${canvasId}` };
    }
    ctx._canvas = canvas;
    return { Right: ctx };
  };

  // output/Hydrogen.GPU.WebGPU.Device/foreign.js
  var isWebGPUSupportedImpl = () => typeof navigator !== "undefined" && navigator.gpu !== void 0;

  // output/Effect.Aff/foreign.js
  var Aff = (function() {
    var EMPTY = {};
    var PURE = "Pure";
    var THROW = "Throw";
    var CATCH = "Catch";
    var SYNC = "Sync";
    var ASYNC = "Async";
    var BIND = "Bind";
    var BRACKET = "Bracket";
    var FORK = "Fork";
    var SEQ = "Sequential";
    var MAP = "Map";
    var APPLY = "Apply";
    var ALT = "Alt";
    var CONS = "Cons";
    var RESUME = "Resume";
    var RELEASE = "Release";
    var FINALIZER = "Finalizer";
    var FINALIZED = "Finalized";
    var FORKED = "Forked";
    var FIBER = "Fiber";
    var THUNK = "Thunk";
    function Aff2(tag, _1, _2, _3) {
      this.tag = tag;
      this._1 = _1;
      this._2 = _2;
      this._3 = _3;
    }
    function AffCtr(tag) {
      var fn = function(_1, _2, _3) {
        return new Aff2(tag, _1, _2, _3);
      };
      fn.tag = tag;
      return fn;
    }
    function nonCanceler2(error3) {
      return new Aff2(PURE, void 0);
    }
    function runEff(eff) {
      try {
        eff();
      } catch (error3) {
        setTimeout(function() {
          throw error3;
        }, 0);
      }
    }
    function runSync(left, right, eff) {
      try {
        return right(eff());
      } catch (error3) {
        return left(error3);
      }
    }
    function runAsync(left, eff, k) {
      try {
        return eff(k)();
      } catch (error3) {
        k(left(error3))();
        return nonCanceler2;
      }
    }
    var Scheduler = (function() {
      var limit = 1024;
      var size2 = 0;
      var ix = 0;
      var queue = new Array(limit);
      var draining = false;
      function drain() {
        var thunk;
        draining = true;
        while (size2 !== 0) {
          size2--;
          thunk = queue[ix];
          queue[ix] = void 0;
          ix = (ix + 1) % limit;
          thunk();
        }
        draining = false;
      }
      return {
        isDraining: function() {
          return draining;
        },
        enqueue: function(cb) {
          var i, tmp;
          if (size2 === limit) {
            tmp = draining;
            drain();
            draining = tmp;
          }
          queue[(ix + size2) % limit] = cb;
          size2++;
          if (!draining) {
            drain();
          }
        }
      };
    })();
    function Supervisor(util) {
      var fibers = {};
      var fiberId = 0;
      var count = 0;
      return {
        register: function(fiber) {
          var fid = fiberId++;
          fiber.onComplete({
            rethrow: true,
            handler: function(result) {
              return function() {
                count--;
                delete fibers[fid];
              };
            }
          })();
          fibers[fid] = fiber;
          count++;
        },
        isEmpty: function() {
          return count === 0;
        },
        killAll: function(killError, cb) {
          return function() {
            if (count === 0) {
              return cb();
            }
            var killCount = 0;
            var kills = {};
            function kill(fid) {
              kills[fid] = fibers[fid].kill(killError, function(result) {
                return function() {
                  delete kills[fid];
                  killCount--;
                  if (util.isLeft(result) && util.fromLeft(result)) {
                    setTimeout(function() {
                      throw util.fromLeft(result);
                    }, 0);
                  }
                  if (killCount === 0) {
                    cb();
                  }
                };
              })();
            }
            for (var k in fibers) {
              if (fibers.hasOwnProperty(k)) {
                killCount++;
                kill(k);
              }
            }
            fibers = {};
            fiberId = 0;
            count = 0;
            return function(error3) {
              return new Aff2(SYNC, function() {
                for (var k2 in kills) {
                  if (kills.hasOwnProperty(k2)) {
                    kills[k2]();
                  }
                }
              });
            };
          };
        }
      };
    }
    var SUSPENDED = 0;
    var CONTINUE = 1;
    var STEP_BIND = 2;
    var STEP_RESULT = 3;
    var PENDING = 4;
    var RETURN = 5;
    var COMPLETED = 6;
    function Fiber(util, supervisor, aff) {
      var runTick = 0;
      var status = SUSPENDED;
      var step = aff;
      var fail = null;
      var interrupt = null;
      var bhead = null;
      var btail = null;
      var attempts = null;
      var bracketCount = 0;
      var joinId = 0;
      var joins = null;
      var rethrow = true;
      function run3(localRunTick) {
        var tmp, result, attempt;
        while (true) {
          tmp = null;
          result = null;
          attempt = null;
          switch (status) {
            case STEP_BIND:
              status = CONTINUE;
              try {
                step = bhead(step);
                if (btail === null) {
                  bhead = null;
                } else {
                  bhead = btail._1;
                  btail = btail._2;
                }
              } catch (e) {
                status = RETURN;
                fail = util.left(e);
                step = null;
              }
              break;
            case STEP_RESULT:
              if (util.isLeft(step)) {
                status = RETURN;
                fail = step;
                step = null;
              } else if (bhead === null) {
                status = RETURN;
              } else {
                status = STEP_BIND;
                step = util.fromRight(step);
              }
              break;
            case CONTINUE:
              switch (step.tag) {
                case BIND:
                  if (bhead) {
                    btail = new Aff2(CONS, bhead, btail);
                  }
                  bhead = step._2;
                  status = CONTINUE;
                  step = step._1;
                  break;
                case PURE:
                  if (bhead === null) {
                    status = RETURN;
                    step = util.right(step._1);
                  } else {
                    status = STEP_BIND;
                    step = step._1;
                  }
                  break;
                case SYNC:
                  status = STEP_RESULT;
                  step = runSync(util.left, util.right, step._1);
                  break;
                case ASYNC:
                  status = PENDING;
                  step = runAsync(util.left, step._1, function(result2) {
                    return function() {
                      if (runTick !== localRunTick) {
                        return;
                      }
                      runTick++;
                      Scheduler.enqueue(function() {
                        if (runTick !== localRunTick + 1) {
                          return;
                        }
                        status = STEP_RESULT;
                        step = result2;
                        run3(runTick);
                      });
                    };
                  });
                  return;
                case THROW:
                  status = RETURN;
                  fail = util.left(step._1);
                  step = null;
                  break;
                // Enqueue the Catch so that we can call the error handler later on
                // in case of an exception.
                case CATCH:
                  if (bhead === null) {
                    attempts = new Aff2(CONS, step, attempts, interrupt);
                  } else {
                    attempts = new Aff2(CONS, step, new Aff2(CONS, new Aff2(RESUME, bhead, btail), attempts, interrupt), interrupt);
                  }
                  bhead = null;
                  btail = null;
                  status = CONTINUE;
                  step = step._1;
                  break;
                // Enqueue the Bracket so that we can call the appropriate handlers
                // after resource acquisition.
                case BRACKET:
                  bracketCount++;
                  if (bhead === null) {
                    attempts = new Aff2(CONS, step, attempts, interrupt);
                  } else {
                    attempts = new Aff2(CONS, step, new Aff2(CONS, new Aff2(RESUME, bhead, btail), attempts, interrupt), interrupt);
                  }
                  bhead = null;
                  btail = null;
                  status = CONTINUE;
                  step = step._1;
                  break;
                case FORK:
                  status = STEP_RESULT;
                  tmp = Fiber(util, supervisor, step._2);
                  if (supervisor) {
                    supervisor.register(tmp);
                  }
                  if (step._1) {
                    tmp.run();
                  }
                  step = util.right(tmp);
                  break;
                case SEQ:
                  status = CONTINUE;
                  step = sequential2(util, supervisor, step._1);
                  break;
              }
              break;
            case RETURN:
              bhead = null;
              btail = null;
              if (attempts === null) {
                status = COMPLETED;
                step = interrupt || fail || step;
              } else {
                tmp = attempts._3;
                attempt = attempts._1;
                attempts = attempts._2;
                switch (attempt.tag) {
                  // We cannot recover from an unmasked interrupt. Otherwise we should
                  // continue stepping, or run the exception handler if an exception
                  // was raised.
                  case CATCH:
                    if (interrupt && interrupt !== tmp && bracketCount === 0) {
                      status = RETURN;
                    } else if (fail) {
                      status = CONTINUE;
                      step = attempt._2(util.fromLeft(fail));
                      fail = null;
                    }
                    break;
                  // We cannot resume from an unmasked interrupt or exception.
                  case RESUME:
                    if (interrupt && interrupt !== tmp && bracketCount === 0 || fail) {
                      status = RETURN;
                    } else {
                      bhead = attempt._1;
                      btail = attempt._2;
                      status = STEP_BIND;
                      step = util.fromRight(step);
                    }
                    break;
                  // If we have a bracket, we should enqueue the handlers,
                  // and continue with the success branch only if the fiber has
                  // not been interrupted. If the bracket acquisition failed, we
                  // should not run either.
                  case BRACKET:
                    bracketCount--;
                    if (fail === null) {
                      result = util.fromRight(step);
                      attempts = new Aff2(CONS, new Aff2(RELEASE, attempt._2, result), attempts, tmp);
                      if (interrupt === tmp || bracketCount > 0) {
                        status = CONTINUE;
                        step = attempt._3(result);
                      }
                    }
                    break;
                  // Enqueue the appropriate handler. We increase the bracket count
                  // because it should not be cancelled.
                  case RELEASE:
                    attempts = new Aff2(CONS, new Aff2(FINALIZED, step, fail), attempts, interrupt);
                    status = CONTINUE;
                    if (interrupt && interrupt !== tmp && bracketCount === 0) {
                      step = attempt._1.killed(util.fromLeft(interrupt))(attempt._2);
                    } else if (fail) {
                      step = attempt._1.failed(util.fromLeft(fail))(attempt._2);
                    } else {
                      step = attempt._1.completed(util.fromRight(step))(attempt._2);
                    }
                    fail = null;
                    bracketCount++;
                    break;
                  case FINALIZER:
                    bracketCount++;
                    attempts = new Aff2(CONS, new Aff2(FINALIZED, step, fail), attempts, interrupt);
                    status = CONTINUE;
                    step = attempt._1;
                    break;
                  case FINALIZED:
                    bracketCount--;
                    status = RETURN;
                    step = attempt._1;
                    fail = attempt._2;
                    break;
                }
              }
              break;
            case COMPLETED:
              for (var k in joins) {
                if (joins.hasOwnProperty(k)) {
                  rethrow = rethrow && joins[k].rethrow;
                  runEff(joins[k].handler(step));
                }
              }
              joins = null;
              if (interrupt && fail) {
                setTimeout(function() {
                  throw util.fromLeft(fail);
                }, 0);
              } else if (util.isLeft(step) && rethrow) {
                setTimeout(function() {
                  if (rethrow) {
                    throw util.fromLeft(step);
                  }
                }, 0);
              }
              return;
            case SUSPENDED:
              status = CONTINUE;
              break;
            case PENDING:
              return;
          }
        }
      }
      function onComplete(join3) {
        return function() {
          if (status === COMPLETED) {
            rethrow = rethrow && join3.rethrow;
            join3.handler(step)();
            return function() {
            };
          }
          var jid = joinId++;
          joins = joins || {};
          joins[jid] = join3;
          return function() {
            if (joins !== null) {
              delete joins[jid];
            }
          };
        };
      }
      function kill(error3, cb) {
        return function() {
          if (status === COMPLETED) {
            cb(util.right(void 0))();
            return function() {
            };
          }
          var canceler = onComplete({
            rethrow: false,
            handler: function() {
              return cb(util.right(void 0));
            }
          })();
          switch (status) {
            case SUSPENDED:
              interrupt = util.left(error3);
              status = COMPLETED;
              step = interrupt;
              run3(runTick);
              break;
            case PENDING:
              if (interrupt === null) {
                interrupt = util.left(error3);
              }
              if (bracketCount === 0) {
                if (status === PENDING) {
                  attempts = new Aff2(CONS, new Aff2(FINALIZER, step(error3)), attempts, interrupt);
                }
                status = RETURN;
                step = null;
                fail = null;
                run3(++runTick);
              }
              break;
            default:
              if (interrupt === null) {
                interrupt = util.left(error3);
              }
              if (bracketCount === 0) {
                status = RETURN;
                step = null;
                fail = null;
              }
          }
          return canceler;
        };
      }
      function join2(cb) {
        return function() {
          var canceler = onComplete({
            rethrow: false,
            handler: cb
          })();
          if (status === SUSPENDED) {
            run3(runTick);
          }
          return canceler;
        };
      }
      return {
        kill,
        join: join2,
        onComplete,
        isSuspended: function() {
          return status === SUSPENDED;
        },
        run: function() {
          if (status === SUSPENDED) {
            if (!Scheduler.isDraining()) {
              Scheduler.enqueue(function() {
                run3(runTick);
              });
            } else {
              run3(runTick);
            }
          }
        }
      };
    }
    function runPar(util, supervisor, par, cb) {
      var fiberId = 0;
      var fibers = {};
      var killId = 0;
      var kills = {};
      var early = new Error("[ParAff] Early exit");
      var interrupt = null;
      var root = EMPTY;
      function kill(error3, par2, cb2) {
        var step = par2;
        var head2 = null;
        var tail = null;
        var count = 0;
        var kills2 = {};
        var tmp, kid;
        loop: while (true) {
          tmp = null;
          switch (step.tag) {
            case FORKED:
              if (step._3 === EMPTY) {
                tmp = fibers[step._1];
                kills2[count++] = tmp.kill(error3, function(result) {
                  return function() {
                    count--;
                    if (count === 0) {
                      cb2(result)();
                    }
                  };
                });
              }
              if (head2 === null) {
                break loop;
              }
              step = head2._2;
              if (tail === null) {
                head2 = null;
              } else {
                head2 = tail._1;
                tail = tail._2;
              }
              break;
            case MAP:
              step = step._2;
              break;
            case APPLY:
            case ALT:
              if (head2) {
                tail = new Aff2(CONS, head2, tail);
              }
              head2 = step;
              step = step._1;
              break;
          }
        }
        if (count === 0) {
          cb2(util.right(void 0))();
        } else {
          kid = 0;
          tmp = count;
          for (; kid < tmp; kid++) {
            kills2[kid] = kills2[kid]();
          }
        }
        return kills2;
      }
      function join2(result, head2, tail) {
        var fail, step, lhs, rhs, tmp, kid;
        if (util.isLeft(result)) {
          fail = result;
          step = null;
        } else {
          step = result;
          fail = null;
        }
        loop: while (true) {
          lhs = null;
          rhs = null;
          tmp = null;
          kid = null;
          if (interrupt !== null) {
            return;
          }
          if (head2 === null) {
            cb(fail || step)();
            return;
          }
          if (head2._3 !== EMPTY) {
            return;
          }
          switch (head2.tag) {
            case MAP:
              if (fail === null) {
                head2._3 = util.right(head2._1(util.fromRight(step)));
                step = head2._3;
              } else {
                head2._3 = fail;
              }
              break;
            case APPLY:
              lhs = head2._1._3;
              rhs = head2._2._3;
              if (fail) {
                head2._3 = fail;
                tmp = true;
                kid = killId++;
                kills[kid] = kill(early, fail === lhs ? head2._2 : head2._1, function() {
                  return function() {
                    delete kills[kid];
                    if (tmp) {
                      tmp = false;
                    } else if (tail === null) {
                      join2(fail, null, null);
                    } else {
                      join2(fail, tail._1, tail._2);
                    }
                  };
                });
                if (tmp) {
                  tmp = false;
                  return;
                }
              } else if (lhs === EMPTY || rhs === EMPTY) {
                return;
              } else {
                step = util.right(util.fromRight(lhs)(util.fromRight(rhs)));
                head2._3 = step;
              }
              break;
            case ALT:
              lhs = head2._1._3;
              rhs = head2._2._3;
              if (lhs === EMPTY && util.isLeft(rhs) || rhs === EMPTY && util.isLeft(lhs)) {
                return;
              }
              if (lhs !== EMPTY && util.isLeft(lhs) && rhs !== EMPTY && util.isLeft(rhs)) {
                fail = step === lhs ? rhs : lhs;
                step = null;
                head2._3 = fail;
              } else {
                head2._3 = step;
                tmp = true;
                kid = killId++;
                kills[kid] = kill(early, step === lhs ? head2._2 : head2._1, function() {
                  return function() {
                    delete kills[kid];
                    if (tmp) {
                      tmp = false;
                    } else if (tail === null) {
                      join2(step, null, null);
                    } else {
                      join2(step, tail._1, tail._2);
                    }
                  };
                });
                if (tmp) {
                  tmp = false;
                  return;
                }
              }
              break;
          }
          if (tail === null) {
            head2 = null;
          } else {
            head2 = tail._1;
            tail = tail._2;
          }
        }
      }
      function resolve(fiber) {
        return function(result) {
          return function() {
            delete fibers[fiber._1];
            fiber._3 = result;
            join2(result, fiber._2._1, fiber._2._2);
          };
        };
      }
      function run3() {
        var status = CONTINUE;
        var step = par;
        var head2 = null;
        var tail = null;
        var tmp, fid;
        loop: while (true) {
          tmp = null;
          fid = null;
          switch (status) {
            case CONTINUE:
              switch (step.tag) {
                case MAP:
                  if (head2) {
                    tail = new Aff2(CONS, head2, tail);
                  }
                  head2 = new Aff2(MAP, step._1, EMPTY, EMPTY);
                  step = step._2;
                  break;
                case APPLY:
                  if (head2) {
                    tail = new Aff2(CONS, head2, tail);
                  }
                  head2 = new Aff2(APPLY, EMPTY, step._2, EMPTY);
                  step = step._1;
                  break;
                case ALT:
                  if (head2) {
                    tail = new Aff2(CONS, head2, tail);
                  }
                  head2 = new Aff2(ALT, EMPTY, step._2, EMPTY);
                  step = step._1;
                  break;
                default:
                  fid = fiberId++;
                  status = RETURN;
                  tmp = step;
                  step = new Aff2(FORKED, fid, new Aff2(CONS, head2, tail), EMPTY);
                  tmp = Fiber(util, supervisor, tmp);
                  tmp.onComplete({
                    rethrow: false,
                    handler: resolve(step)
                  })();
                  fibers[fid] = tmp;
                  if (supervisor) {
                    supervisor.register(tmp);
                  }
              }
              break;
            case RETURN:
              if (head2 === null) {
                break loop;
              }
              if (head2._1 === EMPTY) {
                head2._1 = step;
                status = CONTINUE;
                step = head2._2;
                head2._2 = EMPTY;
              } else {
                head2._2 = step;
                step = head2;
                if (tail === null) {
                  head2 = null;
                } else {
                  head2 = tail._1;
                  tail = tail._2;
                }
              }
          }
        }
        root = step;
        for (fid = 0; fid < fiberId; fid++) {
          fibers[fid].run();
        }
      }
      function cancel(error3, cb2) {
        interrupt = util.left(error3);
        var innerKills;
        for (var kid in kills) {
          if (kills.hasOwnProperty(kid)) {
            innerKills = kills[kid];
            for (kid in innerKills) {
              if (innerKills.hasOwnProperty(kid)) {
                innerKills[kid]();
              }
            }
          }
        }
        kills = null;
        var newKills = kill(error3, root, cb2);
        return function(killError) {
          return new Aff2(ASYNC, function(killCb) {
            return function() {
              for (var kid2 in newKills) {
                if (newKills.hasOwnProperty(kid2)) {
                  newKills[kid2]();
                }
              }
              return nonCanceler2;
            };
          });
        };
      }
      run3();
      return function(killError) {
        return new Aff2(ASYNC, function(killCb) {
          return function() {
            return cancel(killError, killCb);
          };
        });
      };
    }
    function sequential2(util, supervisor, par) {
      return new Aff2(ASYNC, function(cb) {
        return function() {
          return runPar(util, supervisor, par, cb);
        };
      });
    }
    Aff2.EMPTY = EMPTY;
    Aff2.Pure = AffCtr(PURE);
    Aff2.Throw = AffCtr(THROW);
    Aff2.Catch = AffCtr(CATCH);
    Aff2.Sync = AffCtr(SYNC);
    Aff2.Async = AffCtr(ASYNC);
    Aff2.Bind = AffCtr(BIND);
    Aff2.Bracket = AffCtr(BRACKET);
    Aff2.Fork = AffCtr(FORK);
    Aff2.Seq = AffCtr(SEQ);
    Aff2.ParMap = AffCtr(MAP);
    Aff2.ParApply = AffCtr(APPLY);
    Aff2.ParAlt = AffCtr(ALT);
    Aff2.Fiber = Fiber;
    Aff2.Supervisor = Supervisor;
    Aff2.Scheduler = Scheduler;
    Aff2.nonCanceler = nonCanceler2;
    return Aff2;
  })();
  var _pure = Aff.Pure;
  var _throwError = Aff.Throw;
  var _liftEffect = Aff.Sync;
  var makeAff = Aff.Async;
  var _sequential = Aff.Seq;

  // output/Hydrogen.GPU.WebGPU.Device/index.js
  var isWebGPUSupported = isWebGPUSupportedImpl;

  // output/Hydrogen.Target.Canvas2D/foreign.js
  var isCanvas2DSupportedImpl = () => {
    if (typeof document === "undefined") return false;
    const canvas = document.createElement("canvas");
    return !!(canvas && canvas.getContext && canvas.getContext("2d"));
  };
  var saveImpl = (ctx) => () => ctx.save();
  var restoreImpl = (ctx) => () => ctx.restore();
  var renderRectImpl = (ctx) => (x) => (y) => (w) => (h) => (fill) => (tl) => (tr) => (br) => (bl) => () => {
    ctx.fillStyle = fill;
    if (tl > 0 || tr > 0 || br > 0 || bl > 0) {
      ctx.beginPath();
      ctx.moveTo(x + tl, y);
      ctx.lineTo(x + w - tr, y);
      if (tr > 0) ctx.arcTo(x + w, y, x + w, y + tr, tr);
      ctx.lineTo(x + w, y + h - br);
      if (br > 0) ctx.arcTo(x + w, y + h, x + w - br, y + h, br);
      ctx.lineTo(x + bl, y + h);
      if (bl > 0) ctx.arcTo(x, y + h, x, y + h - bl, bl);
      ctx.lineTo(x, y + tl);
      if (tl > 0) ctx.arcTo(x, y, x + tl, y, tl);
      ctx.closePath();
      ctx.fill();
    } else {
      ctx.fillRect(x, y, w, h);
    }
  };
  var renderQuadImpl = (ctx) => (x0) => (y0) => (x1) => (y1) => (x2) => (y2) => (x3) => (y3) => (fill) => () => {
    ctx.fillStyle = fill;
    ctx.beginPath();
    ctx.moveTo(x0, y0);
    ctx.lineTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.lineTo(x3, y3);
    ctx.closePath();
    ctx.fill();
  };
  var renderGlyphImpl = (ctx) => (x) => (y) => (glyphIndex) => (fontSize) => (color) => () => {
    ctx.fillStyle = color;
    ctx.font = `${fontSize}px sans-serif`;
    ctx.textBaseline = "top";
    const char2 = String.fromCharCode(glyphIndex);
    ctx.fillText(char2, x, y);
  };
  var renderParticleImpl = (ctx) => (x) => (y) => (size2) => (color) => () => {
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(x, y, size2, 0, Math.PI * 2);
    ctx.fill();
  };
  var imageCache = /* @__PURE__ */ new Map();
  var renderImageImpl = (ctx) => (url) => (x) => (y) => (w) => (h) => () => {
    let img = imageCache.get(url);
    if (!img) {
      img = new Image();
      img.crossOrigin = "anonymous";
      img.src = url;
      imageCache.set(url, img);
    }
    if (img.complete && img.naturalWidth > 0) {
      ctx.drawImage(img, x, y, w, h);
    }
  };
  var videoCache = /* @__PURE__ */ new Map();
  var renderVideoImpl = (ctx) => (url) => (x) => (y) => (w) => (h) => () => {
    let video = videoCache.get(url);
    if (!video) {
      video = document.createElement("video");
      video.crossOrigin = "anonymous";
      video.src = url;
      video.muted = true;
      videoCache.set(url, video);
    }
    if (video.readyState >= 2) {
      ctx.drawImage(video, x, y, w, h);
    }
  };
  var beginPathImpl = (ctx) => () => ctx.beginPath();
  var moveToImpl = (ctx) => (x) => (y) => () => ctx.moveTo(x, y);
  var lineToImpl = (ctx) => (x) => (y) => () => ctx.lineTo(x, y);
  var quadraticCurveToImpl = (ctx) => (cpx) => (cpy) => (x) => (y) => () => ctx.quadraticCurveTo(cpx, cpy, x, y);
  var bezierCurveToImpl = (ctx) => (cp1x) => (cp1y) => (cp2x) => (cp2y) => (x) => (y) => () => ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
  var closePathImpl = (ctx) => () => ctx.closePath();
  var fillPathImpl = (ctx) => (color) => () => {
    ctx.fillStyle = color;
    ctx.fill();
  };
  var strokePathImpl = (ctx) => (color) => (width) => () => {
    ctx.strokeStyle = color;
    ctx.lineWidth = width;
    ctx.stroke();
  };
  var pushClipRectImpl = (ctx) => (x) => (y) => (w) => (h) => (tl) => (tr) => (br) => (bl) => () => {
    ctx.save();
    ctx.beginPath();
    if (tl > 0 || tr > 0 || br > 0 || bl > 0) {
      ctx.moveTo(x + tl, y);
      ctx.lineTo(x + w - tr, y);
      if (tr > 0) ctx.arcTo(x + w, y, x + w, y + tr, tr);
      ctx.lineTo(x + w, y + h - br);
      if (br > 0) ctx.arcTo(x + w, y + h, x + w - br, y + h, br);
      ctx.lineTo(x + bl, y + h);
      if (bl > 0) ctx.arcTo(x, y + h, x, y + h - bl, bl);
      ctx.lineTo(x, y + tl);
      if (tl > 0) ctx.arcTo(x, y, x + tl, y, tl);
    } else {
      ctx.rect(x, y, w, h);
    }
    ctx.closePath();
    ctx.clip();
  };
  var pushClipPathImpl = (ctx) => () => {
    ctx.save();
    ctx.clip();
  };

  // output/Hydrogen.Target.Canvas2D/index.js
  var for_2 = /* @__PURE__ */ for_(applicativeEffect)(foldableArray);
  var pure2 = /* @__PURE__ */ pure(applicativeEffect);
  var unwrapPixel2 = unwrapPixel;
  var rgbaToCSS = rgbaToLegacyCss;
  var renderWordFallback = function(ctx) {
    return function(params) {
      return renderParticleImpl(ctx)(unwrapPixel2(params.origin.x))(unwrapPixel2(params.origin.y))(4)(rgbaToCSS(params.color));
    };
  };
  var renderVideo = function(ctx) {
    return function(params) {
      return renderVideoImpl(ctx)(params.url)(unwrapScreenX(params.x))(unwrapScreenY(params.y))(unwrapPixelWidth(params.width))(unwrapPixelHeight(params.height));
    };
  };
  var renderQuad = function(ctx) {
    return function(params) {
      var fill = rgbaToCSS(params.fill);
      return renderQuadImpl(ctx)(unwrapPixel2(params.v0.x))(unwrapPixel2(params.v0.y))(unwrapPixel2(params.v1.x))(unwrapPixel2(params.v1.y))(unwrapPixel2(params.v2.x))(unwrapPixel2(params.v2.y))(unwrapPixel2(params.v3.x))(unwrapPixel2(params.v3.y))(fill);
    };
  };
  var renderPlaceholder3D = function(ctx) {
    return function(params) {
      return renderRectImpl(ctx)(unwrapScreenX(params.x))(unwrapScreenY(params.y))(unwrapPixelWidth(params.width))(unwrapPixelHeight(params.height))("rgba(100,100,100,0.5)")(0)(0)(0)(0);
    };
  };
  var renderPath = function(ctx) {
    return function(params) {
      return function __do3() {
        beginPathImpl(ctx)();
        for_2(params.segments)(function(seg) {
          if (seg instanceof MoveTo) {
            return moveToImpl(ctx)(unwrapPixel2(seg.value0.x))(unwrapPixel2(seg.value0.y));
          }
          ;
          if (seg instanceof LineTo) {
            return lineToImpl(ctx)(unwrapPixel2(seg.value0.x))(unwrapPixel2(seg.value0.y));
          }
          ;
          if (seg instanceof QuadraticTo) {
            return quadraticCurveToImpl(ctx)(unwrapPixel2(seg.value0.x))(unwrapPixel2(seg.value0.y))(unwrapPixel2(seg.value1.x))(unwrapPixel2(seg.value1.y));
          }
          ;
          if (seg instanceof CubicTo) {
            return bezierCurveToImpl(ctx)(unwrapPixel2(seg.value0.x))(unwrapPixel2(seg.value0.y))(unwrapPixel2(seg.value1.x))(unwrapPixel2(seg.value1.y))(unwrapPixel2(seg.value2.x))(unwrapPixel2(seg.value2.y));
          }
          ;
          if (seg instanceof ClosePath) {
            return closePathImpl(ctx);
          }
          ;
          throw new Error("Failed pattern match at Hydrogen.Target.Canvas2D (line 300, column 32 - line 310, column 35): " + [seg.constructor.name]);
        })();
        (function() {
          if (params.fill instanceof Just) {
            return fillPathImpl(ctx)(rgbaToCSS(params.fill.value0))();
          }
          ;
          if (params.fill instanceof Nothing) {
            return unit;
          }
          ;
          throw new Error("Failed pattern match at Hydrogen.Target.Canvas2D (line 312, column 3 - line 314, column 25): " + [params.fill.constructor.name]);
        })();
        if (params.stroke instanceof Just) {
          return strokePathImpl(ctx)(rgbaToCSS(params.stroke.value0))(unwrapPixel2(params.strokeWidth))();
        }
        ;
        if (params.stroke instanceof Nothing) {
          return unit;
        }
        ;
        throw new Error("Failed pattern match at Hydrogen.Target.Canvas2D (line 316, column 3 - line 318, column 25): " + [params.stroke.constructor.name]);
      };
    };
  };
  var renderParticle2 = function(ctx) {
    return function(params) {
      return renderParticleImpl(ctx)(unwrapScreenX(params.x))(unwrapScreenY(params.y))(unwrapPixel2(params.size))(rgbaToCSS(params.color));
    };
  };
  var renderImage = function(ctx) {
    return function(params) {
      return renderImageImpl(ctx)(params.url)(unwrapScreenX(params.x))(unwrapScreenY(params.y))(unwrapPixelWidth(params.width))(unwrapPixelHeight(params.height));
    };
  };
  var renderGlyphPathFallback = function(ctx) {
    return function(params) {
      var h = unwrapPixel2(params.bounds.maxY) - unwrapPixel2(params.bounds.minY);
      var w = unwrapPixel2(params.bounds.maxX) - unwrapPixel2(params.bounds.minX);
      return renderRectImpl(ctx)(unwrapPixel2(params.bounds.minX))(unwrapPixel2(params.bounds.minY))(w)(h)("rgba(0,0,0,0.1)")(0)(0)(0)(0);
    };
  };
  var renderGlyphInstanceFallback = function(ctx) {
    return function(params) {
      return renderParticleImpl(ctx)(unwrapPixel2(params.position.x))(unwrapPixel2(params.position.y))(8)(rgbaToCSS(params.color));
    };
  };
  var renderGlyph = function(ctx) {
    return function(params) {
      return renderGlyphImpl(ctx)(unwrapScreenX(params.x))(unwrapScreenY(params.y))(params.glyphIndex)(unwrapPixel2(params.fontSize))(rgbaToCSS(params.color));
    };
  };
  var radiusToPixels = function(r) {
    if (r instanceof RadiusPx) {
      return r.value0;
    }
    ;
    if (r instanceof RadiusPercent) {
      return 0;
    }
    ;
    if (r instanceof RadiusRem) {
      return r.value0 * 16;
    }
    ;
    if (r instanceof RadiusFull) {
      return 9999;
    }
    ;
    if (r instanceof RadiusNone) {
      return 0;
    }
    ;
    throw new Error("Failed pattern match at Hydrogen.Target.Canvas2D (line 478, column 20 - line 483, column 27): " + [r.constructor.name]);
  };
  var renderRect = function(ctx) {
    return function(params) {
      var y = unwrapScreenY(params.y);
      var x = unwrapScreenX(params.x);
      var w = unwrapPixelWidth(params.width);
      var tr = radiusToPixels(params.cornerRadius.topRight);
      var tl = radiusToPixels(params.cornerRadius.topLeft);
      var h = unwrapPixelHeight(params.height);
      var fill = rgbaToCSS(params.fill);
      var br = radiusToPixels(params.cornerRadius.bottomRight);
      var bl = radiusToPixels(params.cornerRadius.bottomLeft);
      return renderRectImpl(ctx)(x)(y)(w)(h)(fill)(tl)(tr)(br)(bl);
    };
  };
  var pushClip = function(ctx) {
    return function(region) {
      if (region instanceof ClipRect) {
        return pushClipRectImpl(ctx)(unwrapPixel2(region.value0.x))(unwrapPixel2(region.value0.y))(unwrapPixel2(region.value0.width))(unwrapPixel2(region.value0.height))(radiusToPixels(region.value0.cornerRadius.topLeft))(radiusToPixels(region.value0.cornerRadius.topRight))(radiusToPixels(region.value0.cornerRadius.bottomRight))(radiusToPixels(region.value0.cornerRadius.bottomLeft));
      }
      ;
      if (region instanceof ClipPath) {
        return function __do3() {
          saveImpl(ctx)();
          beginPathImpl(ctx)();
          for_2(region.value0)(function(seg) {
            if (seg instanceof MoveTo) {
              return moveToImpl(ctx)(unwrapPixel2(seg.value0.x))(unwrapPixel2(seg.value0.y));
            }
            ;
            if (seg instanceof LineTo) {
              return lineToImpl(ctx)(unwrapPixel2(seg.value0.x))(unwrapPixel2(seg.value0.y));
            }
            ;
            if (seg instanceof QuadraticTo) {
              return quadraticCurveToImpl(ctx)(unwrapPixel2(seg.value0.x))(unwrapPixel2(seg.value0.y))(unwrapPixel2(seg.value1.x))(unwrapPixel2(seg.value1.y));
            }
            ;
            if (seg instanceof CubicTo) {
              return bezierCurveToImpl(ctx)(unwrapPixel2(seg.value0.x))(unwrapPixel2(seg.value0.y))(unwrapPixel2(seg.value1.x))(unwrapPixel2(seg.value1.y))(unwrapPixel2(seg.value2.x))(unwrapPixel2(seg.value2.y));
            }
            ;
            if (seg instanceof ClosePath) {
              return closePathImpl(ctx);
            }
            ;
            throw new Error("Failed pattern match at Hydrogen.Target.Canvas2D (line 407, column 27 - line 417, column 37): " + [seg.constructor.name]);
          })();
          return pushClipPathImpl(ctx)();
        };
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Target.Canvas2D (line 397, column 23 - line 418, column 25): " + [region.constructor.name]);
    };
  };
  var popClip = function(ctx) {
    return restoreImpl(ctx);
  };
  var renderCommand = function(ctx) {
    return function(cmd) {
      if (cmd instanceof DrawRect) {
        return renderRect(ctx)(cmd.value0);
      }
      ;
      if (cmd instanceof DrawQuad) {
        return renderQuad(ctx)(cmd.value0);
      }
      ;
      if (cmd instanceof DrawGlyph) {
        return renderGlyph(ctx)(cmd.value0);
      }
      ;
      if (cmd instanceof DrawPath) {
        return renderPath(ctx)(cmd.value0);
      }
      ;
      if (cmd instanceof DrawParticle) {
        return renderParticle2(ctx)(cmd.value0);
      }
      ;
      if (cmd instanceof DrawImage) {
        return renderImage(ctx)(cmd.value0);
      }
      ;
      if (cmd instanceof DrawVideo) {
        return renderVideo(ctx)(cmd.value0);
      }
      ;
      if (cmd instanceof Draw3D) {
        return renderPlaceholder3D(ctx)(cmd.value0);
      }
      ;
      if (cmd instanceof PushClip) {
        return pushClip(ctx)(cmd.value0);
      }
      ;
      if (cmd instanceof PopClip) {
        return popClip(ctx);
      }
      ;
      if (cmd instanceof Noop) {
        return pure2(unit);
      }
      ;
      if (cmd instanceof DrawGlyphPath) {
        return renderGlyphPathFallback(ctx)(cmd.value0);
      }
      ;
      if (cmd instanceof DrawGlyphInstance) {
        return renderGlyphInstanceFallback(ctx)(cmd.value0);
      }
      ;
      if (cmd instanceof DrawWord) {
        return renderWordFallback(ctx)(cmd.value0);
      }
      ;
      if (cmd instanceof DefinePathData) {
        return pure2(unit);
      }
      ;
      if (cmd instanceof UpdateAnimationState) {
        return pure2(unit);
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Target.Canvas2D (line 152, column 25 - line 169, column 38): " + [cmd.constructor.name]);
    };
  };
  var render2 = function(ctx) {
    return function(commands) {
      return for_2(commands)(renderCommand(ctx));
    };
  };
  var isCanvas2DSupported = isCanvas2DSupportedImpl;

  // output/Hydrogen.Target.WebGL/foreign.js
  var RECT_VERTEX_SHADER = `#version 300 es
precision highp float;

// Per-vertex attributes (unit quad)
in vec2 a_position;

// Per-instance attributes
in vec4 a_rect;        // x, y, width, height
in vec4 a_color;       // rgba
in vec4 a_cornerRadius; // tl, tr, br, bl

// Uniforms
uniform vec2 u_resolution;

// Outputs to fragment shader
out vec2 v_localPos;
out vec4 v_color;
out vec4 v_cornerRadius;
out vec2 v_size;

void main() {
    // Transform unit quad to rect position
    vec2 pos = a_rect.xy + a_position * a_rect.zw;
    
    // Convert to clip space (-1 to 1)
    vec2 clipPos = (pos / u_resolution) * 2.0 - 1.0;
    clipPos.y = -clipPos.y; // Flip Y for canvas coords
    
    gl_Position = vec4(clipPos, 0.0, 1.0);
    
    // Pass to fragment shader
    v_localPos = a_position * a_rect.zw; // Local position within rect
    v_color = a_color;
    v_cornerRadius = a_cornerRadius;
    v_size = a_rect.zw;
}
`;
  var RECT_FRAGMENT_SHADER = `#version 300 es
precision highp float;

in vec2 v_localPos;
in vec4 v_color;
in vec4 v_cornerRadius;
in vec2 v_size;

out vec4 fragColor;

// Signed distance to rounded rectangle
float sdRoundedBox(vec2 p, vec2 b, vec4 r) {
    r.xy = (p.x > 0.0) ? r.xy : r.zw;
    r.x  = (p.y > 0.0) ? r.x  : r.y;
    vec2 q = abs(p) - b + r.x;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

void main() {
    // Center the coordinate system
    vec2 center = v_size * 0.5;
    vec2 p = v_localPos - center;
    
    // Clamp corner radii to half size
    vec4 r = min(v_cornerRadius, vec4(min(v_size.x, v_size.y) * 0.5));
    
    // Calculate SDF
    float d = sdRoundedBox(p, center, r);
    
    // Anti-aliased edge
    float aa = fwidth(d);
    float alpha = 1.0 - smoothstep(-aa, aa, d);
    
    fragColor = vec4(v_color.rgb, v_color.a * alpha);
}
`;
  var PARTICLE_VERTEX_SHADER = `#version 300 es
precision highp float;

// Per-instance attributes
in vec4 a_particle; // x, y, size, _
in vec4 a_color;    // rgba

uniform vec2 u_resolution;

out vec4 v_color;
out float v_radius;

void main() {
    vec2 pos = a_particle.xy;
    float size = a_particle.z;
    
    // Convert to clip space
    vec2 clipPos = (pos / u_resolution) * 2.0 - 1.0;
    clipPos.y = -clipPos.y;
    
    gl_Position = vec4(clipPos, 0.0, 1.0);
    gl_PointSize = size * 2.0; // Diameter
    
    v_color = a_color;
    v_radius = size;
}
`;
  var PARTICLE_FRAGMENT_SHADER = `#version 300 es
precision highp float;

in vec4 v_color;
in float v_radius;

out vec4 fragColor;

void main() {
    // Distance from center of point sprite
    vec2 coord = gl_PointCoord * 2.0 - 1.0;
    float dist = length(coord);
    
    // Anti-aliased circle
    float aa = fwidth(dist);
    float alpha = 1.0 - smoothstep(1.0 - aa, 1.0, dist);
    
    fragColor = vec4(v_color.rgb, v_color.a * alpha);
}
`;
  var isWebGL2SupportedImpl = () => {
    if (typeof document === "undefined") return false;
    const canvas = document.createElement("canvas");
    return !!(canvas && canvas.getContext && canvas.getContext("webgl2"));
  };
  var getContextImpl = (canvasId) => () => {
    const canvas = document.getElementById(canvasId);
    if (!canvas) {
      return { Left: `Canvas element not found: ${canvasId}` };
    }
    const gl = canvas.getContext("webgl2", {
      alpha: true,
      antialias: true,
      premultipliedAlpha: true,
      preserveDrawingBuffer: false
    });
    if (!gl) {
      return { Left: `WebGL2 not supported or context creation failed` };
    }
    gl._canvas = canvas;
    return { Right: gl };
  };
  function compileShader(gl, type, source) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      const error3 = gl.getShaderInfoLog(shader);
      gl.deleteShader(shader);
      throw new Error(`Shader compilation failed: ${error3}`);
    }
    return shader;
  }
  function createProgram(gl, vertexSource, fragmentSource) {
    const vertexShader = compileShader(gl, gl.VERTEX_SHADER, vertexSource);
    const fragmentShader = compileShader(gl, gl.FRAGMENT_SHADER, fragmentSource);
    const program = gl.createProgram();
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      const error3 = gl.getProgramInfoLog(program);
      gl.deleteProgram(program);
      throw new Error(`Program linking failed: ${error3}`);
    }
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);
    return program;
  }
  var createRendererImpl = (gl) => () => {
    const renderer = {
      gl,
      programs: {},
      buffers: {},
      vaos: {}
    };
    try {
      renderer.programs.rect = createProgram(gl, RECT_VERTEX_SHADER, RECT_FRAGMENT_SHADER);
      renderer.programs.particle = createProgram(gl, PARTICLE_VERTEX_SHADER, PARTICLE_FRAGMENT_SHADER);
      const quadVerts = new Float32Array([
        0,
        0,
        1,
        0,
        0,
        1,
        1,
        0,
        1,
        1,
        0,
        1
      ]);
      renderer.buffers.quad = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffers.quad);
      gl.bufferData(gl.ARRAY_BUFFER, quadVerts, gl.STATIC_DRAW);
      renderer.buffers.rectInstances = gl.createBuffer();
      renderer.buffers.particleInstances = gl.createBuffer();
      renderer.vaos.rect = gl.createVertexArray();
      renderer.vaos.particle = gl.createVertexArray();
      gl.bindVertexArray(renderer.vaos.rect);
      gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffers.quad);
      const posLoc = gl.getAttribLocation(renderer.programs.rect, "a_position");
      gl.enableVertexAttribArray(posLoc);
      gl.vertexAttribPointer(posLoc, 2, gl.FLOAT, false, 0, 0);
      gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffers.rectInstances);
      const rectLoc = gl.getAttribLocation(renderer.programs.rect, "a_rect");
      const colorLoc = gl.getAttribLocation(renderer.programs.rect, "a_color");
      const radiusLoc = gl.getAttribLocation(renderer.programs.rect, "a_cornerRadius");
      gl.enableVertexAttribArray(rectLoc);
      gl.vertexAttribPointer(rectLoc, 4, gl.FLOAT, false, 48, 0);
      gl.vertexAttribDivisor(rectLoc, 1);
      gl.enableVertexAttribArray(colorLoc);
      gl.vertexAttribPointer(colorLoc, 4, gl.FLOAT, false, 48, 16);
      gl.vertexAttribDivisor(colorLoc, 1);
      gl.enableVertexAttribArray(radiusLoc);
      gl.vertexAttribPointer(radiusLoc, 4, gl.FLOAT, false, 48, 32);
      gl.vertexAttribDivisor(radiusLoc, 1);
      gl.bindVertexArray(null);
      gl.bindVertexArray(renderer.vaos.particle);
      gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffers.particleInstances);
      const particleLoc = gl.getAttribLocation(renderer.programs.particle, "a_particle");
      const pColorLoc = gl.getAttribLocation(renderer.programs.particle, "a_color");
      gl.enableVertexAttribArray(particleLoc);
      gl.vertexAttribPointer(particleLoc, 4, gl.FLOAT, false, 32, 0);
      gl.vertexAttribDivisor(particleLoc, 1);
      gl.enableVertexAttribArray(pColorLoc);
      gl.vertexAttribPointer(pColorLoc, 4, gl.FLOAT, false, 32, 16);
      gl.vertexAttribDivisor(pColorLoc, 1);
      gl.bindVertexArray(null);
    } catch (err) {
      console.error("Renderer creation failed:", err);
      throw err;
    }
    return renderer;
  };
  var renderImpl = (renderer) => (commands) => () => {
    const gl = renderer.gl;
    const canvas = gl._canvas;
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    const rects = [];
    const particles = [];
    for (const cmd of commands) {
      if (cmd.tag === "DrawRect") {
        rects.push(cmd.value0);
      } else if (cmd.tag === "DrawParticle") {
        particles.push(cmd.value0);
      }
    }
    if (rects.length > 0) {
      renderRects(renderer, rects);
    }
    if (particles.length > 0) {
      renderParticles(renderer, particles);
    }
  };
  function renderRects(renderer, rects) {
    const gl = renderer.gl;
    const program = renderer.programs.rect;
    const canvas = gl._canvas;
    gl.useProgram(program);
    const resLoc = gl.getUniformLocation(program, "u_resolution");
    gl.uniform2f(resLoc, canvas.width, canvas.height);
    const instanceData = new Float32Array(rects.length * 12);
    for (let i = 0; i < rects.length; i++) {
      const r = rects[i];
      const offset = i * 12;
      instanceData[offset + 0] = r.x || 0;
      instanceData[offset + 1] = r.y || 0;
      instanceData[offset + 2] = r.width || 0;
      instanceData[offset + 3] = r.height || 0;
      const fill = r.fill || {};
      instanceData[offset + 4] = fill.r || 0;
      instanceData[offset + 5] = fill.g || 0;
      instanceData[offset + 6] = fill.b || 0;
      instanceData[offset + 7] = fill.a || 1;
      const cr = r.cornerRadius || {};
      instanceData[offset + 8] = cr.topLeft || 0;
      instanceData[offset + 9] = cr.topRight || 0;
      instanceData[offset + 10] = cr.bottomRight || 0;
      instanceData[offset + 11] = cr.bottomLeft || 0;
    }
    gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffers.rectInstances);
    gl.bufferData(gl.ARRAY_BUFFER, instanceData, gl.DYNAMIC_DRAW);
    gl.bindVertexArray(renderer.vaos.rect);
    gl.drawArraysInstanced(gl.TRIANGLES, 0, 6, rects.length);
    gl.bindVertexArray(null);
  }
  function renderParticles(renderer, particles) {
    const gl = renderer.gl;
    const program = renderer.programs.particle;
    const canvas = gl._canvas;
    gl.useProgram(program);
    const resLoc = gl.getUniformLocation(program, "u_resolution");
    gl.uniform2f(resLoc, canvas.width, canvas.height);
    const instanceData = new Float32Array(particles.length * 8);
    for (let i = 0; i < particles.length; i++) {
      const p = particles[i];
      const offset = i * 8;
      instanceData[offset + 0] = p.x || 0;
      instanceData[offset + 1] = p.y || 0;
      instanceData[offset + 2] = p.size || 5;
      instanceData[offset + 3] = 0;
      const color = p.color || {};
      instanceData[offset + 4] = color.r || 1;
      instanceData[offset + 5] = color.g || 0;
      instanceData[offset + 6] = color.b || 0;
      instanceData[offset + 7] = color.a || 1;
    }
    gl.bindBuffer(gl.ARRAY_BUFFER, renderer.buffers.particleInstances);
    gl.bufferData(gl.ARRAY_BUFFER, instanceData, gl.DYNAMIC_DRAW);
    gl.bindVertexArray(renderer.vaos.particle);
    gl.drawArraysInstanced(gl.POINTS, 0, 1, particles.length);
    gl.bindVertexArray(null);
  }

  // output/Hydrogen.Target.WebGL/index.js
  var render3 = function(renderer) {
    return function(commands) {
      return renderImpl(renderer)(commands);
    };
  };
  var isWebGL2Supported = isWebGL2SupportedImpl;
  var getContext = getContextImpl;
  var createRenderer = createRendererImpl;

  // output/Hydrogen.Target.GPU/index.js
  var log5 = /* @__PURE__ */ log3(monadEffectEffect);
  var RendererWebGPU = /* @__PURE__ */ (function() {
    function RendererWebGPU2(value0) {
      this.value0 = value0;
    }
    ;
    RendererWebGPU2.create = function(value0) {
      return new RendererWebGPU2(value0);
    };
    return RendererWebGPU2;
  })();
  var RendererWebGL2 = /* @__PURE__ */ (function() {
    function RendererWebGL22(value0) {
      this.value0 = value0;
    }
    ;
    RendererWebGL22.create = function(value0) {
      return new RendererWebGL22(value0);
    };
    return RendererWebGL22;
  })();
  var RendererCanvas2D = /* @__PURE__ */ (function() {
    function RendererCanvas2D2(value0) {
      this.value0 = value0;
    }
    ;
    RendererCanvas2D2.create = function(value0) {
      return new RendererCanvas2D2(value0);
    };
    return RendererCanvas2D2;
  })();
  var WebGPU = /* @__PURE__ */ (function() {
    function WebGPU2() {
    }
    ;
    WebGPU2.value = new WebGPU2();
    return WebGPU2;
  })();
  var WebGL2 = /* @__PURE__ */ (function() {
    function WebGL22() {
    }
    ;
    WebGL22.value = new WebGL22();
    return WebGL22;
  })();
  var Canvas2D = /* @__PURE__ */ (function() {
    function Canvas2D2() {
    }
    ;
    Canvas2D2.value = new Canvas2D2();
    return Canvas2D2;
  })();
  var render4 = function(renderer) {
    return function(commands) {
      if (renderer instanceof RendererWebGPU) {
        return log5("WebGPU render not yet implemented");
      }
      ;
      if (renderer instanceof RendererWebGL2) {
        return render3(renderer.value0.renderer)(commands);
      }
      ;
      if (renderer instanceof RendererCanvas2D) {
        return render2(renderer.value0.context)(commands);
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Target.GPU (line 247, column 28 - line 253, column 59): " + [renderer.constructor.name]);
    };
  };
  var getCanvas2DContext = function(canvasId) {
    return function __do3() {
      var result = getCanvas2DContextImpl(canvasId)();
      if (result instanceof Left) {
        return new Left(result.value0);
      }
      ;
      if (result instanceof Right) {
        return new Right(new RendererCanvas2D({
          context: result.value0
        }));
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Target.GPU (line 228, column 3 - line 230, column 66): " + [result.constructor.name]);
    };
  };
  var getBackend = function(renderer) {
    if (renderer instanceof RendererWebGPU) {
      return WebGPU.value;
    }
    ;
    if (renderer instanceof RendererWebGL2) {
      return WebGL2.value;
    }
    ;
    if (renderer instanceof RendererCanvas2D) {
      return Canvas2D.value;
    }
    ;
    throw new Error("Failed pattern match at Hydrogen.Target.GPU (line 276, column 23 - line 279, column 33): " + [renderer.constructor.name]);
  };
  var detectCapabilities = function __do() {
    var webgpu = isWebGPUSupported();
    var webgl2 = isWebGL2Supported();
    var canvas2d = isCanvas2DSupported();
    var bestBackend = (function() {
      if (webgpu) {
        return WebGPU.value;
      }
      ;
      if (webgl2) {
        return WebGL2.value;
      }
      ;
      return Canvas2D.value;
    })();
    return {
      webgpu,
      webgl2,
      canvas2d,
      bestBackend
    };
  };
  var defaultConfig3 = /* @__PURE__ */ (function() {
    return {
      preferredBackend: Nothing.value,
      powerPreference: "high-performance",
      antialias: true,
      alpha: true,
      preserveDrawingBuffer: false
    };
  })();
  var createWebGL2Renderer = function(canvasId) {
    return function(_config) {
      return function __do3() {
        var ctxResult = getContext(canvasId)();
        if (ctxResult instanceof Left) {
          return new Left(ctxResult.value0);
        }
        ;
        if (ctxResult instanceof Right) {
          var renderer = createRenderer(ctxResult.value0)();
          return new Right(new RendererWebGL2({
            context: ctxResult.value0,
            renderer
          }));
        }
        ;
        throw new Error("Failed pattern match at Hydrogen.Target.GPU (line 208, column 3 - line 212, column 63): " + [ctxResult.constructor.name]);
      };
    };
  };
  var createWebGPURenderer = function(canvasId) {
    return function(config) {
      return function __do3() {
        log5("WebGPU requires async initialization, falling back to WebGL2")();
        return createWebGL2Renderer(canvasId)(config)();
      };
    };
  };
  var createCanvas2DRenderer = function(canvasId) {
    return getCanvas2DContext(canvasId);
  };
  var createRendererWithConfig = function(canvasId) {
    return function(config) {
      return function __do3() {
        var caps = detectCapabilities();
        var backend = (function() {
          if (config.preferredBackend instanceof Just) {
            return config.preferredBackend.value0;
          }
          ;
          if (config.preferredBackend instanceof Nothing) {
            return caps.bestBackend;
          }
          ;
          throw new Error("Failed pattern match at Hydrogen.Target.GPU (line 187, column 17 - line 189, column 36): " + [config.preferredBackend.constructor.name]);
        })();
        if (backend instanceof WebGPU) {
          return createWebGPURenderer(canvasId)(config)();
        }
        ;
        if (backend instanceof WebGL2) {
          return createWebGL2Renderer(canvasId)(config)();
        }
        ;
        if (backend instanceof Canvas2D) {
          return createCanvas2DRenderer(canvasId)();
        }
        ;
        throw new Error("Failed pattern match at Hydrogen.Target.GPU (line 191, column 3 - line 194, column 48): " + [backend.constructor.name]);
      };
    };
  };
  var createRenderer2 = function(canvasId) {
    return createRendererWithConfig(canvasId)(defaultConfig3);
  };

  // output/Canvas.Runtime.GPU/index.js
  var map6 = /* @__PURE__ */ map(functorArray);
  var log6 = /* @__PURE__ */ log3(monadEffectEffect);
  var show5 = function(v) {
    if (v) {
      return "true";
    }
    ;
    if (!v) {
      return "false";
    }
    ;
    throw new Error("Failed pattern match at Canvas.Runtime.GPU (line 246, column 1 - line 246, column 26): " + [v.constructor.name]);
  };
  var colorToRGBA = function(c) {
    return rgba(floor2(c.r * 255))(floor2(c.g * 255))(floor2(c.b * 255))(floor2(c.a * 100));
  };
  var particleToCommand = function(p) {
    var radius = particleRadius(p);
    var pos = particlePosition(p);
    var height = particleHeight(p);
    var depthFromHeight = 0.5 - height * 0.25;
    var color = particleColor(p);
    var rgbaColor = colorToRGBA(color);
    var clampedDepth = (function() {
      var $12 = depthFromHeight < 0;
      if ($12) {
        return 0;
      }
      ;
      return depthFromHeight;
    })();
    var params = {
      x: screenX(pos.x),
      y: screenY(pos.y),
      z: depthValue(clampedDepth),
      size: px(radius),
      color: rgbaColor,
      pickId: Nothing.value,
      onClick: Nothing.value
    };
    return new DrawParticle(params);
  };
  var particlesToCommands = function(particles) {
    return map6(particleToCommand)(particles);
  };
  var renderParticles2 = function(runtime) {
    return function(particles) {
      var commands = particlesToCommands(particles);
      return render4(runtime.renderer)(commands);
    };
  };
  var backendToString = function(backend) {
    if (backend instanceof WebGPU) {
      return "WebGPU";
    }
    ;
    if (backend instanceof WebGL2) {
      return "WebGL2";
    }
    ;
    if (backend instanceof Canvas2D) {
      return "Canvas2D";
    }
    ;
    throw new Error("Failed pattern match at Canvas.Runtime.GPU (line 180, column 27 - line 183, column 29): " + [backend.constructor.name]);
  };
  var getBackendName = function(runtime) {
    return backendToString(runtime.backend);
  };
  var initialize = function(canvasId) {
    return function __do3() {
      log6("Initializing GPU runtime for canvas: " + canvasId)();
      var caps = detectCapabilities();
      log6("GPU Capabilities:")();
      log6("  WebGPU: " + show5(caps.webgpu))();
      log6("  WebGL2: " + show5(caps.webgl2))();
      log6("  Canvas2D: " + show5(caps.canvas2d))();
      log6("  Best backend: " + backendToString(caps.bestBackend))();
      var result = createRenderer2(canvasId)();
      if (result instanceof Left) {
        log6("GPU initialization failed: " + result.value0)();
        return new Left(result.value0);
      }
      ;
      if (result instanceof Right) {
        var backend = getBackend(result.value0);
        log6("Using backend: " + backendToString(backend))();
        return new Right({
          renderer: result.value0,
          canvasId,
          backend
        });
      }
      ;
      throw new Error("Failed pattern match at Canvas.Runtime.GPU (line 123, column 3 - line 130, column 51): " + [result.constructor.name]);
    };
  };

  // output/Data.Nullable/foreign.js
  function nullable(a, r, f) {
    return a == null ? r : f(a);
  }

  // output/Data.Nullable/index.js
  var toMaybe = function(n) {
    return nullable(n, Nothing.value, Just.create);
  };

  // output/Hydrogen.Runtime.Cmd/index.js
  var None = /* @__PURE__ */ (function() {
    function None2() {
    }
    ;
    None2.value = new None2();
    return None2;
  })();
  var Log = /* @__PURE__ */ (function() {
    function Log2(value0) {
      this.value0 = value0;
    }
    ;
    Log2.create = function(value0) {
      return new Log2(value0);
    };
    return Log2;
  })();
  var transition = function(state2) {
    return function(cmd) {
      return {
        state: state2,
        cmd
      };
    };
  };
  var noCmd = function(state2) {
    return {
      state: state2,
      cmd: None.value
    };
  };

  // output/Hydrogen.Target.Static/index.js
  var elem3 = /* @__PURE__ */ elem2(eqString);
  var map7 = /* @__PURE__ */ map(functorArray);
  var voidElements = ["area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"];
  var isVoidElement = function(tag) {
    return elem3(tag)(voidElements);
  };
  var isStyle = function(v) {
    if (v instanceof Style) {
      return true;
    }
    ;
    return false;
  };
  var escapeHtml = function(s) {
    return replaceAll(">")("&gt;")(replaceAll("<")("&lt;")(replaceAll("&")("&amp;")(s)));
  };
  var escapeAttr = function(s) {
    return replaceAll('"')("&quot;")(replaceAll(">")("&gt;")(replaceAll("<")("&lt;")(replaceAll("&")("&amp;")(s))));
  };
  var renderAttribute = function(v) {
    if (v instanceof Attr) {
      return new Just(v.value0 + ('="' + (escapeAttr(v.value1) + '"')));
    }
    ;
    if (v instanceof AttrNS) {
      return new Just(v.value1 + ('="' + (escapeAttr(v.value2) + '"')));
    }
    ;
    if (v instanceof Prop) {
      return new Just(v.value0 + ('="' + (escapeAttr(v.value1) + '"')));
    }
    ;
    if (v instanceof PropBool && v.value1) {
      return new Just(v.value0);
    }
    ;
    if (v instanceof PropBool && !v.value1) {
      return Nothing.value;
    }
    ;
    if (v instanceof Handler) {
      return Nothing.value;
    }
    ;
    if (v instanceof Style) {
      return Nothing.value;
    }
    ;
    throw new Error("Failed pattern match at Hydrogen.Target.Static (line 193, column 19 - line 215, column 12): " + [v.constructor.name]);
  };
  var renderMergedStyles = function(styles2) {
    var styleStr = joinWith("; ")(map7(function(v) {
      return v.value0 + (": " + v.value1);
    })(styles2));
    return 'style="' + (escapeAttr(styleStr) + '"');
  };
  var defaultOptions = {
    selfClosingSlash: true
  };
  var collectStyles = /* @__PURE__ */ (function() {
    var go = function(acc) {
      return function(v) {
        if (v instanceof Style) {
          return snoc(acc)(new Tuple(v.value0, v.value1));
        }
        ;
        return acc;
      };
    };
    return foldl2(go)([]);
  })();
  var renderAttributes = function(attrs) {
    var styles2 = collectStyles(attrs);
    var nonStyleAttrs = filter(function($49) {
      return !isStyle($49);
    })(attrs);
    var rendered = mapMaybe(renderAttribute)(nonStyleAttrs);
    var withStyles = (function() {
      var $36 = $$null(styles2);
      if ($36) {
        return rendered;
      }
      ;
      return snoc(rendered)(renderMergedStyles(styles2));
    })();
    return joinWith(" ")(withStyles);
  };
  var renderVoidElement = function(opts) {
    return function(tag) {
      return function(attrs) {
        var closing = (function() {
          if (opts.selfClosingSlash) {
            return "/>";
          }
          ;
          return ">";
        })();
        var attrsStr = renderAttributes(attrs);
        var $38 = attrsStr === "";
        if ($38) {
          return "<" + (tag + closing);
        }
        ;
        return "<" + (tag + (" " + (attrsStr + closing)));
      };
    };
  };
  var renderWith = function(opts) {
    var go = function($copy_v) {
      var $tco_done = false;
      var $tco_result;
      function $tco_loop(v) {
        if (v instanceof Empty) {
          $tco_done = true;
          return "";
        }
        ;
        if (v instanceof Text) {
          $tco_done = true;
          return escapeHtml(v.value0);
        }
        ;
        if (v instanceof Element) {
          $tco_done = true;
          return renderElement(opts)(v.value0.namespace)(v.value0.tag)(v.value0.attributes)(v.value0.children);
        }
        ;
        if (v instanceof Keyed) {
          $tco_done = true;
          return renderElement(opts)(v.value0.namespace)(v.value0.tag)(v.value0.attributes)(map7(function(v1) {
            return v1.value1;
          })(v.value0.children));
        }
        ;
        if (v instanceof Lazy) {
          $copy_v = v.value0.thunk(unit);
          return;
        }
        ;
        throw new Error("Failed pattern match at Hydrogen.Target.Static (line 95, column 8 - line 108, column 24): " + [v.constructor.name]);
      }
      ;
      while (!$tco_done) {
        $tco_result = $tco_loop($copy_v);
      }
      ;
      return $tco_result;
    };
    return go;
  };
  var renderNormalElement = function(opts) {
    return function(tag) {
      return function(attrs) {
        return function(children) {
          var childrenStr = joinWith("")(map7(renderWith(opts))(children));
          var attrsStr = renderAttributes(attrs);
          var openTag = (function() {
            var $47 = attrsStr === "";
            if ($47) {
              return "<" + (tag + ">");
            }
            ;
            return "<" + (tag + (" " + (attrsStr + ">")));
          })();
          return openTag + (childrenStr + ("</" + (tag + ">")));
        };
      };
    };
  };
  var renderElement = function(opts) {
    return function(_ns) {
      return function(tag) {
        return function(attrs) {
          return function(children) {
            var $48 = isVoidElement(tag);
            if ($48) {
              return renderVoidElement(opts)(tag)(attrs);
            }
            ;
            return renderNormalElement(opts)(tag)(attrs)(children);
          };
        };
      };
    };
  };
  var render5 = /* @__PURE__ */ renderWith(defaultOptions);

  // output/Canvas.Runtime.DOM/index.js
  var pure3 = /* @__PURE__ */ pure(applicativeEffect);
  var setGPUStatusText = setGPUStatusTextImpl;
  var selectElement = function(selector) {
    return function __do3() {
      var result = selectElementImpl(selector)();
      return toMaybe(result);
    };
  };
  var requestAnimationFrame2 = requestAnimationFrameImpl;
  var renderToElement = function(el) {
    return function(view2) {
      return function(state2) {
        var element2 = view2(state2);
        var html = render5(element2);
        return setInnerHTML(el)(html);
      };
    };
  };
  var renderGPUParticles = function(gpuRef) {
    return function(particles) {
      return function __do3() {
        renderCanvasTextureImpl("paint-canvas")();
        var maybeGpu = readRef(gpuRef)();
        if (maybeGpu instanceof Nothing) {
          return unit;
        }
        ;
        if (maybeGpu instanceof Just) {
          return renderParticles2(maybeGpu.value0)(particles)();
        }
        ;
        throw new Error("Failed pattern match at Canvas.Runtime.DOM (line 476, column 3 - line 480, column 44): " + [maybeGpu.constructor.name]);
      };
    };
  };
  var initGPURuntime = function(gpuRef) {
    return function __do3() {
      log2("Canvas: Initializing GPU runtime...")();
      log2("Canvas: Generating linen texture...")();
      initCanvasTextureImpl("paint-canvas")();
      var result = initialize("paint-canvas")();
      if (result instanceof Left) {
        log2("Canvas: GPU initialization failed: " + result.value0)();
        log2("Canvas: Falling back to SVG rendering")();
        writeRef(gpuRef)(Nothing.value)();
        return setGPUStatusText("GPU: SVG fallback")();
      }
      ;
      if (result instanceof Right) {
        var backendName = getBackendName(result.value0);
        log2("Canvas: GPU initialized with backend: " + backendName)();
        writeRef(gpuRef)(new Just(result.value0))();
        return setGPUStatusText("GPU: " + backendName)();
      }
      ;
      throw new Error("Failed pattern match at Canvas.Runtime.DOM (line 445, column 3 - line 457, column 48): " + [result.constructor.name]);
    };
  };
  var exportCanvasSVG = /* @__PURE__ */ exportCanvasSVGImpl("paint-svg-fallback");
  var exportCanvasPNG = /* @__PURE__ */ exportCanvasPNGImpl("paint-canvas");
  var executeCmd = function(cmd) {
    if (cmd instanceof None) {
      return pure3(unit);
    }
    ;
    if (cmd instanceof Log) {
      var $14 = cmd.value0 === "EXPORT:png";
      if ($14) {
        return function __do3() {
          log2("Canvas: Exporting as PNG...")();
          return exportCanvasPNG();
        };
      }
      ;
      var $15 = cmd.value0 === "EXPORT:svg";
      if ($15) {
        return function __do3() {
          log2("Canvas: Exporting as SVG...")();
          return exportCanvasSVG();
        };
      }
      ;
      return log2(cmd.value0);
    }
    ;
    return pure3(unit);
  };
  var addKeyboardShortcutListener = addKeyboardShortcutListenerImpl;
  var mount = function(selector) {
    return function(_app) {
      return function(update2) {
        return function(view2) {
          return function(initialTransition) {
            return function(getParticles) {
              return function(toTickMsg) {
                return function(toKeyboardShortcutMsg) {
                  return function __do3() {
                    log2("Canvas: Mounting to " + selector)();
                    var maybeEl = selectElement(selector)();
                    if (maybeEl instanceof Nothing) {
                      log2("Canvas: ERROR - Could not find element: " + selector)();
                      return unit;
                    }
                    ;
                    if (maybeEl instanceof Just) {
                      log2("Canvas: Found root element, initializing...")();
                      var stateRef = newRef(initialTransition.state)();
                      var gpuRef = newRef(Nothing.value)();
                      var cancelRef = newRef(pure3(unit))();
                      renderToElement(maybeEl.value0)(view2)(initialTransition.state)();
                      initGPURuntime(gpuRef)();
                      var cancelAnimation = requestAnimationFrame2(function(deltaTime) {
                        return function __do4() {
                          var currentState = readRef(stateRef)();
                          var tickMsg = toTickMsg(deltaTime);
                          var newTransition = update2(tickMsg)(currentState);
                          writeRef(stateRef)(newTransition.state)();
                          executeCmd(newTransition.cmd)();
                          renderToElement(maybeEl.value0)(view2)(newTransition.state)();
                          return renderGPUParticles(gpuRef)(getParticles(newTransition.state))();
                        };
                      })();
                      writeRef(cancelRef)(cancelAnimation)();
                      var _cancelKeyboard = addKeyboardShortcutListener(function(shortcut) {
                        return function __do4() {
                          var currentState = readRef(stateRef)();
                          var shortcutMsg = toKeyboardShortcutMsg(shortcut);
                          var newTransition = update2(shortcutMsg)(currentState);
                          writeRef(stateRef)(newTransition.state)();
                          executeCmd(newTransition.cmd)();
                          renderToElement(maybeEl.value0)(view2)(newTransition.state)();
                          return renderGPUParticles(gpuRef)(getParticles(newTransition.state))();
                        };
                      })();
                      setGlobalUnmountImpl(cancelAnimation)();
                      log2("Canvas: Animation loop started")();
                      log2("Canvas: Mount complete!")();
                      return unit;
                    }
                    ;
                    throw new Error("Failed pattern match at Canvas.Runtime.DOM (line 326, column 3 - line 389, column 16): " + [maybeEl.constructor.name]);
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  // output/Data.List.Types/index.js
  var Nil = /* @__PURE__ */ (function() {
    function Nil2() {
    }
    ;
    Nil2.value = new Nil2();
    return Nil2;
  })();
  var Cons = /* @__PURE__ */ (function() {
    function Cons2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    Cons2.create = function(value0) {
      return function(value1) {
        return new Cons2(value0, value1);
      };
    };
    return Cons2;
  })();
  var foldableList = {
    foldr: function(f) {
      return function(b) {
        var rev = (function() {
          var go = function($copy_v) {
            return function($copy_v1) {
              var $tco_var_v = $copy_v;
              var $tco_done = false;
              var $tco_result;
              function $tco_loop(v, v1) {
                if (v1 instanceof Nil) {
                  $tco_done = true;
                  return v;
                }
                ;
                if (v1 instanceof Cons) {
                  $tco_var_v = new Cons(v1.value0, v);
                  $copy_v1 = v1.value1;
                  return;
                }
                ;
                throw new Error("Failed pattern match at Data.List.Types (line 107, column 7 - line 107, column 23): " + [v.constructor.name, v1.constructor.name]);
              }
              ;
              while (!$tco_done) {
                $tco_result = $tco_loop($tco_var_v, $copy_v1);
              }
              ;
              return $tco_result;
            };
          };
          return go(Nil.value);
        })();
        var $284 = foldl(foldableList)(flip(f))(b);
        return function($285) {
          return $284(rev($285));
        };
      };
    },
    foldl: function(f) {
      var go = function($copy_b) {
        return function($copy_v) {
          var $tco_var_b = $copy_b;
          var $tco_done1 = false;
          var $tco_result;
          function $tco_loop(b, v) {
            if (v instanceof Nil) {
              $tco_done1 = true;
              return b;
            }
            ;
            if (v instanceof Cons) {
              $tco_var_b = f(b)(v.value0);
              $copy_v = v.value1;
              return;
            }
            ;
            throw new Error("Failed pattern match at Data.List.Types (line 111, column 12 - line 113, column 30): " + [v.constructor.name]);
          }
          ;
          while (!$tco_done1) {
            $tco_result = $tco_loop($tco_var_b, $copy_v);
          }
          ;
          return $tco_result;
        };
      };
      return go;
    },
    foldMap: function(dictMonoid) {
      var append22 = append(dictMonoid.Semigroup0());
      var mempty2 = mempty(dictMonoid);
      return function(f) {
        return foldl(foldableList)(function(acc) {
          var $286 = append22(acc);
          return function($287) {
            return $286(f($287));
          };
        })(mempty2);
      };
    }
  };

  // output/Data.Map.Internal/index.js
  var $runtime_lazy2 = function(name2, moduleName, init2) {
    var state2 = 0;
    var val;
    return function(lineNumber) {
      if (state2 === 2) return val;
      if (state2 === 1) throw new ReferenceError(name2 + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
      state2 = 1;
      val = init2();
      state2 = 2;
      return val;
    };
  };
  var Leaf = /* @__PURE__ */ (function() {
    function Leaf2() {
    }
    ;
    Leaf2.value = new Leaf2();
    return Leaf2;
  })();
  var Node = /* @__PURE__ */ (function() {
    function Node2(value0, value1, value2, value3, value4, value5) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value2;
      this.value3 = value3;
      this.value4 = value4;
      this.value5 = value5;
    }
    ;
    Node2.create = function(value0) {
      return function(value1) {
        return function(value2) {
          return function(value3) {
            return function(value4) {
              return function(value5) {
                return new Node2(value0, value1, value2, value3, value4, value5);
              };
            };
          };
        };
      };
    };
    return Node2;
  })();
  var SplitLast = /* @__PURE__ */ (function() {
    function SplitLast2(value0, value1, value2) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value2;
    }
    ;
    SplitLast2.create = function(value0) {
      return function(value1) {
        return function(value2) {
          return new SplitLast2(value0, value1, value2);
        };
      };
    };
    return SplitLast2;
  })();
  var unsafeNode = function(k, v, l, r) {
    if (l instanceof Leaf) {
      if (r instanceof Leaf) {
        return new Node(1, 1, k, v, l, r);
      }
      ;
      if (r instanceof Node) {
        return new Node(1 + r.value0 | 0, 1 + r.value1 | 0, k, v, l, r);
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 702, column 5 - line 706, column 39): " + [r.constructor.name]);
    }
    ;
    if (l instanceof Node) {
      if (r instanceof Leaf) {
        return new Node(1 + l.value0 | 0, 1 + l.value1 | 0, k, v, l, r);
      }
      ;
      if (r instanceof Node) {
        return new Node(1 + (function() {
          var $280 = l.value0 > r.value0;
          if ($280) {
            return l.value0;
          }
          ;
          return r.value0;
        })() | 0, (1 + l.value1 | 0) + r.value1 | 0, k, v, l, r);
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 708, column 5 - line 712, column 68): " + [r.constructor.name]);
    }
    ;
    throw new Error("Failed pattern match at Data.Map.Internal (line 700, column 32 - line 712, column 68): " + [l.constructor.name]);
  };
  var size = function(v) {
    if (v instanceof Leaf) {
      return 0;
    }
    ;
    if (v instanceof Node) {
      return v.value1;
    }
    ;
    throw new Error("Failed pattern match at Data.Map.Internal (line 618, column 8 - line 620, column 24): " + [v.constructor.name]);
  };
  var singleton4 = function(k) {
    return function(v) {
      return new Node(1, 1, k, v, Leaf.value, Leaf.value);
    };
  };
  var unsafeBalancedNode = /* @__PURE__ */ (function() {
    var height = function(v) {
      if (v instanceof Leaf) {
        return 0;
      }
      ;
      if (v instanceof Node) {
        return v.value0;
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 757, column 12 - line 759, column 26): " + [v.constructor.name]);
    };
    var rotateLeft = function(k, v, l, rk, rv, rl, rr) {
      if (rl instanceof Node && rl.value0 > height(rr)) {
        return unsafeNode(rl.value2, rl.value3, unsafeNode(k, v, l, rl.value4), unsafeNode(rk, rv, rl.value5, rr));
      }
      ;
      return unsafeNode(rk, rv, unsafeNode(k, v, l, rl), rr);
    };
    var rotateRight2 = function(k, v, lk, lv, ll, lr, r) {
      if (lr instanceof Node && height(ll) <= lr.value0) {
        return unsafeNode(lr.value2, lr.value3, unsafeNode(lk, lv, ll, lr.value4), unsafeNode(k, v, lr.value5, r));
      }
      ;
      return unsafeNode(lk, lv, ll, unsafeNode(k, v, lr, r));
    };
    return function(k, v, l, r) {
      if (l instanceof Leaf) {
        if (r instanceof Leaf) {
          return singleton4(k)(v);
        }
        ;
        if (r instanceof Node && r.value0 > 1) {
          return rotateLeft(k, v, l, r.value2, r.value3, r.value4, r.value5);
        }
        ;
        return unsafeNode(k, v, l, r);
      }
      ;
      if (l instanceof Node) {
        if (r instanceof Node) {
          if (r.value0 > (l.value0 + 1 | 0)) {
            return rotateLeft(k, v, l, r.value2, r.value3, r.value4, r.value5);
          }
          ;
          if (l.value0 > (r.value0 + 1 | 0)) {
            return rotateRight2(k, v, l.value2, l.value3, l.value4, l.value5, r);
          }
          ;
        }
        ;
        if (r instanceof Leaf && l.value0 > 1) {
          return rotateRight2(k, v, l.value2, l.value3, l.value4, l.value5, r);
        }
        ;
        return unsafeNode(k, v, l, r);
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 717, column 40 - line 738, column 34): " + [l.constructor.name]);
    };
  })();
  var $lazy_unsafeSplitLast = /* @__PURE__ */ $runtime_lazy2("unsafeSplitLast", "Data.Map.Internal", function() {
    return function(k, v, l, r) {
      if (r instanceof Leaf) {
        return new SplitLast(k, v, l);
      }
      ;
      if (r instanceof Node) {
        var v1 = $lazy_unsafeSplitLast(779)(r.value2, r.value3, r.value4, r.value5);
        return new SplitLast(v1.value0, v1.value1, unsafeBalancedNode(k, v, l, v1.value2));
      }
      ;
      throw new Error("Failed pattern match at Data.Map.Internal (line 776, column 37 - line 780, column 57): " + [r.constructor.name]);
    };
  });
  var unsafeSplitLast = /* @__PURE__ */ $lazy_unsafeSplitLast(775);
  var unsafeJoinNodes = function(v, v1) {
    if (v instanceof Leaf) {
      return v1;
    }
    ;
    if (v instanceof Node) {
      var v2 = unsafeSplitLast(v.value2, v.value3, v.value4, v.value5);
      return unsafeBalancedNode(v2.value0, v2.value1, v2.value2, v1);
    }
    ;
    throw new Error("Failed pattern match at Data.Map.Internal (line 764, column 25 - line 768, column 38): " + [v.constructor.name, v1.constructor.name]);
  };
  var lookup = function(dictOrd) {
    var compare4 = compare(dictOrd);
    return function(k) {
      var go = function($copy_v) {
        var $tco_done = false;
        var $tco_result;
        function $tco_loop(v) {
          if (v instanceof Leaf) {
            $tco_done = true;
            return Nothing.value;
          }
          ;
          if (v instanceof Node) {
            var v1 = compare4(k)(v.value2);
            if (v1 instanceof LT) {
              $copy_v = v.value4;
              return;
            }
            ;
            if (v1 instanceof GT) {
              $copy_v = v.value5;
              return;
            }
            ;
            if (v1 instanceof EQ) {
              $tco_done = true;
              return new Just(v.value3);
            }
            ;
            throw new Error("Failed pattern match at Data.Map.Internal (line 283, column 7 - line 286, column 22): " + [v1.constructor.name]);
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 280, column 8 - line 286, column 22): " + [v.constructor.name]);
        }
        ;
        while (!$tco_done) {
          $tco_result = $tco_loop($copy_v);
        }
        ;
        return $tco_result;
      };
      return go;
    };
  };
  var insert = function(dictOrd) {
    var compare4 = compare(dictOrd);
    return function(k) {
      return function(v) {
        var go = function(v1) {
          if (v1 instanceof Leaf) {
            return singleton4(k)(v);
          }
          ;
          if (v1 instanceof Node) {
            var v2 = compare4(k)(v1.value2);
            if (v2 instanceof LT) {
              return unsafeBalancedNode(v1.value2, v1.value3, go(v1.value4), v1.value5);
            }
            ;
            if (v2 instanceof GT) {
              return unsafeBalancedNode(v1.value2, v1.value3, v1.value4, go(v1.value5));
            }
            ;
            if (v2 instanceof EQ) {
              return new Node(v1.value0, v1.value1, k, v, v1.value4, v1.value5);
            }
            ;
            throw new Error("Failed pattern match at Data.Map.Internal (line 471, column 7 - line 474, column 35): " + [v2.constructor.name]);
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 468, column 8 - line 474, column 35): " + [v1.constructor.name]);
        };
        return go;
      };
    };
  };
  var foldableMap = {
    foldr: function(f) {
      return function(z) {
        var $lazy_go = $runtime_lazy2("go", "Data.Map.Internal", function() {
          return function(m$prime, z$prime) {
            if (m$prime instanceof Leaf) {
              return z$prime;
            }
            ;
            if (m$prime instanceof Node) {
              return $lazy_go(172)(m$prime.value4, f(m$prime.value3)($lazy_go(172)(m$prime.value5, z$prime)));
            }
            ;
            throw new Error("Failed pattern match at Data.Map.Internal (line 169, column 26 - line 172, column 43): " + [m$prime.constructor.name]);
          };
        });
        var go = $lazy_go(169);
        return function(m) {
          return go(m, z);
        };
      };
    },
    foldl: function(f) {
      return function(z) {
        var $lazy_go = $runtime_lazy2("go", "Data.Map.Internal", function() {
          return function(z$prime, m$prime) {
            if (m$prime instanceof Leaf) {
              return z$prime;
            }
            ;
            if (m$prime instanceof Node) {
              return $lazy_go(178)(f($lazy_go(178)(z$prime, m$prime.value4))(m$prime.value3), m$prime.value5);
            }
            ;
            throw new Error("Failed pattern match at Data.Map.Internal (line 175, column 26 - line 178, column 43): " + [m$prime.constructor.name]);
          };
        });
        var go = $lazy_go(175);
        return function(m) {
          return go(z, m);
        };
      };
    },
    foldMap: function(dictMonoid) {
      var mempty2 = mempty(dictMonoid);
      var append13 = append(dictMonoid.Semigroup0());
      return function(f) {
        var go = function(v) {
          if (v instanceof Leaf) {
            return mempty2;
          }
          ;
          if (v instanceof Node) {
            return append13(go(v.value4))(append13(f(v.value3))(go(v.value5)));
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 181, column 10 - line 184, column 28): " + [v.constructor.name]);
        };
        return go;
      };
    }
  };
  var values = /* @__PURE__ */ (function() {
    return foldr(foldableMap)(Cons.create)(Nil.value);
  })();
  var empty3 = /* @__PURE__ */ (function() {
    return Leaf.value;
  })();
  var $$delete = function(dictOrd) {
    var compare4 = compare(dictOrd);
    return function(k) {
      var go = function(v) {
        if (v instanceof Leaf) {
          return Leaf.value;
        }
        ;
        if (v instanceof Node) {
          var v1 = compare4(k)(v.value2);
          if (v1 instanceof LT) {
            return unsafeBalancedNode(v.value2, v.value3, go(v.value4), v.value5);
          }
          ;
          if (v1 instanceof GT) {
            return unsafeBalancedNode(v.value2, v.value3, v.value4, go(v.value5));
          }
          ;
          if (v1 instanceof EQ) {
            return unsafeJoinNodes(v.value4, v.value5);
          }
          ;
          throw new Error("Failed pattern match at Data.Map.Internal (line 498, column 7 - line 501, column 43): " + [v1.constructor.name]);
        }
        ;
        throw new Error("Failed pattern match at Data.Map.Internal (line 495, column 8 - line 501, column 43): " + [v.constructor.name]);
      };
      return go;
    };
  };

  // output/Canvas.Layer.Types/index.js
  var lookup2 = /* @__PURE__ */ lookup(ordInt);
  var insert2 = /* @__PURE__ */ insert(ordInt);
  var fromFoldable2 = /* @__PURE__ */ fromFoldable(foldableList);
  var $$delete2 = /* @__PURE__ */ $$delete(ordInt);
  var max13 = /* @__PURE__ */ max(ordInt);
  var comparing2 = /* @__PURE__ */ comparing(ordZIndex);
  var compare3 = /* @__PURE__ */ compare(ordZIndex);
  var updateLayer = function(lid) {
    return function(f) {
      return function(stack) {
        var v = lookup2(unwrapLayerId(lid))(stack.layers);
        if (v instanceof Just) {
          return {
            activeLayerId: stack.activeLayerId,
            nextLayerId: stack.nextLayerId,
            layers: insert2(unwrapLayerId(lid))(f(v.value0))(stack.layers)
          };
        }
        ;
        if (v instanceof Nothing) {
          return stack;
        }
        ;
        throw new Error("Failed pattern match at Canvas.Layer.Types (line 359, column 3 - line 362, column 21): " + [v.constructor.name]);
      };
    };
  };
  var stackLayers = function(stack) {
    return fromFoldable2(values(stack.layers));
  };
  var stackActiveLayerId = function(stack) {
    return stack.activeLayerId;
  };
  var setLayerZIndex = function(z) {
    return function(l) {
      return {
        id: l.id,
        name: l.name,
        visible: l.visible,
        locked: l.locked,
        opacity: l.opacity,
        blendMode: l.blendMode,
        clipMask: l.clipMask,
        bounds: l.bounds,
        zIndex: z
      };
    };
  };
  var setLayerVisible = function(v) {
    return function(l) {
      return {
        id: l.id,
        name: l.name,
        zIndex: l.zIndex,
        locked: l.locked,
        opacity: l.opacity,
        blendMode: l.blendMode,
        clipMask: l.clipMask,
        bounds: l.bounds,
        visible: v
      };
    };
  };
  var setActiveLayer = function(lid) {
    return function(stack) {
      return {
        layers: stack.layers,
        nextLayerId: stack.nextLayerId,
        activeLayerId: lid
      };
    };
  };
  var removeLayer = function(lid) {
    return function(stack) {
      return {
        activeLayerId: stack.activeLayerId,
        nextLayerId: stack.nextLayerId,
        layers: $$delete2(unwrapLayerId(lid))(stack.layers)
      };
    };
  };
  var mkLayerStack = function(initialLayers) {
    return function(activeId) {
      var maxId = foldl2(function(acc) {
        return function(l) {
          return max13(acc)(unwrapLayerId(l.id));
        };
      })(0)(initialLayers);
      var insertLayer = function(m) {
        return function(l) {
          return insert2(unwrapLayerId(l.id))(l)(m);
        };
      };
      var layerMap = foldl2(insertLayer)(empty3)(initialLayers);
      return {
        layers: layerMap,
        activeLayerId: activeId,
        nextLayerId: maxId + 1 | 0
      };
    };
  };
  var mkLayer = function(lid) {
    return function(lname) {
      return function(zidx) {
        return function(lbounds) {
          return {
            id: lid,
            name: lname,
            zIndex: zidx,
            visible: true,
            locked: false,
            opacity: 100,
            blendMode: BlendNormal.value,
            clipMask: Nothing.value,
            bounds: lbounds
          };
        };
      };
    };
  };
  var layerZIndex = function(l) {
    return l.zIndex;
  };
  var sortedLayers = function(stack) {
    return sortBy(comparing2(layerZIndex))(stackLayers(stack));
  };
  var layerVisible = function(l) {
    return l.visible;
  };
  var layerName = function(l) {
    return l.name;
  };
  var layerId = function(l) {
    return l.id;
  };
  var layerCount = function(stack) {
    return size(stack.layers);
  };
  var isPaintLayer = function(l) {
    var z = unwrapZIndex(l.zIndex);
    return z >= 1 && z <= 99;
  };
  var getLayer = function(lid) {
    return function(stack) {
      return lookup2(unwrapLayerId(lid))(stack.layers);
    };
  };
  var findLayerBelow = function(currentZ) {
    return function(layers) {
      var below = filter(function(l) {
        return unwrapZIndex(layerZIndex(l)) < currentZ && isPaintLayer(l);
      })(layers);
      var sorted = sortBy(function(a) {
        return function(b) {
          return compare3(layerZIndex(b))(layerZIndex(a));
        };
      })(below);
      return index(sorted)(0);
    };
  };
  var moveLayerDown = function(lid) {
    return function(stack) {
      var v = getLayer(lid)(stack);
      if (v instanceof Nothing) {
        return stack;
      }
      ;
      if (v instanceof Just) {
        var sorted = sortedLayers(stack);
        var currentZ = unwrapZIndex(layerZIndex(v.value0));
        var layerBelow = findLayerBelow(currentZ)(sorted);
        if (layerBelow instanceof Nothing) {
          return stack;
        }
        ;
        if (layerBelow instanceof Just) {
          var newStack = updateLayer(lid)(setLayerZIndex(layerZIndex(layerBelow.value0)))(stack);
          return updateLayer(layerId(layerBelow.value0))(setLayerZIndex(layerZIndex(v.value0)))(newStack);
        }
        ;
        throw new Error("Failed pattern match at Canvas.Layer.Types (line 415, column 9 - line 421, column 88): " + [layerBelow.constructor.name]);
      }
      ;
      throw new Error("Failed pattern match at Canvas.Layer.Types (line 407, column 3 - line 421, column 88): " + [v.constructor.name]);
    };
  };
  var findLayerAbove = function(currentZ) {
    return function(layers) {
      var above = filter(function(l) {
        return unwrapZIndex(layerZIndex(l)) > currentZ && isPaintLayer(l);
      })(layers);
      var sorted = sortBy(comparing2(layerZIndex))(above);
      return index(sorted)(0);
    };
  };
  var moveLayerUp = function(lid) {
    return function(stack) {
      var v = getLayer(lid)(stack);
      if (v instanceof Nothing) {
        return stack;
      }
      ;
      if (v instanceof Just) {
        var sorted = sortedLayers(stack);
        var currentZ = unwrapZIndex(layerZIndex(v.value0));
        var layerAbove = findLayerAbove(currentZ)(sorted);
        if (layerAbove instanceof Nothing) {
          return stack;
        }
        ;
        if (layerAbove instanceof Just) {
          var newStack = updateLayer(lid)(setLayerZIndex(layerZIndex(layerAbove.value0)))(stack);
          return updateLayer(layerId(layerAbove.value0))(setLayerZIndex(layerZIndex(v.value0)))(newStack);
        }
        ;
        throw new Error("Failed pattern match at Canvas.Layer.Types (line 396, column 9 - line 402, column 88): " + [layerAbove.constructor.name]);
      }
      ;
      throw new Error("Failed pattern match at Canvas.Layer.Types (line 388, column 3 - line 402, column 88): " + [v.constructor.name]);
    };
  };
  var addLayer = function(l) {
    return function(stack) {
      return {
        activeLayerId: stack.activeLayerId,
        nextLayerId: stack.nextLayerId,
        layers: insert2(unwrapLayerId(l.id))(l)(stack.layers)
      };
    };
  };

  // output/Hydrogen.Motion.Gesture/index.js
  var pointDistance = function(p1) {
    return function(p2) {
      var dy = p2.y - p1.y;
      var dx = p2.x - p1.x;
      return sqrt(dx * dx + dy * dy);
    };
  };
  var pointCenter = function(p1) {
    return function(p2) {
      return {
        x: (p1.x + p2.x) / 2,
        y: (p1.y + p2.y) / 2
      };
    };
  };
  var pointAngle = function(p1) {
    return function(p2) {
      var dy = p2.y - p1.y;
      var dx = p2.x - p1.x;
      return atan2(dy)(dx) * (180 / pi);
    };
  };
  var normalizeAngle = function(angle) {
    if (angle > 180) {
      return angle - 360;
    }
    ;
    if (angle < -180) {
      return angle + 360;
    }
    ;
    if (otherwise) {
      return angle;
    }
    ;
    throw new Error("Failed pattern match at Hydrogen.Motion.Gesture (line 713, column 1 - line 713, column 35): " + [angle.constructor.name]);
  };
  var computeTwoFingerData = function(p1) {
    return function(p2) {
      return {
        center: pointCenter(p1)(p2),
        distance: pointDistance(p1)(p2),
        angle: pointAngle(p1)(p2)
      };
    };
  };

  // output/Canvas.State/index.js
  var max9 = /* @__PURE__ */ max(ordNumber);
  var min9 = /* @__PURE__ */ min(ordNumber);
  var zoomViewportAt = function(centerX) {
    return function(centerY) {
      return function(scaleDelta) {
        return function(s) {
          var newScale = max9(s.viewportState.minScale)(min9(s.viewportState.maxScale)(s.viewportState.scale * scaleDelta));
          var scaleRatio = newScale / s.viewportState.scale;
          var newPanY = centerY - (centerY - s.viewportState.panY) * scaleRatio;
          var newPanX = centerX - (centerX - s.viewportState.panX) * scaleRatio;
          return {
            canvasBounds: s.canvasBounds,
            tool: s.tool,
            brush: s.brush,
            layers: s.layers,
            paint: s.paint,
            gravity: s.gravity,
            playing: s.playing,
            frameCount: s.frameCount,
            lastFrameTime: s.lastFrameTime,
            undoStack: s.undoStack,
            redoStack: s.redoStack,
            maxHistorySize: s.maxHistorySize,
            easterEggs: s.easterEggs,
            gesture: s.gesture,
            lastPointerX: s.lastPointerX,
            lastPointerY: s.lastPointerY,
            pointerDown: s.pointerDown,
            showDebugOverlay: s.showDebugOverlay,
            viewportState: {
              rotation: s.viewportState.rotation,
              minScale: s.viewportState.minScale,
              maxScale: s.viewportState.maxScale,
              scale: newScale,
              panX: newPanX,
              panY: newPanY
            }
          };
        };
      };
    };
  };
  var zoomViewport = function(scaleDelta) {
    return function(s) {
      var newScale = max9(s.viewportState.minScale)(min9(s.viewportState.maxScale)(s.viewportState.scale * scaleDelta));
      return {
        canvasBounds: s.canvasBounds,
        tool: s.tool,
        brush: s.brush,
        layers: s.layers,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        viewportState: {
          panX: s.viewportState.panX,
          panY: s.viewportState.panY,
          rotation: s.viewportState.rotation,
          minScale: s.viewportState.minScale,
          maxScale: s.viewportState.maxScale,
          scale: newScale
        }
      };
    };
  };
  var updateGravity = function(alpha) {
    return function(beta) {
      return function(gamma) {
        return function(s) {
          return {
            canvasBounds: s.canvasBounds,
            viewportState: s.viewportState,
            tool: s.tool,
            brush: s.brush,
            layers: s.layers,
            paint: s.paint,
            playing: s.playing,
            frameCount: s.frameCount,
            lastFrameTime: s.lastFrameTime,
            undoStack: s.undoStack,
            redoStack: s.redoStack,
            maxHistorySize: s.maxHistorySize,
            easterEggs: s.easterEggs,
            gesture: s.gesture,
            lastPointerX: s.lastPointerX,
            lastPointerY: s.lastPointerY,
            pointerDown: s.pointerDown,
            showDebugOverlay: s.showDebugOverlay,
            gravity: updateFromOrientation(alpha)(beta)(gamma)(s.gravity)
          };
        };
      };
    };
  };
  var updateEasterEggConfetti = function(dt) {
    return function(s) {
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        brush: s.brush,
        layers: s.layers,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        easterEggs: updateConfetti(dt)(s.easterEggs)
      };
    };
  };
  var undo = function(s) {
    var v = unsnoc(s.undoStack);
    if (v instanceof Nothing) {
      return s;
    }
    ;
    if (v instanceof Just) {
      var currentEntry = {
        layerStack: s.layers,
        label: "undo"
      };
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        brush: s.brush,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        layers: v.value0.last.layerStack,
        undoStack: v.value0.init,
        redoStack: snoc(s.redoStack)(currentEntry)
      };
    }
    ;
    throw new Error("Failed pattern match at Canvas.State (line 905, column 3 - line 915, column 12): " + [v.constructor.name]);
  };
  var triggerEasterEggConfetti = function(x) {
    return function(y) {
      return function(s) {
        return {
          canvasBounds: s.canvasBounds,
          viewportState: s.viewportState,
          tool: s.tool,
          brush: s.brush,
          layers: s.layers,
          paint: s.paint,
          gravity: s.gravity,
          playing: s.playing,
          frameCount: s.frameCount,
          lastFrameTime: s.lastFrameTime,
          undoStack: s.undoStack,
          redoStack: s.redoStack,
          maxHistorySize: s.maxHistorySize,
          gesture: s.gesture,
          lastPointerX: s.lastPointerX,
          lastPointerY: s.lastPointerY,
          pointerDown: s.pointerDown,
          showDebugOverlay: s.showDebugOverlay,
          easterEggs: triggerConfetti(x)(y)(s.easterEggs)
        };
      };
    };
  };
  var togglePlaying = function(s) {
    return {
      canvasBounds: s.canvasBounds,
      viewportState: s.viewportState,
      tool: s.tool,
      brush: s.brush,
      layers: s.layers,
      paint: s.paint,
      gravity: s.gravity,
      frameCount: s.frameCount,
      lastFrameTime: s.lastFrameTime,
      undoStack: s.undoStack,
      redoStack: s.redoStack,
      maxHistorySize: s.maxHistorySize,
      easterEggs: s.easterEggs,
      gesture: s.gesture,
      lastPointerX: s.lastPointerX,
      lastPointerY: s.lastPointerY,
      pointerDown: s.pointerDown,
      showDebugOverlay: s.showDebugOverlay,
      playing: !s.playing
    };
  };
  var simulatePaint = function(dt) {
    return function(s) {
      if (s.playing) {
        var g2d = getGravity2D2(s.gravity);
        var withGravity = applyGravity(s.paint)(g2d.vx)(g2d.vy);
        var simulated = simulateStep(withGravity)(dt);
        return {
          canvasBounds: s.canvasBounds,
          viewportState: s.viewportState,
          tool: s.tool,
          brush: s.brush,
          layers: s.layers,
          gravity: s.gravity,
          playing: s.playing,
          lastFrameTime: s.lastFrameTime,
          undoStack: s.undoStack,
          redoStack: s.redoStack,
          maxHistorySize: s.maxHistorySize,
          easterEggs: s.easterEggs,
          gesture: s.gesture,
          lastPointerX: s.lastPointerX,
          lastPointerY: s.lastPointerY,
          pointerDown: s.pointerDown,
          showDebugOverlay: s.showDebugOverlay,
          paint: simulated,
          frameCount: s.frameCount + 1 | 0
        };
      }
      ;
      return s;
    };
  };
  var setTool = function(t) {
    return function(s) {
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        brush: s.brush,
        layers: s.layers,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        tool: t
      };
    };
  };
  var setPointerUp = function(s) {
    return {
      canvasBounds: s.canvasBounds,
      viewportState: s.viewportState,
      tool: s.tool,
      brush: s.brush,
      layers: s.layers,
      paint: s.paint,
      gravity: s.gravity,
      playing: s.playing,
      frameCount: s.frameCount,
      lastFrameTime: s.lastFrameTime,
      undoStack: s.undoStack,
      redoStack: s.redoStack,
      maxHistorySize: s.maxHistorySize,
      easterEggs: s.easterEggs,
      gesture: s.gesture,
      lastPointerX: s.lastPointerX,
      lastPointerY: s.lastPointerY,
      showDebugOverlay: s.showDebugOverlay,
      pointerDown: false
    };
  };
  var setPointerDown = function(x) {
    return function(y) {
      return function(s) {
        return {
          canvasBounds: s.canvasBounds,
          viewportState: s.viewportState,
          tool: s.tool,
          brush: s.brush,
          layers: s.layers,
          paint: s.paint,
          gravity: s.gravity,
          playing: s.playing,
          frameCount: s.frameCount,
          lastFrameTime: s.lastFrameTime,
          undoStack: s.undoStack,
          redoStack: s.redoStack,
          maxHistorySize: s.maxHistorySize,
          easterEggs: s.easterEggs,
          gesture: s.gesture,
          showDebugOverlay: s.showDebugOverlay,
          pointerDown: true,
          lastPointerX: x,
          lastPointerY: y
        };
      };
    };
  };
  var setLayerVisibility = function(lid) {
    return function(vis) {
      return function(s) {
        return {
          canvasBounds: s.canvasBounds,
          viewportState: s.viewportState,
          tool: s.tool,
          brush: s.brush,
          paint: s.paint,
          gravity: s.gravity,
          playing: s.playing,
          frameCount: s.frameCount,
          lastFrameTime: s.lastFrameTime,
          undoStack: s.undoStack,
          redoStack: s.redoStack,
          maxHistorySize: s.maxHistorySize,
          easterEggs: s.easterEggs,
          gesture: s.gesture,
          lastPointerX: s.lastPointerX,
          lastPointerY: s.lastPointerY,
          pointerDown: s.pointerDown,
          showDebugOverlay: s.showDebugOverlay,
          layers: updateLayer(lid)(setLayerVisible(vis))(s.layers)
        };
      };
    };
  };
  var toggleLayerVisibility = function(lid) {
    return function(s) {
      var v = getLayer(lid)(s.layers);
      if (v instanceof Nothing) {
        return s;
      }
      ;
      if (v instanceof Just) {
        var currentVis = layerVisible(v.value0);
        return setLayerVisibility(lid)(!currentVis)(s);
      }
      ;
      throw new Error("Failed pattern match at Canvas.State (line 697, column 3 - line 701, column 51): " + [v.constructor.name]);
    };
  };
  var setGravityEnabled2 = function(en) {
    return function(s) {
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        brush: s.brush,
        layers: s.layers,
        paint: s.paint,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        gravity: setGravityEnabled(en)(s.gravity)
      };
    };
  };
  var setBrushSize = function(sz) {
    return function(s) {
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        layers: s.layers,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        brush: {
          opacity: s.brush.opacity,
          color: s.brush.color,
          preset: s.brush.preset,
          spacing: s.brush.spacing,
          hardness: s.brush.hardness,
          size: max9(1)(min9(500)(sz))
        }
      };
    };
  };
  var setBrushPreset = function(p) {
    return function(s) {
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        layers: s.layers,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        brush: {
          size: s.brush.size,
          opacity: s.brush.opacity,
          color: s.brush.color,
          spacing: s.brush.spacing,
          hardness: s.brush.hardness,
          preset: p
        },
        paint: {
          particles: s.paint.particles,
          bounds: s.paint.bounds,
          smoothingRadius: s.paint.smoothingRadius,
          restDensity: s.paint.restDensity,
          stiffness: s.paint.stiffness,
          gravityX: s.paint.gravityX,
          gravityY: s.paint.gravityY,
          nextId: s.paint.nextId,
          preset: p
        }
      };
    };
  };
  var setBrushOpacity = function(op) {
    return function(s) {
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        layers: s.layers,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        brush: {
          size: s.brush.size,
          color: s.brush.color,
          preset: s.brush.preset,
          spacing: s.brush.spacing,
          hardness: s.brush.hardness,
          opacity: max9(0)(min9(1)(op))
        }
      };
    };
  };
  var setBrushColor = function(c) {
    return function(s) {
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        layers: s.layers,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        brush: {
          size: s.brush.size,
          opacity: s.brush.opacity,
          preset: s.brush.preset,
          spacing: s.brush.spacing,
          hardness: s.brush.hardness,
          color: c
        }
      };
    };
  };
  var setActiveLayer2 = function(lid) {
    return function(s) {
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        brush: s.brush,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        layers: setActiveLayer(lid)(s.layers)
      };
    };
  };
  var rotateViewport = function(deltaRotation) {
    return function(s) {
      return {
        canvasBounds: s.canvasBounds,
        tool: s.tool,
        brush: s.brush,
        layers: s.layers,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        viewportState: {
          panX: s.viewportState.panX,
          panY: s.viewportState.panY,
          scale: s.viewportState.scale,
          minScale: s.viewportState.minScale,
          maxScale: s.viewportState.maxScale,
          rotation: s.viewportState.rotation + deltaRotation
        }
      };
    };
  };
  var resetEasterEggs = function(s) {
    return {
      canvasBounds: s.canvasBounds,
      viewportState: s.viewportState,
      tool: s.tool,
      brush: s.brush,
      layers: s.layers,
      paint: s.paint,
      gravity: s.gravity,
      playing: s.playing,
      frameCount: s.frameCount,
      lastFrameTime: s.lastFrameTime,
      undoStack: s.undoStack,
      redoStack: s.redoStack,
      maxHistorySize: s.maxHistorySize,
      gesture: s.gesture,
      lastPointerX: s.lastPointerX,
      lastPointerY: s.lastPointerY,
      pointerDown: s.pointerDown,
      showDebugOverlay: s.showDebugOverlay,
      easterEggs: reset3(s.easterEggs)
    };
  };
  var removeLayer2 = function(lid) {
    return function(s) {
      var $79 = unwrapLayerId(lid) === 0;
      if ($79) {
        return s;
      }
      ;
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        brush: s.brush,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        layers: removeLayer(lid)(s.layers)
      };
    };
  };
  var redo = function(s) {
    var v = unsnoc(s.redoStack);
    if (v instanceof Nothing) {
      return s;
    }
    ;
    if (v instanceof Just) {
      var currentEntry = {
        layerStack: s.layers,
        label: "redo"
      };
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        brush: s.brush,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        layers: v.value0.last.layerStack,
        redoStack: v.value0.init,
        undoStack: snoc(s.undoStack)(currentEntry)
      };
    }
    ;
    throw new Error("Failed pattern match at Canvas.State (line 920, column 3 - line 930, column 12): " + [v.constructor.name]);
  };
  var pushHistory = function(label) {
    return function(s) {
      var entry = {
        layerStack: s.layers,
        label
      };
      var newUndo = snoc(s.undoStack)(entry);
      var trimmedUndo = (function() {
        var $84 = length(newUndo) > s.maxHistorySize;
        if ($84) {
          var v = unsnoc(newUndo);
          if (v instanceof Just) {
            return v.value0.init;
          }
          ;
          if (v instanceof Nothing) {
            return newUndo;
          }
          ;
          throw new Error("Failed pattern match at Canvas.State (line 893, column 14 - line 895, column 29): " + [v.constructor.name]);
        }
        ;
        return newUndo;
      })();
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        brush: s.brush,
        layers: s.layers,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        undoStack: trimmedUndo,
        redoStack: []
      };
    };
  };
  var processTwoFingerGesture = function(p1) {
    return function(p2) {
      return function(s) {
        var point2 = {
          x: p2.x,
          y: p2.y
        };
        var point1 = {
          x: p1.x,
          y: p1.y
        };
        var current = computeTwoFingerData(point1)(point2);
        if (s.gesture.active) {
          var scaleDelta = (function() {
            var $89 = s.gesture.lastDistance > 1e-3;
            if ($89) {
              return current.distance / s.gesture.lastDistance;
            }
            ;
            return 1;
          })();
          var newScale = max9(s.viewportState.minScale)(min9(s.viewportState.maxScale)(s.viewportState.scale * scaleDelta));
          var newGesture = {
            active: s.gesture.active,
            initialAngle: s.gesture.initialAngle,
            initialDistance: s.gesture.initialDistance,
            touchCount: s.gesture.touchCount,
            lastCenter: current.center,
            lastDistance: current.distance,
            lastAngle: current.angle
          };
          var dy = current.center.y - s.gesture.lastCenter.y;
          var dx = current.center.x - s.gesture.lastCenter.x;
          var angleDeltaDegrees = normalizeAngle(current.angle - s.gesture.lastAngle);
          var angleDeltaRadians = angleDeltaDegrees * 3.14159 / 180;
          return {
            canvasBounds: s.canvasBounds,
            tool: s.tool,
            brush: s.brush,
            layers: s.layers,
            paint: s.paint,
            gravity: s.gravity,
            playing: s.playing,
            frameCount: s.frameCount,
            lastFrameTime: s.lastFrameTime,
            undoStack: s.undoStack,
            redoStack: s.redoStack,
            maxHistorySize: s.maxHistorySize,
            easterEggs: s.easterEggs,
            lastPointerX: s.lastPointerX,
            lastPointerY: s.lastPointerY,
            pointerDown: s.pointerDown,
            showDebugOverlay: s.showDebugOverlay,
            gesture: newGesture,
            viewportState: {
              minScale: s.viewportState.minScale,
              maxScale: s.viewportState.maxScale,
              panX: s.viewportState.panX + dx,
              panY: s.viewportState.panY + dy,
              scale: newScale,
              rotation: s.viewportState.rotation + angleDeltaRadians
            }
          };
        }
        ;
        var newGesture = {
          active: true,
          touchCount: 2,
          initialDistance: current.distance,
          initialAngle: current.angle,
          lastCenter: current.center,
          lastDistance: current.distance,
          lastAngle: current.angle
        };
        return {
          canvasBounds: s.canvasBounds,
          viewportState: s.viewportState,
          tool: s.tool,
          brush: s.brush,
          layers: s.layers,
          paint: s.paint,
          gravity: s.gravity,
          playing: s.playing,
          frameCount: s.frameCount,
          lastFrameTime: s.lastFrameTime,
          undoStack: s.undoStack,
          redoStack: s.redoStack,
          maxHistorySize: s.maxHistorySize,
          easterEggs: s.easterEggs,
          lastPointerX: s.lastPointerX,
          lastPointerY: s.lastPointerY,
          pointerDown: s.pointerDown,
          showDebugOverlay: s.showDebugOverlay,
          gesture: newGesture
        };
      };
    };
  };
  var processEasterEggMotion = function(motion) {
    return function(s) {
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        brush: s.brush,
        layers: s.layers,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        easterEggs: processMotion2(motion)(s.easterEggs)
      };
    };
  };
  var processEasterEggKey = function(key) {
    return function(s) {
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        brush: s.brush,
        layers: s.layers,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        easterEggs: processKey2(key)(s.easterEggs)
      };
    };
  };
  var panViewport = function(dx) {
    return function(dy) {
      return function(s) {
        return {
          canvasBounds: s.canvasBounds,
          tool: s.tool,
          brush: s.brush,
          layers: s.layers,
          paint: s.paint,
          gravity: s.gravity,
          playing: s.playing,
          frameCount: s.frameCount,
          lastFrameTime: s.lastFrameTime,
          undoStack: s.undoStack,
          redoStack: s.redoStack,
          maxHistorySize: s.maxHistorySize,
          easterEggs: s.easterEggs,
          gesture: s.gesture,
          lastPointerX: s.lastPointerX,
          lastPointerY: s.lastPointerY,
          pointerDown: s.pointerDown,
          showDebugOverlay: s.showDebugOverlay,
          viewportState: {
            scale: s.viewportState.scale,
            rotation: s.viewportState.rotation,
            minScale: s.viewportState.minScale,
            maxScale: s.viewportState.maxScale,
            panX: s.viewportState.panX + dx,
            panY: s.viewportState.panY + dy
          }
        };
      };
    };
  };
  var paintSystem = function(s) {
    return s.paint;
  };
  var moveLayerUp2 = function(lid) {
    return function(s) {
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        brush: s.brush,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        layers: moveLayerUp(lid)(s.layers)
      };
    };
  };
  var moveLayerDown2 = function(lid) {
    return function(s) {
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        brush: s.brush,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        layers: moveLayerDown(lid)(s.layers)
      };
    };
  };
  var mkBrushConfig = function(sz) {
    return function(op) {
      return function(col) {
        return function(pre) {
          return {
            size: max9(1)(min9(500)(sz)),
            opacity: max9(0)(min9(1)(op)),
            color: col,
            preset: pre,
            spacing: 0.25,
            hardness: 0.8
          };
        };
      };
    };
  };
  var layerStack = function(s) {
    return s.layers;
  };
  var layerCount2 = function(s) {
    return layerCount(s.layers);
  };
  var isPlaying = function(s) {
    return s.playing;
  };
  var initialViewport = {
    panX: 0,
    panY: 0,
    scale: 1,
    rotation: 0,
    minScale: 0.1,
    maxScale: 10
  };
  var resetViewport = function(s) {
    return {
      canvasBounds: s.canvasBounds,
      tool: s.tool,
      brush: s.brush,
      layers: s.layers,
      paint: s.paint,
      gravity: s.gravity,
      playing: s.playing,
      frameCount: s.frameCount,
      lastFrameTime: s.lastFrameTime,
      undoStack: s.undoStack,
      redoStack: s.redoStack,
      maxHistorySize: s.maxHistorySize,
      easterEggs: s.easterEggs,
      gesture: s.gesture,
      lastPointerX: s.lastPointerX,
      lastPointerY: s.lastPointerY,
      pointerDown: s.pointerDown,
      showDebugOverlay: s.showDebugOverlay,
      viewportState: initialViewport
    };
  };
  var initialGestureTracking = {
    active: false,
    touchCount: 0,
    initialDistance: 0,
    initialAngle: 0,
    lastCenter: {
      x: 0,
      y: 0
    },
    lastDistance: 0,
    lastAngle: 0
  };
  var gravityState = function(s) {
    return s.gravity;
  };
  var endTwoFingerGesture = function(s) {
    return {
      canvasBounds: s.canvasBounds,
      viewportState: s.viewportState,
      tool: s.tool,
      brush: s.brush,
      layers: s.layers,
      paint: s.paint,
      gravity: s.gravity,
      playing: s.playing,
      frameCount: s.frameCount,
      lastFrameTime: s.lastFrameTime,
      undoStack: s.undoStack,
      redoStack: s.redoStack,
      maxHistorySize: s.maxHistorySize,
      easterEggs: s.easterEggs,
      lastPointerX: s.lastPointerX,
      lastPointerY: s.lastPointerY,
      pointerDown: s.pointerDown,
      showDebugOverlay: s.showDebugOverlay,
      gesture: initialGestureTracking
    };
  };
  var easterEggState = function(s) {
    return s.easterEggs;
  };
  var defaultBrushConfig = /* @__PURE__ */ (function() {
    return mkBrushConfig(20)(1)(colorBlack)(Watercolor.value);
  })();
  var mkAppState = function(width) {
    return function(height) {
      var bounds = mkBounds(0)(0)(width)(height);
      var defaultLayer = mkLayer(defaultLayerId)("Layer 1")(mkZIndex(1))(bounds);
      var bgLayer = mkLayer(backgroundLayerId)("Background")(mkZIndex(0))(bounds);
      return {
        canvasBounds: bounds,
        viewportState: initialViewport,
        tool: BrushTool.value,
        brush: defaultBrushConfig,
        layers: mkLayerStack([bgLayer, defaultLayer])(defaultLayerId),
        paint: mkPaintSystem(bounds)(Watercolor.value),
        gravity: initialGravityState,
        playing: false,
        frameCount: 0,
        lastFrameTime: 0,
        undoStack: [],
        redoStack: [],
        maxHistorySize: 50,
        easterEggs: initialState3,
        gesture: initialGestureTracking,
        lastPointerX: 0,
        lastPointerY: 0,
        pointerDown: false,
        showDebugOverlay: false
      };
    };
  };
  var initialAppState = /* @__PURE__ */ mkAppState(1920)(1080);
  var currentTool = function(s) {
    return s.tool;
  };
  var clearActiveLayer = function(s) {
    return {
      canvasBounds: s.canvasBounds,
      viewportState: s.viewportState,
      tool: s.tool,
      brush: s.brush,
      layers: s.layers,
      gravity: s.gravity,
      playing: s.playing,
      frameCount: s.frameCount,
      lastFrameTime: s.lastFrameTime,
      undoStack: s.undoStack,
      redoStack: s.redoStack,
      maxHistorySize: s.maxHistorySize,
      easterEggs: s.easterEggs,
      gesture: s.gesture,
      lastPointerX: s.lastPointerX,
      lastPointerY: s.lastPointerY,
      pointerDown: s.pointerDown,
      showDebugOverlay: s.showDebugOverlay,
      paint: clearParticles(s.paint)
    };
  };
  var canUndo = function(s) {
    return length(s.undoStack) > 0;
  };
  var canRedo = function(s) {
    return length(s.redoStack) > 0;
  };
  var brushConfig = function(s) {
    return s.brush;
  };
  var applyBrushDragFromPointer = function(cx) {
    return function(cy) {
      return function(pressure) {
        return function(s) {
          if (s.pointerDown) {
            var brushDrag = mkBrushDrag(cx)(cy)(s.lastPointerX)(s.lastPointerY)(s.brush.size * 1.5)(pressure);
            var withDrag = applyBrushDrag(brushDrag)(s.paint);
            return {
              canvasBounds: s.canvasBounds,
              viewportState: s.viewportState,
              tool: s.tool,
              brush: s.brush,
              layers: s.layers,
              gravity: s.gravity,
              playing: s.playing,
              frameCount: s.frameCount,
              lastFrameTime: s.lastFrameTime,
              undoStack: s.undoStack,
              redoStack: s.redoStack,
              maxHistorySize: s.maxHistorySize,
              easterEggs: s.easterEggs,
              gesture: s.gesture,
              pointerDown: s.pointerDown,
              showDebugOverlay: s.showDebugOverlay,
              paint: withDrag,
              lastPointerX: cx,
              lastPointerY: cy
            };
          }
          ;
          return {
            canvasBounds: s.canvasBounds,
            viewportState: s.viewportState,
            tool: s.tool,
            brush: s.brush,
            layers: s.layers,
            paint: s.paint,
            gravity: s.gravity,
            playing: s.playing,
            frameCount: s.frameCount,
            lastFrameTime: s.lastFrameTime,
            undoStack: s.undoStack,
            redoStack: s.redoStack,
            maxHistorySize: s.maxHistorySize,
            easterEggs: s.easterEggs,
            gesture: s.gesture,
            pointerDown: s.pointerDown,
            showDebugOverlay: s.showDebugOverlay,
            lastPointerX: cx,
            lastPointerY: cy
          };
        };
      };
    };
  };
  var addPaintParticleWithDynamics = function(px2) {
    return function(py) {
      return function(pressure) {
        return function(tiltX) {
          return function(tiltY) {
            return function(s) {
              var tiltOffsetY = tiltY / 18;
              var tiltOffsetX = tiltX / 18;
              var sizeMultiplier = 0.2 + pressure * 0.8;
              var effectiveY = py + tiltOffsetY;
              var effectiveX = px2 + tiltOffsetX;
              var effectiveSize = s.brush.size * sizeMultiplier;
              var effectiveOpacity = s.brush.opacity * pressure;
              var withSizedBrush = {
                canvasBounds: s.canvasBounds,
                easterEggs: s.easterEggs,
                frameCount: s.frameCount,
                gesture: s.gesture,
                gravity: s.gravity,
                lastFrameTime: s.lastFrameTime,
                lastPointerX: s.lastPointerX,
                lastPointerY: s.lastPointerY,
                layers: s.layers,
                maxHistorySize: s.maxHistorySize,
                paint: s.paint,
                playing: s.playing,
                pointerDown: s.pointerDown,
                redoStack: s.redoStack,
                showDebugOverlay: s.showDebugOverlay,
                tool: s.tool,
                undoStack: s.undoStack,
                viewportState: s.viewportState,
                brush: {
                  color: s.brush.color,
                  hardness: s.brush.hardness,
                  preset: s.brush.preset,
                  spacing: s.brush.spacing,
                  size: effectiveSize,
                  opacity: effectiveOpacity
                }
              };
              var withParticle = {
                brush: withSizedBrush.brush,
                canvasBounds: withSizedBrush.canvasBounds,
                easterEggs: withSizedBrush.easterEggs,
                frameCount: withSizedBrush.frameCount,
                gesture: withSizedBrush.gesture,
                gravity: withSizedBrush.gravity,
                lastFrameTime: withSizedBrush.lastFrameTime,
                lastPointerX: withSizedBrush.lastPointerX,
                lastPointerY: withSizedBrush.lastPointerY,
                layers: withSizedBrush.layers,
                maxHistorySize: withSizedBrush.maxHistorySize,
                playing: withSizedBrush.playing,
                pointerDown: withSizedBrush.pointerDown,
                redoStack: withSizedBrush.redoStack,
                showDebugOverlay: withSizedBrush.showDebugOverlay,
                tool: withSizedBrush.tool,
                undoStack: withSizedBrush.undoStack,
                viewportState: withSizedBrush.viewportState,
                paint: addParticle(withSizedBrush.paint)(effectiveX)(effectiveY)(s.brush.color)
              };
              var restored = {
                canvasBounds: withParticle.canvasBounds,
                easterEggs: withParticle.easterEggs,
                frameCount: withParticle.frameCount,
                gesture: withParticle.gesture,
                gravity: withParticle.gravity,
                lastFrameTime: withParticle.lastFrameTime,
                lastPointerX: withParticle.lastPointerX,
                lastPointerY: withParticle.lastPointerY,
                layers: withParticle.layers,
                maxHistorySize: withParticle.maxHistorySize,
                paint: withParticle.paint,
                playing: withParticle.playing,
                pointerDown: withParticle.pointerDown,
                redoStack: withParticle.redoStack,
                showDebugOverlay: withParticle.showDebugOverlay,
                tool: withParticle.tool,
                undoStack: withParticle.undoStack,
                viewportState: withParticle.viewportState,
                brush: s.brush
              };
              return restored;
            };
          };
        };
      };
    };
  };
  var addPaintParticle = function(px2) {
    return function(py) {
      return function(s) {
        return {
          canvasBounds: s.canvasBounds,
          viewportState: s.viewportState,
          tool: s.tool,
          brush: s.brush,
          layers: s.layers,
          gravity: s.gravity,
          playing: s.playing,
          frameCount: s.frameCount,
          lastFrameTime: s.lastFrameTime,
          undoStack: s.undoStack,
          redoStack: s.redoStack,
          maxHistorySize: s.maxHistorySize,
          easterEggs: s.easterEggs,
          gesture: s.gesture,
          lastPointerX: s.lastPointerX,
          lastPointerY: s.lastPointerY,
          pointerDown: s.pointerDown,
          showDebugOverlay: s.showDebugOverlay,
          paint: addParticle(s.paint)(px2)(py)(s.brush.color)
        };
      };
    };
  };
  var addLayer2 = function(name2) {
    return function(s) {
      var newZ = mkZIndex(layerCount(s.layers) + 1 | 0);
      var newId = mkLayerId(layerCount(s.layers) + 1 | 0);
      var newLayer = mkLayer(newId)(name2)(newZ)(s.canvasBounds);
      return {
        canvasBounds: s.canvasBounds,
        viewportState: s.viewportState,
        tool: s.tool,
        brush: s.brush,
        paint: s.paint,
        gravity: s.gravity,
        playing: s.playing,
        frameCount: s.frameCount,
        lastFrameTime: s.lastFrameTime,
        undoStack: s.undoStack,
        redoStack: s.redoStack,
        maxHistorySize: s.maxHistorySize,
        easterEggs: s.easterEggs,
        gesture: s.gesture,
        lastPointerX: s.lastPointerX,
        lastPointerY: s.lastPointerY,
        pointerDown: s.pointerDown,
        showDebugOverlay: s.showDebugOverlay,
        layers: addLayer(newLayer)(s.layers)
      };
    };
  };
  var activeLayerId = function(s) {
    return stackActiveLayerId(s.layers);
  };

  // output/Canvas.View/foreign.js
  var unsafeNumberToInt = (n) => Math.trunc(n);

  // output/Data.String.CodeUnits/foreign.js
  var toCharArray = function(s) {
    return s.split("");
  };
  var singleton5 = function(c) {
    return c;
  };
  var _charAt = function(just) {
    return function(nothing) {
      return function(i) {
        return function(s) {
          return i >= 0 && i < s.length ? just(s.charAt(i)) : nothing;
        };
      };
    };
  };

  // output/Data.String.CodeUnits/index.js
  var charAt2 = /* @__PURE__ */ (function() {
    return _charAt(Just.create)(Nothing.value);
  })();

  // output/Hydrogen.Math.Core.Trigonometry/index.js
  var abs4 = function(n) {
    var $24 = n < 0;
    if ($24) {
      return -n;
    }
    ;
    return n;
  };
  var atanGo = function($copy_sum) {
    return function($copy_term) {
      return function($copy_x2) {
        return function($copy_n) {
          var $tco_var_sum = $copy_sum;
          var $tco_var_term = $copy_term;
          var $tco_var_x2 = $copy_x2;
          var $tco_done = false;
          var $tco_result;
          function $tco_loop(sum2, term, x2, n) {
            if (n > 50) {
              $tco_done = true;
              return sum2;
            }
            ;
            if (otherwise) {
              var newTerm = -term * x2;
              var k = (2 * n | 0) + 1 | 0;
              var contrib = newTerm / toNumber(k);
              var newSum = sum2 + contrib;
              var $34 = abs4(contrib) < 1e-16 * abs4(newSum);
              if ($34) {
                $tco_done = true;
                return newSum;
              }
              ;
              $tco_var_sum = newSum;
              $tco_var_term = newTerm;
              $tco_var_x2 = x2;
              $copy_n = n + 1 | 0;
              return;
            }
            ;
            throw new Error("Failed pattern match at Hydrogen.Math.Core.Trigonometry (line 241, column 1 - line 241, column 54): " + [sum2.constructor.name, term.constructor.name, x2.constructor.name, n.constructor.name]);
          }
          ;
          while (!$tco_done) {
            $tco_result = $tco_loop($tco_var_sum, $tco_var_term, $tco_var_x2, $copy_n);
          }
          ;
          return $tco_result;
        };
      };
    };
  };
  var atanSmall = function(x) {
    return atanGo(x)(x)(x * x)(1);
  };
  var atan3 = function(x) {
    if ($$isNaN(x)) {
      return x;
    }
    ;
    if (x === infinity2) {
      return pi2 / 2;
    }
    ;
    if (x === negativeInfinity) {
      return -pi2 / 2;
    }
    ;
    if (abs4(x) > 1) {
      var $36 = x > 0;
      if ($36) {
        return pi2 / 2 - atanSmall(1 / x);
      }
      ;
      return -pi2 / 2 - atanSmall(1 / x);
    }
    ;
    if (otherwise) {
      return atanSmall(x);
    }
    ;
    throw new Error("Failed pattern match at Hydrogen.Math.Core.Trigonometry (line 226, column 1 - line 226, column 25): " + [x.constructor.name]);
  };
  var atan22 = function(y) {
    return function(x) {
      if ($$isNaN(x) || $$isNaN(y)) {
        return 0 / 0;
      }
      ;
      if (x > 0) {
        return atan3(y / x);
      }
      ;
      if (x < 0 && y >= 0) {
        return atan3(y / x) + pi2;
      }
      ;
      if (x < 0 && y < 0) {
        return atan3(y / x) - pi2;
      }
      ;
      if (x === 0 && y > 0) {
        return pi2 / 2;
      }
      ;
      if (x === 0 && y < 0) {
        return -pi2 / 2;
      }
      ;
      if (otherwise) {
        return 0;
      }
      ;
      throw new Error("Failed pattern match at Hydrogen.Math.Core.Trigonometry (line 254, column 1 - line 254, column 36): " + [y.constructor.name, x.constructor.name]);
    };
  };

  // output/Hydrogen.Render.Element.Events/index.js
  var onTouchStart = function($2) {
    return Handler.create(OnTouchStart.create($2));
  };
  var onTouchMove = function($3) {
    return Handler.create(OnTouchMove.create($3));
  };
  var onTouchEnd = function($4) {
    return Handler.create(OnTouchEnd.create($4));
  };
  var onMouseUp = function($8) {
    return Handler.create(OnMouseUp.create($8));
  };
  var onMouseMove = function($9) {
    return Handler.create(OnMouseMove.create($9));
  };
  var onMouseDown = function($12) {
    return Handler.create(OnMouseDown.create($12));
  };
  var onClick = function($26) {
    return Handler.create(OnClick.create($26));
  };

  // output/Hydrogen.Render.Element.SVG/index.js
  var svgElement = /* @__PURE__ */ (function() {
    return elementNS(SVG.value);
  })();
  var svg_ = /* @__PURE__ */ svgElement("svg");
  var circle_ = function(attrs) {
    return svgElement("circle")(attrs)([]);
  };

  // output/Data.Enum/foreign.js
  function toCharCode(c) {
    return c.charCodeAt(0);
  }
  function fromCharCode(c) {
    return String.fromCharCode(c);
  }

  // output/Data.Enum/index.js
  var bottom1 = /* @__PURE__ */ bottom(boundedChar);
  var top1 = /* @__PURE__ */ top(boundedChar);
  var fromEnum = function(dict) {
    return dict.fromEnum;
  };
  var defaultSucc = function(toEnum$prime) {
    return function(fromEnum$prime) {
      return function(a) {
        return toEnum$prime(fromEnum$prime(a) + 1 | 0);
      };
    };
  };
  var defaultPred = function(toEnum$prime) {
    return function(fromEnum$prime) {
      return function(a) {
        return toEnum$prime(fromEnum$prime(a) - 1 | 0);
      };
    };
  };
  var charToEnum = function(v) {
    if (v >= toCharCode(bottom1) && v <= toCharCode(top1)) {
      return new Just(fromCharCode(v));
    }
    ;
    return Nothing.value;
  };
  var enumChar = {
    succ: /* @__PURE__ */ defaultSucc(charToEnum)(toCharCode),
    pred: /* @__PURE__ */ defaultPred(charToEnum)(toCharCode),
    Ord0: function() {
      return ordChar;
    }
  };
  var boundedEnumChar = /* @__PURE__ */ (function() {
    return {
      cardinality: toCharCode(top1) - toCharCode(bottom1) | 0,
      toEnum: charToEnum,
      fromEnum: toCharCode,
      Bounded0: function() {
        return boundedChar;
      },
      Enum1: function() {
        return enumChar;
      }
    };
  })();

  // output/Data.Char/index.js
  var toCharCode2 = /* @__PURE__ */ fromEnum(boundedEnumChar);

  // output/Hydrogen.Schema.Attestation.SHA256/index.js
  var div2 = /* @__PURE__ */ div(euclideanRingInt);
  var zshr = function(v) {
    return function(v1) {
      if (v1 === 0) {
        return v;
      }
      ;
      return v >> v1 & ~((-1 | 0) << (32 - v1 | 0));
    };
  };
  var to32 = function(x) {
    return x | 0;
  };
  var splitBlocks = function(words) {
    var len = length(words);
    var extractBlock = function(start) {
      return function(arr) {
        return foldl2(function(acc) {
          return function(j) {
            return snoc(acc)(fromMaybe(0)(index(arr)(start + j | 0)));
          };
        })([])(range2(0)(15));
      };
    };
    var go = function($copy_i) {
      return function($copy_acc) {
        var $tco_var_i = $copy_i;
        var $tco_done = false;
        var $tco_result;
        function $tco_loop(i, acc) {
          if (i >= len) {
            $tco_done = true;
            return acc;
          }
          ;
          if (otherwise) {
            var block = extractBlock(i)(words);
            $tco_var_i = i + 16 | 0;
            $copy_acc = snoc(acc)(block);
            return;
          }
          ;
          throw new Error("Failed pattern match at Hydrogen.Schema.Attestation.SHA256 (line 424, column 3 - line 424, column 54): " + [i.constructor.name, acc.constructor.name]);
        }
        ;
        while (!$tco_done) {
          $tco_result = $tco_loop($tco_var_i, $copy_acc);
        }
        ;
        return $tco_result;
      };
    };
    return go(0)([]);
  };
  var roundConstants = /* @__PURE__ */ (function() {
    return [1116352408, 1899447441, -1245643825 | 0, -376229701 | 0, 961987163, 1508970993, -1841331548 | 0, -1424204075 | 0, -671266408 | 0, 310598401, 607225278, 1426881987, 1925078388, -2132889090 | 0, -1680079193 | 0, -1046744716 | 0, -459576895 | 0, -272742522 | 0, 264347078, 604807628, 770255983, 1249150122, 1555081692, 1996064986, -1740746414 | 0, -1473132947 | 0, -1341970488 | 0, -1084653625 | 0, -958395405 | 0, -710438585 | 0, 113926993, 338241895, 666307205, 773529912, 1294757372, 1396182291, 1695183700, 1986661051, -2117940946 | 0, -1838011259 | 0, -1564481375 | 0, -1474664885 | 0, -1035236496 | 0, -949202525 | 0, -778901479 | 0, -694614492 | 0, -200395387 | 0, 275423344, 430227734, 506948616, 659060556, 883997877, 958139571, 1322822218, 1537002063, 1747873779, 1955562222, 2024104815, -2067236844 | 0, -1933114872 | 0, -1866530822 | 0, -1538233109 | 0, -1090935817 | 0, -965641998 | 0];
  })();
  var rotateRight = function(n) {
    return function(x) {
      return zshr(x)(n) | x << (32 - n | 0);
    };
  };
  var smallSigma0 = function(x) {
    return rotateRight(7)(x) ^ rotateRight(18)(x) ^ zshr(x)(3);
  };
  var smallSigma1 = function(x) {
    return rotateRight(17)(x) ^ rotateRight(19)(x) ^ zshr(x)(10);
  };
  var padToMod64 = function(arr) {
    var len = length(arr);
    var target = (div2(len + 63 | 0)(64) * 64 | 0) - 8 | 0;
    var targetLen = (function() {
      var $29 = target < len;
      if ($29) {
        return target + 64 | 0;
      }
      ;
      return target;
    })();
    var padding = replicate(targetLen - len | 0)(0);
    return concat([arr, padding]);
  };
  var maj = function(x) {
    return function(y) {
      return function(z) {
        return x & y ^ x & z ^ y & z;
      };
    };
  };
  var int32ToBytes = function(n) {
    return [n >> 24 & 255, n >> 16 & 255, n >> 8 & 255, n & 255];
  };
  var padMessage = function(bytes) {
    var withOne = snoc(bytes)(128);
    var padded = padToMod64(withOne);
    var len = length(bytes);
    var bitLen = len * 8 | 0;
    return concat([padded, [0, 0, 0, 0], int32ToBytes(bitLen)]);
  };
  var wordsToBytes = /* @__PURE__ */ foldl2(function(acc) {
    return function(w) {
      return concat([acc, int32ToBytes(w)]);
    };
  })([]);
  var toBytes = function(v) {
    return wordsToBytes(v);
  };
  var h7Init = 1541459225;
  var h6Init = 528734635;
  var h5Init = /* @__PURE__ */ (function() {
    return -1694144372 | 0;
  })();
  var h4Init = 1359893119;
  var h3Init = /* @__PURE__ */ (function() {
    return -1521486534 | 0;
  })();
  var h2Init = 1013904242;
  var h1Init = /* @__PURE__ */ (function() {
    return -1150833019 | 0;
  })();
  var h0Init = 1779033703;
  var initState = {
    h0: h0Init,
    h1: h1Init,
    h2: h2Init,
    h3: h3Init,
    h4: h4Init,
    h5: h5Init,
    h6: h6Init,
    h7: h7Init
  };
  var ch = function(x) {
    return function(y) {
      return function(z) {
        return x & y ^ ~x & z;
      };
    };
  };
  var bytesToWord = function(b0) {
    return function(b1) {
      return function(b2) {
        return function(b3) {
          return b0 << 24 | b1 << 16 | b2 << 8 | b3;
        };
      };
    };
  };
  var bytesToWords = function(bytes) {
    var len = length(bytes);
    var go = function($copy_i) {
      return function($copy_acc) {
        var $tco_var_i = $copy_i;
        var $tco_done = false;
        var $tco_result;
        function $tco_loop(i, acc) {
          if ((i + 3 | 0) >= len) {
            $tco_done = true;
            return acc;
          }
          ;
          if (otherwise) {
            var b3 = fromMaybe(0)(index(bytes)(i + 3 | 0));
            var b2 = fromMaybe(0)(index(bytes)(i + 2 | 0));
            var b1 = fromMaybe(0)(index(bytes)(i + 1 | 0));
            var b0 = fromMaybe(0)(index(bytes)(i));
            var word = bytesToWord(b0)(b1)(b2)(b3);
            $tco_var_i = i + 4 | 0;
            $copy_acc = snoc(acc)(word);
            return;
          }
          ;
          throw new Error("Failed pattern match at Hydrogen.Schema.Attestation.SHA256 (line 383, column 3 - line 383, column 38): " + [i.constructor.name, acc.constructor.name]);
        }
        ;
        while (!$tco_done) {
          $tco_result = $tco_loop($tco_var_i, $copy_acc);
        }
        ;
        return $tco_result;
      };
    };
    return go(0)([]);
  };
  var bigSigma1 = function(x) {
    return rotateRight(6)(x) ^ rotateRight(11)(x) ^ rotateRight(25)(x);
  };
  var bigSigma0 = function(x) {
    return rotateRight(2)(x) ^ rotateRight(13)(x) ^ rotateRight(22)(x);
  };
  var add32 = function(a) {
    return function(b) {
      return to32(a + b | 0);
    };
  };
  var addMany32 = /* @__PURE__ */ foldl2(add32)(0);
  var expandBlock = function(block16) {
    var go = function($copy_i) {
      return function($copy_ws) {
        var $tco_var_i = $copy_i;
        var $tco_done = false;
        var $tco_result;
        function $tco_loop(i, ws) {
          if (i >= 64) {
            $tco_done = true;
            return ws;
          }
          ;
          if (otherwise) {
            var wi7 = fromMaybe(0)(index(ws)(i - 7 | 0));
            var wi2 = fromMaybe(0)(index(ws)(i - 2 | 0));
            var wi16 = fromMaybe(0)(index(ws)(i - 16 | 0));
            var wi15 = fromMaybe(0)(index(ws)(i - 15 | 0));
            var newW = addMany32([smallSigma1(wi2), wi7, smallSigma0(wi15), wi16]);
            $tco_var_i = i + 1 | 0;
            $copy_ws = snoc(ws)(newW);
            return;
          }
          ;
          throw new Error("Failed pattern match at Hydrogen.Schema.Attestation.SHA256 (line 235, column 3 - line 235, column 38): " + [i.constructor.name, ws.constructor.name]);
        }
        ;
        while (!$tco_done) {
          $tco_result = $tco_loop($tco_var_i, $copy_ws);
        }
        ;
        return $tco_result;
      };
    };
    return go(16)(block16);
  };
  var doRound = function(w) {
    return function(vars) {
      return function(t) {
        var wt = fromMaybe(0)(index(w)(t));
        var t2 = add32(bigSigma0(vars.a))(maj(vars.a)(vars.b)(vars.c));
        var kt = fromMaybe(0)(index(roundConstants)(t));
        var t1 = addMany32([vars.h, bigSigma1(vars.e), ch(vars.e)(vars.f)(vars.g), kt, wt]);
        return {
          a: add32(t1)(t2),
          b: vars.a,
          c: vars.b,
          d: vars.c,
          e: add32(vars.d)(t1),
          f: vars.e,
          g: vars.f,
          h: vars.g
        };
      };
    };
  };
  var processBlock = function(state2) {
    return function(block16) {
      var w = expandBlock(block16);
      var initial = {
        a: state2.h0,
        b: state2.h1,
        c: state2.h2,
        d: state2.h3,
        e: state2.h4,
        f: state2.h5,
        g: state2.h6,
        h: state2.h7
      };
      var $$final = foldl2(doRound(w))(initial)(range2(0)(63));
      return {
        h0: add32(state2.h0)($$final.a),
        h1: add32(state2.h1)($$final.b),
        h2: add32(state2.h2)($$final.c),
        h3: add32(state2.h3)($$final.d),
        h4: add32(state2.h4)($$final.e),
        h5: add32(state2.h5)($$final.f),
        h6: add32(state2.h6)($$final.g),
        h7: add32(state2.h7)($$final.h)
      };
    };
  };
  var sha256Bytes = function(bytes) {
    var padded = padMessage(bytes);
    var words = bytesToWords(padded);
    var blocks = splitBlocks(words);
    var finalState = foldl2(processBlock)(initState)(blocks);
    return [finalState.h0, finalState.h1, finalState.h2, finalState.h3, finalState.h4, finalState.h5, finalState.h6, finalState.h7];
  };

  // output/Hydrogen.Schema.Attestation.UUID5.Namespaces/index.js
  var nsElement = [109, 115, 103, 95, 104, 121, 100, 114, 111, 103, 101, 110, 46, 101, 108, 101];

  // output/Hydrogen.Schema.Attestation.UUID5/index.js
  var applyAt = function(idx) {
    return function(val) {
      return function(arr) {
        return foldl2(function(acc) {
          return function(i) {
            var v = (function() {
              var $27 = i === idx;
              if ($27) {
                return val;
              }
              ;
              return fromMaybe(0)(index(arr)(i));
            })();
            return snoc(acc)(v);
          };
        })([])(range2(0)(15));
      };
    };
  };
  var uuid5FromHash = function(hashBytes) {
    var bytes16 = slice(0)(16)(hashBytes);
    var byte8 = fromMaybe(0)(index(bytes16)(8));
    var byte8$prime = byte8 & 63 | 128;
    var byte6 = fromMaybe(0)(index(bytes16)(6));
    var byte6$prime = byte6 & 15 | 80;
    var result = applyAt(6)(byte6$prime)(applyAt(8)(byte8$prime)(bytes16));
    return result;
  };
  var uuid5Bytes = function(v) {
    return function(nameBytes) {
      var input = concat([v, nameBytes]);
      var hashBytes = toBytes(sha256Bytes(input));
      return uuid5FromHash(hashBytes);
    };
  };
  var uuid5 = function(namespace) {
    return function(name2) {
      var chars = toCharArray(name2);
      var nameBytes = foldl2(function(acc) {
        return function(c) {
          return snoc(acc)(toCharCode2(c));
        };
      })([])(chars);
      return uuid5Bytes(namespace)(nameBytes);
    };
  };

  // output/Hydrogen.Schema.Brush.Preset.Types/index.js
  var BuiltIn = /* @__PURE__ */ (function() {
    function BuiltIn2(value0) {
      this.value0 = value0;
    }
    ;
    BuiltIn2.create = function(value0) {
      return new BuiltIn2(value0);
    };
    return BuiltIn2;
  })();
  var Traditional = /* @__PURE__ */ (function() {
    function Traditional2() {
    }
    ;
    Traditional2.value = new Traditional2();
    return Traditional2;
  })();
  var DigitalNative = /* @__PURE__ */ (function() {
    function DigitalNative2() {
    }
    ;
    DigitalNative2.value = new DigitalNative2();
    return DigitalNative2;
  })();
  var Hybrid = /* @__PURE__ */ (function() {
    function Hybrid2() {
    }
    ;
    Hybrid2.value = new Hybrid2();
    return Hybrid2;
  })();
  var Expressive = /* @__PURE__ */ (function() {
    function Expressive2() {
    }
    ;
    Expressive2.value = new Expressive2();
    return Expressive2;
  })();
  var Utility = /* @__PURE__ */ (function() {
    function Utility2() {
    }
    ;
    Utility2.value = new Utility2();
    return Utility2;
  })();
  var Experimental = /* @__PURE__ */ (function() {
    function Experimental2() {
    }
    ;
    Experimental2.value = new Experimental2();
    return Experimental2;
  })();
  var nsPreset = /* @__PURE__ */ uuid5(nsElement)("hydrogen.brush.preset");
  var categoryToId = function(v) {
    if (v instanceof Traditional) {
      return "traditional";
    }
    ;
    if (v instanceof DigitalNative) {
      return "digital-native";
    }
    ;
    if (v instanceof Hybrid) {
      return "hybrid";
    }
    ;
    if (v instanceof Expressive) {
      return "expressive";
    }
    ;
    if (v instanceof Utility) {
      return "utility";
    }
    ;
    if (v instanceof Experimental) {
      return "experimental";
    }
    ;
    throw new Error("Failed pattern match at Hydrogen.Schema.Brush.Preset.Types (line 190, column 1 - line 190, column 41): " + [v.constructor.name]);
  };
  var mkPresetMeta = function(name2) {
    return function(category) {
      return function(provenance) {
        return function(tags) {
          return function(description) {
            return {
              name: name2,
              category,
              provenance,
              tags,
              description,
              uuid: uuid5(nsPreset)(name2 + (":" + categoryToId(category)))
            };
          };
        };
      };
    };
  };

  // output/Hydrogen.Schema.Brush.Preset.Library/index.js
  var watercolorWash = /* @__PURE__ */ (function() {
    return mkPresetMeta("Watercolor Wash")(Hybrid.value)(new BuiltIn("Hydrogen"))(["watercolor", "wash", "flat", "transparent", "sky"])("Even transparent wash \u2014 the foundation of watercolor. Let the paper glow.");
  })();
  var softRound = /* @__PURE__ */ (function() {
    return mkPresetMeta("Soft Round")(DigitalNative.value)(new BuiltIn("Hydrogen"))(["digital", "round", "soft", "blending", "painting"])("Soft edges for digital painting and blending.");
  })();
  var hbPencil = /* @__PURE__ */ (function() {
    return mkPresetMeta("HB Pencil")(Traditional.value)(new BuiltIn("Hydrogen"))(["pencil", "graphite", "sketch", "general", "medium"])("The standard pencil \u2014 not too light, not too dark. Good for everything.");
  })();
  var hardRound = /* @__PURE__ */ (function() {
    return mkPresetMeta("Hard Round")(DigitalNative.value)(new BuiltIn("Hydrogen"))(["digital", "round", "hard", "general", "workhorse"])("The default digital brush \u2014 pressure for size, clean edges.");
  })();
  var brushPen = /* @__PURE__ */ (function() {
    return mkPresetMeta("Brush Pen")(Traditional.value)(new BuiltIn("Hydrogen"))(["ink", "brush", "calligraphy", "expressive", "japanese"])("Flexible tip responds to pressure \u2014 from whisper-thin to bold.");
  })();
  var essentialsKit = [hbPencil, hardRound, softRound, brushPen, watercolorWash];

  // output/Hydrogen.Schema.Brush.WetMedia.Types/index.js
  var Watercolor2 = /* @__PURE__ */ (function() {
    function Watercolor3() {
    }
    ;
    Watercolor3.value = new Watercolor3();
    return Watercolor3;
  })();
  var OilPaint2 = /* @__PURE__ */ (function() {
    function OilPaint3() {
    }
    ;
    OilPaint3.value = new OilPaint3();
    return OilPaint3;
  })();
  var Acrylic2 = /* @__PURE__ */ (function() {
    function Acrylic3() {
    }
    ;
    Acrylic3.value = new Acrylic3();
    return Acrylic3;
  })();
  var Gouache2 = /* @__PURE__ */ (function() {
    function Gouache3() {
    }
    ;
    Gouache3.value = new Gouache3();
    return Gouache3;
  })();
  var Ink2 = /* @__PURE__ */ (function() {
    function Ink3() {
    }
    ;
    Ink3.value = new Ink3();
    return Ink3;
  })();
  var WetIntoWet = /* @__PURE__ */ (function() {
    function WetIntoWet2() {
    }
    ;
    WetIntoWet2.value = new WetIntoWet2();
    return WetIntoWet2;
  })();
  var wetMediaTypeDescription = function(v) {
    if (v instanceof Watercolor2) {
      return "Transparent, flows and pools, pigment settles in texture";
    }
    ;
    if (v instanceof OilPaint2) {
      return "Thick and buttery, blends smoothly, supports impasto";
    }
    ;
    if (v instanceof Acrylic2) {
      return "Quick-drying, versatile coverage, plastic finish";
    }
    ;
    if (v instanceof Gouache2) {
      return "Opaque watercolor, reactivates when wet, matte finish";
    }
    ;
    if (v instanceof Ink2) {
      return "Fluid and permanent, bleeds at edges, high contrast";
    }
    ;
    if (v instanceof WetIntoWet) {
      return "Painting into existing wet areas, aggressive blending";
    }
    ;
    throw new Error("Failed pattern match at Hydrogen.Schema.Brush.WetMedia.Types (line 112, column 1 - line 112, column 50): " + [v.constructor.name]);
  };
  var allWetMediaTypes = /* @__PURE__ */ (function() {
    return [Watercolor2.value, OilPaint2.value, Acrylic2.value, Gouache2.value, Ink2.value, WetIntoWet.value];
  })();

  // output/Canvas.View/index.js
  var eq2 = /* @__PURE__ */ eq(eqTool);
  var append2 = /* @__PURE__ */ append(semigroupArray);
  var show6 = /* @__PURE__ */ show(showTool);
  var show22 = /* @__PURE__ */ show(showNumber);
  var show42 = /* @__PURE__ */ show(showBoolean);
  var show52 = /* @__PURE__ */ show(showInt);
  var map8 = /* @__PURE__ */ map(functorArray);
  var eq12 = /* @__PURE__ */ eq(eqLayerId);
  var div13 = /* @__PURE__ */ div(euclideanRingInt);
  var ToolSelected = /* @__PURE__ */ (function() {
    function ToolSelected2(value0) {
      this.value0 = value0;
    }
    ;
    ToolSelected2.create = function(value0) {
      return new ToolSelected2(value0);
    };
    return ToolSelected2;
  })();
  var BrushPresetSelected = /* @__PURE__ */ (function() {
    function BrushPresetSelected2(value0) {
      this.value0 = value0;
    }
    ;
    BrushPresetSelected2.create = function(value0) {
      return new BrushPresetSelected2(value0);
    };
    return BrushPresetSelected2;
  })();
  var MediaTypeSelected = /* @__PURE__ */ (function() {
    function MediaTypeSelected2(value0) {
      this.value0 = value0;
    }
    ;
    MediaTypeSelected2.create = function(value0) {
      return new MediaTypeSelected2(value0);
    };
    return MediaTypeSelected2;
  })();
  var ColorChanged = /* @__PURE__ */ (function() {
    function ColorChanged2(value0) {
      this.value0 = value0;
    }
    ;
    ColorChanged2.create = function(value0) {
      return new ColorChanged2(value0);
    };
    return ColorChanged2;
  })();
  var BrushSizeChanged = /* @__PURE__ */ (function() {
    function BrushSizeChanged2(value0) {
      this.value0 = value0;
    }
    ;
    BrushSizeChanged2.create = function(value0) {
      return new BrushSizeChanged2(value0);
    };
    return BrushSizeChanged2;
  })();
  var BrushOpacityChanged = /* @__PURE__ */ (function() {
    function BrushOpacityChanged2(value0) {
      this.value0 = value0;
    }
    ;
    BrushOpacityChanged2.create = function(value0) {
      return new BrushOpacityChanged2(value0);
    };
    return BrushOpacityChanged2;
  })();
  var PointerDown = /* @__PURE__ */ (function() {
    function PointerDown2(value0) {
      this.value0 = value0;
    }
    ;
    PointerDown2.create = function(value0) {
      return new PointerDown2(value0);
    };
    return PointerDown2;
  })();
  var PointerMoved = /* @__PURE__ */ (function() {
    function PointerMoved2(value0) {
      this.value0 = value0;
    }
    ;
    PointerMoved2.create = function(value0) {
      return new PointerMoved2(value0);
    };
    return PointerMoved2;
  })();
  var PointerUp = /* @__PURE__ */ (function() {
    function PointerUp2() {
    }
    ;
    PointerUp2.value = new PointerUp2();
    return PointerUp2;
  })();
  var CanvasTouched = /* @__PURE__ */ (function() {
    function CanvasTouched2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    CanvasTouched2.create = function(value0) {
      return function(value1) {
        return new CanvasTouched2(value0, value1);
      };
    };
    return CanvasTouched2;
  })();
  var CanvasMoved = /* @__PURE__ */ (function() {
    function CanvasMoved2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    CanvasMoved2.create = function(value0) {
      return function(value1) {
        return new CanvasMoved2(value0, value1);
      };
    };
    return CanvasMoved2;
  })();
  var CanvasReleased = /* @__PURE__ */ (function() {
    function CanvasReleased2() {
    }
    ;
    CanvasReleased2.value = new CanvasReleased2();
    return CanvasReleased2;
  })();
  var OrientationChanged = /* @__PURE__ */ (function() {
    function OrientationChanged2(value0) {
      this.value0 = value0;
    }
    ;
    OrientationChanged2.create = function(value0) {
      return new OrientationChanged2(value0);
    };
    return OrientationChanged2;
  })();
  var ToggleGravity = /* @__PURE__ */ (function() {
    function ToggleGravity2() {
    }
    ;
    ToggleGravity2.value = new ToggleGravity2();
    return ToggleGravity2;
  })();
  var TogglePlaying = /* @__PURE__ */ (function() {
    function TogglePlaying2() {
    }
    ;
    TogglePlaying2.value = new TogglePlaying2();
    return TogglePlaying2;
  })();
  var ClearCanvas = /* @__PURE__ */ (function() {
    function ClearCanvas2() {
    }
    ;
    ClearCanvas2.value = new ClearCanvas2();
    return ClearCanvas2;
  })();
  var Undo = /* @__PURE__ */ (function() {
    function Undo2() {
    }
    ;
    Undo2.value = new Undo2();
    return Undo2;
  })();
  var Redo = /* @__PURE__ */ (function() {
    function Redo2() {
    }
    ;
    Redo2.value = new Redo2();
    return Redo2;
  })();
  var Tick = /* @__PURE__ */ (function() {
    function Tick2(value0) {
      this.value0 = value0;
    }
    ;
    Tick2.create = function(value0) {
      return new Tick2(value0);
    };
    return Tick2;
  })();
  var LayerSelected = /* @__PURE__ */ (function() {
    function LayerSelected2(value0) {
      this.value0 = value0;
    }
    ;
    LayerSelected2.create = function(value0) {
      return new LayerSelected2(value0);
    };
    return LayerSelected2;
  })();
  var AddLayer = /* @__PURE__ */ (function() {
    function AddLayer2() {
    }
    ;
    AddLayer2.value = new AddLayer2();
    return AddLayer2;
  })();
  var LayerVisibilityToggled = /* @__PURE__ */ (function() {
    function LayerVisibilityToggled2(value0) {
      this.value0 = value0;
    }
    ;
    LayerVisibilityToggled2.create = function(value0) {
      return new LayerVisibilityToggled2(value0);
    };
    return LayerVisibilityToggled2;
  })();
  var DeleteLayer = /* @__PURE__ */ (function() {
    function DeleteLayer2(value0) {
      this.value0 = value0;
    }
    ;
    DeleteLayer2.create = function(value0) {
      return new DeleteLayer2(value0);
    };
    return DeleteLayer2;
  })();
  var MoveLayerUp = /* @__PURE__ */ (function() {
    function MoveLayerUp2(value0) {
      this.value0 = value0;
    }
    ;
    MoveLayerUp2.create = function(value0) {
      return new MoveLayerUp2(value0);
    };
    return MoveLayerUp2;
  })();
  var MoveLayerDown = /* @__PURE__ */ (function() {
    function MoveLayerDown2(value0) {
      this.value0 = value0;
    }
    ;
    MoveLayerDown2.create = function(value0) {
      return new MoveLayerDown2(value0);
    };
    return MoveLayerDown2;
  })();
  var KeyDown = /* @__PURE__ */ (function() {
    function KeyDown2(value0) {
      this.value0 = value0;
    }
    ;
    KeyDown2.create = function(value0) {
      return new KeyDown2(value0);
    };
    return KeyDown2;
  })();
  var KeyboardShortcut = /* @__PURE__ */ (function() {
    function KeyboardShortcut2(value0) {
      this.value0 = value0;
    }
    ;
    KeyboardShortcut2.create = function(value0) {
      return new KeyboardShortcut2(value0);
    };
    return KeyboardShortcut2;
  })();
  var DeviceMotion = /* @__PURE__ */ (function() {
    function DeviceMotion2(value0) {
      this.value0 = value0;
    }
    ;
    DeviceMotion2.create = function(value0) {
      return new DeviceMotion2(value0);
    };
    return DeviceMotion2;
  })();
  var ViewportPan = /* @__PURE__ */ (function() {
    function ViewportPan2(value0, value1) {
      this.value0 = value0;
      this.value1 = value1;
    }
    ;
    ViewportPan2.create = function(value0) {
      return function(value1) {
        return new ViewportPan2(value0, value1);
      };
    };
    return ViewportPan2;
  })();
  var ViewportZoom = /* @__PURE__ */ (function() {
    function ViewportZoom2(value0) {
      this.value0 = value0;
    }
    ;
    ViewportZoom2.create = function(value0) {
      return new ViewportZoom2(value0);
    };
    return ViewportZoom2;
  })();
  var ViewportZoomAt = /* @__PURE__ */ (function() {
    function ViewportZoomAt2(value0, value1, value2) {
      this.value0 = value0;
      this.value1 = value1;
      this.value2 = value2;
    }
    ;
    ViewportZoomAt2.create = function(value0) {
      return function(value1) {
        return function(value2) {
          return new ViewportZoomAt2(value0, value1, value2);
        };
      };
    };
    return ViewportZoomAt2;
  })();
  var ViewportRotate = /* @__PURE__ */ (function() {
    function ViewportRotate2(value0) {
      this.value0 = value0;
    }
    ;
    ViewportRotate2.create = function(value0) {
      return new ViewportRotate2(value0);
    };
    return ViewportRotate2;
  })();
  var ViewportReset = /* @__PURE__ */ (function() {
    function ViewportReset2() {
    }
    ;
    ViewportReset2.value = new ViewportReset2();
    return ViewportReset2;
  })();
  var TwoFingerTouch = /* @__PURE__ */ (function() {
    function TwoFingerTouch2(value0) {
      this.value0 = value0;
    }
    ;
    TwoFingerTouch2.create = function(value0) {
      return new TwoFingerTouch2(value0);
    };
    return TwoFingerTouch2;
  })();
  var TwoFingerEnd = /* @__PURE__ */ (function() {
    function TwoFingerEnd2() {
    }
    ;
    TwoFingerEnd2.value = new TwoFingerEnd2();
    return TwoFingerEnd2;
  })();
  var ExportCanvas = /* @__PURE__ */ (function() {
    function ExportCanvas2(value0) {
      this.value0 = value0;
    }
    ;
    ExportCanvas2.create = function(value0) {
      return new ExportCanvas2(value0);
    };
    return ExportCanvas2;
  })();
  var truncateDecimals = function(s) {
    return function(_maxDecimals) {
      return s;
    };
  };
  var toolButton = function(tool) {
    return function(label) {
      return function(description) {
        return function(state2) {
          var isActive2 = eq2(currentTool(state2))(tool);
          var activeClass = (function() {
            if (isActive2) {
              return "tool-btn active";
            }
            ;
            return "tool-btn";
          })();
          return button_(append2([class_(activeClass), onClick(new ToolSelected(tool)), ariaLabel(description), attr("aria-pressed")((function() {
            if (isActive2) {
              return "true";
            }
            ;
            return "false";
          })())])(styles([new Tuple("padding", "8px 12px"), new Tuple("border", "none"), new Tuple("border-radius", "4px"), new Tuple("background", (function() {
            if (isActive2) {
              return "#4a4a6a";
            }
            ;
            return "#2a2a4e";
          })()), new Tuple("color", "#fff"), new Tuple("cursor", "pointer")])))([text(label)]);
        };
      };
    };
  };
  var stepForRange = function(minVal) {
    return function(maxVal) {
      var range3 = maxVal - minVal;
      var $99 = range3 > 100;
      if ($99) {
        return 10;
      }
      ;
      var $100 = range3 > 10;
      if ($100) {
        return 1;
      }
      ;
      return 0.1;
    };
  };
  var shortPresetName = function(name2) {
    return name2;
  };
  var renderToolButtons = function(state2) {
    return div_(append2([class_("tool-buttons"), role("group"), ariaLabel("Drawing tools")])(styles([new Tuple("display", "flex"), new Tuple("gap", "4px")])))([toolButton(BrushTool.value)("Brush")("Paint brush tool")(state2), toolButton(EraserTool.value)("Eraser")("Eraser tool")(state2), toolButton(PanTool.value)("Pan")("Pan and move canvas")(state2), toolButton(EyedropperTool.value)("Pick")("Color picker tool")(state2)]);
  };
  var renderStatusBar = function(state2) {
    var particleCount2 = particleCount(paintSystem(state2));
    return div_(append2([class_("canvas-statusbar"), role("contentinfo"), ariaLabel("Canvas status"), ariaLive("polite"), ariaAtomic("false")])(styles([new Tuple("display", "flex"), new Tuple("gap", "16px"), new Tuple("padding", "4px 8px"), new Tuple("background", "#1a1a2e"), new Tuple("border-top", "1px solid #333"), new Tuple("font-size", "11px"), new Tuple("color", "#888")])))([span_([ariaLabel("Particle count: " + show52(particleCount2))])([text("Particles: " + show52(particleCount2))]), span_([ariaLabel("Layer count: " + show52(layerCount2(state2)))])([text("Layers: " + show52(layerCount2(state2)))]), span_(append2([id_("gpu-backend"), ariaLabel("GPU rendering backend")])(styles([new Tuple("color", "#4a9eff"), new Tuple("font-weight", "bold")])))([text("GPU: Detecting...")]), span_([])([text((function() {
      var $133 = canUndo(state2);
      if ($133) {
        return "Undo available";
      }
      ;
      return "";
    })())])]);
  };
  var renderSingleParticle = function(p) {
    var radius = particleRadius(p);
    var pos = particlePosition(p);
    var color = particleColorHex(p);
    return circle_([attr("cx")(show22(pos.x)), attr("cy")(show22(pos.y)), attr("r")(show22(radius)), attr("fill")(color), attr("opacity")("0.8")]);
  };
  var renderParticlesSVGFallback = function(state2) {
    var particles = allParticles(paintSystem(state2));
    return svg_(append2([id_("paint-svg-fallback"), class_("svg-particles-fallback")])(styles([new Tuple("position", "absolute"), new Tuple("top", "0"), new Tuple("left", "0"), new Tuple("width", "100%"), new Tuple("height", "100%"), new Tuple("pointer-events", "none"), new Tuple("display", "none")])))(map8(renderSingleParticle)(particles));
  };
  var renderLayerItem = function(activeId) {
    return function(totalLayers) {
      return function(layer) {
        var lid = layerId(layer);
        var isVisible = layerVisible(layer);
        var textColor = (function() {
          if (isVisible) {
            return "#fff";
          }
          ;
          return "#666";
        })();
        var isBackground = eq12(lid)(backgroundLayerId);
        var isActive2 = eq12(lid)(activeId);
        var bgColor = (function() {
          if (isActive2) {
            return "#4a4a6a";
          }
          ;
          return "#2a2a4e";
        })();
        return div_(append2([class_("layer-item")])(styles([new Tuple("display", "flex"), new Tuple("align-items", "center"), new Tuple("gap", "4px"), new Tuple("padding", "4px 6px"), new Tuple("border-radius", "3px"), new Tuple("background", bgColor)])))([button_(append2([class_("visibility-btn"), onClick(new LayerVisibilityToggled(lid)), title((function() {
          if (isVisible) {
            return "Hide layer";
          }
          ;
          return "Show layer";
        })())])(styles([new Tuple("width", "16px"), new Tuple("height", "16px"), new Tuple("border", "none"), new Tuple("border-radius", "3px"), new Tuple("background", (function() {
          if (isVisible) {
            return "#0a0";
          }
          ;
          return "#333";
        })()), new Tuple("cursor", "pointer"), new Tuple("padding", "0")])))([]), button_(append2([class_("layer-name"), onClick(new LayerSelected(lid)), title(layerName(layer))])(styles([new Tuple("flex", "1"), new Tuple("border", "none"), new Tuple("background", "transparent"), new Tuple("color", textColor), new Tuple("cursor", "pointer"), new Tuple("text-align", "left"), new Tuple("padding", "2px 4px"), new Tuple("overflow", "hidden"), new Tuple("text-overflow", "ellipsis"), new Tuple("white-space", "nowrap")])))([text(layerName(layer))]), (function() {
          var $138 = totalLayers > 1 && !isBackground;
          if ($138) {
            return div_(styles([new Tuple("display", "flex"), new Tuple("gap", "2px")]))([button_(append2([class_("move-up-btn"), onClick(new MoveLayerUp(lid)), title("Move layer up")])(styles([new Tuple("width", "16px"), new Tuple("height", "16px"), new Tuple("border", "none"), new Tuple("border-radius", "2px"), new Tuple("background", "#3a3a5e"), new Tuple("color", "#ccc"), new Tuple("cursor", "pointer"), new Tuple("font-size", "10px"), new Tuple("padding", "0")])))([text("^")]), button_(append2([class_("move-down-btn"), onClick(new MoveLayerDown(lid)), title("Move layer down")])(styles([new Tuple("width", "16px"), new Tuple("height", "16px"), new Tuple("border", "none"), new Tuple("border-radius", "2px"), new Tuple("background", "#3a3a5e"), new Tuple("color", "#ccc"), new Tuple("cursor", "pointer"), new Tuple("font-size", "10px"), new Tuple("padding", "0")])))([text("v")]), button_(append2([class_("delete-layer-btn"), onClick(new DeleteLayer(lid)), title("Delete layer")])(styles([new Tuple("width", "16px"), new Tuple("height", "16px"), new Tuple("border", "none"), new Tuple("border-radius", "2px"), new Tuple("background", "#5a2a2e"), new Tuple("color", "#f88"), new Tuple("cursor", "pointer"), new Tuple("font-size", "10px"), new Tuple("padding", "0")])))([text("x")])]);
          }
          ;
          return text("");
        })()]);
      };
    };
  };
  var renderLayerPanel = function(state2) {
    var stack = layerStack(state2);
    var layers = sortedLayers(stack);
    var layerCount3 = length(layers);
    var activeId = activeLayerId(state2);
    return div_(append2([class_("layer-panel"), role("complementary"), ariaLabel("Layer panel")])(styles([new Tuple("width", "180px"), new Tuple("padding", "8px"), new Tuple("background", "#1a1a2e"), new Tuple("border-left", "1px solid #333"), new Tuple("font-size", "11px"), new Tuple("display", "flex"), new Tuple("flex-direction", "column"), new Tuple("gap", "8px")])))([div_(styles([new Tuple("display", "flex"), new Tuple("justify-content", "space-between"), new Tuple("align-items", "center")]))([span_(styles([new Tuple("color", "#888"), new Tuple("font-weight", "bold")]))([text("Layers")]), button_(append2([class_("add-layer-btn"), onClick(AddLayer.value), title("Add new layer"), ariaLabel("Add new layer")])(styles([new Tuple("padding", "4px 8px"), new Tuple("border", "none"), new Tuple("border-radius", "3px"), new Tuple("background", "#3a3a5e"), new Tuple("color", "#ccc"), new Tuple("cursor", "pointer"), new Tuple("font-size", "12px")])))([text("+")])]), div_(append2([class_("layer-list"), role("list"), ariaLabel("Layer stack with " + (show52(layerCount3) + " layers"))])(styles([new Tuple("display", "flex"), new Tuple("flex-direction", "column"), new Tuple("gap", "2px"), new Tuple("flex", "1"), new Tuple("overflow-y", "auto")])))(map8(renderLayerItem(activeId)(layerCount3))(layers))]);
  };
  var renderGPUCanvas = function(_state) {
    return canvas_(append2([id_("paint-canvas"), class_("gpu-canvas")])(styles([new Tuple("position", "absolute"), new Tuple("top", "0"), new Tuple("left", "0"), new Tuple("width", "100%"), new Tuple("height", "100%"), new Tuple("pointer-events", "none")])));
  };
  var renderPaintLayers = function(state2) {
    return div_(append2([class_("paint-layers")])(styles([new Tuple("position", "absolute"), new Tuple("top", "0"), new Tuple("left", "0"), new Tuple("width", "100%"), new Tuple("height", "100%")])))([renderGPUCanvas(state2), renderParticlesSVGFallback(state2)]);
  };
  var renderDebugOverlay = function(state2) {
    var particleCount2 = particleCount(paintSystem(state2));
    var layerCt = layerCount2(state2);
    var gravState = gravityState(state2);
    var gravVector = currentGravity(gravState);
    var gx = gravityX(gravVector);
    var gy = gravityY(gravVector);
    var gz = gravityZ(gravVector);
    var isUpsideDown = gz > 0.3;
    var paintPressure = (function() {
      if (isUpsideDown) {
        return "ONTO GLASS";
      }
      ;
      var $140 = gz < -0.3;
      if ($140) {
        return "Into glass";
      }
      ;
      return "Neutral";
    })();
    var magnitude = gravityMagnitude(gravVector);
    return div_(append2([class_("debug-overlay")])(styles([new Tuple("position", "absolute"), new Tuple("bottom", "8px"), new Tuple("left", "8px"), new Tuple("padding", "8px"), new Tuple("background", (function() {
      if (isUpsideDown) {
        return "rgba(233,69,96,0.8)";
      }
      ;
      return "rgba(0,0,0,0.7)";
    })()), new Tuple("color", (function() {
      if (isUpsideDown) {
        return "#fff";
      }
      ;
      return "#0f0";
    })()), new Tuple("font-family", "monospace"), new Tuple("font-size", "11px"), new Tuple("border-radius", "4px"), new Tuple("pointer-events", "none")])))([div_([])([text("Particles: " + show52(particleCount2))]), div_([])([text("Layers: " + show52(layerCt))]), div_([])([text("Gravity X: " + show22(gx))]), div_([])([text("Gravity Y: " + show22(gy))]), div_([])([text("Gravity Z: " + (show22(gz) + (" [" + (paintPressure + "]"))))]), div_([])([text("Gravity Mag: " + (show22(magnitude) + "g"))]), div_([])([text("Playing: " + show42(isPlaying(state2)))]), div_([])([text("Tool: " + show6(currentTool(state2)))])]);
  };
  var renderConfettiOverlay = function(state2) {
    return renderConfetti(easterEggState(state2));
  };
  var percentValue = function(current) {
    return function(minVal) {
      return function(maxVal) {
        return (current - minVal) / (maxVal - minVal) * 100;
      };
    };
  };
  var numberToInt = function(n) {
    return unsafeNumberToInt(n);
  };
  var mediaLabel = function(v) {
    if (v instanceof Watercolor2) {
      return "WC";
    }
    ;
    if (v instanceof OilPaint2) {
      return "Oil";
    }
    ;
    if (v instanceof Acrylic2) {
      return "Acr";
    }
    ;
    if (v instanceof Gouache2) {
      return "Gou";
    }
    ;
    if (v instanceof Ink2) {
      return "Ink";
    }
    ;
    if (v instanceof WetIntoWet) {
      return "W/W";
    }
    ;
    throw new Error("Failed pattern match at Canvas.View (line 595, column 1 - line 595, column 37): " + [v.constructor.name]);
  };
  var mediaButton = function(mediaType) {
    return button_(append2([class_("media-btn"), onClick(new MediaTypeSelected(mediaType)), title(wetMediaTypeDescription(mediaType))])(styles([new Tuple("padding", "4px 8px"), new Tuple("border", "none"), new Tuple("border-radius", "3px"), new Tuple("background", "#3a3a5e"), new Tuple("color", "#ccc"), new Tuple("font-size", "11px"), new Tuple("cursor", "pointer")])))([text(mediaLabel(mediaType))]);
  };
  var renderMediaSelector = function(_state) {
    return div_(append2([class_("media-selector")])(styles([new Tuple("display", "flex"), new Tuple("flex-direction", "column"), new Tuple("gap", "2px")])))([span_(styles([new Tuple("font-size", "10px"), new Tuple("color", "#888")]))([text("Media")]), div_(styles([new Tuple("display", "flex"), new Tuple("gap", "2px"), new Tuple("flex-wrap", "wrap")]))(map8(mediaButton)(allWetMediaTypes))]);
  };
  var formatNumber = function(n) {
    var s = show22(n);
    return truncateDecimals(s)(1);
  };
  var colorPresets = [{
    r: 0,
    g: 0,
    b: 0,
    a: 1
  }, {
    r: 0.25,
    g: 0.25,
    b: 0.25,
    a: 1
  }, {
    r: 0.5,
    g: 0.5,
    b: 0.5,
    a: 1
  }, {
    r: 0.75,
    g: 0.75,
    b: 0.75,
    a: 1
  }, {
    r: 1,
    g: 1,
    b: 1,
    a: 1
  }, {
    r: 1,
    g: 0,
    b: 0,
    a: 1
  }, {
    r: 1,
    g: 0.5,
    b: 0,
    a: 1
  }, {
    r: 1,
    g: 1,
    b: 0,
    a: 1
  }, {
    r: 0,
    g: 1,
    b: 0,
    a: 1
  }, {
    r: 0,
    g: 0,
    b: 1,
    a: 1
  }, {
    r: 0.5,
    g: 0,
    b: 0.5,
    a: 1
  }, {
    r: 1,
    g: 0,
    b: 1,
    a: 1
  }, {
    r: 0,
    g: 1,
    b: 1,
    a: 1
  }, {
    r: 0.6,
    g: 0.4,
    b: 0.2,
    a: 1
  }, {
    r: 1,
    g: 0.75,
    b: 0.8,
    a: 1
  }];
  var clampNumber2 = function(val) {
    return function(minVal) {
      return function(maxVal) {
        var $208 = val < minVal;
        if ($208) {
          return minVal;
        }
        ;
        var $209 = val > maxVal;
        if ($209) {
          return maxVal;
        }
        ;
        return val;
      };
    };
  };
  var renderSliderControl = function(label) {
    return function(description) {
      return function(currentVal) {
        return function(minVal) {
          return function(maxVal) {
            return function(toMsg) {
              return div_(append2([class_("slider-control"), role("group"), ariaLabel(description)])(styles([new Tuple("display", "flex"), new Tuple("flex-direction", "column"), new Tuple("gap", "4px")])))([div_(styles([new Tuple("display", "flex"), new Tuple("justify-content", "space-between")]))([span_(styles([new Tuple("color", "#aaa")]))([text(label)]), span_(styles([new Tuple("color", "#fff")]))([text(formatNumber(currentVal))])]), div_(styles([new Tuple("display", "flex"), new Tuple("gap", "4px"), new Tuple("align-items", "center")]))([button_(append2([class_("slider-btn"), onClick(toMsg(clampNumber2(currentVal - stepForRange(minVal)(maxVal))(minVal)(maxVal))), ariaLabel("Decrease " + label)])(styles([new Tuple("width", "24px"), new Tuple("height", "24px"), new Tuple("border", "none"), new Tuple("border-radius", "4px"), new Tuple("background", "#3a3a5e"), new Tuple("color", "#fff"), new Tuple("cursor", "pointer")])))([text("-")]), div_(append2([role("progressbar"), attr("aria-valuenow")(show22(currentVal)), attr("aria-valuemin")(show22(minVal)), attr("aria-valuemax")(show22(maxVal)), ariaLabel(label + (" value: " + formatNumber(currentVal)))])(styles([new Tuple("flex", "1"), new Tuple("height", "8px"), new Tuple("background", "#2a2a4e"), new Tuple("border-radius", "4px"), new Tuple("overflow", "hidden")])))([div_(styles([new Tuple("width", show22(percentValue(currentVal)(minVal)(maxVal)) + "%"), new Tuple("height", "100%"), new Tuple("background", "#6a6aaa")]))([])]), button_(append2([class_("slider-btn"), onClick(toMsg(clampNumber2(currentVal + stepForRange(minVal)(maxVal))(minVal)(maxVal))), ariaLabel("Increase " + label)])(styles([new Tuple("width", "24px"), new Tuple("height", "24px"), new Tuple("border", "none"), new Tuple("border-radius", "4px"), new Tuple("background", "#3a3a5e"), new Tuple("color", "#fff"), new Tuple("cursor", "pointer")])))([text("+")])])]);
            };
          };
        };
      };
    };
  };
  var clampInt2 = function(n) {
    return function(minVal) {
      return function(maxVal) {
        var i = numberToInt(n);
        var $210 = i < minVal;
        if ($210) {
          return minVal;
        }
        ;
        var $211 = i > maxVal;
        if ($211) {
          return maxVal;
        }
        ;
        return i;
      };
    };
  };
  var charAtIndex = function(idx) {
    return function(str) {
      var v = charAt2(idx)(str);
      if (v instanceof Nothing) {
        return "0";
      }
      ;
      if (v instanceof Just) {
        return singleton5(v.value0);
      }
      ;
      throw new Error("Failed pattern match at Canvas.View (line 1387, column 3 - line 1389, column 30): " + [v.constructor.name]);
    };
  };
  var intToHex = function(n) {
    var high = div13(n)(16);
    var low = n - (high * 16 | 0) | 0;
    return charAtIndex(high)("0123456789abcdef") + charAtIndex(low)("0123456789abcdef");
  };
  var colorToHex2 = function(c) {
    var toHexByte = function(n) {
      var i = clampInt2(n * 255)(0)(255);
      return intToHex(i);
    };
    return "#" + (toHexByte(c.r) + (toHexByte(c.g) + toHexByte(c.b)));
  };
  var renderColorPreset = function(color) {
    var hexColor = colorToHex2(color);
    return button_(append2([class_("color-preset"), onClick(new ColorChanged(color)), title(hexColor), role("option"), ariaLabel("Select color " + hexColor)])(styles([new Tuple("width", "100%"), new Tuple("aspect-ratio", "1"), new Tuple("border", "none"), new Tuple("border-radius", "4px"), new Tuple("background", hexColor), new Tuple("cursor", "pointer"), new Tuple("padding", "0")])))([]);
  };
  var renderColorPicker = function(currentColor) {
    return div_(append2([class_("color-picker"), role("group"), ariaLabel("Color picker")])(styles([new Tuple("display", "flex"), new Tuple("flex-direction", "column"), new Tuple("gap", "8px")])))([span_(styles([new Tuple("color", "#888")]))([text("Color")]), div_(append2([class_("current-color"), role("img"), ariaLabel("Current color: " + colorToHex2(currentColor))])(styles([new Tuple("width", "100%"), new Tuple("height", "32px"), new Tuple("border-radius", "4px"), new Tuple("border", "2px solid #444"), new Tuple("background", colorToHex2(currentColor))])))([]), div_(append2([class_("color-presets"), role("listbox"), ariaLabel("Color presets")])(styles([new Tuple("display", "grid"), new Tuple("grid-template-columns", "repeat(5, 1fr)"), new Tuple("gap", "4px")])))(map8(renderColorPreset)(colorPresets))]);
  };
  var renderPropertiesPanel = function(state2) {
    var config = brushConfig(state2);
    return div_(append2([class_("properties-panel"), role("complementary"), ariaLabel("Brush properties panel")])(styles([new Tuple("width", "200px"), new Tuple("padding", "8px"), new Tuple("background", "#1a1a2e"), new Tuple("border-right", "1px solid #333"), new Tuple("font-size", "11px"), new Tuple("display", "flex"), new Tuple("flex-direction", "column"), new Tuple("gap", "12px")])))([span_(styles([new Tuple("color", "#888"), new Tuple("font-weight", "bold")]))([text("Properties")]), renderSliderControl("Size")("Brush size in pixels")(config.size)(1)(500)(BrushSizeChanged.create), renderSliderControl("Opacity")("Brush opacity percentage")(config.opacity * 100)(0)(100)(function(v) {
      return new BrushOpacityChanged(v / 100);
    }), renderColorPicker(config.color), div_(append2([role("group"), ariaLabel("Export options")])(styles([new Tuple("margin-top", "auto")])))([span_(styles([new Tuple("color", "#888"), new Tuple("display", "block"), new Tuple("margin-bottom", "4px")]))([text("Export")]), div_(styles([new Tuple("display", "flex"), new Tuple("gap", "4px")]))([button_(append2([class_("export-btn"), onClick(new ExportCanvas("png")), title("Export as PNG"), ariaLabel("Export canvas as PNG image")])(styles([new Tuple("flex", "1"), new Tuple("padding", "8px"), new Tuple("border", "none"), new Tuple("border-radius", "4px"), new Tuple("background", "#2a4a6e"), new Tuple("color", "#fff"), new Tuple("cursor", "pointer")])))([text("PNG")]), button_(append2([class_("export-btn"), onClick(new ExportCanvas("svg")), title("Export as SVG"), ariaLabel("Export canvas as SVG vector image")])(styles([new Tuple("flex", "1"), new Tuple("padding", "8px"), new Tuple("border", "none"), new Tuple("border-radius", "4px"), new Tuple("background", "#2a6a4e"), new Tuple("color", "#fff"), new Tuple("cursor", "pointer")])))([text("SVG")])])])]);
  };
  var brushPresetButton = function(preset) {
    return button_(append2([class_("brush-btn"), onClick(new BrushPresetSelected(preset.name)), title(preset.description)])(styles([new Tuple("padding", "4px 8px"), new Tuple("border", "none"), new Tuple("border-radius", "3px"), new Tuple("background", "#3a3a5e"), new Tuple("color", "#ccc"), new Tuple("font-size", "11px"), new Tuple("cursor", "pointer")])))([text(shortPresetName(preset.name))]);
  };
  var renderBrushSelector = function(_state) {
    return div_(append2([class_("brush-selector")])(styles([new Tuple("display", "flex"), new Tuple("flex-direction", "column"), new Tuple("gap", "2px")])))([span_(styles([new Tuple("font-size", "10px"), new Tuple("color", "#888")]))([text("Brush (" + (show52(length(essentialsKit)) + ")"))]), div_(styles([new Tuple("display", "flex"), new Tuple("gap", "2px"), new Tuple("flex-wrap", "wrap")]))(map8(brushPresetButton)(essentialsKit))]);
  };
  var atan2Deg = function(y) {
    return function(x) {
      return atan22(y)(x) * 180 / pi2;
    };
  };
  var gravityAngleFromVector = function(g) {
    return -atan2Deg(g.vx)(g.vy);
  };
  var renderGravityIndicator = function(state2) {
    var gravState = gravityState(state2);
    var gravVector = currentGravity(gravState);
    var magnitude = gravityMagnitude(gravVector);
    var tooltipText = "Gravity: " + (show22(magnitude) + ("g (" + (show22(gravityX(gravVector)) + (", " + (show22(gravityY(gravVector)) + ")")))));
    var isActive2 = isGravityActive(gravState);
    var grav2d = gravity2D(gravVector);
    var angle = gravityAngleFromVector({
      vx: grav2d.x,
      vy: grav2d.y
    });
    return div_(append2([class_("gravity-indicator"), title(tooltipText)])(styles([new Tuple("position", "absolute"), new Tuple("top", "16px"), new Tuple("right", "16px"), new Tuple("width", "48px"), new Tuple("height", "48px"), new Tuple("border-radius", "50%"), new Tuple("background", (function() {
      if (isActive2) {
        return "rgba(100,150,255,0.3)";
      }
      ;
      return "rgba(100,100,100,0.2)";
    })()), new Tuple("border", (function() {
      if (isActive2) {
        return "2px solid #6496ff";
      }
      ;
      return "2px solid #666";
    })()), new Tuple("display", "flex"), new Tuple("align-items", "center"), new Tuple("justify-content", "center"), new Tuple("transform", "rotate(" + (show22(angle) + "deg)")), new Tuple("transition", "transform 0.1s ease-out")])))([div_(styles([new Tuple("width", "0"), new Tuple("height", "0"), new Tuple("border-left", "8px solid transparent"), new Tuple("border-right", "8px solid transparent"), new Tuple("border-top", (function() {
      if (isActive2) {
        return "16px solid #6496ff";
      }
      ;
      return "16px solid #666";
    })())]))([])]);
  };
  var renderCanvas = function(state2) {
    var particleCount2 = particleCount(paintSystem(state2));
    var canvasDescription = "Paint canvas with " + (show52(particleCount2) + " particles. Press Tab to focus, then use Ctrl+Z to undo, Ctrl+Shift+Z to redo.");
    return div_(append2([class_("canvas-surface"), id_("paint-canvas"), role("img"), ariaLabel(canvasDescription), tabIndex(0), onMouseDown(new CanvasTouched(0, 0)), onMouseMove(new CanvasMoved(0, 0)), onMouseUp(CanvasReleased.value), onTouchStart(new CanvasTouched(0, 0)), onTouchMove(new CanvasMoved(0, 0)), onTouchEnd(CanvasReleased.value)])(styles([new Tuple("flex", "1"), new Tuple("position", "relative"), new Tuple("background", "#f5f5dc"), new Tuple("overflow", "hidden"), new Tuple("cursor", "crosshair"), new Tuple("min-width", "0"), new Tuple("outline", "none")])))([renderPaintLayers(state2), renderGravityIndicator(state2), renderDebugOverlay(state2)]);
  };
  var actionButton = function(msg) {
    return function(label) {
      return function(description) {
        return function(enabled) {
          return button_(append2([class_("action-btn"), onClick(msg), ariaLabel(description), attr("aria-disabled")((function() {
            if (enabled) {
              return "false";
            }
            ;
            return "true";
          })())])(styles([new Tuple("padding", "8px 12px"), new Tuple("border", "none"), new Tuple("border-radius", "4px"), new Tuple("background", (function() {
            if (enabled) {
              return "#2a2a4e";
            }
            ;
            return "#1a1a2e";
          })()), new Tuple("color", (function() {
            if (enabled) {
              return "#fff";
            }
            ;
            return "#666";
          })()), new Tuple("cursor", (function() {
            if (enabled) {
              return "pointer";
            }
            ;
            return "not-allowed";
          })())])))([text(label)]);
        };
      };
    };
  };
  var renderActionButtons = function(state2) {
    return div_(append2([class_("action-buttons"), role("group"), ariaLabel("Canvas actions")])(styles([new Tuple("display", "flex"), new Tuple("gap", "4px"), new Tuple("margin-left", "auto")])))([actionButton(Undo.value)("Undo")("Undo last action (Ctrl+Z)")(canUndo(state2)), actionButton(Redo.value)("Redo")("Redo undone action (Ctrl+Shift+Z)")(canRedo(state2)), actionButton(ClearCanvas.value)("Clear")("Clear all paint from canvas")(true), actionButton(ToggleGravity.value)("Gravity")("Toggle gravity effect")(true), actionButton(TogglePlaying.value)((function() {
      var $221 = isPlaying(state2);
      if ($221) {
        return "Pause";
      }
      ;
      return "Play";
    })())((function() {
      var $222 = isPlaying(state2);
      if ($222) {
        return "Pause physics simulation";
      }
      ;
      return "Resume physics simulation";
    })())(true)]);
  };
  var renderToolbar = function(state2) {
    return div_(append2([class_("canvas-toolbar"), role("toolbar"), ariaLabel("Canvas tools")])(styles([new Tuple("display", "flex"), new Tuple("gap", "8px"), new Tuple("padding", "8px"), new Tuple("background", "#1a1a2e"), new Tuple("border-bottom", "1px solid #333")])))([renderToolButtons(state2), renderBrushSelector(state2), renderMediaSelector(state2), renderActionButtons(state2)]);
  };
  var view = function(state2) {
    return div_(append2([class_("canvas-app"), role("application"), ariaLabel("Canvas Paint Application")])(styles([new Tuple("display", "flex"), new Tuple("flex-direction", "column"), new Tuple("width", "100vw"), new Tuple("height", "100vh"), new Tuple("overflow", "hidden"), new Tuple("touch-action", "none"), new Tuple("user-select", "none")])))([renderToolbar(state2), div_(append2([class_("canvas-main"), role("main"), ariaLabel("Main canvas workspace")])(styles([new Tuple("flex", "1"), new Tuple("display", "flex"), new Tuple("position", "relative"), new Tuple("overflow", "hidden")])))([renderPropertiesPanel(state2), renderCanvas(state2), renderLayerPanel(state2)]), renderStatusBar(state2), renderConfettiOverlay(state2)]);
  };

  // output/Hydrogen.Runtime.App/index.js
  var OnAnimationFrame = /* @__PURE__ */ (function() {
    function OnAnimationFrame2(value0) {
      this.value0 = value0;
    }
    ;
    OnAnimationFrame2.create = function(value0) {
      return new OnAnimationFrame2(value0);
    };
    return OnAnimationFrame2;
  })();
  var OnKeyDown2 = /* @__PURE__ */ (function() {
    function OnKeyDown3(value0) {
      this.value0 = value0;
    }
    ;
    OnKeyDown3.create = function(value0) {
      return new OnKeyDown3(value0);
    };
    return OnKeyDown3;
  })();
  var OnMouseMove2 = /* @__PURE__ */ (function() {
    function OnMouseMove3(value0) {
      this.value0 = value0;
    }
    ;
    OnMouseMove3.create = function(value0) {
      return new OnMouseMove3(value0);
    };
    return OnMouseMove3;
  })();
  var OnMouseDown2 = /* @__PURE__ */ (function() {
    function OnMouseDown3(value0) {
      this.value0 = value0;
    }
    ;
    OnMouseDown3.create = function(value0) {
      return new OnMouseDown3(value0);
    };
    return OnMouseDown3;
  })();
  var OnMouseUp2 = /* @__PURE__ */ (function() {
    function OnMouseUp3(value0) {
      this.value0 = value0;
    }
    ;
    OnMouseUp3.create = function(value0) {
      return new OnMouseUp3(value0);
    };
    return OnMouseUp3;
  })();
  var OnTouchStart2 = /* @__PURE__ */ (function() {
    function OnTouchStart3(value0) {
      this.value0 = value0;
    }
    ;
    OnTouchStart3.create = function(value0) {
      return new OnTouchStart3(value0);
    };
    return OnTouchStart3;
  })();
  var OnTouchMove2 = /* @__PURE__ */ (function() {
    function OnTouchMove3(value0) {
      this.value0 = value0;
    }
    ;
    OnTouchMove3.create = function(value0) {
      return new OnTouchMove3(value0);
    };
    return OnTouchMove3;
  })();
  var OnTouchEnd2 = /* @__PURE__ */ (function() {
    function OnTouchEnd3(value0) {
      this.value0 = value0;
    }
    ;
    OnTouchEnd3.create = function(value0) {
      return new OnTouchEnd3(value0);
    };
    return OnTouchEnd3;
  })();
  var OnPointerDown = /* @__PURE__ */ (function() {
    function OnPointerDown2(value0) {
      this.value0 = value0;
    }
    ;
    OnPointerDown2.create = function(value0) {
      return new OnPointerDown2(value0);
    };
    return OnPointerDown2;
  })();
  var OnPointerMove = /* @__PURE__ */ (function() {
    function OnPointerMove2(value0) {
      this.value0 = value0;
    }
    ;
    OnPointerMove2.create = function(value0) {
      return new OnPointerMove2(value0);
    };
    return OnPointerMove2;
  })();
  var OnPointerUp = /* @__PURE__ */ (function() {
    function OnPointerUp2(value0) {
      this.value0 = value0;
    }
    ;
    OnPointerUp2.create = function(value0) {
      return new OnPointerUp2(value0);
    };
    return OnPointerUp2;
  })();
  var OnDeviceOrientation = /* @__PURE__ */ (function() {
    function OnDeviceOrientation2(value0) {
      this.value0 = value0;
    }
    ;
    OnDeviceOrientation2.create = function(value0) {
      return new OnDeviceOrientation2(value0);
    };
    return OnDeviceOrientation2;
  })();
  var OnDeviceMotion = /* @__PURE__ */ (function() {
    function OnDeviceMotion2(value0) {
      this.value0 = value0;
    }
    ;
    OnDeviceMotion2.create = function(value0) {
      return new OnDeviceMotion2(value0);
    };
    return OnDeviceMotion2;
  })();

  // output/Canvas.App/index.js
  var eq3 = /* @__PURE__ */ eq(eqTool);
  var show7 = /* @__PURE__ */ show(showInt);
  var append12 = /* @__PURE__ */ append(semigroupArray);
  var touchCount = function(event) {
    return length(event.touches);
  };
  var presetFromWetMedia = function(mediaType) {
    if (mediaType instanceof Watercolor2) {
      return Watercolor.value;
    }
    ;
    if (mediaType instanceof OilPaint2) {
      return OilPaint.value;
    }
    ;
    if (mediaType instanceof Acrylic2) {
      return Acrylic.value;
    }
    ;
    if (mediaType instanceof Gouache2) {
      return Gouache.value;
    }
    ;
    if (mediaType instanceof Ink2) {
      return Ink.value;
    }
    ;
    if (mediaType instanceof WetIntoWet) {
      return Watercolor.value;
    }
    ;
    throw new Error("Failed pattern match at Canvas.App (line 551, column 32 - line 557, column 36): " + [mediaType.constructor.name]);
  };
  var presetFromName = function(name2) {
    if (name2 === "watercolor") {
      return Watercolor.value;
    }
    ;
    if (name2 === "Watercolor") {
      return Watercolor.value;
    }
    ;
    if (name2 === "oil") {
      return OilPaint.value;
    }
    ;
    if (name2 === "Oil") {
      return OilPaint.value;
    }
    ;
    if (name2 === "Oil Paint") {
      return OilPaint.value;
    }
    ;
    if (name2 === "acrylic") {
      return Acrylic.value;
    }
    ;
    if (name2 === "Acrylic") {
      return Acrylic.value;
    }
    ;
    if (name2 === "gouache") {
      return Gouache.value;
    }
    ;
    if (name2 === "Gouache") {
      return Gouache.value;
    }
    ;
    if (name2 === "ink") {
      return Ink.value;
    }
    ;
    if (name2 === "Ink") {
      return Ink.value;
    }
    ;
    if (name2 === "honey") {
      return Honey.value;
    }
    ;
    if (name2 === "Honey") {
      return Honey.value;
    }
    ;
    return Watercolor.value;
  };
  var pointerToStylus = function(event) {
    return {
      x: event.x,
      y: event.y,
      pressure: event.pressure,
      tiltX: event.tiltX,
      tiltY: event.tiltY,
      pointerType: event.pointerType
    };
  };
  var physicsTimestep = 0.016;
  var isPaintingActive = function(state2) {
    var tool = currentTool(state2);
    return eq3(tool)(BrushTool.value);
  };
  var updateCanvas = function(msg) {
    return function(state2) {
      if (msg instanceof ToolSelected) {
        return noCmd(setTool(msg.value0)(state2));
      }
      ;
      if (msg instanceof BrushPresetSelected) {
        var preset = presetFromName(msg.value0);
        return noCmd(setBrushPreset(preset)(state2));
      }
      ;
      if (msg instanceof MediaTypeSelected) {
        var preset = presetFromWetMedia(msg.value0);
        return noCmd(setBrushPreset(preset)(state2));
      }
      ;
      if (msg instanceof ColorChanged) {
        return noCmd(setBrushColor(msg.value0)(state2));
      }
      ;
      if (msg instanceof BrushSizeChanged) {
        return noCmd(setBrushSize(msg.value0)(state2));
      }
      ;
      if (msg instanceof BrushOpacityChanged) {
        return noCmd(setBrushOpacity(msg.value0)(state2));
      }
      ;
      if (msg instanceof PointerDown) {
        var withPointer = setPointerDown(msg.value0.x)(msg.value0.y)(state2);
        var withParticle = addPaintParticleWithDynamics(msg.value0.x)(msg.value0.y)(msg.value0.pressure)(msg.value0.tiltX)(msg.value0.tiltY)(withPointer);
        var withHistory = pushHistory("Paint stroke")(withParticle);
        return noCmd(withHistory);
      }
      ;
      if (msg instanceof PointerMoved) {
        var $30 = isPaintingActive(state2);
        if ($30) {
          var withDrag = applyBrushDragFromPointer(msg.value0.x)(msg.value0.y)(msg.value0.pressure)(state2);
          var withParticle = addPaintParticleWithDynamics(msg.value0.x)(msg.value0.y)(msg.value0.pressure)(msg.value0.tiltX)(msg.value0.tiltY)(withDrag);
          return noCmd(withParticle);
        }
        ;
        return noCmd(state2);
      }
      ;
      if (msg instanceof PointerUp) {
        return noCmd(setPointerUp(state2));
      }
      ;
      if (msg instanceof CanvasTouched) {
        var withPointer = setPointerDown(msg.value0)(msg.value1)(state2);
        var withParticle = addPaintParticle(msg.value0)(msg.value1)(withPointer);
        var withHistory = pushHistory("Paint stroke")(withParticle);
        return noCmd(withHistory);
      }
      ;
      if (msg instanceof CanvasMoved) {
        var $34 = isPaintingActive(state2);
        if ($34) {
          var withDrag = applyBrushDragFromPointer(msg.value0)(msg.value1)(0.5)(state2);
          var withParticle = addPaintParticle(msg.value0)(msg.value1)(withDrag);
          return noCmd(withParticle);
        }
        ;
        return noCmd(state2);
      }
      ;
      if (msg instanceof CanvasReleased) {
        return noCmd(setPointerUp(state2));
      }
      ;
      if (msg instanceof OrientationChanged) {
        var updated = updateGravity(msg.value0.alpha)(msg.value0.beta)(msg.value0.gamma)(state2);
        return noCmd(updated);
      }
      ;
      if (msg instanceof ToggleGravity) {
        var currentGrav = gravityState(state2);
        var isEnabled = gravityEnabled(currentGrav);
        var updated = setGravityEnabled2(!isEnabled)(state2);
        return noCmd(updated);
      }
      ;
      if (msg instanceof TogglePlaying) {
        return noCmd(togglePlaying(state2));
      }
      ;
      if (msg instanceof ClearCanvas) {
        var cleared = clearActiveLayer(state2);
        var withHistory = pushHistory("Clear canvas")(cleared);
        return noCmd(withHistory);
      }
      ;
      if (msg instanceof Undo) {
        return noCmd(undo(state2));
      }
      ;
      if (msg instanceof Redo) {
        return noCmd(redo(state2));
      }
      ;
      if (msg instanceof Tick) {
        var dtSeconds = msg.value0 / 1e3;
        var simulated = simulatePaint(dtSeconds)(state2);
        var withConfetti = updateEasterEggConfetti(dtSeconds)(simulated);
        return noCmd(withConfetti);
      }
      ;
      if (msg instanceof LayerSelected) {
        return noCmd(setActiveLayer2(msg.value0)(state2));
      }
      ;
      if (msg instanceof AddLayer) {
        var newLayerName = "Layer " + show7(layerCount2(state2) + 1 | 0);
        var withLayer = addLayer2(newLayerName)(state2);
        var withHistory = pushHistory("Add layer")(withLayer);
        return noCmd(withHistory);
      }
      ;
      if (msg instanceof LayerVisibilityToggled) {
        return noCmd(toggleLayerVisibility(msg.value0)(state2));
      }
      ;
      if (msg instanceof DeleteLayer) {
        var withRemoved = removeLayer2(msg.value0)(state2);
        var withHistory = pushHistory("Delete layer")(withRemoved);
        return noCmd(withHistory);
      }
      ;
      if (msg instanceof MoveLayerUp) {
        var withMoved = moveLayerUp2(msg.value0)(state2);
        var withHistory = pushHistory("Move layer up")(withMoved);
        return noCmd(withHistory);
      }
      ;
      if (msg instanceof MoveLayerDown) {
        var withMoved = moveLayerDown2(msg.value0)(state2);
        var withHistory = pushHistory("Move layer down")(withMoved);
        return noCmd(withHistory);
      }
      ;
      if (msg instanceof KeyDown) {
        var withKey = processEasterEggKey(msg.value0)(state2);
        var eeState = easterEggState(withKey);
        var $44 = konamiTriggered(eeState);
        if ($44) {
          var withConfetti = triggerEasterEggConfetti(960)(540)(withKey);
          var withReset = resetEasterEggs(withConfetti);
          return noCmd(withReset);
        }
        ;
        return noCmd(withKey);
      }
      ;
      if (msg instanceof KeyboardShortcut) {
        var $46 = msg.value0.ctrlKey && (!msg.value0.shiftKey && msg.value0.key === "z");
        if ($46) {
          return noCmd(undo(state2));
        }
        ;
        var $47 = msg.value0.ctrlKey && (msg.value0.shiftKey && (msg.value0.key === "z" || msg.value0.key === "Z"));
        if ($47) {
          return noCmd(redo(state2));
        }
        ;
        var $48 = msg.value0.ctrlKey && (!msg.value0.shiftKey && msg.value0.key === "y");
        if ($48) {
          return noCmd(redo(state2));
        }
        ;
        var $49 = msg.value0.ctrlKey && (msg.value0.key === "s" || msg.value0.key === "S");
        if ($49) {
          return transition(state2)(new Log("EXPORT:png"));
        }
        ;
        var $50 = msg.value0.ctrlKey && (msg.value0.shiftKey && (msg.value0.key === "e" || msg.value0.key === "E"));
        if ($50) {
          return transition(state2)(new Log("EXPORT:svg"));
        }
        ;
        var $51 = msg.value0.key === "Escape";
        if ($51) {
          return noCmd(resetViewport(state2));
        }
        ;
        var $52 = msg.value0.key === " ";
        if ($52) {
          return noCmd(state2);
        }
        ;
        return noCmd(processEasterEggKey(msg.value0.key)(state2));
      }
      ;
      if (msg instanceof DeviceMotion) {
        var withMotion = processEasterEggMotion(msg.value0)(state2);
        var eeState = easterEggState(withMotion);
        var $54 = shakeTriggered(eeState);
        if ($54) {
          var cleared = clearActiveLayer(withMotion);
          var withHistory = pushHistory("Shake clear")(cleared);
          var withReset = resetEasterEggs(withHistory);
          return noCmd(withReset);
        }
        ;
        return noCmd(withMotion);
      }
      ;
      if (msg instanceof ViewportPan) {
        return noCmd(panViewport(msg.value0)(msg.value1)(state2));
      }
      ;
      if (msg instanceof ViewportZoom) {
        return noCmd(zoomViewport(msg.value0)(state2));
      }
      ;
      if (msg instanceof ViewportZoomAt) {
        return noCmd(zoomViewportAt(msg.value0)(msg.value1)(msg.value2)(state2));
      }
      ;
      if (msg instanceof ViewportRotate) {
        return noCmd(rotateViewport(msg.value0)(state2));
      }
      ;
      if (msg instanceof ViewportReset) {
        return noCmd(resetViewport(state2));
      }
      ;
      if (msg instanceof TwoFingerTouch) {
        var p2 = {
          x: msg.value0.x2,
          y: msg.value0.y2
        };
        var p1 = {
          x: msg.value0.x1,
          y: msg.value0.y1
        };
        return noCmd(processTwoFingerGesture(p1)(p2)(state2));
      }
      ;
      if (msg instanceof TwoFingerEnd) {
        return noCmd(endTwoFingerGesture(state2));
      }
      ;
      if (msg instanceof ExportCanvas) {
        return transition(state2)(new Log("EXPORT:" + msg.value0));
      }
      ;
      throw new Error("Failed pattern match at Canvas.App (line 203, column 26 - line 519, column 49): " + [msg.constructor.name]);
    };
  };
  var initCanvas = /* @__PURE__ */ (function() {
    var withPlaying = togglePlaying(initialAppState);
    var withGravity = setGravityEnabled2(true)(withPlaying);
    return noCmd(withGravity);
  })();
  var handleTwoFingerTouch = function(event) {
    var v = head(event.touches);
    if (v instanceof Nothing) {
      return CanvasReleased.value;
    }
    ;
    if (v instanceof Just) {
      var v1 = index(event.touches)(1);
      if (v1 instanceof Nothing) {
        return CanvasReleased.value;
      }
      ;
      if (v1 instanceof Just) {
        return new TwoFingerTouch({
          x1: v.value0.x,
          y1: v.value0.y,
          x2: v1.value0.x,
          y2: v1.value0.y
        });
      }
      ;
      throw new Error("Failed pattern match at Canvas.App (line 754, column 16 - line 759, column 10): " + [v1.constructor.name]);
    }
    ;
    throw new Error("Failed pattern match at Canvas.App (line 752, column 3 - line 759, column 10): " + [v.constructor.name]);
  };
  var handleTouchStart = function(event) {
    var v = touchCount(event);
    if (v === 2) {
      return handleTwoFingerTouch(event);
    }
    ;
    var v1 = head(event.changedTouches);
    if (v1 instanceof Just) {
      return new CanvasTouched(v1.value0.x, v1.value0.y);
    }
    ;
    if (v1 instanceof Nothing) {
      return CanvasReleased.value;
    }
    ;
    throw new Error("Failed pattern match at Canvas.App (line 724, column 10 - line 726, column 42): " + [v1.constructor.name]);
  };
  var handleTouchMove = function(event) {
    var v = touchCount(event);
    if (v === 2) {
      return handleTwoFingerTouch(event);
    }
    ;
    var v1 = head(event.changedTouches);
    if (v1 instanceof Just) {
      return new CanvasMoved(v1.value0.x, v1.value0.y);
    }
    ;
    if (v1 instanceof Nothing) {
      return CanvasReleased.value;
    }
    ;
    throw new Error("Failed pattern match at Canvas.App (line 733, column 10 - line 735, column 42): " + [v1.constructor.name]);
  };
  var handleTouchEnd = function(event) {
    var $75 = touchCount(event) < 2;
    if ($75) {
      return TwoFingerEnd.value;
    }
    ;
    return CanvasReleased.value;
  };
  var handlePointerUp = function(_event) {
    return PointerUp.value;
  };
  var handlePointerMove = function(event) {
    return new PointerMoved(pointerToStylus(event));
  };
  var handlePointerDown = function(event) {
    return new PointerDown(pointerToStylus(event));
  };
  var handleMouseUp = function(_event) {
    return CanvasReleased.value;
  };
  var handleMouseMove = function(pos) {
    return new CanvasMoved(pos.x, pos.y);
  };
  var handleMouseDown = function(event) {
    return new CanvasTouched(event.x, event.y);
  };
  var handleKeyDown = function(key) {
    return new KeyDown(key);
  };
  var handleDeviceOrientation = function(event) {
    var orientation = {
      alpha: event.alpha,
      beta: event.beta,
      gamma: event.gamma
    };
    return new OrientationChanged(orientation);
  };
  var handleDeviceMotion = function(event) {
    return new DeviceMotion({
      accelerationX: event.accelerationX,
      accelerationY: event.accelerationY,
      accelerationZ: event.accelerationZ,
      timestamp: event.interval
    });
  };
  var handleAnimationFrame = function(deltaTime) {
    return new Tick(deltaTime);
  };
  var subscriptionsCanvas = function(state2) {
    var touchSubs = [new OnTouchStart2(handleTouchStart), new OnTouchMove2(handleTouchMove), new OnTouchEnd2(handleTouchEnd)];
    var pointerSubs = [new OnPointerDown(handlePointerDown), new OnPointerMove(handlePointerMove), new OnPointerUp(handlePointerUp)];
    var orientationSub = (function() {
      var $76 = gravityEnabled(gravityState(state2));
      if ($76) {
        return [new OnDeviceOrientation(handleDeviceOrientation)];
      }
      ;
      return [];
    })();
    var mouseSubs = [new OnMouseDown2(handleMouseDown), new OnMouseMove2(handleMouseMove), new OnMouseUp2(handleMouseUp)];
    var motionSub = [new OnDeviceMotion(handleDeviceMotion)];
    var keyboardSub = [new OnKeyDown2(handleKeyDown)];
    var animationSub = (function() {
      var $77 = isPlaying(state2);
      if ($77) {
        return [new OnAnimationFrame(handleAnimationFrame)];
      }
      ;
      return [];
    })();
    return append12(animationSub)(append12(orientationSub)(append12(pointerSubs)(append12(touchSubs)(append12(mouseSubs)(append12(keyboardSub)(motionSub))))));
  };
  var gravityScale = 9.81;
  var frameTimeMs = 16.67;
  var canvasApp = {
    init: initCanvas,
    update: updateCanvas,
    view,
    subscriptions: subscriptionsCanvas,
    triggers: []
  };
  var main = function __do2() {
    log2("Canvas Builder initializing...")();
    log2("  - SPH fluid simulation: enabled")();
    log2("  - Device orientation: listening")();
    log2("  - Touch input: ready")();
    log2("  - Physics timestep: 16.67ms (60 FPS)")();
    log2("")();
    var getParticlesFromState = function(state2) {
      return allParticles(paintSystem(state2));
    };
    var toKbShortcutMsg = function(ks) {
      return new KeyboardShortcut({
        key: ks.key,
        ctrlKey: ks.ctrlKey,
        shiftKey: ks.shiftKey,
        altKey: ks.altKey
      });
    };
    mount("#app")(canvasApp)(updateCanvas)(view)(initCanvas)(getParticlesFromState)(Tick.create)(toKbShortcutMsg)();
    log2("Canvas Builder ready!")();
    return unit;
  };
  return __toCommonJS(index_exports);
})();
