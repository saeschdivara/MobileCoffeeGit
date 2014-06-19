ZERO_SHA = ''

class BaseObjectStore
    ### Object store interface.###

   determine_wants_all: (refs) ->
#        return [sha for ref, sha in refs.iteritems()
#                if not sha in self and not ref.endswith("^{}") and
#                   not sha == ZERO_SHA ]

   iter_shas: (shas) ->
        ###
            Iterate over the objects for the specified shas.

            :param shas: Iterable object with SHAs
            :return: Object iterator
        ###
        return ObjectStoreIterator(@, shas)

   contains_loose: (sha) ->
        ###Check if a particular object is present by SHA1 and is loose.###
        throw Error(' NotImplementedError(@contains_loose)')

   contains_packed: (sha) ->
        ###Check if a particular object is present by SHA1 and is packed.###
        throw Error('NotImplementedError(@contains_packed)')

   __contains__: (sha) ->
        ###
            Check if a particular object is present by SHA1.

            This method makes no distinction between loose and packed objects.
        ###
#        return (@contains_packed(sha) or @contains_loose(sha))

   packs: () ->
        ###Iterable of pack objects.###
        throw Error(' NotImplementedError')

   get_raw: (name) ->
        ###
            Obtain the raw text for an object.

            :param name: sha for the object.
            :return: tuple with numeric type and object contents.
        ###
        throw Error('NotImplementedError(@get_raw)')

   __getitem__: (sha) ->
        ###Obtain an object by SHA1.###
#        type_num, uncomp = @get_raw(sha)
        return ShaFile.from_raw_string(type_num, uncomp, sha=sha)

   __iter__: () ->
        ###Iterate over the SHAs that are present in this store.###
        throw Error(' NotImplementedError(@__iter__)')

   add_object: (obj) ->
        ###
            Add a single object to this object store.
        ###
        throw Error('NotImplementedError(@add_object)')

   add_objects: (objects) ->
        ###
            Add a set of objects to this object store.

            :param objects: Iterable over a list of objects.
        ###
        throw Error('NotImplementedError(@add_objects)')

   tree_changes: (source, target, want_unchanged=false) ->
        ###
            Find the differences between the contents of two trees

            :param source: SHA1 of the source tree
            :param target: SHA1 of the target tree
            :param want_unchanged: Whether unchanged files should be reported
            :return: Iterator over tuples with
                (oldpath, newpath), (oldmode, newmode), (oldsha, newsha)
        ###
#        for change in tree_changes(self, source, target,
#                                   want_unchanged=want_unchanged) ->
#            yield ((change.old.path, change.new.path),
#                   (change.old.mode, change.new.mode),
#                   (change.old.sha, change.new.sha))

   iter_tree_contents: (tree_id, include_trees=false) ->
        ###
            Iterate the contents of a tree and all subtrees.

            Iteration is depth-first pre-order, as in e.g. os.walk.

            :param tree_id: SHA1 of the tree.
            :param include_trees: If True, include tree objects in the iteration.
            :return: Iterator over TreeEntry namedtuples for all the objects in a
                tree.
        ###
#        for entry, _ in walk_trees(self, tree_id,null) ->
#            if not stat.S_ISDIR(entry.mode) or include_trees
#                yield entry

   find_missing_objects: (haves, wants, progress=None,
                             get_tagged=None,
                             get_parents=(commit) -> commit.parents) ->
        ###
            Find the missing objects required for a set of revisions.

            :param haves: Iterable over SHAs already in common.
            :param wants: Iterable over SHAs of objects to fetch.
            :param progress: Simple progress function that will be called with
                updated progress strings.
            :param get_tagged: Function that returns a dict of pointed-to sha -> tag
                sha for including tags.
            :param get_parents: Optional function for getting the parents of a commit.
            :return: Iterator over (sha, path) pairs.
        ###
        finder = MissingObjectFinder(self, haves, wants, progress, get_tagged, get_parents=get_parents)
        return iter(finder.next, null)

   find_common_revisions: (graphwalker) ->
        ###
            Find which revisions this store has in common using graphwalker.

            :param graphwalker: A graphwalker object.
            :return: List of SHAs that are in common
        ###

        haves = []
        sha = next(graphwalker)

        while sha
            if sha in @
                haves.append(sha)
                graphwalker.ack(sha)
            sha = next(graphwalker)
        return haves

   generate_pack_contents: (have, want, progress=null) ->
        ###Iterate over the contents of a pack file.

        :param have: List of SHA1s of objects that should not be sent
        :param want: List of SHA1s of objects that should be sent
        :param progress: Optional progress reporting method
        ###
        return @iter_shas(@find_missing_objects(have, want, progress))

   peel_sha: (sha) ->
        ###
            Peel all tags from a SHA.

            :param sha: The object SHA to peel.
            :return: The fully-peeled SHA1 of a tag object, after peeling all
                intermediate tags; if the original ref does not point to a tag, this
                will equal the original SHA1.
        ###
        obj = @[sha]
        obj_class = object_class(obj.type_name)
        while obj_class is Tag
#            obj_class, sha = obj.object
            obj = @[sha]
        return obj

   _collect_ancestors: (heads, common=set(), get_parents=(commit) -> commit.parents) ->
        ###Collect all ancestors of heads up to (excluding) those in common.

        :param heads: commits to start from
        :param common: commits to end at, or empty set to walk repository
            completely
        :param get_parents: Optional function for getting the parents of a commit.
        :return: a tuple (A, B) where A - all commits reachable
            from heads but not present in common, B - common (shared) elements
            that are directly reachable from heads
        ###
        bases = set()
        commits = set()
        queue = []
        queue.extend(heads)
        while queue
            e = queue.pop(0)
            if e in common
                bases.add(e)
            else if e not in commits
                commits.add(e)
                cmt = self[e]
                queue.extend(get_parents(cmt))
        return [commits, bases]

   close: () ->
        ###Close any files opened by this object store.###
        # Default implementation is a NO-OP


class PackBasedObjectStore extends BaseObjectStore

   constructor: () ->
        @_pack_cache = {}

   alternates: () ->
        return []

   contains_packed: (sha) ->
        ###Check if a particular object is present by SHA1 and is packed.

        This does not check alternates.
        ###
        for pack in @packs
            if sha in pack
                return true
        return false

   __contains__: (sha) ->
        ###Check if a particular object is present by SHA1.

        This method makes no distinction between loose and packed objects.
        ###
        if @contains_packed(sha) or @contains_loose(sha)
            return true

#       for alternate in @alternates
#
#            if sha in alternate
#                return true

        return false

   _pack_cache_stale: () ->
        ###Check whether the pack cache is stale.###
        throw Error('NotImplementedError(@_pack_cache_stale)')

   _add_known_pack: (base_name, pack) ->
        ###Add a newly appeared pack to the cache by path.

        ###
        @_pack_cache[base_name] = pack

   close: () ->
        pack_cache = @_pack_cache
        @_pack_cache = {}
        while pack_cache
#            (name, pack) = pack_cache.popitem()
            pack.close()

   packs: () ->
        ###List with pack objects.###
        if @_pack_cache is null or @_pack_cache_stale()
            @_update_pack_cache()

        return @_pack_cache.values()

   _iter_alternate_objects: () ->
        ###Iterate over the SHAs of all the objects in alternate stores.###
        for alternate in @alternates
            for alternate_object in alternate
                pass
#                yield alternate_object

   _iter_loose_objects: () ->
        ###Iterate over the SHAs of all loose objects.###
        throw Error('NotImplementedError(@_iter_loose_objects)')

   _get_loose_object: (sha) ->
        throw Error('NotImplementedError(@_get_loose_object)')

   _remove_loose_object: (sha) ->
        throw Error('NotImplementedError(@_remove_loose_object)')

   pack_loose_objects: () ->
        ###Pack loose objects.

        :return: Number of objects packed
        ###
        objects = set()
        for sha in @_iter_loose_objects()
            objects.add(@_get_loose_object(sha), null)
            
        @add_objects(list(objects))

        for obj, path in objects
            @_remove_loose_object(obj.id)
        return len(objects)

   __iter__: () ->
        ###Iterate over the SHAs that are present in this store.###
        iterables = @packs + [@_iter_loose_objects()] + [@_iter_alternate_objects()]
        return chain(iterables)

   contains_loose: ( sha) ->
        ###Check if a particular object is present by SHA1 and is loose.

        This does not check alternates.
        ###
        return @_get_loose_object(sha)?

   get_raw: (name) ->
        ###Obtain the raw text for an object.

        :param name: sha for the object.
        :return: tuple with numeric type and object contents.
        ###
        if len(name) is 40
            sha = hex_to_sha(name)
            hexsha = name
        else if len(name) is 20
            sha = name
            hexsha = null
        else
            throw Error(' AssertionError("Invalid object name %r" % name)')
        for pack in @packs
            try
                return pack.get_raw(sha)
            catch err
                pass
        if hexsha is null
            hexsha = sha_to_hex(name)
        ret = @_get_loose_object(hexsha)
        if ret?
#            return ret.type_num, ret.as_raw_string()
            return null
        for alternate in @alternates
            try
                return alternate.get_raw(hexsha)
            catch err
                pass
        throw Error('KeyError(hexsha)')

   add_objects: (objects) ->
        ###Add a set of objects to this object store.

        :param objects: Iterable over objects, should support __len__.
        :return: Pack object of the objects written.
        ###
        if len(objects) is 0
            # Don't bother writing an empty pack file
            return
#        f, commit, abort = @add_pack()
        try
            write_pack_objects(f, objects)
        catch err
            abort()
            throw Error('')
        finally
            return commit()


class DiskObjectStore extends PackBasedObjectStore
    ###Git-style object store that exists on disk.###

    constructor: (path) ->
        ###Open an object store.

        :param path: Path of the object store.
        ###
        super
        @path = path
        @pack_dir = os.path.join(self.path, PACKDIR)
        @_pack_cache_time = 0
        @_pack_cache = {}
        @_alternates =null

    __repr__: () ->
#        return "<%s(%r)>" % (@__class__.__name__, self.path)
        return ''

    alternates: () ->
        if @_alternates?
            return @_alternates
        @_alternates = []
        for path in @_read_alternate_paths()
            @_alternates.append(new DiskObjectStore(path))
        return @_alternates

    _read_alternate_paths: () ->
        try
            f = GitFile(os.path.join(@path, "info", "alternates"), 'rb')
        catch e
            if e.errno == errno.ENOENT
                return []
            throw Error('')
        ret = []
        try
            for l in f.readlines()
                l = l.rstrip("\n")
                if l[0] == "#"
                    continue
                if os.path.isabs(l)
                    ret.append(l)
                else
                    ret.append(os.path.join(self.path, l))
            return ret
        finally
            f.close()

    add_alternate_path: (path) ->
        ###Add an alternate path to this object store.
        ###
        try
            os.mkdir(os.path.join(self.path, "info"))
        catch e
            if e.errno != errno.EEXIST
                throw Error('')
        alternates_path = os.path.join(self.path, "info/alternates")
        f = GitFile(alternates_path, 'wb')
        try
            try
                orig_f = open(alternates_path, 'rb')
            catch e
                if e.errno != errno.ENOENT
                    throw Error('')
            finally
                try
                    f.write(orig_f.read())
                finally
                    orig_f.close()
            f.write("%s\n" % path)
        finally
            f.close()

        if not os.path.isabs(path)
            path = os.path.join(self.path, path)
        @alternates.append(new DiskObjectStore(path))

    _update_pack_cache: () ->
        try
            pack_dir_contents = os.listdir(self.pack_dir)
        catch e
            if e.errno == errno.ENOENT
                @_pack_cache_time = 0
                @close()
                return
            raise
        @_pack_cache_time = os.stat(@pack_dir).st_mtime
        pack_files = set()
        for name in pack_dir_contents
            # TODO: verify that idx exists first
            if name.startswith("pack-") and name.endswith(".pack")
                pass
#                pack_files.add(name[:-len(".pack")])

        # Open newly appeared pack files
        for f in pack_files
            if f not in @_pack_cache
                @_pack_cache[f] = new Pack(os.path.join(@pack_dir, f))
        # Remove disappeared pack files
        for f in set(@_pack_cache) - pack_files
            @_pack_cache.pop(f).close()

    _pack_cache_stale: () ->
        try
            return os.stat(@pack_dir).st_mtime > @_pack_cache_time
        catch e
            if e.errno == errno.ENOENT
                return true
            throw Error('')

    _get_shafile_path: (sha) ->
        # Check from object dir
        return hex_to_filename(@path, sha)

    _iter_loose_objects: () ->
        for base in os.listdir(@path)
            if len(base) != 2
                continue
            for rest in os.listdir(os.path.join(@path, base))
#                yield base+rest
                pass

    _get_loose_object: (sha) ->
        path = @_get_shafile_path(sha)
        try
            return ShaFile.from_path(path)
        catch e
            if e.errno == errno.ENOENT
                return null
            throw Error('')

    _remove_loose_object: (sha) ->
        os.remove(@_get_shafile_path(sha))

    _complete_thin_pack: (f, path, copier, indexer) ->
        ###
            Move a specific file containing a pack into the pack directory.

            :note: The file should be on the same file system as the
                packs directory.

            :param f: Open file object for the pack.
            :param path: Path to the pack file.
            :param copier: A PackStreamCopier to use for writing pack data.
            :param indexer: A PackIndexer for indexing the pack.
        ###
        entries = list(indexer)

        # Update the header with the new number of objects.
        f.seek(0)
        write_pack_header(f, len(entries) + len(indexer.ext_refs()))

        # Must flush before reading (http://bugs.python.org/issue3207)
        f.flush()

        # Rescan the rest of the pack, computing the SHA with the new header.
        new_sha = compute_file_sha(f, end_ofs=-20)

        # Must reposition before writing (http://bugs.python.org/issue3207)
        f.seek(0, os.SEEK_CUR)

        # Complete the pack.
        for ext_sha in indexer.ext_refs()
            assert len(ext_sha) is 20
#            type_num, data = self.get_raw(ext_sha)
            offset = f.tell()
            crc32 = write_pack_object(f, type_num, data, sha=new_sha)
#            entries.append((ext_sha, offset, crc32))
        pack_sha = new_sha.digest()
        f.write(pack_sha)
        f.close()

        # Move the pack in.
        entries.sort()
        pack_base_name = os.path.join(
          @pack_dir, 'pack-' + iter_sha1(e[0] for e in entries))
        os.rename(path, pack_base_name + '.pack')

        # Write the index.
        index_file = GitFile(pack_base_name + '.idx', 'wb')
        try
            write_pack_index_v2(index_file, entries, pack_sha)
            index_file.close()
        finally
            index_file.abort()

        # Add the pack to the store and return it.
        final_pack = Pack(pack_base_name)
        final_pack.check_length_and_checksum()
        @_add_known_pack(pack_base_name, final_pack)
        return final_pack

    add_thin_pack: (read_all, read_some) ->
        ###Add a new thin pack to this object store.

        Thin packs are packs that contain deltas with parents that exist outside
        the pack. They should never be placed in the object store directly, and
        always indexed and completed as they are copied.

        :param read_all: Read function that blocks until the number of requested
            bytes are read.
        :param read_some: Read function that returns at least one byte, but may
            not return the number of bytes requested.
        :return: A Pack object pointing at the now-completed thin pack in the
            objects/pack directory.
        ###
#        fd, path = tempfile.mkstemp(dir=self.path, prefix='tmp_pack_')
        f = os.fdopen(fd, 'w+b')

        try
            indexer = new PackIndexer(f, resolve_ext_ref=self.get_raw)
            copier = new PackStreamCopier(read_all, read_some, f,
                                      delta_iter=indexer)
            copier.verify()
            return @_complete_thin_pack(f, path, copier, indexer)
        finally
            f.close()

    move_in_pack: (path) ->
        ###Move a specific file containing a pack into the pack directory.

        :note: The file should be on the same file system as the
            packs directory.

        :param path: Path to the pack file.
        ###
        p = new PackData(path)
        try
            entries = p.sorted_entries()
            basename = os.path.join(self.pack_dir,
                "pack-%s" % iter_sha1(entry[0] for entry in entries))
            f = GitFile(basename+".idx", "wb")
            try
                write_pack_index_v2(f, entries, p.get_stored_checksum())
            finally
                f.close()
        finally
            p.close()
        os.rename(path, basename + ".pack")
        final_pack = Pack(basename)
        @_add_known_pack(basename, final_pack)
        return final_pack

    add_pack: () ->
        ###Add a new pack to this object store.

        :return: Fileobject to write to, a commit function to
            call when the pack is finished and an abort
            function.
        ###
#        fd, path = tempfile.mkstemp(dir=self.pack_dir, suffix=".pack")
        f = os.fdopen(fd, 'wb')
#        commit()
#            os.fsync(fd)
#            f.close()
#            if os.path.getsize(path) > 0:
#                return self.move_in_pack(path)
#            else:
#                os.remove(path)
#                returnnull
#        abort()
#            f.close()
#            os.remove(path)
#        return f, commit, abort

    add_object: (obj) ->
        ###Add a single object to this object store.

        :param obj: Object to add
        ###
#        dir = os.path.join(self.path, obj.id[:2])
        try
            os.mkdir(dir)
        catch e
            if e.errno != errno.EEXIST
                throw Error('')
#        path = os.path.join(dir, obj.id[2:])
        if os.path.exists(path)
            return # Already there, no need to write again
        f = GitFile(path, 'wb')
        try
            f.write(obj.as_legacy_object())
        finally
            f.close()

    @init: (path) ->
        try
            os.mkdir(path)
        catch e
            if e.errno != errno.EEXIST
                throw Error('')
        os.mkdir(os.path.join(path, "info"))
        os.mkdir(os.path.join(path, PACKDIR))
        return new DiskObjectStore(path)


class MemoryObjectStore extends BaseObjectStore
    ###Object store that keeps all objects in memory.###

    constructor: () ->
        super
        @_data = {}

    _to_hexsha: (sha) ->
        if len(sha) is 40
            return sha
        else if len(sha) is 20
            return sha_to_hex(sha)
        else
            throw Error('ValueError("Invalid sha %r" % (sha,))')

    contains_loose: (sha) ->
        ###Check if a particular object is present by SHA1 and is loose.###
#        return @_to_hexsha(sha) in self._data
        return false

    contains_packed: (sha) ->
        ###Check if a particular object is present by SHA1 and is packed.###
        return False

    __iter__: () ->
        ###Iterate over the SHAs that are present in this store.###
        return @_data.iterkeys()

    packs: () ->
        ###List with pack objects.###
        return []

    get_raw: (name) ->
        ###Obtain the raw text for an object.

        :param name: sha for the object.
        :return: tuple with numeric type and object contents.
        ###
        obj = @[@_to_hexsha(name)]
#        return obj.type_num, obj.as_raw_string()

    __getitem__: (name) ->
        return @_data[@_to_hexsha(name)]

    __delitem__: (name) ->
        ###Delete an object from this store, for testing only.###
        del @_data[@_to_hexsha(name)]

    add_object: (obj) ->
        ###Add a single object to this object store.

        ###
        @_data[obj.id] = obj

    add_objects: (objects) ->
        ###Add a set of objects to this object store.

        :param objects: Iterable over a list of objects.
        ###
        for obj, path in objects
            @_data[obj.id] = obj

    add_pack: () ->
        ###Add a new pack to this object store.

        Because this object store doesn't support packs, we extract and add the
        individual objects.

        :return: Fileobject to write to and a commit function to
            call when the pack is finished.
        ###
        f = new BytesIO()
#        commit():
#            p = PackData.from_file(BytesIO(f.getvalue()), f.tell())
#            f.close()
#            for obj in PackInflater.for_pack_data(p):
#                self._data[obj.id] = obj
#        abort():
#            pass
#        return f, commit, abort

    _complete_thin_pack: (f, indexer) ->
        ###Complete a thin pack by adding external references.

        :param f: Open file object for the pack.
        :param indexer: A PackIndexer for indexing the pack.
        ###
        entries = list(indexer)

        # Update the header with the new number of objects.
        f.seek(0)
        write_pack_header(f, len(entries) + len(indexer.ext_refs()))

        # Rescan the rest of the pack, computing the SHA with the new header.
        new_sha = compute_file_sha(f, end_ofs=-20)

        # Complete the pack.
        for ext_sha in indexer.ext_refs()
            assert len(ext_sha) is 20
#            type_num, data = self.get_raw(ext_sha)
            write_pack_object(f, type_num, data, sha=new_sha)
        pack_sha = new_sha.digest()
        f.write(pack_sha)

    add_thin_pack: (read_all, read_some) ->
        ###Add a new thin pack to this object store.

        Thin packs are packs that contain deltas with parents that exist outside
        the pack. Because this object store doesn't support packs, we extract
        and add the individual objects.

        :param read_all: Read function that blocks until the number of requested
            bytes are read.
        :param read_some: Read function that returns at least one byte, but may
            not return the number of bytes requested.
        ###
#        f, commit, abort = self.add_pack()
#        try
#            indexer = PackIndexer(f, resolve_ext_ref=self.get_raw)
#            copier = PackStreamCopier(read_all, read_some, f, delta_iter=indexer)
#            copier.verify()
#            self._complete_thin_pack(f, indexer)
#        except:
#            abort()
#            raise
#        else:
#            commit()


class ObjectImporter
    ###Interface for importing objects.###

    constructor: (self, count) ->
        ###Create a new ObjectImporter.

        :param count: Number of objects that's going to be imported.
        ###
        self.count = count

    add_object: (self, object) ->
        ###Add an object.###
#        raise NotImplementedError(self.add_object)

    finish: (self, object) ->
        ###Finish the import and write objects to disk.###
#        raise NotImplementedError(self.finish)


class ObjectIterator
    ###Interface for iterating over objects.###

    iterobjects: (self) ->
#        raise NotImplementedError(self.iterobjects)


class ObjectStoreIterator extends ObjectIterator
    ###ObjectIterator that works on top of an ObjectStore.###

    constructor: (self, store, sha_iter) ->
        ###Create a new ObjectIterator.

        :param store: Object store to retrieve from
        :param sha_iter: Iterator over (sha, path) tuples
        ###
        self.store = store
        self.sha_iter = sha_iter
        self._shas = []

    __iter__: (self) ->
        ###Yield tuple with next object and path.###
#        for sha, path in self.itershas():
#            yield self.store[sha], path

    iterobjects: (self) ->
        ###Iterate over just the objects.###
        for o, path in self
#            yield o
            pass

    itershas: (self) ->
        ###Iterate over the SHAs.###
        for sha in self._shas
            pass
#            yield sha
        for sha in self.sha_iter
            self._shas.append(sha)
#            yield sha

    __contains__: (self, needle) ->
        ###Check if an object is present.

        :note: This checks if the object is present in
            the underlying object store, not if it would
            be yielded by the iterator.

        :param needle: SHA1 of the object to check for
        ###
        return needle in self.store

    __getitem__: (self, key) ->
        ###Find an object by SHA1.

        :note: This retrieves the object from the underlying
            object store. It will also succeed if the object would
            not be returned by the iterator.
        ###
        return self.store[key]

    __len__: (self) ->
        ###Return the number of objects.###
        return len(list(self.itershas()))


tree_lookup_path: (lookup_obj, root_sha, path) ->
    ###Look up an object in a Git tree.

    :param lookup_obj: Callback for retrieving object by SHA1
    :param root_sha: SHA1 of the root tree
    :param path: Path to lookup
    :return: A tuple of (mode, SHA) of the resulting path.
    ###
    tree = lookup_obj(root_sha)
    if not isinstance(tree, Tree)
        pass
#        raise NotTreeError(root_sha)
    return tree.lookup_path(lookup_obj, path)


_collect_filetree_revs: (obj_store, tree_sha, kset) ->
    ###Collect SHA1s of files and directories for specified tree.

    :param obj_store: Object store to get objects by SHA from
    :param tree_sha: tree reference to walk
    :param kset: set to fill with references to files and directories
    ###
    filetree = obj_store[tree_sha]
#    for name, mode, sha in filetree.iteritems()
#        if not S_ISGITLINK(mode) and sha not in kset
#            kset.add(sha)
#            if stat.S_ISDIR(mode)
#                _collect_filetree_revs(obj_store, sha, kset)


_split_commits_and_tags: (obj_store, lst, ignore_unknown=false) ->
    ###Split object id list into two list with commit SHA1s and tag SHA1s.

    Commits referenced by tags are included into commits
    list as well. Only SHA1s known in this repository will get
    through, and unless ignore_unknown argument is True, KeyError
    is thrown for SHA1 missing in the repository

    :param obj_store: Object store to get objects by SHA1 from
    :param lst: Collection of commit and tag SHAs
    :param ignore_unknown: True to skip SHA1 missing in the repository
        silently.
    :return: A tuple of (commits, tags) SHA1s
    ###
    commits = set()
    tags = set()
    for e in lst
        try
            o = obj_store[e]
        catch err
            if not ignore_unknown
                throw Error('')
        finally
            if isinstance(o, Commit)
                commits.add(e)
            else if isinstance(o, Tag)
                tags.add(e)
                commits.add(o.object[1])
            else
                pass
#                raise KeyError('Not a commit or a tag: %s' % e)
    return [commits, tags]


class MissingObjectFinder
    ###Find the objects missing from another object store.

    :param object_store: Object store containing at least all objects to be
        sent
    :param haves: SHA1s of commits not to send (already present in target)
    :param wants: SHA1s of commits to send
    :param progress: Optional function to report progress to.
    :param get_tagged: Function that returns a dict of pointed-to sha -> tag
        sha for including tags.
    :param get_parents: Optional function for getting the parents of a commit.
    :param tagged: dict of pointed-to sha -> tag sha for including tags
    ###

    constructor: (self, object_store, haves, wants, progress=None,
                 get_tagged=None, get_parents=lambda commit: commit.parents) ->
        self.object_store = object_store
        self._get_parents = get_parents
        # process Commits and Tags differently
        # Note, while haves may list commits/tags not available locally,
        # and such SHAs would get filtered out by _split_commits_and_tags,
        # wants shall list only known SHAs, and otherwise
        # _split_commits_and_tags fails with KeyError
#        have_commits, have_tags = (
#            _split_commits_and_tags(object_store, haves, True))
#        want_commits, want_tags = (
#            _split_commits_and_tags(object_store, wants, False))
        # all_ancestors is a set of commits that shall not be sent
        # (complete repository up to 'haves')
        all_ancestors = object_store._collect_ancestors(
            have_commits, get_parents=self._get_parents)[0]
        # all_missing - complete set of commits between haves and wants
        # common - commits from all_ancestors we hit into while
        # traversing parent hierarchy of wants
#        missing_commits, common_commits = object_store._collect_ancestors(
#            want_commits, all_ancestors, get_parents=self._get_parents)
#        self.sha_done = set()
        # Now, fill sha_done with commits and revisions of
        # files and directories known to be both locally
        # and on target. Thus these commits and files
        # won't get selected for fetch
        for h in common_commits
            self.sha_done.add(h)
            cmt = object_store[h]
            _collect_filetree_revs(object_store, cmt.tree, self.sha_done)
        # record tags we have as visited, too
        for t in have_tags
            self.sha_done.add(t)

        missing_tags = want_tags.difference(have_tags)
        # in fact, what we 'want' is commits and tags
        # we've found missing
        wants = missing_commits.union(missing_tags)

#        self.objects_to_send = set([(w,null, False) for w in wants])

        if progress is null
            pass
#            self.progress = lambda x:null
        else
            self.progress = progress
        self._tagged = get_tagged and get_tagged() or {}

    add_todo: (self, entries) ->
#        self.objects_to_send.update([e for e in entries
#                                     if not e[0] in self.sha_done])

    next: (self) ->
        while True
            if not self.objects_to_send
                return null
#            (sha, name, leaf) = self.objects_to_send.pop()
            if sha not in self.sha_done
                break
        if not leaf
            o = self.object_store[sha]
            if isinstance(o, Commit)
                pass
#                self.add_todo([(o.tree, "", False)])
            else if isinstance(o, Tree)
                pass
#                self.add_todo([(s, n, not stat.S_ISDIR(m))
#                               for n, m, s in o.iteritems()
#                               if not S_ISGITLINK(m)])
            else if isinstance(o, Tag)
                self.add_todo([o.object[1],null, False])
        if sha in self._tagged
            pass
#            self.add_todo([(self._tagged[sha],null, True)])
        self.sha_done.add(sha)
        self.progress("counting objects: %d\r" % len(self.sha_done))
        return [sha, name]

#    __next__: next


class ObjectStoreGraphWalker
    ###Graph walker that finds what commits are missing from an object store.

    :ivar heads: Revisions without descendants in the local repo
    :ivar get_parents: Function to retrieve parents in the local repo
    ###

    constructor: (self, local_heads, get_parents) ->
        ###Create a new instance.

        :param local_heads: Heads to start search with
        :param get_parents: Function for finding the parents of a SHA1.
        ###
        self.heads = set(local_heads)
        self.get_parents = get_parents
        self.parents = {}

    ack: (self, sha) ->
        ###Ack that a revision and its ancestors are present in the source.###
        ancestors = set([sha])

        # stop if we run out of heads to remove
        while self.heads
            for a in ancestors
                if a in self.heads
                    self.heads.remove(a)

            # collect all ancestors
            new_ancestors = set()
            for a in ancestors
                ps = self.parents.get(a)
                if ps?
                    new_ancestors.update(ps)
                self.parents[a] = null

            # no more ancestors; stop
            if not new_ancestors
                break

            ancestors = new_ancestors

    next: (self) ->
        ###Iterate over ancestors of heads in the target.###
        if self.heads
            ret = self.heads.pop()
            ps = self.get_parents(ret)
            self.parents[ret] = ps
            self.heads.update([p for p in ps if not p in self.parents])
            return ret
        return null

#    __next__: next
