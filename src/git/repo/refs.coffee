class RefsContainer
    ### A container for refs. ###

    set_symbolic_ref: (self, name, other) ->
        ###Make a ref point at another ref.

        :param name: Name of the ref to set
        :param other: Name of the ref to point at
        ###
#        raise NotImplementedError(self.set_symbolic_ref)

    get_packed_refs: (self) ->
        ###Get contents of the packed-refs file.

        :return: Dictionary mapping ref names to SHA1s

        :note: Will return an empty dictionary when no packed-refs file is
            present.
        ###
#        raise NotImplementedError(self.get_packed_refs)

    get_peeled: (self, name) ->
        ###Return the cached peeled value of a ref, if available.

        :param name: Name of the ref to peel
        :return: The peeled value of the ref. If the ref is known not point to a
            tag, this will be the SHA the ref refers to. If the ref may point to
            a tag, but no cached information is available, null is returned.
        ###
        return null

    import_refs: (self, base, other) ->
        for name, value in other.iteritems()
            pass
#            self["%s/%s" % (base, name)] = value

    allkeys: (self) ->
        ###All refs present in this container.###
#        raise NotImplementedError(self.allkeys)

    keys: (self, base=null) ->
        ###Refs present in this container.

        :param base: An optional base to return refs under.
        :return: An unsorted set of valid refs in this container, including
            packed refs.
        ###
        if base?
            return self.subkeys(base)
        else
            return self.allkeys()

    subkeys: (self, base) ->
        ###Refs present in this container under a base.

        :param base: The base to return refs under.
        :return: A set of valid refs in this container under the base; the base
            prefix is stripped from the ref names returned.
        ###
        keys = set()
        base_len = len(base) + 1
        for refname in self.allkeys()
            if refname.startswith(base)
                pass
#                keys.add(refname[base_len:])
        return keys

    as_dict: (self, base=null) ->
        ###Return the contents of this container as a dictionary.

        ###
        ret = {}
        keys = self.keys(base)
        if base is null
            base = ""
        for key in keys
            try
#                ret[key] = self[("%s/%s" % (base, key)).strip("/")]
            catch err
                continue  # Unable to resolve

        return ret

    _check_refname: (self, name) ->
        ###Ensure a refname is valid and lives in refs or is HEAD.

        HEAD is not a valid refname according to git-check-ref-format, but this
        class needs to be able to touch HEAD. Also, check_ref_format expects
        refnames without the leading 'refs/', but this class requires that
        so it cannot touch anything outside the refs dir (or HEAD).

        :param name: The name of the reference.
        :raises KeyError: if a refname is not HEAD or is otherwise not valid.
        ###
        if name in ['HEAD', 'refs/stash']
            return
#        if not name.startswith('refs/') or not check_ref_format(name[5:])
#            raise RefFormatError(name)

    read_ref: (self, refname) ->
        ###Read a reference without following any references.

        :param refname: The name of the reference
        :return: The contents of the ref file, or null if it does
            not exist.
        ###
        contents = self.read_loose_ref(refname)
        if not contents
            contents = self.get_packed_refs().get(refname, null)
        return contents

    read_loose_ref: (self, name) ->
        ###Read a loose reference and return its contents.

        :param name: the refname to read
        :return: The contents of the ref file, or null if it does
            not exist.
        ###
#        raise NotImplementedError(self.read_loose_ref)

    _follow: (self, name) ->
        ###Follow a reference name.

        :return: a tuple of (refname, sha), where refname is the name of the
            last reference in the symbolic reference chain
        ###
        contents = SYMREF + name
        depth = 0
        while contents.startswith(SYMREF)
#            refname = contents[len(SYMREF):]
            contents = self.read_ref(refname)
            if not contents
                break
            depth += 1
            if depth > 5
                pass
#                raise KeyError(name)
#        return refname, contents

    __contains__: (self, refname) ->
        if self.read_ref(refname)
            return true
        return false

    __getitem__: (self, name) ->
        ###Get the SHA1 for a reference name.

        This method follows all symbolic references.
        ###
#        _, sha = self._follow(name)
        if sha is null
            pass
#            raise KeyError(name)
        return sha

    set_if_equals: (self, name, old_ref, new_ref) ->
        ###Set a refname to new_ref only if it currently equals old_ref.

        This method follows all symbolic references if applicable for the
        subclass, and can be used to perform an atomic compare-and-swap
        operation.

        :param name: The refname to set.
        :param old_ref: The old sha the refname must refer to, or null to set
            unconditionally.
        :param new_ref: The new sha the refname will refer to.
        :return: True if the set was successful, False otherwise.
        ###
#        raise NotImplementedError(self.set_if_equals)

    add_if_new: (self, name, ref) ->
        ###Add a new reference only if it does not already exist.###
#        raise NotImplementedError(self.add_if_new)

    __setitem__: (self, name, ref) ->
        ###Set a reference name to point to the given SHA1.

        This method follows all symbolic references if applicable for the
        subclass.

        :note: This method unconditionally overwrites the contents of a
            reference. To update atomically only if the reference has not
            changed, use set_if_equals().
        :param name: The refname to set.
        :param ref: The new sha the refname will refer to.
        ###
        self.set_if_equals(name, null, ref)

    remove_if_equals: (self, name, old_ref) ->
        ###Remove a refname only if it currently equals old_ref.

        This method does not follow symbolic references, even if applicable for
        the subclass. It can be used to perform an atomic compare-and-delete
        operation.

        :param name: The refname to delete.
        :param old_ref: The old sha the refname must refer to, or null to delete
            unconditionally.
        :return: True if the delete was successful, False otherwise.
        ###
#        raise NotImplementedError(self.remove_if_equals)

    __delitem__: (self, name) ->
        ###Remove a refname.

        This method does not follow symbolic references, even if applicable for
        the subclass.

        :note: This method unconditionally deletes the contents of a reference.
            To delete atomically only if the reference has not changed, use
            remove_if_equals().

        :param name: The refname to delete.
        ###
        self.remove_if_equals(name, null)
        
        

class DiskRefsContainer extends RefsContainer
    ###Refs container that reads refs from disk.###

    constructor: (self, path) ->
        self.path = path
        self._packed_refs = null
        self._peeled_refs = null

    __repr__: (self) ->
#        return "%s(%r)" % (self.__class__.__name__, self.path)

    subkeys: (self, base) ->
        keys = set()
        path = self.refpath(base)
#        for root, dirs, files in os.walk(path)
#            dir = root[len(path):].strip(os.path.sep).replace(os.path.sep, "/")
#            for filename in files:
#                refname = ("%s/%s" % (dir, filename)).strip("/")
#                check_ref_format requires at least one /, so we prepend the
                # base before calling it.
#                if check_ref_format("%s/%s" % (base, refname)):
#                    keys.add(refname)
#        for key in self.get_packed_refs():
#            if key.startswith(base):
#                keys.add(key[len(base):].strip("/"))
#        return keys

    allkeys: (self) ->
        keys = set()
        if os.path.exists(self.refpath("HEAD"))
            keys.add("HEAD")
        path = self.refpath("")
#        for root, dirs, files in os.walk(self.refpath("refs")):
#            dir = root[len(path):].strip(os.path.sep).replace(os.path.sep, "/")
#            for filename in files:
#                refname = ("%s/%s" % (dir, filename)).strip("/")
#                if check_ref_format(refname):
#                    keys.add(refname)
        keys.update(self.get_packed_refs())
        return keys

    refpath: (self, name) ->
        ###Return the disk path of a ref.

        ###
        if os.path.sep != "/"
            name = name.replace("/", os.path.sep)
        return os.path.join(self.path, name)

    get_packed_refs: (self) ->
        ###Get contents of the packed-refs file.

        :return: Dictionary mapping ref names to SHA1s

        :note: Will return an empty dictionary when no packed-refs file is
            present.
        ###
        # TODO: invalidate the cache on repacking
        if self._packed_refs is null
            # set both to empty because we want _peeled_refs to be
            # null if and only if _packed_refs is also null.
            self._packed_refs = {}
            self._peeled_refs = {}
            path = os.path.join(self.path, 'packed-refs')
            try
                f = GitFile(path, 'rb')
            catch e
                if e.errno == errno.ENOENT
                    return {}
                throw Error('')
            try
                first_line = next(iter(f)).rstrip()
                if (first_line.startswith("# pack-refs") and " peeled" in first_line)
#                    for sha, name, peeled in read_packed_refs_with_peeled(f)
#                        self._packed_refs[name] = sha
#                        if peeled:
#                            self._peeled_refs[name] = peeled
                else
                    f.seek(0)
                    for sha, name in read_packed_refs(f)
                        self._packed_refs[name] = sha
            finally
                f.close()
        return self._packed_refs

    get_peeled: (self, name) ->
        ###Return the cached peeled value of a ref, if available.

        :param name: Name of the ref to peel
        :return: The peeled value of the ref. If the ref is known not point to a
            tag, this will be the SHA the ref refers to. If the ref may point to
            a tag, but no cached information is available, null is returned.
        ###
        self.get_packed_refs()
        if self._peeled_refs is null or name not in self._packed_refs
            # No cache: no peeled refs were read, or this ref is loose
            return null
        if name in self._peeled_refs
            return self._peeled_refs[name]
        else
            # Known not peelable
            return self[name]

    read_loose_ref: (self, name) ->
        ###Read a reference file and return its contents.

        If the reference file a symbolic reference, only read the first line of
        the file. Otherwise, only read the first 40 bytes.

        :param name: the refname to read, relative to refpath
        :return: The contents of the ref file, or null if the file does not
            exist.
        :raises IOError: if any other error occurs
        ###
        filename = self.refpath(name)
        try
            f = GitFile(filename, 'rb')
            try
                header = f.read(len(SYMREF))
                if header == SYMREF
                    # Read only the first line
                    return header + next(iter(f)).rstrip("\r\n")
                else
                    # Read only the first 40 bytes
                    return header + f.read(40 - len(SYMREF))
            finally
                f.close()
        catch e
            if e.errno == errno.ENOENT
                return null
            throw Error('')

    _remove_packed_ref: (self, name) ->
        if self._packed_refs is null
            return
        filename = os.path.join(self.path, 'packed-refs')
        # reread cached refs from disk, while holding the lock
        f = GitFile(filename, 'wb')
        try
            self._packed_refs = null
            self.get_packed_refs()

            if name not in self._packed_refs
                return

            del self._packed_refs[name]
            if name in self._peeled_refs
                del self._peeled_refs[name]
            write_packed_refs(f, self._packed_refs, self._peeled_refs)
            f.close()
        finally
            f.abort()

    set_symbolic_ref: (self, name, other) ->
        ###Make a ref point at another ref.

        :param name: Name of the ref to set
        :param other: Name of the ref to point at
        ###
        self._check_refname(name)
        self._check_refname(other)
        filename = self.refpath(name)
        try
            f = GitFile(filename, 'wb')
            try
                f.write(SYMREF + other + '\n')
            catch err
                f.abort()
                throw Error('')
        finally
            f.close()

    set_if_equals: (self, name, old_ref, new_ref) ->
        ###Set a refname to new_ref only if it currently equals old_ref.

        This method follows all symbolic references, and can be used to perform
        an atomic compare-and-swap operation.

        :param name: The refname to set.
        :param old_ref: The old sha the refname must refer to, or null to set
            unconditionally.
        :param new_ref: The new sha the refname will refer to.
        :return: True if the set was successful, False otherwise.
        ###
        self._check_refname(name)
        try
#            realname, _ = self._follow(name)
        catch err
            realname = name
        filename = self.refpath(realname)
        ensure_dir_exists(os.path.dirname(filename))
        f = GitFile(filename, 'wb')
        try
            if old_ref?
                try
                    # read again while holding the lock
                    orig_ref = self.read_loose_ref(realname)
                    if orig_ref is null
                        orig_ref = self.get_packed_refs().get(realname, null)
                    if orig_ref != old_ref
                        f.abort()
                        return false
                catch err
                    f.abort()
                    throw Error('')
            try
                f.write(new_ref + "\n")
            catch err
                f.abort()
                throw Error('')
        finally
            f.close()
        return true

    add_if_new: (self, name, ref) ->
        ###Add a new reference only if it does not already exist.

        This method follows symrefs, and only ensures that the last ref in the
        chain does not exist.

        :param name: The refname to set.
        :param ref: The new sha the refname will refer to.
        :return: True if the add was successful, False otherwise.
        ###
        try
#            realname, contents = self._follow(name)
            if contents?
                return false
        catch err
            realname = name
        self._check_refname(realname)
        filename = self.refpath(realname)
        ensure_dir_exists(os.path.dirname(filename))
        f = GitFile(filename, 'wb')
        try
            if os.path.exists(filename) or name in self.get_packed_refs()
                f.abort()
                return false
            try
                f.write(ref + "\n")
            catch err
                f.abort()
                throw Error('')
        finally
            f.close()
        return true

    remove_if_equals: (self, name, old_ref) ->
        ###Remove a refname only if it currently equals old_ref.

        This method does not follow symbolic references. It can be used to
        perform an atomic compare-and-delete operation.

        :param name: The refname to delete.
        :param old_ref: The old sha the refname must refer to, or null to delete
            unconditionally.
        :return: True if the delete was successful, False otherwise.
        ###
        self._check_refname(name)
        filename = self.refpath(name)
        ensure_dir_exists(os.path.dirname(filename))
        f = GitFile(filename, 'wb')
        try
            if old_ref?
                orig_ref = self.read_loose_ref(name)
                if orig_ref is null
                    orig_ref = self.get_packed_refs().get(name, null)
                if orig_ref != old_ref
                    return false
            # may only be packed
            try
                os.remove(filename)
            catch e
                if e.errno != errno.ENOENT
                    throw Error('')
            self._remove_packed_ref(name)
        finally
            # never write, we just wanted the lock
            f.abort()
        return true


#_split_ref_line(line):
#    ###Split a single ref line into a tuple of SHA1 and name.###
#    fields = line.rstrip("\n").split(" ")
#    if len(fields) != 2:
#        raise PackedRefsException("invalid ref line '%s'" % line)
#    sha, name = fields
#    try:
#        hex_to_sha(sha)
#    except (AssertionError, TypeError) as e:
#        raise PackedRefsException(e)
#    if not check_ref_format(name):
#        raise PackedRefsException("invalid ref name '%s'" % name)
#    return (sha, name)
#
#
#read_packed_refs(f):
#    ###Read a packed refs file.
#
#    :param f: file-like object to read from
#    :return: Iterator over tuples with SHA1s and ref names.
#    ###
#    for l in f:
#        if l[0] == "#":
#            # Comment
#            continue
#        if l[0] == "^":
#            raise PackedRefsException(
#              "found peeled ref in packed-refs without peeled")
#        yield _split_ref_line(l)
#
#
#read_packed_refs_with_peeled(f):
#    ###Read a packed refs file including peeled refs.
#
#    Assumes the "# pack-refs with: peeled" line was already read. Yields tuples
#    with ref names, SHA1s, and peeled SHA1s (or null).
#
#    :param f: file-like object to read from, seek'ed to the second line
#    ###
#    last = null
#    for l in f:
#        if l[0] == "#":
#            continue
#        l = l.rstrip("\r\n")
#        if l[0] == "^":
#            if not last:
#                raise PackedRefsException("unexpected peeled ref line")
#            try:
#                hex_to_sha(l[1:])
#            except (AssertionError, TypeError) as e:
#                raise PackedRefsException(e)
#            sha, name = _split_ref_line(last)
#            last = null
#            yield (sha, name, l[1:])
#        else:
#            if last:
#                sha, name = _split_ref_line(last)
#                yield (sha, name, null)
#            last = l
#    if last:
#        sha, name = _split_ref_line(last)
#        yield (sha, name, null)
#
#
#write_packed_refs(f, packed_refs, peeled_refs=null):
#    ###Write a packed refs file.
#
#    :param f: empty file-like object to write to
#    :param packed_refs: dict of refname to sha of packed refs to write
#    :param peeled_refs: dict of refname to peeled value of sha
#    ###
#    if peeled_refs is null:
#        peeled_refs = {}
#    else:
#        f.write('# pack-refs with: peeled\n')
#    for refname in sorted(packed_refs.iterkeys()):
#        f.write('%s %s\n' % (packed_refs[refname], refname))
#        if refname in peeled_refs:
#            f.write('^%s\n' % peeled_refs[refname])
#
#
#read_info_refs(f):
#    ret = {}
#    for l in f.readlines():
#        (sha, name) = l.rstrip("\r\n").split("\t", 1)
#        ret[name] = sha
#    return ret
#
#
#write_info_refs(refs, store):
#    ###Generate info refs.###
#    for name, sha in sorted(refs.items()):
#        # get_refs() includes HEAD as a special case, but we don't want to
#        # advertise it
#        if name == 'HEAD':
#            continue
#        try:
#            o = store[sha]
#        except KeyError:
#            continue
#        peeled = store.peel_sha(sha)
#        yield '%s\t%s\n' % (o.id, name)
#        if o.id != peeled.id:
#            yield '%s\t%s^{}\n' % (peeled.id, name)
   