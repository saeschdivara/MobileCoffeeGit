describe('Helper Functions', () ->

    beforeEach(
        () ->
    )

    ##################################################################
    # SHOULD DETECT THAT OBJECT IS OBJECT
    ##################################################################
    it('should detect that object is object', () ->

        ###############
        ## VARIABLES ##
        ###############

        short_way_object = {}
        named_object = new Object()
        number = 212
        a_function = () ->
        a_string = 'sfafads'
        an_array = []
        a_named_array = new Array()

        #######################
        ## TEST PREPARATIONS ##
        #######################


        ################
        ## TEST START ##
        ################

        # These should be objects
        expect( isObject(short_way_object) ).toBe(true)
        expect( isObject(named_object) ).toBe(true)
        expect( isObject(a_named_array) ).toBe(true)
        expect( isObject(an_array) ).toBe(true)

        # These should not be
        expect( isObject(number) ).toBe(false)
        expect( isObject(a_function) ).toBe(false)
        expect( isObject(a_string) ).toBe(false)
    )
)