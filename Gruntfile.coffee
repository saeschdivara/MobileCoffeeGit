module.exports = (grunt) ->

    grunt.initConfig(
        pkg: grunt.file.readJSON('package.json')

        coffee:
            git_compile:
                options:
                    sourceMap: true

                files:
                    'dist/git.js': [
                        'src/**/*.coffee'
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

    grunt.registerTask('build:git', ['coffee:git_compile'])
    grunt.registerTask('build:all', ['karma', 'build:git'])

    # DEFAULT
    grunt.registerTask('default', ['karma'])