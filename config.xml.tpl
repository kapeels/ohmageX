<?xml version='1.0' encoding='utf-8'?>
<widget id="<%= bundle_id %>" version="<%= app_version %>" android-versionCode="<%= android_version %>" xmlns="http://www.w3.org/ns/widgets" xmlns:cdv="http://cordova.apache.org/ns/1.0">
    <name><%= app_name %></name>
    <description>
        <%= description %>
    </description>
    <author email="<%= author.email %>" href="<%= author.url %>">
        <%= author.name %>
    </author>
    <content src="index.html" />
    <platform name="ios">
        <!-- iOS 8.0+ -->
        <!-- iPhone 6 Plus  -->
        <icon src="../res/<%= image_folder %>/ios/icons/Icon-60@3x.png" width="180" height="180" />
        <!-- iOS 7.0+ -->
        <!-- iPhone / iPod Touch  -->
        <icon src="../res/<%= image_folder %>/ios/icons/Icon-60.png" width="60" height="60" />
        <icon src="../res/<%= image_folder %>/ios/icons/Icon-60@2x.png" width="120" height="120" />
        <!-- iPad -->
        <icon src="../res/<%= image_folder %>/ios/icons/Icon-76.png" width="76" height="76" />
        <icon src="../res/<%= image_folder %>/ios/icons/Icon-76@2x.png" width="152" height="152" />
        <!-- iOS 6.1 -->
        <!-- Spotlight Icon -->
        <icon src="../res/<%= image_folder %>/ios/icons/Icon-Small-40.png" width="40" height="40" />
        <icon src="../res/<%= image_folder %>/ios/icons/Icon-Small-40@2x.png" width="80" height="80" />
        <!-- iPhone / iPod Touch -->
        <icon src="../res/<%= image_folder %>/ios/icons/Icon.png" width="57" height="57" />
        <icon src="../res/<%= image_folder %>/ios/icons/Icon@2x.png" width="114" height="114" />
        <!-- iPad -->
        <icon src="../res/<%= image_folder %>/ios/icons/Icon-72.png" width="72" height="72" />
        <icon src="../res/<%= image_folder %>/ios/icons/Icon-72@2x.png" width="144" height="144" />

        <!-- Other Icons -->
        <icon src="../res/<%= image_folder %>/ios/icons/Icon-Small-50.png" width="50" height="50" />
        <icon src="../res/<%= image_folder %>/ios/icons/Icon-Small-50@2x.png" width="100" height="100" />
        <icon src="../res/<%= image_folder %>/ios/icons/Icon-Small.png" width="29" height="29" />
        <icon src="../res/<%= image_folder %>/ios/icons/Icon-Small@2x.png" width="58" height="58" />

    </platform>

    <preference name="Orientation" value="<%= orientation %>" />
    <!--
    In order for Android splash images to be configurable via this
    config.xml within Cordova, all splash images must be named `screen.png`,
    and the preference tags for `SplashScreen` and `SplashScreenDelay`
    must be provided.
    -->
    <preference name="SplashScreen" value="screen" />
    <preference name="SplashScreenDelay" value="2000" />
    <platform name="android">
        <icon src="../res/<%= image_folder %>/android/icons/ldpi.png" density="ldpi" />
        <icon src="../res/<%= image_folder %>/android/icons/mdpi.png" density="mdpi" />
        <icon src="../res/<%= image_folder %>/android/icons/hdpi.png" density="hdpi" />
        <icon src="../res/<%= image_folder %>/android/icons/xhdpi.png" density="xhdpi" />

        <splash src="../res/<%= image_folder %>/android/splash/splash-land-hdpi/screen.png" density="land-hdpi"/>
        <splash src="../res/<%= image_folder %>/android/splash/splash-land-ldpi/screen.png" density="land-ldpi"/>
        <splash src="../res/<%= image_folder %>/android/splash/splash-land-mdpi/screen.png" density="land-mdpi"/>
        <splash src="../res/<%= image_folder %>/android/splash/splash-land-xhdpi/screen.png" density="land-xhdpi"/>

        <splash src="../res/<%= image_folder %>/android/splash/splash-port-hdpi/screen.png" density="port-hdpi"/>
        <splash src="../res/<%= image_folder %>/android/splash/splash-port-ldpi/screen.png" density="port-ldpi"/>
        <splash src="../res/<%= image_folder %>/android/splash/splash-port-mdpi/screen.png" density="port-mdpi"/>
        <splash src="../res/<%= image_folder %>/android/splash/splash-port-xhdpi/screen.png" density="port-xhdpi"/>
        <feature name="File">
            <param name="android-package" value="org.apache.cordova.file.FileUtils" />
        </feature>
        <feature name="FileTransfer">
            <param name="android-package" value="org.apache.cordova.filetransfer.FileTransfer" />
        </feature>
    </platform>
    <access origin="*" />
</widget>
