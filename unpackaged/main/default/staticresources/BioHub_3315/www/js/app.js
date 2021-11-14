
angular.module('starter', ['ionic', 'starter.services', 'starter.controllers'])

.run(['$ionicPlatform', 'NetworkService', 'AppRunStatusService', 'UserService', 'SyncService', 'logger', 'LocalNotificationService', 'appDataUtils', 'syncRefresh', function($ionicPlatform, NetworkService, AppRunStatusService, UserService, SyncService, logger, LocalNotificationService, appDataUtils, syncRefresh) {

  $ionicPlatform.ready(function() {

    // Hide the MCSDK splashscreen, if running in an MCSDK container
    if (typeof(plugin) !== "undefined" && plugin.mcsdk) {
      console.log("Hiding splashscreen");
      plugin.mcsdk.hideSplashScreen();
    }

    if (window.cordova && window.cordova.plugins && window.cordova.plugins.Keyboard) {
      // Hide the accessory bar above the keyboard
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true);
      // Disable keyboard auto scroll
      cordova.plugins.Keyboard.disableScroll(true);
    }
    if (window.StatusBar) {
      // org.apache.cordova.statusbar required
      StatusBar.styleLightContent();
      // Set the statusbar to use the default style, tweak this to
      // remove the status bar on iOS or change it to use white instead of dark colors.
      StatusBar.styleDefault();
    }

    document.addEventListener("resume", function() {
      AppRunStatusService.statusEvent('resume');
    }, false);
    // document.addEventListener("pause", function() {
    //   AppRunStatusService.statusEvent('pause');
    // }, false);
    document.addEventListener("online", function() {
      NetworkService.networkEvent('online');
    }, false);
    document.addEventListener("offline", function() {
      NetworkService.networkEvent('offline');
    }, false);

    // Local notifications plugin event handlers
    if (cordova && cordova.plugins && cordova.plugins.notification) {
      // Notification has reached its trigger time
      cordova.plugins.notification.local.on("trigger", function (notification, state) {
        LocalNotificationService.handleLocalNotification(notification.id, state);
      });
      // Event fired when user taps on notification
      cordova.plugins.notification.local.on("click", function (notification, state) {
        LocalNotificationService.handleLocalNotificationClick(notification.id, state);
      });
    }
  });

  // Remove the start page element as it is no longer needed.
  angular.element( document.querySelector( '#start-page' ) ).remove();

  // Disable the local notifications
  localStorage.setItem("localNotificationState", "enabled");

  // Sync tables
  UserService.hasDoneProcess("initialDataLoaded").then(function(result) {
    // console.log("bio app.js result: " + result);
    // logger.log("app.js result: " + result);
    if (result) {
      // Ensure that the syncTables will run
      SyncService.setSyncLock("false");
      SyncService.setSyncState("complete");
      // case6454 - Perform tokenRefresh on Cold Start
      var getUrl = 'https://mc-logs.herokuapp.com/log?log="ColdStart: Refreshing token"';
      var xhr = new XMLHttpRequest();
      xhr.open('GET',getUrl, true);
      xhr.send();
      try {
        syncRefresh.refreshToken(
          function(result) {
            console.log(result);
            var getUrl = 'https://mc-logs.herokuapp.com/log?log="ColdStart: Token refreshed ok"';
            var xhr = new XMLHttpRequest();
            xhr.open('GET',getUrl, true);
            xhr.send();
            // If we've already installed the app, and done an initial load of data, then sync tables using standard synchronous call
            SyncService.syncTables(['Mobile_Refresh__ap', 'Content_Item__ap', 'Surgeon_in_Hospital__ap', 'DOF__ap', 'DOF_Item__ap', 'Mobile_Dynamic__ap', 'Mobile_Log__mc']);
          },
          function(error) {
            var getUrl = 'https://mc-logs.herokuapp.com/log?log="ColdStart: Token refresh error"';
            var xhr = new XMLHttpRequest();
            xhr.open('GET',getUrl, true);
            xhr.send();
            logger.error('ColdStart refreshToken', error);
          }
        );
      } catch (e) {
        logger.error(e);
      }
    } else {
      NetworkService.setNetworkStatus("online");
      // Initial install and load of data => we can do a faster asynchronous load of tables.
      // Calls devUtils.initialSync (from within SyncService) rather than usual devUtils.syncMobileTable call
      SyncService.initialSync(['Mobile_Refresh__ap', 'Content_Item__ap', 'Surgeon_in_Hospital__ap', 'DOF__ap', 'DOF_Item__ap', 'Mobile_Dynamic__ap']);
      // update soup
      appDataUtils.getCurrentValueFromAppSoup('authURLType').then(function(res){
        if (!res || res === '') {
          appDataUtils.updateCurrentValueInAppSoup('authURLType', 'instance');
        }
      }).catch(function(e){
        logger.error("Error with authURLType", e);
      });
    }
  });


}])

.config(['$stateProvider', '$urlRouterProvider', '$ionicConfigProvider', '$compileProvider', function($stateProvider, $urlRouterProvider, $ionicConfigProvider, $compileProvider) {

  // Un comment this line when pushing for prod.
  $compileProvider.debugInfoEnabled(false);

  $ionicConfigProvider.navBar.alignTitle('center');
  $ionicConfigProvider.backButton.text('');
  $ionicConfigProvider.views.swipeBackEnabled(false);

  // Ionic uses AngularUI Router which uses the concept of states
  // Learn more here: https://github.com/angular-ui/ui-router
  // Set up the various states which the app can be in.
  $stateProvider

    // app tutorial
    .state('tutorial', {
      url: '/tutorial',
      templateUrl: RESOURCE_ROOT + 'templates/tutorial.html',
      controller: 'TutorialCtrl',
      controllerAs: 'vm'
    })

    // setup an abstract state for the app
    .state('app', {
      url: "/app",
      abstract: true,
      templateUrl: RESOURCE_ROOT + 'templates/menu.html',
      controller: 'MenuCtrl',
      controllerAs: 'vm'
    })

    // the app home page
    .state('app.home', {
      url: '/home',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/home.html',
          controller: 'HomeCtrl',
          controllerAs: 'vm'
        }
      }
    })

    // order form
    .state('app.orderform', {
      url: '/orderform',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/orderForm.html',
          controller: 'OrderFormCtrl',
          controllerAs: 'vm'
        }
      }
    })

    // order history
    .state('app.orderhistory', {
      url: '/orderhistory',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/orderHistory.html',
          controller: 'OrderHistoryCtrl',
          controllerAs: 'vm'
        }
      }
    })

    // new account
    .state('app.newaccount', {
      url: '/newaccount',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/newAccount.html',
          controller: 'NewAccountCtrl',
          controllerAs: 'vm'
        }
      }
    })

    // new account history
    .state('app.newaccounthistory', {
      url: '/newaccounthistory',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/newAccountHistory.html',
          controller: 'NewAccountHistoryCtrl',
          controllerAs: 'vm'
        }
      }
    })

    // my accounts
    .state('app.myaccounts', {
      url: '/myaccounts',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/myAccounts.html',
          controller: 'MyAccountsCtrl',
          controllerAs: 'vm'
        }
      }
    })

    // unsolicited request
    .state('app.request', {
      url: '/request',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/request.html',
          controller: 'RequestCtrl',
          controllerAs: 'vm'
        }
      }
    })

    // unsolicited request history
    .state('app.requesthistory', {
      url: '/requesthistory',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/requestHistory.html',
          controller: 'RequestHistoryCtrl',
          controllerAs: 'vm'
        }
      }
    })

    // lead capture
    .state('app.leadcapture', {
      url: '/leadcapture',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/leadCapture.html',
          controller: 'LeadCaptureCtrl',
          controllerAs: 'vm'
        }
      }
    })

    // lead history
    .state('app.leadhistory', {
      url: '/leadhistory',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/leadHistory.html',
          controller: 'LeadHistoryCtrl',
          controllerAs: 'vm'
        }
      }
    })

    // content items
    .state('app.contentitem', {
      url: '/contentitem/:menuItem/:menuName',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/contentItem.html',
          controller: 'ContentItemCtrl',
          controllerAs: 'vm'
        }
      }
    })

    // outbox
    .state('app.outbox', {
      url: '/outbox',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/outbox.html',
          controller: 'OutboxCtrl',
          controllerAs: 'vm'
        }
      }
    })

    /*****************************************************
     * S E T T I N G S    &    D E V    T O O L S
     ****************************************************/

    .state('app.settings', {
      url: '/settings',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/settings.html',
          controller: 'SettingsCtrl'
        }
      }
    })

    .state('app.settings-devtools', {
      url: '/settings/devtools',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/settingsDevTools.html',
          controller: 'SettingsCtrl'
        }
      }
    })

    .state('app.settings-diagnostics', {
      url: '/settings/diagnostics',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT +  'templates/settingsDiagnostics.html',
          controller: 'DiagnosticsCtrl',
          controllerAs: 'vm'
        }
      }
    })

    .state('app.settings-mti-reovery', {
      url: '/settings/mti-recovery',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT +  'templates/settingsDevMTI.html',
          controller: 'MTICtrl'
        }
      },
      params: { 'recovery': true },
    })

    .state('app.settings-mti', {
      url: '/settings/mti',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/settingsDevMTI.html',
          controller: 'MTICtrl'
        }
      }
    })

    .state('app.mti-detail', {
      url: '/settings/mti/:tableName',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/settingsDevMTIDetail.html',
          controller: 'MTIDetailCtrl'
        }
      }
    })

    .state('app.data-view', {
      url: '/settings/data/:type',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/settingsDevRawView.html',
          controller: 'RawViewCtrl'
        }
      }
    })

    .state('app.settings-testing', {
      url: '/settings/testing',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/settingsTesting.html',
          controller: 'TestingCtrl'
        }
      }
    })

    .state('app.settings-deploy', {
      url: '/settings/deploy',
      views: {
        'menuContent': {
          templateUrl: RESOURCE_ROOT + 'templates/settingsDeploy.html',
          controller: 'DeployCtrl'
        }
      }
    });

    // Determine which initial page will be shown:- home or tutorial
    var tutorial = localStorage.getItem('tutorial');
    var tutorialDone = false;
    if (tutorial !== null) {
       tutorialDone = true;
    }

    // Check whether user has already seen the tutorial page
    if (tutorialDone) {
      $urlRouterProvider.otherwise('/app/home');
    } else {
      $urlRouterProvider.otherwise('/tutorial');
    }

}]);

// This is the function that get's called once the MobileCaddy libs are done
// checking the app install/health. Basically the point at which our client
// app can kick off. It's here we boot angular into action.
function myapp_callback(runUpInfo) {
  console.debug('runUpInfo', runUpInfo);
  if (typeof(runUpInfo) != "undefined" &&
     (typeof(runUpInfo.newVsn) != "undefined" && runUpInfo.newVsn != runUpInfo.curVsn)) {
    var syncRefresh = mobileCaddy.require('mobileCaddy/syncRefresh');
    syncRefresh.heartBeat(function(heartBeatObject) {
      // Continue if connected
      if ((heartBeatObject.status == syncRefresh.HEARTBEAT_OK) || (heartBeatObject.status == syncRefresh.HEARTBEAT_NOT_DEVICE) || (heartBeatObject.status == syncRefresh.HEARTBEAT_REFRESHED_OK)) {

        var devUtils= mobileCaddy.require('mobileCaddy/devUtils');
        devUtils.dirtyTables().then(function(tables){
          var logger = mobileCaddy.require('mobileCaddy/logger');
          if (tables && tables.length === 0) {
            var r = confirm("Upgrade Available:\nClick OK to upgrade now or Cancel to postpone.");
              if (r === true) {
                var vsnUtils= mobileCaddy.require('mobileCaddy/vsnUtils');
                vsnUtils.upgradeIfAvailable();
              } else {
                angular.bootstrap(document, ['starter']);
                logger.log('on startup: upgrade available but user declined');
              }
          } else {
            angular.bootstrap(document, ['starter']);
            logger.log('on startup: upgrade available but dirtyTables found');
          }
        });

      } else {
        // No connection at present
        angular.bootstrap(document, ['starter']);
      }
    },
    function(e) {
      console.error('Heartbeat failed', e);
    });
  } else {
    // carry on, nothing to see here
    angular.bootstrap(document, ['starter']);
  }
}
