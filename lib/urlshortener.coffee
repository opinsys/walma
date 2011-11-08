

exports.alphabet = alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".split("")

base = alphabet.length

exports.encode = (i) ->
  return alphabet[0] if i is 0
  s = ""
  while i > 0
    s += alphabet[i % base]
    i = parseInt(i / base, 10)

  s.split("").reverse().join("")


exports.decode = (s) ->
  i = 0
  for c in s
    i = i * base + alphabet.indexOf c
  i


# Poor man's test case
if require.main is module
  for i in [0..100000]
    if exports.decode(exports.encode(i)) isnt i
      console.log exports.encode(i), i, "is not", exports.decode(exports.encode(i))
      console.log "error"
      break

  console.log "done"
