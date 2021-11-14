/**
 * starter.controllers module
 *
 * @description defines starter.controllers module
 */
(function() {
  'use strict';

  angular.module('starter.controllers', ['ionic']);

})();
/**
 * Deploy Controller
 *
 * @description controller for the Deploy to Salesforce
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('DeployCtrl', DeployCtrl);

  DeployCtrl.$inject = ['$scope', 'DeployService'];

  function DeployCtrl($scope, DeployService) {


	  function iconForErr(errType) {
	    switch(errType) {
	        case 'info':
	            return 'ion-information-circled';
	        default:
	            return 'ion-close-round';
	    }
	  }

	  var messages = [{message : 'Uploading bundle...', type : ''}];
	  var appConfig = {};

	  $scope.messages = messages;

	  DeployService.getDetails().then(function(data){
	    console.log('data', data);
	    appConfig = data;
	    return DeployService.deployBunlde(appConfig);
	  }).then(function(res){
	    console.dir(res);
	    var msg = {message : res, type : 'ok', icon : "ion-checkmark-round"};
	    $scope.$apply(function() {
	      $scope.messages.push(msg);
	      msg = {message : 'Uploading cache manifest...', type : ''};
	      $scope.messages.push(msg);
	    });
	    return DeployService.uploadCachePage(appConfig);
	  }).then(function(res){
	    console.dir(res);
	    var msg = {message : res, type : 'ok', icon : "ion-checkmark-round"};
	    $scope.$apply(function() {
	      $scope.messages.push(msg);
	      msg = {message : 'Uploading start page...', type : ''};
	      $scope.messages.push(msg);
	    });
	    return DeployService.uploadStartPage(appConfig);
	  }).then(function(res){
	    console.dir(res);
	    var msg = {message : res, type : 'ok', icon : "ion-checkmark-round"};
	    $scope.$apply(function() {
	      $scope.messages.push(msg);
	      msg = {message : 'Deploy Completed successfully.', type : 'final'};
	      $scope.messages.push(msg);
	    });
	  }).catch(function(err){
	    var msg = {message : err.message, type : err.type,  icon : iconForErr(err.type)};
	    $scope.$apply(function() {
	      $scope.messages.push(msg);
	      if (err.type != 'error') {
	         msg = {message : 'Deploy Completed successfully.', type : 'final'};
	        $scope.messages.push(msg);
	      }
	    });
	    console.debug(err);
	  });

  }

})();
/**
 * SettingsHB Controller
 *
 * @description Controller for settings heartbeat dev tool
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('SettingsHBCtrl', SettingsHBCtrl);

  SettingsHBCtrl.$inject = ['$scope', 'NetworkService'];

  function SettingsHBCtrl($scope, NetworkService) {

    if (localStorage.connection) {
      $scope.heartbeatStatus = localStorage.connection;
    } else {
      $scope.heartbeatStatus = 100100;
    }

    $scope.hbUpdate = function() {
      localStorage.connection = $scope.heartbeatStatus;
      if ($scope.heartbeatStatus == 100100) NetworkService.networkEvent('online');
      if ($scope.heartbeatStatus == 100103) NetworkService.networkEvent('offline');
    };

  }

})();
/**
 * MTI Controller
 *
 * @description controller for the MTI listing
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('MTICtrl', MTICtrl);

  MTICtrl.$inject = ['$scope', '$rootScope', '$location', '$ionicPopup', '$ionicLoading', 'DevService', 'devUtils', 'logger'];

  function MTICtrl($scope, $rootScope, $location, $ionicPopup, $ionicLoading, DevService, devUtils, logger) {

	  var adminTimeout = (1000 * 60 *5 ); // 5 minutes
	  if ( $rootScope.adminLoggedIn > Date.now() - adminTimeout) {
	  } else {
	    $location.url('tab/settings');
	    var alertPopup = $ionicPopup.alert({
	      title: 'Access Denied'
	    });
	    alertPopup.then(function(res) {
	      //$location.url('tab/settings');
	      $scope.$apply();
	    });
	  }

	  DevService.allTables().then(function(tables) {
	    $scope.tables = tables;
	  }, function(reason) {
	    console.error('Angular: promise returned reason -> ' + reason);
	  });

	  $scope.showTable = function(tableName) {
	    $location.path(decodeURIComponent("/tab/settings/mti/" + tableName));
	  };

	  $scope.syncTable = function(tableName) {
	    var confirmPopup = $ionicPopup.confirm({
	      title: 'Sync Table',
	      template: "<div style='text-align:center;'>Are you sure you want to sync " + tableName + "?</div>",
	      cancelText: 'No',
	      okText: 'Yes',
	    });
	    confirmPopup.then(function(res) {
	      if (res) {
	        $ionicLoading.show({
	          duration: 10000,
	          template: 'Syncing ' + tableName + " ..."
	        });
	        devUtils.syncMobileTable(tableName).then(function(resObject){
	          $ionicLoading.hide();
	        }).catch(function(e){
	          logger.error('syncTable from settings ' + tableName + " " + JSON.stringify(e));
	          $ionicLoading.hide();
	          var alertPopup = $ionicPopup.alert({
	            title: 'Operation failed!',
	            template: '<p>Sorry, something went wrong.</p><p class="error_details">Error: ' + e.status + ' - ' + e.mc_add_status + '</p>'
	          });
	        });
	      }
	    });
	  };

	  $scope.saveTableToML = function(tableName) {
	    var confirmPopup = $ionicPopup.confirm({
	      title: 'Save Table To Mobile Log',
	      template: "<div style='text-align:center;'>Are you sure you want to save " + tableName + "?</div>",
	      cancelText: 'No',
	      okText: 'Yes',
	    });
	    confirmPopup.then(function(res) {
	      if (res) {
	        $ionicLoading.show({
	          duration: 10000,
	          template: 'Saving ' + tableName + " ..."
	        });
	        // Read the table records
	        DevService.allRecords(tableName, false).then(function(tableRecs) {
	          // console.log("tableRecs",angular.toJson(tableRecs));
	          return DevService.insertMobileLog(tableRecs);
	        }).then(function(resObject) {
	          // console.log("mc resObject",resObject);
	          $ionicLoading.hide();
	        }).catch(function(e){
	          logger.error('saveTableToML ' + tableName + " " + JSON.stringify(e));
	          $ionicLoading.hide();
	          var alertPopup = $ionicPopup.alert({
	            title: 'Operation failed!',
	            template: '<p>Sorry, something went wrong.</p><p class="error_details">Error: ' + e.status + ' - ' + e.mc_add_status + '</p>'
	          });
	        });
	      }
	    });
	  };

  }

})();
/**
 * MTIDetail Controller
 *
 * @description controller for the MTI details (per table)
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('MTIDetailCtrl', MTIDetailCtrl);

  MTIDetailCtrl.$inject = ['$scope', '$stateParams', '$ionicLoading', '$ionicModal', 'DevService'];

  function MTIDetailCtrl($scope, $stateParams, $ionicLoading, $ionicModal, DevService) {

	  $ionicLoading.show({
	      duration: 30000,
	      noBackdrop: true,
	      template: '<p id="app-progress-msg" class="item-icon-left"><i class="icon ion-loading-c"></i>Fetching records...</p>'
	    });
	  $scope.table = {'Name': $stateParams.tableName};
	  DevService.allRecords($stateParams.tableName, false)
	    .then(function(tableRecs) {
	    $scope.tableRecs = tableRecs;
	    $ionicLoading.hide();
	  }, function(reason) {
	    console.error('Angular: promise returned error -> ' + reason);
	  });

	  $scope.getItemHeight = function(item, index) {
	    return (typeof(item) != "undefined")  ? 100 + item.length*55 : 0;
	  };

	  $scope.search = {};

	  $scope.clearSearch = function() {
	    $scope.search.query = "";
	  };

	  $scope.showRecord = function(tableRec, soupRecordId) {
	    $ionicLoading.show({
	      duration: 10000,
	      template: 'Loading...'
	    });
	    var tableName;
	    for (i = 0, len = tableRec.length; i < len; i++) {
	      if (tableRec[i].Name == "Mobile_Table_Name") {
	        tableName = tableRec[i].Value;
	      }
	    }
	    console.log("tableName",tableName, soupRecordId);
	    DevService.getRecordForSoupEntryId(tableName, soupRecordId).then(function(record) {
	      console.log("record",record);
	      $scope.showTableRecord(tableName, record, soupRecordId);
	      $ionicLoading.hide();
	    }, function(reason) {
	      $ionicLoading.hide();
	      console.error('getRecordForSoupEntryId ' + reason);
	    });
	  };

	  $scope.showTableRecord = function(tableName, record, soupRecordId) {
	    $ionicModal.fromTemplateUrl('settingDevMTITableRecord.html', function(modal) {
	      $scope.tableRecordModal = modal;
	      $scope.tableRecordModal.tableName = tableName;
	      $scope.tableRecordModal.record = record;
	      $scope.tableRecordModal.soupRecordId = soupRecordId;
	      $scope.tableRecordModal.show();
	    }, {
	      scope: $scope,
	      animation: 'slide-in-up',
	      backdropClickToClose : false
	    });
	  };

	  $scope.closeShowTableRecord = function() {
	    $scope.tableRecordModal.hide();
	    $scope.tableRecordModal.remove();
	    delete $scope.tableRecordModal;
	  };

  }

})();
/**
 * NewExpense Controller
 *
 * @description controller for new expenses
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('NewExpenseCtrl', NewExpenseCtrl);

  NewExpenseCtrl.$inject = ['$scope', '$rootScope', '$stateParams', '$ionicLoading', '$ionicPopup', '$ionicModal', '$location', '$cordovaBarcodeScanner', 'ProjectService', 'Camera', 'OrderService', 'ProductService'];

  function NewExpenseCtrl($scope, $rootScope, $stateParams, $ionicLoading, $ionicPopup, $ionicModal, $location, $cordovaBarcodeScanner, ProjectService, Camera, OrderService, ProductService) {

      $scope.selectedSurgeon = "Select a surgeon";
      $scope.selectedProduct = "Select a product";

      $scope.forms = {};

      $rootScope.$on('surgeon-updated', function(event, args) {
		    $scope.selectedSurgeon = OrderService.getSelectedSurgeon().mobilecaddy1__Short_Description__c + ', ' + OrderService.getSelectedSurgeon().mobilecaddy1__Expense_Type__c;
		});

      $rootScope.$on('product-updated', function(event, args) {
		    $scope.selectedProduct = OrderService.getSelectedProduct().name;
		});

  	  $scope.showSurgeons = function() {
  	  	$location.path('tab/project/order/new/' +  $scope.project.Id + '/surgeons');
  	  };

  	  $scope.showProducts = function() {
  	  	$location.path('tab/project/order/new/' +  $scope.project.Id + '/products');
  	  };

	  switch ($stateParams.type) {
	      case 'order' :
	        $scope.paramType = "Order";
	        break;
	      case 'surgeon' :
	      	$scope.paramType = "Surgeon";
	      	break;
	      default :
	        $scope.paramType = 'Other';
	    }

	    console.log("Statetype: " + $stateParams.type);
  		console.log("paramtype: " + $scope.paramType);
  		 console.log("stateparams: " + JSON.stringify($stateParams));



	  $scope.projectId = $stateParams.projectId;
	  $scope.description = "";
	  $scope.project = ProjectService.get($stateParams.projectId);

	  /* 
	   * Handle submitForm
	   */
	  $scope.submitForm = function() {

	  	var trueState = {
	    	'order': 'time',
	    	'surgeon': 'expense'
	    };

	  	var newExp = {};
	  	var newOrder = {};

	  	if (trueState[$stateParams.type] === 'expense') {
		    newExp = {
		      "mobilecaddy1__Short_Description__c": $scope.forms.expenseForm.description.$modelValue,
		      "Name": 'TMP-' + Date.now(),
		      "mobilecaddy1__Project__c": $stateParams.projectId
		    };
		} else {

	      	var surgeonId = OrderService.getSelectedSurgeon().Name;
	      	var productId = OrderService.getSelectedProduct().productId;


			newExp = {
		      "mobilecaddy1__Short_Description__c": JSON.stringify({
		      	sId: surgeonId,
		      	pId: productId
		      }),
		      "Name": 'TMP-' + Date.now(),
		      "mobilecaddy1__Project__c": $stateParams.projectId
		    };
		}

	    switch (trueState[$stateParams.type]) {
	      case 'time' :
	        newExp.mobilecaddy1__Duration_Minutes__c = 0;
	        newExp.mobilecaddy1__Expense_Type__c = 'time';
	        break;
	      default :
	        newExp.mobilecaddy1__Expense_Amount__c = 0;
	        newExp.mobilecaddy1__Expense_Type__c = $scope.forms.expenseForm.expenseType.$modelValue;
	    }
	    $ionicLoading.show({
	      duration: 30000,
	      delay : 400,
	      maxWidth: 600,
	      noBackdrop: true,
	      template: '<h1>Saving...</h1><p id="app-progress-msg" class="item-icon-left">Saving ' + trueState[$stateParams.type] + ' record...<ion-spinner/></p>'
	    });

	    console.log(newExp);

	    if (trueState[$stateParams.type] === 'expense') {
		    ProjectService.newExpense(newExp,
		      function(){
		        $ionicLoading.hide();
		        $rootScope.$broadcast('refreshProjectTotals');
		        $location.path("/tab/project/" + $stateParams.projectId);
		      },
		      function(e) {
		        console.error('NewExpenseCtrl, error', e);
		        $ionicLoading.hide();
		        var alertPopup = $ionicPopup.alert({
		          title: 'Insert failed!',
		          template: '<p>Sorry, something went wrong.</p><p class="error_details">Error: ' + e.status + ' - ' + e.mc_add_status + '</p>'
		        });
		      });
		} else {
			ProjectService.newExpense(newExp,
		      function(){
		        $ionicLoading.hide();
		        $rootScope.$broadcast('refreshProjectTotals');
		        $location.path("/tab/project/" + $stateParams.projectId);
		      },
		      function(e) {
		        console.error('NewExpenseCtrl, error', e);
		        $ionicLoading.hide();
		        var alertPopup = $ionicPopup.alert({
		          title: 'Insert failed!',
		          template: '<p>Sorry, something went wrong.</p><p class="error_details">Error: ' + e.status + ' - ' + e.mc_add_status + '</p>'
		        });
		      });
		}
	  };

	  $scope.scanImageData = null;

	  $scope.scanBarcode = function() {
	    if (cordova && cordova.plugins && cordova.plugins.barcodeScanner) {
	      $cordovaBarcodeScanner.scan().then(function(imageData) {
	        //console.log("Cancelled -> " + imageData.cancelled);
	        if (!imageData.cancelled) {
	          $scope.scanImageData = imageData;
	          //console.log("Barcode Format -> " + imageData.format);
	        }
	      }, function(error) {
	        console.error(err);
	      });
	    } else {
	      $scope.scanImageData = "0";
	    }

	    var product = ProductService.get($scope.scanImageData);

	    if (product) {
	    	OrderService.setSelectedProduct(product);
	    	$scope.selectedProduct = OrderService.getSelectedProduct().name;
	    }
	  };

	  $scope.photoImageData = null;

	  $scope.capturePhoto = function() {
	    Camera.getPicture().then(function(imageData) {
	      //console.log('capturePhoto success');
	      $scope.photoImageData = imageData;
	    }, function(err) {
	      console.error(err);
	    });
	  };

  }

})();
/**
 * ProjectIndex Controller
 *
 * @description Controller for the products listing
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('ProductIndexCtrl', ProductIndexCtrl);

  ProductIndexCtrl.$inject = ['$scope', '$rootScope', '$ionicLoading', '$interval', '$timeout', 'ProductService', 'SyncService', 'devUtils'];

  function ProductIndexCtrl($scope, $rootScope, $ionicLoading, $interval, $timeout, ProductService, SyncService, devUtils) {

	  // This unhides the nav-bar. The navbar is hidden in the cases where we want a
	  // splash screen, such as in this app
	  var e = document.getElementById('my-nav-bar');
	  angular.element(e).removeClass( "mc-hide" );

	  // Set height of list scrollable area
	  var winHeight = window.innerHeight - 125;
	  var productsList = document.getElementById('product-list');
	  productsList.setAttribute("style","height:" + winHeight + "px");

	  // Get reference to refresh/sync button (so we can change text, disable etc)
	  var storesSyncButton = document.getElementById('products-sync-button');

	  // Adjust width of list refresh/sync button (cater for multiple buttons on different pages)
	  var syncButtons = document.getElementsByClassName('sync-button');
	  // If you need adjust the width of the refresh/sync button on the list then uncomment and amend following code.
	  // Currently, the css on the button will set the width to 100%.
	  /*  for (var i = syncButtons.length - 1; i >= 0; --i) {
	    syncButtons[i].setAttribute("style","width:" + productsList.offsetWidth + "px");
	  }*/

	  // Setup the loader and starting templates
	  if (typeof($rootScope.child) == "undefined") {
	    $ionicLoading.show({
	      duration: 30000,
	      delay : 400,
	      maxWidth: 600,
	      noBackdrop: true,
	      template: '<h1>Loading...</h1><p id="app-progress-msg" class="item-icon-left">Fetching Hospitals...<ion-spinner/></p>'
	    });
	  }

	  var localProjCB = function(localProjects) {
	    $rootScope.products = localProjects;
	    if (localProjects.length > 0) $ionicLoading.hide();
	  };

	  ProductService.all($rootScope.refreshFlag, localProjCB).then(function(products) {
	    $rootScope.products = products;
	    //console.log('ProductIndexCtrl, got products');
	    $ionicLoading.hide();
	    syncButtonsClass("Remove", "ng-hide");
	  }, function(reason) {
	    //console.log('promise returned reason -> ' + reason);
	  });
	  $rootScope.refreshFlag = false;

	  $scope.doRefreshFromPulldown = function() {
	  	//console.log('doRefreshFromPulldown');
	  	ProductService.all(true).then(function(products) {
	      $rootScope.products = products;
	    }, function(reason) {
	      //console.log('promise returned reason -> ' + reason);
	    });
	  };

	  $scope.doRefreshAndSync = function() {
	    //console.log('doRefreshAndSync');
	    ProductService.all(false).then(function(products) {
	      $rootScope.products = products;
	      if (SyncService.getSyncState() != "Syncing") {
	        SyncService.syncTables(['MC_Project__ap', 'MC_Time_Expense__ap'], true);
	      }
	    }, function(reason) {
	      //console.log('promise returned reason -> ' + reason);
	    });
	  };

	  $scope.search = {};

	  $scope.clearSearch = function() {
	    $scope.search.query = "";
	  };

	  $rootScope.$on('handleSyncTables', function(event, args) {
	    //console.log("handleSyncTables called args", args);
	    switch (args.result.toString()) {
	      case "Sync" :
	        updateSyncButtonsText("Syncing...");
	        syncButtonsClass("Add", "disabled");
	        break;
	      case "Complete" :
	        updateSyncButtonsText("Refresh and Sync");
	        syncButtonsClass("Remove", "disabled");
	        break;
	      case "100497" :
	        updateSyncButtonsText("No device records to sync...");
	        syncButtonsClass("Remove", "disabled");
	        $timeout( function() {
	          updateSyncButtonsText("Refresh and Sync");
	        },5000);
	        break;
	      case "100498" :
	        updateSyncButtonsText("Sync already in progress...");
	        syncButtonsClass("Remove", "disabled");
	        $timeout( function() {
	          updateSyncButtonsText("Refresh and Sync");
	        },5000);
	        break;
	      case "100402" :
	        updateSyncButtonsText("Please connect before syncing");
	        syncButtonsClass("Remove", "disabled");
	        break;
	      default :
	        if (args.result.toString().indexOf("Error") >= 0) {
	          updateSyncButtonsText(args.result.toString());
	          $timeout( function() {
	            updateSyncButtonsText("Refresh and Sync");
	          },5000);
	        } else {
	          updateSyncButtonsText("Refresh and Sync");
	        }
	        syncButtonsClass("Remove", "disabled");
	    }
	  });

	  function updateSyncButtonsText(newText) {
	    for (var i = syncButtons.length - 1; i >= 0; --i) {
	      angular.element(syncButtons[i]).html(newText);
	    }
	  }

	  function syncButtonsClass(action, className) {
	    for (var i = syncButtons.length - 1; i >= 0; --i) {
	      if (action == "Remove") {
	        angular.element(syncButtons[i]).removeClass(className);
	        if (className == "disabled") {
	          SyncService.setSyncState("Complete");
	        }
	      } else {
	        angular.element(syncButtons[i]).addClass(className);
	        if (className == "disabled") {
	          SyncService.setSyncState("Syncing");
	        }
	      }
	    }
	  }

	  $interval(function() {
	    $scope.checkIfSyncRequired();
	  }, (1000 * 60 * 3));

	  $scope.checkIfSyncRequired = function() {
	    //console.log("checkIfSyncRequired");
	    // Any dirty tables to sync?
	    devUtils.dirtyTables().then(function(tables){
	      if (tables && tables.length !== 0) {
	        // Is the 'Refresh and Sync' enabled?
	        if (!angular.element(storesSyncButton).hasClass("disabled")) {
	          updateSyncButtonsText("Sync Required");
	          syncButtonsClass("Remove", "disabled");
	        }
	      }
	    });
	  };

  }

})();
/**
 * SelectProduct Controller
 *
 * @description controller for new expenses
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('SelectProductCtrl', SelectProductCtrl);

  SelectProductCtrl.$inject = ['$scope', '$rootScope', '$stateParams', '$ionicLoading', '$ionicPopup', '$ionicModal', '$location', '$cordovaBarcodeScanner', 'ProjectService', 'Camera', 'OrderService', 'ProductService'];

  function SelectProductCtrl($scope, $rootScope, $stateParams, $ionicLoading, $ionicPopup, $ionicModal, $location, $cordovaBarcodeScanner, ProjectService, Camera, OrderService, ProductService) {

      var winHeight = window.innerHeight - 125;
      var productsList = document.getElementById('product-list');
      productsList.setAttribute("style","height:" + winHeight + "px");


      $scope.setSelectedProductAndReturn = function (selection) {
        OrderService.setSelectedProduct(selection);
        $rootScope.$broadcast('product-updated');
        $location.path('tab/project/order/new/' + $stateParams.projectId);
      };

      ProductService.all(false, null).then(function(products) {
        $rootScope.products = products;
        //console.log('ProductIndexCtrl, got products');
        $ionicLoading.hide();
        syncButtonsClass("Remove", "ng-hide");
      }, function(reason) {
        //console.log('promise returned reason -> ' + reason);
      });

  }

})();
/**
 * ProjectDetail Controller
 *
 * @description controller for the detailed screen for the project
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('ProjectDetailCtrl', ProjectDetailCtrl);

  ProjectDetailCtrl.$inject = ['$scope', '$rootScope', '$stateParams', '$location', '$ionicLoading', 'ProjectService', '$window', '$sce'];

  function ProjectDetailCtrl($scope, $rootScope, $stateParams, $location, $ionicLoading,  ProjectService, $window, $sce) {

	  // Listen for event broadcast when new Time/Expense created
	  var unregisterEvent =  $rootScope.$on('handleRefreshProjectTotals', function(event) {
	    getProjectTotals();
	  });

	  // Unregister the event listener when the current scope is destroyed
	  $scope.$on('$destroy', function() {
	    unregisterEvent();
	  });

	  $scope.project = ProjectService.get($stateParams.projectId);
	  $scope.project.formDescription = $scope.project.mobilecaddy1__Description__c;
	  $scope.project.URL = $scope.project.mobilecaddy1__MC_URL_1__c;
	  $scope.project.phone = $scope.project.mobilecaddy1__MC_Phone_1__c;


	  console.log('Scope.Project is: ' + JSON.stringify($scope.project));

	  getProjectTotals();

	  $scope.trustSrc = function(src) {
	  	if (src.substring(0,3).toLowerCase() === 'www') {
	  		src = 'http://' + src;
	  	}
	    return $sce.trustAsResourceUrl(src);
	  };


	  function getProjectTotals() {
	    // Calculate the total Time and Expense values displayed on the project details
	    ProjectService.getProjectTotals($stateParams.projectId).then(function(retObject) {
	      $scope.totalExpense = retObject.totalExpense;
	      $scope.hours = Math.floor(retObject.totalTime / 60);
	      $scope.minutes = retObject.totalTime % 60;
	      $scope.$apply();
	    }).catch(function(returnErr) {
	      console.error('update,  returnErr ->' + angular.toJson(returnErr));
	    });
	  }

	  var localProjCB = function(localProjects) {
	    if (localProjects.length > 0) {
	      $rootScope.projects = localProjects;
	      $ionicLoading.hide();
	      $location.path('/projects');
	    }
	  };

	  $scope.visitWebsite = function (url) {
	  	console.log('Hello!!!!!!!');
	  	$window.open(url, '_system');
	  };

	  /*
	   * Handle submitForm : here we need to take any 'form fields', map them to
	   * the MC object and call the update.
	   */
	  $scope.submitForm = function() {
	    //console.log('submitForm');
	    $ionicLoading.show({
	      template: '<h1>Saving...</h1><p>Saving hospital...</p><i class="icon ion-loading-b" style="font-size: 32px"></i>',
	      animation: 'fade-in',
	      showBackdrop: true,
	      maxWidth: 600,
	      duration: 30000
	    });
	    var newProj = {};
	    newProj.Id = $scope.project.Id;
	    newProj.mobilecaddy1__Description__c  = $scope.project.formDescription;
	    //console.log('update, project -> ' + angular.toJson(newProj));
	    ProjectService.update(newProj).then(function(retObject) {
	      //console.log('update, retObject -> ' + angular.toJson(retObject));
	      // Call with local callback function so project list is displayed quickly while background sync continues
	      return ProjectService.all(true, localProjCB);
	    }).then(function(projects) {
	        $rootScope.projects = projects;
	        $ionicLoading.hide();
	        $location.path('/projects');
	    }).catch(function(returnErr) {
	      console.error('update,  returnErr ->' + angular.toJson(returnErr));
	      $ionicLoading.hide();
	    });
	  };

  }

})();
/**
 * ProjectExpense Controller
 *
 * @description controller for the expenses listing
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('ProjectExpenseCtrl', ProjectExpenseCtrl);

  ProjectExpenseCtrl.$inject = ['$scope', '$stateParams', 'ProjectService', 'ProductService'];

  function ProjectExpenseCtrl($scope, $stateParams, ProjectService, ProductService) {

  		console.log("State Param: " + $stateParams.type);
	  switch ($stateParams.type) {
	      case 'surgeon' : $scope.paramType = "Surgeons";
	      	break;
	      case 'order' : $scope.paramType = "Orders";
	        break;
	      default :  $scope.paramType = 'Other';
	    }

	  ProjectService.expenses($stateParams.type, $stateParams.projectId).then(function(timesheets) {
	  	if ($stateParams.type === 'order') {
	  		ProjectService.expenses('surgeon', $stateParams.projectId).then(function(surgeons) {
	  			$scope.surgeons = surgeons;
	  			for (var i = 0; i < timesheets.length; i++) {
	  				if (timesheets[i].mobilecaddy1__Short_Description__c) {
	  					var ids = JSON.parse(timesheets[i].mobilecaddy1__Short_Description__c);

				        var surgeon =  _.where(surgeons, {'Name': ids.sId});
	      				surgeon = surgeon[0];

				        timesheets[i].product = ProductService.get(ids.pId);
				        timesheets[i].surgeon = surgeon;
		  			}

		  			if (timesheets[i].LastModifiedDate) {
	  					timesheets[i].LastModifiedDate = new Date(Date.parse(timesheets[i].LastModifiedDate)).toString();
					}
		  		}
		  		$scope.expenses = timesheets;
		      }, function(reason) {
		        console.error('promise returned error, reason -> ' + reason);
		      });
	  	} else {
	    	$scope.expenses = timesheets;
	    }
	  }, function(reason) {
	    console.error('promise returned error, reason -> ' + reason);
	  });

  }

})();
/**
 * ProjectIndex Controller
 *
 * @description Controller for the projects listing
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('ProjectIndexCtrl', ProjectIndexCtrl);

  ProjectIndexCtrl.$inject = ['$scope', '$rootScope', '$ionicLoading', '$interval', '$timeout', 'ProjectService', 'SyncService', 'devUtils'];

  function ProjectIndexCtrl($scope, $rootScope, $ionicLoading, $interval, $timeout, ProjectService, SyncService, devUtils) {

	  // This unhides the nav-bar. The navbar is hidden in the cases where we want a
	  // splash screen, such as in this app
	  var e = document.getElementById('my-nav-bar');
	  angular.element(e).removeClass( "mc-hide" );

	  // Set height of list scrollable area
	  var winHeight = window.innerHeight - 125;
	  var projectsList = document.getElementById('project-list');
	  projectsList.setAttribute("style","height:" + winHeight + "px");

	  // Get reference to refresh/sync button (so we can change text, disable etc)
	  var storesSyncButton = document.getElementById('projects-sync-button');

	  // Adjust width of list refresh/sync button (cater for multiple buttons on different pages)
	  var syncButtons = document.getElementsByClassName('sync-button');
	  // If you need adjust the width of the refresh/sync button on the list then uncomment and amend following code.
	  // Currently, the css on the button will set the width to 100%.
	  /*  for (var i = syncButtons.length - 1; i >= 0; --i) {
	    syncButtons[i].setAttribute("style","width:" + projectsList.offsetWidth + "px");
	  }*/

	  // Setup the loader and starting templates
	  if (typeof($rootScope.child) == "undefined") {
	    $ionicLoading.show({
	      duration: 30000,
	      delay : 400,
	      maxWidth: 600,
	      noBackdrop: true,
	      template: '<h1>Loading...</h1><p id="app-progress-msg" class="item-icon-left">Fetching Hospitals...<ion-spinner/></p>'
	    });
	  }

	  var localProjCB = function(localProjects) {
	    $rootScope.projects = localProjects;
	    if (localProjects.length > 0) $ionicLoading.hide();
	  };

	  ProjectService.all($rootScope.refreshFlag, localProjCB).then(function(projects) {
	    $rootScope.projects = projects;
	    //console.log('ProjectIndexCtrl, got projects');
	    $ionicLoading.hide();
	    syncButtonsClass("Remove", "ng-hide");
	  }, function(reason) {
	    //console.log('promise returned reason -> ' + reason);
	  });
	  $rootScope.refreshFlag = false;

	  $scope.doRefreshFromPulldown = function() {
	  	//console.log('doRefreshFromPulldown');
	  	ProjectService.all(true).then(function(projects) {
	      $rootScope.projects = projects;
	    }, function(reason) {
	      //console.log('promise returned reason -> ' + reason);
	    });
	  };

	  $scope.doRefreshAndSync = function() {
	    //console.log('doRefreshAndSync');
	    ProjectService.all(false).then(function(projects) {
	      $rootScope.projects = projects;
	      if (SyncService.getSyncState() != "Syncing") {
	        SyncService.syncTables(['MC_Project__ap', 'MC_Time_Expense__ap'], true);
	      }
	    }, function(reason) {
	      //console.log('promise returned reason -> ' + reason);
	    });
	  };

	  $scope.search = {};

	  $scope.clearSearch = function() {
	    $scope.search.query = "";
	  };

	  $rootScope.$on('handleSyncTables', function(event, args) {
	    //console.log("handleSyncTables called args", args);
	    switch (args.result.toString()) {
	      case "Sync" :
	        updateSyncButtonsText("Syncing...");
	        syncButtonsClass("Add", "disabled");
	        break;
	      case "Complete" :
	        updateSyncButtonsText("Refresh and Sync");
	        syncButtonsClass("Remove", "disabled");
	        break;
	      case "100497" :
	        updateSyncButtonsText("No device records to sync...");
	        syncButtonsClass("Remove", "disabled");
	        $timeout( function() {
	          updateSyncButtonsText("Refresh and Sync");
	        },5000);
	        break;
	      case "100498" :
	        updateSyncButtonsText("Sync already in progress...");
	        syncButtonsClass("Remove", "disabled");
	        $timeout( function() {
	          updateSyncButtonsText("Refresh and Sync");
	        },5000);
	        break;
	      case "100402" :
	        updateSyncButtonsText("Please connect before syncing");
	        syncButtonsClass("Remove", "disabled");
	        break;
	      default :
	        if (args.result.toString().indexOf("Error") >= 0) {
	          updateSyncButtonsText(args.result.toString());
	          $timeout( function() {
	            updateSyncButtonsText("Refresh and Sync");
	          },5000);
	        } else {
	          updateSyncButtonsText("Refresh and Sync");
	        }
	        syncButtonsClass("Remove", "disabled");
	    }
	  });

	  function updateSyncButtonsText(newText) {
	    for (var i = syncButtons.length - 1; i >= 0; --i) {
	      angular.element(syncButtons[i]).html(newText);
	    }
	  }

	  function syncButtonsClass(action, className) {
	    for (var i = syncButtons.length - 1; i >= 0; --i) {
	      if (action == "Remove") {
	        angular.element(syncButtons[i]).removeClass(className);
	        if (className == "disabled") {
	          SyncService.setSyncState("Complete");
	        }
	      } else {
	        angular.element(syncButtons[i]).addClass(className);
	        if (className == "disabled") {
	          SyncService.setSyncState("Syncing");
	        }
	      }
	    }
	  }

	  $interval(function() {
	    $scope.checkIfSyncRequired();
	  }, (1000 * 60 * 3));

	  $scope.checkIfSyncRequired = function() {
	    //console.log("checkIfSyncRequired");
	    // Any dirty tables to sync?
	    devUtils.dirtyTables().then(function(tables){
	      if (tables && tables.length !== 0) {
	        // Is the 'Refresh and Sync' enabled?
	        if (!angular.element(storesSyncButton).hasClass("disabled")) {
	          updateSyncButtonsText("Sync Required");
	          syncButtonsClass("Remove", "disabled");
	        }
	      }
	    });
	  };

  }

})();
/**
 * Settings Controller
 *
 * @description Controller for the settings area
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('SettingsCtrl', SettingsCtrl);

  SettingsCtrl.$inject = ['$scope', '$rootScope', '$ionicPopup', '$ionicLoading', '$location', 'devUtils', 'vsnUtils', 'DevService', 'logger'];

  function SettingsCtrl($scope, $rootScope, $ionicPopup, $ionicLoading, $location, devUtils, vsnUtils, DevService, logger) {


	  /*
	  ---------------------------------------------------------------------------
	    Main settings page
	  ---------------------------------------------------------------------------
	  */

	  // This unhides the nav-bar. The navbar is hidden in the cases where we want a
	  // splash screen, such as in this app
	  // NOTE - you will want to add the following two lines to the controller that
	  // is first called by your app.
	  var e = document.getElementById('my-nav-bar');
	  angular.element(e).removeClass( "mc-hide" );

	  $scope.logoutAllowedClass = 'disabled';
	  $scope.recsToSyncCount = 0;

	  $scope.codeflow = LOCAL_DEV;

	  $scope.upgradeAvailable = false;
	  vsnUtils.upgradeAvailable().then(function(res){
	    if (res)  return devUtils.dirtyTables();
	  }).then(function(tables){
	    if (tables && tables.length === 0) {
	      $scope.upgradeAvailable = true;
	      $scope.$apply();
	    }
	  });

	  DevService.allRecords('recsToSync', false)
	    .then(function(recsToSyncRecs) {
	    $scope.recsToSyncCount = recsToSyncRecs.length;
	    if ($scope.recsToSyncCount === 0) {
	      $scope.logoutAllowedClass = '';
	    } else {
	      $scope.recsToSyncCount  = 0;
	    }
	  }, function(reason) {
	    console.error('Angular: promise returned reason -> ' + reason);
	  });


	  DevService.allRecords('appSoup', false)
	    .then(function(appSoupRecs) {
	    $scope.settingsRecs = extractSettingsValues(appSoupRecs);
	  }, function(reason) {
	    console.error('Angular: promise returned reason -> ' + reason);
	  });

	  function extractSettingsValues(appSoupRecs) {
	    var settingRecs = {};
	    $j.each(appSoupRecs, function(i,records) {
	      var tableRec = {};
	      $j.each(records, function(i,record) {
	        switch (record.Name) {
	          case "Name" :
	            tableRec.Name = record.Value;
	            break;
	          case "CurrentValue" :
	            tableRec.Value = record.Value;
	            break;
	        }
	      }); // end loop through the object fields
	      settingRecs[tableRec.Name] = tableRec.Value;
	    });
	    return settingRecs;
	  }


	  /*
	  ---------------------------------------------------------------------------
	    Utility Functions
	  ---------------------------------------------------------------------------
	  */
	  function validateAdminPassword(pword) {
	    return (pword == "123") ?  true : false;
	  }

	  $scope.upgradeIfAvailable = function() {
	    devUtils.dirtyTables().then(function(tables){
	      logger.log('upgrade: dirtyTables check');
	      if (tables && tables.length === 0) {
	        logger.log('upgrade: no dirtyTables');
	        var confirmPopup = $ionicPopup.confirm({
	          title: 'Upgrade',
	          template: 'Are you sure you want to upgrade now?'
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
	            logger.log('upgrade: calling upgradeIfAvailable');
	            vsnUtils.upgradeIfAvailable().then(function(res){
	              logger.log('upgrade: upgradeIfAvailable? ' + res);
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
	              logger.error('upgrade: ' + JSON.stringify(e));
	              $ionicLoading.hide();
	            });
	          }
	        });
	      } else {
	        logger.log('upgrade: dirtyTables found');
	        $scope.data = {};
	        $ionicPopup.show({
	          title: 'Upgrade',
	          subTitle: 'Unable to upgrade. A sync is required - please try later.',
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
	    });
	  };

	  /*
	  ---------------------------------------------------------------------------
	    Log in/out
	  ---------------------------------------------------------------------------
	  */
	  $scope.showAdminPasswordPopup = function() {
	    var adminTimeout = (1000 * 60 * 5); // 5 minutes
	    if ( $rootScope.adminLoggedIn > Date.now() - adminTimeout) {
	      $location.path('tab/settings/devtools');
	      $rootScope.adminLoggedIn = Date.now();
	      $scope.$apply();
	    } else {
	      $scope.data = {};
	      var myPopup = $ionicPopup.show({
	        template: '<input type="password" ng-model="data.admin">',
	        title: 'Enter Admin Password',
	        scope: $scope,
	        buttons: [
	          { text: 'Cancel' },
	          { text: '<b>Continue</b>',
	            type: 'button-positive',
	            onTap: function(e) {
	            if (validateAdminPassword($scope.data.admin)) {
	                $location.path('tab/settings/devtools');
	                $rootScope.adminLoggedIn = Date.now();
	              } else {
	                console.log("Password incorrect");
	              }
	            }
	          },
	        ]
	      });
	    }
	  };

	  $scope.showConfirmLogout = function() {
	   var confirmPopup = $ionicPopup.confirm({
	     title: 'Logout',
	     template: 'Are you sure you want to logout?'
	   });
	   confirmPopup.then(function(res) {
	     if(res) {
	       $rootScope.adminLoggedIn = null;
	       cordova.require("com.salesforce.plugin.sfaccountmanager").logout();
	     }
	   });
	  };

	  $scope.showConfirmReset = function() {
	    var confirmPopup = $ionicPopup.confirm({
	      title: 'Reset App Data',
	      template: 'Are you sure you want to reset ALL application data?'
	    });
	    confirmPopup.then(function(res) {
	      if(res) {
	        console.debug("Resetting app");
	        var i;
	        var name;
	        $ionicLoading.show({
	          duration: 30000,
	          delay : 400,
	          maxWidth: 600,
	          noBackdrop: true,
	          template: '<h1>Resetting app...</h1><p id="app-progress-msg" class="item-icon-left">Clearing data...<ion-spinner/></p>'
	        });
	        vsnUtils.hardReset().then(function(res){
	          //$ionicLoading.hide();
	        }).catch(function(e){
	          console.error(e);
	          $ionicLoading.hide();
	        });
	      }
	    });
	  };

	  $scope.setLogLevel = function() {
	    if ($scope.log.level == "Off") {
	      localStorage.removeItem('logLevel');
	    } else {
	      localStorage.setItem('logLevel', $scope.log.level);
	    }
	    $scope.log.levelChange = false;
	  };

	  $scope.getLogLevel = function() {
	    var logLevel = localStorage.getItem("logLevel");
	    if (logLevel === null) {
	      logLevel = "Off";
	    }
	    return logLevel;
	  };

	  $scope.log = {};
	  $scope.log.level = $scope.getLogLevel();
	  $scope.log.levelChange = false;

	  $scope.logLevelChange = function() {
	    $scope.log.levelChange = true;
	  };

  }

})();
/**
 * SelectSurgeon Controller
 *
 * @description controller for new expenses
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('SelectSurgeonCtrl', SelectSurgeonCtrl);

  SelectSurgeonCtrl.$inject = ['$scope', '$rootScope', '$stateParams', '$ionicLoading', '$ionicPopup', '$ionicModal', '$location', '$cordovaBarcodeScanner', 'ProjectService', 'Camera', 'OrderService'];

  function SelectSurgeonCtrl($scope, $rootScope, $stateParams, $ionicLoading, $ionicPopup, $ionicModal, $location, $cordovaBarcodeScanner, ProjectService, Camera, OrderService) {

      var winHeight = window.innerHeight - 125;
      var surgeonsList = document.getElementById('surgeon-list');
      surgeonsList.setAttribute("style","height:" + winHeight + "px");

      $scope.surgeons = [
        {
          name: 'Bob',
          title: 'FFFF'
        },
        {
          name: 'Ted',
          title: 'FFFF'
        },
        {
          name: 'Cat',
          title: 'FFFF'
        },
        {
          name: 'Hat',
          title: 'FFFF'
        },
        {
          name: 'Dig',
          title: 'FFFF'
        }
      ];

      $scope.setSelectedSurgeonAndReturn = function (selection) {
        console.log("Selection: " + JSON.stringify(selection));
        OrderService.setSelectedSurgeon(selection);
        console.log("OrderService: " + JSON.stringify(OrderService.setSelectedSurgeon));
        $rootScope.$broadcast('surgeon-updated');
        $location.path('tab/project/order/new/' + $stateParams.projectId);
      };

      ProjectService.expenses('surgeon', $stateParams.projectId).then(function(timesheets) {
        $scope.expenses = timesheets;
      }, function(reason) {
        console.error('promise returned error, reason -> ' + reason);
      });

  }

})();
/**
 * Testing Controller
 *
 * @description controller for testing functions in the settings pages
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('TestingCtrl', TestingCtrl);

  TestingCtrl.$inject = ['$scope', 'AppRunStatusService', 'NotificationService'];

  function TestingCtrl($scope, AppRunStatusService,NotificationService) {

	  $scope.resumeEvent = function() {
	    console.debug("resumeEvent");
	    AppRunStatusService.statusEvent('resume');
	  };

    $scope.localNotificationTrigger = function(id) {
      console.debug('localNotificationTrigger', id);
      NotificationService.handleLocalNotification(id);
    };

  }

})();