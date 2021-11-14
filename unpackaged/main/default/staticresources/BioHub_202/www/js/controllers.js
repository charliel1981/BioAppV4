/**
 * starter.controllers module
 *
 * @description defines starter.controllers module
 */
(function() {
  'use strict';

  angular.module('starter.controllers', ['ionic', 'ngCordova'])

  /**
   * Takes a date object and returns in a readable string form: 'year - month - day'
   * @param  {Date}
   * @return {string}
   */
  .filter('dateYYYYMMDD', ['$filter', function($filter) {
    return function(x) {
      if (typeof(x) != "undefined" && typeof(x) !== null ) {
        if (x === null) {
          return "";
        } else {
          var myDate = new Date(x);
          return $filter("date")(myDate, "yyyy - MM - dd");
        }
      } else {
        return "";
      }
    };
  }])

  /**
   * Takes a date object and returns in a readable string form: 'day shortmonth year'
   * @param  {Date}
   * @return {string}
   */
  .filter('dateDDMMMYYYY', ['$filter', function($filter) {
    return function(x) {
      if (typeof(x) != "undefined" && typeof(x) !== null ) {
        if (x === null) {
          return "";
        } else {
          var myDate = new Date(x);
          return $filter("date")(myDate, "dd MMM yyyy");
        }
      } else {
        return "";
      }
    };
  }])

  /**
   * Takes a date object and returns in a readable string form: 'day shortmonth year  hour:minute'
   * @param  {Date}
   * @return {string}
   */
  .filter('dateDDMMMYYYYHHMM', ['$filter', function($filter) {
    return function(x) {
      if (typeof(x) != "undefined" && typeof(x) !== null ) {
        if (x === null) {
          return "";
        } else {
          var myDate = new Date(x);
          return $filter("date")(myDate, "dd MMM yyyy HH:mm");
        }
      } else {
        return "";
      }
    };
  }])

  /**
   * Replaces characters in a string and returns trusted html string.
   *    Replaces:
   *      1. line breaks with <br/>
   *      2. <ul> with <ul class="bio-custom-bullet bio-green-tick">
   * @param  {string}
   * @return {string}
   */
  .filter('trusted', ['$sce', function($sce) {
    return function(val) {
      if (val) {
        return $sce.trustAsHtml(val.replace(/\n/g, '<br/>').replace('<ul>', '<ul class="bio-custom-bullet bio-green-tick">'));
      }
    };
  }]);

})();
/**
 * Content item Controller
 *
 * @description controller for content items
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('ContentItemCtrl', ContentItemCtrl);

  ContentItemCtrl.$inject = ['$rootScope', '$scope', '$stateParams', '$ionicLoading', '$window', '$timeout', '$ionicModal', '$location', '$ionicScrollDelegate', '$ionicPopup','$ionicHistory', '$state', 'logger', 'ContentItemService', 'NetworkService'];

  function ContentItemCtrl($rootScope, $scope, $stateParams, $ionicLoading, $window, $timeout, $ionicModal, $location, $ionicScrollDelegate, $ionicPopup, $ionicHistory, $state, logger, ContentItemService, NetworkService) {
    logger.log("in ContentItemCtrl");
    console.log("bio in ContentItemCtrl<<<<<<<<<<<");

    var vm = this;
    var resetSliderTimeout;
    var resetModalSliderTimeout;
    var adjustImageTextTimeout;
    var openWindowTimeout;
    var hideSwiperPaginationTimeout;
    var showSwiperPaginationTimeout;
    var slideNextStartTimeout;
    var slidePrevStartTimeout;
    var updateTimeout;
    var showingModal;

    // Menu option
    vm.menuItem = $stateParams.menuItem;

    // Define CSS classes used in positioning of image caption text (make class unique to content item)
    vm.imageCSSClass = "slide-image-" + $stateParams.menuItem;
    vm.imageCaptionCSSClass = "slide-caption-text-" + $stateParams.menuItem;
    vm.imageCSSClassModal = "modal-slide-image-" + $stateParams.menuItem;
    vm.imageCaptionCSSClassModal = "modal-slide-caption-text-" + $stateParams.menuItem;

    // Define HTML element ids used in hiding the swiper pagination if only one slide
    vm.slidesId = "slides-" + $stateParams.menuItem;
    vm.modalSlidesId = "modal-slides-" + $stateParams.menuItem;

    // Twin Images template slider options - dynamically changes number of slides in view based on device width
    vm.twinImagesSliderOptions = {
        // Default parameters
        slidesPerView: 2,
        // Responsive breakpoints
        breakpoints: {
          // when window width is <= 768px
          768: {
            slidesPerView: 1
          }
        }
      };

    // Methods called from html
    vm.showImageModal = showImageModal;
    vm.closeImageModal = closeImageModal;
    vm.gotoPage = gotoPage;
    vm.openWindow = openWindow;
    vm.goBack = goBack;
    vm.goHome = goHome;

    // Code run on first activation of controller
    activate(false);

    // Event fired when we enter view - regardless of whether it's cached
    var deregisterIonicViewEnter = $scope.$on('$ionicView.enter', function(scopes, states) {
      // console.log("bio ContentItemCtrl $ionicView.enter",vm.menuItem);
      // Template is cached. We'll use this event to always run code when view is displayed.
      refreshSliderAndImageText();
      // Register window resize event
      angular.element($window).on('resize', windowResizeHandler);
    });

    var deregisterIonicViewAfterEnter = $scope.$on('$ionicView.afterEnter', function(scopes, states) {
      updateTimeout = $timeout(function() {
        // Set the view title
        vm.title = decodeURIComponent($stateParams.menuName);
      },0);
    });

    // Event fired when we leave view - regardless of whether it's cached
    var deregisterIonicViewLeave = $scope.$on('$ionicView.leave', function(scopes, states) {
      // console.log("bio ContentItemCtrl $ionicView.leave",vm.menuItem,vm.slider);
      // Deregister window resize event
      angular.element($window).off('resize', windowResizeHandler);
      // Move slider to first slide (in case we come back into cached view)
      if (vm.slider) {
        vm.slider.slideTo(0,0);
      }
      // For menu lists, scroll to top of page (in case we come back into cached view)
      if (vm.contentItemTemplate == "Menu_List.html") {
        $ionicScrollDelegate.scrollTop();
      }
    });

    // Method used to (re)populate slides/menu. This method might be called after a sync...so the parameter indicates this situation
    function activate(refreshAfterSync) {
      // Setting title here (as well as $ionicView.enter) stops the title on iphone coming in after page loaded (and gives it as much width as possible)
      vm.title = decodeURIComponent($stateParams.menuName);
      // Loading message if first time through
      if (!refreshAfterSync) {
        // Loading...
        $ionicLoading.show({
          duration: 10000,
          template: 'Loading...',
          animation: 'fade-in',
          showBackdrop: true
        });
      }
      // Get the content items records and populate the template associated with the record type
      ContentItemService.getContentItems($stateParams.menuItem).then(function(records) {
        // console.log("bio ContentItemCtrl records",records);
        if (records.length > 0) {
          // Got records, hide loading.
          $ionicLoading.hide();

          // We can only have one style of template per slider/menu - just examine the first record type to determine this style
          vm.contentItemTemplate = getTemplateName(records[0].Record_Type_Name__c);
          if (vm.contentItemTemplate == "Portrait_Image.html" || vm.contentItemTemplate == "Portrait_Image_Fixed_Heading.html") {
            populatePortraitImageSlider(records,refreshAfterSync);
          } else if (vm.contentItemTemplate == "Menu_List.html") {
            populateMenuList(records,refreshAfterSync);
          } else if (vm.contentItemTemplate == "Twin_Images.html") {
            populateTwinImagesSlider(records,refreshAfterSync);
          } else if (vm.contentItemTemplate == "Landscape_Image.html") {
            populateLandscapeImageSlider(records,refreshAfterSync);
          } else if (vm.contentItemTemplate == "Image_and_Copy.html") {
            populateImageAndCopySlider(records,refreshAfterSync);
          } else if (vm.contentItemTemplate == "Image_or_Copy.html") {
            populateImageOrCopySlider(records,refreshAfterSync);
          }
        }
      });
    }

    function getTemplateName(recordTypeName) {
      if (recordTypeName == "Portrait_Image") {
        // The 'apps' slides have different headings for each slide (so we'll use a different template)
        if (vm.menuItem == "apps") {
          return "Portrait_Image.html";
        } else {
          return "Portrait_Image_Fixed_Heading.html";
        }
      } else if (recordTypeName == "Menu_List") {
        return "Menu_List.html";
      } else if (recordTypeName == "Twin_Images") {
        return "Twin_Images.html";
      } else if (recordTypeName == "Landscape_Image") {
        return "Landscape_Image.html";
      } else if (recordTypeName == "Image_and_Copy") {
        return "Image_and_Copy.html";
      } else if (recordTypeName == "Copy") {
        return "Image_or_Copy.html";
      }
    }

    function populatePortraitImageSlider(records,refreshAfterSync) {
      // console.log("bio populatePortraitImageSlider",vm.slider,refreshAfterSync);
      if (vm.slider && !refreshAfterSync) {
        // We're coming back into page...
        refreshSliderAndImageText();
      } else {
        // Build slides
        vm.slides = [];
        vm.slideHeadings = [];
        vm.slideFooters = [];
        for (var i = 0; i < records.length; i++) {
          vm.slideHeadings.push(records[i].Text2__c);
          vm.slideFooters.push(records[i].Text3__c);
          if (records[i].Display_Type__c == "Copy") {
            vm.slides.push({"text": records[i].Image1__c});
          } else {
            vm.slides.push({"image": records[i].Image1__c, "caption": records[i].Text1__c});
          }
        }
        // Check how many slides we have and hide pagination appropriately
        if (vm.slides.length <= 1) {
          hideSwiperPagination(vm.slidesId);
        } else {
          showSwiperPagination(vm.slidesId);
        }
        // Check whether we're refreshing after sync service event fired
        if (refreshAfterSync) {
          // console.log("bio populatePortraitImageSlider refreshAfterSync");
          refreshSliderAndImageText();
        }
      }
    }

    function populateMenuList(records,refreshAfterSync) {
      if (vm.menuItems && !refreshAfterSync) {
        // We're coming back into page...
      } else {
        vm.menuItems = records;
      }
    }

    function populateTwinImagesSlider(records,refreshAfterSync) {
      // Note. the swiper pagination bar is hidden depending on device size using css class '.bio-image-slider-twin > .swiper-container > .swiper-pagination'
      if (vm.slider && !refreshAfterSync) {
        // We're coming back into page...
        refreshSliderAndImageText();
      } else {
        // Build slides
        vm.slides = [];
        vm.slideHeadings = [];
        vm.slideFooters = [];
        var slideFooter = null;
        for (var i = 0; i < records.length; i++) {
          if (records[i].Display_Type__c == "Left Side Image") {
            slideFooter = records[i].Text3__c;
          }
          if (records[i].Display_Type__c == "Right Side Image") {
            slideFooter = records[i].Text3__c;
          }
          if (records[i].Image1__c) {
            vm.slides.push({"image": records[i].Image1__c, "caption": records[i].Text1__c, "heading": ""});
            vm.slideHeadings.push(records[i].Text2__c);
            vm.slideFooters.push(slideFooter);
          }
        }
        // Check whether we're refreshing after sync service event fired
        if (refreshAfterSync) {
          // console.log("bio populateTwinImagesSlider refreshAfterSync");
          refreshSliderAndImageText();
        }
      }
    }

    function populateLandscapeImageSlider(records,refreshAfterSync) {
      // console.log("bio populateLandscapeImageSlider",vm.slider,refreshAfterSync);
      if (vm.slider && !refreshAfterSync) {
        // We're coming back into page...
        refreshSliderAndImageText();
      } else {
        // Build slides
        vm.slides = [];
        vm.slideHeadings = [];
        vm.slideFooters = [];
        for (var i = 0; i < records.length; i++) {
          if (records[i].Image1__c) {
            vm.slides.push({"image": records[i].Image1__c, "caption": records[i].Text1__c});
            vm.slideHeadings.push(records[i].Text2__c);
            vm.slideFooters.push(records[i].Text3__c);
          }
        }
        // Check how many slides we have and hide pagination appropriately
        if (vm.slides.length <= 1) {
          hideSwiperPagination(vm.slidesId);
        }
        // Check whether we're refreshing after sync service event fired
        if (refreshAfterSync) {
          // console.log("bio populateLandscapeImageSlider refreshAfterSync");
          refreshSliderAndImageText();
        }
      }
    }

    function populateImageAndCopySlider(records,refreshAfterSync) {
      // Both copy and image on the same slider. Or, two images on same slide
      if (vm.slider && !refreshAfterSync) {
        // We're coming back into page...
        refreshSliderAndImageText();
      } else {
        // Build slides
        vm.slides = [];
        vm.slideHeadings = [];
        vm.slideFooters = [];
        vm.modalSlides = []; // We'll use a different image modal for this style of template (because we might have two images on same slide)
        var copyText = null;
        var image = null;
        var image2 = null;
        var slideHeading = null;
        var slideFooter = null;
        for (var i = 0; i < records.length; i++) {
          // One of the 'Left Side's will hold header/footer (never on 'Right Side')
          if (records[i].Display_Type__c == "Left Side Copy") {
            slideHeading = records[i].Text2__c;
            slideFooter = records[i].Text3__c;
            if (records[i].Image1__c) {
              copyText = records[i].Image1__c;
            }
          }
          if (records[i].Display_Type__c == "Left Side Image") {
            slideHeading = records[i].Text2__c;
            slideFooter = records[i].Text3__c;
            if (records[i].Image1__c) {
              image = records[i].Image1__c;
              // Save image in case user taps on image and we want to show modal
              vm.modalSlides.push({"image": records[i].Image1__c});
            }
          }
          if (records[i].Display_Type__c == "Right Side Image") {
            if (records[i].Image1__c) {
              if (image) {
                image2 = records[i].Image1__c;
              } else {
                image  = records[i].Image1__c;
              }
              // Save image in case user taps on image and we want to show modal
              vm.modalSlides.push({"image": records[i].Image1__c});
              // Build the slide data
              vm.slides.push({"image": image, "image2": image2, "text": copyText});
              vm.slideHeadings.push(slideHeading);
              vm.slideFooters.push(slideFooter);
              copyText = null;
              image = null;
              image2 = null;
              slideHeading = null;
              slideFooter = null;
            }
          }
        }
        // Check how many slides we have and hide pagination appropriately
        if (vm.slides.length <= 1) {
          hideSwiperPagination(vm.slidesId);
        }
        // Check whether we're refreshing after sync service event fired
        if (refreshAfterSync) {
          // console.log("bio populateImageAndCopySlider refreshAfterSync");
          refreshSliderAndImageText();
        }
      }
    }

    function populateImageOrCopySlider(records,refreshAfterSync) {
      if (vm.slider && !refreshAfterSync) {
        // We're coming back into page...
        refreshSliderAndImageText();
      } else {
        // Build slides
        vm.slides = [];
        for (var i = 0; i < records.length; i++) {
          var image = null;
          var copy = null;
          var footerText = null;
          var headerText = null;
          var externalURL = null;
          if (records[i].Display_Type__c == "Copy") {
            headerText = records[i].Text1__c;
            copy = records[i].Image1__c;
            footerText = records[i].Text2__c;
            externalURL = records[i].Text3__c;
          }
          if (records[i].Display_Type__c == "Image") {
            if (records[i].Image1__c) {
              image = records[i].Image1__c;
            }
            headerText = records[i].Text1__c;
            footerText = records[i].Text2__c;
            externalURL = records[i].Text3__c;
          }
          vm.slides.push({"image": image, "text": copy, "headerText": headerText, "footerText": footerText, "externalURL": externalURL});
        }
        // Check how many slides we have and hide pagination appropriately
        if (vm.slides.length <= 1) {
          hideSwiperPagination(vm.slidesId);
        }
        // Check whether we're refreshing after sync service event fired
        if (refreshAfterSync) {
          // console.log("bio populateImageOrCopySlider refreshAfterSync");
          refreshSliderAndImageText();
        }
      }
    }

    function refreshSliderAndImageText() {
      // console.log("bio refreshSliderAndImageText showingModal",showingModal);
      resetSliderTimeout = $timeout(function() {
        if (vm.slider) {
          vm.slider.update();
        }
        adjustImageCaptionPosition(vm.imageCSSClass,vm.imageCaptionCSSClass,vm.slidesId);
        if (showingModal) {
          vm.modalSlider.update();
          adjustImageCaptionPosition(vm.imageCSSClassModal,vm.imageCaptionCSSClassModal,vm.modalSlidesId);
        }
      },0);
    }

    $scope.$watch('vm.slider', function(slider) {
      // console.log("bio $watch slider",slider);
      if (slider) {
        adjustImageCaptionPosition(vm.imageCSSClass,vm.imageCaptionCSSClass,vm.slidesId);
        vm.slider.on('slideNextStart', function () {
          // Force header/footer text to be updated when swiping through
          slideNextStartTimeout = $timeout(function() {
            $scope.$apply();
          }, 0);
        });
        vm.slider.on('slidePrevStart', function () {
          // Force header/footer text to be updated when swiping through
          slidePrevStartTimeout = $timeout(function() {
            $scope.$apply();
          }, 0);
        });
      }
    });

    $scope.$watch('vm.modalSlider', function(slider) {
      // console.log("bio $watch modalSlider",slider,vm.imageCSSClassModal,vm.imageCaptionCSSClassModal);
      if (slider) {
        adjustImageCaptionPosition(vm.imageCSSClassModal,vm.imageCaptionCSSClassModal,vm.modalSlidesId);
      }
    });

    function windowResizeHandler() {
      // console.log("bio windowResizeHandler showingModal",showingModal,vm.menuItem);
      if (showingModal) {
        adjustImageCaptionPosition(vm.imageCSSClassModal,vm.imageCaptionCSSClassModal,vm.modalSlidesId);
      } else {
        adjustImageCaptionPosition(vm.imageCSSClass,vm.imageCaptionCSSClass,vm.slidesId);
        $ionicScrollDelegate.scrollTop();
      }
    }

    function showImageModal(index,templateName) {
      // console.log("bio showImageModal");
      $ionicModal.fromTemplateUrl($window.RESOURCE_ROOT + "templates/" + templateName + ".html", {
        scope: $scope,
        animation: 'slide-in-up'
      }).then(function(modal) {
        showingModal = true;
        vm.imageModal = modal;
        if (vm.slides.length <= 1) {
          hideSwiperPagination(vm.modalSlidesId);
        } else {
          showSwiperPagination(vm.modalSlidesId);
        }
        vm.imageModal.show();
        resetModalSliderTimeout = $timeout(function() {
          // Keep modal slider in sync with main page slider
          vm.modalSlider.slideTo(index,0);
        },0);
      });
    }

    function closeImageModal() {
      // console.log("bio closeImageModal",vm.modalSlider);
      showingModal = false;
      vm.slider.update();
      // Reposition main slider to match modal page slider
      vm.slider.slideTo(vm.modalSlider.activeIndex,0);
      adjustImageCaptionPosition(vm.imageCSSClass,vm.imageCaptionCSSClass,vm.slidesId);
      // Make sure we destroy the modal slider
      if (vm.imageModal) {
        vm.imageModal.hide();
        vm.imageModal.remove();
        delete vm.imageModal;
      }
    }

    function adjustImageCaptionPosition(imageClass,imageCaptionClass,slidesId) {
      // console.log("bio adjustImageCaptionPosition",imageClass, imageCaptionClass);
      adjustImageTextTimeout = $timeout(function() {
        // Get the height of the slides wrapper
        var slidesEl = $window.document.getElementById(slidesId);
        // console.log("bio adjustImageCaptionPosition slidesEl",slidesEl);
        var wrappedSlidesEl = angular.element(slidesEl);
        // console.log("bio adjustImageCaptionPosition wrappedSlidesEl",wrappedSlidesEl);
        var slidesHeight = null;
        if (wrappedSlidesEl && wrappedSlidesEl.length > 0) {
          slidesHeight = wrappedSlidesEl[0].offsetHeight;
        }
        // console.log("bio adjustImageCaptionPosition slidesHeight",slidesHeight);
        // Get images and position caption over them
        var images = $window.document.getElementsByClassName(imageClass);
        // console.log("bio adjustImageCaptionPosition images",images);
        if (images.length > 0 && images[0].offsetWidth > 0) {
          // set width and left for elements with image text class
          var imageCaptions = $window.document.getElementsByClassName(imageCaptionClass);
          // console.log("bio imageCaptions",imageCaptions);
          for (var j = imageCaptions.length - 1; j >= 0; --j) {
            var bottomAttr = "";
            if (slidesHeight) {
              var bottom = wrappedSlidesEl[0].offsetHeight - images[j].offsetHeight - images[j].offsetTop;
              bottomAttr = (bottom < 0) ? "bottom:0;" : "bottom:" + bottom + "px;";
            }
            // Set the caption attributes
            imageCaptions[j].setAttribute("style","width:" + images[j].offsetWidth + "px;left:" + images[j].offsetLeft + "px;display:block;" + bottomAttr);
          }
          imageCaptions = null;
        }
        images = slidesEl = wrappedSlidesEl = null;
      },0);
    }

    function hideSwiperPagination(slidesId) {
      // console.log("bio hideSwiperPagination slidesId",slidesId);
      hideSwiperPaginationTimeout = $timeout(function() {
        var slidesEl = $window.document.getElementById(slidesId);
        // console.log("bio hideSwiperPagination slidesEl",slidesEl);
        if (slidesEl) {
          // console.log("bio hideSwiperPagination slidesEl",slidesId,slidesEl);
          var swiperPagination = slidesEl.querySelector('#'+slidesId + ' > .swiper-container > .swiper-pagination');
          // console.log("bio hideSwiperPagination swiperPagination",swiperPagination);
          var wrappedSwiperPagination = angular.element(swiperPagination);
          wrappedSwiperPagination.css('display','none');
          slidesEl = swiperPagination = wrappedSwiperPagination = null;
        }
      },50);
    }

    function showSwiperPagination(slidesId) {
      // console.log("bio showSwiperPagination slidesId",slidesId);
      showSwiperPaginationTimeout = $timeout(function() {
        var slidesEl = $window.document.getElementById(slidesId);
        // console.log("bio showSwiperPagination slidesEl",slidesEl);
        if (slidesEl) {
          // console.log("bio showSwiperPagination slidesEl",slidesId,slidesEl);
          var swiperPagination = slidesEl.querySelector('#'+slidesId + ' > .swiper-container > .swiper-pagination');
          // console.log("bio showSwiperPagination swiperPagination",swiperPagination);
          var wrappedSwiperPagination = angular.element(swiperPagination);
          wrappedSwiperPagination.removeClass('ng-hide');
          slidesEl = swiperPagination = wrappedSwiperPagination = null;
        }
      },500);
    }

    function gotoPage(menuItem, menuName) {
      $location.path("/app/contentitem/" + menuItem + "/" + encodeURIComponent(menuName));
    }

    function openWindow(url) {
      // Check connectivity, if online then open window, otherwise display message
      if (NetworkService.getNetworkStatus() === "online") {
        openWindowTimeout = $timeout(function() {
          if (cordova.InAppBrowser) {
            cordova.InAppBrowser.open(url, "_system", "location=yes");
          } else {
            $window.open(url, "_system", "location=yes");
          }
        },0);
      } else {
        alertOffline();
      }
    }

    function alertOffline(){
      var alertPopup = $ionicPopup.alert({
        title: 'No connection',
        template: 'You need to be online to view',
        cssClass: 'bio-popup'
      });
      alertPopup.then(function(res) {
        if (res) {
        }
      });
    }

    function goBack() {
      // If there is a 'back view' in the history stack then go back to it,
      // otherwise, open up the side menu (possibly sub menu depending on which menu option we're currently on)
      if ($ionicHistory.backView()) {
        $ionicHistory.goBack();
      } else {
        if (vm.menuItem === "toi" ||
            vm.menuItem === "e-learn" ||
            vm.menuItem === "bio") {
          $rootScope.$emit('showSideMenu');
        } else if (vm.menuItem === "terms") {
          $rootScope.$emit('showSettingsMenu');
        } else {
          $rootScope.$emit('showStimulanMenu');
        }
      }
    }

    function goHome() {
      $state.go("app.home");
    }

    // Handle events fired from the SyncService
    var deregisterHandleSyncTables = $rootScope.$on('syncTables', function(event, args) {
      logger.log("ContentItemCtrl syncTables: " + JSON.stringify(args));
      console.log("bio ContentItemCtrl syncTables: " + JSON.stringify(args));
      if (args.result.toString().indexOf("TableComplete") >= 0) {
        var syncedTable = args.result.replace("TableComplete ","");
        if (syncedTable == "Content_Item__ap") {
          activate(true);
        }
      }
    });

    // Note. $destroy doesn't always fire immediately we leave page (for cached view)
    $scope.$on('$destroy', function() {
      logger.log("ContentItemCtrl $destroy");
      console.log("bio ContentItemCtrl $destroy<<<<<<<<<<<");
      destroyReferences();
    });

    function destroyReferences() {
      logger.log("ContentItemCtrl destroyReferences");
      // console.log("bio ContentItemCtrl destroyReferences",vm.menuItem);
      deregisterIonicViewEnter();
      deregisterIonicViewLeave();
      deregisterHandleSyncTables();
      $timeout.cancel(resetSliderTimeout);
      $timeout.cancel(resetModalSliderTimeout);
      $timeout.cancel(adjustImageTextTimeout);
      $timeout.cancel(openWindowTimeout);
      $timeout.cancel(hideSwiperPaginationTimeout);
      $timeout.cancel(showSwiperPaginationTimeout);
      $timeout.cancel(slideNextStartTimeout);
      $timeout.cancel(slidePrevStartTimeout);
      $timeout.cancel(updateTimeout);
      if (vm.slider) {
        vm.slider.off('slideNextStart');
        vm.slider.off('slidePrevStart');
      }
    }

  }

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
 * Home Controller
 *
 * @description controller for home page. Code runs once (it's a cached ionic view).
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('HomeCtrl', HomeCtrl);

  HomeCtrl.$inject = ['$rootScope', '$scope', '$ionicLoading', '$window', '$timeout', 'logger', 'UserService'];

  function HomeCtrl($rootScope, $scope, $ionicLoading, $window, $timeout, logger, UserService) {
    logger.log("in HomeCtrl");
    console.log("bio in HomeCtrl");

    var vm = this;
    var slideInTimeout;

    vm.titleImage = $window.RESOURCE_ROOT + "images/Biocomposites-header-logo.SVG";
    vm.homeImage = $window.RESOURCE_ROOT + "images/home.jpg";
    vm.orderFormSVG = $window.RESOURCE_ROOT + "images/order-form-home-icon.SVG";
    vm.unsolicitedSVG = $window.RESOURCE_ROOT + "images/unsolicited-request-home-icon.SVG";
    vm.stimulanSVG = $window.RESOURCE_ROOT + "images/stimulan-home-icon.SVG";
    vm.topicSVG = $window.RESOURCE_ROOT + "images/topics-of-interest-home-icon.SVG";
    vm.slideInHomePage = true;

    vm.showStimulanSideMenu = showStimulanSideMenu;

    activate();

    function activate() {
      // Get user's firstname
      UserService.getUserFirstName().then(function(result) {
        vm.userFirstName = "Hello " + result;
      });
      // Check whether we've loaded data before showing home page
      UserService.hasDoneProcess("initialDataLoaded").then(function(result) {
        // console.log("bio HomeCtrl initialDataLoaded result: " + result);
        // logger.log("HomeCtrl initialDataLoaded result: " + result);
        if (!result) {
          // If we haven't done the initial data loaded then display loading message.
          // Event handling in MenuCtrl will set 'initialDataLoaded', load menu and hide loading message
          $ionicLoading.show({
            template: '<p id="app-progress-msg" class="item-icon-left"><h3>Loading Data...</h3><ion-spinner></ion-spinner></p>',
            animation: 'fade-in',
            showBackdrop: true,
            maxWidth: 600,
            duration: 0
          });
        }
      });
    }

    function showStimulanSideMenu() {
      $rootScope.$emit('showStimulanMenu');
    }

    slideInTimeout = $timeout(function() {
      // Turn off our own home page 'slide in' animation - it makes for better user experience on app load
      vm.slideInHomePage = false;
    },1000);

    $scope.$on('$destroy', function() {
      logger.log("HomeCtrl destroy");
      console.log("bio HomeCtrl destroy");
      $timeout.cancel(slideInTimeout);
    });

  }

})();

/**
 * Lead Capture Controller
 *
 * @description controller for lead capture functionality
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('LeadCaptureCtrl', LeadCaptureCtrl);

  LeadCaptureCtrl.$inject = ['$rootScope', '$scope', '$ionicPopup', '$state', '$ionicLoading', '$timeout', '$ionicScrollDelegate', 'logger', 'SyncService', 'NetworkService', 'RecordTypeService', 'MobileDynamicService', 'LocalNotificationService'];

  function LeadCaptureCtrl($rootScope, $scope, $ionicPopup, $state, $ionicLoading, $timeout, $ionicScrollDelegate, logger, SyncService, NetworkService, RecordTypeService, MobileDynamicService, LocalNotificationService) {
    logger.log("in LeadCaptureCtrl");
    console.log("bio in LeadCaptureCtrl");

    var vm = this;
    var recordTypeId;
    var initialLead = {
      "eventName": "",
      "title": "",
      "firstName": "",
      "lastName": "",
      "jobTitle": "",
      "hospital": "",
      "email": null,
      "telephone": "",
      "country": "",
      "address": "",
      "state": "",
      "zip": "",
      "product": "Select product",
      "notes": ""
    };
    var scrollTimeout;
    var submitSuccessful = false;

    vm.showCancel = false;
    vm.today = new Date();
    vm.newLeadTitle = "";
    vm.lead = {};

    vm.gotoStep = gotoStep;
    vm.inputValidation = inputValidation;
    vm.submitLeadCapture = submitLeadCapture;
    vm.cancelLeadCapture = cancelLeadCapture;

    activate();

    function activate() {
      angular.copy(initialLead,vm.lead);
      vm.showBackButton = true;
      RecordTypeService.getRecordTypeId("Mobile_Lead","Mobile_Dynamic__c").then(function(id){
        recordTypeId = id;
      });
    }

    function gotoStep(step) {
      if (step == "eventinfo") {
        vm.showCancel = true;
        $rootScope.$emit('disableSideMenu', {showSideMenu : false});
        SyncService.setSyncLock("true");
        vm.newLeadTitle = "- new lead";
      }
      if (step == "eventinfo") {
        if (vm.lead.eventName.trim() !== "") {
          vm.showBackButton = false;
        }
      }
      if (step == "default") {
        vm.newLeadTitle = "";
          vm.showCancel = false;
          activate();
          $rootScope.$emit('disableSideMenu', {showSideMenu : true});
          SyncService.setSyncLock("false");
      }
      vm.step = step;
      scrollTimeout = $timeout(function(){
        $ionicScrollDelegate.scrollTop();
      },50);
    }

    function inputValidation(nextStepIfValid) {
      if (nextStepIfValid === "leadinfo") {
        if (vm.lead.eventName.trim() === "") {
          showAlert("Error","Please enter an event name.");
          return;
        }
      }
      if (nextStepIfValid === "leadinfo2") {
        if (vm.lead.firstName.trim() === "") {
          showAlert("Error","Please enter a first name.");
          return;
        }
        if (vm.lead.lastName.trim() === "") {
          showAlert("Error","Please enter a last name.");
          return;
        }
      }
      if (nextStepIfValid === "contactinfo") {
        if (vm.lead.jobTitle.trim() === "") {
          showAlert("Error","Please enter a job title.");
          return;
        }
        if (vm.lead.hospital.trim() === "") {
          showAlert("Error","Please enter a hospital/institution.");
          return;
        }
      }
      if (nextStepIfValid === "topic") {
        console.log("bio vm.lead",vm.lead);
        if (!vm.lead.email && vm.lead.telephone.trim() === "") {
          showAlert("Error","Please enter either a valid e-mail address or a telephone number.");
          return;
        }
        if (vm.lead.email !== null && vm.lead.email !== "") {
          if (vm.lead.email == "undefined" || !validateEmail(vm.lead.email)) {
            showAlert("Error","Please enter a valid e-mail address.");
            return;
          }
        }
      }
      if (nextStepIfValid === "submit") {
        if (vm.lead.product === "Select product") {
          showAlert("Error","Please select a product.");
          return;
        }
        if (vm.lead.notes.trim() === "") {
          showAlert("Error","Please enter your notes.");
          return;
        }
        submitLeadCapture();
        return;
      }
      gotoStep(nextStepIfValid);
    }

    function submitLeadCapture() {
      // Save Lead (to Mobile_Dynamic__ap)
      $ionicLoading.show({
        duration: 5000,
        template: 'Saving lead...',
        animation: 'fade-in',
        showBackdrop: true
      });
      MobileDynamicService.insertRecord(buildLeadRecord()).then(function(resObject) {
        $ionicLoading.hide();
        // Check connectivity, if online then sync, otherwise display message
        if (NetworkService.getNetworkStatus() === "online") {
          // Ensure sync will run
          SyncService.setSyncLock("false");
          // Sync in background
          SyncService.syncTables(['Mobile_Dynamic__ap']);
          // Exit
          submitSuccessful = true;
          exitLeadCapture();
        } else {
          // Offline...
          $rootScope.$emit('updateOutboxCount');
          // Set a local notification
          LocalNotificationService.setLocalNotification();
          // Display 'offline' message
          alertOffline();
        }
      }).catch(function(e){
        logger.error('submitLeadCapture ' + JSON.stringify(e) + " " + JSON.stringify(orderForm));
        $ionicLoading.hide();
        // if (typeof(e.status) != "undefined" && e.status == 101107) {
        //   $scope.dataNoLongerAvailable("store visit");
        // } else {
        //   var alertPopup = $ionicPopup.alert({
        //     title: 'Save failed',
        //     template: '<p>Sorry, something went wrong.</p><p class="error_details">Error: ' + e.status + ' - ' + e.mc_add_status + '</p>'
        //   });
        // }
      });
    }

    function buildLeadRecord() {
      var lead = {};
      lead.Name = "TMP-" + new Date().valueOf();
      lead.Event_Name__c = vm.lead.eventName;
      lead.Title_Designation__c = vm.lead.title;
      lead.First_Name__c = vm.lead.firstName;
      lead.Last_Name__c = vm.lead.lastName;
      lead.Job_Title__c = vm.lead.jobTitle;
      lead.Hospital_Institution__c = vm.lead.hospital;
      if (!vm.lead.email) {
        lead.Email__c = "";
      } else {
        lead.Email__c = vm.lead.email;
      }
      if (vm.lead.telephone) {
        lead.Telephone__c = vm.lead.telephone;
      }
      if (vm.lead.country) {
        lead.Country__c = vm.lead.country;
      }
      if (vm.lead.address) {
        lead.Address__c = vm.lead.address;
      }
      if (vm.lead.state) {
        lead.State__c = vm.lead.state;
      }
      if (vm.lead.zip) {
        lead.ZIP__c = vm.lead.zip;
      }
      lead.Product__c = vm.lead.product;
      lead.Notes__c = vm.lead.notes;
      if (recordTypeId !== "") {
        lead.RecordTypeId = recordTypeId;
      }
      lead.Date_Entered__c = new Date();
      return lead;
    }

    function cancelLeadCapture(){
      var confirmPopup = $ionicPopup.confirm({
        title: 'Cancel',
        template: 'Are you sure?',
        cssClass: 'bio-popup',
        cancelText: '&nbsp;&nbsp;&nbsp;No',
        cancelType: 'button-dark ion-close-round',
        okText: '&nbsp;&nbsp;&nbsp;Yes',
        okType: 'button-positive ion-checkmark-round'
      });
      confirmPopup.then(function(res) {
        if (res) {
          exitLeadCapture();
        }
      });
    }

    function exitLeadCapture() {
      $rootScope.$emit('disableSideMenu', {showSideMenu : true});
      SyncService.setSyncLock("false");
      if (submitSuccessful) {
        alertSuccess();
      } else {
        $state.go("app.home");
      }
    }

    function alertSuccess(){
      var alertPopup = $ionicPopup.alert({
        title: 'New lead',
        template: 'Submission successful',
        cssClass: 'bio-popup'
      });
      alertPopup.then(function(res) {
        if (res) {
          $state.go("app.home");
        }
      });
    }

    function alertOffline(){
      var alertPopup = $ionicPopup.alert({
        title: 'You are currently offline',
        template: 'Synchronisation will take place when you are next online',
        cssClass: 'bio-popup'
      });
      alertPopup.then(function(res) {
        if (res) {
          exitLeadCapture();
        }
      });
    }

    function showAlert(title, template){
      var alertPopup = $ionicPopup.alert({
        title: title,
        template: template,
        cssClass: 'bio-popup'
      });
      alertPopup.then(function(res) {
        if (res) {
        }
      });
    }

    function validateEmail(email) {
        var re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return re.test(email);
    }

    $scope.$on('$destroy', function() {
      logger.log("LeadCaptureCtrl destroy");
      console.log("bio LeadCaptureCtrl destroy");
      $timeout.cancel(scrollTimeout);
    });

  }

})();
/**
 * Lead History Controller
 *
 * @description controller for lead history
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('LeadHistoryCtrl', LeadHistoryCtrl);

  LeadHistoryCtrl.$inject = ['$rootScope', '$scope', '$window', '$ionicLoading', '$ionicModal', '$state', 'logger', 'RecordTypeService', 'MobileDynamicService'];

  function LeadHistoryCtrl($rootScope, $scope, $window, $ionicLoading, $ionicModal, $state, logger, RecordTypeService, MobileDynamicService) {
    logger.log("in LeadHistoryCtrl");
    console.log("bio in LeadHistoryCtrl");

    var vm = this;

    vm.showModal = showModal;
    vm.closeModal = closeModal;
    vm.goHome = goHome;

    activate();

    function activate() {
      $ionicLoading.show({
        duration: 5000,
        template: 'Loading...',
        animation: 'fade-in',
        showBackdrop: true,
      });
      vm.leads = [];
      RecordTypeService.getRecordTypeId("Mobile_Lead","Mobile_Dynamic__c").then(function(recordTypeId) {
        return MobileDynamicService.getRecords(recordTypeId);
      }).then(function(records) {
        for (var i = 0; i < records.length; i++) {
          // Check whether the record has been synced
          if (records[i].Id.indexOf("PROXY") == -1) {
            // Yes, it's been synced
            vm.leads.push(records[i]);
          }
        }
        console.log("bio vm.leads",vm.leads);
        $ionicLoading.hide();
      });
    }

    function showModal(record) {
      $ionicModal.fromTemplateUrl($window.RESOURCE_ROOT + "templates/leadDetail.html", {
        scope: $scope,
        animation: 'slide-in-up'
      }).then(function(modal) {
        vm.modal = modal;
        vm.modal.lead = record;
        console.log("bio showModal vm.modal.lead",vm.modal.lead);
        vm.modal.show();
      });
    }

    function closeModal() {
      console.log("bio closeModal");
      if (vm.modal) {
        vm.modal.hide();
        vm.modal.remove();
        delete vm.modal;
      }
    }

    function goHome() {
      $state.go("app.home");
    }

    // Handle events fired from the SyncService
    var deregisterHandleSyncTables = $rootScope.$on('syncTables', function(event, args) {
      logger.log("LeadHistoryCtrl syncTables: " + JSON.stringify(args));
      console.log("bio LeadHistoryCtrl syncTables: " + JSON.stringify(args));
      if (args.result.toString().indexOf("TableComplete") >= 0) {
        var syncedTable = args.result.replace("TableComplete ","");
        if (syncedTable == "Mobile_Dynamic__ap") {
          activate();
        }
      }
    });

    $scope.$on('$destroy', function() {
      logger.log("LeadHistoryCtrl destroy");
      console.log("bio LeadHistoryCtrl destroy");
      deregisterHandleSyncTables();
      if (vm.modal) {
        vm.modal.remove();
        delete vm.modal;
      }
    });

  }

})();
/**
 * Menu Controller
 *
 * @description controller for 'app' router state. It's always run regardless of warm/cold start or fresh install.
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('MenuCtrl', MenuCtrl);

  MenuCtrl.$inject = ['$rootScope', '$scope', '$timeout', '$ionicLoading', '$ionicSideMenuDelegate', '$location', '$state', '$ionicScrollDelegate', 'logger', 'MenuService', 'SyncService', 'UserService', 'RecordTypeService', 'OutboxService', 'LocalNotificationService'];

  function MenuCtrl($rootScope, $scope, $timeout, $ionicLoading, $ionicSideMenuDelegate, $location, $state, $ionicScrollDelegate, logger, MenuService, SyncService, UserService, RecordTypeService, OutboxService, LocalNotificationService) {
    var vm = this;
    var feedbackTimeout;
    var gotoPageTimeout;
    var menuRefreshTimeout;

    vm.allSideMenuOptions = [];
    vm.stimulanMenuOption = {};
    vm.settingsMenuOption = {};
    vm.menuOptions = [];
    vm.selectedItem = null;
    vm.feedbackMsgText = "";
    vm.showFeedbackMsg = false;
    vm.showSideMenu = true;

    vm.showSubmenu = showSubmenu;
    vm.goBack = goBack;
    vm.doRefreshAndSync = doRefreshAndSync;
    vm.gotoPage = gotoPage;

    activate();

    function activate() {
      // logger.log("MenuCtrl activate");
      // console.log("bio MenuCtrl activate");
      MenuService.getSideMenuJson().then(function(sidemenu) {
        // console.log("bio MenuCtrl getSideMenuJson sidemenu",sidemenu);
        if (sidemenu && sidemenu[0].length > 0) {
          // This will be after a 'warm' app start
          vm.allSideMenuOptions = sidemenu[0];
          vm.stimulanMenuOption = sidemenu[1];
          vm.settingsMenuOption = sidemenu[2];
          vm.menuOptions = vm.allSideMenuOptions;
          // Load the record types used when saving the lead capture and unsolicited requests (when saved to Mobile_Dynamic__ap)
          setRecordTypes();
          // Check for dirty (unsynced) records
          updateOutboxCount();
          menuRefreshTimeout = $timeout(function() {
            $scope.$apply();
            $ionicLoading.hide();
          },0);
        } else {
          // This will be after an initial install of app.
          // Make sure the menu data is read/loaded before accessing tables for record types/outbox
          MenuService.buildAndSetSideMenuJson().then(function(result) {
            // console.log("bio MenuCtrl getSideMenuJson result",result);
            vm.allSideMenuOptions = result[0];
            vm.stimulanMenuOption = result[1];
            vm.settingsMenuOption = result[2];
            vm.menuOptions = vm.allSideMenuOptions;
            if (vm.allSideMenuOptions.length > 0) {
              // Load the record types used when saving the lead capture and unsolicited requests (when saved to Mobile_Dynamic__ap)
              setRecordTypes();
              // Check for dirty (unsynced) records
              updateOutboxCount();
              // Make sure the menu updates after reading record types, outbox and angular/ionic has done it's stuff
              menuRefreshTimeout = $timeout(function() {
                $scope.$apply();
                $ionicLoading.hide();
              }, 5000);
            }
          });
        }
      });
    }

    function showSubmenu(item) {
      vm.menuOptions = item.submenu;
      vm.selectedItem = item;
      $ionicScrollDelegate.scrollTop();
    }

    function goBack() {
      if (vm.selectedItem) {
        if (vm.selectedItem.parentid === 0) {
          vm.menuOptions = vm.allSideMenuOptions;
          vm.selectedItem = null;
        } else {
          var parentItem = findItemById(vm.allSideMenuOptions, vm.selectedItem.parentid);
          showSubmenu(parentItem);
        }
      }
    }

    function findItemById(obj, id) {
      if (obj.id == id) {
        return obj;
      }
      for (var i in obj) {
        if (obj[i] !== null && typeof(obj[i]) == "object") {
          var result = findItemById(obj[i], id);
          if (result) {
            return result;
          }
        }
      }
      return null;
    }

    function doRefreshAndSync() {
      SyncService.syncTables(['Mobile_Refresh__ap', 'Content_Item__ap', 'DOF__ap', 'DOF_Item__ap', 'Mobile_Dynamic__ap', 'Surgeon_in_Hospital__ap']);
    }

    function gotoPage(path) {
      gotoPageTimeout = $timeout(function() {
        // If in sub menu, switch the menu back to the parent before displaying sub menu page
        goBack();
        $location.path(path);
      },0);
    }

    function setRecordTypes() {
      // console.log("bio MenuCtrl setRecordTypes");
      // Get record types (stored in Mobile_Refresh__ap),
      // used when saving lead capture and unsolicited requests to Mobile_Dynamic__ap table
      RecordTypeService.readAndSetRecordTypes();
    }

    function checkForMenuChanges() {
      MenuService.buildAndSetSideMenuJson().then(function(result) {
        // console.log("bio MenuCtrl after syncTables buildAndSetSideMenuJson",result);
        var reloadMenu = false;
        var newAllSideMenuOptions = result[0];
        var newStimulanMenuOption = result[1];
        // Check to see if main menu order or names have changed
        var currentMainMenuOptionNames = _.pluck(vm.allSideMenuOptions, "name");
        var newMainMenuOptionNames = _.pluck(newAllSideMenuOptions, "name");
        // console.log("bio MenuCtrl after syncTables main joins1",currentMainMenuOptionNames.join());
        // console.log("bio MenuCtrl after syncTables main joins2",newMainMenuOptionNames.join());
        if (newMainMenuOptionNames.join() !== currentMainMenuOptionNames.join()) {
          reloadMenu = true;
        }
        // Check to see if stimulan sub menu order or names have changed
        var currentStimulanMenuOptionNames = _.pluck(vm.stimulanMenuOption.submenu, "name");
        var newStimulanMenuOptionNames = _.pluck(newStimulanMenuOption.submenu, "name");
        // console.log("bio MenuCtrl after syncTables stimulan joins1",currentStimulanMenuOptionNames.join());
        // console.log("bio MenuCtrl after syncTables stimulan joins2",newStimulanMenuOptionNames.join());
        if (newStimulanMenuOptionNames.join() !== currentStimulanMenuOptionNames.join()) {
          reloadMenu = true;
        }
        if (reloadMenu) {
          vm.allSideMenuOptions = newAllSideMenuOptions;
          vm.stimulanMenuOption = newStimulanMenuOption;
          vm.menuOptions = vm.allSideMenuOptions;
          // If on sub menu then go back so refreshing of menu doesn't override sub menu
          if (vm.selectedItem) {
            goBack();
          }
        }
      });
    }

    // Handle events fired from the SyncService.
    // Used to update the feedback message at bottom of page
    var deregisterHandleSyncTables = $rootScope.$on('syncTables', function(event, args) {
      logger.log("MenuCtrl syncTables: " + JSON.stringify(args));
      console.log("bio MenuCtrl syncTables: " + JSON.stringify(args));
      switch (args.result.toString()) {
        case "StartSync" :
          displayFeedbackMsg("Syncing...");
          break;
        case "Complete" :
          LocalNotificationService.cancelNotification();
          delayHidingOfFeedbackMsg(0);
          break;
        case "InitialLoadComplete" :
          // We can now load the menu because table Mobile_Refresh__ap will now be populated after initial install of app
          activate();
          // Save the fact that we've run the initial data load for the app install
          UserService.setProcessDone("initialDataLoaded");
          break;
        case "100497" :
          displayFeedbackMsg("Sync too soon, please try again in a minute");
          delayHidingOfFeedbackMsg(3000);
          break;
        case "100498" :
          displayFeedbackMsg("Sync already in progress");
          displaySyncingMessageAgain();
          break;
        case "100402" :
          displayFeedbackMsg("Please connect before syncing");
          LocalNotificationService.setLocalNotification();
          delayHidingOfFeedbackMsg(3000);
          break;
        default :
          if (args.result.toString().indexOf("Error") >= 0) {
            displayFeedbackMsg(args.result.toString());
            delayHidingOfFeedbackMsg(3000);
          } else if (args.result.toString().indexOf("TableComplete") >= 0) {
            var syncedTable = args.result.replace("TableComplete ","");
            if (syncedTable == "DOF__ap" || syncedTable == "Mobile_Dynamic__ap") {
              updateOutboxCount();
            }
            if (syncedTable == "Mobile_Refresh__ap") {
              checkForMenuChanges();
              setRecordTypes();
            }
          }
      }
    });

    function displayFeedbackMsg(msg) {
      vm.feedbackMsgText = msg;
      vm.showFeedbackMsg = true;
    }

    function delayHidingOfFeedbackMsg(delay) {
      feedbackTimeout = $timeout(function() {
        vm.showFeedbackMsg = false;
      },delay);
    }

    function displaySyncingMessageAgain() {
      feedbackTimeout = $timeout(function() {
        displayFeedbackMsg("Syncing...");
      },3000);
    }

    function updateOutboxCount() {
      OutboxService.getDirtyRecordsCount().then(function(result) {
        if (result > 0) {
          vm.outboxCount = " (" + result + ")";
        } else {
          vm.outboxCount = "";
        }
      });
    }

    var deregisterHandleSetSideMenuVisibility = $rootScope.$on('disableSideMenu', function(event, args) {
      vm.showSideMenu = args.showSideMenu;
      $ionicSideMenuDelegate.canDragContent(args.showSideMenu);
    });

    var deregisterHandleShowStimulan = $rootScope.$on('showStimulanMenu', function(event, args) {
      showSubmenu(vm.stimulanMenuOption);
      $ionicSideMenuDelegate.toggleLeft();
    });

    var deregisterHandleShowSettings = $rootScope.$on('showSettingsMenu', function(event, args) {
      showSubmenu(vm.settingsMenuOption);
      $ionicSideMenuDelegate.toggleLeft();
    });

    var deregisterHandleShowSideMenu = $rootScope.$on('showSideMenu', function(event, args) {
      $ionicSideMenuDelegate.toggleLeft();
    });

    var deregisterHandleUpdateOutboxCount = $rootScope.$on('updateOutboxCount', function(event, args) {
      updateOutboxCount();
    });

    $scope.$on('$destroy', function() {
      logger.log("MenuCtrl destroy");
      console.log("bio MenuCtrl destroy");
      deregisterHandleSyncTables();
      deregisterHandleSetSideMenuVisibility();
      deregisterHandleShowStimulan();
      deregisterHandleShowSettings();
      deregisterHandleUpdateOutboxCount();
      deregisterHandleShowSideMenu();
      $timeout.cancel(feedbackTimeout);
      $timeout.cancel(gotoPageTimeout);
      $timeout.cancel(menuRefreshTimeout);
    });

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
	    $location.url('app/settings');
	    var alertPopup = $ionicPopup.alert({
	      title: 'Access Denied'
	    });
	    alertPopup.then(function(res) {
	      //$location.url('app/settings');
	      $scope.$apply();
	    });
	  }

	  DevService.allTables().then(function(tables) {
	    $scope.tables = tables;
	  }, function(reason) {
	    console.error('Angular: promise returned reason -> ' + reason);
	  });

	  $scope.showTable = function(tableName) {
	    $location.path(decodeURIComponent("/app/settings/mti/" + tableName));
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
	    for (var i = 0, len = tableRec.length; i < len; i++) {
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

	  $scope.reorder = function() {
	  	$scope.tableRecs = $scope.tableRecs.reverse();
	  };

  }

})();
/**
 * Order History Controller
 *
 * @description controller for order form history
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('OrderHistoryCtrl', OrderHistoryCtrl);

  OrderHistoryCtrl.$inject = ['$rootScope', '$scope', '$ionicLoading', '$window', '$ionicModal', '$state', 'logger', 'OrderFormService', 'UserService'];

  function OrderHistoryCtrl($rootScope, $scope, $ionicLoading, $window, $ionicModal, $state, logger, OrderFormService, UserService) {
    logger.log("in OrderHistoryCtrl");
    console.log("bio in OrderHistoryCtrl");

    var vm = this;

    vm.showModal = showModal;
    vm.closeModal = closeModal;
    vm.goHome = goHome;

    activate();

    function activate() {
      $ionicLoading.show({
        duration: 5000,
        template: 'Loading...',
        animation: 'fade-in',
        showBackdrop: true,
      });
      // Get user's currency symbol
      UserService.getUserCurrencySymbol().then(function(result) {
        vm.currencySymbol = result;
      });
      // Get the orders and order items
      vm.orders = [];
      vm.orderItems = [];
      OrderFormService.getOrders().then(function(records) {
        for (var i = 0; i < records.length; i++) {
          // console.log("bio records[i]",records[i]);
          // Check whether the record has been synced
          if (records[i].Id.indexOf("PROXY") == -1) {
            // Yes, it's been synced...
            // Build the 'Hospital notification' output text
            var hospitalNotification;
            if (records[i].Send_Confirmation__c == "Do not send") {
              hospitalNotification = records[i].Send_Confirmation__c;
            } else if (records[i].Send_Confirmation__c == "Send to alternative address") {
              hospitalNotification = "alternative e-mail address - " + records[i].Alternative_Email__c;
            } else {
              hospitalNotification = "e-mail address on file - " + records[i].Hospital_Email__c;
            }
            vm.orders.push({"record": records[i], "items": [], "hospitalNotification": hospitalNotification});
          }
        }
        // Get order items
        return OrderFormService.getOrderItems();
      }).then(function(records) {
        // Add the order items (products) to the order record
        for (var j = 0; j < records.length; j++) {
          for (var k = 0; k < vm.orders.length; k++) {
            if (vm.orders[k].record.Id == records[j].DOF__c) {
              if (records[j].Product_Name__c) {
                vm.orders[k].items.push({"productName": records[j].Product_Name__c, "lotNumber": records[j].Lot_Number__c, "price": records[j].Entered_Price__c, "expiryDate": records[j].Expiry_Date__c});
              } else {
                vm.orders[k].items.push({"lotNumber": records[j].Lot_Number__c, "price": records[j].Entered_Price__c});
              }
            }
          }
        }
        // console.log("bio vm.orders",vm.orders);
        $ionicLoading.hide();
      });
    }

    function showModal(order) {
      $ionicModal.fromTemplateUrl($window.RESOURCE_ROOT + "templates/orderDetail.html", {
        scope: $scope,
        animation: 'slide-in-up'
      }).then(function(modal) {
        vm.modal = modal;
        vm.modal.order = order;
        // console.log("bio showModal vm.modal.order",vm.modal.order);
        vm.modal.show();
      });
    }

    function closeModal() {
      // console.log("bio closeModal");
      if (vm.modal) {
        vm.modal.hide();
        vm.modal.remove();
        delete vm.modal;
      }
    }

    function goHome() {
      $state.go("app.home");
    }

    // Handle events fired from the SyncService
    var deregisterHandleSyncTables = $rootScope.$on('syncTables', function(event, args) {
      logger.log("OrderHistoryCtrl syncTables: " + JSON.stringify(args));
      // console.log("bio OrderHistoryCtrl syncTables: " + JSON.stringify(args));
      if (args.result.toString().indexOf("TableComplete") >= 0) {
        var syncedTable = args.result.replace("TableComplete ","");
        if (syncedTable == "DOF_Item__ap") {
          activate();
        }
      }
    });

    $scope.$on('$destroy', function() {
      logger.log("OrderHistoryCtrl destroy");
      console.log("bio OrderHistoryCtrl destroy");
      deregisterHandleSyncTables();
      if (vm.modal) {
        vm.modal.remove();
        delete vm.modal;
      }
    });

  }

})();
/**
 * Order Form Controller
 *
 * @description controller for order form functionality
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('OrderFormCtrl', OrderFormCtrl);

  OrderFormCtrl.$inject = ['$rootScope', '$scope', '$window', '$ionicPopup', '$state', '$ionicLoading', '$timeout', '$cordovaBarcodeScanner', '$ionicScrollDelegate', 'logger', 'OrderFormService', 'SyncService', 'RecentItemsService', 'NetworkService', 'LocalNotificationService', 'UserService'];

  function OrderFormCtrl($rootScope, $scope, $window, $ionicPopup, $state, $ionicLoading, $timeout, $cordovaBarcodeScanner, $ionicScrollDelegate, logger, OrderFormService, SyncService, RecentItemsService, NetworkService, LocalNotificationService, UserService) {
    logger.log("in OrderFormCtrl");
    // console.log("bio in OrderFormCtrl");

    var vm = this;

    var signaturePad;
    var signatureDataURL;
    var signaturePadTimeout;
    var scannerTimeout;
    var scrollTimeout;
    var onBeginSignatureTimeout;
    var onEndSignatureTimeout;
    var submitSuccessful = false;

    vm.allProducts = [];
    vm.selectedProducts = [];
    vm.showCancel = false;
    vm.isFirstTimeThru = true;
    vm.newHospital = {"name" : "", "address" : ""};
    vm.newSurgeon = {"firstName" : "", "lastName" : ""};
    vm.hospitalRep = {"firstName" : "", "lastName" : ""};
    vm.notification = {"email" : "", "alternativeEmail" : "", "dontSend" : false, "isEmail" : false, "isAlternativeEmail" : false};
    vm.today = new Date();
    vm.hospitalTab = "hospitalrecent";

    vm.gotoStep = gotoStep;
    vm.displayNewManualInput = displayNewManualInput;
    vm.manualInputValidation = manualInputValidation;
    vm.manualInputPriceValidation = manualInputPriceValidation;
    vm.scannedProductDetailsValidation = scannedProductDetailsValidation;
    vm.newHospitalValidation = newHospitalValidation;
    vm.hospitalDetailsValidation = hospitalDetailsValidation;
    vm.newSurgeonValidation = newSurgeonValidation;
    vm.surgeonDetailsValidation = surgeonDetailsValidation;
    vm.hospitalRepValidation = hospitalRepValidation;
    vm.notificationValidation = notificationValidation;
    vm.chargeCheckboxChange = chargeCheckboxChange;
    vm.stockCheckboxChange = stockCheckboxChange;
    vm.notificationEmailCheckboxChange = notificationEmailCheckboxChange;
    vm.displayHospitalDetails = displayHospitalDetails;
    vm.displaySurgeonDetails = displaySurgeonDetails;
    vm.displayHospitalTab = displayHospitalTab;
    vm.displaySurgeonTab = displaySurgeonTab;
    vm.clearHospitalSearch = clearHospitalSearch;
    vm.editProduct = editProduct;
    vm.removeProduct = removeProduct;
    vm.scanBarcode = scanBarcode;
    vm.cancelOrder = cancelOrder;
    vm.submitOrder = submitOrder;
    vm.clearCanvas = clearCanvas;

    activate();

    // Register window resize event
    angular.element($window).on('resize', windowResizeHandler);

    function activate() {
      // Load all products
      OrderFormService.getProducts().then(function(records) {
        vm.allProducts = records;
      });
      // Get all hospitals for user's distributorship
      vm.hospitals = [];
      OrderFormService.getHospitals().then(function(records) {
        // console.log("bio hospitals",records);
        for (var h = 0; h < records.length; h++) {
          vm.hospitals.push({"id": records[h].Hospital__c, "name": records[h].Hospital_Name__c, "email": records[h].Hospital_Email__c});
        }
      });
      // Get all Surgeons for all hospitals...they are filtered further down for a specific hospital
      vm.allSurgeons = [];
      OrderFormService.getSurgeons().then(function(records) {
        // console.log("bio surgeons",records);
        for (var s = 0; s < records.length; s++) {
          vm.allSurgeons.push({"id": records[s].Surgeon__c, "name": records[s].Salutation__c + " " + records[s].First_Name__c + " " + records[s].Last_Name__c, "hospitalId": records[s].Hospital__c});
        }
      });
      // Get recent hospitals
      RecentItemsService.getRecentItems("recentHospitals").then(function(recentItems) {
        vm.recentHospitals = recentItems;
        if (recentItems.length > 7) {
          RecentItemsService.setRecentItems("recentHospitals",recentItems.slice(0,7));
        }
      });
      // Get all recent surgeons (filtered by hospital when surgeons displayed)
      RecentItemsService.getRecentItems("recentSurgeons").then(function(recentItems) {
        vm.allRecentSurgeons = recentItems;
        if (recentItems.length > 40) {
          RecentItemsService.setRecentItems("recentSurgeons",recentItems.slice(0,40));
        }
      });
      // For manual input, allow Back to initial menu options
      vm.showManualInputBackButton = true;
      // Get user's currency symbol
      UserService.getUserCurrencySymbol().then(function(result) {
        vm.currencySymbol = result;
      });
    }

    function gotoStep(step) {
      if (step == "manual" || step == "scangood" || step == "scanbad") {
        vm.showCancel = true;
        $rootScope.$emit('disableSideMenu', {showSideMenu : false});
        SyncService.setSyncLock("true");
        checkRecentHospitalsAreStillValid();
        checkRecentSurgeonsAreStillValid();
      }
      if (step == "confirmation") {
        vm.isFirstTimeThru = false;
        createSignaturePad();
      }
      if (step == "default") {
        vm.showCancel = false;
        $rootScope.$emit('disableSideMenu', {showSideMenu : true});
        SyncService.setSyncLock("false");
      }
      if (step == "manualinputgood") {
        vm.showManualInputBackButton = false;
      }
      vm.step = step;
      scrollTimeout = $timeout(function(){
        $ionicScrollDelegate.scrollTop();
      },50);
    }

    function createSignaturePad() {
      // console.log("bio OrderFormCtrl createSignaturePad",signatureDataURL);
        // Give time for angular/ionic to make the signature canvas element available
        signaturePadTimeout = $timeout(function() {
          var canvas = angular.element(document.getElementById("signatureCanvas"))[0];
          resizeCanvas(canvas);
          signaturePad = new SignaturePad(canvas, {
            backgroundColor: '#FFFFFF',
            minWidth: 1,
            maxWidth: 1.5,
            onBegin: onBeginSignature,
            onEnd: onEndSignature
          });
          // Check whether we already have signature data
          // (user may have edited details and is now coming back into confirmation page)
          if (signatureDataURL) {
            signaturePad.fromDataURL(signatureDataURL);
          }
          canvas = null;
        },0);
    }

    function onBeginSignature() {
      onBeginSignatureTimeout = $timeout(function(){
        $ionicScrollDelegate.freezeAllScrolls(true);
      },0);
    }

    function onEndSignature() {
      onEndSignatureTimeout = $timeout(function(){
        $ionicScrollDelegate.freezeAllScrolls(false);
        signatureDataURL = signaturePad.toDataURL();
      },0);
    }

    function displayNewManualInput(step) {
      vm.manualInput = {};
      vm.manualInput.lotNumber = {"part1" : null, "part2" : null, "part3" : "", "part4" : ""};
      vm.manualInput.price = null;
      vm.manualInput.isCharge = true;
      vm.manualInput.isNoCharge = false;
      vm.product = null;
      vm.gotoStep(step);
    }

    function manualInputValidation(nextStepIfValid) {
      if (vm.manualInput.lotNumber.part1 === null || vm.manualInput.lotNumber.part2 === null || vm.manualInput.lotNumber.part1 === "" || vm.manualInput.lotNumber.part2 === "") {
        showAlert("Error","Please enter all parts of the lot number.");
      } else if (vm.manualInput.lotNumber.part1 < 0 || vm.manualInput.lotNumber.part1 > 99) {
        showAlert("Error","The first part of the lot number can only be a maximum of two digits.");
      } else if (vm.manualInput.lotNumber.part2 < 0 || vm.manualInput.lotNumber.part2 > 99) {
        showAlert("Error","The second part of the lot number can only be a maximum of two digits.");
      } else if (vm.manualInput.lotNumber.part3.trim() === "") {
        showAlert("Error","Please enter all parts of the lot number.");
      } else {
        vm.manualInput.lotNumberCombined = ("00" + vm.manualInput.lotNumber.part1).slice(-2) + "/" + ("00" + vm.manualInput.lotNumber.part2).slice(-2) + "-" + vm.manualInput.lotNumber.part3 + (vm.manualInput.lotNumber.part4.trim() !== "" ?  "/" + vm.manualInput.lotNumber.part4.trim() : "");
        gotoStep(nextStepIfValid);
      }
    }

    function manualInputPriceValidation(nextStepIfValid) {
      // console.log("bio manualInputPriceValidation",vm.manualInput);
      if (vm.manualInput.isCharge && (vm.manualInput.price === null || vm.manualInput.price === 0)) {
        confirmManualInputNoPrice(nextStepIfValid);
      } else {
        manualInputPriceValidationContinued(nextStepIfValid);
      }
    }

    function confirmManualInputNoPrice(nextStepIfValid){
      var confirmPopup = $ionicPopup.confirm({
        title: 'No Price Entered',
        template: 'Would you like to enter a price?',
        cssClass: 'bio-popup',
        cancelText: '&nbsp;&nbsp;&nbsp;No',
        cancelType: 'button-dark ion-close-round',
        okText: '&nbsp;&nbsp;&nbsp;Yes',
        okType: 'button-positive ion-checkmark-round'
      });
      confirmPopup.then(function(res) {
        if (!res) {
          vm.manualInput.price = 0;
          manualInputPriceValidationContinued(nextStepIfValid);
        }
      });
    }

    function manualInputPriceValidationContinued(nextStepIfValid) {
      // console.log("bio manualInputPriceValidationContinued",vm.manualInput);
      if (vm.manualInput.isNoCharge && vm.manualInput.price !== null) {
        showAlert("Error","You have entered a price, but selected no charge.");
        return;
      }
      if (vm.manualInput.isCharge && !isValidPrice(vm.manualInput.price)) {
        showAlert("Error","Please enter a valid price.");
      } else {
        if (vm.manualInput.isNoCharge) {
          vm.manualInput.price = 0;
        }
        vm.selectedProducts.push({"id" : "MANUAL-" + new Date().valueOf(), "lotNumber" : vm.manualInput.lotNumberCombined, "price": vm.manualInput.price, "isCharge": vm.manualInput.isCharge, "isNoCharge": vm.manualInput.isNoCharge});
        if (nextStepIfValid == 'selecthospital') {
          displayHospitalSelection(nextStepIfValid);
        } else {
          gotoStep(nextStepIfValid);
        }
      }
    }

    function scannedProductDetailsValidation(nextStepIfValid) {
      // console.log("bio scannedProductDetailsValidation",vm.product);
      if (vm.product.isCharge && (vm.product.price === null || vm.product.price === 0)) {
        confirmScannedInputNoPrice(nextStepIfValid);
      } else {
        scannedProductDetailsValidationContinued(nextStepIfValid);
      }
    }

    function confirmScannedInputNoPrice(nextStepIfValid) {
      var confirmPopup = $ionicPopup.confirm({
        title: 'No Price Entered',
        template: 'Would you like to enter a price?',
        cssClass: 'bio-popup',
        cancelText: '&nbsp;&nbsp;&nbsp;No',
        cancelType: 'button-dark ion-close-round',
        okText: '&nbsp;&nbsp;&nbsp;Yes',
        okType: 'button-positive ion-checkmark-round'
      });
      confirmPopup.then(function(res) {
        if (!res) {
          vm.product.price = 0;
          scannedProductDetailsValidationContinued(nextStepIfValid);
        }
      });
    }

    function scannedProductDetailsValidationContinued(nextStepIfValid) {
      // console.log("bio scannedProductDetailsValidationContinued",vm.product);
      if (vm.product.isNoCharge && vm.product.price !== null) {
        showAlert("Error","You have entered a price, but selected no charge.");
        return;
      }
      if (vm.product.isCharge && !isValidPrice(vm.product.price)) {
        showAlert("Error","Please enter a valid price.");
      } else {
        if (vm.product.isNoCharge) {
          vm.product.price = 0;
        }
        vm.selectedProducts.push(vm.product);
        if (nextStepIfValid == 'selecthospital') {
          displayHospitalSelection(nextStepIfValid);
        } else {
          gotoStep(nextStepIfValid);
        }
      }
    }

    function hospitalDetailsValidation(nextStepIfValid) {
      if (vm.selectedHospital.replaceStockYes && vm.selectedHospital.replaceStockComments.trim() === "") {
        showAlert("Error","Please enter stock replacement details if you've selected 'Replace stock to'.");
      } else if (vm.selectedHospital.replaceStockNo && vm.selectedHospital.replaceStockComments.trim() !== "") {
        showAlert("Error","You have entered stock details but selected 'Don't replace stock'.");
      } else {
        vm.selectedHospital.stockInstruction = vm.selectedHospital.replaceStockYes ? "Replace stock" : "Don't replace stock";
        displaySurgeonSelection(nextStepIfValid);
      }
    }

    function newHospitalValidation(nextStepIfValid) {
      if (vm.newHospital.name.trim() === "" && vm.newHospital.address.trim() === "") {
        showAlert("Error","Please enter a name and address of the hospital - or select one from the Recent/All tabs.");
      } else if ( (vm.newHospital.name.trim() === "" && vm.newHospital.address.trim() !== "") || (vm.newHospital.name.trim() !== "" && vm.newHospital.address.trim() === "") ) {
        showAlert("Error","Please enter both the name and address of the hospital.");
      } else {
        displayHospitalDetails(vm.newHospital, nextStepIfValid);
      }
    }

    function newSurgeonValidation(nextStepIfValid) {
      if (vm.newSurgeon.firstName.trim() === "" && vm.newSurgeon.lastName.trim() === "") {
        showAlert("Error","Please enter a first and last name for the surgeon - or select one from the Recent/All tabs.");
      } else if ( (vm.newSurgeon.firstName.trim() === "" && vm.newSurgeon.lastName.trim() !== "") || (vm.newSurgeon.firstName.trim() !== "" && vm.newSurgeon.lastName.trim() === "") ) {
        showAlert("Error","Please enter both the first and last names.");
      } else {
        vm.newSurgeon.name = vm.newSurgeon.firstName.trim() + " " + vm.newSurgeon.lastName.trim();
        displaySurgeonDetails(vm.newSurgeon, nextStepIfValid);
      }
    }

    function surgeonDetailsValidation(nextStepIfValid) {
      // console.log("bio vm.selectedProducts",vm.selectedProducts);
      if (!vm.procedureType || vm.procedureType === "Please select") {
        showAlert("Error","Please select type of procedure.");
      } else if (!vm.procedureDate) {
        showAlert("Error","Please enter a valid procedure date.");
      } else {
        if (vm.selectedProducts && vm.selectedProducts.length > 0) {
          // User must add comments if all products have 'No Charge'
          var isNoChargeCount = 0;
          var zeroPriceCount = 0;
          for (var i = 0, len = vm.selectedProducts.length; i < len; i++) {
            if (vm.selectedProducts[i].isNoCharge){
              isNoChargeCount += 1;
            }
            if (vm.selectedProducts[i].price === 0){
              zeroPriceCount += 1;
            }
          }
          if (isNoChargeCount !== 0 && vm.procedureComments.trim() === "") {
            showAlert("Error","You selected no charge. Please add your reason in the comment section.");
            return;
          }
          if (zeroPriceCount !== 0 && vm.procedureComments.trim() === "") {
            showAlert("Error","You entered " + vm.currencySymbol + "0.00. Please add your reason in the comment section.");
            return;
          }
        }
        gotoStep(nextStepIfValid);
      }
    }

    function hospitalRepValidation(nextStepIfValid) {
      if ( (vm.hospitalRep.firstName.trim() === "" && vm.hospitalRep.lastName.trim() !== "") || (vm.hospitalRep.firstName.trim() !== "" && vm.hospitalRep.lastName.trim() === "") ) {
        showAlert("Error","Please enter both the first and last names.");
      } else {
        // Setup data for next screen
        vm.notification.email = vm.selectedHospital.email;
        if (vm.isFirstTimeThru) {
          vm.notification.isEmail = true;
          vm.notification.isAlternativeEmail = false;
          vm.notification.dontSend = false;
        }
        gotoStep(nextStepIfValid);
      }
    }

    function notificationValidation(nextStepIfValid) {
      if (vm.notification.isAlternativeEmail && !vm.notification.alternativeEmail) {
        showAlert("Error","Please enter a valid alternative e-mail address.");
      } else if (!vm.notification.isAlternativeEmail && vm.notification.alternativeEmail) {
        showAlert("Error","You have entered an alternative e-mail address but not tapped the checkedbox.");
      } else if (vm.notification.isAlternativeEmail && vm.notification.alternativeEmail && !validateEmail(vm.notification.alternativeEmail)) {
        showAlert("Error","Please enter a valid e-mail address.");
      } else if (vm.notification.isEmail && vm.notification.email === "") {
        showAlert("Error","e-mail address on file is blank. Please enter an altenative e-mail, or tap don't send.");
      } else {
        if (vm.notification.dontSend) {
          vm.confirmationEmail = "No email will be sent";
        } else if (vm.notification.isAlternativeEmail) {
          vm.confirmationEmail = vm.notification.alternativeEmail;
        } else {
          vm.confirmationEmail = vm.notification.email;
        }
        gotoStep(nextStepIfValid);
      }
    }

    function resizeCanvas(canvas) {
      // N.B. resizing signature canvas will clear the signature data
      var ratio =  Math.max($window.devicePixelRatio || 1, 1);
      canvas.width = canvas.offsetWidth * ratio;
      canvas.height = canvas.offsetHeight * ratio;
      canvas.getContext('2d').scale(ratio, ratio);
    }

    function clearCanvas() {
      signaturePad.clear();
    }

    function displayHospitalSelection(step) {
      // Set initial hospital tab
      vm.hospitalTab = "hospitalrecent";
      // Display hospital selection
      gotoStep(step);
    }

    function displayHospitalDetails(hospital, step) {
      // Parameter 'hospital' is either an existing hospital, or a new manually entered hospital.
      // User can edit previously selected/manually entered hospital
      if (!vm.selectedHospital) {
        // First time hospital has been selected/entered (valid hospital.id implies selected existing hospital)
        vm.selectedHospital = {};
        vm.selectedHospital.id = hospital.id ? hospital.id : null;
        vm.selectedHospital.name = hospital.name;
        vm.selectedHospital.email = hospital.id ? hospital.email : null;
        vm.selectedHospital.replaceStockNo = true;
        vm.selectedHospital.replaceStockYes = false;
        vm.selectedHospital.replaceStockComments = "";
      } else {
        vm.selectedHospital.id = hospital.id ? hospital.id : null;
        vm.selectedHospital.name = hospital.name;
        vm.selectedHospital.email = hospital.id ? hospital.email : null;
      }
      // Add hospital to recent list (as long as it's not a new hospital added by user)
      if (hospital.id) {
        RecentItemsService.addRecentItem("recentHospitals", hospital).then(function(recentItems) {
          vm.recentHospitals = recentItems;
        });
      }
      gotoStep(step);
    }

    function displaySurgeonSelection(step) {
      // Set initial surgeon tab
      vm.surgeonTab = "surgeonrecent";
      // Check whether use has selected a hospital from the Recent/All tab...or added a new one
      if (vm.selectedHospital.id) {
        vm.surgeons = [];
        vm.recentSurgeons = [];
        // Filter all surgeons by the selected hospital.
        // Filter the surgeons on 'All' tab
        for (var a = 0; a < vm.allSurgeons.length; a++) {
          if (vm.allSurgeons[a].hospitalId == vm.selectedHospital.id) {
            vm.surgeons.push(vm.allSurgeons[a]);
          }
        }
        // Filter surgeons in the 'Recent' tab
        for (var r = 0; r < vm.allRecentSurgeons.length; r++) {
          if (vm.allRecentSurgeons[r].hospitalId == vm.selectedHospital.id) {
            vm.recentSurgeons.push(vm.allRecentSurgeons[r]);
          }
        }
      } else {
        // User added a new hospital
        vm.surgeons = vm.allSurgeons;
        vm.recentSurgeons = vm.allRecentSurgeons;
      }
      // Display surgeon selection
      gotoStep(step);
    }

    function displaySurgeonDetails(surgeon, step) {
      vm.selectedSurgeon = {};
      vm.selectedSurgeon.id = surgeon.id ? surgeon.id : null;
      vm.selectedSurgeon.name = surgeon.name;
      vm.selectedSurgeon.hospitalId = surgeon.hospitalId;
      if (vm.isFirstTimeThru) {
        vm.procedureDate = vm.today;
        vm.procedureType = "";
        vm.procedureComments = "";
      }
      // Add surgeon to recent list (as long as it's not a new surgeon added by user)
      if (surgeon.id) {
        RecentItemsService.addRecentItem("recentSurgeons", surgeon).then(function(recentItems) {
          vm.allRecentSurgeons = recentItems;
        });
      }
      gotoStep(step);
    }

    function displayHospitalTab(tab) {
      vm.hospitalTab = tab;
    }

    function displaySurgeonTab(tab) {
      vm.surgeonTab = tab;
    }

    function clearHospitalSearch() {
      vm.hospitalSearch = "";
    }

    function clearSurgeonSearch() {
      vm.surgeonSearch = "";
    }

    function editProduct(startEditAtStep) {
      gotoStep(startEditAtStep);
    }

    function removeProduct(index) {
      console.log("bio removeProduct index",index,vm.selectedProducts);
      var confirmPopup = $ionicPopup.confirm({
        title: 'Remove Product',
        template: 'Are you sure you want to remove product?',
        cssClass: 'bio-popup',
        cancelText: '&nbsp;&nbsp;&nbsp;No',
        cancelType: 'button-dark ion-close-round',
        okText: '&nbsp;&nbsp;&nbsp;Yes',
        okType: 'button-positive ion-checkmark-round'
      });
      confirmPopup.then(function(res) {
        if (res) {
          vm.selectedProducts.splice(index, 1);
        }
      });
    }

    function scanBarcode() {
      // Check whether we're running on device or pc.
      if (cordova && cordova.plugins && cordova.plugins.barcodeScanner) {
        // Give Ionic/Angular a chance to catch up before going to camera for scan
        scannerTimeout = $timeout(function() {
          $cordovaBarcodeScanner.scan().then(function(imageData) {
            // If user cancels the scan they're taken back to the order form start
            if (!imageData.cancelled) {
              processScannedProduct(imageData);
            }
          }, function(err) {
            console.error(err);
          });
        },0);
      } else {
        // For local testing, use a fixed product code
        var imageData = {"text" : "0150601557110348171810311010/15-R123/456", "format" : "CODE_128"};
        processScannedProduct(imageData);
      }
    }

    function cancelOrder(){
      var confirmPopup = $ionicPopup.confirm({
        title: 'Cancel',
        template: 'Are you sure?',
        cssClass: 'bio-popup',
        cancelText: '&nbsp;&nbsp;&nbsp;No',
        cancelType: 'button-dark ion-close-round',
        okText: '&nbsp;&nbsp;&nbsp;Yes',
        okType: 'button-positive ion-checkmark-round'
      });
      confirmPopup.then(function(res) {
        if (res) {
          exitOrderForm();
        }
      });
    }

    function submitOrder(){
      if (vm.selectedProducts.length === 0) {
        showAlert("Error","Please add a product before submitting.");
        return;
      }
      if (signaturePad.isEmpty()) {
        confirmNoSignature();
      } else {
        saveOrder();
      }
    }

    function confirmNoSignature(){
      var confirmPopup = $ionicPopup.confirm({
        title: 'No signature',
        template: 'Add signature?',
        cssClass: 'bio-popup',
        cancelText: '&nbsp;&nbsp;&nbsp;No',
        cancelType: 'button-dark ion-close-round',
        okText: '&nbsp;&nbsp;&nbsp;Yes',
        okType: 'button-positive ion-checkmark-round'
      });
      confirmPopup.then(function(res) {
        if (!res) {
          saveOrder();
        }
      });
    }

    function saveOrder() {
      // Save Order Form (possibly new hospital, possibly new surgeon) and Order Form Items (products)
      $ionicLoading.show({
        duration: 5000,
        template: 'Saving Order form...',
        animation: 'fade-in',
        showBackdrop: true
      });
      // Save the Order Form
      OrderFormService.insertOrderForm(buildOrderFormRecord()).then(function(resObject) {
        // Save Order Form Items (products)
        return OrderFormService.insertOrderFormItems(buidOrderFormItemRecords(resObject.records[0].Id));
      }).then(function(resObject){
        $ionicLoading.hide();
        // Check connectivity, if online then sync, otherwise display message
        if (NetworkService.getNetworkStatus() === "online") {
          // Ensure sync will run
          SyncService.setSyncLock("false");
          // Sync in background
          SyncService.syncTables(['DOF__ap', 'DOF_Item__ap']);
          // Exit
          submitSuccessful = true;
          exitOrderForm();
        } else {
          // Offline...
          $rootScope.$emit('updateOutboxCount');
          // Set a local notification
          LocalNotificationService.setLocalNotification();
          // Display 'offline' message
          alertOffline();
        }
      }).catch(function(e){
        logger.error('saveOrder ' + JSON.stringify(e) + " " + JSON.stringify(orderForm));
        $ionicLoading.hide();
        // if (typeof(e.status) != "undefined" && e.status == 101107) {
        //   $scope.dataNoLongerAvailable("store visit");
        // } else {
        //   var alertPopup = $ionicPopup.alert({
        //     title: 'Save failed',
        //     template: '<p>Sorry, something went wrong.</p><p class="error_details">Error: ' + e.status + ' - ' + e.mc_add_status + '</p>'
        //   });
        // }
      });
    }

    function buildOrderFormRecord() {
      var orderForm = {};
      orderForm.Name = "TMP-" + new Date().valueOf();
      orderForm.DOF_Item_Count__c = vm.selectedProducts.length;
      if (vm.selectedHospital.id) {
        orderForm.Hospital__c = vm.selectedHospital.id;
      } else {
        orderForm.Hospital_Name__c = vm.newHospital.name;
        orderForm.Hospital_Street__c = vm.newHospital.address;
      }
      if (vm.selectedHospital.poNumber) {
        orderForm.PO_Number__c = vm.selectedHospital.poNumber;
      }
      if (vm.selectedHospital.replaceStockNo) {
        orderForm.Stock_Instructions__c = "Don't replace stock";
      } else {
        orderForm.Stock_Instructions__c = "Replace stock to";
        orderForm.Replace_Stock_Details__c = vm.selectedHospital.replaceStockComments;
      }
      if (vm.selectedSurgeon.id) {
        orderForm.Surgeon__c = vm.selectedSurgeon.id;
      } else {
        orderForm.Surgeon_First_Name__c = vm.newSurgeon.firstName;
        orderForm.Surgeon_Last_Name__c = vm.newSurgeon.lastName;
      }
      orderForm.Procedure_Date__c = vm.procedureDate;
      orderForm.Type_of_Procedure__c = vm.procedureType;
      if (vm.procedureComments !== "") {
        orderForm.Procedure_Comments__c = vm.procedureComments;
      }
      if (vm.hospitalRep.firstName !== "") {
        orderForm.First_Name__c = vm.hospitalRep.firstName;
        orderForm.Last_Name__c = vm.hospitalRep.lastName;
      }
      if (vm.notification.isEmail) {
        orderForm.Send_Confirmation__c = "Send to address on file";
      } else if (vm.notification.dontSend) {
        orderForm.Send_Confirmation__c = "Do not send";
      } else {
        orderForm.Send_Confirmation__c = "Send to alternative address";
        orderForm.Alternative_Email__c = vm.notification.alternativeEmail;
      }
      if (!signaturePad.isEmpty()) {
        orderForm.Signature_Capture__c = signaturePad.toDataURL();
      }
      orderForm.Date_Entered__c = new Date();
      return orderForm;
    }

    function buidOrderFormItemRecords(orderFormId) {
      var orderFormItems = [];
      for (var i = 0, len = vm.selectedProducts.length; i < len; i++) {
        // console.log("bio buidOrderFormItemRecords vm.selectedProducts",vm.selectedProducts[i]);
        var record = {};
        record.Name = "TMP-" + new Date().valueOf();
        record.DOF__c = orderFormId;
        if (vm.selectedProducts[i].name) {
          // This is a scanned product
          record.Product__c = vm.selectedProducts[i].id;
          record.Lot_Number__c = vm.selectedProducts[i].lotNumber;
          record.Entered_Price__c = parseFloat(vm.selectedProducts[i].price);
          if (vm.selectedProducts[i].isCharge) {
            record.Price_Entered__c = "Price Entered";
          } else {
            record.Price_Entered__c = "No Charge";
          }
          record.Expiry_Date__c = vm.selectedProducts[i].expiryDate;
        } else {
          // This is a manually entered product
          record.Lot_Number__c = vm.selectedProducts[i].lotNumber;
          record.Entered_Price__c = parseFloat(vm.selectedProducts[i].price);
          if (vm.selectedProducts[i].isCharge) {
            record.Price_Entered__c = "Price Entered";
          } else {
            record.Price_Entered__c = "No Charge";
          }
        }
        orderFormItems.push(record);
      }
      return orderFormItems;
    }

    function exitOrderForm() {
      $rootScope.$emit('disableSideMenu', {showSideMenu : true});
      SyncService.setSyncLock("false");
      if (submitSuccessful) {
        alertSuccess();
      } else {
        $state.go("app.home");
      }
    }

    function alertSuccess(){
      var alertPopup = $ionicPopup.alert({
        title: 'Order form',
        template: 'Submission successful',
        cssClass: 'bio-popup'
      });
      alertPopup.then(function(res) {
        if (res) {
          $state.go("app.home");
        }
      });
    }

    function alertOffline(){
      var alertPopup = $ionicPopup.alert({
        title: 'You are currently offline',
        template: 'Synchronisation will take place when you are next online',
        cssClass: 'bio-popup'
      });
      alertPopup.then(function(res) {
        if (res) {
          exitOrderForm();
        }
      });
    }

    function processScannedProduct(imageData) {
      // console.log("bio imageData",imageData.text,imageData);
      if (vm.allProducts.length === 0) {
        $ionicLoading.show({
          duration: 5000,
          template: 'Loading products...',
          animation: 'fade-in',
          showBackdrop: true
        });
        OrderFormService.getProducts().then(function(records) {
          matchProduct(imageData);
          $ionicLoading.hide();
        });
      } else {
        matchProduct(imageData);
      }
    }

    function matchProduct(imageData) {
      logger.log("scanned code and format: >" + imageData.text + "< >" + imageData.format + "<");
      // Check the image data is the correct format
      if (imageData.format == "CODE_128" || imageData.format == "QR_CODE" || imageData.format == "DATA_MATRIX") {
        // Product code starts at different places for different formats - these formatts have
        // funny chars at front.
        var data = (imageData.format == "QR_CODE" || imageData.format == "DATA_MATRIX") ? imageData.text.substring(1) : imageData.text;
        var scannedProductGTIN = data.substring(2,16);
        logger.log("extracted GTIN: >" + scannedProductGTIN + "<");
        var matchedProduct = null;
        // console.log("bio  scannedProductGTIN",scannedProductGTIN);
        for (var i = 0; i < vm.allProducts.length; i++) {
          if (vm.allProducts[i].GTIN__c == scannedProductGTIN) {
            matchedProduct = vm.allProducts[i];
          }
        }
        if (matchedProduct) {
          vm.product = {};
          vm.product.id = matchedProduct.Id;
          vm.product.name = matchedProduct.Name__c + " " + matchedProduct.Size__c;
          vm.product.expiryDate = new Date("20" + data.substring(18,20) + '-' + data.substring(20,22) + '-' + data.substring(22,24));
          vm.product.lotNumber = data.substring(26);
          vm.product.price = null;
          vm.product.isCharge = true;
          vm.product.isNoCharge = false;
          logger.log("product: " + JSON.stringify(vm.product));
          // console.log("bio vm.product",vm.product);
          gotoStep("scangood");
        } else {
          gotoStep("scanbad");
        }
      } else {
        gotoStep("scanbad");
      }
    }

    function chargeCheckboxChange(inputType, checkbox) {
      if (inputType == "manual") {
        vm.manualInput[checkbox] = !vm.manualInput[checkbox];
      } else {
        vm.product[checkbox] = !vm.product[checkbox];
      }
    }

    function stockCheckboxChange(checkbox) {
      if (checkbox == "replaceStockYes") {
        vm.selectedHospital.replaceStockYes = false;
        vm.selectedHospital.replaceStockNo = true;
      } else {
        vm.selectedHospital.replaceStockYes = true;
        vm.selectedHospital.replaceStockNo = false;
      }
    }

    function notificationEmailCheckboxChange(checkbox) {
      vm.notification.isEmail = false;
      vm.notification.isAlternativeEmail = false;
      vm.notification.dontSend = false;
      if (checkbox == "isEmail") {
        vm.notification.isEmail = true;
      } else if (checkbox == "isAlternativeEmail") {
        vm.notification.isAlternativeEmail = true;
      } else {
        vm.notification.dontSend = true;
      }
    }

    function checkRecentHospitalsAreStillValid() {
      var matchedRecentItems = [];
      for (var i = 0; i < vm.recentHospitals.length; i++) {
        for (var j = 0; j < vm.hospitals.length; j++) {
          if (vm.hospitals[j].id == vm.recentHospitals[i].id) {
            matchedRecentItems.push(vm.recentHospitals[i]);
            break;
          }
        }
      }
      // console.log("bio checkRecentHospitalsAreStillValid",matchedRecentItems.length,vm.recentHospitals.length);
      if (matchedRecentItems.length !== vm.recentHospitals.length) {
        vm.recentHospitals = matchedRecentItems;
        RecentItemsService.setRecentItems("recentHospitals",matchedRecentItems);
      }
    }

    function checkRecentSurgeonsAreStillValid() {
      var matchedRecentItems = [];
      for (var i = 0; i < vm.allRecentSurgeons.length; i++) {
        for (var j = 0; j < vm.allSurgeons.length; j++) {
          if (vm.allSurgeons[j].id == vm.allRecentSurgeons[i].id) {
            matchedRecentItems.push(vm.allRecentSurgeons[i]);
            break;
          }
        }
      }
      // console.log("bio checkRecentSurgeonsAreStillValid",matchedRecentItems.length,vm.allRecentSurgeons.length);
      if (matchedRecentItems.length !== vm.allRecentSurgeons.length) {
        vm.allRecentSurgeons = matchedRecentItems;
        RecentItemsService.setRecentItems("recentSurgeons",matchedRecentItems);
      }
    }

    function showAlert(title, template){
      var alertPopup = $ionicPopup.alert({
        title: title,
        template: template,
        cssClass: 'bio-popup'
      });
      alertPopup.then(function(res) {
        if (res) {
        }
      });
    }

    function windowResizeHandler() {
      var canvas = angular.element(document.getElementById("signatureCanvas"))[0];
      // console.log("bio OrderFormCtrl windowResizeHandler",canvas);
      if (canvas && signaturePad && !signaturePad.isEmpty()) {
        signatureDataURL = signaturePad.toDataURL();
        $timeout(function(){
          resizeCanvas(canvas);
          if (!signaturePad.isEmpty()) {
            signaturePad.fromDataURL(signatureDataURL);
          }
          canvas = null;
        },500);
      }
    }

    function isValidPrice(n) {
      return /^\d*\.?\d{0,2}$/.test(n);
      // return !isNaN(parseFloat(n)) && isFinite(n);
    }

    function validateEmail(email) {
      var re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
      return re.test(email);
    }

    $scope.$on('$destroy', function() {
      logger.log("OrderFormCtrl destroy");
      // console.log("bio OrderFormCtrl destroy");
      $timeout.cancel(signaturePadTimeout);
      $timeout.cancel(scannerTimeout);
      $timeout.cancel(scrollTimeout);
      $timeout.cancel(onBeginSignatureTimeout);
      $timeout.cancel(onEndSignatureTimeout);
      // Deregister window resize event
      angular.element($window).off('resize', windowResizeHandler);
    });

  }

})();
/**
 * Outbox Controller
 *
 * @description controller for outbox page.
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('OutboxCtrl', OutboxCtrl);

  OutboxCtrl.$inject = ['$rootScope', '$scope', '$ionicLoading', '$timeout', 'logger', 'OutboxService', 'RecordTypeService', 'SyncService', 'NetworkService', 'UserService', 'OrderFormService'];

  function OutboxCtrl($rootScope, $scope, $ionicLoading, $timeout, logger, OutboxService, RecordTypeService, SyncService, NetworkService, UserService, OrderFormService)  {
    logger.log("in OutboxCtrl");
    console.log("bio in OutboxCtrl");

    var vm = this;
    var leadRecordTypeId;
    var updateOutboxCountTimeout;
    var dirtyRecordsCount;
    var recordsProcessed = 0;

    vm.showMsg = false;
    vm.showSyncButton = false;
    vm.syncing = false;

    vm.sync = sync;

    activate();

    function activate() {
      $ionicLoading.show({
        duration: 5000,
        template: 'Loading...',
        animation: 'fade-in',
        showBackdrop: true,
        delay: 400
      });
      // Get user's currency symbol
      UserService.getUserCurrencySymbol().then(function(result) {
        vm.currencySymbol = result;
      });
      // Get record types and dirty records
      vm.orders = [];
      vm.leads = [];
      vm.requests = [];
      RecordTypeService.getRecordTypeId("Mobile_Lead","Mobile_Dynamic__c").then(function(recordTypeId) {
        leadRecordTypeId = recordTypeId;
        return OutboxService.getDirtyRecords();
      }).then(function(records) {
        dirtyRecordsCount = records.length;
        // If no dirty records then show the 'No records...' message
        if (dirtyRecordsCount === 0) {
          vm.showMsg = true;
          vm.showSyncButton = false;
          $ionicLoading.hide();
        } else {
          // Else, process records and create cards
          for (var i = 0; i < records.length; i++) {
            pushRecordToArray(records[i].Mobile_Table_Name,records[i].SOUP_Record_Id,i);
          }
        }
        updateOutboxCountTimeout = $timeout(function() {
          // Update the outbox count displayed in the side menu (populated in MenuCtrl)
          $rootScope.$emit('updateOutboxCount');
        },0);
      });
    }

    function pushRecordToArray(tableName,soupRecordId,index) {
      OutboxService.getRecordForSoupEntryId(tableName,soupRecordId).then(function(record) {
        if (record) {
          if (tableName == "DOF__ap") {
            getAdditionalDetails(record,index);
          } else {
            if (record.RecordTypeId == leadRecordTypeId) {
              vm.leads.push(record);
              $scope.$emit("checkIfAllRecordsProcessed");
            } else {
              vm.requests.push(record);
              $scope.$emit("checkIfAllRecordsProcessed");
            }
          }
          // console.log("bio OutboxCtrl pushRecordToArray vm.leads,vm.requests",vm.leads,vm.requests);
        }
      });
    }

    function getAdditionalDetails(record,index) {
      // Gets the fields generated by Salesforce formula fields: hospital, surgeon and product names
      var surgeonInHospitalRecord;
      var items;
      OrderFormService.getSurgeonInHospital(record.Surgeon__c).then(function(surgeonInHospital) {
        surgeonInHospitalRecord = surgeonInHospital;
        // Get order items
        return OrderFormService.getOrderItemsWithOrderId(record.Id);
      }).then(function(orderItems) {
        items = orderItems;
        // Get products for order items
        return OrderFormService.getProductsForOrderItems(orderItems);
      }).then(function(products) {
        // The order items might just be a lot number (after manual entry), so they won't have a product id
        var displayProducts = [];
        var productName;
        for (var j = 0; j < items.length; j++) {
          productName = null;
          if (items[j].Product__c) {
            for (var k = 0; k < products.length; k++) {
              if (items[j].Product__c == products[k].Id) {
                productName = products[k].Name__c + " " + products[k].Size__c;
                break;
              }
            }
          }
          if (!productName) {
            // Manually entered product
            displayProducts.push({"lotNumber": items[j].Lot_Number__c, "price": items[j].Entered_Price__c});
          } else {
            // Scanned product
            displayProducts.push({"productName": productName, "lotNumber": items[j].Lot_Number__c, "price": items[j].Entered_Price__c, "expiryDate": items[j].Expiry_Date__c});
          }
        }
        $scope.$apply();
        vm.orders.push({"record": record, "surgeonInHospitalRecord": surgeonInHospitalRecord, "products": displayProducts});
        $scope.$emit("checkIfAllRecordsProcessed");
        // console.log("bio OutboxCtrl pushRecordToArray vm.orders",vm.orders);
      });
    }

    function sync() {
      SyncService.syncTables(['DOF__ap', 'DOF_Item__ap', 'Mobile_Dynamic__ap']);
    }

    var deregisterHandleCheckRecordProcessed = $scope.$on('checkIfAllRecordsProcessed', function(event, args) {
      // console.log("bio deregisterHandleCheckRecordProcessed",recordsProcessed,dirtyRecordsCount);
      recordsProcessed += 1;
      if (recordsProcessed === dirtyRecordsCount) {
        // If we've processed all the dirty records then hide loading icon
        $ionicLoading.hide();
        vm.showSyncButton = true;
      }
    });

    // Process events fired from the SyncService
    var deregisterHandleSyncTables = $rootScope.$on('syncTables', function(event, args) {
      logger.log("OutboxCtrl syncTables: " + JSON.stringify(args));
      console.log("bio OutboxCtrl syncTables: " + JSON.stringify(args));
      switch (args.result.toString()) {
        default :
          if (args.result.toString().indexOf("TableComplete") >= 0) {
            var syncedTable = args.result.replace("TableComplete ","");
            if (syncedTable == "Mobile_Dynamic__ap") {
              activate();
            }
          }
      }
    });

    $scope.$on('$destroy', function() {
      logger.log("OutboxCtrl destroy");
      console.log("bio OutboxCtrl destroy");
      deregisterHandleSyncTables();
      deregisterHandleCheckRecordProcessed();
      $timeout.cancel(updateOutboxCountTimeout);
    });

  }

})();

/**
 * Request Controller
 *
 * @description controller for unsolicited request functionality
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('RequestCtrl', RequestCtrl);

  RequestCtrl.$inject = ['$rootScope', '$scope', '$ionicPopup', '$state', '$ionicLoading', '$timeout', '$ionicScrollDelegate', 'logger', 'SyncService', 'NetworkService', 'RecordTypeService', 'MobileDynamicService', 'LocalNotificationService'];

  function RequestCtrl($rootScope, $scope, $ionicPopup, $state, $ionicLoading, $timeout, $ionicScrollDelegate, logger, SyncService, NetworkService, RecordTypeService, MobileDynamicService, LocalNotificationService) {
    logger.log("in RequestCtrl");
    console.log("bio in RequestCtrl");

    var vm = this;
    var recordTypeId;
    // "responseDate" below = 2 weeks forward
    var initialRequest = {
      "info": "",
      "product": "STIMULAN",
      "requestorName": "",
      "requestorEmail": "",
      "requestorInstitution": "",
      "responseDate": new Date(new Date().getTime() + (1000 * 60 * 60 * 24 * 14))
    };
    var scrollTimeout;
    var submitSuccessful = false;

    vm.showCancel = false;
    vm.today = new Date();
    vm.requestTypeTitle = "";
    vm.request = {};

    vm.gotoStep = gotoStep;
    vm.inputValidation = inputValidation;
    vm.submitRequest = submitRequest;
    vm.cancelRequest = cancelRequest;

    activate();

    function activate() {
      angular.copy(initialRequest,vm.request);
      vm.showBackButton = true;
      RecordTypeService.getRecordTypeId("Unsolicited_Request","Mobile_Dynamic__c").then(function(id){
        recordTypeId = id;
      });
    }

    function gotoStep(step) {
      if (step == "standardstart" || step == "urgentstart") {
        vm.showCancel = true;
        $rootScope.$emit('disableSideMenu', {showSideMenu : false});
        SyncService.setSyncLock("true");
        if (step == "standardstart") {
          vm.requestTypeTitle = "- standard";
        } else {
          vm.requestTypeTitle = "- urgent";
        }
      }
      if (step == "standardinfo" || step == "urgentinfo") {
        if (vm.request.info.trim() !== "") {
          vm.showBackButton = false;
        }
      }
      if (step == "default") {
        // Going back to the main menu
        vm.requestTypeTitle = "";
        vm.showCancel = false;
        activate();
        $rootScope.$emit('disableSideMenu', {showSideMenu : true});
        SyncService.setSyncLock("false");
      }
      vm.step = step;
      scrollTimeout = $timeout(function(){
        $ionicScrollDelegate.scrollTop();
      },50);
    }

    function inputValidation(nextStepIfValid) {
      if (nextStepIfValid === "standardproduct" || nextStepIfValid === "urgentproduct") {
        if (vm.request.info.trim() === "") {
          showAlert("Error","Please enter information.");
          return;
        }
      }
      if (nextStepIfValid === "standarddeadline") {
        if (vm.request.requestorName.trim() === "" || vm.request.requestorInstitution.trim() === "") {
          showAlert("Error","Please enter the requestor's details.");
          return;
        }
        if (!vm.request.requestorEmail || !validateEmail(vm.request.requestorEmail)) {
          showAlert("Error","Please enter a valid e-mail address.");
          return;
        }
      }
      if (nextStepIfValid === "urgentdeadline") {
        if (vm.request.requestorName.trim() === "" || vm.request.requestorInstitution.trim() === "") {
          showAlert("Error","Please enter the requestor's details.");
          return;
        }
      }
      if (nextStepIfValid === "submitstandard" || nextStepIfValid === "submiturgent") {
        if (!vm.request.responseDate) {
          showAlert("Error","Please enter a date.");
          return;
        }
        submitRequest(nextStepIfValid);
        return;
      }
      gotoStep(nextStepIfValid);
    }

    function submitRequest(requestType) {
      // Save Request (to Mobile_Dynamic__ap)
      $ionicLoading.show({
        duration: 5000,
        template: 'Saving request...',
        animation: 'fade-in',
        showBackdrop: true
      });
      MobileDynamicService.insertRecord(buildRequestRecord(requestType)).then(function(resObject) {
        $ionicLoading.hide();
        // Check connectivity, if online then sync, otherwise display message
        if (NetworkService.getNetworkStatus() === "online") {
          // Ensure sync will run
          SyncService.setSyncLock("false");
          // Sync in background
          SyncService.syncTables(['Mobile_Dynamic__ap']);
          // Exit
          submitSuccessful = true;
          exitRequest();
        } else {
          // Offline...
          $rootScope.$emit('updateOutboxCount');
          // Set a local notification
          LocalNotificationService.setLocalNotification();
          // Display 'offline' message
          alertOffline();
        }
      }).catch(function(e){
        logger.error('submitRequest ' + JSON.stringify(e) + " " + JSON.stringify(orderForm));
        $ionicLoading.hide();
        // if (typeof(e.status) != "undefined" && e.status == 101107) {
        //   $scope.dataNoLongerAvailable("store visit");
        // } else {
        //   var alertPopup = $ionicPopup.alert({
        //     title: 'Save failed',
        //     template: '<p>Sorry, something went wrong.</p><p class="error_details">Error: ' + e.status + ' - ' + e.mc_add_status + '</p>'
        //   });
        // }
      });
    }

    function buildRequestRecord(requestType) {
      var request = {};
      request.Name = "TMP-" + new Date().valueOf();
      if (requestType == "submitstandard") {
        request.Request_Type__c = "Standard";
      } else {
        request.Request_Type__c = "Urgent";
      }
      request.Requested_Information__c = vm.request.info;
      request.Product__c = vm.request.product;
      request.Requestors_Name__c = vm.request.requestorName;
      if (!vm.request.requestorEmail) {
        request.Email__c = "";
      } else {
        request.Email__c = vm.request.requestorEmail;
      }
      request.Hospital_Institution__c = vm.request.requestorInstitution;
      request.Request_Target_Response_Date__c = vm.request.responseDate;
      if (recordTypeId !== "") {
        request.RecordTypeId = recordTypeId;
      }
      request.Date_Entered__c = new Date();
      return request;
    }

    function cancelRequest(){
      var confirmPopup = $ionicPopup.confirm({
        title: 'Cancel',
        template: 'Are you sure?',
        cssClass: 'bio-popup',
        cancelText: '&nbsp;&nbsp;&nbsp;No',
        cancelType: 'button-dark ion-close-round',
        okText: '&nbsp;&nbsp;&nbsp;Yes',
        okType: 'button-positive ion-checkmark-round'
      });
      confirmPopup.then(function(res) {
        if (res) {
          exitRequest();
        }
      });
    }

    function exitRequest() {
      $rootScope.$emit('disableSideMenu', {showSideMenu : true});
      SyncService.setSyncLock("false");
      if (submitSuccessful) {
        alertSuccess();
      } else {
        $state.go("app.home");
      }
    }

    function alertSuccess(){
      var alertPopup = $ionicPopup.alert({
        title: 'Unsolicited request',
        template: 'Submission successful',
        cssClass: 'bio-popup'
      });
      alertPopup.then(function(res) {
        if (res) {
          $state.go("app.home");
        }
      });
    }

    function alertOffline(){
      var alertPopup = $ionicPopup.alert({
        title: 'You are currently offline',
        template: 'Synchronisation will take place when you are next online',
        cssClass: 'bio-popup'
      });
      alertPopup.then(function(res) {
        if (res) {
          exitRequest();
        }
      });
    }

    function showAlert(title, template){
      var alertPopup = $ionicPopup.alert({
        title: title,
        template: template,
        cssClass: 'bio-popup'
      });
      alertPopup.then(function(res) {
        if (res) {
        }
      });
    }

    function validateEmail(email) {
      var re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
      return re.test(email);
    }

    $scope.$on('$destroy', function() {
      logger.log("RequestCtrl destroy");
      console.log("bio RequestCtrl destroy");
      $timeout.cancel(scrollTimeout);
    });

  }

})();
/**
 * Request History Controller
 *
 * @description controller for unsolicited request history
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('RequestHistoryCtrl', RequestHistoryCtrl);

  RequestHistoryCtrl.$inject = ['$rootScope', '$scope', '$window', '$ionicLoading', '$ionicModal', '$state', 'logger', 'RecordTypeService', 'MobileDynamicService'];

  function RequestHistoryCtrl($rootScope, $scope, $window, $ionicLoading, $ionicModal, $state, logger, RecordTypeService, MobileDynamicService) {
    logger.log("in RequestHistoryCtrl");
    console.log("bio in RequestHistoryCtrl");

    var vm = this;

    vm.showModal = showModal;
    vm.closeModal = closeModal;
    vm.goHome = goHome;

    activate();

    function activate() {
      $ionicLoading.show({
        duration: 5000,
        template: 'Loading...',
        animation: 'fade-in',
        showBackdrop: true,
      });
      vm.requests = [];
      RecordTypeService.getRecordTypeId("Unsolicited_Request","Mobile_Dynamic__c").then(function(recordTypeId) {
        return MobileDynamicService.getRecords(recordTypeId);
      }).then(function(records) {
        for (var i = 0; i < records.length; i++) {
          // Check whether the record has been synced
          if (records[i].Id.indexOf("PROXY") == -1) {
            // Yes, it's been synced
            vm.requests.push(records[i]);
          }
        }
        console.log("bio vm.requests",vm.requests);
        $ionicLoading.hide();
      });
    }

    function showModal(record) {
      $ionicModal.fromTemplateUrl($window.RESOURCE_ROOT + "templates/requestDetail.html", {
        scope: $scope,
        animation: 'slide-in-up'
      }).then(function(modal) {
        vm.modal = modal;
        vm.modal.request = record;
        console.log("bio showModal vm.modal.request",vm.modal.request);
        vm.modal.show();
      });
    }

    function closeModal() {
      console.log("bio closeModal");
      if (vm.modal) {
        vm.modal.hide();
        vm.modal.remove();
        delete vm.modal;
      }
    }

    function goHome() {
      $state.go("app.home");
    }

    // Handle events fired from the SyncService
    var deregisterHandleSyncTables = $rootScope.$on('syncTables', function(event, args) {
      logger.log("RequestHistoryCtrl syncTables: " + JSON.stringify(args));
      console.log("bio RequestHistoryCtrl syncTables: " + JSON.stringify(args));
      if (args.result.toString().indexOf("TableComplete") >= 0) {
        var syncedTable = args.result.replace("TableComplete ","");
        if (syncedTable == "Mobile_Dynamic__ap") {
          activate();
        }
      }
    });

    $scope.$on('$destroy', function() {
      logger.log("RequestHistoryCtrl destroy");
      console.log("bio RequestHistoryCtrl destroy");
      deregisterHandleSyncTables();
      if (vm.modal) {
        vm.modal.remove();
        delete vm.modal;
      }
    });

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

  SettingsCtrl.$inject = ['$scope', '$rootScope', '$ionicPopup', '$ionicLoading', '$location', '$state', 'devUtils', 'vsnUtils', 'DevService', 'logger'];

  function SettingsCtrl($scope, $rootScope, $ionicPopup, $ionicLoading, $location, $state, devUtils, vsnUtils, DevService, logger) {


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
	      $location.path('app/settings/devtools');
	      $rootScope.adminLoggedIn = Date.now();
	      // $scope.$apply();
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
	                $location.path('app/settings/devtools');
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


    $scope.goBack = function() {
      $rootScope.$emit('showSettingsMenu');
    };

    $scope.goHome = function() {
      $state.go("app.home");
    };

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

  TestingCtrl.$inject = ['$scope', '$cordovaLocalNotification', 'AppRunStatusService', 'logger', 'LocalNotificationService'];

  function TestingCtrl($scope, $cordovaLocalNotification, AppRunStatusService, logger, LocalNotificationService) {

	  $scope.resumeEvent = function() {
	    console.debug("resumeEvent");
	    AppRunStatusService.statusEvent('resume');
	  };

    $scope.localNotification = function(id) {
      var alarmTime = new Date();
      alarmTime.setSeconds(alarmTime.getSeconds() + 15);
      var args = {
        id: 100100,
        at: alarmTime,
        text: "Unsynced records",
        sound: null};
      if (device.platform == "Android") {
         args.ongoing = true;
         args.smallIcon = "res://icon";
      }
      $cordovaLocalNotification.schedule(args).then(function (result) {
        console.log("localNotification result = " + result);
        logger.log("localNotification result = " + result);
      });
    };

    $scope.localNotificationTrigger = function(id) {
      LocalNotificationService.handleLocalNotification(id, 'foreground');
    };

    $scope.toggleNotificationState = function() {
      var notificationState = LocalNotificationService.getLocalNotificationState();
      if (notificationState == "enabled") {
        LocalNotificationService.setLocalNotificationState("disabled");
        $scope.notificationButtonText = "Enable";
      } else {
        LocalNotificationService.setLocalNotificationState("enabled");
        $scope.notificationButtonText = "Disable";
      }
    };

    var notificationState = LocalNotificationService.getLocalNotificationState();
    if (notificationState == "enabled") {
      $scope.notificationButtonText = "Disable";
    } else {
      $scope.notificationButtonText = "Enable";
    }

  }

})();
/**
 * Tutorial Controller
 *
 * @description controller for app tutial page
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('TutorialCtrl', TutorialCtrl);

  TutorialCtrl.$inject = ['$rootScope', '$scope', '$state', '$window', '$timeout', 'logger', 'UserService'];

  function TutorialCtrl($rootScope, $scope, $state, $window, $timeout, logger, UserService) {
    logger.log("in TutorialCtrl");
    console.log("bio in TutorialCtrl");

    var vm = this;
    var showButtonsTimeout;
    var showSettingsMenuTimeout;
    var updateButtonTextOnResizeTimeout;

    vm.startAppFromImageTap = startAppFromImageTap;

    vm.slides = [];
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial1.jpg", "heading": "Welcome to the Biocomposites' <span class='bio-line-break-on-small-device'>Distributor Hub.</span>"});
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial2.jpg", "heading": "Providing easy, offline access to <span class='bio-line-break-on-small-device'>the tools you need.</span>"});
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial3.jpg", "heading": "Applications and cases at your <span class='bio-line-break-on-small-device'>fingertips.</span>"});
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial4.jpg", "heading": "On-label answers to your <span class='bio-line-break-on-small-device'>surgeons' questions.</span>"});
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial5.jpg", "heading": "e-learning modules to grow your <span class='bio-line-break-on-small-device'>knowledge.</span>"});
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial6.jpg", "heading": "…and regular news updates to <span class='bio-line-break-on-small-device'>keep you informed.</span>"});
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial7.jpg", "heading": "Let's get started."});

    // Workaround for small devices truncating title (when header button's text is long):
    // Hide the buttons initially - this allows the title to be rendered full width on small devices.
    // Show the buttons using a timeout after page is entered and angular has done it's stuff.
    vm.showButtons = false;

    vm.leftButtonClick = leftButtonClick;
    vm.rightButtonClick = rightButtonClick;

    var deregisterIonicViewEnter = $scope.$on('$ionicView.afterEnter', function(scopes, states) {
      showButtonsTimeout = $timeout(function() {
        setButtonText();
        vm.showButtons = true;
      },0);
      // register window resize event
      angular.element($window).on('resize', windowResizeHandler);
    });

    var deregisterIonicViewLeave = $scope.$on('$ionicView.leave', function(scopes, states) {
      // deregister window resize event
      angular.element($window).off('resize', windowResizeHandler);
    });

    function leftButtonClick() {
      if (vm.slider.activeIndex === 0) {
        startApp();
      } else {
        previous();
      }
    }

    function rightButtonClick() {
      if (vm.slider.activeIndex === vm.maxSlideIndex) {
        startApp();
      } else {
        next();
      }
    }

    function startApp() {
      // Check whether user has already done the tutorial (on initial install of app)
      var tutorialDone = localStorage.getItem('tutorial');
      if (tutorialDone === null) {
        // This will stop the tutorial showing in future app starts - user can still view tutorial from Setting sub menu option
        localStorage.setItem("tutorial", "done");
        // Go to home page
        $state.go("app.home");
      } else {
        // If we're showing the tutorial from the Settings sub menu (rather than initial install) then re-show Settings sub menu
        $state.go("app.home");
        showSettingsMenuTimeout = $timeout(function() {
          $rootScope.$emit('showSettingsMenu');
        },0);
      }
    }

    function startAppFromImageTap(index) {
      // Only start the app from here if user has tapped on the last slide image with 'start'
      if (index == vm.maxSlideIndex) {
        startApp();
      }
    }

    function next() {
      vm.slider.slideNext(false);
      setButtonText();
    }

    function previous() {
      vm.slider.slidePrev(false);
      setButtonText();
    }

    function setButtonText() {
      if (vm.slider.activeIndex === 0) {
        vm.leftButtonText = "Skip welcome";
      } else {
        vm.leftButtonText = "<";
      }
      if (vm.slider.activeIndex === vm.maxSlideIndex) {
        vm.rightButtonText = "Start App";
      } else {
        vm.rightButtonText = ">";
      }
    }

    $scope.$watch('vm.slider', function(slider) {
      // console.log("bio $watch slider",slider);
      if (slider) {
        setMaxSlideIndex(slider.params.slidesPerView);
        // Add events so we can change the button text to match where user has swiped to
        vm.slider.on('slideNextStart', function () {
          setButtonText();
          $scope.$apply();
        });
        vm.slider.on('slidePrevStart', function () {
          setButtonText();
          $scope.$apply();
        });
      }
    });

    function setMaxSlideIndex(slidesPerView) {
      if ((vm.slides.length % slidesPerView) === 0) {
        vm.maxSlideIndex = (vm.slides.length / slidesPerView) - 1;
      } else {
        vm.maxSlideIndex = Math.ceil(vm.slides.length / slidesPerView) - 1;
      }
    }

    function windowResizeHandler() {
      updateButtonTextOnResizeTimeout = $timeout(function() {
        // We're changing the 'slidesPerView' for different size devices (using the slider options).
        // We need to change max index so button text is derived correctly
        setMaxSlideIndex(vm.slider.params.slidesPerView);
        setButtonText();
      },0);
    }

    // Handle events fired from the SyncService
    var deregisterHandleSyncTables = $rootScope.$on('syncTables', function(event, args) {
      logger.log("TutorialCtrl syncTables: " + JSON.stringify(args));
      console.log("bio TutorialCtrl syncTables: " + JSON.stringify(args));
      if (args.result.toString() == "InitialLoadComplete") {
        // Save the fact that we've run the initial data load for the app install
        UserService.setProcessDone("initialDataLoaded");
        // If the user stays in the tutorial until the initial data load has finished then
        // load the user's first name into local storage...this should then load faster on home page load.
        // The user's firstname comes from the 'appSoup' table which is one of the first app tables to get loaded
        UserService.setUserFirstName();
      }
    });

    $scope.$on('$destroy', function() {
      logger.log("TutorialCtrl destroy");
      console.log("bio TutorialCtrl destroy");
      deregisterHandleSyncTables();
      deregisterIonicViewEnter();
      deregisterIonicViewLeave();
      $timeout.cancel(showButtonsTimeout);
      $timeout.cancel(updateButtonTextOnResizeTimeout);
      $timeout.cancel(showSettingsMenuTimeout);
      vm.slider.off('slideNextStart');
      vm.slider.off('slidePrevStart');
    });

  }

})();