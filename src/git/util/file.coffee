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

    _root_path: null
    _current_path: null

    _all_paths: null


    #######################
    ## PUBLIC PROPERTIES ##
    #######################


    ####################
    ## PUBLIC METHODS ##
    ####################

    constructor: () ->
        ###
        ###

        @_all_paths = new Object()


    mkdir: (directory_name) ->
        ###
        ###

        if @_current_path?
            current_path_str = @_current_path.path()
        else
            current_path_str = @_root_path.path()

        directory_path = current_path_str + directory_name

        directory = new DirectoryHandler(directory_path)
        @_all_paths[directory_path] = directory

        return directory


    setRoot: (directory) ->
        ###
        ###

        if isObject(directory)
            @_root_path = directory
        else
            directory_obj = @mkdir(directory)
            @setRoot(directory_obj)


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


class DirectoryHandler

    ########################
    ## PRIVATE PROPERTIES ##
    ########################


    #######################
    ## PUBLIC PROPERTIES ##
    #######################


    ####################
    ## PUBLIC METHODS ##
    ####################

    constructor: (@_path) ->
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