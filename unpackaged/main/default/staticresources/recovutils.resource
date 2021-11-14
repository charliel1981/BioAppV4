/*
 * Copyright (c) 2015, MobileCaddy Ltd.
 * mobilecaddy-utils - v0.1.4 - 2016-08-22 13:25:19
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided
 * that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the
 * following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
 * the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * Neither the name of MobileCaddy Ltd nor the names of its contributors may be used to endorse or
 * promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
var $j = jQuery.noConflict();
var MC_TABLES = ['Connection_Session__mc', 'Mobile_Log__mc', 'MC_Project__ap', 'MC_Time_Expense__ap', 'MC_Project_Location__ap'];

/*
 * MobileCaddy startup helper functions
 */

// ======================== //
// Main Function Definition //
// ======================== //
;(function() {

	// =============================== //
	// Local Require.js Implementation //
	// =============================== //
	var require,define;

	(function () {
	    var modules = {};
	    // Stack of moduleIds currently being built.
	    var requireStack = [];
	    // Map of module ID -> index into requireStack of modules currently being built.
	    var inProgressModules = {};

	    function build(module) {
	        var factory = module.factory;
	        module.exports = {};
	        delete module.factory;
	        factory(require, module.exports, module);
	        return module.exports;
	    }

	    require = function (id) {
	        if (!modules[id]) {
	        	// mobileLogger.logMessageAndThrow("module " + id + " not found");
	        	console.error("module " + id + " not found");
	        } else if (id in inProgressModules) {
	            var cycle = requireStack.slice(inProgressModules[id]).join('->') + '->' + id;
	            // mobileLogger.logMessageAndThrow("Cycle in require graph: " + cycle);
	        	console.error("Cycle in require graph: " + cycle);
	        }
	        if (modules[id].factory) {
	            try {
	                inProgressModules[id] = requireStack.length;
	                requireStack.push(id);
	                return build(modules[id]);
	            } finally {
	                delete inProgressModules[id];
	                requireStack.pop();
	            }
	        }
	        return modules[id].exports;
	    };

	    define = function (id, factory) {
	        if (modules[id]) {
	        	// mobileLogger.logMessageAndThrow("module " + id + " already defined");
	        	console.error("module " + id + " already defined");
	        }

	        modules[id] = {
	            id: id,
	            factory: factory
	        };
	    };

	    define.remove = function (id) {
	        delete modules[id];
	    };

	})();

	//Export for use in node
	if (typeof module === "object" && typeof require === "function") {
		module.exports.require = require;
	    module.exports.define = define;
	}
	// ================================ //
	// End of Require.js Implementation //
	// ================================ //



	// ============================================================= //
	// Main MobileCaddy Module                                       //
	// This is created as a global (window.mobileCaddy) and is used  //
	// as an entry point - mainly to use 'require' and to access any //
	// variables                                                     //
	// ============================================================= //
	define("mobileCaddy", function(require, exports, module) {
		var mobileCaddy = {
			    define:define,
			    require:require,

				// Globals
				START_PAGE_CONTROLLER : '',
				QUERY_BUFFER_SIZE : 50,
				INITIAL_APPCACHE_INFO : []
		};

		// Expose the mobileCaddy class
		module.exports = mobileCaddy;
	}); // end mobileCaddy define

	// ================================ //
	// MobileCaddy Mobile Logger Plugin //
	// ================================ //
	define("mobileCaddy/mobileLogger", function(require, exports, module) {

		function getErrorObject(){
		    try { throw Error(''); } catch(err) { return err; }
		}

		// Logging function
		function logMessage(msg, err) {
			var caller_line = err.stack.split("\n")[4];
			var caller = "";
			if (typeof(caller_line) != "undefined") {
				var index = caller_line.indexOf("at ");
				caller = caller_line.slice(index+2, caller_line.length);
			}

			console.log(msg, caller);
		} // end logMessage

		// Instead of just throwing an exception, here we can process
		// the message first
		function logMessageAndThrow(msg, err) {
			logMessage(msg, err);
			throw msg;
		} // end logMessageAndThrow

		function logObjectDetails(obj, err) {
			for (var fieldDef in obj) {
				logMessage('field:' + fieldDef + ': has value :' + obj[fieldDef] + ':', err);
			} // end loop through the object fields
		} // end logObjectDetails

		// Exposed functions
		module.exports = {

				// Logs a message and throws an exception
				logMessageAndThrow : function(msg) {
					logMessageAndThrow(msg, getErrorObject());
				},

				// Delegates to the local function
				logMessage : function(msg) {
					logMessage(msg, getErrorObject());
				}, // end logMessage

				logObjectDetails : function(obj) {
					logObjectDetails(obj, getErrorObject());
				} // end logObjectDetails
		};
	}); // end mobileLogger

	// ================================ //
	// MobileCaddy Geolocation          //
	// ================================ //
	define("mobileCaddy/geolocation", function(require, exports, module) {

		function getLocation(success,error) {
			/*if (navigator.geolocation) {
				console.log('calling get current position');
				navigator.geolocation.getCurrentPosition(
						function (position) {
							console.log('geolocation success callback');
							var returnRecords = [];
							returnRecords["Latitude"] = position.coords.latitude;
							returnRecords["Longitude"] = position.coords.longitude;
							returnRecords["Altitude"] = position.coords.altitude;
							returnRecords["Accuracy"] = position.coords.accuracy;
							returnRecords["Altitude Accuracy"] = position.coords.altitudeAccuracy;
							returnRecords["Heading"] = position.coords.heading;
							returnRecords["Speed"] = position.coords.speed;
							returnRecords["ErrorNumber"] = 0;
							success(returnRecords);
						},
						function (e) {
							console.log('geolocation error callback');
							var returnRecords = [];
							switch(e.code) {
								case e.PERMISSION_DENIED:
									returnRecords["Error"] = 'User denied the request for Geolocation.';
									returnRecords["ErrorNumber"] = 1;
									break;
								case e.POSITION_UNAVAILABLE:
									returnRecords["Error"] = 'Location information is unavailable.';
									returnRecords["ErrorNumber"] = 2;
									break;
								case e.TIMEOUT:
									returnRecords["Error"] = 'The request to get user location timed out.';
									returnRecords["ErrorNumber"] = 3;
									break;
								case e.UNKNOWN_ERROR:
									returnRecords["Error"] = 'An unknown error occurred.';
									returnRecords["ErrorNumber"] = 4;
									break;
								default:
									returnRecords["Error"] = 'An unknown error occurred.';
									returnRecords["ErrorNumber"] = 5;
									break;
							} // end switch
							success(returnRecords);
						},
						{timeout:1000,maximumAge:60000,enableHighAccuracy: false});
		    } // geolocation available check if
			else{
				var returnRecords = [];
				returnRecords["Error"] = 'Geolocation is not supported by this browser.';
				returnRecords["ErrorNumber"] = 6;
				success(returnRecords);
			} // geolocation available check else*/
			var returnRecords = [];
			returnRecords.Error = 'Location information is unavailable.';
			returnRecords.ErrorNumber = 2;
			success(returnRecords);
		} // end getLocation

		// Exposed functions
		module.exports = {

				// Logs a message and throws an exception
				getLocation : function(success,error) {
					getLocation(success,error);
				} // end getLocation
		};
	}); // end geolocation

	// ======================== //
	// MobileCaddy Startup Code //
	// ======================== //
	define("mobileCaddy/startup", function(require, exports, module) {

		// Get required modules
		var mobileLogger      = require('mobileCaddy/mobileLogger');
		var logger            = require('mobileCaddy/logger');
		var smartstore        = cordova.require("com.salesforce.plugin.smartstore");
		var systemDataSupport = require('mobileCaddy/systemData');
		var smartStoreUtils   = require('mobileCaddy/smartStoreUtils');
		var appDataUtils      = require('mobileCaddy/appDataUtils');

		// Create the recs to sync soup
		function createRecsToSyncSoup(success,error) {
			var recsToSyncStructure = [
			                           {path:"Mobile_Table_Name",type:"string"},
			                           {path:"SOUP_Record_Id",type:"string"},
			                           {path:"Id",type:"string"},
			                           {path:"LastModifiedDateTime",type:"integer"},
			                           {path:"CRUD_Operation",type:"string"},
			                           {path:"Current_Connection_Session",type:"string"}
			                           ];

			// Register the soup
			smartstore.registerSoup(
					'recsToSync',
					recsToSyncStructure,
	                success,
	                error);
		} // end recs to sync create

				// Create the recs to sync soup
		function createRecsToSyncSoupPromise() {
      return new Promise(function(resolve, reject) {
				var recsToSyncStructure = [
				                           {path:"Mobile_Table_Name",type:"string"},
				                           {path:"SOUP_Record_Id",type:"string"},
				                           {path:"Id",type:"string"},
				                           {path:"LastModifiedDateTime",type:"integer"},
				                           {path:"CRUD_Operation",type:"string"},
				                           {path:"Current_Connection_Session",type:"string"}
				                           ];

				// Register the soup
				smartstore.registerSoup(
						'recsToSync',
						recsToSyncStructure,
		                function() {
		                	resolve();
		                },
		                function(e){
		                	reject(e);
		                });
			});
		} // end recs to sync create

		// Checks if we are doing an initial startup or not
		function buildRequiredCheck(success,error) {

			// Check the soup exists.  If not then we require a build so pass back true
			smartstore.soupExists(
					'appSoup',
					function(appSoupExists) {

						console.log('soupExists = ' + appSoupExists);

						if (appSoupExists) {
							console.log('app soup found');

							// Now query out the build status.  If 'success' then we have a successful
							// build already so pass back a false
							appDataUtils.getCurrentValueFromAppSoup(
									'buildStatus',
									function(buildStatus) {
										console.log('found build status = ' + buildStatus);
										if (buildStatus == 'Success') {

											// Build is not required
											success(false);
										} // end build success check if
										else {

											// Build not successful so pass back a true
											success(true);
										} // end build success check else
									},
									error);

						} // end soup exists check if
						else {

							// Soup does not exist so we require a build
							success(true);
						} // end soup exists check else
					}, // end soup exists callback
					error);
		} // end initialStartup

		// This routine ensures that the application cache is ready before continuing to load the app.
		var CHECK_CACHE_SUCCESS = 100900;
		var CHECK_CACHE_FAILURE = 100901;
		function checkCache(success) {

			// Clear out cache variable from previous run
			mobileCaddy.INITIAL_APPCACHE_INFO = [];

			console.log('checkCache entry');

			window.applicationCache.addEventListener('checking', function(event) {
				writeCacheInfo(event);
			}, false);


			window.applicationCache.addEventListener('downloading', function(event) {
				writeCacheInfo(event);
			}, false);


			window.applicationCache.addEventListener('progress', function(event) {
				writeCacheInfo(event);
			}, false);

			// Record that we are checking the cache
			mobileCaddy.INITIAL_APPCACHE_INFO.push({Name : 'AppCache: Initial Status', Description : window.applicationCache.status});

			var returnObject = {};
			returnObject.status = CHECK_CACHE_SUCCESS;

			switch (window.applicationCache.status) {
				case window.applicationCache.CHECKING:
			    case window.applicationCache.DOWNLOADING:
		        window.applicationCache.addEventListener('updateready', function(event) {writeCacheInfo(event,success);}, false);
		        window.applicationCache.addEventListener('cached', function(event) {writeCacheInfo(event,success);}, false);
		        window.applicationCache.addEventListener('error', function(event) {writeCacheInfo(event,success);}, false);
		        window.applicationCache.addEventListener('noupdate', function(event) {writeCacheInfo(event,success);}, false);
						throw new Error('MobileCaddy - Cache busy.  Will continue when check/load is complete');
			    case window.applicationCache.UPDATEREADY:
			    	window.applicationCache.swapCache();
			    	success(returnObject);
			    	console.log('cache in updateready');
		        break;
			     default:
			    	console.log('cache in default');
			    	success(returnObject);
			     break;
			}
		} // end checkCache

		// Function to write to the app cache info
		function writeCacheInfo(event,success) {
			if (event.type == 'progress') {
				console.log('cache in progress');
				mobileCaddy.INITIAL_APPCACHE_INFO.push({Name : 'Event ', Description : event.loaded + " of " + event.total});
			}
			else {
				mobileCaddy.INITIAL_APPCACHE_INFO.push({Name : 'Event ', Description : event.type});
			}

			var returnObject = {};
			if ((event.type == 'udpateready') || (event.type = 'cached')) {
				console.log('cache in update ready or cached');
				returnObject.status = CHECK_CACHE_SUCCESS;
			}
			else {
				console.log('cache in else');
				returnObject.status = CHECK_CACHE_FAILURE;
			}

			console.log('return object ');
			mobileLogger.logObjectDetails(returnObject);
			if (success && typeof(success) === "function")  success(returnObject);
		} // end writeCacheInfo


		// At startup, wait for the jquery ready event then put a phonegap device ready event on.
		// When that fires, call init to create all of the mobile tables.
		function startup(thirdPartyCallbackFunction) {
			// Main processing - wait for ready event from jquery and then
			// set up event listener on the cordova device ready
			$j(function() {

				checkCache(
						function(cacheStatus) {
							preparePlatform(thirdPartyCallbackFunction,cacheStatus);
						});
			}); // end jquery ready fucntion
		} // end startup


		// This method determines if we are running on the device or on mock .  If on mock cordova then it will
		// create the app soup as it would have been created on the device.  For cordova it will create an event listener
		// on onDeviceReady that will continue with the general initialisation.
		function preparePlatform(thirdPartyCallbackFunction,cacheStatus) {
			console.log('prep platform cache status = ' + cacheStatus);

			// If we are running against the mock smartstore (assuming cordovaResource contains case insensitive
			// 'Mock') then just call init to initialise.  Otherwise wait for cordova.
			var appSoupJson = getUrlParamByName('appSoupJson');
			if (appSoupJson !== '') {
				console.log('app soup json = ' + JSON.stringify(appSoupJson));
				var upsertList = $j.parseJSON(appSoupJson);

				// Create app soup structure
				var appSoupStructure = [
				    {path:"Name",type:"string"},
					{path:"CurrentValue",type:"string"},
				    {path:"NewValue",type:"string"}
				];

				// Register the soup
				smartstore.registerSoup(
						'appSoup',
						appSoupStructure,
		                function() {
							smartstore.upsertSoupEntries(
									'appSoup',
									upsertList,
									function(upsertedRecs) {

										// Create Cache Soup
										// Create soup structure
										var cacheSoupStructure = [
										    {path:"Name",type:"string"},
											{path:"Description",type:"string"}
										];

										// Register the soup
										smartstore.registerSoup(
												'cacheSoup',
												cacheSoupStructure,
				                function() {
													buildOrReturn(thirdPartyCallbackFunction,cacheStatus);
												},
												function(e) {
													mobileLogger.logMessage('Failed to create cache soup with error = ' + e);
												});
									},
									function(e) {
										mobileLogger.logMessage('Failed to update app soup with error = ' + e);
									});
						},
						function(e) {
							mobileLogger.logMessage('Failed to register app soup with error = ' + e);
						});
			} // end running in mock check if
			else {
				console.log('app soup json2 = ' + appSoupJson);
				if (LOCAL_DEV) {
					cacheSoupStructure = [
				    {path:"Name",type:"string"},
						{path:"Description",type:"string"}
					];
					smartstore.registerSoup(
						'cacheSoup',
						cacheSoupStructure,
            function() {
							buildOrReturn(thirdPartyCallbackFunction,cacheStatus);
						});
				} else {
					// When cordova is ready we call the inner 'init' function above to
					// initialise the data structures
					document.addEventListener("deviceready",function() {buildOrReturn(thirdPartyCallbackFunction,cacheStatus);},false);

					// Prevent user using the back button.  Note although iOS doesn't have a
					// backbutton, this doesn't mess anything up so can be left!
					document.addEventListener("backbutton", function() {}, true);
				}
			} // end running against mock check else
		} // end prepare platform

		// This function checks the status of the app soup and will either build the mobile tables and then call the thirdPartyCallbackFunction or (if already created)
		// will call the thirdPartyCallbackFunction parameter directly.
		var THIRD_PARTY_NEW_INSTALL = 100800;
		var THIRD_PARTY_RESTART = 100801;

		function buildOrReturn(thirdPartyCallbackFunction,cacheStatus){
			console.debug('cache status = ' + JSON.stringify(cacheStatus));
			var logger = require('mobileCaddy/logger');
			smartstore.upsertSoupEntries(
				'cacheSoup',
				mobileCaddy.INITIAL_APPCACHE_INFO,
				function() {

					smartStoreUtils.querySoupRecsPromise('appSoup', smartstore.buildAllQuerySpec("_soupEntryId", null, 50))
					.then(function(appSoupRecs){
							var appSoupValObj = {};
							var appSoupUpsertArr = [];
							appSoupRecs.forEach(function(el){
								if (typeof(appSoupValObj[el.Name]) == "undefined") {
									appSoupValObj[el.Name] = el;

								} else {
									throw 'Should only be 1 ' + el.Name + ' entry in the app soup.  Found more';
								}
							});
							if (!appSoupValObj.userOverrideId) appSoupValObj.userOverrideId = '';

							// If complete we just return to the caller
							if (appSoupValObj.buildStatus.CurrentValue == 'Complete' && appSoupValObj.buildStatus.NewValue == 'Complete') {
								if (thirdPartyCallbackFunction !== null) {
									mobileLogger.logMessage('build already complete - calling 3rd party callback function');
									var returnObject = {};
									returnObject.status = THIRD_PARTY_RESTART;
									returnObject.mc_add_status = cacheStatus.status;
									returnObject.curVsn = appSoupValObj.dynVersionNumber.CurrentValue;
									if (typeof(appSoupValObj.dynVersionNumber.NewValue) != "undefined")
										returnObject.newVsn = appSoupValObj.dynVersionNumber.NewValue;
									thirdPartyCallbackFunction(returnObject);
								}
							} else {
								var getAudInfoSuccCB = function(result, event) {
								if (event.status) {
									mobileLogger.logMessage('Parse json aud' + result);
									appSoupUpsertArr = $j.parseJSON(result);
									var tmpAud = _.find(appSoupUpsertArr, {"Name": "audId"}).CurrentValue;
									var tmpSysDataPlatSupVersion = _.find(appSoupUpsertArr, {"Name": "sysDataPlatSupVersion"}).CurrentValue;
									createRecsToSyncSoupPromise().then(function() {
										// Create System Data Mobile Table
										systemDataSupport.createSystemDataSoup(
												function() {
													// Now we go and build our custom mobile tables
													smartStoreUtils.buildMobileTables(
															function() {
																var buildStatusObj = appSoupValObj.buildStatus;
																buildStatusObj.CurrentValue = 'Complete';
																buildStatusObj.NewValue = 'Complete';
																// Add existing soupEntryIds so thta values are
																// updated and not inserted
																appSoupUpsertArr.map(function(el){
																	if (appSoupValObj[el.Name]) el._soupEntryId = appSoupValObj[el.Name]._soupEntryId;
																	return el;
																});
																appSoupUpsertArr.push(buildStatusObj);
																smartstore.upsertSoupEntries(
																		'appSoup',
																		appSoupUpsertArr,
																		function() {

																			// If there is a callback function then call it.  Otherwise we are done.
																			if (thirdPartyCallbackFunction !== null) {

																				// This is an already completed build
																				var returnObject = {};
																				returnObject.status = THIRD_PARTY_NEW_INSTALL;
																				returnObject.mc_add_status = cacheStatus.status;
																				mobileLogger.logMessage('Calling 3rd party callback');
																				mobileLogger.logObjectDetails(returnObject);
																				thirdPartyCallbackFunction(returnObject);
																			} // end third part callback found check if
																		},
																		function(e) {
																			mobileLogger.logMessage('From upsert soup records ' + e);
																		});	 // end upsert app soup

															},
															function(e) {
																mobileLogger.logMessage('Error building mobile tables ' + e);
															}); // end build mobile tables
												},
												function(e) {
													mobileLogger.logMessage('create system data soup returned error' + e);
												},
												tmpAud,
												tmpSysDataPlatSupVersion
												); // end create system data soup
										mobileLogger.logMessage('Exiting startup');
									}).catch(function(e) {
										mobileLogger.logMessage('Error building recs to sync soup ' + e);
									}
									); // end create recs to sync
								} // end status set check if
								else {
									if (event.type === 'exception') {
										alert(event.message);
									} // end exception if
								} // end success else
							}; // end getAudInfoSuccCB callback

							// Get the aud info to supplement the app soup
							if ( USE_FORCETK === true ) {
								force.request(
						      {
						        method: 'POST',
						        path: '/services/apexrest/mobilecaddy1/' + 'getAUDInfo001',
						        contentType : 'application/json',
						        data: {
												"buildVersion" : appSoupValObj.buildVersion.CurrentValue,
												"buildName" : appSoupValObj.buildName.CurrentValue,
												"buildOS" : appSoupValObj.buildOS.CurrentValue,
												"deviceUuid" : appSoupValObj.deviceUuid.CurrentValue,
												"overrideUserId" : force.getUserId(),
												"startPageControllerVersion" : mobileCaddy.START_PAGE_CONTROLLER_VSN
						            },
						      },
						      function(response) {
						      	console.info('response -> ' + JSON.stringify(response));
						      	var event  = {};
						      	event.status = "200";
						      	getAudInfoSuccCB(response, event);
						      },
						      function(err) {
						      	console.error("err -> " + JSON.stringify(err));
						      	error();
						      });
							} else {
								Visualforce.remoting.Manager.invokeAction('mobilecaddy1.' +
										mobileCaddy.START_PAGE_CONTROLLER + '.getAudInfo',
										appSoupValObj.buildVersion.CurrentValue,
										appSoupValObj.buildName.CurrentValue,
										appSoupValObj.buildOS.CurrentValue,
										appSoupValObj.deviceUuid.CurrentValue,
										appSoupValObj.userOverrideId,
										getAudInfoSuccCB,
										{escape:false,timeout:30000});
							}
						}
					}).catch(function(error){
						console.error(error);
						// TODO - Somehow re-build or suggest re-install?
					});
				},
				function(e) {
					mobileLogger.logMessage('Failed to update app soup with initial app cache info = ' + e);
				});
		}

		// Generic routine used to remove URL parameter from the URL
		function getUrlParamByName(name) {
			console.info('getUrlParamByName -> name = ' + name);
			name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
			var regexS = "[\\?&]" + name + "=([^&#]*)";
			var regex = new RegExp(regexS);
			var results = regex.exec(window.location.search);
			console.log('getUrlParamByName results -> ' + results);
			if(results === null) {
			  return '';
			}
			else
			  return decodeURIComponent(results[1].replace(/\+/g, " "));
		} // end getUrlParamByName

		// Exposed functions
		module.exports = {
				startup : function(thirdPartyCallbackFunction) {
					startup(thirdPartyCallbackFunction);
			} // end startup
		}; // exports
	});

	// ==================================== //
	// MobileCaddy System Data Support Code //
	// ==================================== //
	define("mobileCaddy/systemData", function(require, exports, module) {

		// Need the mobile logger throughout
		var mobileLogger    = require('mobileCaddy/mobileLogger');
		var mobileCaddy     = require('mobileCaddy');
		var logger          = require('mobileCaddy/logger');
		var smartstore      = cordova.require("com.salesforce.plugin.smartstore");
		var smartStoreUtils = mobileCaddy.require('mobileCaddy/smartStoreUtils');
		var appDataUtils    = require('mobileCaddy/appDataUtils');

		function getQueryAndSoupDefinition(soupColumnDefinitions, success, error) {
			mobileLogger.logMessage('in getQueryAndSoupDefinition');
			var columnDefinitions = [];
			var selectStatement = 'Select ';

		    $j.each(soupColumnDefinitions, function(i,soupColumnDefinition) {
				columnDefinitions.push({path: soupColumnDefinition.Column_Name, type: soupColumnDefinition.Column_Type});
	    		if (soupColumnDefinition.Column_Name.indexOf('_') !== 0) {
		    		selectStatement += soupColumnDefinition.Column_Name +',';
		    	} // end check for a column if
		    });

		    // Take final comma off the select statement
		    selectStatement = selectStatement.substring(0, selectStatement.length - 1);

		    // Add from clause
		    selectStatement += ' From ' + soupColumnDefinitions[0].Name;
		    success(selectStatement,columnDefinitions);
		} // end getQueryAndSoupDefinition

		// Variable definitions go into the system data soup
		function populateSysDataSoupVariables(audId,sysDataPlatSupVersion,success,error) {
			mobileLogger.logMessage('In populate system data row values');
			var getSysDataSoupSuccCB = function(soupFieldDefinitions, event) {
				if (event.status) {
					mobileLogger.logMessage('In remoting callback for getSysDataSoupVariables with record count = ' + soupFieldDefinitions.length);
					//mobileLogger.logMessage('Parse json ' + soupFieldDefinitions);

					// Convert from returned JSON array representation into javascript array
					var insertRecords = $j.parseJSON(soupFieldDefinitions);
					mobileLogger.logMessage('Parse json soup field defns done');

					// Upsert the data into the system data soup
					smartstore.upsertSoupEntries(
							'syncLib_system_data',
							insertRecords,
							success,
							error);
				} // end status set check if
				else {
					if (event.type === 'exception') {
						alert(event.message);
						mobileLogger.logMessage('Exception return from getSystemDataRowValues = ' + event.message);
					} // end exception if
					else {
						mobileLogger.logMessage('Unknown return from getSystemDataRowValues = ' + event.message);
					} // end exception else
				} // end success else
			};
			if (USE_FORCETK === true ){
				force.request(
          {
            method: 'POST',
            path: '/services/apexrest/mobilecaddy1/' + 'getSysDataSoupVariables001',
            contentType : 'application/json',
            data: {
              "audId" : audId,
              "startPageControllerVersion" : mobileCaddy.START_PAGE_CONTROLLER_VSN,
              "systemDataPlatformSupportVersion" : sysDataPlatSupVersion
              },
      		},
          function(response) {
	        	var event  = {};
	        	event.status = "200";
	        	getSysDataSoupSuccCB(response, event);
          },
          error);
			} else {
				Visualforce.remoting.Manager.invokeAction('mobilecaddy1.' +
					mobileCaddy.START_PAGE_CONTROLLER + '.getSysDataSoupVariables',
					audId,
					sysDataPlatSupVersion,
					getSysDataSoupSuccCB,
					{escape:false});
			}
		} // end populateSysDataSoupVariables

		// Create the system data soup
		function createSystemDataSoup (success,error, audId, sysDataPlatSupVersion) {
			// TODO MSD-138 remove the else stuff once implemented.
			mobileLogger.logMessage('In createSystemDataSoup');
			if (typeof(audId) != "undefined" && typeof(sysDataPlatSupVersion) != "undefined"){
				getSystemDataSoupDefinition(audId,sysDataPlatSupVersion,success,error);
			} else {
				// Get the current aud Id and pass to backend
				appDataUtils.getCurrentValueFromAppSoup(
						'audId',
						function(audId) {
							appDataUtils.getCurrentValueFromAppSoup(
									'sysDataPlatSupVersion',
									function(sysDataPlatSupVersion) {
										mobileLogger.logMessage('In success callback with aud id = ' + audId);
										getSystemDataSoupDefinition(audId,sysDataPlatSupVersion,success,error);
									},
									error);
						},
						error);
			}
		} // end create system data soup

		function getSystemDataSoupDefinition(audId,sysDataPlatSupVersion,success,error) {
			mobileLogger.logMessage('In getSystemDataSoupDefinition with audId = ' + audId + ' and sysDataPlatSupVersion = ' + sysDataPlatSupVersion);
			var getSysDataSoupDefSuccCB = function (appDefinitions, event) {
				if (event.status) {
					mobileLogger.logMessage('In getSystemDataSoupDefinition callback -> ' + appDefinitions);
					mobileLogger.logMessage('Parse json app defns' + appDefinitions);
					var defnArray = $j.parseJSON(appDefinitions);
					mobileLogger.logMessage('Parse json app defns done');
					$j.each(defnArray, function(i,defn) {
						mobileLogger.logObjectDetails(defn);
					});

					// Register the soup
					smartstore.registerSoup(
							'syncLib_system_data',
							defnArray,
							function() {
								populateSysDataSoupVariables(
										audId,
										sysDataPlatSupVersion,
										function() {
											populateDefsForSObjectMobileTables(audId,sysDataPlatSupVersion,success,error);
										},
										error);
							},
							error);
				}
				else {
					if (event.type === 'exception') {
						alert(event.message);
						mobileLogger.logMessage('Exception return from getSystemDataSoupDefinition = ' + event.message);
					} // end exception if
					else {
						mobileLogger.logMessage('Unknown return from getSystemDataSoupDefinition = ' + event.message);
					} // end exception else
				} // end success else
			};
			if ( USE_FORCETK === true ) {
				console.debug("USE_FORCETK == true");
				force.request(
	        {
	          method: 'POST',
            path: '/services/apexrest/mobilecaddy1/' + 'getSystemDataSoupDefinition001',
            contentType : 'application/json',
            data: {
              "audId" : audId,
              "startPageControllerVersion" : mobileCaddy.START_PAGE_CONTROLLER_VSN,
              "systemDataPlatformSupportVersion" : sysDataPlatSupVersion
              },
	        },
	        function(response) {
	        	var event  = {};
	        	event.status = "200";
	        	getSysDataSoupDefSuccCB(response, event);
	        },
	        error);
			} else {
				Visualforce.remoting.Manager.invokeAction('mobilecaddy1.' +
						mobileCaddy.START_PAGE_CONTROLLER + '.getSystemDataSoupDefinition',
						audId,
						sysDataPlatSupVersion,
						getSysDataSoupDefSuccCB,
						{escape:false});
			}
		} // end getSystemDataSoupDefinition

		function populateDefsForSObjectMobileTables(audId,sysDataPlatSupVersion,success,error) {
			mobileLogger.logMessage(mobileCaddy.START_PAGE_CONTROLLER + '.getDefsForSObjectMobileTables');
			var getDefsForSObjSuccCB = function(tableDefinitions, event) {
				if (event.status) {
					//mobileLogger.logMessage('Parse json ' + tableDefinitions);
					var defnArray = $j.parseJSON(tableDefinitions);
					mobileLogger.logMessage('Parse json table defns done');

					// Populate the soup
					smartstore.upsertSoupEntries(
							'syncLib_system_data',
							defnArray,
							function(insertedRecs) {
								console.log('successful upsert with rec count = ' + insertedRecs.length);
								success(insertedRecs);
							},
							function(e) {
								console.log('Error returned from upsert, message =  ' + e);
								error(e);
							});
				}
				else {
					if (event.type === 'exception') {
						alert(event.message);
						mobileLogger.logMessage('Exception return from getDefsForSObjectMobileTables = ' + event.message);
					} // end exception if
					else {
						mobileLogger.logMessage('Unknown return from getDefsForSObjectMobileTables = ' + event.message);
					} // end exception else
				} // end success else
			};
			if (USE_FORCETK === true ){
				force.request(
          {
            method: 'POST',
            path: '/services/apexrest/mobilecaddy1/' + 'getDefsForSObjectMobileTables001',
            contentType : 'application/json',
            data: {
              "audId" : audId,
              "startPageControllerVersion" : mobileCaddy.START_PAGE_CONTROLLER_VSN,
              "systemDataPlatformSupportVersion" : sysDataPlatSupVersion
              },
      		},
          function(response) {
	        	var event  = {};
	        	event.status = "200";
	        	getDefsForSObjSuccCB(response, event);
          },
          error);
			} else {
				Visualforce.remoting.Manager.invokeAction('mobilecaddy1.' +
					mobileCaddy.START_PAGE_CONTROLLER + '.getDefsForSObjectMobileTables',
					audId,
					sysDataPlatSupVersion,
					getDefsForSObjSuccCB,
					{escape:false,timeout:120000});
			}
		} // end populateDefsForSObjectMobileTables

		// Exposed functions
		module.exports = {

			// Create the system data soup
			createSystemDataSoup : function(success,error, audId, sysDataPlatSupVersion) {
				createSystemDataSoup(success,error, audId, sysDataPlatSupVersion);
			} // end create system data soup
		}; // end exports
	}); // end systemData

	// ======================================= //
	// MobileCaddy Smartstore Utilities Plugin //
	// ======================================= //
	define("mobileCaddy/smartStoreUtils", function(require, exports, module) {

		// Get required modules
		var mobileLogger = require('mobileCaddy/mobileLogger');
		var smartstore = cordova.require("com.salesforce.plugin.smartstore");

		// Updates the snapshot table to contain the same
		// contents as the table given by tableName param
		function refreshSnapshot(tableName,success,error) {

			// First check the soup exists
			smartstore.soupExists(
					tableName,
					function(soupExists) {
						if (soupExists) {

							// Now check the snapshot exists
							smartstore.soupExists(
									'SnapShot_' + tableName,
									function(soupExists) {
										if (soupExists) {

											// Now we must clear out the snapshot table
											// First query back all records
											querySoupRecords(
													'SnapShot_' + tableName,
													function(snapShotRecords) {
														deleteRecordsFromSoup(
																snapShotRecords,
																'SnapShot_' + tableName,
																function() {

																	// Get all records from the main table
																	querySoupRecords(
																			tableName,
																			function(records) {

																				// Now load them into the snapshot table
																				smartstore.upsertSoupEntries(
																						'SnapShot_' + tableName,
																						records,
																						success,
																						error);
																			},
																			error);
																},
																error);
													},
													error);
										} // end snapshot table exists check if
										else {
											mobileLogger.logMessageAndThrow ("SnapShot Table is missing: SnapShot_" + tableName);
										} // end snapshot table exists check else
									},
									error);
						} // end mobile table exists check if
						else {
							mobileLogger.logMessageAndThrow ("Mobile Table is missing" + tableName);
						} // end mobile table exists check else
					},
					error);
		} // end refreshSnapshot

		// This function deletes the given records from the given table.  The externalId
		// parameter indicates which column in the record set uniquely identifies the record
		// in the mobile table.
		function deleteRecordsForExternalId(tableName,records,externalId,success,error) {

			// If provided list is empty then we have finished already!
			if (records.length === 0) {
				success();
			} // end records empty check if
			else {

				// Need a list of external ids that we need to delete
				var externalIdsToDelete = [];
				$j.each(records, function(i, record) {
					externalIdsToDelete.push(record[externalId]);
				});

				// Get all records for the given mobile table
    		querySoupRecords(
						tableName,
						function(existingRecords) {
							// Collect the soup entry ids matching the set of records
							// requiring deletion
							var soupEntryIds = [];
							$j.each(existingRecords, function(i, existingRecord) {
								if (externalIdsToDelete.indexOf(existingRecord[externalId]) != -1) {
									soupEntryIds.push(existingRecord._soupEntryId);
								} // end record needs deleting check if
							});

							if (soupEntryIds.length === 0) {
								success();
							} // end entries for delete not found if
							else {

								// Got the soup numbers so delete the records
								smartstore.removeFromSoup(
										tableName,
										soupEntryIds,
										success,
										error);
							} // end entries for delete not found else
						},
						error);
			} // end records empty check else
		} // deleteRecordsForExternalId

		// Calls the success function with the set of records
		function collectRecsFromCursor(cursor,success,error) {

		    var entries = [];

		    function addEntriesFromCursor(cursor) {
				$j.each(cursor.currentPageOrderedEntries, function(i, entry) {
				    entries.push(entry);
				});
		        if(cursor.currentPageIndex < cursor.totalPages - 1) {
		            cordova.require("com.salesforce.plugin.smartstore").moveCursorToNextPage(cursor, addEntriesFromCursor);
		        }
		        else {
		            cordova.require("com.salesforce.plugin.smartstore").closeCursor(cursor, onCursorClosed);
		        }
		    }

		    function onCursorClosed(cursor) {
		        success(entries);
		    }

		    // Let's start reading from cursor
		    addEntriesFromCursor(cursor);
		} // end collectRecsFromCursor

		// For the given soup name returns the column definitions from the system data soup
		function getSoupDefinitionRows(soupName,success,error) {

			// Get column definitions for this soup
			var querySpec = smartstore.buildExactQuerySpec("Name", soupName, mobileCaddy.QUERY_BUFFER_SIZE);
			querySoupRecordsWithQuerySpec(
					'syncLib_system_data',
					querySpec,
					function(records) {
						mobileLogger.logMessage('soup definition rows success callback with rec count = ' + records.length);

						// We have both the object definition plus the columns
						// Filter out the object
						var filteredEntries = [];
						$j.each(records, function(i,record) {
							mobileLogger.logMessage('processing record = ');
							//mobileLogger.logObjectDetails(record);
							if ((record.Type != mobileCaddy.STANDING_DATA_OBJECT) && (record.Type != mobileCaddy.DYNAMIC_DATA_OBJECT)) {
								mobileLogger.logMessage('Record Match');
								filteredEntries.push(record);
							}
							else {
								mobileLogger.logMessage('Record does not match');
							}
						});	 // end loop through records

						// Pass the retrieved records back
						success(filteredEntries);
					},
					error);
		} // end getSoupDefinitionRows

		// Return the row that defines the object from the system data soup
		function getSoupObjectDefinition(soupName,success,error) {

			// Get column definitions for this soup
			var querySpec = cordova.require("com.salesforce.plugin.smartstore").buildExactQuerySpec("Name", soupName, mobileCaddy.QUERY_BUFFER_SIZE);
			querySoupRecordsWithQuerySpec(
					'syncLib_system_data',
					querySpec,
					function(records) {

						// There will be one object definition - either dynamic or static
						var returnRecord;
						for (var i=0; i<records.length; i++) {
							if ((records[i].Type == mobileCaddy.STANDING_DATA_OBJECT) || (records[i].Type == mobileCaddy.DYNAMIC_DATA_OBJECT)) {
								returnRecord = records[i];
								break;
							}
						}	 // end loop through records

						// Return the found object definition
						success(returnRecord);
					},
					error);
		} // end getSoupObjectDefinition

		// This method removes the specified soup definition from the system data soup
		// This includes the object definition and rows - whether standing or dynamic
		function removeSoupDefinitions(soupName,success,error) {

			// Get column definitions for this soup
			var querySpec = cordova.require("com.salesforce.plugin.smartstore").buildExactQuerySpec("Name", soupName, mobileCaddy.QUERY_BUFFER_SIZE);
			querySoupRecordsWithQuerySpec(
					'syncLib_system_data',
					querySpec,
					function(records) {
						deleteRecordsFromSoup(
							records,
							'syncLib_system_data',
							function(){
								mobileLogger.logMessage('Success delete records from soup, calling callback');
								success();
							},
							error);
					},
					error);
		} // end removeSoupDefnitions

		// Looks up the soup definition in the system data soup and from the columns
		// builds up the query string
		function buildSoupQueryString(soupName, success, error) {
			mobileLogger.logMessage('in buildSoupQueryString for soup = ' + soupName);

			// Get the soup definition rows
			getSoupDefinitionRows(
					soupName,
					function(soupColumnDefinitions) {

						mobileLogger.logMessage('In getSoupDefinitionRows success callback');

						if (soupColumnDefinitions.length === 0 ) {
							simpleMessageSL('No soup columns defined for soup ' + soupName);
							error('No soup columns defined for soup ' + soupName);
						} // end soup column definitions not found if
						else {
							// Need the where clause so get the object definition from system data soup
							getSoupObjectDefinition(
									soupName,
									function (soupObjectDefinition) {

										mobileLogger.logMessage('in getSoupObjectDefinition success callback');

										// Initialise select clause
										var selectStatement = 'Select ';

										// Add on the column names
										$j.each(soupColumnDefinitions, function(i,soupColumnDefinition) {
											selectStatement += soupColumnDefinition.Column_Name +',';
										});

										// Take final comma off the select statement
										selectStatement = selectStatement.substring(0, selectStatement.length - 1);

										// Add from clause
										selectStatement += ' From ' + soupName;

										// Pass back to the calling function
										success(selectStatement);
									},
									error);
						} // end soup column definitions not found else
					},
					error);
		} // end buildSoupQuery

		function getQueryAndSoupDefinition(soupColumnDefinitions, success, error) {
			mobileLogger.logMessage('in getQueryAndSoupDefinition');
			var columnDefinitions = [];
			var selectStatement = 'Select ';

		    $j.each(soupColumnDefinitions, function(i,soupColumnDefinition) {
		    	mobileLogger.logMessage('soup column defn = ' );
		    	//mobileLogger.logObjectDetails(soupColumnDefinition);
				columnDefinitions.push({path: soupColumnDefinition.Column_Name, type: soupColumnDefinition.Column_Type});
	    		if (soupColumnDefinition.Column_Name.indexOf('_') !== 0) {
		    		selectStatement += soupColumnDefinition.Column_Name +',';
		    	} // end check for a column if
		    });

		    // Take final comma off the select statement
		    selectStatement = selectStatement.substring(0, selectStatement.length - 1);

		    // Add from clause
		    selectStatement += ' From ' + soupColumnDefinitions[0].Name;
		    success(selectStatement,columnDefinitions);
		} // end getQueryAndSoupDefinition

		function querySoupRecords(soupName,success,error) {
			var querySpec = smartstore.buildAllQuerySpec("_soupEntryId", null, mobileCaddy.QUERY_BUFFER_SIZE);
			smartstore.querySoup(	soupName,
									querySpec,
									function(cursor) {
										collectRecsFromCursor(	cursor,
															function(records) {
																success(records);
															},
															error);
									});
		} // end querySoupRecords

		// Runs a querySoupRecords call as a promise
		// TODO : modify real querySoupRecords to be a promise
		function querySoupRecsPromise(table) {
			return new Promise(function(resolve, reject) {
      	querySoupRecords(
					table,
					function(allTableRecords) {
	      		resolve(allTableRecords.filter(function(e) {return typeof(e) == 'object';}));
	      	},
	      	function(error) {
	      		reject(error);
	      	}
	      );
      });
		}

		function querySoupRecordsWithQuerySpec(soupName,querySpec,success,error) {
			smartstore.querySoup(	soupName,
									querySpec,
									function(cursor) {
										collectRecsFromCursor(	cursor,
															function(records) {
																mobileLogger.logMessage('Passing records back to callback for soup = ' + soupName + ' and rec count = ' + records.length);
																success(records);
															},
															error);
									},
									error);
		} // end querySoupRecordsWithQuerySpec

		function smartQuerySoupRecordsWithQuerySpec(smartQuerySpec,success,error) {
			console.debug("smartQuerySoupRecordsWithQuerySpec", smartQuerySpec);
			smartstore.runSmartQuery(	smartQuerySpec,
										function(cursor) {
											collectRecsFromCursor(	cursor,
																function(records) {
																	mobileLogger.logMessage('Passing records back to callback for soup with rec count = ' + records.length);
																	success(records);
																},
																error);
										},
										error);
		} // end smartQuerySoupRecordsWithQuerySpec

		// Query the mobile table for col = val
		function queryMobileTable(soupName,col,val,success,error) {
			if (typeof(success) == "undefined" && typeof(error) == "undefined") {
				// run as a promise
    		return new Promise(function(resolve, reject) {
					var querySpec = smartstore.buildExactQuerySpec(col, val, mobileCaddy.QUERY_BUFFER_SIZE_SL);
					querySoupRecordsWithQuerySpec(
						soupName,
						querySpec,
						function(records) {
							resolve(records);
						},
						function(e) {
							reject(e);
						});
				});
			} else {
				var querySpec = smartstore.buildExactQuerySpec(col, val, mobileCaddy.QUERY_BUFFER_SIZE_SL);
				querySoupRecordsWithQuerySpec(
					soupName,
					querySpec,
					function(records) {
						success(records);
					},
					error);
			}
		} // end queryMobileTable

		// Convenience method as 'and' is not available for standard calls
		// and currently not in smartsql in mock smart store
		function queryMobileTableWithAnd(soupName,col1,val1,col2,val2,success,error) {
			var querySpec = smartstore.buildExactQuerySpec(col1, val1, mobileCaddy.QUERY_BUFFER_SIZE_SL);
			querySoupRecordsWithQuerySpec(
					soupName,
					querySpec,
					function(firstPassRecs) {
						var secondPassRecs = [];
						$j.each(firstPassRecs, function(i,firstPassRec) {
							if (firstPassRec[col2] == val2) {
								secondPassRecs.push(firstPassRec);
							} // end col2 check if
						}); // end loop through the records
						success(secondPassRecs);
					},
					error);
		} // end queryMobileTableWithAnd

		// Returns the definition row for the given table.  Enables further analysis
		// e.g. do we snapshot table,
		function getDefnRowForTableName(tableName,success,error) {
			getSysDataRowMapColHeading(
					'Row Mapping PT',
					'Mobile Table Name',
					function(tableNameHeading) {
						queryMobileTableWithAnd(
								'syncLib_system_data',
								'MC_Var_String_001',
								'Platform Table Definition',
								tableNameHeading,
								tableName,
								function(rowList) {

									if (rowList.length != 1) mobileLogger.logMessageAndThrow('Should be exactly 1 table defn row for table: ' + tableName + ', but we got ' + rowList.length);
									success(rowList[0]);
								},
								error);
					},
					error);
		} // end getDefnRowForTableName

		// Returns the table defintion row value for the given mobile table name
		// and heading type (e.g. snapshot data required)
		function getTableDefnColumnValue(tableName,headingType,success,error) {

			// Get system data soup defn row for the given table name
			getDefnRowForTableName(
					tableName,
					function(tableDefnRow) {

						// Get the given column name
						getSysDataRowMapColHeading(
								'Row Mapping PT',
								headingType,
								function(columnName) {
									success(tableDefnRow[columnName]);
								},
								error);
					},
					error);
		} // end getTableDefnColumnValue

		// For the given table name, heading type (e.g. soup built date/time) and value
		// this function updates the system data soup with the given value to set.
		function setTableDefnColumnValue(tableName,headingType,valueToSet,success,error) {

			// Get system data soup defn row for the given table name
			getDefnRowForTableName(
					tableName,
					function(tableDefnRow) {

						// Get the snapshot column name
						getSysDataRowMapColHeading(
								'Row Mapping PT',
								headingType,
								function(columnName) {
									tableDefnRow[columnName] = valueToSet;
									smartstore.upsertSoupEntries(
											'syncLib_system_data',
											[tableDefnRow],
											success,
											error);
								},
								error);
					},
					error);
		} // end setTableDefnColumnValue

		// Function that takes the system data row type (e.g. Row Mapping PT, Row Mapping TC) and the
		// system data row values (e.g. Mobile Table Name) and returns the column name in the sys
		// data soup that contains the data
		function getSysDataRowMapColHeading(sysDataRowType, sysDataRowValue, success,error) {
			queryMobileTableWithAnd(
					'syncLib_system_data',
					'MC_Var_String_001',
					sysDataRowType,
					'MC_Var_String_003',
					sysDataRowValue,
					function(records) {

						// Should be exactly one matching record
						if (records.length != 1) {
							$j.each(records, function(i,record) {
								mobileLogger.logObjectDetails(record);
							}); // end loop through the records

							mobileLogger.logMessageAndThrow('Must be exactly 1 Row Mapping Record for Sys Data Row Type = ' + sysDataRowType + ' and Sys Data Row Value = ' + sysDataRowValue + ' found count = ' + records.length);
						}

						// Pass the column name to the callback
						success(records[0].MC_Var_String_004);
					},
					error);
		} // end getSysDataRowMapColHeading

		// Takes a list of row types (e.g. Row Mapping PT, Row Mapping TC etc and returns a list
		// with the column name in the same order.
		function getSysDataRowMapColHeadings(sysDataRowType, sysDataRowValues, success,error) {

			// Get back all sys data soup rows where s001 is the passed in row type
			var querySpec = smartstore.buildExactQuerySpec('MC_Var_String_001', sysDataRowType, mobileCaddy.QUERY_BUFFER_SIZE_SL);
			querySoupRecordsWithQuerySpec(
					'syncLib_system_data',
					querySpec,
					function(records) {
						// Prepare return list
						var resultsList = [];

						// Go through the passed in sys data row values
						// For each one find the match in the returned record set
						$j.each(sysDataRowValues, function(i,sysDataRowValue) {

							var foundRecord = false;
							$j.each(records, function(i,record) {
								if (record.MC_Var_String_003 == sysDataRowValue) {
									resultsList.push(record.MC_Var_String_004);
									foundRecord = true;

									// Leave each as we have our match
									return;
								} // end match check if
							}); // end loop through returned recs each

							// Raise exception if no match found
							if (!foundRecord) {
								throw "No mapping found for type = " + sysDataRowType + " and value = " + sysDataRowValue;
							} // end rec not found check if
						}); // end loop through passed in values each
						success(resultsList);
					},
					error);
		} // end getSysDataRowMapColHeadings

		// Literals to specify the order that the mobile tables will be returned
		var NONE = 0; 		// order naturally returned - for code speed
		var ALPHA = 1; 		// alphabetical order
		var BUILD = 2; 		// build table order

		// Gets a list of all the mobile tables and returns to the calling routine
		function listMobileTables(order,success,error) {

			// Get the system data column heading for platform table / mobile table name
			// and the build order
			getSysDataRowMapColHeadings(
					'Row Mapping PT',
					['Mobile Table Name',
					 'Build Order'],
					function(resultsList) {
						var heading = resultsList[0];
						var buildOrderHeading = resultsList[1];

						// Requery sys data for the platform table definition
						queryMobileTable(
								'syncLib_system_data',
								'MC_Var_String_001',
								'Platform Table Definition',
								function (tableDefRecs) {

									// If the request is for build order, then get the build order column heading and
									// sort by build order
									//
									var recNames = [];
									if (order == BUILD) {

										tableDefRecs.sort(function(a,b){

											// Default to zero (identical)
											var retVal = 0;

											// Defend against non integer build order values
											var aOrder = parseInt(a[buildOrderHeading]);
											var bOrder = parseInt(b[buildOrderHeading]);
											if (!isNaN(aOrder) && (!isNaN(bOrder))) {
												retVal = aOrder - bOrder;
											}
											return retVal;
										});

										// Extract the table name and return
										$j.each(tableDefRecs, function(i,tableDefRec) {
											recNames.push(tableDefRec[heading]);
										}); // end loop through the records

										if (success !== null) success(recNames);

									} // end build order check if
									else {
										$j.each(tableDefRecs, function(i,tableDefRec) {
											recNames.push(tableDefRec[heading]);
										}); // end loop through the records

										// Alpha
										if (order == ALPHA) {
											recNames.sort();
										} // end ALPHA sort if

										// Finished so call callback
										if (success !== null) success(recNames);
									} // end build order check else
								},
								error);
					},
					error);
		} // end listMobileTables

		// Literals to determine what is returned from listMobileTableColumns
		var LIST = 0;
		var BUILD_OBJECT = 1;
		var FULL = 2;

		// Gets the columns applicable to the given mobile table name.  This function returns
		// either a list of column names (listType is LIST) or an array of objects
		// to pass to the smartstore table create routine (listType is BUILD_OBJECT)
		function listMobileTableColumns(tableName,listType,success,error) {

			// Get system data mappings
			getSysDataRowMapColHeadings(
					'Row Mapping TC',
					['Parent SOUP Name',
					 'Table Column Name',
					 'Mobile Column Type',
					 'Application Field CRUD',
					 'META isNillable',
					 //'Platform Column Type'],
					 'Platform Column Type',
					 'Device Value Type',
					 'Proxy Ref Field Name'],
					function(resultsList) {
						var tableColumnName = resultsList[0];
						var tableColumnHeading = resultsList[1];
						var tableColumnTypeName = resultsList[2];
						var applicationFieldCrud = resultsList[3];
						var isNillable = resultsList[4];
						var platColType = resultsList[5];
						var appColType = resultsList[6];
						var proxyRefFieldName = resultsList[7];

						// Get the sysem data soup Platform Table Column row where
						// the soup column contains our mobile table name.  This give
						// us our table columns
						queryMobileTableWithAnd(
								'syncLib_system_data',
								'MC_Var_String_001',
								'Platform Table Column',
								tableColumnName,
								tableName,
								function (columnRecs) {

									// Go through the column recs and build a list of column names
									var tableDefinition = [];
									$j.each(columnRecs, function(i,columnRec) {

										if (listType == LIST) {
											tableDefinition.push(columnRec[tableColumnHeading]);
										}
										else if (listType == FULL) {
											tableDefinition.push({
												path          : columnRec[tableColumnHeading],
												type          : columnRec[tableColumnTypeName],
												crud          : columnRec[applicationFieldCrud],
												nillable      : columnRec[isNillable],
												platColType   : columnRec[platColType],
												appColType    : columnRec[appColType],
												proxyRefField : columnRec[proxyRefFieldName]
											});
										}
										else {
											// Assume BUILD_OBJECT
											tableDefinition.push({path : columnRec[tableColumnHeading], type : columnRec[tableColumnTypeName]});
											mobileLogger.logMessage('path = ' + columnRec[tableColumnHeading] + ' and type = ' + columnRec[tableColumnTypeName]);
										} // end LIST else
									}); // end loop through the records

									// Pass list of column names into callback function
									success(tableDefinition);
								},
								function(e) {
									mobileLogger.logMessage('Error retrieving column names = ' + e);
								});
					},
					error);
		} // end listMobileTableColumns

		// Build the mobile tables.  This will be called once the definitions are already
		// in our system data soup.
		function buildMobileTables(success,error) {
			// Get a list of the mobile tables in the required build order
			console.debug('About to buildMobileTables');
			listMobileTables(
					BUILD,
					function(tableNames) {

						// Record the number of tables.  We reduce this count
						// as tables are created and call the success callback
						// only once the count reaches 0
						var tableCount = tableNames.length;

						// Iterate through the returned tables / table columns
						$j.each(tableNames, function(i,tableName) {

							// Get the table columns for the given table.  We specify BUILD_OBJECT
							// which means we get back an array of objects rather than a list of
							// textual column names.  The reason is so we can pass directly into
							// registerSoup
							listMobileTableColumns(
									tableName,
									BUILD_OBJECT,
									function(tableColumnObjectArray) {
										console.debug('tableColumnObjectArray -> ' + tableColumnObjectArray);

										// Register the soup
										smartstore.registerSoup(
												tableName,
												tableColumnObjectArray,
												function() {

													console.log('success on register soup ' + tableName);

													// Successfully registered soup so update the
													// system date soup 'soup build date/time'
													setTableDefnColumnValue(
															tableName,
															'SOUP Built Date/Time',
															new Date().getTime(),
															function() {

																console.log('success on update of soup build date time');

																// Do we need to create a snapshot for this table ?
																getTableDefnColumnValue(
																		tableName,
																		'Snapshot Data Required',
																		function(snapshotValue) {

																			// Create the snapshot table too, if required
																			if (snapshotValue == 'Yes') {
																				smartstore.registerSoup(
																						'SnapShot_' + tableName,
																						tableColumnObjectArray,
																						function() {
																							console.log('Success from build of SnapShot_' + tableName);

																							// Successfully registered snapshot soup so update the
																							// system date soup 'snapshot soup build date/time'
																							setTableDefnColumnValue(
																									tableName,
																									'Snapshot SOUP Built Date/Time',
																									new Date().getTime(),
																									function() {

																										// Update the table count and call callback when complete
																										// after the snapshot is created
																										tableCount--;
																										if (tableCount === 0) {
																											success();
																										} // end tables check if
																									},
																									error);
																						},
																						function(e) {
																							console.log('Fail on create of SnapShot_' + tableName + ' ' + e);
																							error(e);
																						});
																			} // end snapshot needed check if
																			else {

																				// Update the table count and call callback when complete
																				tableCount--;
																				if (tableCount === 0) {
																					success();
																				} // end tables check if
																			} // end snapshot needed check else
																		},
																		error);
															},
															error);
												},
												function(e) {
													console.log('Fail on create of table' + tableName + ' ' + e);
													error(e);
												});
									},
									error);
						}); // end loop through the records
					},
					error);
		} // end buildMobileTables

		// This function deletes the list of current records from the given soup
		// Deals with an empty list by directly calling the callback function
		function deleteRecordsFromSoup (records,soupName,success,error) {
			mobileLogger.logMessage('In delete recs from soup with rec count = ' + records.length);

			// Defend against no records in the list
			if (records.length !== 0) {
				var recIds = [];
				$j.each(records, function(i,recToDelete) {
					recIds.push(recToDelete._soupEntryId);
				}); // end loop through the records

				// Remove recs from the soup
				smartstore.removeFromSoup(soupName,
											recIds,
											function(param) {
												mobileLogger.logMessage('Deleted rec(s) - calling callback');
												success(param);
											},
											error);
			} // end records not empty check if
			else {
				// No records so just call the success function
				mobileLogger.logMessage('no recs to delete - calling callback');
				success();
			} // end records not empty check else
		} // end deleteRecordsFromSoup

		// This function takes a mobile table name and a list of records and it inserts the records.
		// In addition it adds the proxy id and places the record in the records to sync mobile table.
		function insertRecords(mobileTable,records,success,error) {

			var syncRefresh = require('mobileCaddy/syncRefresh');

			console.log('in insert records');
			console.log('mobile table name = ' + mobileTable);
			console.log('records = ' + JSON.stringify(records));
			console.log('records size = ' + records.length);
			// Direct cordova call to insert the records
			smartstore.upsertSoupEntries(
					mobileTable,
					records,
					function(records) {
						console.log('back from upsert soup with records = ' + JSON.stringify(records));

						// Success callback.  Now we add proxy ids to our newly returned records that
						// will now have their _soupEntryId populated
						var epoch = new Date().getTime();
						syncRefresh.addProxyIds(
								mobileTable,
								records,
								epoch,
								function(proxyRecords) {

									console.log('back with proxy ids = ' + JSON.stringify(proxyRecords));

									// Success return from addProxy Ids.  Now we go through and add the
									// entries to the records to sync mobile table to ensure they are caught
									// in the next m2p update to Salesforce.
									var recsToSync = [];
									$j.each(proxyRecords, function(i,proxyRecord) {

										// Create the rec to sync record
										var recToSync = {
												Mobile_Table_Name : mobileTable,
												CRUD_Operation : "Insert",
												SOUP_Record_Id : proxyRecord._soupEntryId,
												Id : proxyRecord.Id,
												LastModifiedDateTime : epoch};
										recsToSync.push(recToSync);
									}); // end loop through the returned proxy recs

									// console.log('Calling upsert recs to sync -> ' + JSON.stringify(recsToSync));
									smartstore.upsertSoupEntriesWithExternalId(
											'recsToSync',
											recsToSync,
											"Id",
											success,

											error);
								},
								error);
					},
					error);
		} // end insertRecords


		/**
		 * fillOutRecords :returns promise records array.Takes an array of partial records,
		 * reads the current details from the DB and returns an updated array of full records
		 * @param {string} mobileTable The table
		 * @param {[rec]} records An array of records
		 * @param {string} idFieldName The field to be used as index
		 */
		function fillOutRecords(mobileTable, records, idFieldName) {
			var expectedCBs = records.length;
			var rcvdCBs = 0;
			return new Promise(function(resolve, reject) {
				$j.each(records, function(i,record) {
					queryMobileTable(mobileTable,idFieldName,record[idFieldName]).then(function(curRecs){
						if (curRecs.length > 0) {
							var curRec = curRecs[0];
							for (var attribute in record) {
								curRec[attribute] = record[attribute];
							}
							records[i] = curRec;
							rcvdCBs++;
							if (rcvdCBs >= expectedCBs) {
								resolve(records);
							}
						} else {
							// MSD-289 Could be that we've been passed a ProxyID, so check that too
							// console.debug("checking the Proxy field");
							if ( idFieldName == "Id" && record.Id.length > 18 ) {
								// MSD-364 - TODO - unit tests to use non-packaged tables too.
								var proxyFieldName =  (_.indexOf(MC_TABLES, mobileTable) > -1) ?
									'mobilecaddy1__MC_Proxy_ID__c' : 'MC_Proxy_ID__c';
								queryMobileTable(mobileTable, proxyFieldName, record.Id).then(function(curRecs){
									if (curRecs.length > 0) {
										var curRec = curRecs[0];
										for (var attribute in record) {
											if (attribute != "Id") curRec[attribute] = record[attribute];
										}
										records[i] = curRec;
										rcvdCBs++;
										if (rcvdCBs >= expectedCBs) {
											resolve(records);
										}
									} else {
										reject({status : 101107});
									}
								});
							} else {
								reject({status : 101107});
							}
						}
					}).catch(function (error) {
						reject(error);
					});
				});
			});
		}

		// This function takes a mobile table name and a list of (partial)records and it updates
		// the records. In addition it places the record in the records to sync mobile table.
		// The record finds the record to updated using the idFieldName
		function updateRecordsWithExternalId(mobileTable, records, idFieldName, success, error) {

			var syncRefresh = require('mobileCaddy/syncRefresh');

			// populate partial records with info from SmartStore
			fillOutRecords(mobileTable, records, idFieldName).then( function(filledRecs) {
				// console.debug('filledRecs', filledRecs);
				// Direct cordova call to insert the records
				smartstore.upsertSoupEntriesWithExternalId(
					mobileTable,
					filledRecs,
					idFieldName,
					function(records) {

						// Fetch records from recs to sync where the mobile table name is the same
						// as the one we are working on.  This enables us to set a correct CRUD Operation
						queryMobileTable(
								'recsToSync',
								'Mobile_Table_Name',
								mobileTable,
								function(foundRecsToSync) {

									// Now we go through and add the
									// entries to the records to sync mobile table to ensure they are caught
									// in the next m2p update to Salesforce.
									var recsToSync = [];
									$j.each(records, function(i,record) {

										// If we have a record already in the recs to sync then we need to update it
										// with the modstamp and possibly with a new CRUD Operation
										var existingRecToSync;
										$j.each(foundRecsToSync, function(i,foundRecToSync) {
											if (foundRecToSync.Id == record.Id) {
												existingRecToSync = foundRecToSync;
												return;
											} // end check for match on the Id
										}); // end loop until found rec to sync

										// Default the crud to 'Insert'.  It gets this when there is no existing matching
										// record to sync
										var crudOperation;
										if (typeof existingRecToSync !== 'undefined'){
											console.log("existingRecToSync", existingRecToSync);
											if (typeof(existingRecToSync.Current_Connection_Session) !== 'undefined') {
												switch (existingRecToSync.CRUD_Operation) {
													case "Insert" :
													case "InsertUpdate" :
														crudOperation = 'InsertUpdate';
														break;
													default :
														crudOperation = 'UpdateUpdate';
												}
											} // end connection session found check if
											else {
												// Could be either an insert or an update at this stage
												// We need only to update the date/time
												crudOperation = existingRecToSync.CRUD_Operation;
											} // end connection session found check else
										} // end record found already check if
										else {
											// No existing record to sync found
											// so we create one with stage update
											crudOperation = 'Update';
										} // end record found already check else

										// Create the rec to sync record
										var recToSync = {
												Mobile_Table_Name : mobileTable,
												SOUP_Record_Id : record._soupEntryId,
												Id : record.Id,
												CRUD_Operation : crudOperation,
												LastModifiedDateTime : record.SystemModstamp
										}; // recToSync

										// MSD-379 - This was missing, causing the rec to not be handled in the m2p resp handling.
										if (crudOperation == 'InsertUpdate') {
											recToSync.Current_Connection_Session = existingRecToSync.Current_Connection_Session;
										}

										recsToSync.push(recToSync);
									}); // end loop through the returned proxy recs

									smartstore.upsertSoupEntriesWithExternalId(
											'recsToSync',
											recsToSync,
											"Id",
											success,
											error);
								},
								error);
					},
					error);
			}).catch(function(err) {
				error(err);
			});
		} // end updateRecords

		// Exposed functions
		module.exports = {

			// Mobile table order literals.  These specify the order that the mobile
			// tables are returned in
			NONE : NONE,
			ALPHA : ALPHA,
			BUILD : BUILD,

			// List the names of the soups(mobile tables) in the smartstore.  Have
			// to specify one of the above literals for the ordering
			listMobileTables : function(order,success,error) {
				listMobileTables(order,success,error);
			},

			// Literals for the mobile table column build type
			// LIST will return an array of the names (text strings)
			// BUILD_OBJECT will return an array of objects ready to put into the smartstore for table creation
			LIST : LIST,
			BUILD_OBJECT : BUILD_OBJECT,
			FULL : FULL,

			// List the names of the columns in the given mobile table
			listMobileTableColumns : function(tableName,listType,success,error) {
				listMobileTableColumns(tableName,listType,success,error);
			},

			// Query mobile table
			queryMobileTable : function(soupName,col,val,success,error) {
				return queryMobileTable(soupName,col,val,success,error);
			},

			// Called to create the mobile tables.  The assumptions are that the mobile tables are
			// not already present and their definitions have already been downloaded to the system
			// data soup
			buildMobileTables : function(success,error) {
				buildMobileTables(success,error);
			}, // end buildMobileTable

			// Function that takes the system data row type (e.g. Row Mapping PT, Row Mapping TC) and the
			// system data row values (e.g. Mobile Table Name) and returns the column name in the sys
			// data soup that contains the data
			getSysDataRowMapColHeading : function(sysDataRowType, sysDataRowValue, success,error) {
				getSysDataRowMapColHeading(sysDataRowType, sysDataRowValue, success,error);
			},

			getSysDataRowMapColHeadings : function(sysDataRowType, sysDataRowValues,success,error) {
				getSysDataRowMapColHeadings(sysDataRowType,sysDataRowValues,success,error);
			},

			// For a given table and heading type (e.g. snapshot required, refresh date/times etc)
			// get the value and pass to the success callback function
			getTableDefnColumnValue : function(tableName,headingType,success,error) {
				getTableDefnColumnValue(tableName,headingType,success,error);
			},

			// For a given table and heading type (e.g. snapshot required, refresh date/times etc)
			// set the value
			setTableDefnColumnValue : function (tableName,headingType,valueToSet,success,error) {
				setTableDefnColumnValue(tableName,headingType,valueToSet,success,error);
			},

			// Convenience method as 'and' is not available for standard calls
			// and currently not in smartsql in mock smart store
			// TODO : Are smartSql queries now available?
			queryMobileTableWithAnd : function(soupName,col1,val1,col2,val2,success,error) {
				queryMobileTableWithAnd(soupName,col1,val1,col2,val2,success,error);
			},

			smartQuerySoupRecordsWithQuerySpec : function(smartQuerySpec,success,error) {
				smartQuerySoupRecordsWithQuerySpec(smartQuerySpec,success,error);
			},

			// Insert records.  This takes a list of records together with the mobile table name.  It
			// puts the records into the mobile table, generates and complements them with their MC_Proxy_ID__c
			// and additionally creates an entry in the records to sync mobile table so they go up to
			// Salesforce in the next m2pUpdate
			insertRecords : function (mobileTable, records, success, error) {
				insertRecords(mobileTable, records, success, error);
			},

			// Update records.  This takes a list of records together with the mobile table name.  It
			// updates the records into their mobile table
			// and creates an entry in the records to sync mobile table so they go up to
			// Salesforce in the next m2pUpdate
			updateRecordsWithExternalId : function (mobileTable, records, idFieldName, success, error) {
				updateRecordsWithExternalId(mobileTable, records, idFieldName, success, error);
			},

			// Mark the given soup for a one off sync
			markSoupToSync: function(soupName,success,error) {

				var querySpec = smartstore.buildExactQuerySpec("Type", mobileCaddy.DYNAMIC_DATA_OBJECT, mobileCaddy.QUERY_BUFFER_SIZE_SL);
				querySoupRecordsWithQuerySpec(
						'syncLib_system_data',
						querySpec,
						success,
						function (recs) {
							for (var i=0;i<recs.length;i++) {
								if (recs[i].Name == soupName) {
									recs[i].Refresh_Indicator = 'Once';
									smartstore.upsertSoupEntries(
											'syncLib_system_data',
											[recs[i]],
											success,
											error);
									break;
								} // end check for named soup if
							} // end loop through recs for
						},
						error);
			}, // end markSoupToSync

			// Delete the named soup and recreate it - thus emptying it out
			emptySoup: function(soupName,success,error) {
    		var smartStoreUtils = mobileCaddy.require('mobileCaddy/smartStoreUtils');
				smartstore.removeSoup(	soupName,
											function() {
												smartStoreUtils.createSoup(
														soupName,
														success,
														error);
											},
											error);
			}, // end emptySoup


			// Delete the named soup and recreate it - thus emptying it out
			emptySoupPromise: function(soupName) {
    		return new Promise(function(resolve, reject) {
    		var smartStoreUtils = mobileCaddy.require('mobileCaddy/smartStoreUtils');
				var logger = require('mobileCaddy/logger');
					smartstore.removeSoup(soupName,
						function() {
							smartStoreUtils.createSoup(
								soupName,
								function() {
									console.debug('emptySoupPromise', soupName);
									resolve();
								},
								function(e){
									logger.error('emptySoupPromise', e);
									reject(e);
								});
						},
						function(e){
							logger.error('emptySoupPromise', e);
							reject(e);
						});
				});
			}, // end emptySoup

			// Delete the named soup and recreate it - thus emptying it out
			deleteSoup: function(soupName) {
  			console.debug('deleteSoup', soupName);
    		return new Promise(function(resolve, reject) {
	    		var smartStoreUtils = mobileCaddy.require('mobileCaddy/smartStoreUtils');
	    		var logger = require('mobileCaddy/logger');
					smartstore.removeSoup(	soupName,
						function() {
							logger.log('deleteSoup', soupName);
							resolve();
						},
						function(e){
							logger.error('deleteSoup', e);
							reject(e);
						});
				});
			}, // end deleteSoup

			// Creates the soup given by the soup name parameter.  Uses the definitions that must
			// be in the system data soup
			createSoup : function(soupName,success,error) {
				getSoupDefinitionRows(
						soupName,
						function(definitionRows) {
							getQueryAndSoupDefinition(
									definitionRows,
									function(queryString,columnDefinitions) {
										// Returns dynamic query string to get the data together with
										// the column definitions in structure for creating the soup
									    smartstore.registerSoup(	soupName,
					                            					columnDefinitions,
					                            					function(param) {
									    								success();
									    							},
					                            					error);
										},
										error);
							},
							error);
			},

			// Query all records for the given soup.  Function will deal with building the query
			// spec and dealing with the cursor on return
			querySoupRecords: function(soupName,success,error) {
				querySoupRecords(soupName,success,error);
			}, // end querySoupRecords

			querySoupRecsPromise: function(soupName) {
				return querySoupRecsPromise(soupName);
			},

			querySoupRecordsWithQuerySpec: function(soupName,querySpec,success,error) {
				querySoupRecordsWithQuerySpec(soupName,querySpec,success,error);
			}, // end querySoupRecordsWithQuerySpec

			// Compares the backend version from salesforce and the current device version
			compareVersions: function(success,error) {
				var querySpec = cordova.require("com.salesforce.plugin.smartstore").buildExactQuerySpec("Name",mobileCaddy.VERSION_ID,mobileCaddy.QUERY_BUFFER_SIZE);
				querySoupRecordsWithQuerySpec(
						'syncLib_system_data',
						querySpec,
						function(records) {
							simpleMessageSL('Version in soup = ' + records[0].Value);
							getVersion(
									function(version) {
										simpleMessageSL('Version in Salesforce = ' + version);
										success();
									},
									error);
						},
						error);
			}, // end updateInternalIdFields

			// This function deletes the given records from the given table.  The externalId
			// parameter indicates which column in the record set uniquely identifies the record
			// in the mobile table.
			deleteRecordsForExternalId : function(tableName,records,externalId,success,error) {
				deleteRecordsForExternalId(tableName,records,externalId,success,error);
			},

			// This function deletes the list of current records from the given soup
			// Deals with an empty list by directly calling the callback function
			deleteRecordsFromSoup : function(records,soupName,success,error) {
				deleteRecordsFromSoup(records,soupName,success,error);
			}, // end deleteRecordsFromSoup

			refreshSnapshot : function(tableName,success,error) {
				refreshSnapshot(tableName,success,error);
			}
		}; // end exports
	}); // end smartStoreUtils define

	// ================================ //
	// App Data Utilities               //
	// ================================ //
	define("mobileCaddy/appDataUtils", function(require, exports, module) {

		// Get required modules
		var mobileLogger = require('mobileCaddy/mobileLogger');
		var smartstore = cordova.require("com.salesforce.plugin.smartstore");
		var smartStoreUtils = require('mobileCaddy/smartStoreUtils');

		// Lookup the given variable name (name column) in the app data soup
		// and return the current value
		function getCurrentValueFromAppSoup(variableName,success,error) {
			var querySpec = smartstore.buildExactQuerySpec("Name", variableName, mobileCaddy.QUERY_BUFFER_SIZE);
			if (typeof(success) == "undefined" && typeof(error) == "undefined") {
				// run as a promise
    		return new Promise(function(resolve, reject) {
    			smartStoreUtils.querySoupRecordsWithQuerySpec(
						'appSoup',
						querySpec,
						function(appSoupRecs) {
							resolve(appSoupRecs[0].CurrentValue);
						},
						function(e) {
							reject(e);
						}
					);
    		});
			} else {
				// run with callback
				smartStoreUtils.querySoupRecordsWithQuerySpec(
						'appSoup',
						querySpec,
						function(appSoupRecs) {
							if (typeof(appSoupRecs[0]) != "undefined") {
								success(appSoupRecs[0].CurrentValue);
							} else {
								error();
							}
						},
						error);
			}
		} // end getCurrentValueFromAppSoup


		function updateValueInAppSoup(name, val, type){
  		return new Promise(function(resolve, reject) {
     		var buildStatusQuerySpec = smartstore.buildExactQuerySpec("Name", name, mobileCaddy.QUERY_BUFFER_SIZE);
				smartStoreUtils.querySoupRecordsWithQuerySpec(
					'appSoup',
						buildStatusQuerySpec,
						function(appRec) {
							appRec[0][type] = val;
							smartstore.upsertSoupEntries(
								'appSoup',
								appRec,
								function(resObject) {
									resolve(resObject);
								},
								function(e){
									reject(e);
								}
							);
						},
						function(e){
							reject(e);
						}
				);
			});
		}

		// Exposed functions
		module.exports = {

			getCurrentValueFromAppSoup : function(variableName,success,error) {
				return getCurrentValueFromAppSoup(variableName,success,error);
			},
			updateNewValueInAppSoup : function(name, newValue){
				return updateValueInAppSoup(name, newValue, 'NewValue');
			},
			updateCurrentValueInAppSoup : function(name, curValue) {
				return updateValueInAppSoup(name, curValue, 'CurrentValue');
			}
		};
	}); // end appDataUtils

	// ================================ //
	// Sync/Refresh Utilities           //
	// ================================ //
	define("mobileCaddy/syncRefresh", function(require, exports, module) {

		// Required modules
		var appDataUtils    = require('mobileCaddy/appDataUtils');
		var vsnUtils        = require('mobileCaddy/vsnUtils');
		var smartStoreUtils = require('mobileCaddy/smartStoreUtils');
		var mobileLogger    = require('mobileCaddy/mobileLogger');
		var logger          = require('mobileCaddy/logger');
		var smartstore      = cordova.require("com.salesforce.plugin.smartstore");
		var connSessUtils   = require('mobileCaddy/connSessUtils');

		// Function is called when m2pRefresh gets its response.
		// Note that response format is like this
		/*{
			   "records":[
			      {
			         "recordData":{
			            "Allow_Stock_Take__c":"false",
			            ....... (all record fields)
			         },
			         "RecordCRUD":"U"
			      },
			      ... (more records)
			   ],
			   "lastRefreshDatetime":1402736904069,
			   "snapShot":"Y",
			   "mt":"Vehicles__ap",
			   "cs":"a2gR0000000aAELIA2",
			   "cp":"PROXY%Connection_Session__mc%1402736903343%2%a2eR0000000Jv5zIAC"
			}*/
		function handleRefreshResponse(jsonString,success,error) {

			// Status returned is 0 (success)
			// Additional status values:
			// null - no issues
			// 1 - means RTS changed for our table during processing - changes abandoned
			var returnObject = {};

			// First convert from json into js objects
			mobileLogger.logMessage('Parse json date time');

			// new line and carriage return replacements
			var globalRegEx = new RegExp('\n','g');
			jsonString = jsonString.replace(globalRegEx,'\\n');
			globalRegEx = new RegExp('\r','g');
			jsonString = jsonString.replace(globalRegEx,'');

			var jsonObject = $j.parseJSON(jsonString);
			mobileLogger.logMessage('Parse json date time done');
			console.log('json object date time = ' + jsonObject.lastRefreshDatetime);

			// First we need to scan the RTS for our records. Break into 2 sets
			// by CRUD - insert/insert update is
			var proxyIdObject = {};
			var sfIdObject = {};

			// Validate we have table name in the response json
			var mobileTableName = jsonObject.mt;
			if (mobileTableName === null) {
				mobileLogger.logMessageAndThrow("Mobile Table (tag 'mt') empty in p2mRefresh response: " + jsonString);
			} // end validate mobile table present check if

			var querySpec = smartstore.buildExactQuerySpec("Mobile_Table_Name", mobileTableName, mobileCaddy.QUERY_BUFFER_SIZE);
			smartStoreUtils.querySoupRecordsWithQuerySpec(
					'recsToSync',
					querySpec,
					function(recsToSyncRecords) {
						$j.each(recsToSyncRecords, function(i,recToSyncRecord) {
							if ((recToSyncRecord.CRUD_Operation == 'Insert') || (recToSyncRecord.CRUD_Operation == 'InsertUpdate')) {
								proxyIdObject[recToSyncRecord.Id] = 1;
							} // end insert check if
							else {
								// non inserts check if
								if ((recToSyncRecord.CRUD_Operation == 'Update') || (recToSyncRecord.CRUD_Operation == 'UpdateUpdate')) {
									sfIdObject[recToSyncRecord.Id] = 1;
								} // end non insert check if
								else {

									// Throw error for unsupported type - really to get our attention during development
									mobileLogger.logMessageAndThrow("RTS contains record with non support CRUD Operation" + recToSyncRecord);
									return;
								} // end non insert check else
							} // end insert check else
						}); // end loop through recs to sync each

						// From the incoming records, filter out records where there are RTS matches and throw them away
						// Note that a record contains the actual record plus recordCRUD - see example at function header.
						var recordsToUpsert = [];
						var recordsToDelete = [];
						$j.each(jsonObject.records, function(i,record) {

							// See if the record proxy is in our proxy set
							var useRecord = true;
							if (_.indexOf(MC_TABLES, mobileTableName) > -1){
								if (record.recordData.mobilecaddy1__MC_Proxy_ID__c !== null) {
									if (proxyIdObject.hasOwnProperty(record.recordData.mobilecaddy1__MC_Proxy_ID__c)) {
										useRecord = false;
									} // end proxy id present in proxy object check if
								} // end incoming proxy present check if
							} else {
								if (record.recordData.MC_Proxy_ID__c !== null) {
									if (proxyIdObject.hasOwnProperty(record.recordData.MC_Proxy_ID__c)) {
										useRecord = false;
									} // end proxy id present in proxy object check if
								} // end incoming proxy present check if
							}

							// See if the real proxy is on our set (only if we are
							// still intending to use this record
							if (useRecord) {
								if (sfIdObject.hasOwnProperty(record.recordData.Id)) {
									useRecord = false;
								} // end sfdc id present in sfId object check if
							} // end useRecord check if

							// Now put in filtered set if we are allowed
							// Note we put in the whole record (including the record CRUD)
							if (useRecord) {
								recordsToUpsert.push(record.recordData);
							} // end used record check if
						}); // end loop through response records each

						if (jsonObject.ds) {
							var dsIds = jsonObject.ds.oq.concat(jsonObject.ds.sd.concat(jsonObject.ds.hd.concat(jsonObject.ds.sh)));
							dsIds.forEach(function(IdToDel){
								if (!sfIdObject.hasOwnProperty(IdToDel)) {
									recordsToDelete.push({'Id' : IdToDel});
								} else {
									console.log("We have a dirty local version, not deleting");
								}
							});
						}

						// Now we are ready for the upserting/deleting.  Belt and Braces
						// we first check that the RTS has the same record count for our table.
						// If not we throw away the update
						var querySpec2 = smartstore.buildExactQuerySpec("Mobile_Table_Name", mobileTableName, mobileCaddy.QUERY_BUFFER_SIZE);
						smartStoreUtils.querySoupRecordsWithQuerySpec(
								'recsToSync',
								querySpec2,
								function(recsToSyncCheck) {

									// Only continue if counts are the same
									if (recsToSyncCheck.length == recsToSyncRecords.length) {

										// Remove recs from the mobile table.  Function deals with no records in the list.
										smartStoreUtils.deleteRecordsForExternalId(
												mobileTableName,
												recordsToDelete,
												'Id',
												function() {

													// Upsert records into the mobile table
													smartstore.upsertSoupEntriesWithExternalId(
															mobileTableName,
															recordsToUpsert,
															"Id",
															function() {

																// Deal with the snapshot if it exists
																smartstore.soupExists(
																		'SnapShot_' + mobileTableName,
																		function(soupExists) {
																			if (soupExists) {

																				// Remove same records from the snapshot (if there one)
																				smartStoreUtils.deleteRecordsForExternalId(
																						'SnapShot_'  + mobileTableName,
																						recordsToDelete,
																						'Id',
																						function() {

																							// Upsert snapshot entries
																							smartstore.upsertSoupEntriesWithExternalId(
																									'SnapShot_' + mobileTableName,
																									recordsToUpsert,
																									"Id",
																									function() {
																										vsnUtils.checkForMigrateToInfo(jsonObject);
																										// All good ! Return success.
																										returnObject.status = 0;
																										returnObject.cs = jsonObject.cs;
																										returnObject.cp = jsonObject.cp;
																										returnObject.lastRefreshDatetime = jsonObject.lastRefreshDatetime;
																										success(returnObject);
																									},
																									error);
																						},
																						error);
																			} // end soup exists check if
																			else {

																				// All good ! Return success.
																				vsnUtils.checkForMigrateToInfo(jsonObject);
																				returnObject.status = 0;
																				returnObject.lastRefreshDatetime = jsonObject.lastRefreshDatetime;
																				returnObject.cs = jsonObject.cs;
																				returnObject.cp = jsonObject.cp;
																				success(returnObject);
																			} // end soup exists check else
																		},
																		error);
															}, // end upsert success callback
															error); // end upsert soup entries
												},
												error);
									} // end recs to sync length check if
									else {
										// Call the success callback with status
										// of success.  Give additional info signifying we
										// abandoned hope
										returnObject.status = 0;
										returnObject.mc_add_status = 1;
										returnObject.cs = jsonObject.cs;
										returnObject.cp = jsonObject.cp;
										returnObject.lastRefreshDatetime = jsonObject.lastRefreshDatetime;
										success(returnObject);
									} // end recs to sync length check else
								},
								error);
					}, // end recs to sync success callback
					error); // end query rts soup
		} // end handleRefreshResponse

		// Refreshes given mobile table from Salesforce
		var P2M_REFRESH_OK = 100500;
		var SYNC_NOK       = 100402;
		function p2mRefreshTable(tableName,maxTableAge, cleanCSFlag,success,error) {
			var returnObject = {};

			mobileLogger.logMessage('Refreshing table = ' + tableName);

			// Create connection session - this gives us the record including geolocation plus the json
			buildConnectionSession(
					'Sync - Refresh',
					'P2M RE Process Called',
					function(connSessObject) {
						//console.debug("connSessObject -> " +JSON.stringify(connSessObject));
						// Get the dynamic version
						appDataUtils.getCurrentValueFromAppSoup(
								'audId',
								function(audId) {

									mobileLogger.logMessage('Using app data aud id = ' + audId);

									// Get the sync refresh version
									appDataUtils.getCurrentValueFromAppSoup(
											'syncRefreshVersion',
											function(syncRefreshVersion) {

												mobileLogger.logMessage('Using app data syncRefreshVersion = ' + syncRefreshVersion);

												// Get the last refresh date/time for the mobile table
												smartStoreUtils.getTableDefnColumnValue(
														tableName,
														'Last Refresh Date/Time',
														function(lastRefreshDatetime) {

															// If the last refresh date/time is not present then this must
															// be the first run so use the epoch itself (zero)
															if ((lastRefreshDatetime === null) || (lastRefreshDatetime === '')) lastRefreshDatetime = 0;

															mobileLogger.logMessage('Using lastRefreshDatetime = ' + lastRefreshDatetime);
															console.debug('maxTableAge', maxTableAge);
															var timeNow = new Date();
															if (lastRefreshDatetime < (timeNow - maxTableAge)) {


																// NOTE - for now not passing up any 3rd part json
																var thirdPartyJson = '';

																// Now we can make the refresh call
																console.log('last refresh date/time is ' + lastRefreshDatetime);
																var p2mRefreshSuccFun = function(jsonString, event) {

																	console.debug('jsonString', jsonString);
																	console.debug('event', event);
																	if (event.status) {

																		mobileLogger.logMessage("In success callback from remoting 'refreshTable' call");
																		console.debug('returned json = ' + jsonString);
																		handleRefreshResponse(
																			jsonString,
																			function(handleRefreshResultObject){

																				console.log('handle refresh res = ' + handleRefreshResultObject.status);
																				console.log(handleRefreshResultObject.mc_add_status);
																				// console.log('### b RTS', localStorage.getItem('recsToSync'));
																				// console.log('### b CS', localStorage.getItem('Connection_Session__mc'));
																				// console.log('### b SCS', localStorage.getItem('SnapShot_Connection_Session__mc'));

																				// Now refresh is complete, update the last refresh date/time
																				smartStoreUtils.setTableDefnColumnValue(
																						tableName,
																						'Last Refresh Date/Time',
																						handleRefreshResultObject.lastRefreshDatetime,
																						function() {
																							console.log('Success from update last refresh date time');

																							// Check for abandoned
																							var mobileProcessStatus = 'P2M RE Records Processed';
																							if (tableName == 'Connection_Session__mc') {
																								mobileProcessStatus = 'P2M Conn_Sess Records Processed';
																							}
																							if (handleRefreshResultObject.mc_add_status == 1) {
																								mobileProcessStatus = 'P2M RE Abandoned';
																							} // end abandoned check if

																							// Close the connection session
																							// Update the proxy with the salesforce id passed down
																							connSessObject.connSessionRec.mobilecaddy1__Mobile_Process_Status__c = mobileProcessStatus;
																							connSessObject.connSessionRec.Id = handleRefreshResultObject.cs;

																							// Update the connection session, create a snapshot and put in recs to sync
																							connSessUtils.postProcessConnectionSession(
																								connSessObject.connSessionRec,
																								function() {
																									console.log('success return from post process');
																									if (cleanCSFlag) {
																										connSessUtils.maybeSyncConnSess(connSessObject.connSessionRec,
																											function(){
																												console.log('success return from maybeSyncConnSess');
																												// console.log('### e RTS', localStorage.getItem('recsToSync'));
																												// console.log('### e CS', localStorage.getItem('Connection_Session__mc'));
																												// console.log('### e SCS', localStorage.getItem('SnapShot_Connection_Session__mc'));
																												returnObject.status = P2M_REFRESH_OK;
																												success(returnObject);
																											},
																											error);
																									} else {
																										returnObject.status = P2M_REFRESH_OK;
																										success(returnObject);
																									}
																								},
																								error);
																					},
																					error);
																				}
																			); // end handleRefreshResponse
																		}
																		else {
																			if (event.type === 'exception') {
																				logger.error('p2mRefresh', tableName, event.message, event.where);
																			}
																			connSessUtils.cleanConnectionSessionVFEvent(
																					event,
																					connSessObject,
																					function(cleanReturnObject) {
																						returnObject.status = SYNC_NOK;
																						returnObject.mc_add_status = cleanReturnObject.mc_add_status;
																						success(returnObject);
																					},
																					error);
																		} // end success else
																	}; // p2mRefreshSuccFun
																	// TODO : RIP OUT REMOTING OPTION
																	// console.log('### a RTS', localStorage.getItem('recsToSync'));
																	// console.log('### a CS', localStorage.getItem('Connection_Session__mc'));
																	// console.log('### a SCS', localStorage.getItem('SnapShot_Connection_Session__mc'));
																	if ( USE_FORCETK === true ) {
																		force.request(
													            {
													                method: 'POST',
													                path: '/services/apexrest/mobilecaddy1/' + 'p2mRefreshTable001',
													                contentType : 'application/json',
													                data: {
													                    "audId" : audId,
													                    "startPageControllerVersion" : mobileCaddy.START_PAGE_CONTROLLER_VSN,
													                    'syncRefreshDataVersion': syncRefreshVersion,
													                    'mobileTableName': tableName,
													                    'deviceRefreshIds' : [],
													                    'lastRefreshDateTime' : lastRefreshDatetime,
													                    'thirdPartyJson' : thirdPartyJson,
													                    'connSessJson' : connSessObject.connSessJson
													                    },
													            },
													            function(response, event) {
													            	if  ( typeof(event) == 'undefined') {
													            		event  = {};
													            		event.status = "200";
													            	}
													            	p2mRefreshSuccFun(response, event);
													            },
													            error);
																	} else {
																	Visualforce.remoting.Manager.invokeAction('mobilecaddy1.' +
																			mobileCaddy.START_PAGE_CONTROLLER + '.p2mRefreshTable',
																			audId,
																			syncRefreshVersion,
																			tableName,
																			[],
																			lastRefreshDatetime,
																			thirdPartyJson,
																			connSessObject.connSessJson,
																			p2mRefreshSuccFun,
																			//{escape:false, timeout:30000});
																			{buffer: false, escape:false, timeout:120000});
																	}
																} else {
																	// table isn't old enough to refresh
																	console.log('Not refreshing table. it is too young');
																	returnObject.status        = 100402;
																	returnObject.status = 100497;
																	success(returnObject);
																}
														},
														error);
											},
											error);
								},
								error);
					},
					error);
		} // end p2mRefreshTable

		// Generate a proxy id for new records
		function genProxyId(tableName,soupEntryId,insertDateTime,success,error) {

			// Need the aud id as this forms part of the proxy id
			appDataUtils.getCurrentValueFromAppSoup(
					'audId',
					function(audId) {
						var proxyId = 'PROXY%' + tableName + '%' + insertDateTime + '%' + soupEntryId + '%' + audId;
						success(proxyId);
					},
					error);
		} // end genProxyId

		// This routines is passed a set of created mobile table records.  It calculates a proxy id for each record
		// puts this in the Id and the MC_Proxy_ID__c fields and upserts back into the mobile table.
		function addProxyIds(tableName,records,insertDateTime,success,error) {

			// Need the aud id as this forms part of the proxy id
			appDataUtils.getCurrentValueFromAppSoup(
					'audId',
					function(audId) {
						$j.each(records, function(i,record) {
							var proxyId = 'PROXY%' + tableName + '%' + insertDateTime + '%' + record._soupEntryId + '%' + audId;
							record.Id = proxyId;
							if (_.indexOf(MC_TABLES, tableName) > -1){
								record.mobilecaddy1__MC_Proxy_ID__c = proxyId;
							} else {
								record.MC_Proxy_ID__c = proxyId;
							}
						});
						smartstore.upsertSoupEntries(
								tableName,
								records,
								function(updatedRecords) {
									success(updatedRecords);
								},
								error);
					},
					error);
		} // end addProxyIds

		// Helper method when processing an M2P update.  Deals with null values
		// as specified on the platform
		function nullHandler(tableName,fieldName,fullSoupRecord,fieldNullHandler) {
			var convertedValue;
			if (fieldNullHandler == 'Throw Exception') {
				throw "NULL value found for field " + fieldName + " in Mobile Table " + tableName + " with Id = " + fullSoupRecord.Id;
			} // end throw exception check if
			else {
				if (fieldNullHandler == 'Return NULL') {
					convertedValue = 'null';
				} // end return null check if
				else {
					if (fieldNullHandler == 'Return Empty String') {
						convertedValue = '';
					} // end empty string check if
				} // end return null check else
			} // end throw exception check else
			return convertedValue;
		} // end nullHandler

		// Helper method - creates the json string for the M2P Update call
		function createUpdateJson(tableName,columnRecs,tableColumnColumn,converterColumnName,nullHandlerColumnName,formatterColumnName,recsToSyncRecords,fullSoupRecords,snapShotRecords,connSessProxyId,success,error) {
			// Start forming the JSON response
			// JSON needs the mobile table name

			var globalRegEx = "";

			var jsonString = '{ "MobileTable" : "' + tableName + '",';

			// Add the connection session proxy id
			jsonString += '"connSessProxyId" : "' + connSessProxyId + '",';

			// Create the records json array
			jsonString += '"records" : [';

			function columnHandler(i,columnRec) {
							// Is this our column definition ?
							if (fieldName == columnRec[tableColumnColumn]) {
								console.log('Found field name = ' + fieldName);
								console.log('Null handler column name = ' + nullHandlerColumnName);
								fieldConverter = columnRec[converterColumnName];
								fieldFormatter = columnRec[formatterColumnName];
								fieldNullHandler = columnRec[nullHandlerColumnName];
								console.log('fieldConverter = ' + fieldConverter);
								// As found, jump out of the each
								return;
							} // end field mapping found check if
						}

			// Process each rec referenced in recs to sync.  Dig out the correcsponding real full width
			// record together with any corresponding snapshot record.
			$j.each(recsToSyncRecords, function(i,recsToSyncRecord) {


				// JSON for start of record
				jsonString += '{"RTSRowNum" : "' + recsToSyncRecord._soupEntryId + '","RecordCRUD" : "';

				console.log('Processing rec to syn with soup id = ' + recsToSyncRecord.SOUP_Record_Id);

				// For the currect record to sync, find the matching full width record
				$j.each(fullSoupRecords, function(i,fullSoupRecord) {

					// Match on the Salesforce ids
					if (recsToSyncRecord.Id == fullSoupRecord.Id) {

						// For a CRUD create, put the entire record in our create record set
						if ((recsToSyncRecord.CRUD_Operation == 'Insert') ||  (recsToSyncRecord.CRUD_Operation == 'InsertDelete')) {

							if (recsToSyncRecord.CRUD_Operation == 'Insert') {
								jsonString += 'I", "fields" : [';
							}
							else {
								jsonString += 'T", "fields" : [';
							}

							// For create we use all fields
							for (var fieldName in fullSoupRecord) {

								if (fieldName == "mobilecaddy1__Error_Text__c") { // MSD-359
									jsonString += '{ "name" : "' + fieldName + '","value" : ' + JSON.stringify(fullSoupRecord[fieldName]) + '},' ;
								} else // We only want to send up SObject fields so exclude the soup specific fields
								if ((fieldName != '_soupEntryId') && (fieldName != '_soupLastModifiedDate')) {

									console.log('fieldName', fieldName);

									var fieldConverter;
									var fieldFormatter = 'M2P UP None';
									var fieldNullHandler;

									// We need our converter, null handler and formatter for this field
									$j.each(columnRecs, function(i,columnRec) {

										// Is this our column definition ?
										if (fieldName == columnRec[tableColumnColumn]) {
											console.log('Found field name = ' + fieldName);
											console.log('Null handler column name = ' + nullHandlerColumnName);
											fieldConverter = columnRec[converterColumnName];
											fieldFormatter = columnRec[formatterColumnName];
											fieldNullHandler = columnRec[nullHandlerColumnName];
											//mobileLogger.logObjectDetails(fieldNullHandler);
											// As found, jump out of the each
											return;
										} // end field mapping found check if
									});

									// Final value - used when formatting, converting and dealing with null checking
									// We are always creating a string for going into the JSON but in some cases we
									// need to quote, unquote and some null values will be nulls or empty strings.
									var convertedValue;

									// Deal with any nulls
									if (fullSoupRecord[fieldName] === null) {

										convertedValue = nullHandler(tableName,fieldName,fullSoupRecord,fieldNullHandler);
									} // end null value check if
									else {

										// Not a null so do conversion here
										// Initialise with a direct copy
										convertedValue = fullSoupRecord[fieldName];

										// Deal with any field conversion if necessary
										// Initially nothing is being done here - for any future
										// expansion
										if (fieldConverter == 'M2P UP None') {
											convertedValue = fullSoupRecord[fieldName];
										} // end none check if
									} // end null check else


									// Do the field quoting/unquoting.  Only do something here if
									// we are quoted.  Other values leave the result alone
									if (fieldFormatter == 'M2P UP Quoted') {
										globalRegEx = new RegExp('"','g');
										convertedValue = convertedValue.replace(globalRegEx,'\\"');
										convertedValue = '"' + convertedValue + '"';
									} // end quoting check if

									// replace new line chars for
									if (typeof(convertedValue) == "string") {
										globalRegEx = new RegExp('\n','g');
										convertedValue = convertedValue.replace(globalRegEx,'\\n');
										globalRegEx = new RegExp('\r','g');
										convertedValue = convertedValue.replace(globalRegEx,'\\r');
									}

									// Create the JSON, no previous value as in an update
									jsonString += '{ "name" : "' + fieldName + '","value" : ' + convertedValue + '},' ;
								}
							} // end loop through the object fields

							// Remove the trailing comma from the records list
							jsonString = jsonString.substring(0, jsonString.length - 1);

						} // end create record check if
						else {

							// Check for update/delete.  In this case we need to check field by field
							if ((recsToSyncRecord.CRUD_Operation == 'Update') || (recsToSyncRecord.CRUD_Operation == 'Delete') || (recsToSyncRecord.CRUD_Operation == 'UpdateDelete')) {

								// Capture the update/delete record
								if (recsToSyncRecord.CRUD_Operation == 'Update') {
									jsonString += 'U", "fields" : [';
								} // end update check if
								else {
									if (recsToSyncRecord.CRUD_Operation == 'Delete') {
										jsonString += 'D", "fields" : [';
									}
									else {
										jsonString += 'Q", "fields" : [';
									}
								} // end update check else

								// Update and delete, we need to find out which fields have changed
								// For this get the corresponding snap shot record
								$j.each(snapShotRecords, function(i,snapShotRecord) {
									if (snapShotRecord.Id == fullSoupRecord.Id) {

										// Prepare JSON for this record.  Don't add directly to the overall json string
										// because if no fields have changed we will bail on this recrd.  First add the id
										// which (of course) has same previous and current values
										var recordJSON = '{ "name" : "Id", "previousValue" : "' + snapShotRecord.Id + '","value" : "' + snapShotRecord.Id + '"},' ;

										// Go through the fields and determine which have changed.
										// Id has been put in already but cannot have changed so
										// won't be processed a second time!
										var fieldDifferenceFound = false;
										for (var fieldName in fullSoupRecord) {

											// Filter out smartstore specific fields
											if ((fieldName != '_soupEntryId') && (fieldName != '_soupLastModifiedDate')) {

												// If the fields differ then record the full soup record value (new value)
												// MSD-379 - Also always include SystemModstamp
												if (fullSoupRecord[fieldName] != snapShotRecord[fieldName] || fieldName == 'SystemModstamp') {
													fieldDifferenceFound = true;

													// We need our converter, null handler and formatter for this field
													$j.each(columnRecs, function(i,columnRec) {

														// Is this our column definition ?
														if (fieldName == columnRec[tableColumnColumn]) {
															fieldConverter = columnRec[converterColumnName];
															fieldFormatter = columnRec[formatterColumnName];
															fieldNullHandler = columnRec[nullHandlerColumnName];

															console.log('fieldConverter = ' + fieldConverter);
															// As found, jump out of the each
															return;
														} // end field mapping found check if
													});

													// Final value - used when formatting, converting and dealing with null checking
													// We are always creating a string for going into the JSON but in some cases we
													// need to quote, unquote and some null values will be nulls or empty strings.
													var convertedValue;
													var previousConvertedValue;

													// Do null checking if necessary
													if (fullSoupRecord[fieldName] === null) {
														convertedValue = nullHandler(tableName,fieldName,fullSoupRecord,fieldNullHandler);
														previousConvertedValue = nullHandler(tableName,fieldName,snapShotRecord,fieldNullHandler);
													} // end null value check if
													else {

														// Deal with any field conversion if necessary
														// Initially nothing is being done here - for any future
														// expansion
														if (fieldConverter == 'M2P UP None') {
															convertedValue = fullSoupRecord[fieldName];
															previousConvertedValue = snapShotRecord[fieldName];
														} // end none check if
													} // end null check else

													// Do the field quoting/unquoting.  Only do something here if
													// we are quoted.  Other values leave the result alone
													if (fieldFormatter == 'M2P UP Quoted') {
														globalRegEx = new RegExp('"','g');
														if (convertedValue !== null && typeof(convertedValue) !== "undefined") {
															convertedValue = convertedValue.replace(globalRegEx,'\\"');
															convertedValue = '"' + convertedValue + '"';
														}
														if (previousConvertedValue !== null && typeof(previousConvertedValue) !== "undefined") {
															previousConvertedValue = previousConvertedValue.replace(globalRegEx,'\\"');
															previousConvertedValue = '"' + previousConvertedValue + '"';
														}
													} // end quoting check if

													// replace new line chars for
													if (typeof(convertedValue) == "string") {
														// globalRegEx = new RegExp('\\n','g');
														// convertedValue = convertedValue.replace(globalRegEx,'\\n');
														globalRegEx = new RegExp('\n','g');
														convertedValue = convertedValue.replace(globalRegEx,'\\n');
														globalRegEx = new RegExp('\r','g');
														convertedValue = convertedValue.replace(globalRegEx,'\\r');
													}
													if (typeof(previousConvertedValue) == "string") {
														// globalRegEx = new RegExp('\\n','g');
														// previousConvertedValue = previousConvertedValue.replace(globalRegEx,'\\n');
														globalRegEx = new RegExp('\n','g');
														previousConvertedValue = previousConvertedValue.replace(globalRegEx,'\\n');
														globalRegEx = new RegExp('\r','g');
														previousConvertedValue = previousConvertedValue.replace(globalRegEx,'\\r');
													}

													// Create the json for this before/after image
													recordJSON += '{ "name" : "' + fieldName + '", "previousValue" : ' + previousConvertedValue + ',"value" : ' + convertedValue + '},' ;
												} // end field differ check if
											} // end filter out smartstore specific names if
										} // end loop through the object fields

										// If at least one field has changed, then add the JSON
										// for the record to the overall list
										if (fieldDifferenceFound) {

											// Remove the trailing comma from the records list
											recordJSON = recordJSON.substring(0, recordJSON.length - 1);

											// Add to the overall json
											jsonString += recordJSON;
										} // end field difference found
										// Return as we found the match - no point
										// continuing through snapShot records for another!
										return;
									} // end match found if
								}); // end loop through snapShot records each
							} // end update/delete CRUD check if
							else {
								throw "Rec to sync with Id = " + recsToSyncRecord.Id + " has invalid CRUD Operation = " + recsToSyncRecord.CRUD_Operation;
							} // end update/delete CRUD check else
						} // end create record check else

						// End the fields list in the JSON
						jsonString += ']';

						// End the record in the json
						jsonString += '},';

						// Have now found and processed the full soup record for the current recs
						// to sync record.  Return so we don't try to find more full soup records
						// for the same sync record - there won't be any!
						return;
					} // end match found on soup record if
				}); // end loop through full soup records each
			}); // end loop through recs to sync each

			// Remove the trailing comma from the records list
			jsonString = jsonString.substring(0, jsonString.length - 1);

			// End the record array and terminate the json string
			jsonString += ']}';
			success(jsonString);
		} // end createUpdateJson helper method

		// Mark the provided recs to sync with the connection session proxy id
		function markRecsToSyncWithProxy(recsToSyncRecords, connSessProxyId,success,error) {
			$j.each(recsToSyncRecords, function(i,recToSyncRecord) {
				recToSyncRecord.Current_Connection_Session = connSessProxyId;
			}); // end each

			// Update recs to sync with the updated records
			// console.log('### d2 RTS', recsToSyncRecords);
			//smartstore.upsertSoupEntries(
			// MSD-219 spotted this bug I think. Line above replaced with the one below
			smartstore.upsertSoupEntriesWithExternalId(
					'recsToSync',
					recsToSyncRecords,
					'Id',
					success,
					error);
		} // end markRecsToSyncWithProxy

		// This method goes through the records to sync, identifies the insert records and creates
		// snapshot duplicates
		function createInsertSnapshotRecords(mobileTableName,recsToSyncRecords,primaryRecords,success,error) {

			// List of new snapshot recordsstartup
			var snapshotRecords = [];

			$j.each(recsToSyncRecords, function(i,recsToSyncRecord) {

				// Prepare snapshot record
				var snapshotRecord = {};

				// For the currect record to sync, find the matching full width record
				$j.each(primaryRecords, function(i,primaryRecord) {

					// Match on the Salesforce ids
					if (recsToSyncRecord.Id == primaryRecord.Id) {

						// For a CRUD create, put the entire record in our create record set
						if (recsToSyncRecord.CRUD_Operation == 'Insert') {

							// Loop through the fields of the primary record
							for (var primaryField in primaryRecord) {

								// Do not include the soup entry id of the primary record
								if ((primaryField != '_soupEntryId') && (primaryField != '_soupLastModifiedDate')){
									snapshotRecord[primaryField] = primaryRecord[primaryField];
								} // end check for soup entry id
							} // end loop through field names
						} // end insert check if
					} // end rec to sync/primary match check if
				}); // end loop through primary mobile table check if

				// Add new snapshot record to the snapshot list
				snapshotRecords.push(snapshotRecord);
			}); // end loop through records to sync

			// Now insert the snapshot records
			if (snapshotRecords.length === 0) {
				success();
			} // end check for snapshotRecords if
			else {

				// Upsert the soup entries for new snapshot records
				smartstore.upsertSoupEntries(
						'SnapShot_' + mobileTableName,
						snapshotRecords,
						success,
						error);
			} // end check for snapshotRecords else
		} // end createInsertSnapshotRecords

		// This function gets the current location, creates a connection session record
		// and forms the connection session Json to send to the platform
		function buildConnectionSession(sessionType,mobileProcessStatus,success,error) {
			var geoLib = require('mobileCaddy/geolocation');
			var returnObject = {};
			geoLib.getLocation(
					function(locationRecords) {

						// Create a connection session for this m2p update
						var connSessionRec = {mobilecaddy1__Session_Type__c : sessionType, mobilecaddy1__Mobile_Process_Status__c : mobileProcessStatus, SystemModstamp : new Date().getTime()};

						// Add in geolocation info
						var geoErrorNumber = locationRecords.ErrorNumber;
						if (geoErrorNumber !== 0) {
							connSessionRec.mobilecaddy1__Session_Created_Location_Error__c = locationRecords.Error;
						}
						else {
							connSessionRec.Session_Created_Location__Longitude__s = locationRecords.Latitude;
							connSessionRec.Session_Created_Location__Latitude__s = locationRecords.Longitude;
						}
						insertRecWithProxyId(
							'Connection_Session__mc',
							connSessionRec,
							function(connSessReturnObject) {

								// Build up the connection session json
								var connSessJson = '{';
								connSessJson += '"Sync Session Proxy ID" : null,';
								connSessJson += '"Total Sessions" : 1,';
								connSessJson += '"Session Number" : 1,';
								connSessJson += '"Connection Session Proxy ID" : "' + connSessReturnObject.proxyId + '",';
								if (geoErrorNumber !== 0) {
									connSessJson += '"ErrorNumber" : ' + geoErrorNumber + ',';
								}
								else {
									connSessJson += '"Location Long" : ' + locationRecords.Longitude + ',';
									connSessJson += '"Location Lat" : ' + locationRecords.Latitude + ',';
								}
								var rightNow = new Date();
								connSessJson += '"Device Call Date/Time" : ' + rightNow.getTime();
								connSessJson += '}';

								// Create return object (passed to callback)
								returnObject.status = 0;
								returnObject.connSessionRec = connSessReturnObject.insertedRecord;
								returnObject.connSessProxyId = connSessReturnObject.proxyId;
								returnObject.connSessJson = connSessJson;
								success(returnObject);
							},
							error); // end insert rec with proxy id
					},
					error); // end getLocation
		} // end buildConnectionSession

		// Recovery M2P Function Call for syncing mobile tables.
		// Similar to m2pUpdateMobileTable but with removed connection sessions
		// and other functions that handle post-sync processing.
		function m2pRecoveryUpdateMobileTable(tableName) {
		    return new Promise(function(resolve, reject) {

						// maxRecsPerCall set to 30,000 for recovery to push everything up
						// in one go.
						var maxRecsPerCall = 30000;

		        var returnObject = {};
		        var success = function(status) {
		            resolve(status);
		        };
		        var error = function(err) {
		            reject(err);
		        };

						// See if we have any RTS recs for our mobile table
		        var querySpec = smartstore.buildExactQuerySpec("Mobile_Table_Name", tableName, mobileCaddy.QUERY_BUFFER_SIZE);
		        smartStoreUtils.querySoupRecordsWithQuerySpec(
		            'recsToSync',
		            querySpec,
		            function(recsToSyncRecords) {

		                // Only continue if we have any matching records
		                if (recsToSyncRecords.length !== 0) {
		                    console.debug('recsToSyncRecords', JSON.stringify(recsToSyncRecords));

		                    var moreToSync = false;
		                    if (tableName != "Connection_Session__mc" && recsToSyncRecords.length > maxRecsPerCall) {
		                        moreToSync = true;
		                    }
		                    console.log('moreToSync: ' + moreToSync);
		                    var recsToSyncRecords2 = [];
		                    if (moreToSync) {
		                        recsToSyncRecords2 = _.sortBy(recsToSyncRecords, '_soupLastModifiedDate');
		                        recsToSyncRecords2 = recsToSyncRecords2.slice(0, maxRecsPerCall);
		                    } else {
		                        recsToSyncRecords2 = recsToSyncRecords;
		                    }
		                    console.debug('recsToSyncRecords2', JSON.stringify(recsToSyncRecords2));

		                    // console.log('### d1 RTS', localStorage.getItem('recsToSync'));
		                    smartStoreUtils.querySoupRecords(
		                        tableName,
		                        function(fullSoupRecords) {

		                            // Also need full set of matching snapshot records so that we can
		                            // detect changes
		                            smartStoreUtils.querySoupRecords(
		                                'SnapShot_' + tableName,
		                                function(snapShotRecords) {

		                                    // Get back all of the row mapping table columns needed here
		                                    smartStoreUtils.getSysDataRowMapColHeadings(
		                                        'Row Mapping TC', ['Parent SOUP Name',
		                                            'Table Column Name',
		                                            'M2P Update Converter DEVICE',
		                                            'M2P Update NULL Handler DEVICE',
		                                            'M2P Update Formatter DEVICE'
		                                        ],
		                                        function(mappingsList) {

		                                            // Extract table column names from results list into
		                                            // variables for convenience
		                                            var tableNameColumn = mappingsList[0];
		                                            var tableColumnColumn = mappingsList[1];
		                                            var converterColumnName = mappingsList[2];
		                                            var nullHandlerColumnName = mappingsList[3];
		                                            var formatterColumnName = mappingsList[4];

		                                            // Get back all columns recs for our
		                                            // mobile table.  This is metadata and will tell us what converter
		                                            // formatter and nullhandlers to use
		                                            smartStoreUtils.queryMobileTableWithAnd(
		                                                'syncLib_system_data',
		                                                'MC_Var_String_001',
		                                                'Platform Table Column',
		                                                tableNameColumn,
		                                                tableName,
		                                                function(columnRecs) {

																											// Make sure all ID in recsToSyncRecords2 has corresponding
																											// record in the fullSoupRecords.
																											function recordExistsInFullSoup(idToCheck, list) {
																												return _.find(fullSoupRecords, function(r){
																													return r.Id == idToCheck;
																												});
																											}
																											var checkedRecsToSync = [];
																											_.each(recsToSyncRecords2, function(v) {
																												if (recordExistsInFullSoup(v.Id, fullSoupRecords)) {
																													checkedRecsToSync.push(v);
																												}
																											});

																											// If checkedRecsToSync is empty after this validation above,
																											// don't proceed but finish as there is nothing to sync.
																											if (_.isEmpty(checkedRecsToSync)) {
																												console.debug('Nothing in checkedRecsToSync.');
																												smartStoreUtils.setTableDefnColumnValue(
																		                        tableName,
																		                        'Last Sync Date/Time',
																		                        new Date().getTime(),
																		                        function() {
																		                            returnObject.status = M2P_UPDATE_OK;
																		                            returnObject.mc_add_status = M2P_NO_RECS_TO_SYNC;
																		                            success(returnObject);
																		                        },
																		                        error);
																												return;
																											}

		                                                    // Call helper to produce the json string - which is passed
		                                                    // to the success callback
		                                                    createUpdateJson(
		                                                        tableName,
		                                                        columnRecs,
		                                                        tableColumnColumn,
		                                                        converterColumnName,
		                                                        nullHandlerColumnName,
		                                                        formatterColumnName,
		                                                        checkedRecsToSync,
		                                                        fullSoupRecords,
		                                                        snapShotRecords,
		                                                        "", // connSessObject.connSessProxyId no longer needed for recovery sync
		                                                        function(jsonString) {
		                                                            appDataUtils.getCurrentValueFromAppSoup(
		                                                                'audId',
		                                                                function(audId) {

		                                                                    // Get the sync refresh version
		                                                                    appDataUtils.getCurrentValueFromAppSoup(
		                                                                        'syncRefreshVersion',
		                                                                        function(syncRefreshVersion) {

		                                                                            createInsertSnapshotRecords(
		                                                                                tableName,
		                                                                                recsToSyncRecords2,
		                                                                                fullSoupRecords,
		                                                                                function() {
		                                                                                    console.log('moreToSync: ' + moreToSync);
		                                                                                    var m2pUpdateTableSuccFun = function(result, event) {
		                                                                                        console.debug('result: ' +  result);
		                                                                                        console.debug('event: ' + event);
																																														returnObject.result = result;
																																														returnObject.event = event;
		                                                                                        success(returnObject);
		                                                                                    };
		                                                                                    jsonString = jsonString.replace(/: undefined/g, ': "undefined"');
		                                                                                    console.debug('jsonString -> ' + jsonString);

		                                                                                    // console.log('### d RTS', localStorage.getItem('recsToSync'));
		                                                                                    // console.log('### d CS', localStorage.getItem('Connection_Session__mc'));
		                                                                                    // console.log('### d SCS', localStorage.getItem('SnapShot_Connection_Session__mc'));

		                                                                                    if (USE_FORCETK === true) {
		                                                                                        // TODO : don't have invalid JSON objects from store.
		                                                                                        // Something to do with null handlers perhaps.
		                                                                                        // var jsonObj = JSON.parse(jsonString);
		                                                                                        // var trimmedFields = jsonObj.records[0].fields;
		                                                                                        // trimmedFields = _.filter(trimmedFields, function(el){
		                                                                                        // 	switch (el.name) {
		                                                                                        // 		 case 'LastActivtyDate' :
		                                                                                        // 		 case 'LastViewedDate' :
		                                                                                        // 		 	return false;
		                                                                                        // 		default :
		                                                                                        // 			return true;
		                                                                                        // 	}
		                                                                                        // });
		                                                                                        //jsonObj.records[0].fields = trimmedFields;
		                                                                                        force.request({
		                                                                                                method: 'POST',
		                                                                                                path: '/services/apexrest/mobilecaddy1/' + 'm2pUpdateTable001',
		                                                                                                contentType: 'application/json',
		                                                                                                data: {
		                                                                                                    "audId": audId,
		                                                                                                    "startPageControllerVersion": mobileCaddy.START_PAGE_CONTROLLER_VSN,
		                                                                                                    'syncRefreshDataVersion': syncRefreshVersion,
		                                                                                                    'mobileTableName': tableName,
		                                                                                                    'jsonRecords': jsonString
		                                                                                                },
		                                                                                            },
		                                                                                            function(response, event) {
		                                                                                                if (typeof(event) == 'undefined') {
		                                                                                                    event = {};
		                                                                                                    event.status = "200";
		                                                                                                }
		                                                                                                m2pUpdateTableSuccFun(response, event);
		                                                                                            },
		                                                                                            error);
		                                                                                    } else {
		                                                                                        // Mocked conSessJson object since connection sessions not required in recovery sync.

		                                                                                        Visualforce.remoting.Manager.invokeAction('mobilecaddy1.' +
		                                                                                            mobileCaddy.START_PAGE_CONTROLLER + '.m2pUpdateTable',
		                                                                                            audId,
		                                                                                            syncRefreshVersion,
		                                                                                            tableName,
		                                                                                            jsonString,
		                                                                                            JSON.stringify({
		                                                                                                'Session Number': 1,
		                                                                                                'Location Long': 10.0,
		                                                                                                'Location Lat': 10.0,
		                                                                                                'Total Sessions': 1,
		                                                                                                'Device Call Date/Time': new Date().getTime(),
		                                                                                                'Connection Session Proxy ID': '1',
		                                                                                                'ErrorNumber': 2
		                                                                                            }),
		                                                                                            m2pUpdateTableSuccFun, {
		                                                                                                buffer: false,
		                                                                                                escape: false,
		                                                                                                timeout: 30000
		                                                                                            });
		                                                                                    }
		                                                                                },
		                                                                                error);
		                                                                        },
		                                                                        error);
		                                                                },
		                                                                error);
		                                                        },
		                                                        error);
		                                                }, // end query column recs success callback
		                                                error); // end query column recs
		                                        }, // end get column headings callback
		                                        error);
		                                }, // end query snapshot soup records success callback
		                                error); // end query soup record call on snapshot table
		                        }, // end query soup callback function on full soup records
		                        error); // end full soup records query
		                } // end recs to sync recs found check if
		                else {

		                    // No recs to sync found.  This is ok! Just update the
		                    // last sync date/time and call the success function
		                    smartStoreUtils.setTableDefnColumnValue(
		                        tableName,
		                        'Last Sync Date/Time',
		                        new Date().getTime(),
		                        function() {
		                            returnObject.status = M2P_UPDATE_OK;
		                            returnObject.mc_add_status = M2P_NO_RECS_TO_SYNC;
		                            success(returnObject);
		                        },
		                        error);
		                } // end recs to sync found check else
		            }, // end recs to sync success callback
		            error); // end recs to sync query
		    });
		}

		// For the given table, scans recs to sync and creates the appropriate JSON for
		// new records and mods.
		var M2P_UPDATE_OK = 100300;
		var M2P_NO_RECS_TO_SYNC = 100310;

		function m2pUpdateMobileTable(tableName, maxRecsPerCall, success,error) {
			var returnObject = {};
			console.debug("In m2pUpdateMobileTable call", tableName, maxRecsPerCall);
			//'P2M RE Process Called',
			// Create connection session - this gives us the record including geolocation plus the json
			buildConnectionSession(
					'Sync - Update',
					'M2P Process Called',
					function(connSessObject) {

						console.log('proxy id = ' + connSessObject.connSessProxyId);

						// See if we have any RTS recs for our mobile table
						var querySpec = smartstore.buildExactQuerySpec("Mobile_Table_Name", tableName, mobileCaddy.QUERY_BUFFER_SIZE);
						smartStoreUtils.querySoupRecordsWithQuerySpec(
								'recsToSync',
								querySpec,
								function(recsToSyncRecords) {

									// Only continue if we have any matching records
									if (recsToSyncRecords.length !==0) {
										console.debug('recsToSyncRecords', JSON.stringify(recsToSyncRecords));

										var moreToSync = false;
										if (tableName != "Connection_Session__mc" && recsToSyncRecords.length > maxRecsPerCall) {
											moreToSync = true;
										}
										console.log('moreToSync', moreToSync);
										var recsToSyncRecords2 = [];
										if (moreToSync) {
											recsToSyncRecords2 = _.sortBy(recsToSyncRecords, '_soupLastModifiedDate');
											recsToSyncRecords2 = recsToSyncRecords2.slice(0, maxRecsPerCall);
										} else {
											recsToSyncRecords2 = recsToSyncRecords;
										}
										console.debug('recsToSyncRecords2', JSON.stringify(recsToSyncRecords2));

										// Take the records to sync and update them all with our connection session proxy id
										markRecsToSyncWithProxy(
												recsToSyncRecords2,
												connSessObject.connSessProxyId,
												function(recsToSyncRecords2) {
													// console.log('### d1 RTS', localStorage.getItem('recsToSync'));
													smartStoreUtils.querySoupRecords(
															tableName,
															function(fullSoupRecords) {

																// Also need full set of matching snapshot records so that we can
																// detect changes
																smartStoreUtils.querySoupRecords(
																		'SnapShot_' + tableName,
																		function(snapShotRecords) {

																			// Get back all of the row mapping table columns needed here
																			smartStoreUtils.getSysDataRowMapColHeadings(
																					'Row Mapping TC',
																					['Parent SOUP Name',
																					 'Table Column Name',
																					 'M2P Update Converter DEVICE',
																					 'M2P Update NULL Handler DEVICE',
																					 'M2P Update Formatter DEVICE'],
																					 function(mappingsList) {

																						// Extract table column names from results list into
																						// variables for convenience
																						var tableNameColumn = mappingsList[0];
																						var tableColumnColumn = mappingsList[1];
																						var converterColumnName = mappingsList[2];
																						var nullHandlerColumnName = mappingsList[3];
																						var formatterColumnName = mappingsList[4];

																						// Get back all columns recs for our
																						// mobile table.  This is metadata and will tell us what converter
																						// formatter and nullhandlers to use
																						smartStoreUtils.queryMobileTableWithAnd(
																								'syncLib_system_data',
																								'MC_Var_String_001',
																								'Platform Table Column',
																								tableNameColumn,
																								tableName,
																								function (columnRecs) {

																									// Call helper to produce the json string - which is passed
																									// to the success callback
																									createUpdateJson(
																											tableName,
																											columnRecs,
																											tableColumnColumn,
																											converterColumnName,
																											nullHandlerColumnName,
																											formatterColumnName,
																											recsToSyncRecords2,
																											fullSoupRecords,
																											snapShotRecords,
																											connSessObject.connSessProxyId,
																											function(jsonString) {
																												appDataUtils.getCurrentValueFromAppSoup(
																														'audId',
																														function(audId) {

																															// Get the sync refresh version
																															appDataUtils.getCurrentValueFromAppSoup(
																																	'syncRefreshVersion',
																																	function(syncRefreshVersion) {

																																		createInsertSnapshotRecords(
																																				tableName,
																																				recsToSyncRecords2,
																																				fullSoupRecords,
																																				function() {
																																					console.log('moreToSync', moreToSync);
																																					var m2pUpdateTableSuccFun = function(result, event) {
																																						console.debug('result', result);
																																						console.debug('event', event);
																																						if (event.status) {
																																							connSessUtils.processM2PUpdateResponse(
																																									result,
																																									jsonString,
																																									function(responseObject) {
																																										console.debug('responseObject', JSON.stringify(responseObject));
																																										if (tableName == 'Connection_Session__mc') {
																																											connSessObject.connSessionRec.mobilecaddy1__Mobile_Process_Status__c = "M2P Conn_Sess Records Processed";
																																										} else {
																																											connSessObject.connSessionRec.mobilecaddy1__Mobile_Process_Status__c = "M2P Records Processed";
																																										}
																																										connSessObject.connSessionRec.Id = responseObject.csId;

																																										// Update the connection session, create a snapshot and put in recs to sync
																																										connSessUtils.postProcessConnectionSession(
																																												connSessObject.connSessionRec,
																																												function() {
																																													console.log('success return from post process');
																																													console.log('moreToSync', moreToSync);
																																													if (moreToSync) {
																																														returnObject.status = M2P_UPDATE_OK;
																																														returnObject.mc_add_status = 'more-to-sync';
																																														success(returnObject);
																																													} else {
																																														connSessUtils.maybeSyncConnSess(connSessObject.connSessionRec,
																																																function(){
																																																	console.log('success return from maybeSyncConnSess');
																																																	returnObject.status = M2P_UPDATE_OK;
																																																	success(returnObject);
																																																},
																																																error);
																																														}
																																													},
																																												error);

																																										// returnObject.status = M2P_UPDATE_OK;
																																										// success(returnObject);
																																									},
																																									error);
																																						} // end status set check if
																																						else {
																																							if (event.type === 'exception') {
																																								returnObject.status = M2P_UPDATE_OK;
																																								returnObject.mc_add_status = HEARTBEAT_EXCEPTION;
																																								success(returnObject);
																																								logger.error('m2pUpdate', tableName, event.message, event.where);
																																							} // end exception if
																																							else {
																																								returnObject.status = M2P_UPDATE_OK;
																																								returnObject.mc_add_status = HEARTBEAT_FAILURE;
																																								success(returnObject);
																																								logger.error('m2pUpdate', tableName, event.message, event.where);
																																							} // end exception else
																																						} // end success else
																																					};
																																					jsonString = jsonString.replace(/: undefined/g, ': "undefined"');
																																					console.debug('jsonString -> ' + jsonString);

// console.log('### d RTS', localStorage.getItem('recsToSync'));
// console.log('### d CS', localStorage.getItem('Connection_Session__mc'));
// console.log('### d SCS', localStorage.getItem('SnapShot_Connection_Session__mc'));

																																					if ( USE_FORCETK === true ) {
																																						// TODO : don't have invalid JSON objects from store.
																																						// Something to do with null handlers perhaps.
																																						// var jsonObj = JSON.parse(jsonString);
																																						// var trimmedFields = jsonObj.records[0].fields;
																																						// trimmedFields = _.filter(trimmedFields, function(el){
																																						// 	switch (el.name) {
																																						// 		 case 'LastActivtyDate' :
																																						// 		 case 'LastViewedDate' :
																																						// 		 	return false;
																																						// 		default :
																																						// 			return true;
																																						// 	}
																																						// });
																																						//jsonObj.records[0].fields = trimmedFields;
																																						force.request(
																																	            {
																																                method: 'POST',
																																                path: '/services/apexrest/mobilecaddy1/' + 'm2pUpdateTable001',
																																                contentType : 'application/json',
																																                data: {
																																                    "audId" : audId,
																																                    "startPageControllerVersion" : mobileCaddy.START_PAGE_CONTROLLER_VSN,
																																                    'syncRefreshDataVersion': syncRefreshVersion,
																																                    'mobileTableName': tableName,
																																                    'jsonRecords' : jsonString,
																																                    'connSessJson' : connSessObject.connSessJson
																																                    },
																																	            },
																																	            function(response, event) {
																																	            	if  ( typeof(event) == 'undefined') {
																																	            		event  = {};
																																	            		event.status = "200";
																																	            	}
																																	            	m2pUpdateTableSuccFun(response, event);
																																	            },
																																	            error);
																																					} else {
																																						Visualforce.remoting.Manager.invokeAction('mobilecaddy1.' +
																																								mobileCaddy.START_PAGE_CONTROLLER + '.m2pUpdateTable',
																																								audId,
																																								syncRefreshVersion,
																																								tableName,
																																								jsonString,
																																								connSessObject.connSessJson,
																																								m2pUpdateTableSuccFun,
																																								{ buffer: false, escape: false, timeout: 30000 });
																																					}
																																				},
																																				error);
																																	},
																																	error);
																														},
																														error);
																											},
																											error);
																								}, // end query column recs success callback
																								error);// end query column recs
																					}, // end get column headings callback
																					error);
																		}, // end query snapshot soup records success callback
																		error); // end query soup record call on snapshot table
															}, // end query soup callback function on full soup records
															error); // end full soup records query
												}, // end markRecsToShyncWithProxy callback function
												error); // end markRecsToSyncWithProxy
									} // end recs to sync recs found check if
									else {

										// No recs to sync found.  This is ok! Just update the
										// last sync date/time and call the success function
										smartStoreUtils.setTableDefnColumnValue(
												tableName,
												'Last Sync Date/Time',
												new Date().getTime(),
												function() {
													returnObject.status = M2P_UPDATE_OK;
													returnObject.mc_add_status = M2P_NO_RECS_TO_SYNC;
													success(returnObject);
												},
												error);
									} // end recs to sync found check else
								}, // end recs to sync success callback
								error); // end recs to sync query
					},
					error);

		} // end m2pUpdateMobileTable function

		function insertRecWithProxyId(tableName,newRecord,success,error) {
			var returnObject = {};
			var now = new Date();
			smartstore.upsertSoupEntries(
					tableName,
					[newRecord],
					function(upsertedRecordList) {
						var upsertedRecord = upsertedRecordList[0];
						genProxyId(
								tableName,
								upsertedRecord._soupEntryId,
								now.getTime(),
								function(proxyId) {

									upsertedRecord.Id = proxyId;
									if (_.indexOf(MC_TABLES, tableName) > -1){
										upsertedRecord.mobilecaddy1__MC_Proxy_ID__c = proxyId;
									} else {
										upsertedRecord.MC_Proxy_ID__c = proxyId;
									}
									smartstore.upsertSoupEntries(
											tableName,
											[upsertedRecord],
											function(upsertedRecsList) {
												returnObject.status = 0;
												returnObject.proxyId = proxyId;
												returnObject.insertedRecord = upsertedRecsList[0];
												success(returnObject);
											},
											error);
								},
								error); // end genProxyId
						}, // end upsert callback
						error
					);
		} // end insertRecWithProxyId

		// Heartbeat function - minimal salesforce call - determine that salesforce is up!
		// Note that a return of HEARTBEAT_NO_CONNECTION indicates that we are running in a browser
		// rather than in phonegap/cordova.  At present we assume a connection is available if
		// running in the browser and we don't make the VF remoting call here.
		var HEARTBEAT_OK = 100100;
		var HEARTBEAT_EXCEPTION = 100101;
		var HEARTBEAT_FAILURE = 100102;
		var HEARTBEAT_NO_CONNECTION = 100103;
		var HEARTBEAT_NOT_DEVICE = 100104;
		var HEARTBEAT_REFRESHED_OK = 100105;

		function heartBeat(success,error) {
			var returnObject = {};
			// Before we bother calling Salesforce, check that the connection is there
			if (!navigator || !navigator.connection || typeof(Connection) == "undefined") {
				if (localStorage.connection) {
					returnObject.status = localStorage.connection;
				} else {
					returnObject.status = HEARTBEAT_NOT_DEVICE;
				}
				success(returnObject);
			}
			else {
				console.log('Connection details');
				mobileLogger.logObjectDetails(Connection);
				if (navigator.connection.type == Connection.NONE) {
					returnObject.status = HEARTBEAT_NO_CONNECTION;
					success(returnObject);
				} // end no connection check if
				else {
					Visualforce.remoting.Manager.invokeAction('mobilecaddy1.' +
							mobileCaddy.START_PAGE_CONTROLLER + '.heartBeat',
							function(result, event) {
								if (event.status) {
									returnObject.status = HEARTBEAT_OK;
									success(returnObject);
								} // end status set check if
								else {
									if (event.type === 'exception') {

										// Refresh the token and continue
										refreshToken(
											function(token) {
												mobileLogger.logMessage('refresh token refreshed in heartbeat');
												returnObject.status = HEARTBEAT_REFRESHED_OK;
												success(returnObject);
											},
											function(err) {
												returnObject.status = HEARTBEAT_EXCEPTION;
												success(returnObject);
											});
									} // end exception if
									else {
										console.debug("other");
										returnObject.status = HEARTBEAT_FAILURE;
										success(returnObject);
									} // end exception else
								} // end success else
							},
							{escape:false,timeout:30000});
				} // end no connection check else
			} // end no connection check else
		} // end heartBeat

		// Attempt to refresh the token
		function refreshToken(success,error) {

			// We need a whole load of info from the appSoup
			smartStoreUtils.querySoupRecords('appSoup',
				function(appSoupRecs) {
					var appSoupValObj = {};
					appSoupRecs.forEach(function(el){
						appSoupValObj[el.Name] = el.CurrentValue;
					});
					refreshTokenRequest(appSoupValObj, success,error);
				},
				function(err) {
					error(err);
				}
			);
		} // end refreshToken

		function refreshTokenRequest(appSoupObj, success, error) {
			var mobileLogger = require('mobileCaddy/mobileLogger');
			var smartstore = cordova.require("com.salesforce.plugin.smartstore");
            var urlToHit = 'https://mobilecaddy.secure.force.com/apex/ProxyToken';
            var dataStr = 'grant_type=refresh_token&identity_url=' + appSoupObj.identityUrl + '&client_id=' + appSoupObj.clientId + '&refresh_token=' + appSoupObj.refreshToken + '&orgId=' + appSoupObj.orgId + '&audId=' + appSoupObj.audId + '&userId=' + appSoupObj.userId;
            mobileLogger.logMessage('data: ' + dataStr);
            $j.ajax({
                type: 'POST',
                url: urlToHit,
                cache: false,
                processData: false,
                data: dataStr,
                success: function(response) {
                	mobileLogger.logMessage('Changing vf access token from ' + Visualforce.remoting.oauthAccessToken + ' to ' + response.access_token);
                	Visualforce.remoting.oauthAccessToken = response.access_token;
                	Visualforce.remoting.last.refresh(
                			function() {
                				appDataUtils.updateCurrentValueInAppSoup('accessToken',response.access_token).then(function(){
                					mobileLogger.logMessage('Updated accessToken in appSoup');
								 					success(response.access_token);
                				}).catch(function(err){
													error(err);
                				});
                			},
                			function(err){
                				console.log('in VF last refresh error');
                				error(err);
                				});
                },
                error: function(err) {
                	mobileLogger.logMessage('failed to refresh access token ' +  JSON.stringify(err));
                	error(err);
                },
                dataType: "json",
                beforeSend: function(xhr) {

                }
            });
	    } // end refreshTokenRequest

		// Exposed functions for syncRefresh
		module.exports = {
			refreshToken : function(success,error) {
				refreshToken(success,error);
			},

			// Generate a proxy id for newly created mobile records
			genProxyId : function(tableName,soupEntryId,insertDateTime,success,error) {
				 genProxyId(tableName,soupEntryId,insertDateTime,success,error);
			}, // end getProxyId

			// Generates proxy ids for multiple records for the same soup.  Passed in
			// records have been inserted into a soup.  This routine calculates the
			// proxy and upserts back into the mobile table
			addProxyIds : function(tableName,records,insertDateTime,success,error) {
				addProxyIds(tableName,records,insertDateTime,success,error);
			},

			// Delegates to the local function
			P2M_REFRESH_OK : P2M_REFRESH_OK,
			p2mRefreshTable : function(tableName, maxTableAge, cleanCSFlag, success,error) {
				p2mRefreshTable(tableName,maxTableAge, cleanCSFlag,success,error);
			}, // end logMessage

			buildConnectionSession : function(sessionType,mobileProcessStatus,success,error) {
				buildConnectionSession(sessionType,mobileProcessStatus,success,error);
			},

			// Updates the given mobile table onto the platform
			M2P_UPDATE_OK : M2P_UPDATE_OK,
			M2P_NO_RECS_TO_SYNC : M2P_NO_RECS_TO_SYNC,
			m2pUpdateMobileTable : function(tableName,maxRecsPerCall,success,error) {
				m2pUpdateMobileTable(tableName,maxRecsPerCall,success,error);
			}, // end m2pUpdateMobileTable

			// Updates the given mobile table onto the platform
			// Recovery version without connection sessions and post-sync processing
			m2pRecoveryUpdateMobileTable : function(tableName) {
				return m2pRecoveryUpdateMobileTable(tableName);
			}, // end recovery function

			// Heartbeat check - minimal apex call to see that salesforce
			// is responding.  Note the response literals
			HEARTBEAT_OK : HEARTBEAT_OK,
			HEARTBEAT_EXCEPTION : HEARTBEAT_EXCEPTION,
			HEARTBEAT_FAILURE : HEARTBEAT_FAILURE,
			HEARTBEAT_NO_CONNECTION : HEARTBEAT_NO_CONNECTION,
			HEARTBEAT_NOT_DEVICE : HEARTBEAT_NOT_DEVICE,
			HEARTBEAT_REFRESHED_OK : HEARTBEAT_REFRESHED_OK,
			heartBeat : function(success,error) {
				heartBeat(success,error);
			},

			// EXPORTS FOR TESTING ONLY
			handleRefreshResponse : function(jsonObj){
    		return new Promise(function(resolve, reject) {
					handleRefreshResponse(jsonObj,
						function(){ resolve();},
						function(e){reject(e);});
			});
			}
		};
	}); // end syncRefresh


	// ================================ //
	// Connection Session Utilities     //
	// ================================ //
	define("mobileCaddy/connSessUtils", function(require, exports, module) {

		function getRTSPendingconnSess(success,error) {

			var smartStoreUtils = require('mobileCaddy/smartStoreUtils');
			var SYNC_ALREADY_IN_PROGRESS = 100498;

			// Check recs to sync for pending connection session
			// Pass the first found into the success function
			// Note all should be the same
			smartStoreUtils.querySoupRecords(
					'recsToSync',
					function(recsToSync) {
						console.debug("recsToSync -> " + JSON.stringify(recsToSync));
						var currentConnectionSession = null;
						var rtsRec = null;

						// Attempt to find a current connection session
						for (var i=0; i< recsToSync.length; i++) {
							console.debug("recsToSync["+ i + "] -> " + JSON.stringify(recsToSync[i]));
							if (recsToSync[i].Current_Connection_Session !== null && typeof(recsToSync[i].Current_Connection_Session) != "undefined") {
								currentConnectionSession = recsToSync[i].Current_Connection_Session;
								rtsRec = recsToSync[i];
								break;
							} // end check for connection session
						} // end loop through recs to sync
						if ( currentConnectionSession !== null && typeof(currentConnectionSession) != "undefined") {
							var timeNow = new Date().getTime();
							var timeoutTs = rtsRec._soupLastModifiedDate + 30000;
							if ( timeNow > timeoutTs) {
								console.debug('timeNow > timeoutTs', timeNow, timeoutTs);
								// We have a timedout session
								console.debug('We have a timedout Conn_Sess', currentConnectionSession);
								success(currentConnectionSession);
							} else {
								// A sync is still valid and in process
								console.debug('We have a SYNC_ALREADY_IN_PROGRESS', currentConnectionSession);
								var returnObject = {};
								returnObject.status = SYNC_ALREADY_IN_PROGRESS;
								error(returnObject);
							}
						} else {
							console.debug('getRTSPendingconnSess - All clear');
							success(currentConnectionSession);
						}
					},
					error);

		} // end getRTSPendingconnSess


		var CONN_SESS_OK  = 100200;
		var CONN_SESS_NOK = 100201;
		function csStatusCheck(checkedForCSProxyId,success,error) {

			var syncRefresh = require('mobileCaddy/syncRefresh');
			var appDataUtils = require('mobileCaddy/appDataUtils');
			var connSessUtils = require('mobileCaddy/connSessUtils');
			var smartStoreUtils = require('mobileCaddy/smartStoreUtils');
			var logger = require('mobileCaddy/logger');

			console.debug("csStatusCheck -> " + checkedForCSProxyId);
			// Create our connection session record and json
			syncRefresh.buildConnectionSession('Status Check','M2P SC Status Check Requested',
				function(connSessObject) {

					syncRefresh.heartBeat(
						function(heartBeatObject) {

							// Continue if connected
							if ((heartBeatObject.status == syncRefresh.HEARTBEAT_OK) || (heartBeatObject.status == syncRefresh.HEARTBEAT_NOT_DEVICE) || (heartBeatObject.status == syncRefresh.HEARTBEAT_REFRESHED_OK)) {

								// Get the dynamic version
								appDataUtils.getCurrentValueFromAppSoup('audId',
									function(audId) {

										// Get the sync refresh version
										appDataUtils.getCurrentValueFromAppSoup(
											'syncRefreshVersion',
											function(syncRefreshVersion) {
												var m2pCSStatusCheckSuccCB = function(result, event){
													if (event.status) {

														// Successful return so parse out the JSON
														var resultObject = JSON.parse(result);
														console.debug('Parse json status check done');

														if (resultObject.cs_fc_sc == 'Received Processed') {
															handleCsStatusCheckRespReceivedProcessed(
																connSessObject,
																resultObject,
																success,
																error);
														} else {
															// "Received Not Processed" || "Not Received"
															// First clear out the recs to sync - so we don't get stuck in csStatusCheck
															// loop.
															clearRTSRecs(checkedForCSProxyId,
																function() {
																	// We know record exists so pull it back so we can update it
																	smartStoreUtils.queryMobileTable(
																		'Connection_Session__mc',
																		'mobilecaddy1__MC_Proxy_ID__c',
																		checkedForCSProxyId,
																		function(csRecs) {
																			if (csRecs.length > 0) {
																				// Capture the connection session record
																				var csRecToUpdate = csRecs[0];
																				if (resultObject.cs_fc_sc == 'Received Not Processed') {
																					handleCsStatusCheckRespReceivedNotProcessed(
																						csRecToUpdate,
																						connSessObject,
																						resultObject,
																						success,
																						error);
																				} // end received not processed check if
																				else {
																					// 'Not Received'
																					handleCsStatusCheckRespNotReceived(
																						csRecToUpdate,
																						connSessObject,
																						resultObject,
																						success,
																						error);
																				}
																			} // end csRecs.length > 0
																			else {
																				// we don't have a connection session, but we think we do have an RTS rec
																				// TODO What should we do?
																				success({status : CONN_SESS_OK});
																			}
																		},
																		error); // smartStoreUtils.queryMobileTable
																},
																error);
														} // end "Not Received" || "Rceived Not Processed" else
													} // end event.status set check if
													else {
														logger.error('csStatusCheck', event.message);
														success({status : CONN_SESS_NOK});
													} // end success else
												}; // end m2pCSStatusCheckSuccCB function def

												// MSD-405
												var myConnSessJson =  connSessObject.connSessJson;
												var lastErrorLog = localStorage.getItem('lastErrorLog');
												if ( lastErrorLog ) {
													localStorage.removeItem('lastErrorLog');
													myConnSessJson = JSON.parse(myConnSessJson);
													myConnSessJson.lastErrorLog = lastErrorLog;
													myConnSessJson = JSON.stringify(myConnSessJson);
												}

												if ( USE_FORCETK === true ) {
													force.request(
								            {
							                method: 'POST',
							                path: '/services/apexrest/mobilecaddy1/' + 'm2pCSStatusCheck001',
							                contentType : 'application/json',
							                data: {
																	"audId" : audId,
																	"syncRefreshDataVersion" : syncRefreshVersion,
																	"statusCheckCSProxyId" : checkedForCSProxyId,
																	"connSessJson" : myConnSessJson,
																	"startPageControllerVersion" : mobileCaddy.START_PAGE_CONTROLLER_VSN
							                    },
								            },
								            function(response, event) {
						                	console.info('response -> ' + JSON.stringify(response));
								            	if  ( typeof(event) == 'undefined') {
								            		event  = {};
								            		event.status = "200";
								            	}
								            	m2pCSStatusCheckSuccCB(response, event);
								            },
								            function(err) {
								            	logger.error("err -> " + JSON.stringify(err));
								            	error(err);
								            });
												} else {
													Visualforce.remoting.Manager.invokeAction('mobilecaddy1.' +
														mobileCaddy.START_PAGE_CONTROLLER + '.m2pCSStatusCheck',
														audId,
														syncRefreshVersion,
														checkedForCSProxyId,
														myConnSessJson,
														m2pCSStatusCheckSuccCB,
														{ buffer: false, escape: false, timeout: 30000 });
												}
											},
											error);
									},
									error);
							} // end heartbeat success if
							else {

								// Heartbeat failed so clean the connection session
								connSessUtils.cleanConnectionSessionHeartBeat(
									heartBeatObject,
									connSessObject,
									function(cleanReturnObject) {
										success({status: CONN_SESS_OK, mc_add_status: cleanReturnObject.mc_add_status});
									},
									error);
							} // end heartbeat success else
						}, // end heartbeat success callback
						error);
				},
				error);

		} // end csStatusCheck


		function handleCsStatusCheckRespReceivedProcessed(connSessObject, resultObject, success, error){
			var connSessUtils = require('mobileCaddy/connSessUtils');

			try {
				// Process the returned json
				processM2PUpdateResponse(
					resultObject.cs_fc_jr,
					function(processResultObject) {

						// Update the connection session, create a snapshot and put in recs to sync
						connSessObject.connSessionRec.mobilecaddy1__Mobile_Process_Status__c = 'M2P UP Received - Records Processed';
						connSessObject.connSessionRec.SystemModstamp = new Date().getTime();
						connSessObject.connSessionRec.mobilecaddy1__Status__c = 'Closed';
							// cs_sc_sf - this is the new conn-sess created
						connSessObject.connSessionRec.Id = resultObject.cs_sc_sf;
						connSessUtils.postProcessConnectionSession(
								connSessObject.connSessionRec,
								function() {
									success({status : CONN_SESS_OK});
								},
								error);
					},
					error);
			}
			catch (e){
				logger.error("processM2PUpdateResponse", e);
				error("processM2PUpdateResponse-error");
			}
		}


		function handleCsStatusCheckRespReceivedNotProcessed(csRecToUpdate, connSessObject, resultObject,
				success, error){
			var connSessUtils = require('mobileCaddy/connSessUtils');

			// Update the checked for connection session
			csRecToUpdate.mobilecaddy1__Mobile_Process_Status__c = 'M2P UP Failed - RTS Cleared';
			csRecToUpdate.mobilecaddy1__Session_Type__c = 'Sync Update';
			csRecToUpdate.mobilecaddy1__Status__c = 'Closed';
			csRecToUpdate.SystemModstamp = new Date().getTime();
			// cs_fc_sf - this would relate to a matching ID from the proxy we sent up
			csRecToUpdate.Id = resultObject.cs_fc_sf;
			// Update the connection session, create a snapshot and put in recs to sync
			connSessUtils.postProcessConnectionSession(
				csRecToUpdate,
				function() {
					// Update the connection session for the call
					connSessObject.connSessionRec.mobilecaddy1__Mobile_Process_Status__c = 'M2P SC - Status Check Processed';
					connSessObject.connSessionRec.SystemModstamp = new Date().getTime();
					connSessObject.connSessionRec.mobilecaddy1__Status__c = 'Closed';
					// cs_sc_sf - this is the new conn-sess created
					connSessObject.connSessionRec.Id = resultObject.cs_sc_sf;
					connSessUtils.postProcessConnectionSession(
						connSessObject.connSessionRec,
						function() {
								success({status : CONN_SESS_OK});
						},
						error);
				},
				error);
		}


		function handleCsStatusCheckRespNotReceived(csRecToUpdate, connSessObject, resultObject,
				success, error){
			var connSessUtils = require('mobileCaddy/connSessUtils');
			var smartStoreUtils = require('mobileCaddy/smartStoreUtils');

			// remove conn_sess entry
			smartStoreUtils.deleteRecordsFromSoup([csRecToUpdate],'Connection_Session__mc',
				function(res) {

					// Update the connection session for the call
					connSessObject.connSessionRec.mobilecaddy1__Mobile_Process_Status__c = 'M2P SC - Status Check Processed';
					connSessObject.connSessionRec.SystemModstamp = new Date().getTime();
					connSessObject.connSessionRec.mobilecaddy1__Status__c = 'Closed';
						// cs_sc_sf - this is the new conn-sess created
					connSessObject.connSessionRec.Id = resultObject.cs_sc_sf;
					connSessObject.connSessionRec.mobilecaddy1__Session_Type__c = 'Status Check';
					connSessUtils.postProcessConnectionSession(
							connSessObject.connSessionRec,
						function() {
								success({status : CONN_SESS_OK});
						},
						error);
				},
			error);
		}


		function processM2PUpdateResponse(jsonResponse, jsonReq, success,error) {
			// handle situation where jsonReq is not present
			if (!error) {
				error = success;
				success = jsonReq;
				jsonReq = '{}';
			}

			var smartStoreUtils = require('mobileCaddy/smartStoreUtils');
			var smartstore      = cordova.require("com.salesforce.plugin.smartstore");
			var logger          = require('mobileCaddy/logger');
			var vsnUtils        = require('mobileCaddy/vsnUtils');
			var derivedSyncVersion = 1;

			console.debug("processM2PUpdateResponse", jsonResponse, jsonReq);

			// Get the response object and parse it
			// TODO : remove this once the bug with the m2pUpdateResponse JSON has been fixed.
			jsonResponse = jsonResponse.replace(/,}/g, '}');
			console.log('Parse json processM2PUpdateResponse');
			var responseObject = JSON.parse(jsonResponse);
			console.log('Parse json processM2PUpdateResponse done');

			var mobileTable = responseObject.mt,
					inSuccessRecords   = (responseObject.is !== undefined) ? responseObject.is : [],
					inDupeRecords      = (responseObject.id !== undefined) ? responseObject.id : [],
					upSuccessRecords   = (responseObject.us !== undefined) ? responseObject.us : [],
					inMatchFailureRecs = (responseObject.ifmf !== undefined) ? responseObject.ifmf : [],
					upMatchFailureRecs = (responseObject.ufmf !== undefined) ? responseObject.ufmf : [],
					rtsToUpdateRecs    = [],
					rtsToDeleteRecs    = [],
					priToUpdateRecs    = [],
					priToInsertRecs    = [],
					snapToUpdateRecs   = [],
					snapToInsertRecs   = [],
					priToDeleteRecs    = [],
					snapshotRecords    = [];
			inSuccessRecords = inSuccessRecords.concat(inDupeRecords);

			// INSERT FAILURES
			// handle both SYNC 1 and SYNC 2
			if (typeof(responseObject.if) == "undefined") {
				inFailureRecs = [];
			} else if (typeof(responseObject.if.if) == "undefined") {
				// SYNC VERSION 1
				inFailureRecs = responseObject.if;
			} else {
				// SYNC VERSION 2
				derivedSyncVersion = 2;
				var ifRecs = responseObject.if.if.map(function(id){
					var fbe =  (responseObject.ifbe !== undefined) ? responseObject.ifbe : "K";
					return {'pd': id, 'fbe' : fbe};
				});
				var ifv = responseObject.if.ifv.map(function(id){
					var fbe =  (responseObject.ifvbe !== undefined) ? responseObject.ifvbe : "K";
					return {'pd': id, 'fbe' : fbe};
				});
				var icv = responseObject.if.icv.map(function(id){
					var fbe =  (responseObject.icvbe !== undefined) ? responseObject.icvbe : "K";
					return {'pd': id, 'fbe' : fbe};
				});
				inFailureRecs = ifRecs.concat(ifv.concat(icv));
			}

			inFailureRecs = addNonRespondedIds(jsonReq, inSuccessRecords, inFailureRecs);

			// UPDATE FAILURES
			// handle both SYNC 1 and SYNC 2
			if (typeof(responseObject.uf) == "undefined") {
				upFailureRecs = [];
			} else if (typeof(responseObject.uf.uf) == "undefined") {
				// SYNC VERSION 1
				upFailureRecs = responseObject.uf;
			} else {
				// SYNC VERSION 2
				derivedSyncVersion = 2;
				var uf = responseObject.uf.uf.map(function(id){
					var fbe =  (responseObject.ufbe !== undefined) ? responseObject.ufbe : "K";
					return {'Id': id, 'fbe' : fbe};
				});
				var usv = responseObject.uf.usv.map(function(id){
					var fbe =  (responseObject.usvbe !== undefined) ? responseObject.usvbe : "K";
					return {'Id': id, 'fbe' : fbe};
				});
				var sdf = responseObject.uf.sdf.map(function(id){
					var fbe =  (responseObject.sdfbe !== undefined) ? responseObject.sdfbe : "K";
					return {'Id': id, 'fbe' : fbe};
				});
				var hdf = responseObject.uf.hdf.map(function(id){
					var fbe =  (responseObject.hdfbe !== undefined) ? responseObject.hdfbe : "K";
					return {'Id': id, 'fbe' : fbe};
				});
				var ufv = responseObject.uf.ufv.map(function(id){
					var fbe =  (responseObject.ufvbe !== undefined) ? responseObject.ufvbe : "K";
					return {'Id': id, 'fbe' : fbe};
				});
				var ucv = responseObject.uf.ucv.map(function(id){
					var fbe =  (responseObject.ucvbe !== undefined) ? responseObject.ucvbe : "K";
					return {'Id': id, 'fbe' : fbe};
				});
				upFailureRecs = uf.concat(usv.concat(sdf.concat(hdf.concat(ufv.concat(ucv)))));
			}

			// enrich our lists with RTS info (CRUD etc) and
			// start creating our rtsToUpdateRecs and rtsToDeleteRecs
			// TODO - should we move the read of the SnapShot to be conditional on wether RTS has any insertUpdates?
			//   It's likely to be a rare occurance.
			querySoupRecsPromise('SnapShot_' + mobileTable).then(function(res){
				snapshotRecords = res;
				return querySoupRecsPromise(mobileTable);
			}).then(function(priRecords){
				console.debug('priRecords -> ' + JSON.stringify(priRecords));
				smartStoreUtils.queryMobileTable(
					'recsToSync',
					'Mobile_Table_Name',
					mobileTable,
					function(recsToSyncRec) {
						for (var i in recsToSyncRec) {
							console.debug('recsToSyncRec[i] = ' + JSON.stringify(recsToSyncRec[i]));
							if ( recsToSyncRec[i].Current_Connection_Session == responseObject.cp ) {
								var matchFound = false;
								var tmpRtsRec = {};
								var tmpPri = {};
								var failBehaviour = "";
								switch (recsToSyncRec[i].CRUD_Operation) {
									// S U C C E S S - I N S E R T *
									case "Insert" :
									case "InsertUpdate"	:
										for (var j in inSuccessRecords) {
											if (recsToSyncRec[i].Id == inSuccessRecords[j].pd) {
												inSuccessRecords[j].crud = recsToSyncRec[i].CRUD_Operation;
												//if (recsToSyncRec[i].CRUD_Operation == "Insert") {
													tmpPri = priFromRespRec(inSuccessRecords[j], priRecords);
													if (recsToSyncRec[i].CRUD_Operation == "Insert") {
														switch ( responseObject.stbe )  {
															case "D" :
																priToDeleteRecs.push(tmpPri);
																break;
															default :
																if ( inSuccessRecords[j].pc == "U" ) {
																	tmpPri.Id = inSuccessRecords[j].Id;
																	if ( typeof(inSuccessRecords[j].an) != "undefined" ) {
																		tmpPri.Name = inSuccessRecords[j].an;
																	}
																	if ( typeof(inSuccessRecords[j].lu) != "undefined" ) {
																		// we have some lookup fields to update
																		for(var prop in inSuccessRecords[j].lu) {
																		  if(inSuccessRecords[j].lu.hasOwnProperty(prop))
																		  	console.debug("prop", prop, inSuccessRecords[j].lu[prop]);
																		  	tmpPri[prop] = inSuccessRecords[j].lu[prop];
																		}
																	}
																	priToInsertRecs.push(tmpPri);
																	snapToInsertRecs.push(tmpPri);
																}
														}
														rtsToDeleteRecs.push(recsToSyncRec[i]._soupEntryId);
													} else {
														// S U C C E S S - I N S E R T    U P D A T E*
														// MSD-130
														// we don't care about "match"/"unmatch and "delete" / "retain" here
														tmpPri.Id = inSuccessRecords[j].Id;
														if ( typeof(inSuccessRecords[j].an) != "undefined" ) {
															tmpPri.Name = inSuccessRecords[j].an;
														}
														if ( typeof(inSuccessRecords[j].lu) != "undefined" ) {
															// we have some lookup fields to update
															for(var iUProp in inSuccessRecords[j].lu) {
															  if(inSuccessRecords[j].lu.hasOwnProperty(iUProp))
															  	console.debug("iUProp", iUProp, inSuccessRecords[j].lu[iUProp]);
															  	tmpPri[iUProp] = inSuccessRecords[j].lu[iUProp];
															}
														}
														priToInsertRecs.push(tmpPri);
														var tmpSnap = priFromRespRec(inSuccessRecords[j], snapshotRecords);
														tmpSnap.Id = inSuccessRecords[j].Id;
														snapToInsertRecs.push(tmpSnap);
														tmpRtsRec = recsToSyncRec[i];
														tmpRtsRec.Current_Connection_Session = null;
														tmpRtsRec.CRUD_Operation = "Update";
														tmpRtsRec.Id = inSuccessRecords[j].Id;
														rtsToUpdateRecs.push(tmpRtsRec);
													}
												matchFound = true;
												break;
											}
										}
									// F A I L U R E  - I N S E R T *
										if ( ! matchFound ) {
											for (j in inFailureRecs) {
												console.info("failure", recsToSyncRec[i].Id, inFailureRecs[j].pd);
												if (recsToSyncRec[i].Id == inFailureRecs[j].pd) {
													inFailureRecs[j].crud = recsToSyncRec[i].CRUD_Operation;
													if (recsToSyncRec[i].CRUD_Operation == "Insert") {
														failBehaviour = "K"; // DEFAULT
														if ( derivedSyncVersion ==1 ) {
															failBehaviour = getFailBehaviour(0, inFailureRecs[j].fl, responseObject);
														} else {
															failBehaviour = inFailureRecs[j].fbe;
														}
														switch (failBehaviour) {
														//switch (getFailBehaviour(0, inFailureRecs[j].fl, responseObject)) {
															case "K" :
																tmpRtsRec = recsToSyncRec[i];
																tmpRtsRec.Current_Connection_Session = null;
																rtsToUpdateRecs.push(tmpRtsRec);
																break;
															case "R" :
																// TODO :
																break;
															default : // DELETE
																tmpPri = priFromRespRec(inFailureRecs[j], priRecords);
																priToDeleteRecs.push(tmpPri);
																rtsToDeleteRecs.push(recsToSyncRec[i]._soupEntryId);
														}
													} else if (recsToSyncRec[i].CRUD_Operation == "InsertUpdate") {
														tmpRtsRec = recsToSyncRec[i];
														tmpRtsRec.Current_Connection_Session = null;
														tmpRtsRec.CRUD_Operation = "Insert";
														rtsToUpdateRecs.push(tmpRtsRec);
													}
													matchFound = true;
													break;
												}
											}
										}
									// F A I L U R E - I N S E R T - M A T C H    F A I L U R E *
										if ( ! matchFound ) {
											for (j in inMatchFailureRecs) {
												if (recsToSyncRec[i].Id == inMatchFailureRecs[j].pd) {
													inMatchFailureRecs[j].crud = recsToSyncRec[i].CRUD_Operation;
													if (recsToSyncRec[i].CRUD_Operation == "Insert") {
														switch (inMatchFailureRecs[j].fbe) {
															case "K" :
																tmpRtsRec = recsToSyncRec[i];
																tmpRtsRec.Current_Connection_Session = null;
																rtsToUpdateRecs.push(tmpRtsRec);
																break;
															case "R" :
																// TODO :
																break;
															default : // DELETE
																tmpPri = priFromRespRec(inMatchFailureRecs[j], priRecords);
																priToDeleteRecs.push(tmpPri);
																rtsToDeleteRecs.push(recsToSyncRec[i]._soupEntryId);
														}
													} else if (recsToSyncRec[i].CRUD_Operation == "InsertUpdate") {
														tmpRtsRec = recsToSyncRec[i];
														tmpRtsRec.Current_Connection_Session = null;
														tmpRtsRec.CRUD_Operation = "Insert";
														rtsToUpdateRecs.push(tmpRtsRec);
													}
													matchFound = true;
													break;
												}
											}
										}
										break;
									// S U C C E S S - U P D A T E *
									case "Update" :
									case "UpdateUpdate"	:
										for (j in upSuccessRecords) {
											if (recsToSyncRec[i].Id == upSuccessRecords[j].Id) {
												upSuccessRecords[j].crud = recsToSyncRec[i].CRUD_Operation;
												if (recsToSyncRec[i].CRUD_Operation == "Update") {
													tmpPri = priFromRespRec(upSuccessRecords[j], priRecords);
													switch ( responseObject.stbe )  {
														case "D" :
															// TODO : only delete if "Update" not "UpdateUpdate" ?
															priToDeleteRecs.push(tmpPri);
															break;
														default :
															if ( upSuccessRecords[j].pc == "M" ) {
																tmpPri.SystemModstamp = new Date(upSuccessRecords[j].sm);
															}
															if ( typeof(upSuccessRecords[j].lu) != "undefined" ) {
																// we have some lookup fields to update
																console.debug("lu", upSuccessRecords[j].lu);
																for(var uProp in upSuccessRecords[j].lu) {
																  if(upSuccessRecords[j].lu.hasOwnProperty(uProp))
																  	tmpPri[uProp] = upSuccessRecords[j].lu[uProp];
																}
															}
															priToUpdateRecs.push(tmpPri);
															snapToUpdateRecs.push(tmpPri);
													}
													rtsToDeleteRecs.push(recsToSyncRec[i]._soupEntryId);
												} else if (recsToSyncRec[i].CRUD_Operation == "UpdateUpdate") {
													tmpRtsRec = recsToSyncRec[i];
													tmpRtsRec.Current_Connection_Session = null;
													tmpRtsRec.CRUD_Operation = "Update";
													rtsToUpdateRecs.push(tmpRtsRec);
												}
												matchFound = true;
												break;
											}
										}
									// F A I L U R E - U P D A T E *
										if ( ! matchFound ) {
											for (j in upFailureRecs) {
												if (recsToSyncRec[i].Id == upFailureRecs[j].Id) {
													if (recsToSyncRec[i].CRUD_Operation == "Update") {
														failBehaviour = "K"; // DEFAULT
														if ( derivedSyncVersion ==1 ) {
															failBehaviour = getFailBehaviour(1, upFailureRecs[j].fl, responseObject);
														} else {
															failBehaviour = upFailureRecs[j].fbe;
														}
														switch (failBehaviour) {
															case "K" :
																tmpRtsRec = recsToSyncRec[i];
																tmpRtsRec.Current_Connection_Session = null;
																rtsToUpdateRecs.push(tmpRtsRec);
																break;
															case "R" :
																// TODO :
																break;
															default : // DELETE
																tmpPri = priFromRespRec(upFailureRecs[j], priRecords);
																priToDeleteRecs.push(tmpPri);
																rtsToDeleteRecs.push(recsToSyncRec[i]._soupEntryId);
														}
													} else if (recsToSyncRec[i].CRUD_Operation == "UpdateUpdate") {
														tmpRtsRec = recsToSyncRec[i];
														tmpRtsRec.Current_Connection_Session = null;
														tmpRtsRec.CRUD_Operation = "Update";
														rtsToUpdateRecs.push(tmpRtsRec);
													}
													matchFound = true;
													break;
												}
											}
										}
									// F A I L U R E - U P D A T E - M A T C H    F A I L U R E *
										if ( ! matchFound ) {
											for (j in upMatchFailureRecs) {
												if (recsToSyncRec[i].Id == upMatchFailureRecs[j].pd) {
													upMatchFailureRecs[j].crud = recsToSyncRec[i].CRUD_Operation;
													if (recsToSyncRec[i].CRUD_Operation == "Update") {
														switch (upMatchFailureRecs[j].fbe) {
															case "K" :
																tmpRtsRec = recsToSyncRec[i];
																tmpRtsRec.Current_Connection_Session = null;
																rtsToUpdateRecs.push(tmpRtsRec);
																break;
															case "R" :
																// TODO :
																break;
															default : // DELETE
																tmpPri = priFromRespRec(upMatchFailureRecs[j], priRecords);
																priToDeleteRecs.push(tmpPri);
																rtsToDeleteRecs.push(recsToSyncRec[i]._soupEntryId);
														}
													} else if (recsToSyncRec[i].CRUD_Operation == "UpdateUpdate") {
														tmpRtsRec = recsToSyncRec[i];
														tmpRtsRec.Current_Connection_Session = null;
														tmpRtsRec.CRUD_Operation = "Update";
														rtsToUpdateRecs.push(tmpRtsRec);
													}
													matchFound = true;
													break;
												}
											}
										}
								} // end switch on CRUD
							} // end if on current_connectio_session proxy ID
						} // end loop through RTS


						console.info('priToInsertRecs', priToInsertRecs);
						console.info('rtsToUpdateRecs', rtsToUpdateRecs);

						m2pRespUpRecs(mobileTable, "Id", priToUpdateRecs).then(function(res) {
							console.debug("m2pRespUpRecs (" + mobileTable + ") res -> " +JSON.stringify(res));
							if (_.indexOf(MC_TABLES, mobileTable) > -1){
								return m2pRespUpRecs(mobileTable, "mobilecaddy1__MC_Proxy_ID__c", priToInsertRecs);
							} else {
								return m2pRespUpRecs(mobileTable, "MC_Proxy_ID__c", priToInsertRecs);
							}
						}).then(function(res) {

							console.debug("m2pRespUpRecs" + mobileTable + ") (PROXY KEY) res -> " +JSON.stringify(res));
							return m2pRespUpRecs('SnapShot_' + mobileTable, "Id", snapToUpdateRecs);
						}).then(function(res) {
							console.debug("m2pRespUpRecs" + mobileTable + ") (PROXY KEY) res -> " +JSON.stringify(res));
							if (_.indexOf(MC_TABLES, mobileTable) > -1){
								return m2pRespUpRecs('SnapShot_' + mobileTable, "mobilecaddy1__MC_Proxy_ID__c", snapToInsertRecs);
							} else {
								return m2pRespUpRecs('SnapShot_' + mobileTable, "MC_Proxy_ID__c", snapToInsertRecs);
							}
						}).then(function(res) {
							console.debug("m2pRespUpRecs (SnapShot_" + mobileTable + ") res -> " +JSON.stringify(res));
							return m2pRespDelRecs(mobileTable, priToDeleteRecs);
						}).then(function(res) {
							console.debug("m2pRespDelRecs res -> " +JSON.stringify(res));
							return m2pRespDelRecs('SnapShot_' + mobileTable, priToDeleteRecs);
						}).then(function(res) {
							console.debug("m2pRespDelRecs (SnapShot_' + mobileTable + ') res -> " +JSON.stringify(res));
							return m2pRespUpRTSRecs(rtsToUpdateRecs);
						}).then(function(res) {
							console.debug("m2pRespUpRTSRecs res -> " +JSON.stringify(res));
							return m2pRespDelRTSRecs(rtsToDeleteRecs);
						}).then(function(res) {
							console.debug("m2pRespDelRTSRecs res -> " +JSON.stringify(res));
							return vsnUtils.checkForMigrateToInfo(responseObject);
						}).then(function(){
							var returnObject = {};
							returnObject.status = 0;
							returnObject.csId = responseObject.csId;
							success(returnObject);
						}).catch(function(err) {
							logger.error("m2pResp error for " + mobileTable + " -> " + JSON.stringify(err));
							error(err);
						});
					},
					error
				);
			}).catch(function(e) {
				logger.error("Err reading table", mobileTable);
				error(e);
			});
		} // end processM2PUpdateResponse

		// gets Primary record for associated m2pJsonResp rec from priRecs
		function priFromRespRec(m2pJsonRespRec, priRecs) {
      var searchObj = {};
      if (m2pJsonRespRec.crud == "Insert" || m2pJsonRespRec.crud == "InsertUpdate" ) {
      	searchObj.Id = m2pJsonRespRec.pd;
      } else {
      	searchObj.Id = m2pJsonRespRec.Id;
      }
			return _.findWhere(priRecs, searchObj);
		}

		function getFailBehaviour(op, failureType, respObj) {
			switch (op) {
				case 0 : // INSERT
					switch (failureType) {
						case "DF" : // Database Failure
							return respObj.ifbe;
						case "CV" : // Object CRUD Violation
							return respObj.icvbe;
						case "FV" : // FLS Violation
							return respObj.ifvbe;
					}
					break;
				case 1 : // UPDATE
					// TODO - This needs removing at some point as it doesn't work like this
					// anymore
					// https://docs.google.com/document/d/13IqzU-p4mpOTj1TCrjsZkPJEJ0YrYafSPbMhBMWW3Vw/edit
					switch (failureType) {
						case "DF" : // Database Failure
							return respObj.ufbe;
						case "SV" : // Sharing Violation
							return respObj.usvbe;
						case "CV" : // Object CRUD Violation
							return respObj.ucvbe;
						case "FV" : // FLS Violation
							return respObj.ufvbe;
						case "SD" : // Soft Delete
							return respObj.sdfbe;
						case "HD" : // Hard Delete
							return respObj.hdfbe;
					}
			}
		}

		function addNonRespondedIds(jsonReq, inSuccessRecords, inFailureRecs) {
			jsonReq = JSON.parse((jsonReq));
			var outFailureRecs = inFailureRecs;
			if (jsonReq.records &&
					(jsonReq.records.length > (inSuccessRecords.length + inFailureRecs.length ))) {
				// we have some missing IDs, so add these to the failure list with "K" behaviour
				var missingFailureRecs = [];
				var proxyFieldName =  (_.indexOf(MC_TABLES, jsonReq.MobileTable) > -1) ?
					'mobilecaddy1__MC_Proxy_ID__c' : 'MC_Proxy_ID__c';
				jsonReq.records.forEach(function(el){
					if (el.RecordCRUD == "I") {
						var myPd = el.fields.find(function(field) {
							return (field.name == proxyFieldName) ? true : false;
						}).value;
						if (! _.findWhere(inSuccessRecords, {pd : myPd}) && !_.findWhere(inFailureRecs, {pd : myPd})) {
							missingFailureRecs.push({'pd': myPd, 'fbe' : 'K'});
						}
					}
				});
				if (missingFailureRecs.length > 0 ) outFailureRecs = inFailureRecs.concat(missingFailureRecs);
			}
			return outFailureRecs;
		}

		// Runs a querySoupRecords call as a promise
		// TODO : modify real querySoupRecords to be a promise
		function querySoupRecsPromise(table) {
			var smartStoreUtils = require('mobileCaddy/smartStoreUtils');
      return new Promise(function(resolve, reject) {
      	smartStoreUtils.querySoupRecords(
					table,
					function(allTableRecords) {
	      		resolve(allTableRecords);
	      	},
	      	function(error) {
	      		reject(error);
	      	}
	      );
      });
		}

		// runs upsertSoupEntriesWithExternalId as a promise
		// TODO : modify real upsertSoupEntriesWithExternalId to be a promise
		function m2pRespUpRecs(mobileTable, key, updateRecs) {
			var smartstore = cordova.require("com.salesforce.plugin.smartstore");
			console.debug("m2pRespUpRecs (" + mobileTable + ") updateRecs -> " + JSON.stringify(updateRecs));
      return new Promise(function(resolve, reject) {
      	if (updateRecs.length > 0) {
	      	smartstore.upsertSoupEntriesWithExternalId(
						mobileTable,
						updateRecs,
						key,
						function(res) {
	      			resolve(res);
						},
						function(error) {
							reject(error);
						});
	      } else {
	      	resolve("OK");
	      }
      });
		}

		// take a list of RTS rec SoupIDs and removes them
		function m2pRespDelRTSRecs(recsToDel) {
			var smartstore = cordova.require("com.salesforce.plugin.smartstore");
			console.debug("m2pRespDelRTSRecs recsToDel -> " +JSON.stringify(recsToDel));
      return new Promise(function(resolve, reject) {
      	if (recsToDel.length > 0) {
	      	smartstore.removeFromSoup(
						'recsToSync',
						recsToDel,
						function(res) {
	      			resolve(res);
						},
						function(error) {
							reject(error);
						});
	      } else {
	      	resolve('OK');
	      }
      });
		}

		// take a list of RTS recs and upserts them
		function m2pRespUpRTSRecs(recsToUp) {
			var smartstore = cordova.require("com.salesforce.plugin.smartstore");
			console.debug("m2pRespUpRTSRecs recsToUp -> " +JSON.stringify(recsToUp));
      return new Promise(function(resolve, reject) {
      	if (recsToUp.length > 0) {
	      	smartstore.upsertSoupEntries(
						'recsToSync',
						recsToUp,
						function(res) {
	      			resolve(res);
						},
						function(error) {
							reject(error);
						});
	      } else {
	      	resolve('OK');
	      }
      });
		}


		// runs deleteRecordsFromSoup as a promise
		// TODO : modify real deleteRecordsFromSoup to be a promise
		function m2pRespDelRecs(mobileTable, recsToDel){
			console.debug("m2pRespDelRecs (" + mobileTable + ") recsToDel -> " +JSON.stringify(recsToDel));
			var smartStoreUtils = require('mobileCaddy/smartStoreUtils');
      return new Promise(function(resolve, reject) {
	    	if (recsToDel.length > 0) {
	    		// Handle SnapShot tables by calling delete with ID
	    		if (mobileTable.indexOf('SnapShot') == -1) {
						smartStoreUtils.deleteRecordsFromSoup(
							recsToDel,
							mobileTable,
								function(res) {
			      			resolve(res);
								},
								function(error) {
									reject(error);
								});
					} else {
						console.debug('Deleting from SnapShot ', mobileTable);
						smartStoreUtils.deleteRecordsForExternalId(
							mobileTable,
							recsToDel,
							'Id',
								function(res) {
			      			resolve(res);
								},
								function(error) {
									logger.error(error);
									reject(error);
								}
						);
					}
		     } else {
	      	resolve('OK');
	      }
      });
		}

		// Clear down recs to sync entries for the given checked for proxy id
		function clearRTSRecs(checkedForCSProxyId,success,error) {
			console.log("clearRTSRecs", checkedForCSProxyId);
			var smartStoreUtils = require('mobileCaddy/smartStoreUtils');
			var smartstore = cordova.require("com.salesforce.plugin.smartstore");

			// Find recs to syn with our checked for CS proxy id
			smartStoreUtils.queryMobileTable(
					'recsToSync',
					'Current_Connection_Session',
					checkedForCSProxyId,
					function(recsWithCheckedForProxyId) {

						// Defend against no records returned
						if (recsWithCheckedForProxyId.length !== 0) {

							// Go through records and update the CRUD settings
							for (var i=0; i<recsWithCheckedForProxyId.length; i++) {
								recsWithCheckedForProxyId[i].Current_Connection_Session = null;

								if (recsWithCheckedForProxyId[i].CRUD_Operation == 'InsertUpdate') {
									recsWithCheckedForProxyId[i].CRUD_Operation = 'Insert';
								} // end insertUpdate check if
								else {
									if (recsWithCheckedForProxyId[i].CRUD_Operation == 'UpdateUpdate') {
										// MSD-190 : Changed from Insert to Update.
										recsWithCheckedForProxyId[i].CRUD_Operation = 'Update';
									} // end updateUpdate check if
								} // end insertUpdate check else
							} // end loop through recs to sync

							// Update the updated recs to sync recs
							smartstore.upsertSoupEntries(
									'recsToSync',
									recsWithCheckedForProxyId,
									success,
									error);
						} // end rts length check not zero if
						else {
							success();
						} // end rts length check not zero else
					},
					error);
		} // end clearRTSRecords

		// Clean up connection session after a heartbeat failure
		// 2 calls here - 1 with VF event object - called following VF call
		// failure and another called on heartBeat failure with the heartbeat
		// return object.
		var CLEAN_CS_OK = 100600;

		// Initiates the clean connection process from a VF call failure
		function cleanConnectionSessionVFEvent(vfEventObject,connSessObject,success,error) {
			var syncRefresh = require('mobileCaddy/syncRefresh');

			// Form a bogus heartbeat response
			var heartBeatResponse = {bogus : true};
			if (vfEventObject.type === 'exception') {
				heartBeatResponse.status = syncRefresh.HEARTBEAT_EXCEPTION;
			} // end exception check if
			else {
				heartBeatResponse.status = syncRefresh.HEARTBEAT_FAILURE;
			} // end exception check else

			// Now pass on to the heart beat version of the call
			cleanConnectionSessionHeartBeat(heartBeatResponse,connSessObject,success,error);
		} // end cleanConnectionSessionVFEvent

		function cleanConnectionSessionHeartBeat(heartBeatObject,connSessObject,success,error) {
			console.log('in clean connection session heart beat');
			var smartStoreUtils = require('mobileCaddy/smartStoreUtils');
			var syncRefresh = require('mobileCaddy/syncRefresh');
			var smartstore = cordova.require("com.salesforce.plugin.smartstore");
			var mobileLogger = require('mobileCaddy/mobileLogger');

			var returnObject = {};
			var mobileProcessStatus = null;

			// Heartbeat failed - capture no connection.  This type can only
			// be heartbeat failure so no check here for VF
			if (heartBeatObject.status == syncRefresh.HEARTBEAT_NO_CONNECTION) {

				// Examine the session type to determine the mobile process status
				if (connSessObject.connSessionRec.mobilecaddy1__Session_Type__c == 'Sync - Refresh') {
					mobileProcessStatus = 'P2M RE Heartbeat No Connection';
				} // end sync/refresh check if
				else {
					if (connSessObject.connSessionRec.mobilecaddy1__Session_Type__c == 'Status Check') {
						mobileProcessStatus = 'M2P SC Heartbeat No Connection';
					} // end sync/refresh check if
				} // end sync/refresh check else

			} // end no connection check if
			else {

				// Update if heartbeat exception
				if (heartBeatObject.status == syncRefresh.HEARTBEAT_EXCEPTION) {

					// Examine the session type to determine the mobile process status
					if (connSessObject.connSessionRec.mobilecaddy1__Session_Type__c == 'Sync - Refresh') {
						if (heartBeatObject.bogus) {
							mobileProcessStatus = 'P2M RE Exception/Timeout';
						} // end bogus check if
						else {
							mobileProcessStatus = 'P2M RE Heartbeat Exception/Timeout';
						} // end bogus check else
					} // end sync/refresh check if
					else {
						if (connSessObject.connSessionRec.mobilecaddy1__Session_Type__c == 'Status Check') {
							if (heartBeatObject.bogus) {
								mobileProcessStatus = 'M2P SC Exception/Timeout';
							} // end bogus check if
							else {
								mobileProcessStatus = 'M2P SC Heartbeat Exception/Timeout';
							} // end bogus check else
						} // end status check if
					} // end sync/refresh check else
				} // end heartbeat exception check if
				else {
					if (heartBeatObject.status == syncRefresh.HEARTBEAT_FAILURE) {

						// Examine the session type to determine the mobile process status
						if (connSessObject.connSessionRec.mobilecaddy1__Session_Type__c == 'Sync - Refresh') {
							if (heartBeatObject.bogus) {
								mobileProcessStatus = 'P2M RE Failure';
							}
							else {
								mobileProcessStatus = 'P2M RE Hearbeat Failure';
							}
						} // end sync/refresh check if
						else {
							if (connSessObject.connSessionRec.mobilecaddy1__Session_Type__c == 'Status Check') {
								if (heartBeatObject.bogus) {
									mobileProcessStatus = 'M2P SC Failure';
								} // end bogus check if
								else {
									mobileProcessStatus = 'M2P SC Heartbeat Failure';
								} // end bogus check else
							} // end status check if
						} // end sync refresh check else
					} // end heartbeat failure check else
				} // end heartbeat no connection check else
			} // end cleanConnectionSessionHeartBeat

			// Set connection status mobile process status to no connection
			if (mobileProcessStatus !== null) {
				connSessObject.connSessionRec.mobilecaddy1__Mobile_Process_Status__c = mobileProcessStatus;
				connSessObject.connSessionRec.SystemModstamp = new Date().getTime();
				connSessObject.connSessionRec.mobilecaddy1__Status__c = 'Closed';
				console.log('Upserting connection session');
				smartstore.upsertSoupEntries(
						'Connection_Session__mc',
						[connSessObject.connSessionRec],
						function() {
							returnObject.status = CLEAN_CS_OK;
							returnObject.mc_add_status = heartBeatObject.status;
							// console.log('### f RTS', localStorage.getItem('recsToSync'));
							// console.log('### f CS', localStorage.getItem('Connection_Session__mc'));
							// console.log('### f SCS', localStorage.getItem('SnapShot_Connection_Session__mc'));
							success(returnObject);
						},
						error);
			} // end check we matched status if
			else {
				mobileLogger.logMessageAndThrow("Unknown status, cannot continue. " + heartBeatObject.status);
			} // end check we matched status else
		} // end heartbeat failure check if

		// This routine conditionally calls a m2pUpdate for the 'Connection_session__mc' table
		function maybeSyncConnSess(connSess, success, error) {
			// TODO : would be nice to be able to return at this point, and then further callback/promise
			// once conn_sess also closed.
      var devUtils = mobileCaddy.require('mobileCaddy/devUtils');
			var smartStoreUtils = require('mobileCaddy/smartStoreUtils');
			var logger          = require('mobileCaddy/logger');
			var returnObject = {};

			console.debug('maybeSyncConnSess');

			smartStoreUtils.querySoupRecsPromise('recsToSync').then(function(res) {
        console.debug('Success from readRecords recsToSync -> ' + JSON.stringify(res));
        var connSessRTS = _.filter(res, function(rec) {
        	return (typeof(rec.currentConnectionSession) != 'undefined');
        });
        console.debug('connSessRTS -> ' + JSON.stringify(connSessRTS));
        if (connSessRTS.length > 1 || connSess.mobilecaddy1__Mobile_Process_Status__c != "M2P Conn_Sess Records Processed" ){
					devUtils.syncMobileTable('Connection_Session__mc').then(function(resObject){
						console.debug('syncMobileTable -> ', JSON.stringify(resObject));
						returnObject.status = 0;
						success(returnObject);
					}).catch(function(err) {
						// TODO - needs to be "error" not "warn" malformed JSON MSD-359
						logger.warn('syncMobileTable ERROR -> ', err);
						error(err);
					});
				} else {
					console.debug('maybeSyncConnSess - not syncing');
					returnObject.status = 0;
					success(returnObject);
				}
      }).catch(function(err) {
				logger.error('querySoupRecsPromise ERROR -> ', err);
				error(err);
      });
		}

		// This routine updates the provided connection session, creates a snapshot duplicate and then
		// puts an entry in recs to sync so it gets updated.
		function postProcessConnectionSession(connectionSessionRec,success,error) {
			var smartstore = cordova.require("com.salesforce.plugin.smartstore");
			var mobileLogger = require('mobileCaddy/mobileLogger');
			console.debug('postProcessConnectionSession', JSON.stringify(connectionSessionRec));

			mobileLogger.logObjectDetails(connectionSessionRec);

			var returnObject = {};
			smartstore.upsertSoupEntries(
					'Connection_Session__mc',
					[connectionSessionRec],
					function(updatedConnSessRecArray) {

						console.log('success from conn sess upsert');
						mobileLogger.logObjectDetails(updatedConnSessRecArray[0]);

						// First copy the connection session to its snapshot
						// Subtract 1 millisecond from the snapshot to force the system mod stamps up on the next update
						var connectionSessionSnapShot = {Id : connectionSessionRec.Id, SystemModstamp : connectionSessionRec.SystemModstamp - 1};
						for (var fieldDef in connectionSessionRec) {
							if ((fieldDef != '_soupEntryId') && (fieldDef != '_soupLastModifiedDate') && (fieldDef != 'Id') && (fieldDef != 'SystemModstamp')) {
								connectionSessionSnapShot[fieldDef] = null;
							} // end loop through field definitions
						} // end loop through the object fields

						smartstore.upsertSoupEntries(
								'SnapShot_Connection_Session__mc',
								[connectionSessionSnapShot],
								function(updatedConnSessRecArray) {

									console.log('success on snapshot upsert');

									var recToSync = {
											Mobile_Table_Name : 'Connection_Session__mc',
											CRUD_Operation : "Update",
											SOUP_Record_Id : updatedConnSessRecArray[0]._soupEntryId,
											Id : updatedConnSessRecArray[0].Id,
											LastModifiedDateTime : updatedConnSessRecArray[0].SystemModstamp
									};

									// Update recs to sync with the updated records
									smartstore.upsertSoupEntries(
											'recsToSync',
											[recToSync],
											function() {
												console.log('success from upsert of recs to sync');
												returnObject.status = 0;
												// console.log('### c RTS', localStorage.getItem('recsToSync'));
												// console.log('### c CS', localStorage.getItem('Connection_Session__mc'));
												// console.log('### c SCS', localStorage.getItem('SnapShot_Connection_Session__mc'));

												success(returnObject);
											},
											error);
								},
								error);
					},
					error);
		} // end postProcessConnectionSession

		// Exposed functions
		module.exports = {

				// Returns any records in the records to sync mobile table that have a pending
				// (ie existing) current connection session
				getRTSPendingconnSess : function(success,error) {
					getRTSPendingconnSess(success,error);
				}, // end getRTSPendingconnSess

				CLEAN_CS_OK : CLEAN_CS_OK,
				cleanConnectionSessionHeartBeat : function(heartBeatObject,connSessObject,success,error) {
					cleanConnectionSessionHeartBeat(heartBeatObject,connSessObject,success,error);
				},

				cleanConnectionSessionVFEvent : function(vfEventObject,connSessObject,success,error) {
					cleanConnectionSessionVFEvent(vfEventObject,connSessObject,success,error);
				},

				CONN_SESS_OK : CONN_SESS_OK,
				csStatusCheck : function(statusCheckCSProxyId,success,error) {
					csStatusCheck(statusCheckCSProxyId,success,error);
				},

				maybeSyncConnSess : function(connectionSessionRec, success, error) {
					maybeSyncConnSess(connectionSessionRec, success, error);
				},

				processM2PUpdateResponse : function(jsonResponse, jsonReq, success,error) {
					processM2PUpdateResponse(jsonResponse,jsonReq, success,error);
				},

				postProcessConnectionSession : function (connectionSessionRec,success,error) {
					postProcessConnectionSession(connectionSessionRec,success,error);
				}
		}; // end export section
	}); // end connSessUtils

	// ================================ //
	// Version Utilities              //
	// ================================ //
	define("mobileCaddy/vsnUtils", function(require, exports, module) {
		var devUtils        = mobileCaddy.require('mobileCaddy/devUtils');
		var smartstore      = cordova.require("com.salesforce.plugin.smartstore");
		var smartStoreUtils = mobileCaddy.require('mobileCaddy/smartStoreUtils');
		var connSessUtils   = require('mobileCaddy/connSessUtils');
		var appDataUtils    = require('mobileCaddy/appDataUtils');
		var logger          = require('mobileCaddy/logger');

		// TODO make these available in one place, currently here and in devUtils
		var SYSTEM_TABLES = [
			//'appSoup',
			//'cacheSoup',
			'recsToSync'
			//'appSoup'
			];

		// TODO Currently clears all but appSoup... we want this to be more flexible
		// I think.
		function getSoupsToClear(soupsToClear, soupstoRetain) {
	    return new Promise(function(resolve, reject) {
				if (soupsToClear === null) {
					smartStoreUtils.listMobileTables(
			    	smartStoreUtils.ALPHA,
		      	// Success callback
		      	function(tableNames) {
		      		var allTables = SYSTEM_TABLES;
		      		_.each(tableNames, function(t){
		      			allTables.push(t);
		      			allTables.push('SnapShot_' + t);
		      			localStorage.removeItem('meta-tableDEF-' + t);
		      			localStorage.removeItem('meta-tableCRUD-' + t);
		      		});
		      		console.debug('allTables', allTables);
		      		resolve(allTables);
			      },
		      	function(error) {
		      		reject(error);
				  	}
		  		);
				} else {
					resolve([]);
				}
	    });
		}

		function clearSoups(soupsToClear, soupstoRetain) {
	    return new Promise(function(resolve, reject) {
	    	getSoupsToClear(soupsToClear, soupstoRetain).then(function(allTables){
	    		return Promise.all(allTables.map(smartStoreUtils.deleteSoup));
	    	}).then(function(){
    			resolve();
    		}).catch(function(e){
    			logger.error(e);
    			reject(e);
    		});
    	});
		}

		function hardReset(isUpgrade){
	    return new Promise(function(resolve, reject) {
				var fallbackBootstrapPage = '/apex/mobilecaddy1__MobileCaddyBootstrap001_mc';
				var appSoupRecs = {};
				var sessionType = (isUpgrade)? 'Version Upgrade' : 'HardReset';

				var syncRefresh = require('mobileCaddy/syncRefresh');

				testRefreshAccessToken().then(function(){
					devUtils.readRecords('appSoup').then(function(res){
						res.records.forEach(function(el){
							appSoupRecs[el.Name] = el.CurrentValue;
						});
						console.info('appSoupRecs', JSON.stringify(appSoupRecs));
						return clearSoups(null, ['appSoup']);
					}).then(function(){
						var url = "";
						console.debug('deletedSoups OK');
						var appEnv = getAppEnv();

						var codeFlowAuth, appSoupContents;

						// clear localStorage
						if ( appEnv == 'codeflow' ) {
							codeFlowAuth = localStorage.getItem('forceOAuth');
							appSoupContents = localStorage.getItem('appSoup');
						}
						localStorage.clear();

		        if ( appEnv == 'codeflow' ) {
		        	localStorage.setItem('forceOAuth', codeFlowAuth);
							localStorage.setItem('appSoup', appSoupContents);
		     //      var mobileCaddyStartup = mobileCaddy.require('mobileCaddy/startup');
							// mobileCaddyStartup.startup( function(){console.info("this was my fake callback");});
							//document.dispatchEvent('deviceready');
							url = (window.location.protocol + "//" + window.location.host + "/www");
		          resolve('ok');
		        } else if ( appEnv == 'platform') {
		        	url = window.location.href.substr(0, window.location.href.indexOf('#'));
		        } else {
		        	var connType = '';
							if (navigator && navigator.connection) {
								connType = navigator.connection.type;
							}
		         	url =
		         		appSoupRecs.loginUrl +
								fallbackBootstrapPage +
								'?deviceUuid=' + device.uuid +
								'&deviceName=' + device.name +
								'&deviceCordova=' + device.cordova +
								'&deviceVersion=' + device.version +
								'&deviceModel=' + device.model +
								'&buildName=' + appSoupRecs.buildName +
								'&buildVersion=' + appSoupRecs.buildVersion +
								'&buildOS=' + appSoupRecs.buildOS +
								'&knownAud=' + appSoupRecs.audId +
								'&currentDv=' + appSoupRecs.dynVersionNumber +
								'&orientation=' + orientation +
								'&viewportWidth=' + $j(window).width() +
								'&viewportHeight=' + $j(window).height() +
								'&sessionType=' + sessionType +
								'&connType=' + connType +
								'&loginUrl=' + appSoupRecs.loginUrl +
								'&millsFromEpoch=' + new Date().getTime();
		        }

						// Redirect to start url
						appDataUtils.updateNewValueInAppSoup('buildStatus', 'Resetting')
	  				.then(function(){
	  					console.info('AppSoup Updated for reset');
							smartStoreUtils.deleteSoup('syncLib_system_data').then(function(res) {
								console.log('Redirecting to: ' + url);
								try {
										window.location.href = url;
								}
								catch (error) {
									logger.error('error on redirect', error);
									reject(error);
								}
								resolve();
							}).catch(function(e){
								logger.error(e);
							});
							resolve();
						}).catch(function(e){
							logger.error(e);
							reject(e);
						});
					}).catch(function(e){
						logger.error(e);
						reject(e);
					});
				}).catch(function(err){
					// looks like our tokens are cocked up
					console.log('Tokens are bad, testRefreshAccessToken rejected with: ' + JSON.stringify(err));
					window.history.go( -( history.length - 1 ) );
					cordova.require("com.salesforce.plugin.sfaccountmanager").logout();
					reject(err);
				});
	  	});
		}

		function testRefreshAccessToken() {
			return new Promise(function(resolve, reject) {
				var syncRefresh = require('mobileCaddy/syncRefresh');

				syncRefresh.refreshToken(
					function (token) {
						console.debug('Successfully refreshed access token. Continue reset.');
						resolve('ok');
				}, function (err) {
						console.error('Unable to refresh access token. Abort reset: ' + JSON.stringify(err));
						reject(err);
				});
			});
		}

		function checkForMigrateToInfo(responseObject){
			var appDataUtils = require('mobileCaddy/appDataUtils');
      return new Promise(function(resolve, reject) {
      	if (responseObject.migrateTo !== null && typeof(responseObject.migrateTo) != "undefined") {
      		appDataUtils.updateNewValueInAppSoup('dynVersionNumber', responseObject.migrateTo)
      		.then(function(){
      			resolve();
      		}).catch(function(e){
      			logger.error(e);
      			reject(e);
      		});
      	} else {
      		resolve();
      	}
      });
		}

		function getAppEnv() {
	    if ( window.location.host == "localhost:3030" ) {
	      return "codeflow";
	    } else if ( typeof(mockStore) != "undefined" ) {
	      return"platform";
	    } else {
	      return "device";
	    }
		}


		function upgradeAvailable(){
      return new Promise(function(resolve, reject) {
				var smartStoreUtils = mobileCaddy.require('mobileCaddy/smartStoreUtils');
      	smartStoreUtils.queryMobileTable('appSoup', 'Name', 'dynVersionNumber').then(function(recs){
      		if (typeof(recs[0].NewValue) != "undefined" && recs[0].NewValue != recs[0].CurrentValue) {
      			resolve(true);
      		} else {
      			resolve(false);
      		}
      	}).catch(function(e){
      		logger.error(e);
      		reject(e);
      	});
      });
		}

		function upgradeIfAvailable(){
      return new Promise(function(resolve, reject) {
      	upgradeAvailable().then(function(res){
      		if (res){
      			connSessUtils.getRTSPendingconnSess(
							function(statusCheckCSProxyId) {
								if (statusCheckCSProxyId !== null && typeof(statusCheckCSProxyId) != "undefined") {
									resolve(false);
								} else {
									return hardReset(true);
									}
								},
							function (e) {
								resolve(false);
							}
						);
      		} else {
      			resolve(false);
      		}
      	}).catch(function(e){
      		logger.error(e);
      		reject(e);
      	});
      });
		}


		// Exposed functions
		module.exports = {
			checkForMigrateToInfo : function(jsonObj) {
				return checkForMigrateToInfo(jsonObj);
			},
			clearSoups : function(soupsToClear, soupstoRetain){
				return clearSoups(soupsToClear, soupstoRetain);
			},
			getSoupsToClear : function(soupsToClear, soupstoRetain){
				return getSoupsToClear(soupsToClear, soupstoRetain);
			},
			hardReset : function() {
				return hardReset();
			},
			upgradeAvailable :function(){
				return upgradeAvailable();
			},
			upgradeIfAvailable : function(){
				return upgradeIfAvailable();
			}
		}; // end export section
	});


	// ================================ //
	// Logger Utilities              //
	// ================================ //
	define("mobileCaddy/logger", function(require, exports, module) {
		var smartstore      = cordova.require("com.salesforce.plugin.smartstore");
		var smartStoreUtils = require('mobileCaddy/smartStoreUtils');
		var appDataUtils = require('mobileCaddy/appDataUtils');

		var LOG_LEVEL_ERROR = 0,
				LOG_LEVEL_WARN  = 1,
				LOG_LEVEL_LOG   = 2,
				LOG_LEVEL_INFO  = 3,
				LOG_LEVEL_DEBUG = 4;

		function hasLogType() {
			return new Promise(function(resolve, reject) {
			if ( localStorage.hasLogType ) {
				resolve(localStorage.hasLogType);
		  } else {
			smartStoreUtils.listMobileTableColumns('Mobile_Log__mc',smartStoreUtils.FULL,
        function(res) {
        	var logTypePath = _.find(res, {path : 'mobilecaddy1__Log_Type__c'});
        	if (typeof(logTypePath) == "undefined") {
        		localStorage.setItem('hasLogType', "false");
        		resolve("false");
        	} else {
        		localStorage.setItem('hasLogType', "true");
        		resolve("true");
        	}
        },
        function(e) {
          reject(e);
        });
			}
			});
		}


		function insertLog(type, content){
			return new Promise(function(resolve, reject) {
				if (content.length == 1) content = content[0];
				if (typeof(content) == "object") content = JSON.stringify(content);
				if (typeof(content) == "string"){

					// MSD-405
					if (type == LOG_LEVEL_ERROR) {
						localStorage.setItem("lastErrorLog", content.substring(0, 1024));
					}

					var rec = {
							mobilecaddy1__Error_Text__c : content.substring(0, 1024), // MSD-359
							SystemModstamp : new Date().getTime()
						};

					appDataUtils.getCurrentValueFromAppSoup('audId').then(function(audId){
						rec.mobilecaddy1__Application_User_Device__c = audId;
						return hasLogType();
					}).then(function(hasLogType){
						if ( hasLogType == "true") rec.mobilecaddy1__Log_Type__c = "D" + type.toString();
						smartStoreUtils.insertRecords('Mobile_Log__mc', [rec],
							function(res) {
									resolve();
							},
							function(err) {
								reject(err);
							});
					}).catch(function(e){
						console.error(e);
						reject(e);
					});
				} else {
					logger.error("Trying to log unsupported type", typeof(content));
					reject("Trying to log unsupported type" + typeof(content));
				}
			});
		}

		function log(type, content, err) {
			var logLevel = localStorage.getItem('logLevel');
			logLevel = (typeof(logLevel) == "undefined") ? 0 : logLevel;

			if (logLevel >= type) {
				var caller = "";
				if (type > 0) { // we don't need caller for error calls, its automagic
					var caller_line = err.stack.split("\n")[4];
					if (typeof(caller_line) != "undefined") {
						var index = caller_line.indexOf("at ");
						caller = caller_line.slice(index+2, caller_line.length);
					}
				}

				switch (type){
					case LOG_LEVEL_ERROR :
						insertLog(type, content);
						console.error.apply(console, content);
						break;
					case LOG_LEVEL_WARN :
						if (logLevel >= LOG_LEVEL_WARN) {
							insertLog(type, content);
							console.log.apply(console, content);
							console.log(caller);
						}
						break;
					default :
						if (logLevel >= LOG_LEVEL_LOG) {
							insertLog(type, content);
							console.log.apply(console, content);
							console.log(caller);
						}
				}
			}
		}


		function getErrorObject(){
		    try { throw Error(''); } catch(err) { return err; }
		}

		// Exposed functions
		module.exports = {
			debug : function(content) {
				return log(LOG_LEVEL_DEBUG, arguments, getErrorObject());
			},
			error : function(content) {
				return log(LOG_LEVEL_ERROR, arguments);
			},
			info : function(content) {
				return log(LOG_LEVEL_INFO, arguments, getErrorObject());
			},
			log : function(content) {
				return log(LOG_LEVEL_LOG, arguments, getErrorObject());
			},
			warn : function(content) {
				return log(LOG_LEVEL_WARN, arguments, getErrorObject());
			},
			hasLogType : function(){
				return hasLogType();
			},
		}; // end export section
	});


	// ================================ //
	// Developer Utilities              //
	// ================================ //
	define("mobileCaddy/devUtils", function(require, exports, module) {
		var smartStoreUtils = require('mobileCaddy/smartStoreUtils');
		var mobileLogger    = require('mobileCaddy/mobileLogger');
		var logger          = require('mobileCaddy/logger');

		// Sub errors and errors
		var UNKONWN_TABLE     = 1;
		var UNKONWN_FIELD     = 2;
		var ACCESS_DENIED     = 3;
		var MANDATORY_MISSING = 4;
		var DATATYPE_MISMATCH = 5;
		var PROTECTED_FIELD   = 6;
		var UNKNOWN_ID        = 7;
		var SYNC_ALREADY_IN_PROGRESS  = 98;
		var UNKONWN_ERR       = 99;
		// Base (offset) status codes
		var SYNC              = 100400;
		var SYNC_OK           = SYNC;
		var SYNC_NOK 					= 100402;
		var INSERT_RECS       = 100700;
		var READ_RECS         = 101000;
		var UPDATE_RECS       = 101100;
		var DELETE_RECS       = 101200;

		var SYSTEM_TABLES = [
			'syncLib_system_data',
			'appSoup',
			'cacheSoup',
			'recsToSync',
			'SnapShot_Connection_Session__mc',
			//TMP lines for unit testing
			//'SnapShot_MC_Project__ap'
			];
		var PROTECTED_FIELDS = [
			'autonumber',
			'CreatedById',
			'CreatedDate',
			'IsDeleted',
			//'LastActivtyDate',
			'LastModifiedById',
			'LastModifiedDate',
			'LastReferencedDate',
			// TODO : 'LastViewedDate' - should this be local field that can be updated
			// explicitly (for 'recent items' type usage)
			//'LastViewedDate',
			'mobilecaddy1__MC_Proxy_ID',
			'MC_Proxy_ID',
			'OwnerId',
			'SystemModstamp',
			'Id'
			];


		/**
		 * Increments the counter for 'key' by 1
		 * @param  {string} key
		 * @return {promise}
		 */
		function analInc(key) {
			var analTable = "Analytics";
			return new Promise(function(resolve, reject) {
			  var now = new Date();
			  var curHour =   new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), 0, 0, 0).valueOf();
			  maybeCreateAnalyticTable().then(function(){
					return getCurAnalyticsAndHousekeep(curHour);
				}).then(function(records){
					var newCnts = {};
					if (records.length === 0) { // New counter
							newCnts[key] = 1;
							var newObj = {
								"Name" :  curHour,
								"Data" : JSON.stringify(newCnts)
							};
						resolve(newCnts[key]);
						smartStoreUtils.insertRecords(analTable, [newObj],
							function(res) {
							},
							function(err) {
								logger.error("Unable to insert analytic recs", err);
							}
						); // insertRecords
					} else {
						var cntRec = records[0];
						newCnts = JSON.parse(cntRec.Data);
						newCnts[key] = (typeof(newCnts[key]) == "undefined") ? 1 : newCnts[key] + 1;
						resolve(newCnts[key]);
						cntRec.Data = JSON.stringify(newCnts);
						smartStoreUtils.updateRecordsWithExternalId(
		        	analTable,[cntRec], "Name",
							function (retRecs) {
							},
							function(err) {
								logger.error(err);
							}
						); //updateRecordsWithExternalId
					}
				}).catch(function(err){
					logger.error("Error in analInc", err);
					reject(err);
				});
			});
		}

		/**
		 * Creates analytic soup if needed
		 * @return {promise}
		 */
		function maybeCreateAnalyticTable() {
			return new Promise(function(resolve, reject) {
				smartstore.soupExists('Analytics',
					function(soupExists) {
						if (!soupExists) {
							var analSpec = [{path:"Name",type:"integer"},{path:"Data",type:"string"}];
							smartstore.registerSoup(
								'Analytics',
								analSpec,
								function(res){resolve();},
								function(err){reject(err);}
							); // registerSoup
						} else {
							resolve();
						}
					},
					function(e){
						logger.error(e);
						reject(e);
					}
				); //soupExists
			});
		}

		/**
		 * moves non-current Analytics recs to the Mobile_Log__c
		 * @return {promise}
		 */
		function getCurAnalyticsAndHousekeep(curHour) {
			return new Promise(function(resolve, reject) {
				var appDataUtils = require('mobileCaddy/appDataUtils');
				var audId = "";
				appDataUtils.getCurrentValueFromAppSoup('audId').then(function(res){
					audId = res;
				  return smartStoreUtils.querySoupRecsPromise('Analytics');
				}).then(function(recs){
					var curRecs = [];
					var oldRecs = [];
					var oldRecsIds = [];
					recs.forEach(function(el){
						if (el.Name == curHour) {
							curRecs.push(el);
						} else {
							var newObj = {
								"Name" :  el.Name.toString(),
								"SystemModstamp" : new Date().getTime(),
								"mobilecaddy1__Error_Text__c" : el.Data,
								"mobilecaddy1__Application_User_Device__c": audId
							};
							// Log_Type__c doesn't exist in older packages
							if ( logger.hasLogType() ) newObj.mobilecaddy1__Log_Type__c = "analytic";
							oldRecs.push(newObj);
							oldRecsIds.push(el._soupEntryId);
						}
					});
					if (oldRecs.length !== 0){
						// Copy recs to Mobile_Log__c
						smartStoreUtils.insertRecords("Mobile_Log__mc", oldRecs,
							function(res) {
								// Delete recs from Analytics
								smartstore.removeFromSoup("Analytics",oldRecsIds,
									function(res) {
										resolve(curRecs);
									},
									function(e) {
										logger.error("Unable to insert analytic recs", e);
										reject(e);
									}
								); // removeFromSoup
							},
							function(e) {
								logger.error("Unable to insert analytic recs", e);
								reject(e);
							}
						); // insertRecords
					}
					resolve(curRecs);
				}).catch(function(e){
					logger.error("Error housekeeping Analytics", e);
					reject(e);
				});
			});
		}

		/**
		 * checkTableAccess :returns promise returnObject based on whether
		 * the table tableName can be accessed for opType
		 * @param {string} tableName The success callback
		 * @param {integer} opType SYNC, INSERT, READ, UPDATE, etc
		 */
		function checkTableAccess(tableName, opType, tableDefinition){
			console.time("MC-TIMING checkTableAccess "+ tableName);
			return new Promise(function(resolve, reject) {
				var crudCheck = function(opType, crud){
					// TODO : need to support master CRUD at some point.
					var index = 0;
					switch (opType) {
						case INSERT_RECS : index = 1;
							break;
						case READ_RECS : index = 4;
							break;
						case UPDATE_RECS : index = 7;
							break;
						case DELETE_RECS : index = 10;
							break;
						default :
							index = 0;
					}
					if (crud.charAt(index) == "Y" ) {
						//localStorage['meta-tableCRUD-'+tableName] = "Y";
						console.timeEnd("MC-TIMING checkTableAccess "+ tableName);
						resolve(tableDefinition);
					}
					else {
						var returnObject = {};
						returnObject.status = opType + ACCESS_DENIED;
						returnObject.mc_add_status = tableName;
						//localStorage['meta-tableCRUD-'+tableName] = "N";
						console.timeEnd("MC-TIMING checkTableAccess "+ tableName);
						reject(returnObject);
					}
				};

				if ( SYSTEM_TABLES.indexOf(tableName) == -1 ){
				  if ( localStorage['meta-tableCRUD-'+tableName] ) {
				  	crudCheck(opType, localStorage['meta-tableCRUD-'+tableName]);
				  } else {
						smartStoreUtils.getTableDefnColumnValue(tableName,'Application Record CRUD',
							function(crud) {
								localStorage['meta-tableCRUD-'+tableName] = crud;
								crudCheck(opType, crud);
							}, function(e) {
								console.timeEnd("MC-TIMING checkTableAccess "+ tableName);
								console.info('Opps -> ' + tableName);
								reject(e);
							});
					}
				} else {
					console.timeEnd("MC-TIMING checkTableAccess "+ tableName);
					resolve(tableDefinition);
				}
			});
		}

		function getCurrentUserId() {
			return new Promise(function(resolve, reject) {
				if ( USE_FORCETK === true ) {
					var userId = force.getUserId();
					if (typeof(userId) !== "undefined") {
						resolve(userId);
					} else {
						resolve(userId);
					}
				} else {

					console.log('querying from app soup');
					var appDataUtils = require('mobileCaddy/appDataUtils');

					// Get the user id from app soup
					appDataUtils.getCurrentValueFromAppSoup(
							'userId',
							function(userId) {
								resolve(userId);
							},
							function(err) {
								logger.error('getCurrentUserId Error obtaining user ID');
								reject(err);
							}
					);
				}
			});
		}

		function isValidEmail(str) {
			if (str.length === 0) return true;
			var atpos = str.indexOf("@");
	    var dotpos = str.lastIndexOf(".");
	    if (atpos< 1 || dotpos<atpos+2 || dotpos+2>=str.length) {
        return false;
	    } else {
	    	return true;
	    }
		}

		var BYTES = 0;
		var CHARS = 1;
		function isValidStrLength(str, type, length) {
			if ( typeof(str) == "undefined" ) {
				return true;
			} else {
				switch ( type ) {
					case BYTES :
						var s = str.length;
					  for (var i=str.length-1; i>=0; i--) {
					    var code = str.charCodeAt(i);
					    if (code > 0x7f && code <= 0x7ff) s++;
					    else if (code > 0x7ff && code <= 0xffff) s+=2;
					    if (code >= 0xDC00 && code <= 0xDFFF) i--; //trail surrogate
					  }
					  if ( s <= length ) {
					  	return true;
					  } else {
					  	return false;
					  }
					  break;
					 default :
					 	return true;
				}
			}
		}

		/**
		 * isValidFieldAndTranslate :returns true or a returnObject based on whether
		 * fieldName can be found in tableDefinition and if so, does a transform.
		 * @param {string} tableName The success callback
		 * @param {[obj]} tableDefinition An arr of fieldInfo objects
		 */
			function isValidFieldAndTranslate(fieldName, opType, tableDefinition, fieldVal) {
				if ( fieldName == '_soupLastModifiedDate' ) {
					return fieldVal;
				} else {
					var validField = _.findWhere(tableDefinition, {'path': fieldName});
					var returnObject = {};
					if ( typeof(validField) != "undefined")  {
						// Check field level CRUD
						var index = 0;
						switch (opType) {
							case INSERT_RECS : index = 1;
								break;
							case READ_RECS : index = 4;
								break;
							case UPDATE_RECS : index = 7;
								break;
							default :
								index = 0;
						}
						if (validField.crud.charAt(index) == "Y" ){
							// Check datatypes
							try {
								returnObject.value = maybeWriteTransformType(fieldVal,validField.appColType,validField.platColType);
								return returnObject;
							} catch (err) {
								returnObject.status = opType + DATATYPE_MISMATCH;
								returnObject.mc_add_status = err + '->' + fieldName;
								return returnObject;
							}
						}
						else {
							returnObject.status = opType + ACCESS_DENIED;
							return returnObject;
						}
					} else {
						returnObject.status = opType + UNKONWN_FIELD;
						returnObject.mc_add_status = fieldName;
						return returnObject;
					}
				}
			}

		/**
		 * listMobileTableColumns :returns a table definition array
		 * This is just a "promise" facade to the one in sysutils.
		 * @param {string} tableName The success callback
		 */
		function listMobileTableColumns(tableName) {
			console.time("MC-TIMING listMobileTableColumns "+ tableName);
			return new Promise(function(resolve, reject) {
			  if ( localStorage['meta-tableDEF-'+tableName] ) {
					console.timeEnd("MC-TIMING listMobileTableColumns "+ tableName);
					resolve(JSON.parse(localStorage['meta-tableDEF-'+tableName]));
			  } else {
					smartStoreUtils.listMobileTableColumns(tableName,smartStoreUtils.FULL,
		        function(res) {
		        	localStorage['meta-tableDEF-'+tableName] = JSON.stringify(res);
							console.timeEnd("MC-TIMING listMobileTableColumns "+ tableName);
		          resolve(res);
		        },
		        function(e) {
							console.timeEnd("MC-TIMING listMobileTableColumns "+ tableName);
		          reject(e);
		        });
				}
			});
		}

		function maybeReadTransformType(fieldVal,FromType,ToType) {
			switch (ToType) {
				case 'checkbox' :
				case 'Deleted' : // TODO - maybe delete this line as it's not really allowed
					return String(fieldVal) === "true";
				case 'CreatedDate' :
				case 'date' :
				case 'datetime' :
				case 'LastActivtyDate' :
				case 'LastModifiedDate' :
				case 'LastReferencedDate' :
				case 'LastViewedDate' :
				case 'SystemModstamp' :
					if ( fieldVal !== null) {
						var d = new Date(fieldVal);
						return d;
					} else {
						return fieldVal;
					}
					break;
				default :
					return fieldVal;
			}
		}

		function maybeWriteTransformType(fieldVal,FromType,ToType) {
			//console.info('fieldVal -> ' + fieldVal + ',FromType -> ' + FromType + ',ToType -> ' + ToType);
			switch (ToType) {
				case 'autonumber' :
					throw "invalid_autonumber";
				case 'checkbox' :
				case 'Deleted' : // TODO - maybe delete this line as it's not really allowed
					if (typeof(fieldVal) === 'boolean' || fieldVal === "true" || fieldVal === "false") {
						return String(fieldVal);
					} else {
						throw "invalid_boolean";
					}
					break;
				case 'date' :
					if (fieldVal instanceof Date) {
						fieldVal.setUTCHours(0);
						fieldVal.setUTCMinutes(0);
						fieldVal.setUTCSeconds(0);
						fieldVal.setUTCMilliseconds(0);
						return fieldVal.valueOf();
					} else if (fieldVal === null) {
						return null;
					} else {
						throw "invalid_date";
					}
					break;
				case 'datetime' :
					//case 'CreatedDate' :
					if (fieldVal instanceof Date) {
						return fieldVal.valueOf();
					} else {
						throw "invalid_datetime";
					}
					break;
				case 'email' :
					if ( isValidEmail(fieldVal) ) {
						return fieldVal;
					} else {
						throw "invalid_email";
					}
					break;
				case 'text_area_rich' :
					if ( isValidStrLength(fieldVal, BYTES, 32000) ) {
						return fieldVal;
					} else {
						throw "invalid_string_too_long";
					}
					break;
				default :
					switch (FromType) {
						case 'jsString' :
							if (typeof(fieldVal) === 'string')  {
								return fieldVal;
							} else if (typeof(fieldVal) === 'number') {
								return fieldVal.toString();
							} else {
								throw "invalid_string";
							}
							break;
						case 'jsNumber' :
							if (typeof(fieldVal) === 'number' || fieldVal === null)  {
								return fieldVal;
							} else {
								throw "invalid_number";
							}
							break;
						default :
					return fieldVal;
					}
			}
		}

		/**
		 * tableExists : checks to see if the table exists. Returns false for non
		 * apptables (e.g. recsToSync will return false) - NO IT DOES NOT
		 * @param {string} tableName
		 * @param {integet} StatusOffset
		 */
		function tableExists(tableName, statusOffset) {
			console.time("MC-TIMING tableExists "+ tableName);
			return new Promise(function(resolve, reject) {
			  var returnObject = {};
			  if ( localStorage['meta-tableCRUD-'+tableName] ) {
					console.timeEnd("MC-TIMING tableExists "+ tableName);
			  	resolve();
			  } else {
					smartStoreUtils.listMobileTables(
			    	smartStoreUtils.ALPHA,
		      	// Success callback
		      	function(tableNames1) {
					    var tableNames  = tableNames1.concat(SYSTEM_TABLES);
							if (tableNames.indexOf(tableName) >= 0) {
								console.timeEnd("MC-TIMING tableExists "+ tableName);
		      			resolve();
		      		} else {
								returnObject.status = statusOffset + UNKONWN_TABLE;
								returnObject.mc_add_status = tableName;
								console.timeEnd("MC-TIMING tableExists "+ tableName);
								reject(returnObject);
		      		}
			      },
		      	function(error) {
							returnObject.status = statusOffset + UNKONWN_ERR;
							returnObject.mc_add_status = "Unkonwn error " + error;
							console.timeEnd("MC-TIMING tableExists "+ tableName);
							reject(returnObject);
				  	});
				}
			});
		}


		/**
		 * validateRecords : performs various record validation/transformation
		 * @param {string} mobileTableName
		 * @param {string} idField
		 * @param {string} opType The operation type (insert | update | etc)
		 * @param {[object]} recs
		 * @param {[obj]} tableDefinition An arr of fieldInfo objects
		 */
		function validateRecords(tableName, idField, opType, records, tableDefinition){
			return new Promise(function(resolve, reject) {
				var returnObject = {};
				var validatedRecs = [];
				returnObject.status = opType;

				getCurrentUserId().then(function(userId) {
					$j.each(records, function(i,record) {
						//console.info("inputRec -> " + JSON.stringify(record));
						// Strip known fields
						delete record._soupEntryId;
						delete record['$$HashKey'];
						for(var fieldName in record) {
						  if(record.hasOwnProperty(fieldName) && fieldName != idField) {
								// check if we know about this field, if we do then maybe transform it.
								// if not, error it.
								isValidFieldRes = isValidFieldAndTranslate(fieldName,
										opType,
										tableDefinition,
										record[fieldName]);
								if ( isValidFieldRes.status == opType + UNKONWN_FIELD ) {
									returnObject.status = isValidFieldRes.status;
									returnObject.mc_add_status = fieldName;
									break;
								} if ( isValidFieldRes.status == opType + DATATYPE_MISMATCH ) {
									returnObject.status = isValidFieldRes.status;
									returnObject.mc_add_status = fieldName;
									break;
								} if ( isValidFieldRes.status == opType + ACCESS_DENIED ) {
									returnObject.status = isValidFieldRes.status;
									returnObject.mc_add_status = fieldName;
									break;
								}
								if ( opType == INSERT_RECS && PROTECTED_FIELDS.indexOf(fieldName) >= 0  ) {
									returnObject.status = opType + PROTECTED_FIELD;
									returnObject.mc_add_status = fieldName;
									break;
								}
								else {
									// maybe perform transform
									record[fieldName] = isValidFieldRes.value;
								}
							}
						}
						if ( returnObject.status != opType + UNKONWN_FIELD &&
								 returnObject.status != opType + DATATYPE_MISMATCH &&
								 returnObject.status != opType + PROTECTED_FIELD) {

							// Add System fields
							var myDate = new Date().getTime();
							if ( opType == INSERT_RECS ) {
								record.CreatedById = userId;
								record.CreatedDate = myDate;
							}
							record.SystemModstamp     = myDate;
							//record.LastActivtyDate  = myDate;
							record.LastModifiedDate   = myDate;
							//record.LastReferencedDate = myDate;
							//record.LastViewedDate   = myDate;
							record.LastModifiedById   = userId;
							record.IsDeleted          = 'false';

							$j.each(tableDefinition, function(i,field) {
								if ( opType == INSERT_RECS ) {
									var insertCrud = field.crud.charAt(1);
									if ( PROTECTED_FIELDS.indexOf(field.path) < 0 &&
											 field.nillable == "false"  &&
											 insertCrud == "Y") { // if CRUD == N then we cannot insert it - see MSD-349
										if (! _.has(record, field.path)) {
											returnObject.status = opType + MANDATORY_MISSING;
											returnObject.mc_add_status = field.path;
										}
									}
								}
								// Populate any proxy refs
								if (field.proxyRefField !== ""){
									if (typeof(record[field.path]) != "undefined" && record[field.path].length > 18) {
										record[field.proxyRefField] = record[field.path];
									}
								}
							});
						}
					});
					returnObject.records = records;
					resolve(returnObject);
				}, function(err) {
					logger.error('Error getting userID' ,JSON.stringify(err));
				});
			});
		}


		/**
		 * Deletes a record from the local table (if valid)
		 * LIMITATION: only can delete non-syn'd recs
		 * @param {string} mobileTableName
		 * @param {[object]} recs
		 * @param {string} idField The field to be used as the ID
		 */
		// TODO, only accepts one rec at the moment
		function deleteRecords(tableName,recs, idField) {
			var returnObject = {};
			var recsToDelete;
			return new Promise(function(resolve, reject) {
				if ( recs.length > 0 ) {
					tableExists(tableName,DELETE_RECS).then(function() {
						return listMobileTableColumns(tableName);
					}).then(function(tableDefinition){
						return checkTableAccess(tableName, DELETE_RECS, tableDefinition);
					}).then(function(tableDefinition) {
						var validFieldsPromise = new Promise(function(resolve, reject) {
							var isValidFieldRes = isValidFieldAndTranslate(idField, DELETE_RECS, tableDefinition);
							if ( isValidFieldRes.status != DELETE_RECS + UNKONWN_FIELD ) {
								validateRecords(tableName, idField, DELETE_RECS, recs, tableDefinition).then(function(validateRecordsRes){
									if ( validateRecordsRes.status == DELETE_RECS ) {
										resolve(validateRecordsRes.records);
									} else {
										reject(validateRecordsRes);
										logger.error(validateRecordsRes);
									}
								});
							} else {
								reject(isValidFieldRes);
								logger.error(isValidFieldRes);
							}
						});
						return validFieldsPromise;
					}).then(function(validRecs) {
						return smartStoreUtils.queryMobileTable(tableName,idField, recs[0][idField]);
					}).then(function(recToDelete){
						if (recToDelete.length === 0){
							returnObject.status = DELETE_RECS + MANDATORY_MISSING;
							logger.warn("deleteRecord no record found", tableName);
							returnObject.mc_add_status = "no record found";
							reject(returnObject);
						} else if (recToDelete[0].Id.length < 19){
							returnObject.status = DELETE_RECS + ACCESS_DENIED;
							logger.warn("deleteRecord Cannot delete synced records");
							returnObject.mc_add_status = "Cannot delete synced records";
							reject(returnObject);
						} else {
							recsToDelete = recToDelete;
							// get list of RTS rec _soupEntryIds as these need to be removed too
							return smartStoreUtils.querySoupRecsPromise('recsToSync');
						}
					}).then(function(rtsRecs){
						console.debug('tableName', tableName);
						console.debug('recsToDelete', recsToDelete);
						console.debug('rts recs', rtsRecs);
						var rtsRecSoupIds = rtsRecs.reduce(function(acc, rec){
							if (rec.Mobile_Table_Name == tableName) {
								if (_.findWhere(recsToDelete, {_soupEntryId : rec.SOUP_Record_Id })) {
									acc.push({'_soupEntryId' : rec._soupEntryId});
								}
							}
							return acc;
						}, []);
						console.debug('rtsRecSoupIds', rtsRecSoupIds);
						smartStoreUtils.deleteRecordsFromSoup(
		        	recsToDelete,tableName,
							function () {
								// need to remove any RTS rec too.
								smartStoreUtils.deleteRecordsFromSoup(
				        	rtsRecSoupIds,'recsToSync',
									function () {
										returnObject.status = DELETE_RECS;
										returnObject.records = recsToDelete;
										resolve(returnObject);
									} ,function(err) {
										reject(err);
									});
							},function(err) {
								reject(err);
							}
						);
					}).catch(function(e){
						reject(e);
					});
				} else {
					returnObject.status = DELETE_RECS;
					logger.warn("deleteRecord No records supplied");
					returnObject.mc_add_status = "No records supplied";
					returnObject.records = [];
					resolve(returnObject);
				}
			});
		} // end deleteRecords



		/**
		 * dirtyTables :returns a list of tableNames that have entries in the RTS
		 */
		function dirtyTables() {
			return new Promise(function(resolve, reject) {
		    readRecords('recsToSync').then(function(resObject) {
	      	var tmpArr = [],
	      			resArr = [];
	      	resObject.records.forEach(function(e){
	      		if (e.Mobile_Table_Name != "Connection_Session__mc" &&
	      				typeof(tmpArr[e.Mobile_Table_Name]) == "undefined") {
							tmpArr[e.Mobile_Table_Name] = true;
							resArr.push(e.Mobile_Table_Name);
						}
	      	});
	      	resolve(resArr);
		    }).catch(function(e){
		    	logger.error(e);
		    	reject(e);
		    });
			});
		} // end dirtyTables

		/**
		 * Inserts a record into the local table (if valid)
		 * @param {string} mobileTableName
		 * @param {[object]} recs
		 */
		function insertRecords(tableName,recs) {
			var returnObject = {};
			return new Promise(function(resolve, reject) {
				tableExists(tableName,INSERT_RECS).then(function(){
					return listMobileTableColumns(tableName);
				}).then(function(tableDefinition){
					return checkTableAccess(tableName, INSERT_RECS, tableDefinition);
				}).then(function(tableDefinition) {
					var validFieldsPromise = new Promise(function(resolve, reject) {
						validateRecords(tableName, null, INSERT_RECS, recs, tableDefinition).then(function(validateRecordsRes){
							if ( validateRecordsRes.status == INSERT_RECS ) {
								resolve(validateRecordsRes.records);
							} else {
								reject(validateRecordsRes);
							}
						});
					});
					return validFieldsPromise;
			}).then(function(validRecs) {
				smartStoreUtils.insertRecords(tableName, validRecs,
				function(res) {
					returnObject.status = INSERT_RECS;
					returnObject.records = res;
					var vsnUtils = mobileCaddy.require('mobileCaddy/vsnUtils');
					vsnUtils.upgradeAvailable().then(function(upAvailable){
						returnObject.upgradeAvailable = upAvailable;
						resolve(returnObject);
					}).catch(function(e){
						resolve(returnObject);
						logger.error(e);
					});
				},
				function(err) {
					reject(err);
					logger.error(err);
				});
			}).catch(function(err) {
				reject(err);
				logger.error(err);
			}); // promise
		});
		} // end insertRecords


		/**
		 * Reads record(s) from the local table (if valid)
		 * @param {string} mobileTableName
		 */
		// TODO : options will be things like order/limit etc
		function readRecords(tableName,options) {
			var returnObject = {};
      var tag = "MC-TIMING readRecords " + tableName;
      console.time(tag);
			return new Promise(function(resolve, reject) {
				tableExists(tableName,READ_RECS).then(function() {
					return checkTableAccess(tableName, READ_RECS);
				}).then(function() {
					return listMobileTableColumns(tableName);
				}).then(function(tableDefinition) {
			  	smartStoreUtils.querySoupRecords(tableName,
						function(records) {
							returnObject.status = READ_RECS;
							$j.each(records, function(i,record) {
								// console.info("rawReadRec -> " + JSON.stringify(record));
								for(var fieldName in record) {
									var validField = _.findWhere(tableDefinition, {'path': fieldName});
									if (typeof(validField) != "undefined") {
										//console.info("validField -> " + JSON.stringify(validField));
										record[fieldName]  = maybeReadTransformType(record[fieldName],validField.appColType,validField.platColType);
									}
								}
								// console.info("parsedReadRec -> " + JSON.stringify(record));
							});
							returnObject.records = records.filter(function(e) {return typeof(e) == 'object';});
   						var vsnUtils = mobileCaddy.require('mobileCaddy/vsnUtils');
							vsnUtils.upgradeAvailable().then(function(upAvailable){
								returnObject.upgradeAvailable = upAvailable;
								console.timeEnd(tag);
								resolve(returnObject);
							}).catch(function(e){
								console.timeEnd(tag);
								resolve(returnObject);
								logger.error(e);
							});
						},
						function(err) {
							console.timeEnd(tag);
				  		reject(err); // Error: "It broke"
							logger.error(err);
						});
					}, function(err) {
						console.timeEnd(tag);
						reject(err);
						logger.error(err);
					}
				);
			});
		}


		/**
		 * Performs a smartSql SELECT from the local table (if valid)
		 * Current Limitation: Only "SELECT * ..." supported
		 * @param {string} smartSql
		 */
		function smartRead(smartSql) {
			var smartstore = cordova.require("com.salesforce.plugin.smartstore");
			var returnObject = {};
			var tablePatt = /\{(\S*)\}/g;
			var res = tablePatt.exec(smartSql);
			tableName = res[1];
			smartSql2 = parseSmartSql(tableName, smartSql);
			console.debug('smartSql2', smartSql2);
			var querySpec = smartstore.buildSmartQuerySpec(smartSql2);
			console.debug('querySpec', querySpec);
      var tag = "MC-TIMING smartRead " + tableName;
      console.time(tag);
			return new Promise(function(resolve, reject) {
				tableExists(tableName,READ_RECS).then(function() {
					return checkTableAccess(tableName, READ_RECS);
				}).then(function() {
					return listMobileTableColumns(tableName);
				}).then(function(tableDefinition) {
			  	smartStoreUtils.smartQuerySoupRecordsWithQuerySpec(querySpec,
						function(records) {
							returnObject.status = READ_RECS;
							var cleanRecs = [];
							$j.each(records, function(i,record) {
								var recordObj = record[1];
								for(var fieldName in recordObj) {
									var validField = _.findWhere(tableDefinition, {'path': fieldName});
									if (typeof(validField) != "undefined") {
										recordObj[fieldName]  = maybeReadTransformType(recordObj[fieldName],validField.appColType,validField.platColType);
									}
								}
								cleanRecs.push(recordObj);
							});
							returnObject.records = cleanRecs.filter(function(e) {return typeof(e) == 'object';});
   						var vsnUtils = mobileCaddy.require('mobileCaddy/vsnUtils');
							vsnUtils.upgradeAvailable().then(function(upAvailable){
								returnObject.upgradeAvailable = upAvailable;
								console.timeEnd(tag);
								resolve(returnObject);
							}).catch(function(e){
								console.timeEnd(tag);
								resolve(returnObject);
								logger.error(e);
							});
						},
						function() {
							//console.timeEnd(tag);
							//logger.error("boo");
				  		reject(); // Error: "It broke"
						});

					}, function(err) {
						console.timeEnd(tag);
						reject(err);
						logger.error(err);
					}
				);
			});
		}

		/**
		 * MSD-289 Reformats query if looking up by ID but passing in a Proxy value
		 * @param  {string} smartSql
		 * @return {string}
		 */
		function parseSmartSql(tableName, smartSql){
			m = smartSql.match(/.* WHERE (.* = .*)/i);
      console.debug('m', m);
      if (m !== null && m[1] !== null) {
        var whereStr = m[1].split("AND");
        var props = {};
        var whereValue = '';

        whereStr.forEach(function(str){
            mWhere = str.match(/{(.*):(.*)} = (.*)/i);
            whereField = mWhere[2];
            whereValue = mWhere[3].split("'")[1];
            props[whereField] = whereValue;
        });

        if ( typeof(props.Id) != "undefined" && props.Id.length > 18 ) {
					var proxyFieldName =  (_.indexOf(MC_TABLES, tableName) > -1) ?
						'mobilecaddy1__MC_Proxy_ID__c' : 'MC_Proxy_ID__c';
        	parsedSmartSql = smartSql.replace("Id} =", proxyFieldName + "} =");
        	return parsedSmartSql;
        } else {
	      	return smartSql;
	      }
      } else {
      	return smartSql;
      }
		}


		function innerProcessRefreshTablePromise(tableName){
			return new Promise(function(resolve, reject) {
				var syncRefresh = require('mobileCaddy/syncRefresh');
				var success = function(res){
					console.debug('innerProcessRefreshTablePromise res', res);
						resolve(res);
				};
				var error = function(e){
					logger.error('innerProcessRefreshTablePromise error', e);
					reject(e);
				};

				var returnObject = {table: tableName};
				syncRefresh.p2mRefreshTable(
						tableName,
						0,
						false,
						function(refreshStatusObject) {
							console.debug('refreshStatusObject', refreshStatusObject);
							if (refreshStatusObject.status == syncRefresh.P2M_REFRESH_OK) {
								returnObject.status = SYNC_OK;
								//returnObject.mc_add_status = refreshStatusObject.mc_add_status;
								success(returnObject);
							} // end status success check if
							else {
								returnObject.status = refreshStatusObject.status;
								returnObject.mc_add_status = refreshStatusObject.mc_add_status;
								success(returnObject);
							} // end status success check else
						},
						error);
			});
		}

		function initialSync(tableNames) {
			console.time('initialSync');
			return new Promise(function(resolve, reject) {
				if (tableNames.length === 0) {
					resolve({ status: SYNC + MANDATORY_MISSING});
				}
				// check we're online
				var returnObject = {};
				var syncRefresh     = require('mobileCaddy/syncRefresh');
				syncRefresh.heartBeat(
					function(heartBeatResultsObject) {
						console.log('heartbeat call gave ' + heartBeatResultsObject.status);
						if ((heartBeatResultsObject.status == syncRefresh.HEARTBEAT_OK) || (heartBeatResultsObject.status == syncRefresh.HEARTBEAT_NOT_DEVICE)  || (heartBeatResultsObject.status == syncRefresh.HEARTBEAT_REFRESHED_OK)) {
							var tabs2Sync = [];
							var resArr = [];
							// get dirty Tables
							dirtyTables().then(function(dirtyTableNames){
								// Take an array of promises and wait on them all
								console.debug('dirtyTableNames', dirtyTableNames);
								// remove from sync list and also start creating the response array
								dirtyTableNames.forEach(function(dirtyTableName){
									dirtyIndex = tableNames.indexOf(dirtyTableName);
									if ( dirtyIndex > -1 ) {
										resArr.push({table: dirtyTableName, status: SYNC_NOK, mc_add_status: 'Dirty records'});
										tableNames.splice(dirtyIndex, 1);
									}
								});
								console.debug('tableNames', tableNames);
								console.debug('resArr', resArr);
								// pre MSD-375
				  			// return Promise.all(
				  			// 	tableNames.map(innerProcessRefreshTablePromise)
				  			// );
				  			// MSD-375
				  			return doInitialSync(tableNames);
				  		}).then(function(res) {
			  				console.debug('doInitialSync res', res);
			  				var resArrFinal = resArr.concat(res);
			  				console.debug('Promise.all resArrFinal', resArrFinal);
			  				console.timeEnd('initialSync');
			  				resolve(resArrFinal);
			  				// clean up conn_sess in the background
			  				var connSessUtils   = require('mobileCaddy/connSessUtils');
			  				var dummyConnSessObj = {mobilecaddy1__Mobile_Process_Status__c : ""};
			  				connSessUtils.maybeSyncConnSess(dummyConnSessObj,
									function(){
										console.log('success return from maybeSyncConnSess');
									},
									function(e){
										reject(e);
										logger.error(e);
									});
			  			}).catch(function(e){
			  				reject(e);
			  				logger.error(e);
			  			});
			  		} else {
							// Pass the return status back to the calling routine
							returnObject.status = SYNC_NOK;
							returnObject.mc_add_status = heartBeatResultsObject.status;
							resolve(returnObject);
							if ( returnObject.mc_add_status == 100101 ||  returnObject.mc_add_status == 100102 ) {
								logger.error(returnObject);
							} else {
								logger.log(returnObject);
							}
						}
					},
					function(e) {
						logger.error(e);
						returnObject.status = SYNC_NOK;
						resolve(returnObject);
					}
				);
			});
		}

		function doInitialSync(tableNames){
			var sequence = Promise.resolve();
			var accum = [];
			return tableNames.reduce(function(sequence, table){
				return sequence.then(function(res) {
					return innerProcessRefreshTablePromise(table);
				}).then(function(res){
					accum.push(res);
					return accum;
				}).catch(function(e){
  				logger.error(e);
  				reject(e);
  			});
		  }, Promise.resolve());
		}

		function syncMobileTable(mobileTableName, syncWithoutLocalUpdates, maxTableAge,maxRecsPerCall) {
			console.time("syncMobileTable");
			syncWithoutLocalUpdates = typeof syncWithoutLocalUpdates !== 'undefined' ? syncWithoutLocalUpdates : true;
			var connSessUtils   = require('mobileCaddy/connSessUtils');
			var syncRefresh     = require('mobileCaddy/syncRefresh');
			var smartStoreUtils = require('mobileCaddy/smartStoreUtils');
			var mobileLogger    = require('mobileCaddy/mobileLogger');

			var M2P_MAX_RECS = 50;

			if (!maxTableAge) maxTableAge = 0;
			if (!maxRecsPerCall) maxRecsPerCall = M2P_MAX_RECS;

			// INNER functions - see further down for start of MAIN processing
			var innerProcessRefreshTable = function(mobileTableName,success,error) {
				var returnObject = {};
				syncRefresh.p2mRefreshTable(
						mobileTableName,
						maxTableAge,
						true,
						function(refreshStatusObject) {
							console.debug('refreshStatusObject', refreshStatusObject);
							if (refreshStatusObject.status == syncRefresh.P2M_REFRESH_OK) {
								returnObject.status = SYNC_OK;
								//returnObject.mc_add_status = refreshStatusObject.mc_add_status;
								success(returnObject);
							} // end status success check if
							else {
								returnObject.status = refreshStatusObject.status;
								returnObject.mc_add_status = refreshStatusObject.mc_add_status;
								success(returnObject);
							} // end status success check else
						},
						error);
			}; // end innerProcessRefreshTable

			// Inner function - will check RTS records and call m2p update if there are records
			var innerCheckRTSAndUpdate = function(mobileTableName,success,error) {
				var returnObject = {};

				// Check if there are any RTS record for this table
				smartStoreUtils.queryMobileTable(
						'recsToSync',
						'Mobile_Table_Name',
						mobileTableName,
						function(recsToSyncForTable) {

							// If we have records we need to perform an update table
							if (recsToSyncForTable.length > 0) {
								syncRefresh.m2pUpdateMobileTable(
										mobileTableName,
										maxRecsPerCall,
										function(m2pStatusObject) {
											console.log('m2pStatusObject', m2pStatusObject);
											if (m2pStatusObject.status == syncRefresh.M2P_UPDATE_OK && typeof(m2pStatusObject.mc_add_status) === 'undefined' ) {
												// set maxTableAge to 0 so that refresh takes place.
												maxTableAge = 0;
												// Pass a 0 for success
												returnObject.status = 0;
												success(returnObject);
											} else if (m2pStatusObject.status == syncRefresh.M2P_UPDATE_OK && m2pStatusObject.mc_add_status === 'more-to-sync'){
												console.log('moreToSync - Going round again');
												innerCheckRTSAndUpdate(mobileTableName,success,error);
											} else {
												// Pass a 1 for failure
												returnObject.status = m2pStatusObject.status;
												returnObject.mc_add_status = m2pStatusObject.mc_add_status;
												success(returnObject);
											}
										},
										error);
							} // end rts recs found check if
							else {
								returnObject.status = 2;
								returnObject.mc_add_status = 'no-sync-no-updates';
								success(returnObject);
							} // end rts recs found check else
						},
						error);
			}; // end innerCheckRTSAndUpdate

			// Inner function - called either on callback of the csStatus check or directly if we have
			// no pending connection sessions in the RTS
			var innerProcessM2PUpdate = function(mobileTableName, syncType, syncWithoutLocalUpdates, success, error) {
				var returnObject = {};
				// Submit/refresh route check
				if ((syncType == 'Dynamic (Submit First/Retain)') || (syncType == 'Dynamic (Submit First/Clear)')) {

					innerCheckRTSAndUpdate(
						mobileTableName,
						function(statusObject) {
							// Success call to update then do the refresh
							if (statusObject.status === 0 || (syncWithoutLocalUpdates && statusObject.status == 2)) {
								// Success then directly call the refresh
								innerProcessRefreshTable(mobileTableName,success,error);
							} // end success update check if
							else if (statusObject.status == 2) {
								returnObject.status = SYNC_OK;
								returnObject.mc_add_status = statusObject.mc_add_status;
								success(returnObject);
							}
							else {
								// Anything other than success, we perform the callback
								// with a success status.  Pass back the additional info from the
								// refresh call too.
								returnObject.status = SYNC_NOK;
								returnObject.mc_add_status = statusObject.mc_add_status;
								success(returnObject);
							} // end success update check else
						},
						error);
				} // end submit/refresh check if
				else if ((syncType == 'Submit Only') || (syncType == 'Submit & Clear') ||  (syncType == 'Submit & Destroy')) {

					// Perform an update only
					innerCheckRTSAndUpdate(
						mobileTableName,
						function(statusObject) {

							// Success
							if (statusObject.status === 0) {
								returnObject.status = SYNC_OK;
								success(returnObject);
							} // end success update check if
							else {
								// Anything other than success, we perform the callback
								// with a success status.  Pass back the additional info from the
								// refresh call too.
								returnObject.status = SYNC_NOK;
								returnObject.mc_add_status = statusObject.mc_add_status;
								success(returnObject);
							} // end success update check else
						},
						error);
				} // end submit only check if
				else {
					logger.error('Unknown sync type', syncType);
				} // end refresh check else
			}; // end processTableRefresh

			// MAIN processing starts here
			//
			return new Promise(function(resolve, reject) {
				var returnObject = {};
				var success = function(status) {resolve(status);};
				var error = function(err) {reject(err);};
				// MSD-167 basic race condition checking
				var lsKey = 'syncTime' + mobileTableName,
						lastSyncReqTime = localStorage.getItem(lsKey),
						timeNow = new Date().valueOf(),
						syncBuffer = (lastSyncReqTime) ? parseInt(lastSyncReqTime) + 5000 : 0;
				if (mobileTableName != "Connection_Session__mc" && timeNow < syncBuffer) {
					returnObject.status = SYNC_OK;
					returnObject.mc_add_status = "sync-too-soon";
					console.timeEnd("syncMobileTable");
					resolve(returnObject);
				} else {
					localStorage.setItem(lsKey, timeNow);


					tableExists(mobileTableName,SYNC).then(function() {
						// Get the table refresh type
						//
						// TODO - MOVE THIS AROUND SO IT IS
						//  1) LOCAL CONNECTION CHECK
						//  2) HEARTBEAT
						//  3) GETPENDINGRTS
						//  4) SYNC CHECK
						//
						// Do a heartbeat check as we are now going to
						// access Salesforce
						syncRefresh.heartBeat(
							function(heartBeatResultsObject) {
								console.log('heartbeat call gave ' + heartBeatResultsObject.status);
								if ((heartBeatResultsObject.status == syncRefresh.HEARTBEAT_OK) || (heartBeatResultsObject.status == syncRefresh.HEARTBEAT_NOT_DEVICE)  || (heartBeatResultsObject.status == syncRefresh.HEARTBEAT_REFRESHED_OK)) {
									smartStoreUtils.getTableDefnColumnValue(
										mobileTableName,
										'Sync Type',
										function(syncType) {
											// Get list of records to sync with pending connection session
											connSessUtils.getRTSPendingconnSess(
												function(statusCheckCSProxyId) {
													// We got some pending RTS records with a connection session.
													// Call csStatusCheck to deal with them
													if (statusCheckCSProxyId !== null && typeof(statusCheckCSProxyId) != "undefined") {
														connSessUtils.csStatusCheck(
															statusCheckCSProxyId,
															function(connSessStatusObject) {
																if (connSessStatusObject.status == connSessUtils.CONN_SESS_OK) {
																	if (syncType == 'Refresh Only' || syncType == 'Refresh & Clear') {
																		innerProcessRefreshTable(mobileTableName,success,error);
																	} else {
																		innerProcessM2PUpdate(mobileTableName,syncType, syncWithoutLocalUpdates, success,error);
																	}
																} // end conn sess ok check if
																else {
																	// Not a success so call the success callback, passing in the
																	// error number
																	returnObject.status = SYNC_OK;
																	returnObject.mc_add_status = connSessStatusObject.status;
																	console.timeEnd("syncMobileTable");
																	resolve(returnObject);
																} // end conn sess ok check else
															}, // end success callback
															function(e) {
																logger.error(e);
																reject(e);
															});
													} // end pending records present check if
													else {
														// No pending connection session records so continue.
														//
														if (syncType == 'Refresh Only' || syncType == 'Refresh & Clear') {
															innerProcessRefreshTable(mobileTableName,success,error);
														} else {
															innerProcessM2PUpdate(mobileTableName,syncType,syncWithoutLocalUpdates, success,error);
														}
													} // end pending records present check else
												},
												error
											);
										},
										error); // END getTableDefnColumnValue
								} // end heartbeat OK
								else {
									// Pass the return status back to the calling routine
									returnObject.status = SYNC_NOK;
									returnObject.mc_add_status = heartBeatResultsObject.status;
									console.timeEnd("syncMobileTable");
									resolve(returnObject);
									if ( returnObject.mc_add_status == 100101 ||  returnObject.mc_add_status == 100102 ) {
										logger.error(returnObject);
									} else {
										logger.log(returnObject);
									}
								}
							},
							error);
						}
					).catch(error);
				}
			});
		} // end syncMobileTable


		/**
		 * Updtes a record into the local table (if valid)
		 * @param {string} mobileTableName
		 * @param {[object]} recs
		 * @param {string} idField The field to be used as the ID
		 */
		function updateRecords(tableName,recs, idField) {
			var returnObject = {};
			return new Promise(function(resolve, reject) {
				if ( recs.length > 0 ) {
					tableExists(tableName,UPDATE_RECS).then(function() {
						return listMobileTableColumns(tableName);
					}).then(function(tableDefinition){
						return checkTableAccess(tableName, UPDATE_RECS, tableDefinition);
					}).then(function(tableDefinition) {
						var validFieldsPromise = new Promise(function(resolve, reject) {
							var isValidFieldRes = isValidFieldAndTranslate(idField, UPDATE_RECS, tableDefinition);
							if ( isValidFieldRes.status != UPDATE_RECS + UNKONWN_FIELD ) {
								validateRecords(tableName, idField, UPDATE_RECS, recs, tableDefinition).then(function(validateRecordsRes){
									if ( validateRecordsRes.status == UPDATE_RECS ) {
										resolve(validateRecordsRes.records);
									} else {
										reject(validateRecordsRes);
									}
								});
							} else {
								reject(isValidFieldRes);
							}
						});
						return validFieldsPromise;
					}).then(function(validRecs) {
						smartStoreUtils.updateRecordsWithExternalId(
		        	tableName,validRecs, idField,
							function (retRecs) {
								returnObject.status = UPDATE_RECS;
								returnObject.records = retRecs;
   							var vsnUtils = mobileCaddy.require('mobileCaddy/vsnUtils');
   							vsnUtils.upgradeAvailable().then(function(res){
   								returnObject.upgradeAvailable = res;
									resolve(returnObject);
   							}).catch(function(e){
									resolve(returnObject);
   							});
							} ,function(err) {
								reject(err);
 								logger.error(err);
							});
					}, function(err) {
						reject(err);
						logger.error(err);
					});
				} else {
					returnObject.status = UPDATE_RECS;
					returnObject.mc_add_status = "No records supplied";
					returnObject.records = [];
					resolve(returnObject);
					logger.warn(returnObject);
				}
			});
		} // end updateRecords

		// Exposed functions
		module.exports = {
				// returnObject.status codes
				SYNC_OK : SYNC_OK,
				SYNC_NOK : SYNC_NOK,
				SYNC_ALREADY_IN_PROGRESS : SYNC + SYNC_ALREADY_IN_PROGRESS,
				SYNC_UNKONWN_TABLE: SYNC + UNKONWN_TABLE,
				SYNC_MANDATORY_MISSING: SYNC + MANDATORY_MISSING,
				DELETE_RECS_OK : DELETE_RECS,
				DELETE_RECS_UNKONWN_TABLE: DELETE_RECS + UNKONWN_TABLE,
				DELETE_RECS_UNKONWN_FIELD: DELETE_RECS + UNKONWN_FIELD,
				DELETE_RECS_ACCESS_DENIED: DELETE_RECS + ACCESS_DENIED,
				DELETE_RECS_MANDATORY_MISSING: DELETE_RECS + MANDATORY_MISSING,
				INSERT_RECS_OK : INSERT_RECS,
				INSERT_RECS_UNKONWN_TABLE: INSERT_RECS + UNKONWN_TABLE,
				INSERT_RECS_UNKONWN_FIELD: INSERT_RECS + UNKONWN_FIELD,
				INSERT_RECS_ACCESS_DENIED: INSERT_RECS + ACCESS_DENIED,
				INSERT_RECS_MANDATORY_MISSING: INSERT_RECS + MANDATORY_MISSING,
				INSERT_RECS_DATATYPE_MISMATCH: INSERT_RECS + DATATYPE_MISMATCH,
				INSERT_RECS_PROTECTED_FIELD: INSERT_RECS + PROTECTED_FIELD,
				READ_RECS_OK: READ_RECS,
				READ_RECS_UNKONWN_TABLE: READ_RECS + UNKONWN_TABLE,
				READ_RECS_ACCESS_DENIED: READ_RECS + ACCESS_DENIED,
				UPDATE_RECS_OK: UPDATE_RECS,
				UPDATE_RECS_UNKONWN_TABLE: UPDATE_RECS + UNKONWN_TABLE,
				UPDATE_RECS_UNKONWN_FIELD: UPDATE_RECS + UNKONWN_FIELD,
				UPDATE_RECS_ACCESS_DENIED: UPDATE_RECS + ACCESS_DENIED,
				UPDATE_RECS_DATATYPE_MISMATCH: UPDATE_RECS + DATATYPE_MISMATCH,
				UPDATE_RECS_UNKNOWN_ID: UPDATE_RECS + UNKNOWN_ID,

				analInc: function(key) {
					return analInc(key);
				},

				deleteRecord : function(tableName,rec, idField) {
					return deleteRecords(tableName,[rec], idField);
				},
				// TODO - need to implement this
				// deleteRecords : function(tableName,recs, idField) {
				// 	return deleteRecords(tableName,recs, idField);
				// },
				dirtyTables: function(){
					return dirtyTables();
				},
				syncMobileTable : function(tableName,syncWithoutLocalUpdates, maxTableAge, maxRecsPerCall) {
					return syncMobileTable(tableName, syncWithoutLocalUpdates, maxTableAge, maxRecsPerCall);
				},
				initialSync : function(tableNames) {
					return initialSync(tableNames);
				},
				getCurrentUserId: function(){
					return getCurrentUserId();
				},
				insertRecord : function(tableName,rec) {
					return insertRecords(tableName,[rec]);
				},
				insertRecords : function(tableName,recs) {
					return insertRecords(tableName,recs);
				},
				readRecords : function(tableName,options) {
					console.debug("readRecords", tableName);
					return readRecords(tableName,options);
				},
				smartSql: function(smartSql){
					console.debug("smartSql", smartSql);
					return smartRead(smartSql);
				},
				updateRecord : function(tableName,rec, idField) {
					return updateRecords(tableName,[rec], idField);
				},
				updateRecords : function(tableName,recs, idField) {
					return updateRecords(tableName,recs, idField);
				},
				maybeReadTransformType : function(fieldVal,FromType,ToType) {
					return maybeReadTransformType(fieldVal,FromType,ToType);
				},
				maybeWriteTransformType : function(fieldVal,FromType,ToType) {
					return maybeWriteTransformType(fieldVal,FromType,ToType);
				}
		}; // end export section
	}); // end devUtils

	// The mobileCaddy module becomes a global (and hence an entry point)
	window.mobileCaddy = require('mobileCaddy');
})();
