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

  ContentItemCtrl.$inject = ['$rootScope', '$scope', '$stateParams', '$ionicLoading', '$window', '$timeout', '$ionicModal', '$location', '$ionicScrollDelegate', '$ionicPopup','$ionicHistory', '$state', 'logger', 'ContentItemService', 'NetworkService', 'AnalyticsService'];

  function ContentItemCtrl($rootScope, $scope, $stateParams, $ionicLoading, $window, $timeout, $ionicModal, $location, $ionicScrollDelegate, $ionicPopup, $ionicHistory, $state, logger, ContentItemService, NetworkService, AnalyticsService) {
    // logger.log("in ContentItemCtrl");
    // console.log("bio in ContentItemCtrl<<<<<<<<<<<");

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
      // Increment analytics
      AnalyticsService.incrementKey(vm.menuItem).then(function(result) {
      }).catch(function(e){
        logger.error('ContentItemCtrl AnalyticsService.incrementKey error: ' + JSON.stringify(e));
      });
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
            vm.menuItem === "bio" ||
            vm.menuItem === "contact-us") {
          $rootScope.$emit('showSideMenu');
        } else if (vm.menuItem === "terms") {
          $rootScope.$emit('showSettingsMenu');
        } else if (vm.menuItem.includes("genex-")) {
          $rootScope.$emit('showGenexMenu');
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
      // logger.log("ContentItemCtrl syncTables: " + JSON.stringify(args));
      // console.log("bio ContentItemCtrl syncTables: " + JSON.stringify(args));
      if (args.result.toString().indexOf("TableComplete") >= 0) {
        var syncedTable = args.result.replace("TableComplete ","");
        if (syncedTable == "Content_Item__ap") {
          activate(true);
        }
      }
    });

    // Note. $destroy doesn't always fire immediately we leave page (for cached view)
    $scope.$on('$destroy', function() {
      // logger.log("ContentItemCtrl $destroy");
      // console.log("bio ContentItemCtrl $destroy<<<<<<<<<<<");
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
    });

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
 * Diagnostics Controller
 *
 * @description controller for diagnostics functions in the settings pages
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('DiagnosticsCtrl', DiagnosticsCtrl);

  DiagnosticsCtrl.$inject = ['$scope', 'AppRunStatusService', 'DiagnosticService', 'logger', 'NetworkService'];

  function DiagnosticsCtrl($scope, AppRunStatusService, DiagnosticService, logger, NetworkService) {
    var logTag = 'app.DiagnosticsCtrl';

    var vm = this;
    vm.testHeartbeat = testHeartbeat;

    activate();

    function activate(){
      DiagnosticService.getCachedFlag().then(function(cachedFlag){
        vm.cachedFlag = cachedFlag;
      }).catch(function(e){
        logger.error(e);
      });

      vm.networkStatus = NetworkService.getNetworkStatus();

      DiagnosticService.getRecentLogs(5).then(function(latestLogs){
        vm.latestMobileLogs = latestLogs;
      }).catch(function(e){
        logger.error(e);
      });

    }

    function testHeartbeat() {
      console.debug("testHeartbeat");
      vm.testTitle = "Heartbeat in progress...";
      DiagnosticService.testVfRemote().then(function(res){
        vm.testTitle = "Heartbeat result";
        vm.testResults = {
          result: JSON.stringify(res.result),
          event: JSON.stringify(res.event)
        };
        $scope.$apply();
      }).catch(function(e){
        var err = errToObj(e);
        vm.testTitle = "Heartbeat Errored";
        vm.testResults = {
          result: "-",
          event: "-",
          error: JSON.stringify(err)
        };
        $scope.$apply();
        logger.error("testHeartbeat", err);
      });
    }

    /**
     * Convert Error type to std object, if it is one - as it does not play nice
     * with JSON.stringify.
     * @param  {error} e A JS Error.
     * @return {object}
     */
    function errToObj(e) {
      //
      var err = {};
      if (e instanceof Error) {
        Object.getOwnPropertyNames(e).forEach(function(key) {
          err[key] = e[key];
        });
      } else {
        err = e;
      }
      return err;
    }
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

  HomeCtrl.$inject = ['$rootScope', '$scope', '$ionicLoading', '$window', '$timeout', '$location', 'logger', 'UserService', 'OutboxService', 'AnalyticsService'];

  function HomeCtrl($rootScope, $scope, $ionicLoading, $window, $timeout, $location, logger, UserService, OutboxService, AnalyticsService) {
    // logger.log("in HomeCtrl");
    // console.log("bio in HomeCtrl");

    var vm = this;
    var slideInTimeout, gotoPageTimeout, refreshTimeout;

    vm.titleImage = $window.RESOURCE_ROOT + "images/Biocomposites-header-logo.SVG";
    vm.homeImage = $window.RESOURCE_ROOT + "images/home.JPG";
    vm.orderFormSVG = $window.RESOURCE_ROOT + "images/order-form-home-icon.SVG";
    vm.unsolicitedSVG = $window.RESOURCE_ROOT + "images/unsolicited-request-home-icon.SVG";
    vm.stimulanSVG = $window.RESOURCE_ROOT + "images/stimulan-home-icon.SVG";
    vm.topicSVG = $window.RESOURCE_ROOT + "images/topics-of-interest-home-icon.SVG";
    vm.elearnSVG = $window.RESOURCE_ROOT + "images/elearn-home-icon.SVG";
    vm.outboxSVG = $window.RESOURCE_ROOT + "images/outbox-home-icon.SVG";
    vm.outboxAlertGIF = $window.RESOURCE_ROOT + "images/outbox-alert.GIF";
    vm.slideInHomePage = true;
    vm.showOutboxAlert = false;

    // Exposed methods
    vm.showStimulanSideMenu = showStimulanSideMenu;
    vm.gotoPage = gotoPage;

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
            template: '<p id="app-progress-msg" class="item-icon-left"><h3>Loading Data...</h3><p>Please do not close the app until complete…</p><ion-spinner></ion-spinner></p>',
            animation: 'fade-in',
            showBackdrop: true,
            maxWidth: 600,
            duration: 0
          });
        }
      });
    }

    function showStimulanSideMenu() {
      // Fire event in menu controller
      $rootScope.$emit('showStimulanMenu');
      // Increment analytics
      AnalyticsService.incrementKey("home-stimulan").then(function(result) {
      }).catch(function(e){
        logger.error('HomeCtrl showStimulanSideMenu AnalyticsService.incrementKey error: ' + JSON.stringify(e));
      });
    }

    slideInTimeout = $timeout(function() {
      // Turn off our own home page 'slide in' animation - it makes for better user experience on app load
      vm.slideInHomePage = false;
    },1000);

    function checkOutbox() {
      OutboxService.getDirtyRecordsCount().then(function(result) {
        // console.log("bio HomeCtrl checkOutbox getDirtyRecordsCount=",result);
        if (result > 0) {
          vm.showOutboxAlert = true;
        } else {
          vm.showOutboxAlert = false;
        }
        refreshTimeout = $timeout(function() {
          $scope.$apply();
        }, 0);
      });
    }

    function gotoPage(path,key) {
      // Increment analytics
      AnalyticsService.incrementKey(key).then(function(result) {
      }).catch(function(e){
        logger.error('HomeCtrl gotoPage AnalyticsService.incrementKey error: ' + JSON.stringify(e));
      });
      // Go to page
      gotoPageTimeout = $timeout(function() {
        $location.path(path);
      },0);
    }

    var deregisterHandleCheckOutbox = $rootScope.$on('home:checkOutbox', function(event, args) {
      checkOutbox();
    });

    // Event fired when we enter view - regardless of whether it's cached
    var deregisterIonicViewEnter = $scope.$on('$ionicView.enter', function(scopes, states) {
      // Increment analytics
      AnalyticsService.incrementKey("home").then(function(result) {
      }).catch(function(e){
        logger.error('HomeCtrl deregisterIonicViewEnter AnalyticsService.incrementKey error: ' + JSON.stringify(e));
      });
    });

    $scope.$on('$destroy', function() {
      // logger.log("HomeCtrl destroy");
      // console.log("bio HomeCtrl destroy");
      $timeout.cancel(slideInTimeout);
      $timeout.cancel(gotoPageTimeout);
      $timeout.cancel(refreshTimeout);
      deregisterHandleCheckOutbox();
      deregisterIonicViewEnter();
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

  LeadCaptureCtrl.$inject = ['$rootScope', '$scope', '$ionicPopup', '$state', '$ionicLoading', '$timeout', '$ionicScrollDelegate', '$ionicHistory', 'logger', 'SyncService', 'NetworkService', 'RecordTypeService', 'MobileDynamicService', 'LocalNotificationService', 'CameraService', 'AnalyticsService'];

  function LeadCaptureCtrl($rootScope, $scope, $ionicPopup, $state, $ionicLoading, $timeout, $ionicScrollDelegate, $ionicHistory, logger, SyncService, NetworkService, RecordTypeService, MobileDynamicService, LocalNotificationService, CameraService, AnalyticsService) {
    // logger.log("in LeadCaptureCtrl");
    // console.log("bio in LeadCaptureCtrl");

    var vm = this;
    var recordTypeId;
    var initialLead = {
      "eventName": "",
      "nameTitleInstitution": "",
      "contactInformation": "",
      "product": "STIMULAN",
      "notes": "",
      "leadPhotoBase64": ""
    };
    var scrollTimeout;
    var submitSuccessful = false;
    var cameraQuality = 90;

    vm.showCancel = false;
    vm.today = new Date();
    vm.newLeadTitle = "";
    vm.lead = {};

    // Exposed functions
    vm.gotoStep = gotoStep;
    vm.stepBack = stepBack;
    vm.inputValidation = inputValidation;
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
        if (vm.lead.eventName.trim() !== "") {
          vm.showBackButton = false;
        }
        // Analytics
        if (step == "eventinfo") {
          // Increment analytics
          AnalyticsService.incrementKey("lead-new").then(function(result) {
          }).catch(function(e){
            logger.error('LeadCaptureCtrl gotoStep AnalyticsService.incrementKey error: ' + JSON.stringify(e));
          });
        }
      } else if (step == "capture-photo") {
        // Increment analytics
        AnalyticsService.incrementKey("lead-new-photo").then(function(result) {
        }).catch(function(e){
          logger.error('LeadCaptureCtrl gotoStep AnalyticsService.incrementKey error: ' + JSON.stringify(e));
        });
        // Stop step being changed here until photo has been taken (or errored)
        step = null;
        // Take photo
        try {
          navigator.camera.getPicture(function(result) {
            // Once captured, check size, save and show
            if (result.length <= 130000) {
              vm.lead.leadPhotoBase64 = result;
              gotoStep("eventinfo");
            } else {
              // Photo image too large (for SFDC field size), reduce quality and allow to try again
              cameraQuality -= 10;
              showAlert("Error","Unfortunately, the photo size is too large. Please try again.");
            }
          }, function(err) {
            logger.error("CameraService.getPicture " + JSON.stringify(err));
          }, {
            quality         : cameraQuality,
            targetWidth     : 480,
            targetHeight    : 480,
            encodingType    : navigator.camera.EncodingType.JPEG,
            destinationType : navigator.camera.DestinationType.DATA_URL
          });
        } catch(e) {
          logger.error("CameraService.getPicture try error " + JSON.stringify(e));
        }
      } else if (step == "default") {
        vm.newLeadTitle = "";
        vm.showCancel = false;
        activate();
        $rootScope.$emit('disableSideMenu', {showSideMenu : true});
        SyncService.setSyncLock("false");
      }
      if (step) {
        vm.step = step;
        // Always scroll to top of view
        scrollTimeout = $timeout(function(){
          $ionicScrollDelegate.scrollTop();
        },50);
      }
    }

    function stepBack(currentStep) {
      if (currentStep == "topic") {
        if (vm.lead.leadPhotoBase64) {
          gotoStep("eventinfo");
        } else {
          gotoStep("contactinfo");
        }
      }
    }

    function inputValidation(nextStepIfValid) {
      if (nextStepIfValid === "leadinfo") {
        if (vm.lead.eventName.trim() === "") {
          showAlert("Error","Please enter an event name.");
          return;
        }
      }
      if (nextStepIfValid === "contactinfo") {
        if (vm.lead.nameTitleInstitution.trim() === "") {
          showAlert("Error","Please enter a name/title/institution.");
          return;
        }
      }
      if (nextStepIfValid === "topic") {
        // console.log("bio vm.lead",vm.lead);
        if (vm.lead.contactInformation.trim() === "") {
          showAlert("Error","Please enter an e-mail/telephone/address.");
          return;
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
      // Check for change of flow
      if (nextStepIfValid === "leadinfo") {
        // If Event name is valid and photo has been taken
        // then skip to the 'topic' view
        if (vm.lead.leadPhotoBase64) {
          nextStepIfValid = 'topic';
        }
      }
      // Go to step
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
          SyncService.syncTables(['Mobile_Dynamic__ap','Mobile_Log__mc']);
          // Exit
          submitSuccessful = true;
          exitLeadCapture("lead-capture-submit");
        } else {
          // Offline...
          $rootScope.$emit('updateOutboxCount');
          $rootScope.$emit('home:checkOutbox');
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
      lead.Name_Title_Institution__c = vm.lead.nameTitleInstitution;
      lead.Contact_Information__c = vm.lead.contactInformation;
      lead.Product__c = vm.lead.product;
      lead.Notes__c = vm.lead.notes;
      if (vm.lead.leadPhotoBase64) {
        lead.Lead_Photo_Base64__c = vm.lead.leadPhotoBase64;
      }
      if (recordTypeId !== "") {
        lead.RecordTypeId = recordTypeId;
      }
      lead.Date_Entered__c = new Date();
      // Set other required checkboxes
      lead.Alternate_Billing_Address__c = false;
      lead.STIMULAN_Bullet__c = false;
      lead.STIMULAN_Kit_10cc__c = false;
      lead.STIMULAN_Kit_5cc__c = false;
      lead.STIMULAN_Rapid_Cure_10cc__c = false;
      lead.STIMULAN_Rapid_Cure_20cc__c = false;
      lead.STIMULAN_Rapid_Cure_5cc__c = false;
      lead.Other_Product__c = false;
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
          exitLeadCapture("lead-capture-cancel");
        }
      });
    }

    function exitLeadCapture(analyticPoint) {
      // Increment analytics
      AnalyticsService.incrementKey(analyticPoint).then(function(result) {
      }).catch(function(e){
        logger.error('LeadCaptureCtrl exitLeadCapture AnalyticsService.incrementKey error: ' + JSON.stringify(e));
      });
      // Re-enable menu
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
        template: 'Submission successful. Please allow sync to complete before closing app',
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
          exitLeadCapture("lead-capture-submit");
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

    // Event fired when we enter view - regardless of whether it's cached
    var deregisterIonicViewEnter = $scope.$on('$ionicView.enter', function(scopes, states) {
      var forwardView = $ionicHistory.viewHistory().forwardView;
      // Make sure we're not coming back form the History list view
      if (!forwardView) {
        // Increment analytics
        AnalyticsService.incrementKey("lead").then(function(result) {
        }).catch(function(e){
          logger.error('LeadCaptureCtrl deregisterIonicViewEnter AnalyticsService.incrementKey error: ' + JSON.stringify(e));
        });
      }
    });

    $scope.$on('$destroy', function() {
      // logger.log("LeadCaptureCtrl destroy");
      // console.log("bio LeadCaptureCtrl destroy");
      $timeout.cancel(scrollTimeout);
      deregisterIonicViewEnter();
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

  LeadHistoryCtrl.$inject = ['$rootScope', '$scope', '$window', '$ionicLoading', '$ionicModal', '$state', 'logger', 'RecordTypeService', 'MobileDynamicService', 'AnalyticsService'];

  function LeadHistoryCtrl($rootScope, $scope, $window, $ionicLoading, $ionicModal, $state, logger, RecordTypeService, MobileDynamicService, AnalyticsService) {
    // logger.log("in LeadHistoryCtrl");
    // console.log("bio in LeadHistoryCtrl");

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
        // console.log("bio vm.leads",vm.leads);
        $ionicLoading.hide();
        // Increment analytics
        AnalyticsService.incrementKey("lead-history").then(function(result) {
        }).catch(function(e){
          logger.error('LeadHistoryCtrl activate AnalyticsService.incrementKey error: ' + JSON.stringify(e));
        });
      });
    }

    function showModal(record) {
      $ionicModal.fromTemplateUrl($window.RESOURCE_ROOT + "templates/leadDetail.html", {
        scope: $scope,
        animation: 'slide-in-up'
      }).then(function(modal) {
        vm.modal = modal;
        vm.modal.lead = record;
        // console.log("bio showModal vm.modal.lead",vm.modal.lead);
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
      // logger.log("LeadHistoryCtrl syncTables: " + JSON.stringify(args));
      // console.log("bio LeadHistoryCtrl syncTables: " + JSON.stringify(args));
      if (args.result.toString().indexOf("TableComplete") >= 0) {
        var syncedTable = args.result.replace("TableComplete ","");
        if (syncedTable == "Mobile_Dynamic__ap") {
          activate();
        }
      }
    });

    $scope.$on('$destroy', function() {
      // logger.log("LeadHistoryCtrl destroy");
      // console.log("bio LeadHistoryCtrl destroy");
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

  MenuCtrl.$inject = ['$rootScope', '$scope', '$timeout', '$ionicLoading', '$ionicSideMenuDelegate', '$location', '$state', '$ionicScrollDelegate', '$ionicPopup', '$window', 'logger', 'MenuService', 'SyncService', 'UserService', 'RecordTypeService', 'OutboxService', 'LocalNotificationService', 'NetworkService', 'AppSoupService', 'AnalyticsService'];

  function MenuCtrl($rootScope, $scope, $timeout, $ionicLoading, $ionicSideMenuDelegate, $location, $state, $ionicScrollDelegate, $ionicPopup, $window, logger, MenuService, SyncService, UserService, RecordTypeService, OutboxService, LocalNotificationService, NetworkService, AppSoupService, AnalyticsService) {
    var vm = this;
    var displayFeedbackMsgTimeout, delayHidingOfFeedbackMsgTimeout, displaySyncingMessageAgainTimeout, gotoPageTimeout, menuRefreshTimeout, inAppBrowserTimeout;

    vm.allSideMenuOptions = [];
    vm.stimulanMenuOption = {};
    vm.settingsMenuOption = {};
    vm.genexMenuOption = {};
    vm.menuOptions = [];
    vm.selectedItem = null;
    vm.feedbackMsgText = "";
    vm.showFeedbackMsg = false;
    vm.showSideMenu = true;
    vm.currentYear = (new Date()).getFullYear();

    vm.showSubmenu = showSubmenu;
    vm.goBack = goBack;
    vm.doRefreshAndSync = doRefreshAndSync;
    vm.gotoPage = gotoPage;
    vm.openDistHub = openDistHub;

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
          vm.genexMenuOption = sidemenu[3];
          vm.menuOptions = vm.allSideMenuOptions;
          // Load the record types used when saving the lead capture and unsolicited requests (when saved to Mobile_Dynamic__ap)
          setRecordTypes();
          // Check for dirty (unsynced) records
          updateOutboxCount();
          menuRefreshTimeout = $timeout(function() {
            $scope.$apply();
            UserService.hasDoneProcess("initialDataLoaded").then(function(result) {
              if (result) {
                $ionicLoading.hide();
              }
            });
          },0);
          // If the app is warm started then a sync (in app.js) is kicked off.
          // By the time this controller is instantiated, the syncstart event might have been missed
          if (SyncService.getSyncState() == "syncing") {
            displayFeedbackMsg("Syncing...");
          }
        } else {
          // This will be after an initial install of app.
          // Make sure the menu data is read/loaded before accessing tables for record types/outbox
          MenuService.buildAndSetSideMenuJson().then(function(result) {
            // console.log("bio MenuCtrl getSideMenuJson result",result);
            vm.allSideMenuOptions = result[0];
            vm.stimulanMenuOption = result[1];
            vm.settingsMenuOption = result[2];
            vm.genexMenuOption = result[3];
            vm.menuOptions = vm.allSideMenuOptions;
            if (vm.allSideMenuOptions.length > 0) {
              // Load the record types used when saving the lead capture and unsolicited requests (when saved to Mobile_Dynamic__ap)
              setRecordTypes();
              // Check for dirty (unsynced) records
              updateOutboxCount();
              // Make sure the menu updates after reading record types, outbox and angular/ionic has done it's stuff
              menuRefreshTimeout = $timeout(function() {
                $scope.$apply();
                UserService.hasDoneProcess("initialDataLoaded").then(function(result) {
                  if (result) {
                    $ionicLoading.hide();
                  }
                });
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
      // Increment analytics
      AnalyticsService.incrementKey(vm.selectedItem.name).then(function(result) {
      }).catch(function(e){
        logger.error('MenuCtrl showSubmenu AnalyticsService.incrementKey error: ' + JSON.stringify(e));
      });
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
      // Increment analytics
      AnalyticsService.incrementKey("sync").then(function(result) {
        if (SyncService.getSyncState() == "complete") {
          // Sync tables
          SyncService.syncTables(['Mobile_Refresh__ap', 'Content_Item__ap', 'DOF__ap', 'DOF_Item__ap', 'Mobile_Dynamic__ap', 'Surgeon_in_Hospital__ap', 'Mobile_Log__mc']);
        }
      }).catch(function(e){
        logger.error('MenuCtrl doRefreshAndSync AnalyticsService.incrementKey error: ' + JSON.stringify(e));
      });
      // Display home page
      $state.go("app.home");
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
        var newGenexMenuOption = result[3];
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
        // Check to see if genex sub menu order or names have changed
        var currentGenexMenuOptionNames = _.pluck(vm.genexMenuOption.submenu, "name");
        var newGenexMenuOptionNames = _.pluck(newGenexMenuOption.submenu, "name");
        // console.log("bio MenuCtrl after syncTables Genex joins1",currentGenexMenuOptionNames.join());
        // console.log("bio MenuCtrl after syncTables Genex joins2",newGenexMenuOptionNames.join());
        if (newGenexMenuOptionNames.join() !== currentGenexMenuOptionNames.join()) {
          reloadMenu = true;
        }
        // Check if menu re-load required
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
      // logger.log("MenuCtrl syncTables: " + JSON.stringify(args));
      // console.log("bio MenuCtrl syncTables: " + JSON.stringify(args));
      if (args && args.result) {
        switch (args.result.toString()) {
          case "StartSync" :
            displayFeedbackMsg("Syncing...");
            break;
          case "Complete" :
            delayHidingOfFeedbackMsg(0);
            // Fire event to show/hide outbox alert on home page
            $rootScope.$emit('home:checkOutbox');
            LocalNotificationService.cancelNotification();
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
            delayHidingOfFeedbackMsg(3000);
            // Fire event to show/hide outbox alert on home page
            $rootScope.$emit('home:checkOutbox');
            LocalNotificationService.setLocalNotification();
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
              if (syncedTable == "DOF_Item__ap" || syncedTable == "Mobile_Dynamic__ap") {
                // Fire event to show/hide outbox alert on home page
                $rootScope.$emit('home:checkOutbox');
              }
              if (syncedTable == "Mobile_Refresh__ap") {
                checkForMenuChanges();
                setRecordTypes();
              }
            }
        }
      }
    });

    function displayFeedbackMsg(msg) {
      displayFeedbackMsgTimeout = $timeout(function() {
        vm.feedbackMsgText = msg;
        vm.showFeedbackMsg = true;
        $scope.$apply();
      },0);
    }

    function delayHidingOfFeedbackMsg(delay) {
      delayHidingOfFeedbackMsgTimeout = $timeout(function() {
        vm.showFeedbackMsg = false;
        $scope.$apply();
      },delay);
    }

    function displaySyncingMessageAgain() {
      displaySyncingMessageAgainTimeout = $timeout(function() {
        vm.feedbackMsgText = "Syncing...";
        vm.showFeedbackMsg = true;
        $scope.$apply();
      },3000);
    }

    function updateOutboxCount() {
      OutboxService.getDirtyRecords().then(function(records) {
        // console.log("bio records",records);
        var count = 0;
        // Don't include DOF_Item__ap records in count shown in side menu
        for (var i = 0; i < records.length; i++) {
          if (records[i].Mobile_Table_Name === "DOF__ap" || records[i].Mobile_Table_Name === "Mobile_Dynamic__ap") {
            count ++;
          }
        }
        if (count > 0) {
          vm.outboxCount = " (" + count + ")";
        } else {
          vm.outboxCount = "";
        }
      });
    }


    function openDistHub() {
      var token;
      var url;

      if (NetworkService.getNetworkStatus() === "online") {
        // Harding coding of production community
        url = "https://biocomposites.force.com";
        inAppBrowserTimeout = $timeout(function() {
          if (cordova.InAppBrowser) {
            cordova.InAppBrowser.open(url, "_system", "location=yes");
          } else {
            $window.open(url, "_system", "location=yes");
          }
        },0);
      } else {
        alertOffline();
      }

      // Old code that gets url from appSoup
      // if (NetworkService.getNetworkStatus() === "online") {
      //   AppSoupService.getCurrentValue("accessToken").then(function(result) {
      //     if (result) {
      //       token = result;
      //       // Get the login url
      //       return AppSoupService.getCurrentValue("loginUrl");
      //     } else {
      //       return null;
      //     }
      //   }).then(function(result) {
      //     if (result) {
      //       url = result + "/secur/frontdoor.jsp?sid=" + token + "&retURL=/apex/biocomp?tab=Home";

      //       inAppBrowserTimeout = $timeout(function() {
      //         if (cordova.InAppBrowser) {
      //           cordova.InAppBrowser.open(url, "_system", "location=yes");
      //         } else {
      //           $window.open(url, "_system", "location=yes");
      //         }
      //       },0);
      //     }
      //   });
      // } else {
      //   alertOffline();
      // }

      // Increment analytics
      AnalyticsService.incrementKey("dist-hub").then(function(result) {
      }).catch(function(e){
        logger.error('MenuCtrl openDistHub AnalyticsService.incrementKey error: ' + JSON.stringify(e));
      });
      // Display home page
      $state.go("app.home");
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

    var deregisterHandleSetSideMenuVisibility = $rootScope.$on('disableSideMenu', function(event, args) {
      vm.showSideMenu = args.showSideMenu;
      $ionicSideMenuDelegate.canDragContent(args.showSideMenu);
    });

    var deregisterHandleShowStimulan = $rootScope.$on('showStimulanMenu', function(event, args) {
      showSubmenu(vm.stimulanMenuOption);
      $ionicSideMenuDelegate.toggleLeft();
    });

    var deregisterHandleShowGenex = $rootScope.$on('showGenexMenu', function(event, args) {
      showSubmenu(vm.genexMenuOption);
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

    var deregisterHandleOpenDistHub = $rootScope.$on('menu:openDistHub', function(event, args) {
      openDistHub();
    });

    $scope.$on('$destroy', function() {
      // logger.log("MenuCtrl destroy");
      // console.log("bio MenuCtrl destroy");
      deregisterHandleSyncTables();
      deregisterHandleSetSideMenuVisibility();
      deregisterHandleShowStimulan();
      deregisterHandleShowGenex();
      deregisterHandleShowSettings();
      deregisterHandleUpdateOutboxCount();
      deregisterHandleShowSideMenu();
      deregisterHandleOpenDistHub();
      $timeout.cancel(displayFeedbackMsgTimeout);
      $timeout.cancel(delayHidingOfFeedbackMsgTimeout);
      $timeout.cancel(displaySyncingMessageAgainTimeout);
      $timeout.cancel(gotoPageTimeout);
      $timeout.cancel(menuRefreshTimeout);
      $timeout.cancel(inAppBrowserTimeout);
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

  MTICtrl.$inject = ['$stateParams', '$scope', '$rootScope', '$location', '$ionicPopup', '$ionicLoading', 'DevService', 'devUtils', 'logger', 'syncRefresh'];

  function MTICtrl($stateParams, $scope, $rootScope, $location, $ionicPopup, $ionicLoading, DevService, devUtils, logger, syncRefresh) {

  	if ($stateParams.recovery) {
  		$scope.recovery = true;
  	}

	  var adminTimeout = (1000 * 60 *5 ); // 5 minutes
	  if ( $rootScope.adminLoggedIn > Date.now() - adminTimeout) {
	  } else {
	    $location.url('app/settings');
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
	        if ($scope.recovery) {
						syncRefresh.m2pRecoveryUpdateMobileTable(tableName).then(function(resObject){
							var resJson = JSON.parse(resObject.result);
							var resMsg = '';
							console.log("resJson.is", resJson.is);
							if (resJson.is) {
								resMsg += '<p>Insert Success: ' + resJson.is.length + '</p>';
							}
							if (resObject.us) {
								resMsg += '<p>Update Success: ' + resJson.us.length + '</p>';
							}
							var alertPopup = $ionicPopup.alert({
		            title: 'ForceSync Success!',
		            template: resMsg,
		            buttons: [
			            { text: 'Done' }, {
			               text: '<b>Show Full Resp</b>',
			               type: 'button-positive',
			               onTap: function(e) {
			                  var alertPopup2 = $ionicPopup.alert({
			                  	title: "Full Response",
			                  	template: '<p>Returned with:</p><p><pre>' + JSON.stringify(resObject) + '</pre></p>'
			                  });
			               }
			            }
			         ]

		          });
		          $ionicLoading.hide();
		        }).catch(function(e){
		          logger.error('syncRefresh.m2pRecoveryUpdateMobileTable from settings ' + tableName + " " + JSON.stringify(e));
		          $ionicLoading.hide();
		          var alertPopup = $ionicPopup.alert({
		            title: 'Operation failed!',
		            template: '<p>Sorry, something went wrong.</p><p class="error_details">Error: ' + e.status + ' - ' + e.mc_add_status + '</p>'
		          });
		        });
	        } else {
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
 * My Accounts Controller
 *
 * @description List of my accounts
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('MyAccountsCtrl', MyAccountsCtrl);

  MyAccountsCtrl.$inject = ['$rootScope', '$scope', '$ionicLoading', '$location', '$timeout', '$ionicScrollDelegate', '$ionicModal', '$ionicHistory', '$window', '$stateParams', 'logger', 'SyncService', 'OrderFormService', 'UserService'];

  function MyAccountsCtrl($rootScope, $scope, $ionicLoading, $location, $timeout, $ionicScrollDelegate, $ionicModal, $ionicHistory, $window, $stateParams, logger, SyncService, OrderFormService, UserService) {
    // logger.log("in MyAccountsCtrl");
    // console.log("bio in MyAccountsCtrl");

    var vm = this;
    var refreshTimeout;

    vm.accounts = [];
    vm.searchQuery = "";

    // Exposed functions
    vm.scrollTop = scrollTop;
    vm.clearSearch = clearSearch;
    vm.showModal = showModal;
    vm.closeModal = closeModal;

    /**
     * @function showList
     * @description Shows list of accounts
     */
    function showList(showLoading) {
      // console.log("bio showList showLoading=",showLoading);
      if (showLoading) {
        $ionicLoading.show({
          duration: 60000,
          template: 'Loading...',
          animation: 'fade-in',
          showBackdrop: true
        });
      }
      adjustListHeight();
      UserService.hasDoneProcess("initialDataLoaded").then(function (initialInstallFinished) {
        if (initialInstallFinished) {
          // Get all the accounts
          OrderFormService.getHospitals().then(function(res) {
            // console.log("bio res",res);
            if (res.length > 0) {
              vm.accounts = res;
            }
            refreshTimeout = $timeout(function() {
              $ionicLoading.hide();
              $scope.$apply();
            }, 0);
          }).catch(function(resObject){
            logger.error('MyAccountsCtrl ' + JSON.stringify(resObject));
            $ionicLoading.hide();
          });
        } // else we have not yet completed the initialSync
      });
    }

    /**
     * @function clearSearch
     * @description clears search box
     */
    function clearSearch() {
      vm.searchQuery = "";
    }

    /**
     * @function scrollTop
     * @description This should scroll the list to the top
     **/
    function scrollTop() {
      $ionicScrollDelegate.scrollTop();
    }

    function showModal(record) {
      $ionicModal.fromTemplateUrl($window.RESOURCE_ROOT + "templates/accountDetail.html", {
        scope: $scope,
        animation: 'slide-in-up'
      }).then(function(modal) {
        vm.modal = modal;
        vm.modal.account = record;
        vm.modal.show();
      });
    }

    function closeModal() {
      if (vm.modal) {
        vm.modal.hide();
        vm.modal.remove();
        delete vm.modal;
      }
    }

    function adjustListHeight() {
      var winHeight = $window.innerHeight - 175;
      var accountsList = $window.document.getElementById('accounts-list');
      if (accountsList) {
        accountsList.setAttribute("style","height:" + winHeight + "px");
      }
    }

    function windowResizeHandler() {
      adjustListHeight();
    }

    // Handle event fired when view loaded
    var deregisterHandleViewLoaded = $scope.$on('$ionicView.loaded', function (viewInfo, state) {
      // Register window resize event
      angular.element($window).on('resize', windowResizeHandler);
    });

    // Handle event fired when we leave view - regardless of whether it's cached
    var deregisterHandleViewLeave = $scope.$on('$ionicView.leave', function(scopes, states) {
      // Deregister window resize event
      angular.element($window).off('resize', windowResizeHandler);
    });

    // Clear the cache after we leave this view - so controller is instatiated each time we do a new referral
    var deregisterHandleViewAfterLeave = $scope.$on("$ionicView.afterLeave", function () {
         $ionicHistory.clearCache();
    });

    /**
     * @event on $ionicView.beforeEnter
     * @description Handle events fired from Ionic $ionicView.beforeEnter to reload of list.
     *              Associated view is cached by default so we use this event to refresh the list
     */
    var deregisterIonicViewBeforeEnter = $scope.$on('$ionicView.beforeEnter', function(scopes, states) {
      showList(true);
    });

    /**
     * @event on syncTables
     * @description Handle events fired from the SyncService.
     */
    var deregisterHandleSyncTables = $rootScope.$on('syncTables', function(event, args) {
      // logger.log("MyAccountsCtrl syncTables: " + JSON.stringify(args));
      console.info("bio MyAccountsCtrl syncTables: " + JSON.stringify(args));
      if (args && args.result) {
        var syncResult = args.result.toString();
        switch (syncResult) {
          case "InitialLoadComplete" :
            // Check that accounts list has been populated after initial data load
            if (vm.accounts.length === 0) {
              showList(true);
            } else {
              $ionicLoading.hide();
            }
            // Save the fact that we've run the initial data load for the app install
            UserService.setProcessDone("initialDataLoaded");
            break;
          default :
            if (args.table) {
              var syncedTable = args.table.toString();
              if (syncedTable == "Surgeon_in_Hospital__ap") {
                showList(false);
              }
            }
        }
      }
    });

    /**
     * @event on $destroy
     * @description Tidy up objects when $scope is destroyed
     */
    $scope.$on('$destroy', function() {
      // logger.log("MyAccountsCtrl destroy");
      // console.log("bio MyAccountsCtrl destroy");
      deregisterHandleSyncTables();
      deregisterIonicViewBeforeEnter();
      deregisterHandleViewLoaded();
      deregisterHandleViewLeave();
      deregisterHandleViewAfterLeave();
      $timeout.cancel(refreshTimeout);
    });

  }

})();
/**
 * New account Controller
 *
 * @description controller for new account functionality
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('NewAccountCtrl', NewAccountCtrl);

  NewAccountCtrl.$inject = ['$rootScope', '$scope', '$ionicPopup', '$state', '$ionicLoading', '$timeout', '$ionicScrollDelegate', '$ionicHistory', 'logger', 'SyncService', 'NetworkService', 'RecordTypeService', 'MobileDynamicService', 'LocalNotificationService', 'UserService', 'AnalyticsService'];

  function NewAccountCtrl($rootScope, $scope, $ionicPopup, $state, $ionicLoading, $timeout, $ionicScrollDelegate, $ionicHistory, logger, SyncService, NetworkService, RecordTypeService, MobileDynamicService, LocalNotificationService, UserService, AnalyticsService) {
    // logger.log("in NewAccountCtrl");
    // console.log("bio in NewAccountCtrl");

    var vm = this;
    var recordTypeId;
    var initialAccount = {
      "hospitalName": "",
      "address": "",
      "alternateBillingAddressDetails": "",
      "STIMULANRapidCure5cc": false,
      "STIMULANRapidCure5ccPrice": null,
      "STIMULANRapidCure10cc": false,
      "STIMULANRapidCure10ccPrice": null,
      "STIMULANRapidCure20cc": false,
      "STIMULANRapidCure20ccPrice": null,
      "STIMULANKit5cc": false,
      "STIMULANKit5ccPrice": null,
      "STIMULANKit10cc": false,
      "STIMULANKit10ccPrice": null,
      "STIMULANBullet": false,
      "STIMULANBulletPrice": null,
      "otherProduct": false,
      "otherProductDetails": "",
      "hospitalContactInfo": "",
      "additionalComments": ""
    };
    var scrollTimeout;
    var submitSuccessful = false;

    vm.showCancel = false;
    vm.today = new Date();
    vm.account = {};

    // Exposed functions
    vm.gotoStep = gotoStep;
    vm.inputValidation = inputValidation;
    vm.cancelNewAccount = cancelNewAccount;
    vm.billAddressCheckboxChange = billAddressCheckboxChange;

    activate();

    function activate() {
      angular.copy(initialAccount,vm.account);
      vm.billingAddress = {};
      vm.billingAddress.isSameAsMainAddress = true;
      vm.billingAddress.isAlternativeAddress = false;
      vm.showBackButton = true;
      RecordTypeService.getRecordTypeId("New_Account","Mobile_Dynamic__c").then(function(id){
        recordTypeId = id;
        // Get user's currency symbol
        UserService.getUserCurrencySymbol().then(function(result) {
          vm.currencySymbol = result;
        });
      });
    }

    function gotoStep(step) {
      if (step == "hosp-details") {
        vm.showCancel = true;
        $rootScope.$emit('disableSideMenu', {showSideMenu : false});
        SyncService.setSyncLock("true");
        if (vm.account.hospitalName.trim() !== "") {
          vm.showBackButton = false;
        }
        // Increment analytics
        AnalyticsService.incrementKey("new-account-start").then(function(result) {
        }).catch(function(e){
          logger.error('NewAccountCtrl gotoStep AnalyticsService.incrementKey error: ' + JSON.stringify(e));
        });
      } else if (step == "default") {
        vm.showCancel = false;
        activate();
        $rootScope.$emit('disableSideMenu', {showSideMenu : true});
        SyncService.setSyncLock("false");
      }
      if (step) {
        vm.step = step;
        // Always scroll to top of view
        scrollTimeout = $timeout(function(){
          $ionicScrollDelegate.scrollTop();
        },50);
      }
    }

    function inputValidation(nextStepIfValid) {
      if (nextStepIfValid === "bill-address") {
        if (vm.account.hospitalName.trim() === "") {
          showAlert("Error","Please enter a hospital name.");
          return;
        }
        if (vm.account.address.trim() === "") {
          showAlert("Error","Please enter a hospital address.");
          return;
        }
      }
      if (nextStepIfValid === "products") {
        if (vm.billingAddress.isAlternativeAddress && vm.account.alternateBillingAddressDetails.trim() === "" ||
            !vm.billingAddress.isAlternativeAddress && vm.account.alternateBillingAddressDetails.trim() !== "") {
          showAlert("Error","Please enter an alternative billing address and tick the option.");
          return;
        }
      }
      if (nextStepIfValid === "add-info") {
        var errorMsg = validateProducts();
        if (errorMsg !== "") {
          showAlert("Error",errorMsg);
          return;
        }
      }
      if (nextStepIfValid === "submit") {
        submitNewAccount();
        return;
      }
      // Go to step
      gotoStep(nextStepIfValid);
    }

    function validateProducts() {
      var errorMsg = "";
      if (!vm.account.STIMULANRapidCure5cc &&
          !vm.account.STIMULANRapidCure10cc &&
          !vm.account.STIMULANRapidCure20cc &&
          !vm.account.STIMULANKit5cc &&
          !vm.account.STIMULANKit10cc &&
          !vm.account.STIMULANBullet &&
          (vm.account.otherProductDetails === "")) {
        errorMsg = "Please select at least one product.";
      }
      // If price(s) entered then validate decimal
      if (typeof(vm.account.STIMULANRapidCure5ccPrice) === "undefined" || (vm.account.STIMULANRapidCure5ccPrice && !isValidPrice(vm.account.STIMULANRapidCure5ccPrice))) {
        errorMsg = "Please enter a valid STIMULAN Rapid Cure 5cc price.";
      }
      if (typeof(vm.account.STIMULANRapidCure10ccPrice) === "undefined" || (vm.account.STIMULANRapidCure10ccPrice && !isValidPrice(vm.account.STIMULANRapidCure10ccPrice))) {
        errorMsg = "Please enter a valid STIMULAN Rapid Cure 10cc price.";
      }
      if (typeof(vm.account.STIMULANRapidCure20ccPrice) === "undefined" || (vm.account.STIMULANRapidCure20ccPrice && !isValidPrice(vm.account.STIMULANRapidCure20ccPrice))) {
        errorMsg = "Please enter a valid STIMULAN Rapid Cure 20cc price.";
      }
      if (typeof(vm.account.STIMULANKit5ccPrice) === "undefined" || (vm.account.STIMULANKit5ccPrice && !isValidPrice(vm.account.STIMULANKit5ccPrice))) {
        errorMsg = "Please enter a valid STIMULAN Kit 5cc price.";
      }
      if (typeof(vm.account.STIMULANKit10ccPrice) === "undefined" || (vm.account.STIMULANKit10ccPrice && !isValidPrice(vm.account.STIMULANKit10ccPrice))) {
        errorMsg = "Please enter a valid STIMULAN Kit 10cc price.";
      }
      if (typeof(vm.account.STIMULANBulletPrice) === "undefined" || (vm.account.STIMULANBulletPrice && !isValidPrice(vm.account.STIMULANBulletPrice))) {
        errorMsg = "Please enter a valid STIMULAN Bullet Mat and Introducer price.";
      }

      // If price(s) entered then check option is ticked
      if (!vm.account.STIMULANRapidCure5cc && vm.account.STIMULANRapidCure5ccPrice) {
        errorMsg = "Please select the STIMULAN Rapid Cure 5cc product.";
      }
      if (!vm.account.STIMULANRapidCure10cc && vm.account.STIMULANRapidCure10ccPrice) {
        errorMsg = "Please select the STIMULAN Rapid Cure 10cc product.";
      }
      if (!vm.account.STIMULANRapidCure20cc && vm.account.STIMULANRapidCure20ccPrice) {
        errorMsg = "Please select the STIMULAN Rapid Cure 20cc product.";
      }
      if (!vm.account.STIMULANKit5cc && vm.account.STIMULANKit5ccPrice) {
        errorMsg = "Please select the STIMULAN Kit 5cc product.";
      }
      if (!vm.account.STIMULANKit10cc && vm.account.STIMULANKit10ccPrice) {
        errorMsg = "Please select the STIMULAN Kit 10cc product.";
      }
      if (!vm.account.STIMULANBullet && vm.account.STIMULANBulletPrice) {
        errorMsg = "Please select the STIMULAN Bullet Mat and Introducer product.";
      }
      return errorMsg;
    }

    function submitNewAccount() {
      // Save Account (to Mobile_Dynamic__ap)
      $ionicLoading.show({
        duration: 5000,
        template: 'Saving account...',
        animation: 'fade-in',
        showBackdrop: true
      });
      MobileDynamicService.insertRecord(buildAccountRecord()).then(function(resObject) {
        $ionicLoading.hide();
        // Check connectivity, if online then sync, otherwise display message
        if (NetworkService.getNetworkStatus() === "online") {
          // Ensure sync will run
          SyncService.setSyncLock("false");
          // Sync in background
          SyncService.syncTables(['Mobile_Dynamic__ap','Mobile_Log__mc']);
          // Exit
          submitSuccessful = true;
          exitNewAccount("new-account-submit");
        } else {
          // Offline...
          $rootScope.$emit('updateOutboxCount');
          $rootScope.$emit('home:checkOutbox');
          // Set a local notification
          LocalNotificationService.setLocalNotification();
          // Display 'offline' message
          alertOffline();
        }
      }).catch(function(e){
        logger.error('submitNewAccount ' + JSON.stringify(e) + " " + JSON.stringify(orderForm));
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

    function buildAccountRecord() {
      var account = {};
      account.Name = "TMP-" + new Date().valueOf();
      account.Hospital_Name__c = vm.account.hospitalName.trim();
      account.Address__c = vm.account.address.trim();
      account.Alternate_Billing_Address__c = vm.billingAddress.isAlternativeAddress;
      if (vm.billingAddress.isAlternativeAddress) {
        account.Alternate_Billing_Address_Details__c = vm.account.alternateBillingAddressDetails.trim();
      }
      account.STIMULAN_Rapid_Cure_5cc__c = vm.account.STIMULANRapidCure5cc;
      if (vm.account.STIMULANRapidCure5cc) {
        account.STIMULAN_Rapid_Cure_5cc_Price__c = vm.account.STIMULANRapidCure5ccPrice;
      }
      account.STIMULAN_Rapid_Cure_10cc__c = vm.account.STIMULANRapidCure10cc;
      if (vm.account.STIMULANRapidCure10cc) {
        account.STIMULAN_Rapid_Cure_10cc_Price__c = vm.account.STIMULANRapidCure10ccPrice;
      }
      account.STIMULAN_Rapid_Cure_20cc__c = vm.account.STIMULANRapidCure20cc;
      if (vm.account.STIMULANRapidCure20cc) {
        account.STIMULAN_Rapid_Cure_20cc_Price__c = vm.account.STIMULANRapidCure20ccPrice;
      }
      account.STIMULAN_Kit_5cc__c = vm.account.STIMULANKit5cc;
      if (vm.account.STIMULANKit5cc) {
        account.STIMULAN_Kit_5cc_Price__c = vm.account.STIMULANKit5ccPrice;
      }
      account.STIMULAN_Kit_10cc__c = vm.account.STIMULANKit10cc;
      if (vm.account.STIMULANKit10cc) {
        account.STIMULAN_Kit_10cc_Price__c = vm.account.STIMULANKit10ccPrice;
      }
      account.STIMULAN_Bullet__c = vm.account.STIMULANBullet;
      if (vm.account.STIMULANBullet) {
        account.STIMULAN_Bullet_Price__c = vm.account.STIMULANBulletPrice;
      }
      if (vm.account.otherProductDetails && vm.account.otherProductDetails.trim() !== "") {
        account.Other_Product_Details__c = vm.account.otherProductDetails.trim();
        account.Other_Product__c = true;
      } else {
        account.Other_Product__c = false;
      }
      if (vm.account.hospitalContactInfo) {
        account.Hospital_Contact_Info__c = vm.account.hospitalContactInfo.trim();
      }
      if (vm.account.additionalComments) {
        account.Additional_Comments__c = vm.account.additionalComments.trim();
      }
      if (recordTypeId !== "") {
        account.RecordTypeId = recordTypeId;
      }
      account.Date_Entered__c = new Date();
      return account;
    }

    function billAddressCheckboxChange(checkbox) {
      if (checkbox == "isSameAsMainAddress") {
        vm.billingAddress.isSameAsMainAddress = true;
        vm.billingAddress.isAlternativeAddress = false;
      } else {
        vm.billingAddress.isSameAsMainAddress = false;
        vm.billingAddress.isAlternativeAddress = true;
      }
    }

    function cancelNewAccount(){
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
          exitNewAccount("new-account-cancel");
        }
      });
    }

    function exitNewAccount(analyticPoint) {
      // Increment analytics
      AnalyticsService.incrementKey(analyticPoint).then(function(result) {
      }).catch(function(e){
        logger.error('NewAccountCtrl exitNewAccount AnalyticsService.incrementKey error: ' + JSON.stringify(e));
      });
      // Re-enable menu
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
        title: 'New account',
        template: 'Submission successful. Please allow sync to complete before closing app',
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
          exitNewAccount("new-account-submit");
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

    function isValidPrice(n) {
      return /^\d*\.?\d{0,2}$/.test(n);
      // return !isNaN(parseFloat(n)) && isFinite(n);
    }

    // Event fired when we enter view - regardless of whether it's cached
    var deregisterIonicViewEnter = $scope.$on('$ionicView.enter', function(scopes, states) {
      var forwardView = $ionicHistory.viewHistory().forwardView;
      // Make sure we're not coming back form the History list view
      if (!forwardView) {
        // Increment analytics
        AnalyticsService.incrementKey("new-account").then(function(result) {
        }).catch(function(e){
          logger.error('NewAccountCtrl deregisterIonicViewEnter AnalyticsService.incrementKey error: ' + JSON.stringify(e));
        });
      }
    });

    $scope.$on('$destroy', function() {
      // logger.log("NewAccountCtrl destroy");
      // console.log("bio NewAccountCtrl destroy");
      $timeout.cancel(scrollTimeout);
      deregisterIonicViewEnter();
    });

  }

})();
/**
 * New Account History Controller
 *
 * @description controller for new account history
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('NewAccountHistoryCtrl', NewAccountHistoryCtrl);

  NewAccountHistoryCtrl.$inject = ['$rootScope', '$scope', '$window', '$ionicLoading', '$ionicModal', '$state', 'logger', 'RecordTypeService', 'MobileDynamicService', 'UserService', 'AnalyticsService'];

  function NewAccountHistoryCtrl($rootScope, $scope, $window, $ionicLoading, $ionicModal, $state, logger, RecordTypeService, MobileDynamicService, UserService, AnalyticsService) {
    // logger.log("in NewAccountHistoryCtrl");
    // console.log("bio in NewAccountHistoryCtrl");

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
      vm.accounts = [];
      RecordTypeService.getRecordTypeId("New_Account","Mobile_Dynamic__c").then(function(recordTypeId) {
        return MobileDynamicService.getRecords(recordTypeId);
      }).then(function(records) {
        for (var i = 0; i < records.length; i++) {
          // Check whether the record has been synced
          if (records[i].Id.indexOf("PROXY") == -1) {
            // Yes, it's been synced
            vm.accounts.push(records[i]);
          }
        }
        // Get user's currency symbol
        UserService.getUserCurrencySymbol().then(function(result) {
          vm.currencySymbol = result;
        });
        // console.log("bio vm.accounts",vm.accounts);
        $ionicLoading.hide();
        // Increment analytics
        AnalyticsService.incrementKey("new-account-history").then(function(result) {
        }).catch(function(e){
          logger.error('NewAccountHistoryCtrl activate AnalyticsService.incrementKey error: ' + JSON.stringify(e));
        });
      });
    }

    function showModal(record) {
      $ionicModal.fromTemplateUrl($window.RESOURCE_ROOT + "templates/newAccountDetail.html", {
        scope: $scope,
        animation: 'slide-in-up'
      }).then(function(modal) {
        vm.modal = modal;
        vm.modal.account = record;
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
      // logger.log("NewAccountHistoryCtrl syncTables: " + JSON.stringify(args));
      // console.log("bio NewAccountHistoryCtrl syncTables: " + JSON.stringify(args));
      if (args.result.toString().indexOf("TableComplete") >= 0) {
        var syncedTable = args.result.replace("TableComplete ","");
        if (syncedTable == "Mobile_Dynamic__ap") {
          activate();
        }
      }
    });

    $scope.$on('$destroy', function() {
      // logger.log("NewAccountHistoryCtrl destroy");
      // console.log("bio NewAccountHistoryCtrl destroy");
      deregisterHandleSyncTables();
      if (vm.modal) {
        vm.modal.remove();
        delete vm.modal;
      }
    });

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

  OrderHistoryCtrl.$inject = ['$rootScope', '$scope', '$ionicLoading', '$window', '$ionicModal', '$state', 'logger', 'OrderFormService', 'UserService', 'AnalyticsService'];

  function OrderHistoryCtrl($rootScope, $scope, $ionicLoading, $window, $ionicModal, $state, logger, OrderFormService, UserService, AnalyticsService) {
    // logger.log("in OrderHistoryCtrl");
    // console.log("bio in OrderHistoryCtrl");

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
                vm.orders[k].items.push({"productName": records[j].Product_Name__c, "lotNumber": records[j].Lot_Number__c, "price": records[j].Entered_Price__c, "priceEntered": records[j].Price_Entered__c, "expiryDate": records[j].Expiry_Date__c});
              } else if (records[j].Product_Name_from_Lot_Number__c) {
                vm.orders[k].items.push({"productName": records[j].Product_Name_from_Lot_Number__c, "lotNumber": records[j].Lot_Number__c, "price": records[j].Entered_Price__c, "priceEntered": records[j].Price_Entered__c, "expiryDate": records[j].Expiry_Date__c});
              } else {
                vm.orders[k].items.push({"lotNumber": records[j].Lot_Number__c, "price": records[j].Entered_Price__c, "priceEntered": records[j].Price_Entered__c});
              }
            }
          }
        }
        // console.log("bio vm.orders",vm.orders);
        $ionicLoading.hide();
        // Increment analytics
        AnalyticsService.incrementKey("order-form-history").then(function(result) {
        }).catch(function(e){
          logger.error('OrderHistoryCtrl activate AnalyticsService.incrementKey error: ' + JSON.stringify(e));
        });
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
      // logger.log("OrderHistoryCtrl syncTables: " + JSON.stringify(args));
      // console.log("bio OrderHistoryCtrl syncTables: " + JSON.stringify(args));
      if (args.result.toString().indexOf("TableComplete") >= 0) {
        var syncedTable = args.result.replace("TableComplete ","");
        if (syncedTable == "DOF_Item__ap") {
          activate();
        }
      }
    });

    $scope.$on('$destroy', function() {
      // logger.log("OrderHistoryCtrl destroy");
      // console.log("bio OrderHistoryCtrl destroy");
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

  OrderFormCtrl.$inject = ['$rootScope', '$scope', '$window', '$ionicPopup', '$state', '$ionicLoading', '$timeout', '$cordovaBarcodeScanner', '$ionicScrollDelegate', '$ionicHistory', 'logger', 'OrderFormService', 'SyncService', 'RecentItemsService', 'NetworkService', 'LocalNotificationService', 'UserService', 'AnalyticsService'];

  function OrderFormCtrl($rootScope, $scope, $window, $ionicPopup, $state, $ionicLoading, $timeout, $cordovaBarcodeScanner, $ionicScrollDelegate, $ionicHistory, logger, OrderFormService, SyncService, RecentItemsService, NetworkService, LocalNotificationService, UserService, AnalyticsService) {
    // logger.log("in OrderFormCtrl");
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
    vm.allLotNumbers = [];
    vm.selectedProducts = [];
    vm.showCancel = false;
    vm.isFirstTimeThru = true;
    vm.newHospital = {"name" : "", "address" : ""};
    vm.newSurgeon = {"firstName" : "", "lastName" : ""};
    vm.hospitalRep = {"firstName" : "", "lastName" : ""};
    vm.notification = {"email" : "", "alternativeEmail" : "", "dontSend" : false, "isEmail" : false, "isAlternativeEmail" : false};
    vm.today = new Date();
    vm.hospitalTab = "hospitalrecent";

    // Exposed methods
    vm.gotoStep = gotoStep;
    vm.displayNewManualInput = displayNewManualInput;
    vm.manualInputLotNumberMatch = manualInputLotNumberMatch;
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
        // Load all lot numbers
        return OrderFormService.getLotNumbers();
      }).then(function(records) {
        vm.allLotNumbers = records;
      });
      // Get all hospitals for user's distributorship
      vm.hospitals = [];
      OrderFormService.getHospitals().then(function(records) {
        // console.log("bio hospitals",records);
        vm.hospitals = records.map(function(el){
         return {"id": el.Hospital__c, "name": el.Hospital_Name__c, "email": el.Hospital_Email__c};
        });

        return RecentItemsService.getRecentHospitals(vm.hospitals);
      }).then(function (recentHospitals) {
        vm.recentHospitals = recentHospitals;
      });
      // Get all Surgeons for all hospitals...they are filtered further down for a specific hospital
      vm.allSurgeons = [];
      OrderFormService.getSurgeons().then(function(records) {
        // console.log("bio surgeons",records);
        vm.allSurgeons = records.map(function(el){
          return {"id": el.Surgeon__c, "name": el.Salutation__c + " " + el.First_Name__c + " " + el.Last_Name__c, "hospitalId": el.Hospital__c};
        });

        return RecentItemsService.getRecentSurgeons(vm.allSurgeons);
      }).then(function (recentSurgeons) {
        vm.allRecentSurgeons = recentSurgeons;

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
      // Create new manual input object
      vm.manualInput = {};
      vm.manualInput.lotNumber = {"part1" : null, "part2" : null, "part3" : "", "part4" : ""};
      vm.manualInput.price = null;
      vm.manualInput.isCharge = true;
      vm.manualInput.isNoCharge = false;
      vm.product = null;
      // Increment analytics
      AnalyticsService.incrementKey("order-form-manual").then(function(result) {
      }).catch(function(e){
        logger.error('OrderFormCtrl displayNewManualInput AnalyticsService.incrementKey error: ' + JSON.stringify(e));
      });
      // Go to next step
      gotoStep(step);
    }

    function manualInputLotNumberMatch(nextStepIfValid) {
      if (vm.allLotNumbers.length === 0) {
        // Under normal circumstances we wouldn't come in here - vm.allLotNumbers is populated in 'activate'
        $ionicLoading.show({
          duration: 5000,
          template: 'Loading lot numbers...',
          animation: 'fade-in',
          showBackdrop: true
        });
        OrderFormService.getLotNumbers().then(function(records) {
          vm.allLotNumbers = records;
          matchLotNumber(nextStepIfValid);
          $ionicLoading.hide();
        });
      } else {
        matchLotNumber(nextStepIfValid);
      }
    }

    function matchLotNumber(nextStepIfValid) {
      if (!vm.manualInput.lotNumber.part1 && !vm.manualInput.lotNumber.part2) {
        showAlert("Error","Please enter all parts of the lot number.");
        return;
      }
      // Build the lot number to be matched against
      vm.manualInput.lotNumberCombined = "";
      if (vm.manualInput.lotNumber.part1) {
        vm.manualInput.lotNumberCombined += ("00" + vm.manualInput.lotNumber.part1).slice(-2) + "/";
      }
      if (vm.manualInput.lotNumber.part2) {
        vm.manualInput.lotNumberCombined += ("00" + vm.manualInput.lotNumber.part2).slice(-2) + "-";
      }
      if (vm.manualInput.lotNumber.part3) {
        vm.manualInput.lotNumberCombined += vm.manualInput.lotNumber.part3;
      }
      if (vm.manualInput.lotNumber.part4) {
        vm.manualInput.lotNumberCombined += "/" + vm.manualInput.lotNumber.part4;
      }
      vm.manualInput.lotNumberCombined = vm.manualInput.lotNumberCombined.toUpperCase();
      // Attempt to match input lot number against a Mobile Refresh 'Lot Numbers' record type
      var matchedLotNumber = null;
      for (var i = 0; i < vm.allLotNumbers.length; i++) {
        if (vm.allLotNumbers[i].Lot_Number__c.toUpperCase() == vm.manualInput.lotNumberCombined) {
          matchedLotNumber = vm.allLotNumbers[i];
        }
      }
      if (matchedLotNumber) {
        vm.manualInput.name = matchedLotNumber.Product_Name__c;
        vm.manualInput.expiryDate = matchedLotNumber.Expiry_Date__c;
        gotoStep(nextStepIfValid);
      } else {
        // No match, so inform user and allow them to proceed in flow after confirmation
        confirmManualInputLotNumberNotMatched(nextStepIfValid);
      }
    }

    function confirmManualInputLotNumberNotMatched(nextStepIfValid){
      var confirmPopup = $ionicPopup.confirm({
        title: 'Lot Number Not Matched',
        template: vm.manualInput.lotNumberCombined + '<br/><br/>Would you like to continue or re-enter lot number?',
        cssClass: 'bio-popup',
        cancelText: 'Re-enter',
        cancelType: 'button-dark',
        okText: 'Continue',
        okType: 'button-positive'
      });
      confirmPopup.then(function(res) {
        if (res) {
          manualInputValidation(nextStepIfValid);
        }
      });
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
        // vm.manualInput.lotNumberCombined = ("00" + vm.manualInput.lotNumber.part1).slice(-2) + "/" + ("00" + vm.manualInput.lotNumber.part2).slice(-2) + "-" + vm.manualInput.lotNumber.part3 + (vm.manualInput.lotNumber.part4.trim() !== "" ?  "/" + vm.manualInput.lotNumber.part4.trim() : "");
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
        // Save the manual input product to the selected products
        var product = {"id" : "MANUAL-" + new Date().valueOf(), "lotNumber" : vm.manualInput.lotNumberCombined, "price": vm.manualInput.price, "isCharge": vm.manualInput.isCharge, "isNoCharge": vm.manualInput.isNoCharge};
        // Matched lot number products might have additional details
        if (vm.manualInput.name) {
          product.name = vm.manualInput.name;
        }
        if (vm.manualInput.expiryDate) {
          product.expiryDate = vm.manualInput.expiryDate;
        }
        vm.selectedProducts.push(product);
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
        // Save the stock notification into recent items - if it's different to the most recent
        RecentItemsService.getRecentItems("recentStockNotification").then(function(recentItems) {
          var canAddItem = true;
          if (recentItems.length > 0) {
            // If the current stock option matches the last one in our 'recent' list then no need to add
            if (vm.selectedHospital.replaceStockNo && recentItems[0].replaceStockNo) {
              canAddItem = false;
            }
            if ((vm.selectedHospital.replaceStockYes && recentItems[0].replaceStockYes) &&
                (vm.selectedHospital.replaceStockComments.trim() == recentItems[0].replaceStockComments)) {
              canAddItem = false;
            }
          }
          if (canAddItem) {
            var recentItemToSave = {"replaceStockYes": vm.selectedHospital.replaceStockYes, "replaceStockNo": vm.selectedHospital.replaceStockNo, "replaceStockComments":vm.selectedHospital.replaceStockComments.trim()};
            RecentItemsService.addRecentItem("recentStockNotification",recentItemToSave).then(function(recentItems) {
              vm.recentStockNotifications = recentItems;
            });
          }
        });
        // Go to next step
        if (nextStepIfValid == 'selectsurgeon' || nextStepIfValid == 'confirmsurgeon') {
          displaySurgeonSelection(nextStepIfValid);
        } else {
          gotoStep(nextStepIfValid);
        }
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
      // Setup data for next screen
      vm.notification.email = vm.selectedHospital.email;
      if (vm.isFirstTimeThru) {
        vm.notification.isEmail = false;
        vm.notification.isAlternativeEmail = false;
        vm.notification.dontSend = true;
      }
      gotoStep(nextStepIfValid);
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
        // Get the last hospital stock notification user chose
        RecentItemsService.getRecentItems("recentStockNotification").then(function(recentItems) {
          if (recentItems.length > 0) {
            // Populate stock choices using last recent selection
            vm.selectedHospital.replaceStockNo = recentItems[0].replaceStockNo;
            vm.selectedHospital.replaceStockYes = recentItems[0].replaceStockYes;
            vm.selectedHospital.replaceStockComments = recentItems[0].replaceStockComments;
          } else {
            vm.selectedHospital.replaceStockNo = true;
            vm.selectedHospital.replaceStockYes = false;
            vm.selectedHospital.replaceStockComments = "";
          }
          // Save so we can populate stock comments if user changes the stock option during the flow
          vm.recentStockNotifications = recentItems;
        });
      } else {
        vm.selectedHospital.id = hospital.id ? hospital.id : null;
        vm.selectedHospital.name = hospital.name;
        vm.selectedHospital.email = hospital.id ? hospital.email : null;
      }
      // Add hospital to recent list (as long as it's not a new hospital added by user)
      if (hospital.id) {
        RecentItemsService.addRecentHospital(hospital).then(function(recentItems) {
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
        if (vm.allRecentSurgeons) {
          for (var r = 0; r < vm.allRecentSurgeons.length; r++) {
            if (vm.allRecentSurgeons[r].hospitalId == vm.selectedHospital.id) {
              vm.recentSurgeons.push(vm.allRecentSurgeons[r]);
            }
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
        RecentItemsService.addRecentSurgeon(surgeon).then(function(recentItems) {
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
      // console.log("bio removeProduct index",index,vm.selectedProducts);
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
            // Increment analytics
            AnalyticsService.incrementKey("order-form-scan").then(function(result) {
            }).catch(function(e){
              logger.error('OrderFormCtrl scanBarcode AnalyticsService.incrementKey error: ' + JSON.stringify(e));
            });
            // If user cancels the scan they're taken back to the order form start
            if (!imageData.cancelled) {
              processScannedProduct(imageData);
            }
          }, function(err) {
            showAlert("Information","The camera cannot be accessed.<br/><br/>Please check that the Biocomposites app has permission to use the camara.");
            logger.error("scanBarcode: err = " + JSON.stringify(err));
            // Increment analytics
            AnalyticsService.incrementKey("order-form-scan").then(function(result) {
            }).catch(function(e){
              logger.error('OrderFormCtrl scanBarcode AnalyticsService.incrementKey error: ' + JSON.stringify(e));
            });
          });
        },0);
      } else {
        // Increment analytics
        AnalyticsService.incrementKey("order-form-scan").then(function(result) {
        }).catch(function(e){
          logger.error('OrderFormCtrl scanBarcode AnalyticsService.incrementKey error: ' + JSON.stringify(e));
        });
        // For local testing in codeflow, use a fixed product code
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
          exitOrderForm("order-form-cancel");
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
          SyncService.syncTables(['DOF__ap','DOF_Item__ap','Mobile_Log__mc']);
          // Exit
          submitSuccessful = true;
          exitOrderForm("order-form-submit");
        } else {
          // Offline...
          $rootScope.$emit('updateOutboxCount');
          $rootScope.$emit('home:checkOutbox');
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
      }
      if (vm.hospitalRep.lastName !== "") {
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
          // This is a scanned product..or a manually entered product where lot number has been matched
          if (vm.selectedProducts[i].id.includes("MANUAL")) {
            record.Product_Name_from_Lot_Number__c = vm.selectedProducts[i].name;
          } else {
            record.Product__c = vm.selectedProducts[i].id;
          }
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

    function exitOrderForm(analyticPoint) {
      // Increment analytics
      AnalyticsService.incrementKey(analyticPoint).then(function(result) {
      }).catch(function(e){
        logger.error('OrderFormCtrl exitOrderForm AnalyticsService.incrementKey error: ' + JSON.stringify(e));
      });
      // Re-enable menu
      $rootScope.$emit('disableSideMenu', {showSideMenu : true});
      // Re-enable syncing
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
        template: 'Submission successful. Please allow sync to complete before closing app',
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
          exitOrderForm("order-form-submit");
        }
      });
    }

    function processScannedProduct(imageData) {
      // console.log("bio imageData",imageData.text,imageData);
      if (vm.allProducts.length === 0) {
        // Under normal circumstances we wouldn't come in here - vm.allProducts is populated in 'activate'
        $ionicLoading.show({
          duration: 5000,
          template: 'Loading products...',
          animation: 'fade-in',
          showBackdrop: true
        });
        OrderFormService.getProducts().then(function(records) {
          vm.allProducts = records;
          matchProduct(imageData);
          $ionicLoading.hide();
        });
      } else {
        matchProduct(imageData);
      }
    }

    function matchProduct(imageData) {
      // logger.log("scanned code and format: >" + imageData.text + "< >" + imageData.format + "<");
      // Check the image data is the correct format
      if (imageData.format == "CODE_128" || imageData.format == "QR_CODE" || imageData.format == "DATA_MATRIX") {
        // Product code starts at different places for different formats - these formatts have
        // funny chars at front.
        var data = (imageData.format == "QR_CODE" || imageData.format == "DATA_MATRIX") ? imageData.text.substring(1) : imageData.text;
        var scannedProductGTIN = data.substring(2,16);
        // logger.log("extracted GTIN: >" + scannedProductGTIN + "<");
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
          // logger.log("product: " + JSON.stringify(vm.product));
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
        // If user has chosen 'Replace stock to' then...
        // Look for last recent item (for recentStockNotification with replaceStockYes = true) and
        // use it's 'replaceStockComments'
        if (vm.recentStockNotifications) {
          for (var i = 0; i < vm.recentStockNotifications.length; i++) {
            if (vm.recentStockNotifications[i].replaceStockYes) {
              vm.selectedHospital.replaceStockComments = vm.recentStockNotifications[i].replaceStockComments;
              break;
            }
          }
        }
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

    // Event fired when we enter view - regardless of whether it's cached
    var deregisterIonicViewEnter = $scope.$on('$ionicView.enter', function(scopes, states) {
      var forwardView = $ionicHistory.viewHistory().forwardView;
      // Make sure we're not coming back form the order form History list view
      if (!forwardView) {
        // Increment analytics
        AnalyticsService.incrementKey("order-form").then(function(result) {
        }).catch(function(e){
          logger.error('OrderFormCtrl deregisterIonicViewEnter AnalyticsService.incrementKey error: ' + JSON.stringify(e));
        });
      }
    });

    $scope.$on('$destroy', function() {
      // logger.log("OrderFormCtrl destroy");
      // console.log("bio OrderFormCtrl destroy");
      $timeout.cancel(signaturePadTimeout);
      $timeout.cancel(scannerTimeout);
      $timeout.cancel(scrollTimeout);
      $timeout.cancel(onBeginSignatureTimeout);
      $timeout.cancel(onEndSignatureTimeout);
      deregisterIonicViewEnter();
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

  OutboxCtrl.$inject = ['$rootScope', '$scope', '$ionicLoading', '$timeout', 'logger', 'OutboxService', 'RecordTypeService', 'SyncService', 'NetworkService', 'UserService', 'OrderFormService', 'AnalyticsService'];

  function OutboxCtrl($rootScope, $scope, $ionicLoading, $timeout, logger, OutboxService, RecordTypeService, SyncService, NetworkService, UserService, OrderFormService, AnalyticsService)  {
    // logger.log("in OutboxCtrl");
    // console.log("bio in OutboxCtrl");

    var vm = this;
    var leadRecordTypeId;
    var newAccountRecordTypeId;
    var updateOutboxCountTimeout;
    var dirtyRecordsCount;
    var recordsProcessed = 0;
    var dofDirtyCount;

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
      vm.accounts = [];
      // Get lead record type id
      RecordTypeService.getRecordTypeId("Mobile_Lead","Mobile_Dynamic__c").then(function(recordTypeId) {
        leadRecordTypeId = recordTypeId;
        // Get new account record type
        return RecordTypeService.getRecordTypeId("New_Account","Mobile_Dynamic__c");
      }).then(function(recordTypeId) {
        newAccountRecordTypeId = recordTypeId;
        // Get dirty records
        return OutboxService.getDirtyRecords();
      }).then(function(records) {
        dirtyRecordsCount = records.length;
        // If no dirty records then show the 'No records...' message
        if (dirtyRecordsCount === 0) {
          vm.showMsg = true;
          vm.showSyncButton = false;
          vm.syncing = false;
          $ionicLoading.hide();
        } else {
          getDOFDirtyCount(records);
          // Process records and create cards
          for (var i = 0; i < records.length; i++) {
            pushRecordToArray(records[i].Mobile_Table_Name,records[i].SOUP_Record_Id);
          }
        }
        updateOutboxCountTimeout = $timeout(function() {
          // Update the outbox count displayed in the side menu (populated in MenuCtrl)
          $rootScope.$emit('updateOutboxCount');
        },0);
        // Increment analytics
        AnalyticsService.incrementKey("outbox").then(function(result) {
        }).catch(function(e){
          logger.error('OutboxCtrl activate AnalyticsService.incrementKey error: ' + JSON.stringify(e));
        });
      });
    }

    function pushRecordToArray(tableName,soupRecordId) {
      OutboxService.getRecordForSoupEntryId(tableName,soupRecordId).then(function(record) {
        // console.log("bio record",record);
        if (record) {
          if (tableName == "DOF__ap") {
            getAdditionalDOFDetails(record);
          } else if (tableName == "DOF_Item__ap") {
            // If we don't have a dirty DOF then we need to build a card by using the item
            if (dofDirtyCount === 0) {
              // Build a DOF card
              buildDOFCardFromItem(record);
            } else {
              // need to adjust records processed
              $scope.$emit("checkIfAllRecordsProcessed");
            }
          } else {
            if (record.RecordTypeId == leadRecordTypeId) {
              vm.leads.push(record);
              $scope.$emit("checkIfAllRecordsProcessed");
            } else if (record.RecordTypeId == newAccountRecordTypeId) {
              vm.accounts.push(record);
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

    function getAdditionalDOFDetails(record) {
      // Gets the fields generated by Salesforce formula fields: hospital, surgeon and product names
      var surgeonInHospitalRecord;
      var items;
      OrderFormService.getSurgeonInHospital(record.Surgeon__c).then(function(surgeonInHospital) {
        surgeonInHospitalRecord = surgeonInHospital;
        // Try getting order items using Id
        return OrderFormService.getOrderItemsWithOrderId(record.Id);
      }).then(function(orderItems) {
        if (orderItems && orderItems.length > 0) {
          return orderItems;
        } else {
          // Try getting order items using Proxy Id
          return OrderFormService.getOrderItemsWithOrderId(record.MC_Proxy_ID__c);
        }
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
        vm.orders.push({"record": record, "surgeonInHospitalRecord": surgeonInHospitalRecord, "products": displayProducts});
        $scope.$apply();
        $scope.$emit("checkIfAllRecordsProcessed");
        // console.log("bio OutboxCtrl pushRecordToArray vm.orders",vm.orders);
      });
    }

    function getDOFDirtyCount(dirtyRecords) {
      dofDirtyCount = 0;
      for (var i = 0; i < dirtyRecords.length; i++) {
        if (dirtyRecords[i].Mobile_Table_Name == "DOF__ap") {
          dofDirtyCount += 1;
        }
      }
    }

    function buildDOFCardFromItem(orderItem) {
      // Get the DOF orderItem for the item
      OrderFormService.getOrderById(orderItem.DOF__c).then(function(order) {
        // console.log("bio order",order);
        if (order && order.length > 0) {
          // Build the card
          getAdditionalDOFDetails(order[0]);
        } else {
          $scope.$emit("checkIfAllRecordsProcessed");
        }
      });
    }

    function sync() {
      SyncService.syncTables(['DOF__ap','DOF_Item__ap','Mobile_Dynamic__ap','Mobile_Log__mc']);
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
      // logger.log("OutboxCtrl syncTables: " + JSON.stringify(args));
      // console.log("bio OutboxCtrl syncTables: " + JSON.stringify(args));
      if (args && args.result) {
        switch (args.result.toString()) {
          case "StartSync" :
            vm.syncing = true;
            break;
          case "Complete" :
          case "100497" :
          case "100498" :
          case "100402" :
            vm.syncing = false;
            break;
          default :
            if (args.result.toString().indexOf("Error") >= 0) {
              vm.syncing = false;
            } else if (args.result.toString().indexOf("TableComplete") >= 0) {
              var syncedTable = args.result.replace("TableComplete ","");
              if (syncedTable == "Mobile_Dynamic__ap") {
                // Once the Mobile_Dynamic__ap table has synced then refresh page.
                // Mobile_Dynamic__ap is the last table to sync that affects this page
                activate();
              }
            }
        }
      }
    });

    $scope.$on('$destroy', function() {
      // logger.log("OutboxCtrl destroy");
      // console.log("bio OutboxCtrl destroy");
      deregisterHandleSyncTables();
      deregisterHandleCheckRecordProcessed();
      $timeout.cancel(updateOutboxCountTimeout);
    });

  }

})();

/**
 * RawView Controller
 *
 * @description controller for the Raw Data Viewer
 */
(function() {
  'use strict';

  angular
    .module('starter.controllers')
    .controller('RawViewCtrl', RawViewCtrl);

  RawViewCtrl.$inject = ['$scope', '$stateParams', '$ionicLoading', '$ionicModal', 'RecoveryService'];

  function RawViewCtrl($scope, $stateParams, $ionicLoading, $ionicModal, RecoveryService) {

    $ionicLoading.show({
	      duration: 30000,
	      noBackdrop: true,
	      template: '<p id="app-progress-msg" class="item-icon-left"><h3>Loading Data</h3><p>Please wait...</p><ion-spinner></ion-spinner></p>'
	    });

    $scope.type = $stateParams.type;
	  $scope.viewContent = "";

    function activate() {

      console.log(">>> Raw Data View activated. Loading: " + $scope.type);

      switch ($stateParams.type) {
        case 'tables':
          loadTableData();
          break;
        case 'localStorage':
          loadLocalStorageData();
          break;
        case 'soups':
          loadSoupsData();
          break;
        default:
          break;
      }
    }

    function loadTableData() {
      RecoveryService.returnAllTableData().then(function (data) {
        $scope.viewContent = data;
        $ionicLoading.hide();
      });
    }

    function loadSoupsData() {
      RecoveryService.returnAllSoupsData().then(function (data) {
        $scope.viewContent = JSON.stringify(data);
        $ionicLoading.hide();
      });
    }

    function loadLocalStorageData() {
      console.log(">>> loading local storage");
      RecoveryService.returnAllLocalStorageData().then(function (data) {
        console.log(">>> done");
        $scope.viewContent = data;
        $ionicLoading.hide();
      });
    }

    setTimeout(function() {
      activate();
    }, 1000);
    // activate();

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

  RequestCtrl.$inject = ['$rootScope', '$scope', '$ionicPopup', '$state', '$ionicLoading', '$timeout', '$ionicScrollDelegate', '$ionicHistory', 'logger', 'SyncService', 'NetworkService', 'RecordTypeService', 'MobileDynamicService', 'LocalNotificationService', 'AnalyticsService'];

  function RequestCtrl($rootScope, $scope, $ionicPopup, $state, $ionicLoading, $timeout, $ionicScrollDelegate, $ionicHistory, logger, SyncService, NetworkService, RecordTypeService, MobileDynamicService, LocalNotificationService, AnalyticsService) {
    // logger.log("in RequestCtrl");
    // console.log("bio in RequestCtrl");

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
        // Increment analytics
        AnalyticsService.incrementKey("request-"+step).then(function(result) {
        }).catch(function(e){
          logger.error('RequestCtrl gotoStep AnalyticsService.incrementKey error: ' + JSON.stringify(e));
        });
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
        if (!vm.request.requestorEmail || !validateEmail(vm.request.requestorEmail)) {
          showAlert("Error","Please enter a valid e-mail address.");
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
          SyncService.syncTables(['Mobile_Dynamic__ap','Mobile_Log__mc']);
          // Exit
          submitSuccessful = true;
          exitRequest("new-request-submit");
        } else {
          // Offline...
          $rootScope.$emit('updateOutboxCount');
          $rootScope.$emit('home:checkOutbox');
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
      // Set other required checkboxes
      request.Alternate_Billing_Address__c = false;
      request.STIMULAN_Bullet__c = false;
      request.STIMULAN_Kit_10cc__c = false;
      request.STIMULAN_Kit_5cc__c = false;
      request.STIMULAN_Rapid_Cure_10cc__c = false;
      request.STIMULAN_Rapid_Cure_20cc__c = false;
      request.STIMULAN_Rapid_Cure_5cc__c = false;
      request.Other_Product__c = false;
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
          exitRequest("new-request-cancel");
        }
      });
    }

    function exitRequest(analyticPoint) {
      // Increment analytics
      AnalyticsService.incrementKey(analyticPoint).then(function(result) {
      }).catch(function(e){
        logger.error('RequestCtrl exitRequest AnalyticsService.incrementKey error: ' + JSON.stringify(e));
      });
      // Re-enable menu
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
        template: 'Submission successful. Please allow sync to complete before closing app',
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
          exitRequest("new-request-submit");
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

    // Event fired when we enter view - regardless of whether it's cached
    var deregisterIonicViewEnter = $scope.$on('$ionicView.enter', function(scopes, states) {
      var forwardView = $ionicHistory.viewHistory().forwardView;
      // Make sure we're not coming back form the History list view
      if (!forwardView) {
        // Increment analytics
        AnalyticsService.incrementKey("request").then(function(result) {
        }).catch(function(e){
          logger.error('RequestCtrl deregisterIonicViewEnter AnalyticsService.incrementKey error: ' + JSON.stringify(e));
        });
      }
    });

    $scope.$on('$destroy', function() {
      // logger.log("RequestCtrl destroy");
      // console.log("bio RequestCtrl destroy");
      deregisterIonicViewEnter();
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

  RequestHistoryCtrl.$inject = ['$rootScope', '$scope', '$window', '$ionicLoading', '$ionicModal', '$state', 'logger', 'RecordTypeService', 'MobileDynamicService', 'AnalyticsService'];

  function RequestHistoryCtrl($rootScope, $scope, $window, $ionicLoading, $ionicModal, $state, logger, RecordTypeService, MobileDynamicService, AnalyticsService) {
    // logger.log("in RequestHistoryCtrl");
    // console.log("bio in RequestHistoryCtrl");

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
        // console.log("bio vm.requests",vm.requests);
        $ionicLoading.hide();
        // Increment analytics
        AnalyticsService.incrementKey("request-history").then(function(result) {
        }).catch(function(e){
          logger.error('RequestHistoryCtrl activate AnalyticsService.incrementKey error: ' + JSON.stringify(e));
        });
      });
    }

    function showModal(record) {
      $ionicModal.fromTemplateUrl($window.RESOURCE_ROOT + "templates/requestDetail.html", {
        scope: $scope,
        animation: 'slide-in-up'
      }).then(function(modal) {
        vm.modal = modal;
        vm.modal.request = record;
        // console.log("bio showModal vm.modal.request",vm.modal.request);
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
      // logger.log("RequestHistoryCtrl syncTables: " + JSON.stringify(args));
      // console.log("bio RequestHistoryCtrl syncTables: " + JSON.stringify(args));
      if (args.result.toString().indexOf("TableComplete") >= 0) {
        var syncedTable = args.result.replace("TableComplete ","");
        if (syncedTable == "Mobile_Dynamic__ap") {
          activate();
        }
      }
    });

    $scope.$on('$destroy', function() {
      // logger.log("RequestHistoryCtrl destroy");
      // console.log("bio RequestHistoryCtrl destroy");
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

	SettingsCtrl.$inject = ['$scope', '$rootScope', '$ionicPopup', '$ionicLoading', '$location', '$state', 'devUtils', 'vsnUtils', 'DevService', 'logger', 'RecoveryService', 'SyncService', 'NetworkService', '$timeout', 'OutboxService', 'AnalyticsService'];

	function SettingsCtrl($scope, $rootScope, $ionicPopup, $ionicLoading, $location, $state, devUtils, vsnUtils, DevService, logger, RecoveryService, SyncService, NetworkService, $timeout, OutboxService, AnalyticsService) {

    // Increment analytics
    AnalyticsService.incrementKey("app-settings").then(function(result) {
    }).catch(function(e){
      logger.error('SettingsCtrl AnalyticsService.incrementKey error: ' + JSON.stringify(e));
    });

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
	  	var tables2;
	  	if (tables) {
	  		tables2 = tables.filter(function(table){
		  		return table != "Mobile_Log__mc";
		  	});
	  	}
	    if (tables2 && tables2.length === 0) {
	      $scope.upgradeAvailable = true;
				$timeout(function() {
          $scope.$apply();
        }, 0);
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


	  $scope.networkStatusLS = NetworkService.getNetworkStatus();

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
	    Recovery
	  ---------------------------------------------------------------------------
	  */

    $scope.recoverAllData = function() {
      $ionicLoading.show({
  	      duration: 60000,
  	      noBackdrop: true,
  	      template: '<p id="app-progress-msg" class="item-icon-left"><h3>Recovering Data</h3><p>Please do not close the app until complete…</p><ion-spinner></ion-spinner></p>'
  	    });

      RecoveryService.recoverAllData().then(function() {
        $ionicLoading.hide();
        showAlert('Success', 'Recovery Completed. Please transfer recovered data from device.');
      }).catch(function (error) {
        $ionicLoading.hide();
        showAlert('Error', 'Error recovering data.');
      });
    };

    function showAlert(title, message) {
      var alert = $ionicPopup.alert({
        title: title,
        template: message,
        cssClass: 'bio-popup'
      });
      alert.then(function() {

      });
    }

	  /*
	  ---------------------------------------------------------------------------
	    Log in/out
	  ---------------------------------------------------------------------------
	  */
	  $scope.showAdminPasswordPopup = function() {
	  	if (LOCAL_DEV) {
	  		$location.path('app/settings/devtools');
	  		$rootScope.adminLoggedIn  = Date.now();
	  	} else {
	  		var supportPin = DevService.generateSupportPin();
	  		var adminTimeout = (1000 * 60 * 30); // 30 minutes
		    if ( $rootScope.adminLoggedIn > Date.now() - adminTimeout) {
		      $location.path('app/settings/devtools');
		      $rootScope.adminLoggedIn = Date.now();
		      $scope.$apply();
		    } else {
		      $scope.data = {};
		      var myPopup = $ionicPopup.show({
		        template: '<p>Pass this support PIN to your admin: <em>' + supportPin +'</em></p><p>They will provide you with an access PIN, to enter here:</p><input type="password" ng-model="data.admin">',
		        title: 'Enter Access PIN',
		        scope: $scope,
		        buttons: [
		          { text: 'Cancel' },
		          { text: '<b>Continue</b>',
		            type: 'button-positive',
		            onTap: function(e) {
			            DevService.authenticate(supportPin, $scope.data.admin).then(function(result){
			            	if ( result ) {
			            		$location.path('app/settings/devtools');
			                $rootScope.adminLoggedIn = Date.now();
			                $scope.$apply();
			              } else {
			                console.log("Password incorrect");
			              }
			            }).catch(function(e){
			            	logger.error(e);
			            });
		            }
		          },
		        ]
		      });
		    }
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
	       devUtils.logout();
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

  TestingCtrl.$inject = ['$scope', '$cordovaLocalNotification', 'AppRunStatusService', 'logger', 'LocalNotificationService','DiagnosticService'];

  function TestingCtrl($scope, $cordovaLocalNotification, AppRunStatusService, logger, LocalNotificationService,DiagnosticService) {

	  $scope.resumeEvent = function() {
	    console.debug("resumeEvent");
	    AppRunStatusService.statusEvent('resume');
	  };

    $scope.testHeartbeat = function() {
      console.debug("testHeartbeat");
      $scope.testTitle = "Heartbeat in progress...";
      DiagnosticService.testVfRemote().then(function(res){
        $scope.testTitle = "Heartbeat result";
        $scope.testResults = {
          result: JSON.stringify(res.result),
          event: JSON.stringify(res.event)
        };
        $scope.$apply();
      }).catch(function(e){
        // Convert Error type to std object, if it is one - as it does not play nice with JSON.stringify
        var err = {};
        if (e instanceof Error) {
          Object.getOwnPropertyNames(e).forEach(function(key) {
            err[key] = e[key];
          });
        } else {
          err = e;
        }
        $scope.testTitle = "Heartbeat Errored";
        $scope.testResults = {
          result: "-",
          event: "-",
          error: JSON.stringify(err)
        };
        $scope.$apply();
        logger.error("testHeartbeat", err);
      });
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

  TutorialCtrl.$inject = ['$rootScope', '$scope', '$state', '$window', '$timeout', 'logger', 'UserService', 'AnalyticsService'];

  function TutorialCtrl($rootScope, $scope, $state, $window, $timeout, logger, UserService, AnalyticsService) {
    // logger.log("in TutorialCtrl");
    // console.log("bio in TutorialCtrl");

    var vm = this;
    var showButtonsTimeout;
    var showSettingsMenuTimeout;
    var updateButtonTextOnResizeTimeout;

    vm.startAppFromImageTap = startAppFromImageTap;

    vm.slides = [];
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial1.JPG", "heading": "Welcome to the Biocomposites' <span class='bio-line-break-on-small-device'>Distributor Hub.</span>"});
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial2.JPG", "heading": "Providing easy, offline access to <span class='bio-line-break-on-small-device'>the tools you need.</span>"});
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial3.JPG", "heading": "Applications and cases at your <span class='bio-line-break-on-small-device'>fingertips.</span>"});
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial4.JPG", "heading": "On-label answers to your <span class='bio-line-break-on-small-device'>surgeons' questions.</span>"});
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial5.JPG", "heading": "e-learning modules to grow your <span class='bio-line-break-on-small-device'>knowledge.</span>"});
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial6.JPG", "heading": "…and regular news updates to <span class='bio-line-break-on-small-device'>keep you informed.</span>"});
    vm.slides.push({"image": $window.RESOURCE_ROOT + "images/tutorial7.JPG", "heading": "Let's get started."});

    // Workaround for small devices truncating title (when header button's text is long):
    // Hide the buttons initially - this allows the title to be rendered full width on small devices.
    // Show the buttons using a timeout after page is entered and angular has done it's stuff.
    vm.showButtons = false;

    vm.leftButtonClick = leftButtonClick;
    vm.rightButtonClick = rightButtonClick;

    var deregisterIonicViewAfterEnter = $scope.$on('$ionicView.afterEnter', function(scopes, states) {
      showButtonsTimeout = $timeout(function() {
        setButtonText();
        vm.showButtons = true;
      },0);
      // register window resize event
      angular.element($window).on('resize', windowResizeHandler);
      // Increment analytics
      AnalyticsService.incrementKey("tutorial").then(function(result) {
      }).catch(function(e){
        logger.error('TutorialCtrl deregisterIonicViewAfterEnter AnalyticsService.incrementKey error: ' + JSON.stringify(e));
      });
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
      // logger.log("TutorialCtrl syncTables: " + JSON.stringify(args));
      // console.log("bio TutorialCtrl syncTables: " + JSON.stringify(args));
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
      // logger.log("TutorialCtrl destroy");
      // console.log("bio TutorialCtrl destroy");
      deregisterHandleSyncTables();
      deregisterIonicViewAfterEnter();
      deregisterIonicViewLeave();
      $timeout.cancel(showButtonsTimeout);
      $timeout.cancel(updateButtonTextOnResizeTimeout);
      $timeout.cancel(showSettingsMenuTimeout);
      vm.slider.off('slideNextStart');
      vm.slider.off('slidePrevStart');
    });

  }

})();