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
            a tag, but no cached information is available, None is returned.
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

    as_dict: (self, base=None) ->
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
        :return: The contents of the ref file, or None if it does
            not exist.
        ###
        contents = self.read_loose_ref(refname)
        if not contents
            contents = self.get_packed_refs().get(refname, None)
        return contents

    read_loose_ref: (self, name) ->
        ###Read a loose reference and return its contents.

        :param name: the refname to read
        :return: The contents of the ref file, or None if it does
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
        :param old_ref: The old sha the refname must refer to, or None to set
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
        :param old_ref: The old sha the refname must refer to, or None to delete
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
        self.remove_if_equals(name, None)