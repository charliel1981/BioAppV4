/*! BioHub - v3.3.4 - 2019-01-30 09:51:27*/
/* Copyright 2019 MobileCaddy Ltd */
function myapp_callback(runUpInfo){if(console.debug("runUpInfo",runUpInfo),"undefined"!=typeof runUpInfo&&"undefined"!=typeof runUpInfo.newVsn&&runUpInfo.newVsn!=runUpInfo.curVsn){var syncRefresh=mobileCaddy.require("mobileCaddy/syncRefresh");syncRefresh.heartBeat(function(heartBeatObject){if(heartBeatObject.status==syncRefresh.HEARTBEAT_OK||heartBeatObject.status==syncRefresh.HEARTBEAT_NOT_DEVICE||heartBeatObject.status==syncRefresh.HEARTBEAT_REFRESHED_OK){var devUtils=mobileCaddy.require("mobileCaddy/devUtils");devUtils.dirtyTables().then(function(tables){var logger=mobileCaddy.require("mobileCaddy/logger");if(tables&&0===tables.length){var r=confirm("Upgrade Available:\nClick OK to upgrade now or Cancel to postpone.");if(r===!0){var vsnUtils=mobileCaddy.require("mobileCaddy/vsnUtils");vsnUtils.upgradeIfAvailable()}else angular.bootstrap(document,["starter"]),logger.log("on startup: upgrade available but user declined")}else angular.bootstrap(document,["starter"]),logger.log("on startup: upgrade available but dirtyTables found")})}else angular.bootstrap(document,["starter"])},function(e){console.error("Heartbeat failed",e)})}else angular.bootstrap(document,["starter"])}angular.module("starter",["ionic","starter.services","starter.controllers"]).run(["$ionicPlatform","NetworkService","AppRunStatusService","UserService","SyncService","logger","LocalNotificationService","appDataUtils",function($ionicPlatform,NetworkService,AppRunStatusService,UserService,SyncService,logger,LocalNotificationService,appDataUtils){$ionicPlatform.ready(function(){window.cordova&&window.cordova.plugins&&window.cordova.plugins.Keyboard&&(cordova.plugins.Keyboard.hideKeyboardAccessoryBar(!0),cordova.plugins.Keyboard.disableScroll(!0)),window.StatusBar&&(StatusBar.styleLightContent(),StatusBar.styleDefault()),document.addEventListener("resume",function(){AppRunStatusService.statusEvent("resume")},!1),document.addEventListener("online",function(){NetworkService.networkEvent("online")},!1),document.addEventListener("offline",function(){NetworkService.networkEvent("offline")},!1),cordova&&cordova.plugins&&cordova.plugins.notification&&(cordova.plugins.notification.local.on("trigger",function(notification,state){LocalNotificationService.handleLocalNotification(notification.id,state)}),cordova.plugins.notification.local.on("click",function(notification,state){LocalNotificationService.handleLocalNotificationClick(notification.id,state)}))}),angular.element(document.querySelector("#start-page")).remove(),localStorage.setItem("localNotificationState","enabled"),UserService.hasDoneProcess("initialDataLoaded").then(function(result){result?(SyncService.setSyncLock("false"),SyncService.setSyncState("complete"),SyncService.syncTables(["Mobile_Refresh__ap","Content_Item__ap","Surgeon_in_Hospital__ap","DOF__ap","DOF_Item__ap","Mobile_Dynamic__ap","Mobile_Log__mc"])):(NetworkService.setNetworkStatus("online"),SyncService.initialSync(["Mobile_Refresh__ap","Content_Item__ap","Surgeon_in_Hospital__ap","DOF__ap","DOF_Item__ap","Mobile_Dynamic__ap"]),appDataUtils.getCurrentValueFromAppSoup("authURLType").then(function(res){res&&""!==res||appDataUtils.updateCurrentValueInAppSoup("authURLType","instance")})["catch"](function(e){logger.error("Error with authURLType",e)}))})}]).config(["$stateProvider","$urlRouterProvider","$ionicConfigProvider","$compileProvider",function($stateProvider,$urlRouterProvider,$ionicConfigProvider,$compileProvider){$compileProvider.debugInfoEnabled(!1),$ionicConfigProvider.navBar.alignTitle("center"),$ionicConfigProvider.backButton.text(""),$ionicConfigProvider.views.swipeBackEnabled(!1),$stateProvider.state("tutorial",{url:"/tutorial",templateUrl:RESOURCE_ROOT+"templates/tutorial.html",controller:"TutorialCtrl",controllerAs:"vm"}).state("app",{url:"/app","abstract":!0,templateUrl:RESOURCE_ROOT+"templates/menu.html",controller:"MenuCtrl",controllerAs:"vm"}).state("app.home",{url:"/home",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/home.html",controller:"HomeCtrl",controllerAs:"vm"}}}).state("app.orderform",{url:"/orderform",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/orderForm.html",controller:"OrderFormCtrl",controllerAs:"vm"}}}).state("app.orderhistory",{url:"/orderhistory",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/orderHistory.html",controller:"OrderHistoryCtrl",controllerAs:"vm"}}}).state("app.newaccount",{url:"/newaccount",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/newAccount.html",controller:"NewAccountCtrl",controllerAs:"vm"}}}).state("app.newaccounthistory",{url:"/newaccounthistory",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/newAccountHistory.html",controller:"NewAccountHistoryCtrl",controllerAs:"vm"}}}).state("app.myaccounts",{url:"/myaccounts",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/myAccounts.html",controller:"MyAccountsCtrl",controllerAs:"vm"}}}).state("app.request",{url:"/request",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/request.html",controller:"RequestCtrl",controllerAs:"vm"}}}).state("app.requesthistory",{url:"/requesthistory",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/requestHistory.html",controller:"RequestHistoryCtrl",controllerAs:"vm"}}}).state("app.leadcapture",{url:"/leadcapture",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/leadCapture.html",controller:"LeadCaptureCtrl",controllerAs:"vm"}}}).state("app.leadhistory",{url:"/leadhistory",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/leadHistory.html",controller:"LeadHistoryCtrl",controllerAs:"vm"}}}).state("app.contentitem",{url:"/contentitem/:menuItem/:menuName",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/contentItem.html",controller:"ContentItemCtrl",controllerAs:"vm"}}}).state("app.outbox",{url:"/outbox",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/outbox.html",controller:"OutboxCtrl",controllerAs:"vm"}}}).state("app.settings",{url:"/settings",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/settings.html",controller:"SettingsCtrl"}}}).state("app.settings-devtools",{url:"/settings/devtools",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/settingsDevTools.html",controller:"SettingsCtrl"}}}).state("app.settings-diagnostics",{url:"/settings/diagnostics",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/settingsDiagnostics.html",controller:"DiagnosticsCtrl",controllerAs:"vm"}}}).state("app.settings-mti-reovery",{url:"/settings/mti-recovery",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/settingsDevMTI.html",controller:"MTICtrl"}},params:{recovery:!0}}).state("app.settings-mti",{url:"/settings/mti",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/settingsDevMTI.html",controller:"MTICtrl"}}}).state("app.mti-detail",{url:"/settings/mti/:tableName",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/settingsDevMTIDetail.html",controller:"MTIDetailCtrl"}}}).state("app.data-view",{url:"/settings/data/:type",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/settingsDevRawView.html",controller:"RawViewCtrl"}}}).state("app.settings-testing",{url:"/settings/testing",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/settingsTesting.html",controller:"TestingCtrl"}}}).state("app.settings-deploy",{url:"/settings/deploy",views:{menuContent:{templateUrl:RESOURCE_ROOT+"templates/settingsDeploy.html",controller:"DeployCtrl"}}});var tutorial=localStorage.getItem("tutorial"),tutorialDone=!1;null!==tutorial&&(tutorialDone=!0),tutorialDone?$urlRouterProvider.otherwise("/app/home"):$urlRouterProvider.otherwise("/tutorial")}]);