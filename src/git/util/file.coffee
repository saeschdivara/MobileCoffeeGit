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

        @path = new PathHelper()


    #####################
    ## PRIVATE METHODS ##
    #####################


class PathHelper

    ########################
    ## PRIVATE PROPERTIES ##
    ########################


    #######################
    ## PUBLIC PROPERTIES ##
    #######################

    path_separator: ''
    sep: ''


    ####################
    ## PUBLIC METHODS ##
    ####################

    constructor: () ->
        ###
        ###

        @path_separator = '/'
        @sep = @path_separator
    
        
    join: () ->
        ###
        ###

        path = ''

        for arg in arguments

            # Check if it is a directory
            if @isdir(arg)
                # Check if it is an object
                if isObject(arg)
                    arg = arg.path()

            else if isObject(arg) and arg.hasOwnProperty('length')
                arg = PathHelper.prototype.join.apply(@, arg)

            path += arg + @path_separator
            # If arg had already a / at the end
            path = path.replace('//', '/')

        return path


    isfile: (file) ->
        ###
        ###

        if not isObject(file)
            file = os.file(file)

        return file instanceof FileHandler


    isdir: (dir) ->
        ###
        ###

        if not isObject(dir)
            dir = os.file(dir)

        return dir instanceof DirectoryHandler



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
    _temporary_paths: null


    #######################
    ## PUBLIC PROPERTIES ##
    #######################


    ####################
    ## PUBLIC METHODS ##
    ####################

    constructor: () ->
        ###
        ###

        super

        @_all_paths = new Object()
        @_temporary_paths = new Object()


    mkdir: (directory_name) ->
        ###
        ###

        if @_current_path?
            current_path_str = @_current_path.path()
        else if @_root_path?
            current_path_str = @_root_path.path()
        else
            current_path_str = '/'

        if not directory_name.startsWith('/')
            directory_path = current_path_str + directory_name
        else
            directory_path = directory_name

        directory = new DirectoryHandler(directory_path)
        @_all_paths[directory_path] = directory

        return directory


    mkdtemp: () ->
        ###
        ###

        temp_name = getRandomHexString() + '.tmp'
        temp_directory = @mkdir(temp_name)
        @_temporary_paths[temp_directory.path()] = temp_directory


    file: (path) ->
        ###
        ###

        return @_all_paths[path]


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

    _is_open: false
    _open_mode: 0


    #######################
    ## PUBLIC PROPERTIES ##
    #######################


    ####################
    ## PUBLIC METHODS ##
    ####################

    constructor: () ->
        ###
        ###


    open: (mode) ->
        ###
        ###

        #


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


    path: () ->
        ###
        ###

        return @_path


    #####################
    ## PRIVATE METHODS ##
    #####################


################################################################
# FILE SYSTEM GLOBAL FUNCTIONS
################################################################

open = (name, mode=null, buffering=null) ->
    ###
        open(name[, mode[, buffering]]) -> file object

        Open a file using the file() type, returns a file object.  This is the
        preferred way to open a file.  See file.__doc__ for further information.
    ###

    file = new FileHandler()
    file.open(mode)

    return file


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


clear_file_system = () ->
    ###
    ###

    # For now do nothing