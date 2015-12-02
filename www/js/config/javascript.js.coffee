@my$XmlToString = ($xmlData) -> # requires JQuery XML data
  xmlString = `undefined`
  xmlString = $xmlData[0].xml  if window.ActiveXObject
  if xmlString is `undefined`
    oSerializer = new XMLSerializer()
    xmlString = oSerializer.serializeToString($xmlData[0])
  # trim any rogue characters that may exist in the XML
  xmlString.substr(xmlString.indexOf("<"), xmlString.lastIndexOf(">") + 1)

@myGetCookie = (sKey) ->
  # method taken from Mozilla's mini cookie reader/writer at Web API document.cookie docs
  if (!sKey) then return null
  return decodeURIComponent(document.cookie.replace(new RegExp("(?:(?:^|.*;)\\s*" + encodeURIComponent(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*([^;]*).*$)|^.*$"), "$1")) || null

@mixOf = (base, mixins ...) ->
  # method to add mixins to a class extension in Coffeescript
  # from: https://github.com/jashkenas/coffeescript/issues/452#issuecomment-17012372
  # usage: 
  #
  # class A extends mixOf Foo, Bar
  #
  # Implementation notes:
  # - Includes "super" from A methods
  # - There is no python-style method-resolution-order magic from "super" in Bar methods (that would be multiple inheritance, not mixins)
  # - Does not include methods that Bar inherits from a superclass (technically, mixins should have this; but pragmatically, it's good that this doesn't, because it discourages mixins as anything but simple one-offs.)
  # - Changes to mixin are not reflected in A (again, technically bad but pragmatically good)

  class Mixed extends base
  for mixin in mixins by -1
    for name, method of mixin::
      Mixed::[name] = method
  Mixed


@myStringToHex = (tmp) ->
  # Each character in the string is converted to a 2-digit hex
  # of its character code, no spaces between.

  d2h = (d) -> d.toString 16

  str = ''
  i = 0
  tmp_len = tmp.length
  c = undefined
  while i < tmp_len
    c = tmp.charCodeAt(i)
    str += d2h(c)
    i += 1
  str

@myHexToString = (tmp) ->
  # Assuming a string composed of 2-digit hex codes
  # to convert into strings, no spaces between
  h2d = (h) -> parseInt h, 16
  arr = tmp.match(/.{2}/g)
  str = ''
  i = 0
  arr_len = arr.length
  c = undefined
  while i < arr_len
    c = String.fromCharCode(h2d(arr[i]))
    str += c
    i += 1
  str


if typeof String.prototype.capitalizeFirstLetter isnt 'function'
  String.prototype.capitalizeFirstLetter = ->
    @ && @[0].toUpperCase() + @slice(1)

if typeof String.prototype.endsWith isnt 'function'
  String.prototype.endsWith = (suffix) ->
    @indexOf(suffix, @length - suffix.length) isnt -1
