isObject = (variable) ->
    ###
    ###

    return variable? && typeof(variable) is 'object'

isString = () ->
    ###
    ###

    return false

isArray = () ->
    ###
    ###

    return false


isinstance = (obj, cls) ->
    ###
    ###


    return obj instanceof cls


len = () ->
    ###
    ###

    return false


pass = () ->
    ###
    ###

    return false


del = () ->
    ###
    ###

    return false

getRandomHexString = () ->
    ###
     Generates random hex number string

     @return {String}
    ###

    return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)


guid = (separator) ->
    ###
     Generates https://en.wikipedia.org/wiki/Globally_Unique_Identifier
     with random numbers

     @param {String} separator String which separates parts

     @return {String}
    ###
    return  getRandomHexString() +
            getRandomHexString() + separator +
            getRandomHexString() + separator +
            getRandomHexString() + separator +
            getRandomHexString() + separator +
            getRandomHexString() + getRandomHexString() + getRandomHexString()