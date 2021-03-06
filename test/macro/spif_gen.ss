# Try changing these flags between 1 (true) and 0 (false) to get very
# different programs! But all of the programs produce the same result when
# executed.
var flag1 = <0>;
var flag2 = <1>;

# A conditional specialized `if`. If `s` is true, then this runs an `if`
# immediately. If it's false, then we insert an `if` into the code.
var spif? = fun s:<Int> c:<Int> t:<Int> f:<Int> ->
    if !s (if !c t f) < if [c] [t] [f] >;

# This is the program we're generating.
<
  @spif? [flag1] 1 2 3 +
  @spif? [flag2] 1 2 3
>
# -> < (if 1 2 3) + 2 >
