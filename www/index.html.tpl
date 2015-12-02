<!doctype html>
<html class="notie no-js">
<head>
  <meta charset="utf-8" />
  <title><%= app_name %></title>
  <meta name="viewport" content="initial-scale=1, maximum-scale=1, user-scalable=no, minimal-ui">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="format-detection" content="telephone=no">
  <link rel="shortcut icon" href="/favicon.ico?v=1.1">
  <link rel="stylesheet" href="<%= css_path %>" />
  <script src="cordova.js"></script>
  <script src="<%= js_modernizr_path %>"></script>
</head>
<body>
  <div id="loading-spinner"></div>
  <div id="ui-blocker"></div>
  <div id="full-modal"></div>
  <header role="banner"></header>
  <main role="main"></main>
  <footer role="contentinfo"></footer>
  <script src="<%= js_jquery_path %>"></script>
  <script src="<%= js_path %>"></script>
  <%
    configObj = JSON.parse(app_config);
    if (configObj.build.debug) {
      print('<script src="' + configObj.build.debug_settings.debug_script + '"></script>\n');
    }
  %>
  <script type="text/javascript">
  $(function() {
    var myConfig = {
        environment: "<%= js_env %>",
        root_path: "<%= root_path %>",
        url: "<%= js_url %>",
        app_version: "<%= app_version %>",
        package_info: <%= package_info %>,
        app_config: <%= app_config %>
      };
    if (typeof window.cordova !== "undefined") {
      document.addEventListener('deviceready', function() {
        // The app uses key device event listeners on mobile.
        // Only start it up on 'deviceready'.
        Ohmage.start(_.extend(myConfig, {cordova: true} ));
      });
    } else {
      Ohmage.start(_.extend(myConfig, {cordova: false} ));
    }
  });
  </script>
</body>
</html>