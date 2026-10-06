# betterbird: thunderbird with fixes and features it lacks
{ wrapThunderbird, betterbird-unwrapped }:

wrapThunderbird betterbird-unwrapped {
  pname = "betterbird";
  inherit (betterbird-unwrapped) libName;
}
