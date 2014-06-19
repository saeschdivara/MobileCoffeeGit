###
    Const variables
###
PATHS =
    OBJECTS: 'objects'
    REFERENCES:
        BASE: 'refs'
        TAGS: 'tags'
        HEADS: 'heads'
    INDEX: 'index'
    BRANCHES: 'branches'
    PACK: 'pack'
    HOOKS: 'hooks'
    INFO: 'info'

OBJECTDIR = PATHS.OBJECTS
PACKDIR = PATHS.PACK

BASE_DIRECTORIES = [
    [PATHS.BRANCHES],
    [PATHS.REFERENCES.BASE],
    [PATHS.REFERENCES.BASE, PATHS.REFERENCES.TAGS],
    [PATHS.REFERENCES.BASE, PATHS.REFERENCES.HEADS],
    [PATHS.HOOKS],
    [PATHS.INFO]
]