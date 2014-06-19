### http://mths.be/startswith v0.2.0 by @mathias ###
if not String.prototype.startsWith

    'use strict' # needed to support `apply`/`call` with `undefined`/`null`
    defineProperty = () ->
        # IE 8 only supports `Object.defineProperty` on DOM elements
        try
            object = {}
            $defineProperty = Object.defineProperty
            result = $defineProperty(object, object, object) && $defineProperty
        catch error
        return result


    toString = {}.toString;
    startsWith = () ->
        ###
        ###
        if this is null
            throw TypeError()

        string = String(@)
        if search and toString.call(search) == '[object RegExp]'
            throw TypeError()

        stringLength = string.length
        searchString = String(search)
        searchLength = searchString.length
        position =
            switch
                when arguments.length > 1 then arguments[1]
                else
                    undefined

        # `ToInteger`
        pos =
                switch
                    when position then Number(position)
                    else 0

        if pos != pos  # better `isNaN`
            pos = 0

        start = Math.min(Math.max(pos, 0), stringLength)
        # Avoid the `indexOf` call if no match is possible
        if searchLength + start > stringLength
            return false

        index = -1
        while ++index < searchLength
            if string.charCodeAt(start + index) != searchString.charCodeAt(index)
                return false

        return true

    if (defineProperty)
        defineProperty(String.prototype, 'startsWith',
            value: startsWith
            configurable: true
            writable: true
        )
    else
        String.prototype.startsWith = startsWith


