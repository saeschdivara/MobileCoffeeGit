describe('FileHandler', () ->

    beforeEach(
        () ->
    )


    ##################################################################
    # SHOULD BE HERE
    ##################################################################
    it('should be here', () ->

        ###############
        ## VARIABLES ##
        ###############

        file_handler = new FileHandler()


        #######################
        ## TEST PREPARATIONS ##
        #######################


        ################
        ## TEST START ##
        ################

        expect(file_handler).toBeDefined()
    )
)


describe('PathHelper', () ->


    beforeEach(
        () ->
            set_file_system('memory')
    )

    afterEach(
        () ->
            clear_file_system()
    )

    ##################################################################
    # SHOULD JOIN THREE PATH NAMES TOGETHER
    ##################################################################
    it('should join three path names together', () ->

        ###############
        ## VARIABLES ##
        ###############

        root_path = '/foo/bar/'
        path1 = 'bare'
        path2 = 'test'


        #######################
        ## TEST PREPARATIONS ##
        #######################


        ################
        ## TEST START ##
        ################

        joined_path = os.path.join(root_path, path1, path2)

        expect(joined_path).toBe('/foo/bar/bare/test/')
    )
)