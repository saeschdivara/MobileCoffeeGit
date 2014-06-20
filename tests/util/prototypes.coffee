describe('Prototypes', () ->

    beforeEach(
        () ->
    )


    ##################################################################
    # SHOULD STRING LAST TWO CHARACTERS
    ##################################################################
    it('should strip last two characters', () ->

        ###############
        ## VARIABLES ##
        ###############

        test_path_string = '/tff/fff/lll//'


        #######################
        ## TEST PREPARATIONS ##
        #######################


        ################
        ## TEST START ##
        ################

        new_string = test_path_string.lstrip("//")

        expect(new_string).toBe('/tff/fff/lll')
    )
)