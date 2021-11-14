/**
 * starter.services module
 *
 * @description defines starter.service module and also sets up some other deps
 * as Angular modules.
 */
angular.module('underscore', [])
  .factory('_', function() {
    return window._; // assumes underscore has already been loaded on the page
});

angular.module('devUtils', [])
  .factory('devUtils', function() {
    return mobileCaddy.require('mobileCaddy/devUtils');
});

angular.module('vsnUtils', [])
  .factory('vsnUtils', function() {
    return mobileCaddy.require('mobileCaddy/vsnUtils');
});

angular.module('smartStoreUtils', [])
  .factory('smartStoreUtils', function() {
    return mobileCaddy.require('mobileCaddy/smartStoreUtils');
});

angular.module('logger', [])
  .factory('logger', function() {
    return mobileCaddy.require('mobileCaddy/logger');
});

angular.module('starter.services', ['underscore', 'devUtils', 'vsnUtils', 'smartStoreUtils', 'logger']);
/**
 * AppRunStatus Factory
 *
 * @description Handles app status events such as "resume" etc.
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('AppRunStatusService', AppRunStatusService);

  AppRunStatusService.$inject = ['$ionicPopup', '$ionicLoading', 'devUtils', 'vsnUtils', 'SyncService', 'logger'];

  function AppRunStatusService($ionicPopup, $ionicLoading, devUtils, vsnUtils, SyncService, logger) {

	 return {
	    statusEvent: function(status){
	      logger.log('AppRunStatusService status ' + status);
	      if (status == "resume") {
	        resume();
	      }
	    }
	  };

	  function resume() {
	    devUtils.dirtyTables().then(function(tables){
	      logger.log('on resume: dirtyTables check');
	      if (tables && tables.length === 0) {
	        logger.log('on resume: calling upgradeAvailable');
	        vsnUtils.upgradeAvailable().then(function(res){
	          logger.log('on resume: upgradeAvailable? ' + res);
	          if (res) {
	            var notificationTimeout = (1000 * 60 * 5); // 5 minutes
	            var prevUpNotification = localStorage.getItem('prevUpNotification');
	            var timeNow = Date.now();
	            if (prevUpNotification === null) {
	              prevUpNotification = 0;
	            }
	            if (parseInt(prevUpNotification) < (timeNow - notificationTimeout)){
	              var confirmPopup = $ionicPopup.confirm({
	                title: 'Upgrade available',
	                template: 'Would you like to upgrade now?',
	                cancelText: 'Not just now',
	                okText: 'Yes'
	              });
	              confirmPopup.then(function(res) {
	                if(res) {
	                  $ionicLoading.show({
	                    duration: 30000,
	                    delay : 400,
	                    maxWidth: 600,
	                    noBackdrop: true,
	                    template: '<h1>Upgrade app...</h1><p id="app-upgrade-msg" class="item-icon-left">Upgrading...<ion-spinner/></p>'
	                  });
	                  localStorage.removeItem('prevUpNotification');
	                  logger.log('on resume: calling upgradeIfAvailable');
	                  vsnUtils.upgradeIfAvailable().then(function(res){
	                    logger.log('on resume: upgradeIfAvailable res = ' + res);
	                    //console.log('upgradeIfAvailable', res);
	                    if (!res) {
	                      $ionicLoading.hide();
	                      $scope.data = {};
	                      $ionicPopup.show({
	                        title: 'Upgrade',
	                        subTitle: 'The upgrade could not take place due to sync in progress. Please try again later.',
	                        scope: $scope,
	                        buttons: [
	                          {
	                            text: 'OK',
	                            type: 'button-positive',
	                            onTap: function(e) {
	                              return true;
	                            }
	                          }
	                        ]
	                      });
	                    }
	                  }).catch(function(e){
	                    logger.error("resume " + JSON.stringify(e));
	                    $ionicLoading.hide();
	                  });
	                } else {
	                  localStorage.setItem('prevUpNotification', timeNow);
	                }
	              });
	            }
	          }
	        });
	      } else {
	        logger.log('on resume: dirtyTables found');
	        // console.log('bio on resume: dirtyTables found');
	        SyncService.syncTables(['DOF__ap', 'DOF_Item__ap', 'Mobile_Dynamic__ap']);
	      }
	    });
	    return true;
	  }
  }

})();
/**
 * Content Item Factory
 *
 * @description Gets data for the Content Item controller.
 *
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('ContentItemService', ContentItemService);

  ContentItemService.$inject = ['devUtils', 'logger'];

  function ContentItemService(devUtils, logger) {

    return {
      getContentItems: getContentItems
    };

    function getContentItems(menuItem) {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('Content_Item__ap', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .filter(function(el){
                return (el.Menu_Item__c == menuItem) ? true : false;
              })
            .sortBy('Order__c')
            .value();
          resolve(records);
        }).catch(function(resObject){
          // console.error('getContentItems ', angular.toJson(resObject));
          logger.error('getContentItems ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

  }

})();
/**
 * Deploy Factory
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('DeployService', DeployService);

  DeployService.$inject = ['$rootScope', '$q', '$timeout', '$http'];

  function DeployService($rootScope, $q, $timeout, $http) {
		var apiVersion = "v32.0";


	  return {
	    getDetails : getDetails,

	    deployBunlde : function(appConfig){
	      return encodeAppBundle(appConfig).then(function(myBody, bundleFiles){
	        return uploadAppBundle(appConfig, myBody);
	      });
	    },
	    uploadCachePage : uploadCachePage,

	    uploadStartPage : uploadStartPage,

	    srDetails: function() {
	      return encodeAppBundle().then(function(myBody){
	        return uploadAppBundle(myBody);
	      }).then(function(res){
	        return uploadStartPage();
	      });
	    }
	  };

	  function _arrayBufferToBase64( buffer ) {
	    var binary = '';
	    var bytes = new Uint8Array( buffer );
	    var len = bytes.byteLength;
	    for (var i = 0; i < len; i++) {
	        binary += String.fromCharCode( bytes[ i ] );
	    }
	    return window.btoa( binary );
	  }

	  /**
	   * Does the static resource already exist on the platform for this app/vsn
	   */
	  function doesBundleExist(appConfig){
	    return new Promise(function(resolve, reject) {
	    var dataName = appConfig.sf_app_name + '_' + appConfig.sf_app_vsn;
	    // check if statid resource already exists
	    force.request(
	      {
	        path: '/services/data/' + apiVersion + '/tooling/query/?q=select Id, Name, Description, LastModifiedDate from StaticResource WHERE Name=\'' + dataName + '\' LIMIT 1'
	      },
	      function(response) {
	          console.debug('response' , response);
	          resolve(response);
	      },
	      function(error) {
	        console.error('Failed to check if app bundle already existed on platform');
	        reject({message :"App bundle upload failed. See console for details.", type: 'error'});
	      });
	    });
	  }

	  /**
	   * Does the static resource already exist on the platform for this app/vsn
	   */
	  function doesPageExist(pageName){
	    return new Promise(function(resolve, reject) {
	    // check if statid resource already exists
	    force.request(
	      {
	        path: '/services/data/' + apiVersion + '/tooling/query/?q=select Id, Name, Description, LastModifiedDate from ApexPage WHERE Name=\'' + pageName + '\' LIMIT 1'
	      },
	      function(response) {
	          console.debug('response' , response);
	          resolve(response);
	      },
	      function(error) {
	        console.error('Failed to check if page already existed on platform');
	        reject({message :"Page upload failed. See console for details.", type: 'error'});
	      });
	    });
	  }

	  function getDetails () {
	    return new Promise(function(resolve, reject) {
	    var details = {};
	    $timeout(function() {
	        $http.get('../package.json').success(function(appConfig) {
	          appConfig.sf_app_vsn = appConfig.version.replace(/\./g, '');
	          resolve(appConfig);
	        }).catch(function(err){
	          console.error(err);
	        });
	    }, 30);
	    });
	  }

	  function encodeAppBundle(appConfig){
	    return new Promise(function(resolve, reject) {

	      JSZipUtils.getBinaryContent('../' + appConfig.name + '-' + appConfig.version +'.zip', function(err, data) {
	        if(err) {
	          console.error(err);
	          reject(err); // or handle err
	        }
	        var zipFileLoaded = new JSZip(data);
	        $rootScope.deployFiles = zipFileLoaded.files;
	        resolve(_arrayBufferToBase64(data));
	      });
	    });
	  }

	  function uploadAppBundle (appConfig, myBody) {
	    return new Promise(function(resolve, reject) {
	    var dataName = appConfig.sf_app_name + '_' + appConfig.sf_app_vsn;
	    doesBundleExist(appConfig).then(function(response){
	      if (response.records.length > 0) {
	        // Update existing resource
	        console.debug('resource exists... patching existing');
	        var existingSR = response.records[0];
	        force.request(
	          {
	            method: 'PATCH',
	            contentType: 'application/json',
	            path: '/services/data/' + apiVersion + '/tooling/sobjects/StaticResource/' + existingSR.Id + '/',
	            data: {
	              'Body':myBody
	            }
	          },
	          function(response) {
	              console.debug('response' , response);
	              resolve('Existing app bundle updated');
	          },
	          function(error) {
	            console.error('Failed to check if app bundle already existed on platform');
	            reject({message :"App bundle upload failed. See console for details.", type: 'error'});
	          }
	        );
	      } else {
	        // Updload new resource
	        force.request(
	          {
	            method: 'POST',
	            contentType: 'application/json',
	            path: '/services/data/' + apiVersion + '/tooling/sobjects/StaticResource/',
	            data: {
	              'Name': dataName,
	              'Description' : 'App Bundle - auto-uploaded by MobileCaddy delopyment tooling',
	              'ContentType':'application/zip',
	              'Body':myBody,
	              'CacheControl': 'Public'
	            }
	          },
	          function(response) {
	            console.debug('response' , response);
	            resolve('App bundle uploaded');
	          },
	          function(error) {
	            console.error(error);
	            reject({message :"App bundle upload failed. See console for details.", type: 'error'});
	          });
	      }
	    });
	    });
	  }

	  function uploadCachePage(appConfig) {
	    return new Promise(function(resolve, reject) {
	      $timeout(function() {
	        $http.get('../apex-templates/cachepage-template.apex').success(function(data) {
	          var dataName = appConfig.sf_app_name + 'Cache_' + appConfig.sf_app_vsn;
	          var cacheEntriesStr = '';
	          _.each($rootScope.deployFiles, function(el){
	            if (!el.dir) cacheEntriesStr += '{!URLFOR($Resource.' + appConfig.sf_app_name + '_' + appConfig.sf_app_vsn + ', \'' + el.name + '\')}\n';
	          });
	          var dataParsed = data.replace(/MC_UTILS_RESOURCE/g, appConfig.mc_utils_resource);
	          dataParsed = dataParsed.replace(/MY_APP_FILE_LIST/g, cacheEntriesStr);
	          delete $rootScope.deployFiles;

	          doesPageExist(dataName).then(function(response){
	            if (response.records.length > 0) {
	               // Update existing resource
	              console.debug('page exists... patching existing');
	              var existingPage = response.records[0];
	              force.request(
	                {
	                  method: 'PATCH',
	                  contentType: 'application/json',
	                  path: '/services/data/' + apiVersion + '/tooling/sobjects/ApexPage/' + existingPage.Id + '/',
	                  data: {
	                    'Markup' : dataParsed
	                  },
	                },
	                function(response) {
	                  resolve('Existing Cache manifest updated');
	                },
	                function(error) {
	                  console.error(error);
	                  reject({message :'Cache manifest upload failed. See console for details.', type: 'error'});
	                }
	              );
	            } else {
	              force.request(
	                {
	                  method: 'POST',
	                  contentType: 'application/json',
	                  path: '/services/data/' + apiVersion + '/tooling/sobjects/ApexPage/',
	                  data: {
	                    'Name': dataName,
	                    'MasterLabel': dataName,
	                    'Markup' : dataParsed
	                  }
	                },
	                function(response) {
	                  resolve('Cache manifest uploaded');
	                },
	                function(error) {
	                  console.error(error);
	                  reject({message :'Cache manifest upload failed. See console for details.', type: 'error'});
	                }
	              );
	            }
	        });
	      }, 30);
	    });
	    });
	  }


	  function uploadStartPage(appConfig) {
	    return new Promise(function(resolve, reject) {
	      $timeout(function() {
	        $http.get('../apex-templates/startpage-template.apex').success(function(data) {
	          var dataName = appConfig.sf_app_name + '_' + appConfig.sf_app_vsn;
	          var dataParsed = data.replace(/MC_UTILS_RESOURCE/g, appConfig.mc_utils_resource);
	          dataParsed = dataParsed.replace(/MY_APP_RESOURCE/g, appConfig.sf_app_name + '_' + appConfig.sf_app_vsn);
	          dataParsed = dataParsed.replace(/MY_APP_CACHE_RESOURCE/g, appConfig.sf_app_name + 'Cache_' + appConfig.sf_app_vsn);
	          force.request(
	            {
	              method: 'POST',
	              contentType: 'application/json',
	              path: '/services/data/' + apiVersion + '/tooling/sobjects/ApexPage/',
	              data: {
	                'Name': dataName,
	                'ControllerType' : '3',
	                'MasterLabel': dataName,
	                'Markup' : dataParsed
	              }
	            },
	            function(response) {
	              resolve('Start page uploaded');
	            },
	            function(error) {
	              console.error(error);
	              doesPageExist(dataName).then(function(response){
	                if (response.records.length > 0) {
	                  reject({message :'Start page already exists. Not updated.', type : 'info'});
	                } else {
	                  reject({message :'Start page upload failed. See console for details.', type: 'error'});
	                }
	              });
	            }
	          );
	        });
	      }, 30);
	    });
	  }

  }

})();
/**
 * Dev Factory
 *
 * @description
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('DevService', DevService);

  DevService.$inject = ['$rootScope', '$q', '_', 'devUtils', 'smartStoreUtils'];

  function DevService($rootScope, $q, _, devUtils, smartStoreUtils) {

	  return {
	    allTables: getTables,

	    allRecords: function(tableName,refreshFlag) {
	    	var tableRecs = [];
	      switch (refreshFlag) {
	        case true :
	          tableRecs = [];
	          tableRecs = getRecords(tableName, true);
	          break;
	        default :
	          if ((typeof tableRecs == 'undefined') || (tableRecs.length < 1)) {
	            tableRecs = [];
	            tableRecs = getRecords(tableName, true);
	          } else {
	            tableRecs = [];
	            tableRecs = getRecords(tableName, false);
	          }
	      }
	      return tableRecs;
	    },
	    getRecordForSoupEntryId: getRecordForSoupEntryId,

	    insertMobileLog: insertMobileLog
	  };

	  function getTables() {
	    var deferred = $q.defer();
	    var tables = [];

	    // Add other system tables
	    tables.push({'Name' : 'syncLib_system_data'});
	    tables.push({'Name' : 'appSoup'});
	    tables.push({'Name' : 'cacheSoup'});
	    tables.push({'Name' : 'recsToSync'});
	    smartStoreUtils.listMobileTables(
	      smartStoreUtils.ALPHA,
	      // Success callback
	      function(tableNames) {
	          $j.each(tableNames, function(i,tableName) {
	            tables.push({'Name' : tableName});
	            // TODO :: make this a promise ?
	            // TODO :: Improve this, add a meta table?
	            smartStoreUtils.getTableDefnColumnValue(
	              tableName,
	              'Snapshot Data Required',
	              function(snapshotValue) {
	                // Create the snapshot table too, if required
	                if (snapshotValue == 'Yes') {
	                  tables.push({'Name' : 'SnapShot_' + tableName});
	                } else {
	                }
	                $rootScope.$apply(function(){
	                  tables = tables;
	                });
	                return tables;
	              }, // end success callback
	              function(resObject){
	                console.error('MC : Error from listMobileTables -> ' + angular.toJson(resObject));
	                deferred.reject('error');
	              });
	          });

	          $rootScope.$apply(function(){
	            deferred.resolve(tables);
	            });
	          return deferred.promise;
	        },
	      function(e) {
	        console.log('MC: error from listMobileTables -> ' + angular.toJson(e));
	        deferred.reject(e);
	      });
	    return deferred.promise;
	  }


	 /**
	  * Works out if Val is likely an ID based on it's format
	  * @param {string} Val
	  * @return {boolean}
	  */
	  function isId(Val) {
	    var patt = /^[a-zA-Z0-9]{18}$/;
	    return patt.test(Val);
	  }


	  function getRecords(tableName, refreshFlag) {
	    var deferred = $q.defer();
	    var myTableRecs = [];
	    devUtils.readRecords(tableName, []).then(function(resObject) {
	    	console.log(tableName, resObject);
	      $j.each(resObject.records, function(i,record) {
	        var tableRec = [];
	        for (var fieldDef in record) {
	          var field = {
	            'Name' : fieldDef,
	            'Value' : record[fieldDef],
	            'ID_flag' : isId(record[fieldDef])};
	          tableRec.push(field);
	        } // end loop through the object fields
	        myTableRecs.push(tableRec);
	      });
	      deferred.resolve(myTableRecs);
	    }).catch(function(resObject){
	      console.error('MC : Error from devUtils.readRecords -> ' + angular.toJson(resObject));
	      deferred.reject('error');
	    });
	    return deferred.promise;
	  }

	  function getRecordForSoupEntryId(tableName, soupRecordId) {
	    return new Promise(function(resolve, reject) {
	      devUtils.readRecords(tableName, []).then(function(resObject) {
	        var record = _.findWhere(resObject.records, {'_soupEntryId': soupRecordId});
	        resolve(record);
	      }).catch(function(resObject){
	        reject(resObject);
	      });
	    });
	  }

	  function insertRecordUsingSmartStoreUtils(tableName, rec) {
	    return new Promise(function(resolve, reject) {
	      smartStoreUtils.insertRecords(tableName, [rec],
	        function(res) {
	          resolve(res);
	        },
	        function(err) {
	          reject(err);
	        }
	      );
	    });
	  }

	  function insertMobileLog(recs) {
	    return new Promise(function(resolve, reject) {
	      var remainingData = JSON.stringify(recs);
	      var dataToInsert = [];
	      // Push 'chunks' of data to array for processing further down
	      while (remainingData.length > 0) {
	        dataToInsert.push(remainingData.substring(0,32767));
	        remainingData = remainingData.substring(32767);
	      }
	      // Iterate over the data 'chunks', inserting each 'chunk' into the Mobile_Log_mc table
	      var sequence = Promise.resolve();
	      dataToInsert.forEach(function(data){
	        sequence = sequence.then(function() {
	          var mobileLog = {};
	          mobileLog.Name = "TMP-" + new Date().valueOf();
	          mobileLog.mobilecaddy1__Error_Text__c = data;
	          mobileLog.SystemModstamp = new Date().getTime();
	          return insertRecordUsingSmartStoreUtils('Mobile_Log__mc', mobileLog);
	        }).then(function(resObject) {
	          resolve(resObject);
	        }).catch(function(res){
	          reject(res);
	        });
	      });
	    });
	  }

  }

})();
/**
 * LocalNotificationService
 *
 * @description Enables device local notifications using Cordova Local-Notification Plugin
 *              (https://github.com/katzer/cordova-plugin-local-notifications)
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('LocalNotificationService', LocalNotificationService);

  LocalNotificationService.$inject = ['$cordovaLocalNotification', '$cordovaNetwork', 'devUtils', 'logger', 'SyncService'];

  function LocalNotificationService($cordovaLocalNotification, $cordovaNetwork, devUtils, logger, SyncService) {

    var lnDefaultTimeout = 600,  // 5 minutes
        lnDefaultId      = 100100,
        lnDefaultMsg     = 'Unsynced records';

    return {
      cancelNotification: cancelNotification,

      setLocalNotification: setLocalNotification,

      handleLocalNotification: handleLocalNotification,

      handleLocalNotificationClick: handleLocalNotificationClick,

      getLocalNotificationState: getLocalNotificationState,

      setLocalNotificationState: setLocalNotificationState
    };


    /**
     * @function cancelNotification
     * @description Attempts to cancel the localNotifcation with a certain id
     * @param  {string | number | undefined} id
     */
    function cancelNotification(id) {
      return new Promise(function(resolve, reject) {
        id =  (id) ? id : lnDefaultId;
        if (getLocalNotificationState() == "disabled") {
          logger.log('cancelNotification NotificationState disabled');
          resolve();
        } else {
          logger.log('cancelNotification', id);
          if (cordova && cordova.plugins && cordova.plugins.notification) {
            $cordovaLocalNotification.cancel(id).then(function (result) {
              logger.log('localNotification cancelled if it existed', id, result);
              resolve(result);
            });
          }
        }
    });
    }

    /**
     * @function setLocalNotification
     * @description Sets a localNotification for id
     * @param {string | number | undefined} id
     * @param {integer | undefined} secsTillNotify - number of seconds till notification
     * @param {string | undefined} msg
     */
    function setLocalNotification(id, secsTillNotify, msg) {
      return new Promise(function(resolve, reject) {
        if (getLocalNotificationState() == "disabled") {
          logger.log('setLocalNotification NotificationState disabled');
          resolve('ok');
        } else {
          // Set to defaults if needed
          id =  (id) ? id : lnDefaultId;
          secsTillNotify =  (secsTillNotify) ? secsTillNotify : lnDefaultTimeout;
          msg =  (msg) ? msg : lnDefaultMsg;

          logger.log('setLocalNotification id', id, secsTillNotify, msg );
          devUtils.dirtyTables().then(function(tables){
            if (tables && tables.length === 0 && id == lnDefaultId) {
              // do nothing if no dirtyTables and using defeault ID (the used by SyncService)
              logger.log('setLocalNotification no dirty tables', id);
              resolve();
            } else {
              if (cordova && cordova.plugins && cordova.plugins.notification) {
                var alarmTime = new Date();
                alarmTime.setSeconds(alarmTime.getSeconds() + secsTillNotify);
                logger.log('setLocalNotification alarmTime', alarmTime);
                $cordovaLocalNotification.isScheduled(id).then(function(isScheduled) {
                  logger.log('setLocalNotification isScheduled', isScheduled);
                  if (isScheduled) {
                    // update existing notification
                    $cordovaLocalNotification.update({
                      id: id,
                      at: alarmTime,
                    }).then(function (result) {
                      logger.log("localNotification updated", id, result);
                      resolve(result);
                    });
                  } else {
                    // set a new notification
                    var args = {
                      id: id,
                      at: alarmTime,
                      text: msg,
                      sound: null};
                    if (device.platform == "Android") {
                       args.ongoing = true;
                       args.smallIcon = "res://icon";
                    }
                    $cordovaLocalNotification.schedule(args).then(function (result) {
                      logger.log("localNotification has been set", id, result);
                      resolve(result);
                    });
                  }
                }).catch(function(err){
                  logger.error("setLocalNotification", JSON.stringify(err));
                  reject(err);
                });
              } else {
                logger.log('setLocalNotification no cordova plugin');
                resolve();
              }
            }
          });
        }
      });
    }

    function handleLocalNotification(id, state) {
      return new Promise(function(resolve, reject) {
        if (getLocalNotificationState() == "disabled") {
          logger.log('handleLocalNotification NotificationState disabled');
          resolve();
        } else {
          logger.log('handleLocalNotification', id, state);
          if (cordova && cordova.plugins && cordova.plugins.notification) {
            if (id == lnDefaultId) { // lnDefaultId is used for our syncProcess
              $cordovaLocalNotification.cancel(id, function(){});
              devUtils.dirtyTables().then(function(tables){
                //console.log('mc tables', tables);
                if (tables && tables.length !== 0) {
                  var isOnline = $cordovaNetwork.isOnline();
                  logger.log('handleLocalNotification isOnline', isOnline);
                  if (isOnline) {
                    // take this opportunity to set our network status in case it's wrong
                    localStorage.setItem('networkStatus', 'online');
                    resolve();
                    SyncService.syncAllTables();
                  } else {
                    // take this opportunity to set our network status in case it's wrong
                    localStorage.setItem('networkStatus', 'offline');
                    setLocalNotification(id).then(function(result){
                      resolve(result);
                    }).catch(function(e){
                      reject(e);
                    });
                  }
                } else {
                  resolve();
                }
              });
            } else {
              resolve();
            }
          } else {
            resolve();
          }
        }
      });
    }


    function handleLocalNotificationClick(id, state) {
      return new Promise(function(resolve, reject) {
        if (getLocalNotificationState() == "disabled") {
          logger.log('handleLocalNotification NotificationState disabled');
          resolve();
        } else {
          logger.log('handleLocalNotification', id, state);
          if (cordova && cordova.plugins && cordova.plugins.notification) {
            if (id == lnDefaultId) { // lnDefaultId is used for our syncProcess
              $cordovaLocalNotification.cancel(id, function(){});
              devUtils.dirtyTables().then(function(tables){
                //console.log('mc tables', tables);
                if (tables && tables.length !== 0) {
                  var isOnline = $cordovaNetwork.isOnline();
                  logger.log('handleLocalNotification isOnline', isOnline);
                  if (isOnline) {
                    // take this opportunity to set our network status in case it's wrong
                    localStorage.setItem('networkStatus', 'online');
                    resolve();
                  } else {
                    // take this opportunity to set our network status in case it's wrong
                    localStorage.setItem('networkStatus', 'offline');
                    setLocalNotification(id).then(function(result){
                      resolve(result);
                    }).catch(function(e){
                      reject(e);
                    });
                  }
                } else {
                  resolve();
                }
              });
            } else {
              resolve();
            }
          } else {
            resolve();
          }
        }
      });
    }

    function getLocalNotificationState() {
      var localNotificationState = localStorage.getItem("localNotificationState");
      if (localNotificationState === null) {
        localNotificationState = "enabled";
        localStorage.setItem("localNotificationState", localNotificationState);
      }
      return localNotificationState;
    }

    function setLocalNotificationState(status) {
      localStorage.setItem("localNotificationState", status);
    }

  }

})();

/**
 * Menu Factory
 *
 * @description Builds json used in nested menu.
 *
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('MenuService', MenuService);

  MenuService.$inject = ['devUtils', '$window', 'logger'];

  function MenuService(devUtils, $window, logger) {

    return {
      getSideMenuJson: getSideMenuJson,

      buildAndSetSideMenuJson: buildAndSetSideMenuJson,

      setSideMenuJson: setSideMenuJson
    };

    function buildAndSetSideMenuJson() {
      return new Promise(function(resolve, reject) {
        buildSideMenuJson().then(function(result) {
          setSideMenuJson(result);
          resolve(result);
        }).catch(function(e){
          reject(e);
        });
      });
    }

    function getSideMenuJson() {
      return new Promise(function(resolve, reject) {
        resolve(JSON.parse(localStorage.getItem('sidemenu')));
      });
    }

    function setSideMenuJson(sideMenuJson) {
      localStorage.setItem('sidemenu', JSON.stringify(sideMenuJson));
    }

    function buildSideMenuJson() {
      // console.log("bio in buildSideMenuJson");
      // logger.log("in buildSideMenuJson");
      var resourcePath = $window.RESOURCE_ROOT + "images/";
      return new Promise(function(resolve, reject) {
        getMenuItems().then(function(records) {
          var sideMenuJson = [];
          var mainMenuOption;
          var stimulanMenuOption;
          var stimulanSubMenuOption;
          var stimulanSubMenu = [];
          var settingsMenuOption;
          var settingsSubMenuOption;
          var settingsSubMenu = [];
          var menuOption;
          var menuOptionName;

          // Get menu options
          for (var i = 0; i < records.length; i++) {
            menuOption = records[i].App_Menu_Option__c;
            menuOptionName = records[i].Name__c;
            stimulanSubMenuOption = null;
            settingsSubMenuOption = null;
            mainMenuOption = null;
            if (menuOption == "apps") {
              stimulanSubMenuOption = {"id": 40, "name": menuOptionName, "node": true, "parentid": 4, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "key-ben") {
              stimulanSubMenuOption = {"id": 41, "name": menuOptionName, "node": true, "parentid": 4, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "hip") {
              stimulanSubMenuOption = {"id": 42, "name": menuOptionName, "node": true, "parentid": 4, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "knee") {
              stimulanSubMenuOption = {"id": 43, "name": menuOptionName, "node": true, "parentid": 4, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "foot") {
              stimulanSubMenuOption = {"id": 44, "name": menuOptionName, "node": true, "parentid": 4, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "trauma") {
              stimulanSubMenuOption = {"id": 45, "name": menuOptionName, "node": true, "parentid": 4, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "faq") {
              stimulanSubMenuOption = {"id": 46, "name": menuOptionName, "node": true, "parentid": 4, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "map") {
              stimulanSubMenuOption = {"id": 47, "name": menuOptionName, "node": true, "parentid": 4, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "tutorial") {
              settingsSubMenuOption = {"id": 90, "name": menuOptionName, "node": true, "parentid": 9, "path": "/tutorial", "submenu": []};
            } else if (menuOption == "terms") {
              settingsSubMenuOption = {"id": 91, "name": menuOptionName, "node": true, "parentid": 9, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "mc-settings") {
              settingsSubMenuOption = {"id": 92, "name": menuOptionName, "node": true, "parentid": 9, "path": "/app/settings", "submenu": []};
            }
            if (stimulanSubMenuOption) {
              stimulanSubMenu.push(stimulanSubMenuOption);
            }
            if (settingsSubMenuOption) {
              settingsSubMenu.push(settingsSubMenuOption);
            }
            if (menuOption == "home") {
              mainMenuOption = {"id": 1, "name": menuOptionName, "node": true, "parentid": 0, "href": "#/app/home", "svg": resourcePath + "home-icon.svg", "submenu": []};
            } else if (menuOption == "order-form") {
              mainMenuOption = {"id": 2, "name": menuOptionName, "node": true, "parentid": 0, "href": "#/app/orderform", "svg": resourcePath + "order-form-icon.svg", "submenu": []};
            } else if (menuOption == "un-req") {
              mainMenuOption = {"id": 3, "name": menuOptionName, "node": true, "parentid": 0, "href": "#/app/request", "svg": resourcePath + "unsolicited-request-icon.svg", "submenu": []};
            } else if (menuOption == "stimulan") {
              mainMenuOption = {"id": 4, "name": menuOptionName, "node": false, "parentid": 0, "href": "#/app/home", "svg": resourcePath + "stimulan-icon.svg", "submenu": []};
              // Pass stimulan menu options back so we can go directly to it from home page button
              stimulanMenuOption = mainMenuOption;
            } else if (menuOption == "bio") {
              mainMenuOption = {"id": 5, "name": menuOptionName, "node": true, "parentid": 0, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "svg": resourcePath + "biocomposites-icon.svg", "submenu": []};
            } else if (menuOption == "toi") {
              mainMenuOption = {"id": 6, "name": menuOptionName, "node": true, "parentid": 0, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "svg": resourcePath + "topics-of-interest-icon.svg", "submenu": []};
            } else if (menuOption == "e-learn") {
              mainMenuOption = {"id": 7, "name": menuOptionName, "node": true, "parentid": 0, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "svg": resourcePath + "e-learning-icon.svg", "submenu": []};
            } else if (menuOption == "l-cap") {
              mainMenuOption = {"id": 8, "name": menuOptionName, "node": true, "parentid": 0, "href": "#/app/leadcapture", "svg": resourcePath + "lead-capture-icon.svg", "submenu": []};
            } else if (menuOption == "settings") {
              mainMenuOption = {"id": 9, "name": menuOptionName, "node": false, "parentid": 0, "href": "#/app/home", "svg": resourcePath + "settings-icon.svg", "submenu": []};
              settingsMenuOption = mainMenuOption;
            } else if (menuOption == "outbox") {
              mainMenuOption = {"id": 10, "name": menuOptionName, "node": true, "parentid": 0, "href": "#/app/outbox", "svg": resourcePath + "outbox-icon.svg", "submenu": []};
            } else if (menuOption == "sync") {
              mainMenuOption = {"id": 11, "name": menuOptionName, "node": true, "parentid": 0, "click": "vm.doRefreshAndSync()", "svg": resourcePath + "sync-icon.svg", "submenu": []};
            }
            if (mainMenuOption) {
              sideMenuJson.push(mainMenuOption);
            }
          }

          // Update the stimulan and settings sub menus
          for (var x = 0, len = sideMenuJson.length; x < len; x++) {
            if (sideMenuJson[x].id === 4) {
              sideMenuJson[x].submenu = stimulanSubMenu;
            }
            if (sideMenuJson[x].id === 9) {
              sideMenuJson[x].submenu = settingsSubMenu;
            }
          }

          // console.log("bio sideMenuJson",sideMenuJson);
          // logger.log("sideMenuJson.length: "+sideMenuJson.length);

          resolve([sideMenuJson,stimulanMenuOption,settingsMenuOption]);
        }).catch(function(e){
          reject(e);
        });
      });
    }

    function getMenuItems() {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('Mobile_Refresh__ap', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .filter(function(el){
                return (el.RecordType_Name__c == "Profile Menu Item") ? true : false;
              })
            .sortBy('Order__c')
            .value();
          resolve(records);
        }).catch(function(resObject){
          //console.error('getMenuItems ', angular.toJson(resObject));
          logger.error('getMenuItems ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

  }

})();
/**
 * Mobile Dynamic Factory
 *
 * @description Read and writes data from the Mobile Dynamic object (e.g. Request & Request History controllers)
 *
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('MobileDynamicService', MobileDynamicService);

  MobileDynamicService.$inject = ['devUtils', 'logger'];

  function MobileDynamicService(devUtils, logger) {

    return {
      insertRecord: insertRecord,
      getRecords: getRecords
    };

    function insertRecord(record) {
      return new Promise(function(resolve, reject) {
        devUtils.insertRecord('Mobile_Dynamic__ap', record).then(function(resObject) {
          resolve(resObject);
        }).catch(function(resObject){
          // console.error('insertRecord ', angular.toJson(resObject));
          logger.error('insertRecord ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

    function getRecords(recordTypeId) {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('Mobile_Dynamic__ap', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .filter(function(el){
                return (el.RecordTypeId == recordTypeId) ? true : false;
              })
            .sortBy(function(e) { return -e.Date_Entered__c; })
            .value();
          resolve(records);
        }).catch(function(resObject){
          // console.error('getRecords ', angular.toJson(resObject));
          logger.error('getRecords ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

  }

})();
/**
 * Network Factory
 *
 * @description Handles network events (online/offline) and kicks off tasks if needed
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('NetworkService', NetworkService);

  NetworkService.$inject = ['SyncService', 'logger'];

  function NetworkService(SyncService, logger) {
  	return {
	    networkEvent: function(status){
        var pastStatus = localStorage.getItem('networkStatus');
        if (status == "online" && pastStatus != status) {
          // You could put some actions in here that you want to take place when
          // your app regains connectivity. For example see the Mobile Seed Apps
          // If you don't need this then you can ignore this. e.g.
          // SyncService.syncTables(['Table_x__ap', 'Table_y__ap'], true);
        }
        localStorage.setItem('networkStatus', status);
        logger.log("NetworkService " + status);
        return true;
      },

      getNetworkStatus: function() {
        return localStorage.getItem('networkStatus');
      },

      setNetworkStatus: function(status) {
	      localStorage.setItem('networkStatus', status);
      }
	  };
  }

})();
/**
 * Order Form Factory
 *
 * @description Read and writes data for the Order Form & Order History controllers.
 *
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('OrderFormService', OrderFormService);

  OrderFormService.$inject = ['devUtils', 'logger'];

  function OrderFormService(devUtils, logger) {

    return {
      getProducts: getProducts,
      getHospitals: getHospitals,
      getSurgeons: getSurgeons,
      insertOrderForm: insertOrderForm,
      insertOrderFormItems: insertOrderFormItems,
      getOrders: getOrders,
      getOrderItems: getOrderItems
    };

    function getProducts() {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('Mobile_Refresh__ap', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .filter(function(el){
                return (el.RecordType_Name__c == "Product") ? true : false;
              })
            .value();
          resolve(records);
        }).catch(function(resObject){
          // console.error('getProducts ', angular.toJson(resObject));
          logger.error('getProducts ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

    function getHospitals() {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('Surgeon_in_Hospital__ap', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .uniq('Hospital_Name__c')
            .sortBy('Hospital_Name__c')
            .value();
          resolve(records);
        }).catch(function(resObject){
          // console.error('getHospitals ', angular.toJson(resObject));
          logger.error('getHospitals ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

    function getSurgeons() {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('Surgeon_in_Hospital__ap', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .uniq(function(el){
                return el.Last_Name__c + el.First_Name__c;
              })
            .sortBy('First_Name__c')
            .sortBy('Last_Name__c')
            .value();
          resolve(records);
        }).catch(function(resObject){
          // console.error('getSurgeons ', angular.toJson(resObject));
          logger.error('getSurgeons ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

    function insertOrderForm(record) {
      return new Promise(function(resolve, reject) {
        devUtils.insertRecord('DOF__ap', record).then(function(resObject) {
          resolve(resObject);
        }).catch(function(resObject){
          // console.error('insertOrderForm ', angular.toJson(resObject));
          logger.error('insertOrderForm ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

    function insertOrderFormItems(records){
      return new Promise(function(resolve, reject) {
        devUtils.insertRecords('DOF_Item__ap', records).then(function(resObject) {
          resolve(resObject);
        }).catch(function(resObject){
          // console.error('insertOrderFormItems ', angular.toJson(resObject));
          logger.error('insertOrderFormItems ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

    function getOrders() {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('DOF__ap', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .sortBy(function(e) { return -e.Date_Entered__c; })
            .value();
          resolve(records);
        }).catch(function(resObject){
          // console.error('getOrders ', angular.toJson(resObject));
          logger.error('getOrders ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

    function getOrderItems() {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('DOF_Item__ap', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .value();
          resolve(records);
        }).catch(function(resObject){
          // console.error('getOrderItems ', angular.toJson(resObject));
          logger.error('getOrderItems ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }
  }

})();
/**
 * Outbox Factory
 *
 * @description Gets data for the Outbox menu option.
 *
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('OutboxService', OutboxService);

  OutboxService.$inject = ['devUtils', 'logger'];

  function OutboxService(devUtils, logger) {

    return {
      getDirtyRecordsCount: getDirtyRecordsCount,
      getDirtyRecords: getDirtyRecords,
      getRecordForSoupEntryId: getRecordForSoupEntryId,
      getSurgeonInHospital: getSurgeonInHospital,
      getOrderItems: getOrderItems,
      getProductsForOrderItems: getProductsForOrderItems
    };

    function getDirtyRecordsCount() {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('recsToSync', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .filter(function(el){
                return (el.Mobile_Table_Name == "DOF__ap" || el.Mobile_Table_Name == "Mobile_Dynamic__ap") ? true : false;
              })
            .value();
          resolve(records.length);
        }).catch(function(resObject){
          // console.error('getDirtyRecordsCount ', angular.toJson(resObject));
          logger.error('getDirtyRecordsCount ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

    function getDirtyRecords() {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('recsToSync', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .filter(function(el){
                return (el.Mobile_Table_Name == "DOF__ap" || el.Mobile_Table_Name == "Mobile_Dynamic__ap") ? true : false;
              })
            .value();
          resolve(records);
        }).catch(function(resObject){
          // console.error('getDirtyRecords ', angular.toJson(resObject));
          logger.error('getDirtyRecords ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

    function getRecordForSoupEntryId(tableName, soupRecordId) {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords(tableName, []).then(function(resObject) {
          var record = _.findWhere(resObject.records, {'_soupEntryId': soupRecordId});
          resolve(record);
        }).catch(function(resObject){
          reject(resObject);
        });
      });
    }

    function getSurgeonInHospital(surgeonId) {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords("Surgeon_in_Hospital__ap", []).then(function(resObject) {
          var record = _.findWhere(resObject.records, {'Surgeon__c': surgeonId});
          resolve(record);
        }).catch(function(resObject){
          reject(resObject);
        });
      });
    }

    function getOrderItems(orderId) {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('DOF_Item__ap', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .filter(function(el){
                return (el.DOF__c == orderId) ? true : false;
              })
            .value();
          resolve(records);
        }).catch(function(resObject){
          // console.error('getOrderItems ', angular.toJson(resObject));
          logger.error('getOrderItems ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

    function getProductsForOrderItems(orderItems) {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('Mobile_Refresh__ap', []).then(function(resObject) {
          var products = _.chain(resObject.records)
            .filter(function(el){
                return (el.RecordType_Name__c == "Product") ? true : false;
              })
            .value();
          var records = [];
          for (var j = 0; j < orderItems.length; j++) {
            for (var k = 0; k < products.length; k++) {
              if (products[k].Id == orderItems[j].Product__c) {
                records.push(products[k]);
                break;
              }
            }
          }
          resolve(records);
        }).catch(function(resObject){
          // console.error('getProductsForOrderItems ', angular.toJson(resObject));
          logger.error('getProductsForOrderItems ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

  }

})();
/**
 * RecentItems Factory
 *
 * @description RecentItems services: e.g. gets/sets/adds to 'recentHospitals' & 'recentSurgeons' local storage
 *
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('RecentItemsService', RecentItemsService);

  function RecentItemsService() {

    return {
      getRecentItems: getRecentItems,
      setRecentItems: setRecentItems,
      addRecentItem: addRecentItem
    };

    function getRecentItems(type) {
      return new Promise(function(resolve, reject) {
        var recentItems = JSON.parse(localStorage.getItem(type));
        if (recentItems === null) {
          resolve([]);
        } else {
          resolve(recentItems);
        }
      });
    }

    function setRecentItems(type,recentItems) {
      return new Promise(function(resolve, reject) {
        localStorage.setItem(type, JSON.stringify(recentItems));
        resolve();
      });
    }

    function addRecentItem(type, recentItem) {
      return new Promise(function(resolve, reject) {
        var recentItems = JSON.parse(localStorage.getItem(type));
        if (recentItems === null) {
          recentItems = [];
        }
        // Make sure item isn't already in the array before adding
        var itemFound = false;
        for (var i = 0; i < recentItems.length; i++) {
          if (recentItem.id && (recentItem.id === recentItems[i].id)) {
            itemFound = true;
          }
        }
        if (!itemFound) {
          recentItems.unshift(recentItem);
        }
        localStorage.setItem(type, JSON.stringify(recentItems));
        resolve(recentItems);
      });
    }

  }

})();
/**
 * Record Type Factory
 *
 * @description Gets the RecordTypeIds from Mobile_Refresh__ap object (for use in Lead Capture and Unsolicted Request)
 *
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('RecordTypeService', RecordTypeService);

  RecordTypeService.$inject = ['devUtils', 'logger'];

  function RecordTypeService(devUtils, logger) {

    return {
      getRecordTypeId: getRecordTypeId,

      readAndSetRecordTypes: readAndSetRecordTypes
    };

    function readAndSetRecordTypes() {
      return new Promise(function(resolve, reject) {
        readRecordTypes().then(function(result) {
          setRecordTypes(result);
          resolve(result);
        }).catch(function(e){
          reject(e);
        });
      });
    }

    function getRecordTypeId(recordTypeName,recordTypeObject) {
      return new Promise(function(resolve, reject) {
        var recordTypes = JSON.parse(localStorage.getItem('recordtypes'));
        if (recordTypes === null) {
          resolve("");
        } else {
          var recordTypeId;
          for (var i = 0; i < recordTypes.length; i++) {
            if (recordTypes[i].name == recordTypeName && recordTypes[i].object == recordTypeObject) {
              recordTypeId = recordTypes[i].id;
            }
          }
          resolve(recordTypeId);
        }
      });
    }

    function setRecordTypes(recordTypes) {
      localStorage.setItem('recordtypes', JSON.stringify(recordTypes));
    }

    function readRecordTypes() {
      return new Promise(function(resolve, reject) {
        getRecordTypes().then(function(records) {
          // Get record types/ids and add them to an array for saving to local storage
          var recordTypes = [];

          for (var i = 0; i < records.length; i++) {
            recordTypes.push({"name": records[i].Name__c, "id": records[i].Record_Type_ID__c, "object": records[i].Object_Reference__c});
          }

          // console.log("bio recordTypes",recordTypes);
          logger.log("recordTypes.length: "+recordTypes.length);

          resolve(recordTypes);
        }).catch(function(e){
          reject(e);
        });
      });
    }

    function getRecordTypes() {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('Mobile_Refresh__ap', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .filter(function(el){
                return (el.RecordType_Name__c == "Record Type Reference") ? true : false;
              })
            .value();
          resolve(records);
        }).catch(function(resObject){
          //console.error('getRecordTypes ', angular.toJson(resObject));
          logger.error('getRecordTypes ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

  }

})();
/**
 * Sync Factory
 *
 * @description Handles Sync calls to the MobileCaddy API amd gets/sets sync state
 *
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('SyncService', SyncService);

  SyncService.$inject = ['$rootScope', 'devUtils'];

  function SyncService($rootScope, devUtils) {

	  return {
	    getSyncLock: getSyncLock,

	    setSyncLock: setSyncLock,

	    getSyncState: getSyncState,

	    setSyncState: setSyncState,

	    syncTables: syncTables,

	    initialSync: initialSync
	  };

	  function initialSync(tablesToSync) {
	    devUtils.initialSync(tablesToSync).then(function(res){
	      setSyncState("complete");
	      $rootScope.$emit('syncTables', {result : "InitialLoadComplete"});
	    });
	  }

	  function syncTables(tablesToSync, syncWithoutLocalUpdates, maxTableAge) {
	  	// Check that we haven't locked out the syncing (e.g. whilst completing order form)
	  	var syncLock = getSyncLock();
	  	var syncState = getSyncState();
	    // logger.log("syncTables: syncLock = " + syncLock + "; syncState = " + syncState);

	    if (syncLock == "true") {
	      return;
	    }
	    // Check that we don't already have a sync in progress.
	    // MobileCaddy Utils will also check for this condition, but we'll check before calling utils
	    if (syncState == "syncing") {
	      return;
	    }
	    setSyncState("syncing");
	    // Check the parameters
	    if (typeof(syncWithoutLocalUpdates) == "undefined") {
	      syncWithoutLocalUpdates = true;
	    }
	    if (typeof(maxTableAge) == "undefined") {
	      maxTableAge = (1000 * 60 * 1); // 3 minutes
	    }
	    // console.log('bio syncTables syncWithoutLocalUpdates, maxTableAge',syncWithoutLocalUpdates,maxTableAge);
	    $rootScope.$emit('syncTables', {result : "StartSync"});

	    var stopSyncing = false;
	    var firstSync = true;
	    var syncCount = 0;
	    var sequence = Promise.resolve();
	    var maxRecsPerCall = 50;

	    tablesToSync.forEach(function(table){
	      sequence = sequence.then(function() {
	        syncCount ++;
	        if (stopSyncing) {
	          return {status: "100999"};  // "100999" is not an official code (used to indicate stopping of sync)
	        } else {
	          return devUtils.syncMobileTable(table, syncWithoutLocalUpdates, maxTableAge, maxRecsPerCall);
	        }
	      }).then(function(resObject) {
	        if (typeof(resObject.status) != "undefined" && resObject.status != "100400") {
	          if (resObject.status != "100999") {
	            // We haven't stopped the sync
	            if (resObject.status == "100497" ||
	                resObject.status == "100498" ||
	                resObject.status == "100402" ||
	                (typeof(resObject.mc_add_status) != "undefined" && resObject.mc_add_status == "sync-too-soon")) {
	              // "100497" => table is too young (synced recently) -> break out of any further syncing attempts
	              // "100498" => sync already in progress
	              // "100402" => error (e.g. offline, timeout)
	              // We stop syncing if the first sync has a problem
	              if (firstSync) {
	                stopSyncing = true;
	                $rootScope.$emit('syncTables', {result : resObject.status});
	                setSyncState("complete");
	              }
	            }
	            // Unable to sync -> set a localnotification
	            // NotificationService.setLocalNotification();
	          }
	        } else {
	        	$rootScope.$emit('syncTables', {result : "TableComplete " + table});
	          // NotificationService.cancelNotifications();
	        }
	        if (syncCount == tablesToSync.length && !stopSyncing) {
	          // All syncs complete
	          $rootScope.$emit('syncTables', {result : "Complete"});
	          setSyncState("complete");
	        }
	        firstSync = false;
	      }).catch(function(res){
	        if (typeof(res.status) != "undefined" &&
	             (res.status == "100497" ||
	              res.status == "100498" ||
	              res.status == "100402")) {
	          $rootScope.$emit('syncTables', {result : "Complete"});
	        } else {
	          console.error(res);
	          $rootScope.$emit('syncTables', {result : "Error " + JSON.stringify(res)});
	        }
	        setSyncState("complete");
	        // NotificationService.setLocalNotification();
	      });
	    });
	  }

	  function getSyncState() {
	    var syncState = localStorage.getItem("syncState");
	    if (syncState === null) {
	      syncState = "complete";
	      localStorage.setItem("syncState", syncState);
	    }
	    return syncState;
	  }

	  function setSyncState(status) {
	    localStorage.setItem("syncState", status);
	  }

	  function getSyncLock() {
	    var syncLock = localStorage.getItem("syncLock");
	    if (syncLock === null) {
	      syncLock = "false";
	      localStorage.setItem("syncLock", syncLock);
	    }
	    return syncLock;
	  }

	  function setSyncLock(status) {
	    localStorage.setItem("syncLock", status);
	  }

  }

})();
/**
 * User Factory
 *
 * @description User services: sets/gets current user id; sets/gets 'processes' local storage
 * sync status.
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('UserService', UserService);

  UserService.$inject = ['devUtils', 'logger'];

  function UserService(devUtils, logger) {

    return {
      getCurrentUserId: getCurrentUserId,
      setCurrentUserId: setCurrentUserId,
      hasDoneProcess: hasDoneProcess,
      setProcessDone: setProcessDone,
      getUserFirstName: getUserFirstName,
      setUserFirstName: setUserFirstName,
      getUserDefaultCurrency: getUserDefaultCurrency,
      setUserDefaultCurrency: setUserDefaultCurrency,
      getUserCurrencySymbol: getUserCurrencySymbol
    };

    function getCurrentUserId() {
      return new Promise(function(resolve, reject) {
        var currentUserId = localStorage.getItem('currentUserId');
        if (currentUserId !== null) {
          resolve(currentUserId);
        } else {
          devUtils.getCurrentUserId().then(function(userId){
            localStorage.setItem('currentUserId', userId);
            resolve(userId);
          }).catch(function(resObject){
            logger.log('getCurrentUserId',resObject);
            reject(resObject);
          });
        }
      });
    }

    function setCurrentUserId(userId) {
      return new Promise(function(resolve, reject) {
        localStorage.setItem('currentUserId', userId);
        resolve(true);
      });
    }

    function hasDoneProcess(processName) {
      return new Promise(function(resolve, reject) {
        var processes = JSON.parse(localStorage.getItem('processes'));
        if (processes === null) {
          resolve(false);
        } else {
          if (processes[processName] == "true") {
            resolve(true);
          } else {
            resolve(false);
          }
        }
      });
    }

    function setProcessDone(processName) {
      return new Promise(function(resolve, reject) {
        var processes = JSON.parse(localStorage.getItem('processes'));
        if (processes === null) {
          processes = {};
        }
        processes[processName] = "true";
        localStorage.setItem('processes', JSON.stringify(processes));
        resolve(true);
      });
    }

    function getUserFirstName() {
      return new Promise(function(resolve, reject) {
        var currentUserFirstName = localStorage.getItem('currentUserFirstName');
        if (currentUserFirstName !== null) {
          resolve(currentUserFirstName);
        } else {
          setUserFirstName().then(function(result) {
            resolve(result);
          });
        }
      });
    }

    function setUserFirstName() {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('appSoup', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .filter(function(el){
                return (el.Name == "userFirstName") ? true : false;
              })
            .value();
          var userFirstName;
          if (records.length > 0) {
            userFirstName = records[0].CurrentValue;
          } else {
            userFirstName = "";
          }
          localStorage.setItem('currentUserFirstName', userFirstName);
          resolve(userFirstName);
        }).catch(function(resObject){
          //console.error('setUserFirstName ', angular.toJson(resObject));
          logger.error('setUserFirstName ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

    function getUserDefaultCurrency() {
      return new Promise(function(resolve, reject) {
        var userDefaultCurrency = localStorage.getItem('userDefaultCurrency');
        if (userDefaultCurrency !== null) {
          resolve(userDefaultCurrency);
        } else {
          setUserDefaultCurrency().then(function(result) {
            resolve(result);
          });
        }
      });
    }

    function setUserDefaultCurrency() {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('appSoup', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .filter(function(el){
                return (el.Name == "userDefaultCurrency") ? true : false;
              })
            .value();
          var userDefaultCurrency;
          if (records.length > 0) {
            userDefaultCurrency = records[0].CurrentValue;
          } else {
            userDefaultCurrency = "";
          }
          localStorage.setItem('userDefaultCurrency', userDefaultCurrency);
          resolve(userDefaultCurrency);
        }).catch(function(resObject){
          //console.error('setUserDefaultCurrency ', angular.toJson(resObject));
          logger.error('setUserDefaultCurrency ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }

    function getUserCurrencySymbol() {
      return new Promise(function(resolve, reject) {
        getUserDefaultCurrency().then(function(result) {
          var symbol;
          switch (result) {
            case "GBP" :
              symbol = "£";
              break;
            case "USD" :
              symbol = "$";
              break;
            case "CAD" :
              symbol = "$";
              break;
            default :
              symbol = "$";
          }
          resolve(symbol);
        });
      });
    }


  }

})();