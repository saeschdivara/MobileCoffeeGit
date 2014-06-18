class AbstractFileSystem

    ########################
    ## PRIVATE PROPERTIES ##
    ########################


    #######################
    ## PUBLIC PROPERTIES ##
    #######################


    ####################
    ## PUBLIC METHODS ##
    ####################

    constructor: () ->
        ###
        ###


    #####################
    ## PRIVATE METHODS ##
    #####################


class MemoryFileSystem extends AbstractFileSystem

    ########################
    ## PRIVATE PROPERTIES ##
    ########################


    #######################
    ## PUBLIC PROPERTIES ##
    #######################


    ####################
    ## PUBLIC METHODS ##
    ####################

    constructor: () ->
        ###
        ###


    #####################
    ## PRIVATE METHODS ##
    #####################


###
    This class is to be intended to abstract a file
    and where the content is saved to
###
class FileHandler

    ########################
    ## PRIVATE PROPERTIES ##
    ########################


    #######################
    ## PUBLIC PROPERTIES ##
    #######################


    ####################
    ## PUBLIC METHODS ##
    ####################

    constructor: () ->
        ###
        ###


    #####################
    ## PRIVATE METHODS ##
    #####################


################################################################
# FILE SYSTEM CHOOSING
################################################################

# By default os is null
os = null

set_file_system = (cls_string) ->
    ###
    ###

    switch
        when cls_string is 'memory' then os = new MemoryFileSystem()