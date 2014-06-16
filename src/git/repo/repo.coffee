class BaseRepository

    ########################
    ## PRIVATE PROPERTIES ##
    ########################

    _graphpoints


    #######################
    ## PUBLIC PROPERTIES ##
    #######################

    object_store: null
    refs: null
    hooks: null


    ####################
    ## PUBLIC METHODS ##
    ####################

    constructor: (object_store, refs) ->
        ###
            Open a repository.

            This shouldn't be called directly, but rather through one of the
            base classes, such as MemoryRepo or Repo.

            :param object_store: Object store to use
            :param refs: Refs container to use
        ###

        @object_store = object_store
        @refs = refs

        @_graftpoints = new Object()
        @hooks = new Object()


    #####################
    ## PRIVATE METHODS ##
    #####################