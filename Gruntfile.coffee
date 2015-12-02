module.exports = (grunt) ->
  deployment = grunt.option('deployment') || 'default'
  grunt.initConfig
    pkg: grunt.file.readJSON("package.json")
    appConfig: grunt.file.readJSON('appconfig/' + deployment + '.json')
    cordova_project_folder: "cordova-build"
    web_root_folder: "www"
    hybrid_build_folder: "www-mobile"
    my_js_lib_prod_files: [
      "<%= web_root_folder %>/js/vendor/modernizr-2.6.2.custom.min.js"
      "<%= web_root_folder %>/js/vendor/jquery-1.10.2.min.js"
    ]
    my_build_files: [
      "<%= web_root_folder %>/.blocks/build/blocks.js"
      "<%= web_root_folder %>/js/vendor/underscore.js"
      "<%= web_root_folder %>/js/vendor/backbone.js"
      "<%= web_root_folder %>/js/vendor/fastclick.js"
      "<%= web_root_folder %>/js/vendor/backbone.marionette.js"
      "<%= web_root_folder %>/js/vendor/syphon.js"
      "<%= web_root_folder %>/js/vendor/spin.js"
      "<%= web_root_folder %>/js/vendor/jquery.spin.js"
      "<%= web_root_folder %>/js/vendor/hideShowPassword.js"
      "<%= web_root_folder %>/js/vendor/markdown.js"
      "<%= web_root_folder %>/js/vendor/backbone-routefilter.js"
      "<%= web_root_folder %>/js/vendor/placeholder_polyfill.jquery.js"
      "<%= web_root_folder %>/js/vendor/ConditionalParser.js"
      "<%= web_root_folder %>/js/vendor/jstz.js"
      "<%= web_root_folder %>/js/vendor/moment.js"
      "<%= web_root_folder %>/js/vendor/xmlToJSON.js"
      "<%= web_root_folder %>/js/build/templates.js"
      "<%= web_root_folder %>/js/build/mycoffee.js"
    ]
    my_template_files: [
      "<%= web_root_folder %>/js/backbone/apps/**/*.eco"
      "<%= web_root_folder %>/js/backbone/lib/components/**/*.eco"
    ]
    my_coffeescript_files: [
      "<%= web_root_folder %>/js/config/**/*.coffee"
      "<%= web_root_folder %>/js/backbone/app.js.coffee"
      "<%= web_root_folder %>/js/backbone/lib/concerns/**/*.coffee"
      "<%= web_root_folder %>/js/backbone/lib/entities/**/*.coffee"
      "<%= web_root_folder %>/js/backbone/lib/utilities/**/*.coffee"
      "<%= web_root_folder %>/js/backbone/lib/views/**/*.coffee"
      "<%= web_root_folder %>/js/backbone/lib/controllers/**/*.coffee"
      "<%= web_root_folder %>/js/backbone/lib/components/**/*.coffee"
      "<%= web_root_folder %>/js/backbone/entities/**/*.coffee"
      "<%= web_root_folder %>/js/backbone/apps/**/*.coffee"
    ]

    eco:
      app:
        options:
          basePath: "<%= web_root_folder %>/"
        files:
          "<%= web_root_folder %>/js/build/templates.js": ["<%= my_template_files %>"]


    coffee:
      compile:
        options: {}
        files:
          "<%= web_root_folder %>/js/build/mycoffee.js": "<%= my_coffeescript_files %>" # concat then compile into single file

    compass:
      dist:
        options:
          config: 'config.rb'

    cssmin:
      combine:
        expand: true
        cwd: "css/"
        src: ["*.css", "!*.min.css", "!lib/*", "!fonts/*"]
        dest: "css/"
        ext: ".min.css"

    connect:
      server:
        options:
          base: './www'
          port: '8088'
          useAvailablePort: true
          hostname: '*' # using '*' makes the server accessible from anywhere, for development
      mobile_web:
        options:
          base: "./<%= hybrid_build_folder %>"
          port: '8089'
          useAvailablePort: true
          hostname: '*' # using '*' makes the server accessible from anywhere, for development

    watch:
      templates:
        files: ["<%= my_template_files %>"]
        tasks: ["eco", "concat"]
      coffee:
        files: ["<%= my_coffeescript_files %>"]
        tasks: ["coffee", "concat"]
      template:
        files: ["<%= web_root_folder %>/index.html.tpl"]
        tasks: ["template:dev"]
      css:
        files: "<%= web_root_folder %>/**/*.scss"
        tasks: ['compass:dist']

    concat:
      options:
        separator: ";"
      dist:
        src: ["<%= my_build_files %>"]
        dest: "<%= web_root_folder %>/js/<%= pkg.name %>.js"

    uglify:
      options:
        mangle:
          except: ["jQuery", "$", "Backbone", "_", "Marionette"]
      my_target:
        files:
          "<%= web_root_folder %>/js/<%= pkg.name %>.min.js": ["<%= web_root_folder %>/js/<%= pkg.name %>.js"]
          "<%= web_root_folder %>/js/lib/modernizr-2.6.2.custom.min.js": ["<%= web_root_folder %>/js/lib/modernizr-2.6.2.custom.js"]

    template:
      dev:
        options:
          data:
            css_path: "css/main.css"
            css_core_path: "css/lib/core.css"
            js_modernizr_path: "js/vendor/modernizr-2.6.2.custom.js"
            js_jquery_path: "js/vendor/jquery-1.10.2.js"
            js_path: "js/<%= pkg.name %>.js"
            js_env: "development"
            js_url: "http://0.0.0.0:8088/"
            app_version: "<%= pkg.version %>"
            app_config: "<%= JSON.stringify(appConfig) %>"
            package_info: "<%= JSON.stringify(appConfig.build) %>"
            app_name: "<%= appConfig.build.app_name %>"
            root_path: "/"
        files:
          "<%= web_root_folder %>/index.html": ["<%= web_root_folder %>/index.html.tpl"]
      cordova_config:
        options:
          data:
            app_name: "<%= appConfig.build.app_name %>"
            bundle_id: "<%= appConfig.build.bundle_id %>"
            description: "<%= pkg.description %>"
            author: "<%= pkg.author %>"
            image_folder: "<%= appConfig.build.image_folder %>"
            app_version: "<%= pkg.version %>"
            android_version: "#{Math.floor(new Date() / 1000)}"
            orientation: "<%= appConfig.build.orientation %>"
        files:
          "config.xml": ["config.xml.tpl"]
      blockfile:
        options:
          data:
            custom_block: "<%= appConfig.appearance.custom_block %>"
        files:
          "<%= web_root_folder %>/Blockfile.rb": ["<%= web_root_folder %>/Blockfile.rb.tpl"]

    cordovacli:
      options:
        path: "<%= cordova_project_folder %>"
        cwd: "<%= cordova_project_folder %>"

      cordova:
        options:
          command: [ "create", "platform", "plugin", "build" ]
          platforms: [ "ios", "android" ]
          plugins: [ "device", "dialogs" ]
          path: "<%= cordova_project_folder %>"
          id: "<%= appConfig.build.bundle_id %>"
          name: "<%= appConfig.build.app_name %>"

      create:
        options:
          command: "create"
          id: "<%= appConfig.build.bundle_id %>"
          name: "<%= appConfig.build.app_name %>"

      add_platforms:
        options:
          command: "platform"
          action: "add"
          platforms: [ "ios", "android" ]

      add_ios_platforms:
        options:
          command: "platform"
          action: "add"
          platforms: [ "ios" ]

      add_plugins:
        options:
          command: "plugin"
          action: "add"
          plugins: [ 
            "camera", 
            "console", 
            "device",
            "device-orientation",
            "dialogs",
            "file",
            "geolocation",
            "inappbrowser",
            "media",
            "media-capture",
            "network-information",
            "splashscreen",
            "org.apache.cordova.file-transfer",
            "https://github.com/wrenr/cordova-plugin-openfilenative.git",
            "https://github.com/ucla/cordova-plugin-local-notifications.git"
          ]

      build_ios:
        options:
          command: "build"
          platforms: [ "ios" ]

    clean:
      cordova_project: ["<%= cordova_project_folder %>"]
      hybrid_build: ["<%= hybrid_build_folder %>"]
      cordova_www: ["<%= cordova_project_folder %>/www/*"]
      cordova_config: ["<%= cordova_project_folder %>/config.xml"]
      cordova_ios_splash: ["<%= cordova_project_folder %>/platforms/ios/<%= appConfig.build.app_name %>/Resources/splash/*"]

    copy:
      hybrid_build:
        files: [
          { expand: true, cwd: 'www/', src: ['css/**'], dest: "<%= hybrid_build_folder %>/" }
          { expand: true, cwd: 'www/', src: ['img/**'], dest: "<%= hybrid_build_folder %>/" }
          { expand: true, cwd: 'www/', src: ['js/vendor/**'], dest: "<%= hybrid_build_folder %>" }
          { expand: true, cwd: 'www/', src: ["js/<%= pkg.name %>.js"], dest: "<%= hybrid_build_folder %>/" }
          { expand: true, cwd: 'www/', src: ['index.html'], dest: "<%= hybrid_build_folder %>/" }
        ]
      cordova_www:
        files: [
          { expand: true, cwd: "<%= hybrid_build_folder %>/", src: ["**"], dest: "<%= cordova_project_folder %>/www/" }
        ]
      cordova_config:
        files: [
          { expand: true, src: ['config.xml'], dest: "<%= cordova_project_folder %>/" }
        ]
      cordova_ios_splash:
        files: [
          { expand: true, cwd: "res/<%= appConfig.build.image_folder %>/ios/splash/", src: ['**'], dest: "<%= cordova_project_folder %>/platforms/ios/<%= appConfig.build.app_name %>/Resources/splash/" }
        ]

    exec:
      blocks_build:
        cmd: "bundle exec blocks build"
        cwd: "<%= web_root_folder %>"
      blocks_watch:
        cmd: "bundle exec blocks watch"
        cwd: "<%= web_root_folder %>"
      mobile_init:
        cmd: "../node_modules/grunt-cli/bin/grunt cordova_init"
        cwd: "<%= cordova_project_folder %>"
      ios_init:
        cmd: "../node_modules/grunt-cli/bin/grunt cordova_ios_init"
        cwd: "<%= cordova_project_folder %>"
      ios_build:
        cmd: "../node_modules/grunt-cli/bin/grunt cordova_build_ios"
        cwd: "<%= cordova_project_folder %>"
      android_build:
        cmd: "adb uninstall <%= appConfig.build.bundle_id %>;../node_modules/cordova/bin/cordova run android"
        cwd: "<%= cordova_project_folder %>"
      android_theme_fix:
        cmd: "sed -i '' 's|android:theme=\"@android:style/Theme.Black.NoTitleBar\"||g' AndroidManifest.xml"
        cwd: "<%= cordova_project_folder %>/platforms/android"

  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-connect"
  grunt.loadNpmTasks "grunt-contrib-compass"

  # Command line interface for Cordova
  grunt.loadNpmTasks "grunt-cordovacli"

  # grunt-eco generates compatible JS from ECO-style templates.
  grunt.loadNpmTasks "grunt-eco"
  grunt.loadNpmTasks "grunt-contrib-cssmin"
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-exec"
  
  # Here grunt-template is used to allow grunt to generate alternate index.html for different environments.
  grunt.loadNpmTasks "grunt-template"

  grunt.registerTask "default", [
    "template:dev"
    "template:blockfile"
    "eco"
    "coffee"
    "concat"
    "compass"
    "connect:server"
    "watch"
  ]
  grunt.registerTask "mobile_dev", [
    "template:dev"
    "template:blockfile"
    "eco"
    "coffee"
    "concat"
    "compass"
    "clean:hybrid_build"
    "copy:hybrid_build"
    "connect:mobile_web"
    "watch"
  ]
  grunt.registerTask "dev", [
    "template:dev"
    "template:blockfile"
    "eco"
    "coffee"
    "concat"
    "compass"
  ]

  grunt.registerTask "cordova_init", [
    "cordovacli:add_platforms"
    "cordovacli:add_plugins"
  ]

  grunt.registerTask "cordova_ios_init", [
    "cordovacli:add_ios_platforms"
    "cordovacli:add_plugins"
  ]


  grunt.registerTask "webblocks_build", [
    "template:blockfile",
    "exec:blocks_build"
  ]

  grunt.registerTask "cordova_build_ios", [
    "cordovacli:build_ios"
  ]

  grunt.registerTask "mobile_firstrun", [
    "clean:cordova_project"
    "clean:hybrid_build"
    "cordovacli:create"
    "template:cordova_config"
    "clean:cordova_config"
    "copy:cordova_config"
    "dev"
    "copy:hybrid_build"
    "clean:cordova_www"
    "copy:cordova_www"
    "exec:mobile_init" # must pass it through a custom exec to change cwd
    "clean:cordova_ios_splash"
    "copy:cordova_ios_splash"
    "exec:android_theme_fix"
  ]

  grunt.registerTask "ios_firstrun", [
    "clean:cordova_project"
    "clean:hybrid_build"
    "cordovacli:create"
    "template:cordova_config"
    "clean:cordova_config"
    "copy:cordova_config"
    "dev"
    "copy:hybrid_build"
    "clean:cordova_www"
    "copy:cordova_www"
    "exec:ios_init" # must pass it through a custom exec to change cwd
    "clean:cordova_ios_splash"
    "copy:cordova_ios_splash"
  ]

  grunt.registerTask "ios_www_build", [
    "dev"
    "clean:hybrid_build"
    "copy:hybrid_build"
    "clean:cordova_www"
    "copy:cordova_www"
    "template:cordova_config"
    "clean:cordova_config"
    "copy:cordova_config"
    "exec:ios_build" # must pass it through a custom exec to change cwd
  ]

  grunt.registerTask "android_www_build", [
    "dev"
    "clean:hybrid_build"
    "copy:hybrid_build"
    "clean:cordova_www"
    "copy:cordova_www"
    "template:cordova_config"
    "clean:cordova_config"
    "copy:cordova_config"
    "exec:android_build" # must pass it through a custom exec to change cwd
  ]

  grunt.registerTask "jenkins_build", [
    "dev"
    "clean:hybrid_build"
    "copy:hybrid_build"
    "clean:cordova_www"
    "copy:cordova_www"
    "template:cordova_config"
    "clean:cordova_config"
    "copy:cordova_config"
  ]
