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
    HOOKS: 'hooks'
    INFO: 'info'

BASE_DIRECTORIES = [
    [PATHS.BRANCHES],
    [PATHS.REFERENCES.BASE],
    [PATHS.REFERENCES.BASE, PATHS.REFERENCES.TAGS],
    [PATHS.REFERENCES.BASE, PATHS.REFERENCES.HEADS],
    [PATHS.HOOKS],
    [PATHS.INFO]
]