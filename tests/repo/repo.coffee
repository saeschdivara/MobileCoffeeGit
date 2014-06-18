assertFileContentsEqual = (expected, repo, path) ->
        f = repo.get_named_file(path)
        if not f
            expect(expected).toBe(null)
        else
            try
                expect(f.read()).toBe(expected)
            finally
                f.close()


describe('BaseRepository', () ->

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

        repo = new BaseRepository()


        #######################
        ## TEST PREPARATIONS ##
        #######################


        ################
        ## TEST START ##
        ################

        expect(repo).toBeDefined()
    )
)


describe('CreateRepositoryTests', () ->

    _check_repo_contents = (repo, expect_bare) ->
        expect(repo.bare).toBe(expect_bare)

        assertFileContentsEqual('Unnamed repository', repo, 'description')
        assertFileContentsEqual('', repo, os.path.join('info', 'exclude'))
        assertFileContentsEqual(null, repo, 'nonexistent file')
        barestr = 'bare = '.format(expect_bare.lower())
        config_text = repo.get_named_file('config').read()
#        self.assertTrue(barestr in config_text, "%r" % config_text)

    beforeEach(
        () ->
            set_file_system('memory')
            os.mkdir('test')
            os.setRoot('test')
    )

    afterEach(
        () ->
            clear_file_system()
    )

    ##################################################################
    # SHOULD CREATE BARE REPOSITORY
    ##################################################################
    it('should create bare repository', () ->

        ###############
        ## VARIABLES ##
        ###############

        tmp_dir = Tempfile.mkdtemp()


        #######################
        ## TEST PREPARATIONS ##
        #######################


        ################
        ## TEST START ##
        ################


        repo = Repo.init_bare(tmp_dir)

        expect(repo._controldir).toBe(tmp_dir)

        _check_repo_contents(repo, true)
    )
)