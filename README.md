# ohmageX v3.10.25

[ohmage](http://ohmage.org/) is an open-source, mobile to web platform that records, analyzes, and visualizes data from both prompted experience samples entered by the user, as well as continuous streams of data passively collected from sensors or applications onboard the mobile device. 

**ohmageX** is a revamped version of ohmage MWF, which aims to deliver a single-source and platform-independent mobile application integrated with the Ohmage API. It includes enhancements such as a modular event-driven architecture with [Backbone](http://backbonejs.org/) + [Marionette](http://marionettejs.com/), automated development workflow enhancements, and extensive use of preprocessors (e.g. [Coffeescript](http://coffeescript.org/) and [SASS](http://sass-lang.com/)).

## Installation and Setup

#### Prerequisites

* Ruby 2.1+
* Node.js 0.10+
* Java JDK 1.6+


#### Build Web Assets

Install dependencies for local build:

```
bundle
npm install
```

WebBlocks requires Bower, ensure it can see it with an export for the `$PATH` that includes the node bin.


```
export NODE_PATH=$(npm config get prefix)/lib/node_modules
```

Compile assets with WebBlocks:

```
node_modules/grunt-cli/bin/grunt webblocks_build
```



Compile assets with Grunt:

```
node_modules/grunt-cli/bin/grunt dev
```

If files in `/blocks` weren't updated, you may skip the WebBlocks build.


#### Build Cordova for mobile

The following task prepares the app for iOS builds only, and is required before the first iOS build:

```
grunt ios_firstrun
```

To build for both iOS and Android, execute the following command instead:

```
grunt mobile_firstrun
```


After this, the mobile app can be built at any time with the following:

```
grunt mobile_www_build
```

Note that `mobile_www_build` creates a build with updated contents of the `www` folder. If other assets need to be updated in the build such as Webblocks, check the **Cordova Build Process Details** section.


##### Troubleshooting

During the first time that `mobile_www_build` is executed, Grunt may stop it with an error. The error resolves if the `mobile_www_build` task is repeated again.


##### Cordova Build Process Details

`grunt mobile_firstrun` and `grunt ios_firstrun` do the following:

- cleans any mobile build folders, if they exist
- creates a cordova project in a build folder
- creates a hybrid_build folder containing only core assets, that are copied to the build folder
- overwrites the base config.xml with a custom config.xml
- replaces default icon and splash screens with custom icons
- adds cordova target platforms (defined in Gruntfile)
- adds plugins (defined in Gruntfile)

This task may be run again at any time if major changes to any of these assets are made.

There are also individual Grunt tasks, defined in the Gruntfile, for each of these actions, if needed to be performed separately.

##### Note on Using `cordovacli` tasks

If you need to execute a Grunt `cordovacli` task, you must navigate to the Cordova project build folder first. `cordovacli` tasks will **only** execute in the current directory that the `grunt` command is executed in, regardless of `options.path` settings in the `Gruntfile`. This is an open issue on the Github page for `cordovacli` [https://github.com/csantanapr/grunt-cordovacli/issues/12](https://github.com/csantanapr/grunt-cordovacli/issues/12). 

The `mobile_firstrun` task executes in the root folder without issues, and avoids this problem by executing a custom `grunt-exec` task with a forced `cwd` context from the shell.


## Development using **ohmageX**

- [Development Workflow (wiki)](https://github.com/ucla/ohmageX/wiki/Development-Workflow)

## Version Notes

### 3.10.25 - ohmageX General Release

- Custom features
  - Multi-question survey flow
    - multiple questions per page
      - multiple validation, navigation, condition checks
      - special cases for skipped prompts
      - supports device back button
  - Response History (Android)
    - history with filters, display single history item
    - supports download and offline open of documents and videos
    - supports offline display of images
    - configurable auto-media fetch
  - Dashboard page with grouping and displaying latest campaign
  - Horizontal single-choice layout
  - Some CSS can be customized per deployment
  - XML meta properties per campaign, survey, and prompt
    - randomized integer prompts (using custom XML meta property)

- Media
  - cache images, documents and videos
  - cache video before upload
  - add "clear cache" button to profile
  - validate attached doc and video prompt files by file extension

- Survey flow
  - track state of uploads
  - allow prepopulation of prompt responses

- Prompt Conditional Parser
  - Fix choice prompt parsing
  - Fix message condition parsing

- Prompts support Markdown
  - Parses standard markdown in prompt XML to HTML
  - Applied to prompt messages, prompt questions, choice prompts

- Android compatibility fixes
  - Refactor XML parsing with Android 4.4 compatibility hack

### 3.0.3 - Mobilize Android Release

- Prompt Conditional Parser
  - Fix space parsing and values for skipped choice prompts

- Photo Prompt Fixes
  - Fix max dimension property handlers
  - allow 0 value max dimension to be evaluated as boundless
  - constrain to 800 pixels on native (prevent memory issues)

- UI Rendering Fixes
  - Firefox UI fixes
  - Android 4.1 stock browser UI fixes

- hotfix v3.0.31 - add timeout and options for GPS location

### 3.0.2 - Mobilize iOS Release

- Config
  - Multiple config
    - Supports multiple configuration via sending a new `--deployment` param with the name of a JSON file located in `/appconfig`
  - Add post survey reminders disabled config
  - add configurable prompt defaults

- Dictionary
  - Add dictionary to missing view elements, alerts and dialogs

- Development
  - clean up development build tasks
  - Add debug username and password params to auto-populate login form on debug mobile builds

- Reminder Fixes
  - Refactor to use new version of local notifications plugin, more streamlined
  - Fix reminder turn off and turn on
  - Fix reminder suppression
  - Fix reminder scheduling with repeating
  - Fix reminder survey trigger events

- Photo prompt
  - add native photo picker, take photo and choose from library
  - add width and height constraints

- Add global app state tracking entity - tracks loading state, etc.

### 3.0.1 - Mobilize Android Fixes (partial release)

- Document Prompt
  - Add support for document prompt

- Video Prompt
  - Add support for video prompt
  - Assumes 1 video per survey

- File Upload
  - Add upload progress indicator for video and file uploads
  - Assumes standard upload, video upload, or file upload are separate survey upload types - no mixing types currently allowed

- Native back button
  - Add general support for handling the device back button

### 3.0.0 - iOS Release

> Change project name to "ohmageX"
> The first major release begins with 3.0.0, because this new codebase is the successor to version 2.0.0 of ohmage MWF.

- Date Management
  - Use `Moment.js` for date manipulations [https://github.com/moment/moment/](https://github.com/moment/moment/)

- Build Process Streamlining
  - root is no longer the Cordova build location
  - now creates only necessary files in a separate Cordova build folder
  - Remove unnecessary modules and includes from the build process
  - Cordova build now executes in seconds rather than minutes
  - uses `cordova-cli` [https://github.com/csantanapr/grunt-cordovacli](https://github.com/csantanapr/grunt-cordovacli)

- Touch Events
  - Switch from a custom implementation of `backbone.touch` to FastClick [https://github.com/ftlabs/fastclick](https://github.com/ftlabs/fastclick)
    - Required updating Marionette core from `v2.2.0` to `v2.3.0`
    - in Marionette view, `onAttach` event fires `FastClick.attach` on the attaching element

- Network error and auth error handling

- Loading graphic during processing
  - delay timer so loading messages don't flash abruptly for rapid requests

- General alert and confirmation box system
  - Uses system alerts and confirmation boxes when native, browser alerts and confirmation when not

- iOS Reminders Section
  - Schedule reminders to take a saved survey. Can be one-time reminders, daily repeating reminders, or repeating weekly on selected days of the week
  - Reminders use Local Notification plugin
    - Handle Local Notification permissions
    - Shows Blocker Component when configuring a reminder

- Updated Geolocation plugin

- GUI
  - interaction responsiveness improvements
  - "unstyled" GUI elements styled
  - Multiple pages redesigned
  - Add min and max display to number prompt
  - Add show/hide for password fields using [https://github.com/cloudfour/hideShowPassword](https://github.com/cloudfour/hideShowPassword)

- New Graphic Elements
  - New ohmageX icon and splash screen
  - New App logo header
  - Custom icons per section

- Build Customization
  - Customizable app name, icons, client string
  - Customizable dictionary for common terms, with single and plural, menu labels, etc.
    - Not quite localization, but swapping out important terms
  - Customizable menu items
  - customizable server list
    - customizable toggle of displaying "Custom..." input for server entry

- Auth
  - Implement browser token-based auth
  - Separate device auth (using hashed password) and token-based auth

- Blocker UI component
  - Blocks the entire UI when active
    - password auth blocker - if a request fails because of invalid password, user must logout or fix it

- Change Password Functionality
  - uses the Blocker component to show a change password form

- Upload Queue
  - Response summary page
    - Show all responses with survey questions that the user has submitted

- Version Checking
  - If the version changes, clear settings (old settings may be incompatible)

#### 0.2.0 - GUI Release

- Build updates
  - Standardized build process

- GUI now integrated
  - Webblocks CSS and UI Components
  - Hamburger Menu
  - Progress Bar
  - Notice Regions on select pages
  - Custom Choice
  - Basic Profile Page placeholder

- Storage
  - Custom Choices now saved
  - Custom choices can be individually deleted
  - User data deleted on logout

- Cordova optimizations
  - status bar overlay
  - Device Detection
  - Touch event optimization

- Error handling
  - Unsupported prompt types
  - Survey Upload errors

- Login Flow
  - Multi-modal menu, shows Logged-In and Not Logged-In items
  - Redirect when not logged in


#### 0.1.0 - First Release

Includes the following functionality:

- Header
  - Header navigation list
  - Slot for dynamic header navigation button

- Footer
  - Simple footer template

- Login Page
  - Login / password form
  - Save auth via hashed password
  - Switch servers
  - Show login failure error messages

- Campaign List
  - Multiple Campaign status
  - Sync campaigns from server
  - Filter Campaigns by saved / unsaved
  - Campaign search box with fuzzy filtering

- Save and Unsave Campaigns
  - Save campaigns to localstorage
  - Remove campaigns and associated surveys on remove
  - store campaign XML on save

- Saved Surveys List
  - List all surveys
  - Filter surveys dropdown
  - running and "ghosted" survey states based on parent campaign

- Survey Taking
  - Parse survey XML into survey flow
  - Render All Prompts in sequence
  - Prompt validation rules from XML, with basic error alert
  - Previous, Skip and Next buttons
  - Survey intro, before Submit and After Submit steps
  - Conditional parser (based on old parser)
  - Confirmation warning on survey exit

- Survey Upload
  - Upload responses with timestamp and geolocation
  - Upload images object hash with UUIDs

- Logout
  - Clear hashed password
  - Confirmation warning on logout

#### 0.0.1 - Initial Setup

> Ohmage MWF Dragon Well 龍井
> The name "Dragon Well" comes from a variety of Chinese green tea (龍井茶).

- Set up Cordova, Backbone + Marionette, and vendor libraries

## License

The ohmageX project is **open-source** and licensed under the AFFERO GENERAL PUBLIC LICENSE. The full text of the license may be found in the `LICENSE` file.

### "Dual-licensing" note

Due to known policies of Apple Inc. (described [here](https://www.fsf.org/blogs/licensing/more-about-the-app-store-gpl-enforcement)) limiting/revoking access to the store for projects with GPL-based licenses the project owner (UCLA's Educational and Collaborative Technology Group) are opting currently to release app store builds under a proprietary, non-AGPL license.  New contributors will be require to agree to these terms prior to the acceptance of pull requests.
