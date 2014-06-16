module.exports = (grunt) ->

    grunt.initConfig(
        pkg: grunt.file.readJSON('package.json')

        coffee:
            presentation_compile:
                options:
                    sourceMap: true

                files:
                    '': [
                    ]


        karma:
            unit:
                configFile: 'karma.conf.coffee'
                singleRun: true
    )

    # measures the time each task takes
    require('time-grunt')(grunt)

    grunt.loadNpmTasks('grunt-contrib-coffee')
    grunt.loadNpmTasks('grunt-karma')

    grunt.registerTask('build:all', ['karma'])

    # DEFAULT
    grunt.registerTask('default', ['karma'])