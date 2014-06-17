class BaseRepository

    ########################
    ## PRIVATE PROPERTIES ##
    ########################

    _graphpoints: null


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


    openIndex: () ->
        ###
            Open the index for this repository.

            :raise NoIndexPresent: If no index is present
            :return: The matching `Index`
        ###

        throw Error("NotImplementedError(self.openIndex)")


    fetch: (target, determine_wants=null, progress=null) ->
        ###
            Fetch objects into another repository.

            :param target: The target repository
            :param determine_wants: Optional function to determine what refs to
                fetch.
            :param progress: Optional progress function
            :return: The local refs
        ###

        if determine_wants is null
            determine_wants = target.object_store.determine_wants_all

        target.object_store.addObjects(
          self.fetchObjects(determine_wants, target.graphWalker(), progress)
        )

        return @getReferences()


    getFileByName: (path) ->
        ###
            Get a file from the control dir with a specific name.

            Although the filename should be interpreted as a filename relative to
            the control dir in a disk-based Repo, the object returned need not be
            pointing to a file in that location.

            :param path: The path to the file, relative to the control dir.
            :return: An open file object, or None if the file does not exist.
        ###

        throw Error("NotImplementedError(self.getFileByName)")


    #####################
    ## PRIVATE METHODS ##
    #####################

    _createFileByName: (path, contents) ->
        ###
            Write a file to the control dir with the given name and contents.

            :param path: The path to the file, relative to the control dir.
            :param contents: A string to write to the file.
        ###

        throw Error("NotImplementedError(self._createFileByName)")











    fetchObjects: (determine_wants, graph_walker, progress, get_tagged=None) ->
        ###
            Fetch the missing objects required for a set of revisions.

            :param determine_wants: Function that takes a dictionary with heads
                and returns the list of heads to fetch.
            :param graph_walker: Object that can iterate over the list of revisions
                to fetch and has an "ack" method that will be called to acknowledge
                that a revision is present.
            :param progress: Simple progress function that will be called with
                updated progress strings.
            :param get_tagged: Function that returns a dict of pointed-to sha -> tag
                sha for including tags.
            :return: iterator over objects, with __len__ implemented
        ###

        wants = determine_wants(@getReferences())
        if not isinstance(wants, list)
            raise TypeError("determine_wants() did not return a list")

        shallows = getattr(graph_walker, 'shallow', frozenset())
        unshallows = getattr(graph_walker, 'unshallow', frozenset())

        if wants == []
            # TODO(dborowitz): find a way to short-circuit that doesn't change
            # this interface.

            if shallows or unshallows
                # Do not send a pack in shallow short-circuit path
                return null

            return []

        haves = self.object_store.find_common_revisions(graph_walker)

        # Deal with shallow requests separately because the haves do
        # not reflect what objects are missing
        if shallows or unshallows
            haves = []  # TODO: filter the haves commits from iter_shas.
                        # the specific commits aren't missing.

        get_parents = (commit) ->
            if commit.id in shallows
                return []
            return self.get_parents(commit.id, commit)

        return @object_store.iter_shas(
          @object_store.find_missing_objects(
              haves, wants, progress,
              get_tagged,
              get_parents=get_parents))

    get_graph_walker: (heads=null) ->
        ###
            Retrieve a graph walker.

            A graph walker is used by a remote repository (or proxy)
            to find out which objects are present in this repository.

            :param heads: Repository heads to use (optional)
            :return: A graph walker object
        ###
        if heads is null
            heads = self.refs.as_dict('refs/heads').values()

        return ObjectStoreGraphWalker(heads, self.get_parents)

    get_refs: () ->
        ###
            Get dictionary with all refs.

            :return: A ``dict`` mapping ref names to SHA1s
        ###
        return @refs.as_dict()

    head: () ->
        ###Return the SHA1 pointed at by HEAD.###
        return @refs['HEAD']

    _get_object: (sha, cls) ->
        assert len(sha) in [20, 40]
        ret = self.get_object(sha)
        if not isinstance(ret, cls)
            if cls is Commit
                throw Error(" NotCommitError(ret) ")
            else if cls is Blob
                throw Error(" NotBlobError(ret) ")
            else if cls is Tree
                throw Error(" NotTreeError(ret) ")
            else if cls is Tag
                throw Error(" NotTagError(ret) ")
            else
                throw Error(' Exception("Type invalid: %r != %r" % ( ret.type_name, cls.type_name))')
        return ret

    get_object: (sha) ->
        ###
            Retrieve the object with the specified SHA.

            :param sha: SHA to retrieve
            :return: A ShaFile object
            :raise KeyError: when the object can not be found
        ###
        return @object_store[sha]

    get_parents: (sha, commit=null) ->
        ###
            Retrieve the parents of a specific commit.

            If the specific commit is a graftpoint, the graft parents
            will be returned instead.

            :param sha: SHA of the commit for which to retrieve the parents
            :param commit: Optional commit matching the sha
            :return: List of parents
        ###

        try
            return self._graftpoints[sha]
        catch err
            if commit is null
                commit = @[sha]
            return commit.parents

    get_config: () ->
        ###
            Retrieve the config object.

            :return: `ConfigFile` object for the ``.git/config`` file.
        ###
        throw Error('raise NotImplementedError(self.get_config)')

    get_description: () ->
        ###
            Retrieve the description for this repository.

            :return: String with the description of the repository
                as set by the user.
        ###

        throw Error('raise NotImplementedError(self.get_description)')

    set_description: (description) ->
        ###
            Set the description for this repository.

            :param description: Text to set as description for this repository.
        ###

        throw Error('raise NotImplementedError(self.set_description)')

    get_config_stack: () ->
        ###
            Return a config stack for this repository.

            This stack accesses the configuration for both this repository
            itself (.git/config) and the global configuration, which usually
            lives in ~/.gitconfig.

            :return: `Config` instance for this repository
        ###

        # from dulwich.config import StackedConfig
        backends = [@get_config()] + StackedConfig.default_backends()
        return StackedConfig(backends, writable=backends[0])

    get_peeled: (ref) ->
        ###
            Get the peeled value of a ref.

            :param ref: The refname to peel.
            :return: The fully-peeled SHA1 of a tag object, after peeling all
                intermediate tags; if the original ref does not point to a tag, this
                will equal the original SHA1.
        ###
        cached = @refs.get_peeled(ref)
        if not cached is null
            return cached
        return @object_store.peel_sha(@refs[ref]).id

    get_walker: (include=null, args, kwargs) ->
        ###
        Obtain a walker for this repository.

        :param include: Iterable of SHAs of commits to include along with their
            ancestors. Defaults to [HEAD]
        :param exclude: Iterable of SHAs of commits to exclude along with their
            ancestors, overriding includes.
        :param order: ORDER_* constant specifying the order of results. Anything
            other than ORDER_DATE may result in O(n) memory usage.
        :param reverse: If True, reverse the order of output, requiring O(n)
            memory.
        :param max_entries: The maximum number of entries to yield, or None for
            no limit.
        :param paths: Iterable of file or subtree paths to show entries for.
        :param rename_detector: diff.RenameDetector object for detecting
            renames.
        :param follow: If True, follow path across renames/copies. Forces a
            default rename_detector.
        :param since: Timestamp to list commits after.
        :param until: Timestamp to list commits before.
        :param queue_cls: A class to use for a queue of commits, supporting the
            iterator protocol. The constructor takes a single argument, the
            Walker.
        :return: A `Walker` object
        ###

        # from dulwich.walk import Walker
        if include is null
            include = [@head()]
        if isinstance(include, str)
            include = [include]

        kwargs['get_parents'] = (commit) -> @get_parents(commit.id, commit)

        return Walker(@object_store, include, args, kwargs)

    __getitem__: (name) ->
        ###
            Retrieve a Git object by SHA1 or ref.

            :param name: A Git object SHA1 or a ref name
            :return: A `ShaFile` object, such as a Commit or Blob
            :raise KeyError: when the specified ref or object does not exist
        ###
        if not isinstance(name, str)
            throw Error('raise TypeError("name must be bytestring, not %.80s" % type(name).__name__)')

        if len(name) in [20, 40]
            try
                return self.object_store[name]
            catch err
                pass
        try
            return @object_store[@refs[name]]
        catch err
            throw Error('raise KeyError(name)')

    __contains__: (name) ->
        ###
            Check if a specific Git object or ref is present.

            :param name: Git object SHA1 or ref name
        ###

        if len(name) in [20, 40]
            return name in @object_store or name in @refs
        else
            return name in @refs

    __setitem__: (name, value) ->
        ###
            Set a ref.

            :param name: ref name
            :param value: Ref value - either a ShaFile object, or a hex sha
        ###

        if name.startswith("refs/") or name == "HEAD"
            if isinstance(value, ShaFile)
                @refs[name] = value.id
            else if isinstance(value, str)
                @refs[name] = value
            else
                throw Error('raise TypeError(value)')
        else
            throw Error('raise ValueError(name)')

    __delitem__: (name) ->
        ###
            Remove a ref.

            :param name: Name of the ref to remove
        ###

        if name.startswith("refs/") or name == "HEAD"
            delete @refs[name]
        else
            throw Error('raise ValueError(name)')

    _get_user_identity: () ->
        ###
            Determine the identity to use for new commits.
        ###

        config = @get_config_stack()
        return "%s <%s>".format(config.get(["user", ], "name"), config.get(["user", ], "email"))

    _add_graftpoints: (updated_graftpoints) ->
        ###
            Add or modify graftpoints

            :param updated_graftpoints: Dict of commit shas to list of parent shas
        ###

        # Simple validation
        for commit, parents in updated_graftpoints.iteritems()
            for sha in [commit] + parents
                check_hexsha(sha, 'Invalid graftpoint')

        @_graftpoints.update(updated_graftpoints)

    _remove_graftpoints: (to_remove=[]) ->
        ###
            Remove graftpoints

            :param to_remove: List of commit shas
        ###
        for sha in to_remove
            del @_graftpoints[sha]


    do_commit: (message=null, committer=null,
                  author=null, commit_timestamp=null,
                  commit_timezone=null, author_timestamp=null,
                  author_timezone=null, tree=null, encoding=null,
                  ref='HEAD', merge_heads=null) ->
        ###
            Create a new commit.

            :param message: Commit message
            :param committer: Committer fullname
            :param author: Author fullname (defaults to committer)
            :param commit_timestamp: Commit timestamp (defaults to now)
            :param commit_timezone: Commit timestamp timezone (defaults to GMT)
            :param author_timestamp: Author timestamp (defaults to commit timestamp)
            :param author_timezone: Author timestamp timezone
                (defaults to commit timestamp timezone)
            :param tree: SHA1 of the tree root to use (if not specified the
                current index will be committed).
            :param encoding: Encoding
            :param ref: Optional ref to commit to (defaults to current branch)
            :param merge_heads: Merge heads (defaults to .git/MERGE_HEADS)
            :return: New commit SHA1
        ###

        # import time
        c = new Commit()
        if tree is null
            index = @open_index()
            c.tree = index.commit(self.object_store)
        else
            if len(tree) != 40
                throw Error('raise ValueError("tree must be a 40-byte hex sha string")')

            c.tree = tree

        try
            @hooks['pre-commit'].execute()
#        catch HookError as e
#            raise CommitError(e)
#        except KeyError:  # no hook defined, silent fallthrough
        catch e
            pass

        if merge_heads is null
            # FIXME: Read merge heads from .git/MERGE_HEADS
            merge_heads = []

        if committer is null
            # FIXME: Support GIT_COMMITTER_NAME/GIT_COMMITTER_EMAIL environment
            # variables
            committer = @_get_user_identity()
        c.committer = committer

        if commit_timestamp is null
            # FIXME: Support GIT_COMMITTER_DATE environment variable
            commit_timestamp = time.time()
        c.commit_time = int(commit_timestamp)

        if commit_timezone is null
            # FIXME: Use current user timezone rather than UTC
            commit_timezone = 0
        c.commit_timezone = commit_timezone

        if author is null
            # FIXME: Support GIT_AUTHOR_NAME/GIT_AUTHOR_EMAIL environment
            # variables
            author = committer
        c.author = author

        if author_timestamp is null
            # FIXME: Support GIT_AUTHOR_DATE environment variable
            author_timestamp = commit_timestamp
        c.author_time = int(author_timestamp)

        if author_timezone is null
            author_timezone = commit_timezone
        c.author_timezone = author_timezone

        if encoding is not null
            c.encoding = encoding

        if message is null
            # FIXME: Try to read commit message from .git/MERGE_MSG
            raise ValueError("No commit message specified")

        try
            c.message = @hooks['commit-msg'].execute(message)
            if c.message is null
                c.message = message
#        except HookError as e:
#            raise CommitError(e)
#        except KeyError:  # no hook defined, message not modified
#            c.message = message
        catch e

        if ref is null
            # Create a dangling commit
            c.parents = merge_heads
            @object_store.add_object(c)
        else
            try
                old_head = @refs[ref]
                c.parents = [old_head] + merge_heads
                @object_store.add_object(c)
                ok = @refs.set_if_equals(ref, old_head, c.id)
            catch err
                c.parents = merge_heads
                @object_store.add_object(c)
                ok = @refs.add_if_new(ref, c.id)
            if not ok
                # Fail if the atomic compare-and-swap failed, leaving the commit and
                # all its objects as garbage.
                throw Error('raise CommitError("%s changed during commit" % (ref,))')

        try
            @hooks['post-commit'].execute()
#        except HookError as e:  # silent failure
#            warnings.warn("post-commit hook failed: %s" % e, UserWarning)
#        except KeyError:  # no hook defined, silent fallthrough
#            pass
        catch err

        return c.id













class Repo extends BaseRepository
    ###
        A git repository backed by local disk.

        To open an existing repository, call the contructor with
        the path of the repository.

        To create a new repository, use the Repo.init class method.
    ###

    constructor: (root) ->
        if os.path.isdir(os.path.join(root, ".git", PATHS.OBJECTS))
            @bare = false
            @_controldir = os.path.join(root, ".git")
        else if (os.path.isdir(os.path.join(root, OBJECTDIR)) and
              os.path.isdir(os.path.join(root, REFSDIR)))
            @bare = True
            @_controldir = root
        else if (os.path.isfile(os.path.join(root, ".git")))
            # import re
            f = open(os.path.join(root, ".git"), 'r')
            try
#                _, path = re.match('(gitdir: )(.+$)', f.read()).groups()
            finally
                f.close()
            @bare = False
            @_controldir = os.path.join(root, path)
        else
            throw Error('''
            raise NotGitRepository(
                "No git repository was found at %(path)s" % dict(path=root)
            ) ''')

        @path = root
        object_store = DiskObjectStore(os.path.join(@controldir(),
                                                    OBJECTDIR))
        refs = DiskRefsContainer(@controldir())
        super(object_store, refs)

        @_graftpoints = new Object()
        graft_file = @get_named_file(os.path.join("info", "grafts"))
        if graft_file
            @_graftpoints.update(parse_graftpoints(graft_file))
        graft_file = @get_named_file("shallow")
        if graft_file
            @_graftpoints.update(parse_graftpoints(graft_file))

        @hooks['pre-commit'] = PreCommitShellHook(@controldir())
        @hooks['commit-msg'] = CommitMsgShellHook(@controldir())
        @hooks['post-commit'] = PostCommitShellHook(@controldir())

    controldir: () ->
        ### Return the path of the control directory.###
        return @_controldir

    _put_named_file: (path, contents) ->
        ###
            Write a file to the control dir with the given name and contents.

            :param path: The path to the file, relative to the control dir.
            :param contents: A string to write to the file.
        ###

        path = path.lstrip(os.path.sep)
        f = GitFile(os.path.join(self.controldir(), path), 'wb')
        try
            f.write(contents)
        finally
            f.close()

    get_named_file: (path) ->
        ###
            Get a file from the control dir with a specific name.

            Although the filename should be interpreted as a filename relative to
            the control dir in a disk-based Repo, the object returned need not be
            pointing to a file in that location.

            :param path: The path to the file, relative to the control dir.
            :return: An open file object, or None if the file does not exist.
        ###

        # TODO(dborowitz): sanitize filenames, since this is used directly by
        # the dumb web serving code.
        path = path.lstrip(os.path.sep)
        try
            return open(os.path.join(self.controldir(), path), 'rb')
        catch e
            if e.errno == errno.ENOENT
                return null
#            raise

    index_path: () ->
        ### Return path to the index file. ###
        return os.path.join(@controldir(), INDEX_FILENAME)

    open_index: () ->
        ###
            Open the index for this repository.

            :raise NoIndexPresent: If no index is present
            :return: The matching `Index`
        ###

        #from dulwich.index import Index

        if not @has_index()
            throw Error('NoIndexPresent()')
        return Index(@index_path())

    has_index: () ->
        ### Check if an index is present. ###
        # Bare repos must never have index files; non-bare repos may have a
        # missing index file, which is treated as empty.
        return not @bare


    stage: (paths) ->
        ###
            Stage a set of paths.

            :param paths: List of paths, relative to the repository path
        ###
        if isinstance(paths, basestring)
            paths = [paths]
#        from dulwich.index import (
#            blob_from_path_and_stat,
#            index_entry_from_stat,
#            )
        index = @open_index()
        for path in paths
            full_path = os.path.join(self.path, path)
            try
                st = os.lstat(full_path)
            catch err
                # File no longer exists
                try
                    del index[path]
                catch key_err
                    pass  # already removed
            finally
                blob = blob_from_path_and_stat(full_path, st)
                @object_store.add_object(blob)
                index[path] = index_entry_from_stat(st, blob.id, 0)
        index.write()

    clone: (target_path, mkdir=True, bare=False, origin="origin") ->
        ###
            Clone this repository.

            :param target_path: Target path
            :param mkdir: Create the target directory
            :param bare: Whether to create a bare repository
            :param origin: Base name for refs in target repository
                cloned from this repository
            :return: Created repository as `Repo`
        ###

        if not bare
            target = @init(target_path, mkdir=mkdir)
        else
            target = @init_bare(target_path)

        @fetch(target)
        target.refs.import_refs('refs/remotes/' + origin, self.refs.as_dict('refs/heads'))
        target.refs.import_refs('refs/tags', @refs.as_dict('refs/tags'))

        try
            target.refs.add_if_new('refs/heads/master', @refs['refs/heads/master'])
        catch err
            pass

        # Update target head
#        head, head_sha = self.refs._follow('HEAD')
        head = null
        head_sha = @refs._follow('HEAD')
        if head? and head_sha?
            target.refs.set_symbolic_ref('HEAD', head)
            target['HEAD'] = head_sha

            if not bare
                # Checkout HEAD to target dir
                target._build_tree()

        return target

    _build_tree: () ->
#        from dulwich.index import build_index_from_tree
        config = @get_config()
        honor_filemode = config.get_boolean('core', 'filemode', os.name != "nt")
        return build_index_from_tree(@path, @index_path(), @object_store, @['HEAD'].tree, honor_filemode=honor_filemode)

    get_config: () ->
        ###
            Retrieve the config object.

            :return: `ConfigFile` object for the ``.git/config`` file.
        ###
#        from dulwich.config import ConfigFile
        path = os.path.join(@_controldir, 'config')
        try
            return ConfigFile.from_path(path)
        catch e
            if e.errno != errno.ENOENT
                raise
            ret = ConfigFile()
            ret.path = path
            return ret

    get_description: () ->
        ###
            Retrieve the description of this repository.

            :return: A string describing the repository or None.
        ###
        path = os.path.join(self._controldir, 'description')
        try
            f = GitFile(path, 'rb')
            try
                return f.read()
            finally
                f.close()
        catch e
            if e.errno != errno.ENOENT
                throw Error('')
            return null

    __repr__: () ->
        return "<Repo at %r>".format(@path)

    set_description: (description) ->
        ###
            Set the description for this repository.

            :param description: Text to set as description for this repository.
        ###

        path = os.path.join(@_controldir, 'description')
        f = open(path, 'w')
        try
            f.write(description)
        finally
            f.close()

    @_init_maybe_bare: (path, bare) ->
        for d in BASE_DIRECTORIES
            os.mkdir(os.path.join(path, d))
        DiskObjectStore.init(os.path.join(path, OBJECTDIR))
        ret = new Repo(path)
        ret.refs.set_symbolic_ref("HEAD", "refs/heads/master")
        ret._init_files(bare)

        return ret

    @init: (path, mkdir=False) ->
        ###
            Create a new repository.

            :param path: Path in which to create the repository
            :param mkdir: Whether to create the directory
            :return: `Repo` instance
        ###

        if mkdir
            os.mkdir(path)
        controldir = os.path.join(path, ".git")
        os.mkdir(controldir)
        Repo._init_maybe_bare(controldir, false)

        return new Repo(path)

    @init_bare: (path) ->
        ###
            Create a new bare repository.

            ``path`` should already exist and be an emty directory.

            :param path: Path to create bare repository in
            :return: a `Repo` instance
        ###

        return Repo._init_maybe_bare(path, true)

    @create: Repo.init_bare


class MemoryRepo extends BaseRepository
    ###
        Repo that stores refs, objects, and named files in memory.

        MemoryRepos are always bare: they have no working tree and no index, since
        those have a stronger dependency on the filesystem.
    ###

    constructor:() ->
#        from dulwich.config import ConfigFile
        super(MemoryObjectStore(), DictRefsContainer(new Object()))
        @_named_files = new Object()
        @bare = true
        @_config = new ConfigFile()

    _put_named_file: (path, contents) ->
        ###
            Write a file to the control dir with the given name and contents.

            :param path: The path to the file, relative to the control dir.
            :param contents: A string to write to the file.
        ###

        @_named_files[path] = contents

    get_named_file: (path) ->
        ###
            Get a file from the control dir with a specific name.

            Although the filename should be interpreted as a filename relative to
            the control dir in a disk-baked Repo, the object returned need not be
            pointing to a file in that location.

            :param path: The path to the file, relative to the control dir.
            :return: An open file object, or None if the file does not exist.
        ###

        contents = @_named_files.get(path, null)
        if contents is null
            return null
        return new BytesIO(contents)

    open_index: () ->
        ###
            Fail to open index for this repo, since it is bare.

            :raise NoIndexPresent: Raised when no index is present
        ###
        throw Error('NoIndexPresent()')

    get_config: () ->
        ###
            Retrieve the config object.

            :return: `ConfigFile` object.
        ###
        return @_config

    get_description: () ->
        ###
            Retrieve the repository description.

            This defaults to None, for no description.
        ###
        return None

    @init_bare: (objects, refs) ->
        """Create a new bare repository in memory.

        :param objects: Objects for the new repository,
            as iterable
        :param refs: Refs as dictionary, mapping names
            to object SHA1s
        """
        ret = new MemoryRepo()
        for obj in objects
            ret.object_store.add_object(obj)
        for refname, sha in refs.iteritems()
            ret.refs[refname] = sha
        ret._init_files(bare=True)
        return ret
