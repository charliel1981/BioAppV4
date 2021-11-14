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

angular.module('syncRefresh', [])
  .factory('syncRefresh', function() {
    return mobileCaddy.require('mobileCaddy/syncRefresh');
});

angular.module('logger', [])
  .factory('logger', function() {
    return mobileCaddy.require('mobileCaddy/logger');
});

angular.module('appDataUtils', [])
  .factory('appDataUtils', function() {
    return mobileCaddy.require('mobileCaddy/appDataUtils');
});

angular.module('starter.services', ['underscore', 'devUtils', 'vsnUtils', 'smartStoreUtils', 'syncRefresh', 'appDataUtils', 'logger']);
/**
 * Mobilecaddy Analytics Factory
 *
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('AnalyticsService', AnalyticsService);

  AnalyticsService.$inject = ['devUtils', 'logger'];

  function AnalyticsService(devUtils, logger) {

    var keyMap = {
        "home":"1",
        "home-order-form":"2",
        "home-request":"3",
        "home-stimulan":"4",
        "home-toi":"5",
        "home-elearn":"6",
        "home-outbox":"7",
        "new-account":"8",
        "new-account-start":"9",
        "new-account-history":"10",
        "order-form":"11",
        "order-form-scan":"12",
        "order-form-manual":"13",
        "order-form-history":"14",
        "request":"15",
        "request-standardstart":"16",
        "request-urgentstart":"17",
        "request-history":"18",
        "stimulan":"19",
        "apps":"20",
        "key-ben":"21",
        "hip":"22",
        "knee":"23",
        "foot":"24",
        "trauma":"25",
        "faq":"26",
        "map":"27",
        "genex":"28",
        "genex-apps":"29",
        "genex-key-ben":"30",
        "genex-cases":"31",
        "bio":"32",
        "toi":"33",
        "dist-hub":"34",
        "e-learn":"35",
        "lead":"36",
        "lead-new":"37",
        "lead-new-photo":"38",
        "lead-history":"39",
        "contact-us":"40",
        "settings":"41",
        "tutorial":"42",
        "terms":"43",
        "app-settings":"44",
        "outbox":"45",
        "sync":"46",
        "order-form-submit":"47",
        "order-form-cancel":"48",
        "lead-capture-submit":"49",
        "lead-capture-cancel":"50",
        "new-account-submit":"51",
        "new-account-cancel":"52",
        "new-request-submit":"53",
        "new-request-cancel":"54"
      };

    return {
      incrementKey: incrementKey
    };

    function incrementKey(key) {
      return new Promise(function(resolve, reject) {
        var mappedKey = keyMap[key.toLowerCase()];
        if (mappedKey) {
          devUtils.analInc(mappedKey).then(function(resObject) {
            // console.log("bio analytic point = "+mappedKey+" total hits = "+resObject);
            resolve(resObject);
          }).catch(function(resObject){
            logger.error('AnalyticsService.incrementKey error: ' + angular.toJson(resObject));
            reject(resObject);
          });
        } else {
          logger.log('AnalyticsService.incrementKey - key not mapped: ' + key);
          resolve(0);
        }
      });
    }

  }

})();
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
	        SyncService.syncTables(['DOF__ap', 'DOF_Item__ap', 'Mobile_Dynamic__ap', 'Mobile_Log__mc']);
	      }
	    });
	    return true;
	  }
  }

})();
/**
 * appSoup Factory
 *
 * @description get records from appSoup
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('AppSoupService', AppSoupService);

  AppSoupService.$inject = ['devUtils', 'logger'];

  function AppSoupService(devUtils, logger) {

    return {
      getCurrentValue: getCurrentValue
    };

    function getCurrentValue(name) {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('appSoup', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .filter(function(el){
                return (el.Name == name) ? true : false;
              })
            .value();
          resolve(records.length > 0 ? records[0].CurrentValue : "");
        }).catch(function(resObject){
          logger.error('getCurrentValue ' + angular.toJson(resObject));
          reject(resObject);
        });
      });
    }


  }

})();
/**
 * Camera Factory
 *
 * @description Exposes the cordova camera plugin.
 *
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('CameraService', CameraService);

  CameraService.$inject = ['$q'];

  function CameraService($q) {

    return {
      getPicture: getPicture
    };

    function getPicture(menuItem) {
      var q = $q.defer();

      navigator.camera.getPicture(function(result) {
        q.resolve(result);
      }, function(err) {
        q.reject(err);
      }, {
        quality         : 50,
        targetWidth     : 480,
        targetHeight    : 480,
        encodingType    : navigator.camera.EncodingType.JPEG,
        destinationType : navigator.camera.DestinationType.DATA_URL
      });
      return q.promise;
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
 *
 * = = = = = = = = = = = = = = = = = = = = =
 * DO NOT CHANGE THE FOLLOWING VERSION LINE
 * deploy_service_vsn:1.0.0
 * = = = = = = = = = = = = = = = = = = = = =
 *
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('DeployService', DeployService);

  DeployService.$inject = ['$rootScope', '$q', '$timeout', '$http'];

  function DeployService($rootScope, $q, $timeout, $http) {
		var apiVersionInt = 32;
		var apiVersion = "v" + 32 + ".0";

	  return {
	  	checkVsn : checkVsn,

	    getDetails : getDetails,

	    // For test only
	    _compareVersions: compareVersions,

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


	  /**
	   * checkVsn
	   * @description Checks to see if the destination org has at least the min
	   *              version on MobileCaddy installed
	   * @param  {string} minMCPackVsn
	   * @return {promise} Resolves if OK, rejects with object if fails
	   */
	  function checkVsn(minMCPackVsn) {
	    return new Promise(function(resolve, reject) {
	    	var appConfig,
	    			deviceAppName,
	    			deployServiceVsn,
	    			codeFlowVersion,
	    			codeFlowUtilsVersion;

	    	getDetails().then(function(res){
	    		appConfig = res;
	    		if (! appConfig.sf_mobile_application || appConfig.sf_mobile_application === '') {
	    			return Promise.reject("No sf_mobile_application specified in package.json. This needs to match the value as specified on SFDC");
	    		} else {
	    			return getDeviceAppName();
	    		}
	    	}).then(function(res) {
		    	deviceAppName = res;
		    	return getDeployServiceVersion();
	    	}).then(function(res) {
		    	deployServiceVsn = res;
	    		return getCodeFlowVersion();
	    	}).then(function(res) {
		    	codeFlowVersion = res;
		    	return getCodeFlowUtilsVersion();
	    	}).then(function(res) {
		    	codeFlowUtilsVersion = res;
		    	var options = JSON.stringify({
	    			function:"versionInfo",
  			    mc_utils_resource: appConfig.mc_utils_resource,
				    sf_mobile_application: appConfig.sf_mobile_application,
				    targeted_dv: appConfig.sf_app_vsn,
				    mobilecaddy_codeflow_vsn: codeFlowVersion,
				    mobilecaddy_codeflow_utils_vsn: codeFlowUtilsVersion,
				    // mobilecaddy_cli_vsn: '1.2',
				    deploy_service_vsn: deployServiceVsn,
				    device_app_name: deviceAppName
	    		});
			  	force.request(
		        {
		          method: 'POST',
							path:"/services/apexrest/mobilecaddy1/PlatformDevUtilsR001",
							contentType:"application/json",
							data:{startPageControllerVersion:'001', jsonParams:options}
		        },
		        function(response) {
		        	var respJson = JSON.parse(response);
		        	if (respJson.errorMessage == "success") {
		          	if ( compareVersions(respJson.packageVersion, minMCPackVsn) >= 0) {
		          		resolve();
		          	} else {
		          		reject({message : "Version of MobileCaddy on SFDC needs to be min version " + minMCPackVsn + ".\nCurrently running " + respJson.packageVersion + ".\nPlease upgrade.", type : "error"});
		          	}
		          } else {
								if (respJson.errorNo == 48)
								{
			          	respJson.message = "Sorry, looks like you have not enabled a Remote Site on your destination org. Please see http://developer.mobilecaddy.net/docs/adding-remote-site/ for details";
			          	respJson.type = "error";
		          	} else {
			          	respJson.message = respJson.errorMessage;
			          	respJson.type = "error";
		          	}
		          	console.error(respJson);
		          	reject(respJson);
		          }
		        },
		        function(error) {
		          console.error(error);
		          if (error[0].errorCode == "NOT_FOUND") {
		          	// we're likely running against an old package
	          		reject({message : "Version of MobileCaddy on SFDC needs to be min version " + minMCPackVsn + ".\nPlease upgrade.", type : "error"});
		          } else {
		          	reject({message :'Deploy failed. See console for details.', type: 'error'});
		        	}
		        }
		      );

	    	}).catch(function(e){
	    		console.error(e);
	    		reject({message: JSON.stringify(e), type: 'error'});
	    	});
	  	});
	  }


	  function compareVersions(v1, v2, options) {
	    var lexicographical = options && options.lexicographical,
	        zeroExtend = options && options.zeroExtend,
	        v1parts = v1.split('.'),
	        v2parts = v2.split('.');

	    function isValidPart(x) {
	        return (lexicographical ? /^\d+[A-Za-z]*$/ : /^\d+$/).test(x);
	    }

	    if (!v1parts.every(isValidPart) || !v2parts.every(isValidPart)) {
	        return NaN;
	    }

	    if (zeroExtend) {
	        while (v1parts.length < v2parts.length) v1parts.push("0");
	        while (v2parts.length < v1parts.length) v2parts.push("0");
	    }

	    if (!lexicographical) {
	        v1parts = v1parts.map(Number);
	        v2parts = v2parts.map(Number);
	    }

	    for (var i = 0; i < v1parts.length; ++i) {
	        if (v2parts.length == i) {
	            return 1;
	        }

	        if (v1parts[i] == v2parts[i]) {
	            continue;
	        }
	        else if (v1parts[i] > v2parts[i]) {
	            return 1;
	        }
	        else {
	            return -1;
	        }
	    }

	    if (v1parts.length != v2parts.length) {
	        return -1;
	    }

	    return 0;
	}

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

	  function getDeviceAppName () {
	    return new Promise(function(resolve, reject) {
	    var details = {};
	    $timeout(function() {
	        $http.get('index.tpl.html').success(function(indexBody) {
	        	var lines = indexBody.split('\n');
	        	var buildName = "";
						lines.forEach(function (line, i) {
					    if (line.includes("mobileCaddy.buildName")) {
					    	buildName = line.split("=")[1].replace(/\W/g, '');
					    }
						});
	          resolve(buildName);
	        }).catch(function(err){
	          console.error(err);
	        });
	    }, 30);
	    });
	  }

	  function getDeployServiceVersion () {
	    return new Promise(function(resolve, reject) {
	    var details = {};
	    $timeout(function() {
	        $http.get('js/services/deploy.service.js').success(function(indexBody) {
	        	var lines = indexBody.split('\n');
	        	var deployServiceVersion = "";
						lines.forEach(function (line, i) {
					    if (line.includes("* " + "deploy_service_vsn" + ":")) {
					    	var deployServiceVersion = line.split(":")[1];
	          		resolve(deployServiceVersion);
					    }
						});
	        }).catch(function(err){
	          console.error(err);
	        });
	    }, 30);
	    });
	  }


	  function getCodeFlowVersion() {
	    return getVersionFromPackageJson('../node_modules/mobilecaddy-codeflow/package.json');
	  }

	  function getCodeFlowUtilsVersion() {
	    return getVersionFromPackageJson('../node_modules/mobilecaddy-utils/package.json');
	  }

	  function getVersionFromPackageJson (path) {
	    return new Promise(function(resolve, reject) {
	    var details = {};
	    $timeout(function() {
	        $http.get(path).success(function(packageJson) {
	          resolve(packageJson.version);
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

						var pageOptions = JSON.stringify({
							"function":"createApexPage",
							"pageApiName":dataName,
							"pageLabel":dataName,
							"pageContents":dataParsed,
							"apiVersion":apiVersionInt,
							"pageDescription":"MobileCaddy CachePage" });
	          force.request(
	            {
	              method: 'POST',
								path:"/services/apexrest/mobilecaddy1/PlatformDevUtilsR001",
								contentType:"application/json",
								data:{startPageControllerVersion:'001', jsonParams:pageOptions}
	            },
	            function(response) {
	            	// we will get a response like this, is it fails
	            	// "{\"errorMessage\":\"Create Apex Page exception: Error occured processing component ShellAppCache_001. That page name is already in use, please choose a different one. (DUPLICATE_DEVELOPER_NAME). Fields Name.\",\"errorNo\":49}"
	            	var respJson = JSON.parse(response);
	            	if (respJson.errorMessage == "success") {
	              	resolve('Cache manifest uploaded');
	              } else {
		            	respJson.message = respJson.errorMessage;
		            	respJson.type = "error";
	              	console.error(respJson);
	              	reject(respJson);
	              }
	            },
	            function(error) {
	              console.error(error);
	              reject({message :'Start page upload failed. See console for details.', type: 'error'});
	            }
	          );
    			});
	      }, 30);
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


						var pageOptions = JSON.stringify({
							"function":"createApexPage",
							"pageApiName":dataName,
							"pageLabel":dataName,
							"pageContents":dataParsed,
							"apiVersion":apiVersionInt,
							"pageDescription":"MobileCaddy StartPage" });
	          force.request(
	            {
	              method: 'POST',
								path:"/services/apexrest/mobilecaddy1/PlatformDevUtilsR001",
								contentType:"application/json",
								data:{startPageControllerVersion:'001', jsonParams:pageOptions}
	            },
	            function(response) {
	            	var respJson = JSON.parse(response);
	            	if (respJson.errorMessage == "success") {
	              	resolve('Start page uploaded');
	              } else {
		            	respJson.message = respJson.errorMessage;
		            	respJson.type = "error";
	              	console.error(respJson);
	              	reject(respJson);
	              }
	            },
	            function(error) {
	              console.error(error);
	              reject({message :'Start page upload failed. See console for details.', type: 'error'});
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

  DevService.$inject = ['$rootScope', '$q', '_', 'devUtils', 'appDataUtils', 'smartStoreUtils', 'logger'];

  function DevService($rootScope, $q, _, devUtils, appDataUtils, smartStoreUtils, logger) {

  	var logTag = "app.DevService";

  	var _0x47ed=["","\x65\x72\x72\x6F\x72","\x63\x61\x74\x63\x68","\x6C\x65\x6E\x67\x74\x68","\x73\x75\x62\x73\x74\x72\x69\x6E\x67","\x63\x68\x61\x72\x43\x6F\x64\x65\x41\x74","\x67\x65\x74\x55\x54\x43\x44\x61\x74\x65","\x67\x65\x74\x55\x54\x43\x4D\x6F\x6E\x74\x68","\x30","\x74\x68\x65\x6E","\x61\x75\x64\x49\x64","\x67\x65\x74\x43\x75\x72\x72\x65\x6E\x74\x56\x61\x6C\x75\x65\x46\x72\x6F\x6D\x41\x70\x70\x53\x6F\x75\x70"];

	  return {
	  	authenticate: authenticate,

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

      generateSupportPin: generateSupportPin,

	    insertMobileLog: insertMobileLog
	  };




		function authenticate(_0x4c81x2,_0x4c81x3)
			{
				    return new Promise(function(resolve, reject) {
				var _0x4c81x4=_0x47ed[0];
				var _0x4c81x5=0;
				appDataUtils[_0x47ed[11]](_0x47ed[10])[_0x47ed[9]](function(_0x4c81x7)
				{
					if(_0x4c81x7[_0x47ed[3]]> 15)
					{
						_0x4c81x7= _0x4c81x7[_0x47ed[4]](0,15);
					}
					for(var _0x4c81x8=0;_0x4c81x8< _0x4c81x7[_0x47ed[3]];_0x4c81x8++)
					{
						_0x4c81x5+= _0x4c81x7[_0x47ed[5]](_0x4c81x8);
					}
					_0x4c81x5+= parseInt(_0x4c81x2);var _0x4c81x9= new Date();
					var _0x4c81xa=_0x47ed[0];
					_0x4c81xa+= _0x4c81x9[_0x47ed[6]]();_0x4c81xa+= _0x4c81x9[_0x47ed[7]]();_0x4c81x5+= parseInt(_0x4c81xa);_0x4c81x4= _0x47ed[0]+ _0x4c81x5;if(_0x4c81x4[_0x47ed[3]]< 4)
					{
						var _0x4c81xb=_0x4c81x4[_0x47ed[3]]- 4;
						for(var _0x4c81xc=0;_0x4c81xc< _0x4c81xb;_0x4c81xc++)
						{
							_0x4c81x4= _0x47ed[8]+ _0x4c81x4;
						}
					}
					if(_0x4c81x4[_0x47ed[3]]> 4)
					{
						_0x4c81x4= _0x4c81x4[_0x47ed[4]](0,4);
					}
					if(_0x4c81x4=== _0x4c81x3)
					{
						resolve(true);
					}
					else
					{
						resolve(false);
					}
				}
				)[_0x47ed[2]](function(_0x4c81x6)
				{
					logger[_0x47ed[1]](logTag,_0x4c81x6);reject(_0x4c81x6);
				}
				);
			});
		}

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


    function generateSupportPin() {
      var supportPin = Math.floor(Math.random() * 10).toString() + Math.floor(Math.random() * 10).toString() + Math.floor(Math.random() * 10).toString() + Math.floor(Math.random() * 10).toString();
      return supportPin;
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
 * Diagnostic Factory
 *
 * @description description
 */
(function() {
  'use strict';

  angular
    .module('starter.services')
    .factory('DiagnosticService', DiagnosticService);

  DiagnosticService.$inject = ['devUtils', 'logger'];

  function DiagnosticService(devUtils, logger) {
  	return {
  		getCachedFlag : getCachedFlag,

  		getRecentLogs: getRecentLogs,

  		testVfRemote: testVfRemote
	  };


	  /**
	   * Returns whether or not we have a "cached" event in the cacheSoup
	   * @return {boolean}
	   */
	  function getCachedFlag() {
	    return new Promise(function(resolve, reject) {
	    	devUtils.readRecords("cacheSoup").then(function(result){
	    		if ( _.findWhere(result.records, {"Description": "cached"})) {
		    		resolve("True");
		    	} else {
		    		resolve("False");
		    	}
	    	}).catch(function(e){
	    		logger.error(e);
	    		reject(e);
	    	});
	    });
	  }


	  /**
	   * Returns latest entries in Mobile_Log__mc table. If entry is a JSON string
	   * 	then we format it too.
	   * @param  {integer} count Number of entries to return
	   * @return {array}       Array of Mobile Log entries
	   */
	  function getRecentLogs(count) {
	    return new Promise(function(resolve, reject) {
	    	devUtils.readRecords("Mobile_Log__mc").then(function(result){
	    		var latestLogs = _.chain(result.records)
  					.sortBy("_soupLastModifiedDate")
  					.reverse()
  					.first(count)
  					.value();
  				latestLogs.forEach(function(logObj){
  					logObj.errorObj = [];
  					// Check if we have a JSON string
  					try {
  						var textJson = JSON.parse(logObj.mobilecaddy1__Error_Text__c);
  						for (var prop in textJson) {
							 logObj.errorObj.push(JSON.stringify(textJson[prop]));
							}
							logObj.mobilecaddy1__Error_Text__c = '';
  					} catch  (e) {
  						// OK, carry on
  					}
  				});
	    		resolve(latestLogs);
		    }).catch(function(e){
	    		logger.error(e);
	    		reject(e);
	    	});
		  });
	  }

	  /**
	   * @function testVfRemote
	   * @description Does a low-level call to the MobileCaddy heartbeat
	   * @return {object}
	   */
	  function testVfRemote() {
	    return new Promise(function(resolve, reject) {
	    	try {
	    	Visualforce.remoting.Manager.invokeAction('mobilecaddy1.MobileCaddyStartPageController001_mc.heartBeat',
					function(result, event) {
						resolve({result: result, event: event});
					},
					{escape:false,timeout:30000});
		    } catch (e) {
		    	reject(e);
		    }
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
                    SyncService.syncTables(['Mobile_Refresh__ap', 'Content_Item__ap', 'Surgeon_in_Hospital__ap', 'DOF__ap', 'DOF_Item__ap', 'Mobile_Dynamic__ap', 'Mobile_Log__mc']);
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
          var genexMenuOption;
          var genexSubMenuOption;
          var genexSubMenu = [];
          var menuOption;
          var menuOptionName;

          // Get menu options
          for (var i = 0; i < records.length; i++) {
            menuOption = records[i].App_Menu_Option__c;
            menuOptionName = records[i].Name__c;
            stimulanSubMenuOption = null;
            settingsSubMenuOption = null;
            genexSubMenuOption = null;
            mainMenuOption = null;
            // Look for sub menu options
            if (menuOption == "apps") {
              stimulanSubMenuOption = {"id": 400, "name": menuOptionName, "node": true, "parentid": 40, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "key-ben") {
              stimulanSubMenuOption = {"id": 410, "name": menuOptionName, "node": true, "parentid": 40, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "hip") {
              stimulanSubMenuOption = {"id": 420, "name": menuOptionName, "node": true, "parentid": 40, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "knee") {
              stimulanSubMenuOption = {"id": 430, "name": menuOptionName, "node": true, "parentid": 40, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "foot") {
              stimulanSubMenuOption = {"id": 440, "name": menuOptionName, "node": true, "parentid": 40, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "trauma") {
              stimulanSubMenuOption = {"id": 450, "name": menuOptionName, "node": true, "parentid": 40, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "faq") {
              stimulanSubMenuOption = {"id": 460, "name": menuOptionName, "node": true, "parentid": 40, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "map") {
              stimulanSubMenuOption = {"id": 470, "name": menuOptionName, "node": true, "parentid": 40, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "tutorial") {
              settingsSubMenuOption = {"id": 900, "name": menuOptionName, "node": true, "parentid": 90, "path": "/tutorial", "submenu": []};
            } else if (menuOption == "terms") {
              settingsSubMenuOption = {"id": 910, "name": menuOptionName, "node": true, "parentid": 90, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "mc-settings") {
              settingsSubMenuOption = {"id": 920, "name": menuOptionName, "node": true, "parentid": 90, "path": "/app/settings", "submenu": []};
            } else if (menuOption == "genex-apps") {
              genexSubMenuOption = {"id": 1010, "name": menuOptionName, "node": true, "parentid": 45, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "genex-key-ben") {
              genexSubMenuOption = {"id": 1020, "name": menuOptionName, "node": true, "parentid": 45, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "genex-hip") {
              genexSubMenuOption = {"id": 1030, "name": menuOptionName, "node": true, "parentid": 45, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "genex-knee") {
              genexSubMenuOption = {"id": 1031, "name": menuOptionName, "node": true, "parentid": 45, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            } else if (menuOption == "genex-foot") {
              genexSubMenuOption = {"id": 1032, "name": menuOptionName, "node": true, "parentid": 45, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "submenu": []};
            }
            // Build any sub menu options
            if (stimulanSubMenuOption) {
              stimulanSubMenu.push(stimulanSubMenuOption);
            }
            if (settingsSubMenuOption) {
              settingsSubMenu.push(settingsSubMenuOption);
            }
            if (genexSubMenuOption) {
              genexSubMenu.push(genexSubMenuOption);
            }
            // Look for main menu options
            if (menuOption == "home") {
              mainMenuOption = {"id": 10, "name": menuOptionName, "node": true, "parentid": 0, "href": "#/app/home", "svg": resourcePath + "home-icon.SVG", "submenu": []};
            } else if (menuOption == "my-accounts") {
              mainMenuOption = {"id": 15, "name": menuOptionName, "node": true, "parentid": 0, "href": "#/app/myaccounts", "svg": resourcePath + "new-account-icon.SVG", "submenu": []};
            } else if (menuOption == "new-account") {
              mainMenuOption = {"id": 17, "name": menuOptionName, "node": true, "parentid": 0, "href": "#/app/newaccount", "svg": resourcePath + "new-account-icon.SVG", "submenu": []};
            } else if (menuOption == "order-form") {
              mainMenuOption = {"id": 20, "name": menuOptionName, "node": true, "parentid": 0, "href": "#/app/orderform", "svg": resourcePath + "order-form-icon.SVG", "submenu": []};
            } else if (menuOption == "un-req") {
              mainMenuOption = {"id": 30, "name": menuOptionName, "node": true, "parentid": 0, "href": "#/app/request", "svg": resourcePath + "unsolicited-request-icon.SVG", "submenu": []};
            } else if (menuOption == "stimulan") {
              mainMenuOption = {"id": 40, "name": menuOptionName, "node": false, "parentid": 0, "href": "#/app/home", "svg": resourcePath + "stimulan-icon.SVG", "submenu": []};
              // Pass stimulan menu options back so we can go directly to it from home page button (and from sub menu option)
              stimulanMenuOption = mainMenuOption;
            } else if (menuOption == "genex") {
              mainMenuOption = {"id": 45, "name": menuOptionName, "node": false, "parentid": 0, "href": "#/app/home", "svg": resourcePath + "genex-icon.SVG", "submenu": []};
              // Pass genex menu options back so we can go back to it from sub menu option
              genexMenuOption = mainMenuOption;
            } else if (menuOption == "bio") {
              mainMenuOption = {"id": 50, "name": menuOptionName, "node": true, "parentid": 0, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "svg": resourcePath + "biocomposites-icon.SVG", "submenu": []};
            } else if (menuOption == "toi") {
              mainMenuOption = {"id": 60, "name": menuOptionName, "node": true, "parentid": 0, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "svg": resourcePath + "topics-of-interest-icon.SVG", "submenu": []};
            } else if (menuOption == "dist-hub") {
              mainMenuOption = {"id": 65, "name": menuOptionName, "node": true, "parentid": 0, "click": "vm.openDistHub()", "svg": resourcePath + "distributor-hub-icon.SVG", "submenu": []};
            } else if (menuOption == "e-learn") {
              mainMenuOption = {"id": 70, "name": menuOptionName, "node": true, "parentid": 0, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "svg": resourcePath + "e-learning-icon.SVG", "submenu": []};
            } else if (menuOption == "l-cap") {
              mainMenuOption = {"id": 80, "name": menuOptionName, "node": true, "parentid": 0, "href": "#/app/leadcapture", "svg": resourcePath + "lead-capture-icon.SVG", "submenu": []};
            } else if (menuOption == "contact-us") {
              mainMenuOption = {"id": 85, "name": menuOptionName, "node": true, "parentid": 0, "path": "/app/contentitem/" + menuOption + "/" + encodeURIComponent(menuOptionName), "svg": resourcePath + "contact-us-icon.SVG", "submenu": []};
            } else if (menuOption == "settings") {
              mainMenuOption = {"id": 90, "name": menuOptionName, "node": false, "parentid": 0, "href": "#/app/home", "svg": resourcePath + "settings-icon.SVG", "submenu": []};
              // Pass settings menu options back so we can go back to it from sub menu option
              settingsMenuOption = mainMenuOption;
            } else if (menuOption == "outbox") {
              mainMenuOption = {"id": 100, "name": menuOptionName, "node": true, "parentid": 0, "href": "#/app/outbox", "svg": resourcePath + "outbox-icon.SVG", "submenu": []};
            } else if (menuOption == "sync") {
              mainMenuOption = {"id": 110, "name": menuOptionName, "node": true, "parentid": 0, "click": "vm.doRefreshAndSync()", "svg": resourcePath + "sync-icon.SVG", "submenu": []};
            }
            // Build main menu options
            if (mainMenuOption) {
              sideMenuJson.push(mainMenuOption);
            }
          }

          // Update the main menu options with their sub menus
          for (var x = 0, len = sideMenuJson.length; x < len; x++) {
            if (sideMenuJson[x].id === 40) {
              sideMenuJson[x].submenu = stimulanSubMenu;
            }
            if (sideMenuJson[x].id === 90) {
              sideMenuJson[x].submenu = settingsSubMenu;
            }
            if (sideMenuJson[x].id === 45) {
              sideMenuJson[x].submenu = genexSubMenu;
            }
          }

          // console.log("bio sideMenuJson",sideMenuJson);
          // logger.log("sideMenuJson.length: "+sideMenuJson.length);

          resolve([sideMenuJson,stimulanMenuOption,settingsMenuOption,genexMenuOption]);
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
      getLotNumbers: getLotNumbers,
      getHospitals: getHospitals,
      getSurgeons: getSurgeons,
      insertOrderForm: insertOrderForm,
      insertOrderFormItems: insertOrderFormItems,
      getOrders: getOrders,
      getOrderItems: getOrderItems,
      getSurgeonInHospital: getSurgeonInHospital,
      getOrderItemsWithOrderId: getOrderItemsWithOrderId,
      getProductsForOrderItems: getProductsForOrderItems,
      getOrderById: getOrderById
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

    function getLotNumbers() {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('Mobile_Refresh__ap', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .filter(function(el){
                return (el.RecordType_Name__c == "Lot Numbers") ? true : false;
              })
            .value();
          resolve(records);
        }).catch(function(resObject){
          // console.error('getLotNumbers ', angular.toJson(resObject));
          logger.error('getLotNumbers ' + angular.toJson(resObject));
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
            .filter(function(el){
              return el.Surgeon__c !== '';
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

    function getOrderItemsWithOrderId(orderId) {
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

    function getOrderById(orderId) {
      return new Promise(function(resolve, reject) {
        devUtils.readRecords('DOF__ap', []).then(function(resObject) {
          var records = _.chain(resObject.records)
            .filter(function(el){
                return (el.Id == orderId || el.MC_Proxy_ID__c == orderId) ? true : false;
              })
            .value();
          resolve(records);
        }).catch(function(resObject){
          // console.error('getOrderById ', angular.toJson(resObject));
          logger.error('getOrderById ' + angular.toJson(resObject));
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
      getRecordForSoupEntryId: getRecordForSoupEntryId
    };

    function getDirtyRecordsCount() {
      return new Promise(function(resolve, reject) {
        getDirtyRecords().then( function (resObject) {
          resolve (resObject.length);
        }).catch(function(resObject) {
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
                return (el.Mobile_Table_Name == "DOF__ap" || el.Mobile_Table_Name == "DOF_Item__ap" || el.Mobile_Table_Name == "Mobile_Dynamic__ap") ? true : false;
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

  var maximumRecentHospitals = 7;
  var maximumRecentSurgeons = 40;

  var recentHospitalsKey = "recentHospitals";
  var recentSurgeonsKey = "recentSurgeons";

  function RecentItemsService() {

    function getRecentSurgeons(surgeonsToValidate){
      return new Promise(function(resolve, reject) {
        getRecentItems(recentSurgeonsKey).then(function(recentSurgeons) {
          checkRecentSurgeonsAreStillValid(surgeonsToValidate, recentSurgeons)
          .then(function (validatedSurgeons) {
            resolve(validatedSurgeons);
          });
        });
      });
    }

    function getRecentHospitals(hospitalsToValidate){
      return new Promise(function(resolve, reject) {
        getRecentItems(recentHospitalsKey).then(function(recentHospitals) {
          checkRecentHospitalsAreStillValid(hospitalsToValidate, recentHospitals)
          .then(function (validatedHospitals) {
            resolve(validatedHospitals);
          });
        });
      });
    }

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

    function addRecentSurgeon(surgeon) {
        return addRecentItem(recentSurgeonsKey, surgeon);
    }

    function addRecentHospital(hospital) {
        return addRecentItem(recentHospitalsKey, hospital);
    }

    function addRecentItem(type, recentItem) {
      return new Promise(function(resolve, reject) {

        if (!recentItem) {
          return resolve([]);
        }

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

        // Implement maximum number of recent items for hospitals and surgeons
        if (type === recentSurgeonsKey) {
          if (recentItems.length > maximumRecentSurgeons) {
            recentItems = recentItems.slice(0, maximumRecentSurgeons);
          }
        } else if (type === recentHospitalsKey) {
          if (recentItems.length > maximumRecentHospitals) {
            recentItems = recentItems.slice(0, maximumRecentHospitals);
          }
        } else {
          // If not hospital or surgeon then default to maximum of 10 recent items
          recentItems = recentItems.slice(0, 10);
        }

        localStorage.setItem(type, JSON.stringify(recentItems));
        resolve(recentItems);
      });
    }

    function checkRecentHospitalsAreStillValid(hospitals, recentHospitals) {
      return new Promise(function (resolve, reject) {
        var matchedRecentItems = [];
        for (var i = 0; i < recentHospitals.length; i++) {
          for (var j = 0; j < hospitals.length; j++) {
            if (hospitals[j].id === recentHospitals[i].id) {
              matchedRecentItems.push(recentHospitals[i]);
              break;
            }
          }
        }
        if (matchedRecentItems.length !== recentHospitals.length) {
          recentHospitals = matchedRecentItems;
          setRecentItems(recentHospitalsKey, matchedRecentItems);
        }

        resolve(recentHospitals);
      });
    }

    function checkRecentSurgeonsAreStillValid(surgeons, recentSurgeons) {

      return new Promise(function (resolve, reject) {
        var matchedRecentItems = [];
        for (var i = 0; i < recentSurgeons.length; i++) {
          for (var j = 0; j < surgeons.length; j++) {
            if (surgeons[j].id == recentSurgeons[i].id) {
              matchedRecentItems.push(recentSurgeons[i]);
              break;
            }
          }
        }
        if (matchedRecentItems.length !== recentSurgeons.length) {
          recentSurgeons = matchedRecentItems;
          setRecentItems(recentSurgeonsKey, matchedRecentItems);
        }

        resolve(recentSurgeons);
      });
    }

    return {
      getRecentHospitals: getRecentHospitals,
      getRecentSurgeons: getRecentSurgeons,
      getRecentItems: getRecentItems,
      addRecentItem: addRecentItem,
      addRecentSurgeon: addRecentSurgeon,
      addRecentHospital: addRecentHospital
    };

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
 * Recovery Factory
 *
 * @description Handles tasks needed for recovery functions in the settings
 */
(function() {
    'use strict';

    angular
        .module('starter.services')
        .factory('RecoveryService', RecoveryService);

    RecoveryService.$inject = ['SyncService', 'logger', 'smartStoreUtils', 'devUtils', 'syncRefresh', '$ionicPopup'];

    function RecoveryService(SyncService, logger, smartStoreUtils, devUtils, syncRefresh, $ionicPopup) {
        return {
            forceSync: function() {
              return new Promise(function(resolve, reject) {
                var numberOfTables = 0;
                var completedTablesCount = 0;

                var sequence = Promise.resolve();
                var syncCount = 0;

                var success = function(tablesToSync) {

                    logger.log('Built tables for forceSync: ' + JSON.stringify(tablesToSync));
                    var syncCount = 0;
                    var totalTables = tablesToSync.length;
                    var sequence = Promise.resolve();

                    tablesToSync.forEach(function(table) {
                        sequence = sequence.then(function() {
                            syncCount++;

                            // This is a call to the new recovery lighter force sync.
                            return syncRefresh.m2pRecoveryUpdateMobileTable(table);
                        }).then(function(resObject) {

                            logger.log('(' + syncCount + ' of ' + totalTables + ') Sync Result for ' + table + ': ' + JSON.stringify(resObject));

                            if (syncCount == totalTables) {
                                logger.log('Force Sync completed.');
                                resolve();
                            }
                        }).catch(function(res) {
                            logger.error('Caught error in force sync: ' + res);
                            reject(error);
                        });
                    });
                };

                var error = function(error) {
                    reject(error);
                    logger.error('Error getting tables: ' + JSON.stringify(error));
                };

                smartStoreUtils.listMobileTables(smartStoreUtils.ALPHA, success, error);
              });
            },

            recoverAllData: function() {
              return new Promise(function(resolve, reject) {
                dumpLocalStorage().then(function(res) {
                    return dumpSoups();
                }).then(function(res) {
                    return dumpTables();
                }).then(function(res) {
                    resolve();
                    logger.log('Completed Recovery: ' + res);
                }).catch(function(err) {
                    reject(err);
                    logger.error('Error in recovery: ' + err);
                });
              });
            },

            returnAllTableData: function() {
                return new Promise(function(resolve, reject) {
                    var tablesData = {};
                    devUtils.readRecords('recsToSync', []).then(function(recsToSyncRecords) {
                        tablesData.recsToSync = recsToSyncRecords;
                        smartStoreUtils.listMobileTables(smartStoreUtils.NONE, function(tables) {
                                tables.forEach(function(tableName) {
                                    devUtils.readRecords(tableName, []).then(function(records) {
                                        tablesData[tableName] = records;
                                        if (tableName === tables[tables.length - 1]) {
                                            resolve(tablesData);
                                        }
                                    }).catch(function(resObject) {
                                        logger.error("Error getting table data for viewer: " + JSON.stringify(resObject));
                                    });
                                });
                            },
                            function(error) {
                                logger.error("Unable to get tables from smartstore. " + error);
                            });
                    }).catch(function(resObject) {
                        logger.error("Error getting recsToSync data for viewer: " + JSON.stringify(resObject));
                    });
                });

            },

            returnAllLocalStorageData: function() {
              return new Promise(function(resolve, reject) {
                var dumpedLocalStorageData = [];
                for (var i in localStorage) {
                    dumpedLocalStorageData.push(localStorage[i]);
                }
                resolve(dumpedLocalStorageData);
              });
            },

            returnAllSoupsData: function() {
              return new Promise(function(resolve, reject) {
                var data = {};
                devUtils.readRecords('appSoup', []).then(function(records) {
                    data.appSoupData = records;
                    devUtils.readRecords('cacheSoup', []).then(function(records) {
                        data.cacheSoupData = records;
                        resolve(data);
                    }).catch(function(resObject) {
                        logger.error("Error getting cacheSoup data for viewer: " + JSON.stringify(resObject));
                    });
                }).catch(function(resObject) {
                    logger.error("Error getting appSoup data for viewer: " + JSON.stringify(resObject));
                });
              });
            }
        };

        function dumpTables() {
            return new Promise(function(resolve, reject) {
                var sequence = Promise.resolve();
                var dumpCount = 0;
                var totalTables = 0;
                smartStoreUtils.listMobileTables(smartStoreUtils.NONE, function(tables) {
                        tables.push('recsToSync');
                        totalTables = tables.length;

                        tables.forEach(function(tableName) {
                            sequence = sequence.then(function() {
                                dumpCount++;
                                return devUtils.readRecords(tableName, []).then(function(records) {
                                    return storeDumpedDataToRecoveryFolder('MobileTable_' + tableName, records);
                                }).then(function(resObject) {
                                    logger.log('(' + dumpCount + ' of ' + totalTables + ') Dump Result for ' + tableName + ': ' + JSON.stringify(resObject));

                                    if (dumpCount == totalTables) {
                                        resolve("Dump Completed for all tables.");
                                    }
                                }).catch(function(err) {
                                    reject(err);
                                });
                            });
                        });
                    },
                    function(error) {
                        logger.error("Unable to get tables from smartstore.");
                        reject(error);
                    });
            });
        }

        function dumpLocalStorage() {
            return new Promise(function(resolve, reject) {
                var dumpedLocalStorageData = [];
                for (var i in localStorage) {
                    dumpedLocalStorageData.push(localStorage[i]);
                }

                storeDumpedDataToRecoveryFolder('LocalStorage', dumpedLocalStorageData).then(function(res) {
                    resolve(res);
                }).catch(function(err) {
                    reject(err);
                });
            });
        }

        function dumpSoups() {
            return new Promise(function(resolve, reject) {
                devUtils.readRecords('appSoup', []).then(function(appSoupRecords) {
                    return storeDumpedDataToRecoveryFolder('AppSoup', appSoupRecords);
                }).then(function(resultOfAppSoupDump) {
                    return devUtils.readRecords('cacheSoup', []);
                }).then(function(cacheSoupRecords) {
                    return storeDumpedDataToRecoveryFolder('CacheSoup', cacheSoupRecords);
                }).then(function(resultOfCacheSoupDump) {
                    resolve("Completed dump of App Soup and Cache Soup: " + resultOfCacheSoupDump);
                }).catch(function(resObject) {
                    reject('Error in dump Soups: ' + resObject);
                });
            });
        }

        function storeDumpedDataToExternalAndroidRecoveryFolder(fileName, data) {
            // Stores dumped data to recovery folder
            // Params: fileName - name of the file. data - data to dump as JSON string

            return new Promise(function(resolve, reject) {

                logger.log('Beginning Android dump for: ' + fileName);
                window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, function(fs) {

                    var date = new Date();
                    var dateString = date.toISOString();
                    dateString = dateString.replace(/:/g, '');
                    var fileNameWithDate = 'Recovered_' + fileName + '_' + dateString + '.txt';

                    window.resolveLocalFileSystemURL(cordova.file.externalRootDirectory, function(dir) {
                        logger.log('File system open: ' + fs.name);
                        dir.getDirectory('RecoveredData', {
                            create: true
                        }, function(recoveryFolder) {

                            recoveryFolder.getFile(fileNameWithDate, {
                                create: true,
                                exclusive: false
                            }, function(fileEntry) {

                                logger.log("fileEntry is file? " + fileEntry.isFile.toString());

                                fileEntry.createWriter(function(fileWriter) {

                                    fileWriter.onerror = function(e) {
                                        logger.log("Failed file read: " + e.toString());
                                        reject(e.toString());
                                    };

                                    var dataObj = new Blob([JSON.stringify(data)], {
                                        type: 'text/plain'
                                    });
                                    logger.log('Completed write for: ' + fileName);

                                    fileWriter.write(dataObj);
                                    resolve("Completed dump of " + fileName);
                                });

                            }, function(e) {
                                reject('Error for getFile: ' + JSON.stringify(e));
                            });
                        });

                    }, function(e) {
                        reject('Error for resolveLocalFileSystemURL: ' + JSON.stringify(e));
                    });
                }, function(e) {
                    reject('Error for requestFileSystem: ' + JSON.stringify(e));
                });
            });
        }

        function storeDumpedDataToRecoveryFolder(fileName, data) {
            logger.log('Attempting to dump: ' + fileName);

            if (device.platform === "Android") {
                return storeDumpedDataToExternalAndroidRecoveryFolder(fileName, data);
            } else {

                return new Promise(function(resolve, reject) {

                    logger.log('Beginning iOS dump for: ' + fileName);
                    // Stores dumped data to recovery folder
                    // Params: fileName - name of the file. data - data to dump as JSON string
                    window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, function(fs) {

                        var date = new Date();
                        var dateString = date.toISOString();
                        dateString = dateString.replace(/:/g, '');
                        var fileNameWithDate = 'Recovered_' + fileName + '_' + dateString + '.txt';

                        logger.log('File system open: ' + fs.name);
                        fs.root.getDirectory('RecoveredData', {
                            create: true
                        }, function(recoveryFolder) {

                            recoveryFolder.getFile(fileNameWithDate, {
                                create: true,
                                exclusive: false
                            }, function(fileEntry) {

                                logger.log("fileEntry is file? " + fileEntry.isFile.toString());

                                fileEntry.createWriter(function(fileWriter) {

                                    fileWriter.onerror = function(e) {
                                        logger.error("Failed file read: " + e.toString());
                                        reject("Failed file read: " + e.toString());
                                    };

                                    var dataObj = new Blob([JSON.stringify(data)], {
                                        type: 'text/plain'
                                    });

                                    fileWriter.write(dataObj);
                                    logger.log('Write completed: ' + fileName);
                                    resolve('Recovery Completed: ' + fileName);
                                });

                            }, function(e) {
                                reject('Error for getFile: ' + JSON.stringify(e));
                            });
                        }, function(e) {
                            reject('Error for getDirectory: ' + JSON.stringify(e));
                        });
                    }, function(e) {
                        reject('Error for requestFileSystem: ' + JSON.stringify(e));
                    });
                });
            }
        }

        function showAlert(title, message) {
          var alert = $ionicPopup.alert({
            title: title,
            template: message,
            cssClass: 'bio-popup'
          });
          alert.then(function() {

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
      return new Promise(function(resolve, reject) {
        setSyncState("syncing");
  	    devUtils.initialSync(tablesToSync).then(function(res){
  	      setSyncState("complete");

          if (_.every(_.values(res), function(table) { return table.status === 100400; })){
            $rootScope.$emit('syncTables', {result : "InitialLoadComplete"});
            resolve();
          }
		    }).catch(function(resObject){
          setSyncState("complete");
          console.error('initialSync ',resObject);
          reject(resObject);
        });
      });
	  }

	  function syncTables(tablesToSync, syncWithoutLocalUpdates, maxTableAge) {

	  	// Check that we haven't locked out the syncing (e.g. whilst completing order form)
	  	var syncLock = getSyncLock();
	  	var syncState = getSyncState();
	    // logger.log("syncTables: syncLock = " + syncLock + "; syncState = " + syncState);

	    // Check that we don't already have a sync in progress.
	    // MobileCaddy Utils will also check for this condition, but we'll check before calling utils
	    if (syncState == "syncing") {
        $rootScope.$emit('syncTables', {result : 100498});
	      return;
	    }

      if (syncLock == "true") {
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