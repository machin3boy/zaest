__all__ = ['encoding']

# Don't look below, you will not understand this Python code :) I don't.

from js2py.pyjs import *
# setting scope
var = Scope( JS_BUILTINS )
set_global_object(var)

# Code follows:
var.registers(['strToBig', 'bigToHex', 'bigToU8arr', 'u8arrToBig', 'strToU8arr', 'bigToStr', 'u32arrToHex', 'hexToBig', 'u8arrToStr'])
@Js
def PyJsHoisted_hexToBig_(num, this, arguments, var=var):
    var = Scope({'num':num, 'this':this, 'arguments':arguments}, var)
    var.registers(['num'])
    return var.get('BigInt')(var.get('num'))
PyJsHoisted_hexToBig_.func_name = 'hexToBig'
var.put('hexToBig', PyJsHoisted_hexToBig_)
@Js
def PyJsHoisted_bigToHex_(num, this, arguments, var=var):
    var = Scope({'num':num, 'this':this, 'arguments':arguments}, var)
    var.registers(['num'])
    return (Js('0x')+var.get('BigInt')(var.get('num')).callprop('toString', Js(16.0)))
PyJsHoisted_bigToHex_.func_name = 'bigToHex'
var.put('bigToHex', PyJsHoisted_bigToHex_)
@Js
def PyJsHoisted_strToU8arr_(str, this, arguments, var=var):
    var = Scope({'str':str, 'this':this, 'arguments':arguments}, var)
    var.registers(['str'])
    return var.get('TextEncoder').create(Js('utf-8')).callprop('encode', var.get('str'))
PyJsHoisted_strToU8arr_.func_name = 'strToU8arr'
var.put('strToU8arr', PyJsHoisted_strToU8arr_)
@Js
def PyJsHoisted_u8arrToStr_(u8arr, this, arguments, var=var):
    var = Scope({'u8arr':u8arr, 'this':this, 'arguments':arguments}, var)
    var.registers(['u8arr'])
    return var.get('TextDecoder').create(Js('utf-8')).callprop('decode', var.get('u8arr'))
PyJsHoisted_u8arrToStr_.func_name = 'u8arrToStr'
var.put('u8arrToStr', PyJsHoisted_u8arrToStr_)
@Js
def PyJsHoisted_bigToU8arr_(big, this, arguments, var=var):
    var = Scope({'big':big, 'this':this, 'arguments':arguments}, var)
    var.registers(['u8', 'big', 'big0', 'i', 'len', 'j', 'big8', 'big1', 'prefix1', 'hex', 'bits'])
    var.put('big0', var.get('BigInt')(Js(0.0)))
    var.put('big1', var.get('BigInt')(Js(1.0)))
    var.put('big8', var.get('BigInt')(Js(8.0)))
    if (var.get('big')<var.get('big0')):
        var.put('bits', (((var.get('BigInt')(var.get('big').callprop('toString', Js(2.0)).get('length'))/var.get('big8'))+var.get('big1'))*var.get('big8')))
        var.put('prefix1', (var.get('big1')<<var.get('bits')))
        var.put('big', var.get('prefix1'), '+')
    var.put('hex', var.get('big').callprop('toString', Js(16.0)))
    if (var.get('hex').get('length')%Js(2.0)):
        var.put('hex', (Js('0')+var.get('hex')))
    var.put('len', (var.get('hex').get('length')/Js(2.0)))
    var.put('u8', var.get('Uint8Array').create(var.get('len')))
    var.put('i', Js(0.0))
    var.put('j', Js(0.0))
    while (var.get('i')<var.get('len')):
        var.get('u8').put(var.get('i'), var.get('parseInt')(var.get('hex').callprop('slice', var.get('j'), (var.get('j')+Js(2.0))), Js(16.0)))
        var.put('i', Js(1.0), '+')
        var.put('j', Js(2.0), '+')
    return var.get('u8')
PyJsHoisted_bigToU8arr_.func_name = 'bigToU8arr'
var.put('bigToU8arr', PyJsHoisted_bigToU8arr_)
@Js
def PyJsHoisted_u8arrToBig_(buf, this, arguments, var=var):
    var = Scope({'buf':buf, 'this':this, 'arguments':arguments}, var)
    var.registers(['hex', 'buf'])
    var.put('hex', Js([]))
    var.put('u8', var.get('Uint8Array').callprop('from', var.get('buf')))
    @Js
    def PyJs_anonymous_0_(i, this, arguments, var=var):
        var = Scope({'i':i, 'this':this, 'arguments':arguments}, var)
        var.registers(['i', 'h'])
        var.put('h', var.get('i').callprop('toString', Js(16.0)))
        if (var.get('h').get('length')%Js(2.0)):
            var.put('h', (Js('0')+var.get('h')))
        var.get('hex').callprop('push', var.get('h'))
    PyJs_anonymous_0_._set_name('anonymous')
    var.get('u8').callprop('forEach', PyJs_anonymous_0_)
    return var.get('BigInt')((Js('0x')+var.get('hex').callprop('join', Js(''))))
PyJsHoisted_u8arrToBig_.func_name = 'u8arrToBig'
var.put('u8arrToBig', PyJsHoisted_u8arrToBig_)
@Js
def PyJsHoisted_u32arrToHex_(u32Arr, this, arguments, var=var):
    var = Scope({'u32Arr':u32Arr, 'this':this, 'arguments':arguments}, var)
    var.registers(['u32Arr', 'hex'])
    var.put('hex', Js([]))
    var.put('u32', var.get('Uint32Array').callprop('from', var.get('u32Arr')))
    @Js
    def PyJs_anonymous_1_(i, this, arguments, var=var):
        var = Scope({'i':i, 'this':this, 'arguments':arguments}, var)
        var.registers(['i', 'h'])
        var.put('h', var.get('i').callprop('toString', Js(16.0)))
        var.get('hex').callprop('push', (Js('0').callprop('repeat', (Js(8.0)-var.get('h').get('length')))+var.get('h')))
    PyJs_anonymous_1_._set_name('anonymous')
    var.get('u32').callprop('forEach', PyJs_anonymous_1_)
    return (Js('0x')+var.get('hex').callprop('join', Js('')))
PyJsHoisted_u32arrToHex_.func_name = 'u32arrToHex'
var.put('u32arrToHex', PyJsHoisted_u32arrToHex_)
@Js
def PyJsHoisted_strToBig_(str, this, arguments, var=var):
    var = Scope({'str':str, 'this':this, 'arguments':arguments}, var)
    var.registers(['str'])
    return var.get('u8arrToBig')(var.get('strToU8arr')(var.get('str')))
PyJsHoisted_strToBig_.func_name = 'strToBig'
var.put('strToBig', PyJsHoisted_strToBig_)
@Js
def PyJsHoisted_bigToStr_(big, this, arguments, var=var):
    var = Scope({'big':big, 'this':this, 'arguments':arguments}, var)
    var.registers(['big'])
    return var.get('u8arrToStr')(var.get('bigToU8arr')(var.get('big')))
PyJsHoisted_bigToStr_.func_name = 'bigToStr'
var.put('bigToStr', PyJsHoisted_bigToStr_)
pass
pass
pass
pass
pass
pass
pass
pass
pass
pass


# Add lib to the module scope
encoding = var.to_python()