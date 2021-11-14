/* global Vue */
/* global data */

var vm = new Vue({
  el: '#vm',
  data: {
    username: 'Test',
    sforce: false,
    pdf: false,
    pdfurl: '',
    database: {
      topics: [],
      featured: [
        {
          brainsharkURL: '',
          urlForImage: '',
          title: '',
          textForBrainsharkTitle: '',
          videoURL: '',
          Video_thumbnail_URL__c: '',
          title: '',
          altTag: '',
          LINK: ''
        }
      ],
      collateral: [],
      sales: [],
      account: [],
      learning: [
        {
          brainsharkURL: '',
          urlForImage: '',
          title: '',
          textForBrainsharkTitle: ''
        }
      ],
      internal: [],
      videos: [
        {
          videoURL: '',
          Video_thumbnail_URL__c: '',
          title: '',
          altTag: ''
        }
      ],
      publishing: []
    },
    navigation: false,
    loaded: false,
    selected_video: '',
    width: 0,
    colors: '',
    image: '',
    height: 0,
    shift: 0,
    video: false,
    position: 0,
    shown: 'none',
    see_internal: '',
    see_pub: '',
    show_abstract: false,
    total: 0,
    selected_paper: {
      title: '',
      authorPub: '',
      publishers: '',
      abstractPub: '',
      ourView: ''
    },
    pages: 0,
    page: '',
    selected_page: 1,
    search: '',
    profile: '',
    section_width: ''
  },
  watch: {
    'selected_page': function (newV, oldV) {
      vi.getPapers(vm.selected_page).then(function (res) {
        vm.database.publishing = res;
      })
    },
    'navigation': function (val) {
      if (val == true && vm.width <= 800) {
        document.getElementsByTagName('body')[0].style.overflow = 'hidden';
      } else {
        document.getElementsByTagName('body')[0].style.overflow = 'auto';
      }
    }
  },
  methods: {
    // called on resize event
    resize: function () {
      if (document.getElementById('vm')) {
        document.getElementById('vm').width = window.innerWidth;
        vm.height = document.getElementById('vm').clientHeight;
      }
      if (document.getElementById('bc-content')) {
        document.getElementById('bc-content').width = document.getElementById('vm').width
      }
      vm.width = window.innerWidth;
      if (vm.width > 1360) {
        vm.shift = 'calc(((100% - 974px) / 2) - 200px)';
      }
      if (vm.width < 1360 && vm.width > 960) {
        vm.shift = 'calc((100% - 974px) / 2)';
      }
      if (vm.width < 960) {
        vm.shift = '0px'
      }
      if (document.getElementById('bc-video-viewer') && vm.video == true) {
        vm.check();
      }
    },
    // checks oddness 
    odd: function (num) {
      var returner = num % 2 == 0 ? true : false;
      return returner;
    },
    // gets video width for clsoe button position
    check: function () {
      setTimeout(function () {
        var el = document.getElementById('video-viewer');
        vm.position = 'calc(50% - ' + el.clientWidth / 2 + 'px)';
        vm.shown = 'block';
      }, 100);
    },
    // process html string
    content: function (content, clone) {
      var element = document.createElement('div');
      if (content !== undefined) {
        var preprocess = content.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&').replace(/&quot;/g, '"');
        var process = vm.stripper(preprocess);
        if (process.split('<br>')) {
          var chunks = process.split('<br>');
          var classname = clone ? 'content-clone' : 'content';
          element.setAttribute('class', classname);
          for (var a = 0; a < chunks.length; a++) {
            if (chunks[a].replace(/\s/g, '').length !== 0 && chunks[a].indexOf('</a>') == -1) {
              var el = document.createElement('p');
              el.innerText = chunks[a].replace(/<i>/g, '').replace(/<\/i>/g, '');
              element.appendChild(el);
            }
            if (chunks[a].indexOf('</a>') !== -1) {
              var links = chunks[a].split('<a');
              var content = chunks[a].split('<a')[0].replace(/\<u\>/g, '');
              var href = '';
              for (var b = 0; b < links.length; b++) {
                var slices = links[b].split('>');
                for (var c = 0; c < slices.length; c++) {
                  var slice = slices[c];
                  if (slice.indexOf('</a') !== -1) {
                    content += slice.replace('</a', '');
                  }
                  if (slice.indexOf('href') !== -1) {
                    href = slice.split('href="')[1].split('"')[0]
                  }
                }
              }
              var tag = document.createElement('a');
              tag.setAttribute('href', href);
              tag.setAttribute('target', '_blank');
              tag.setAttribute('onclick', '(function(e) { e.stopPropagation() })(event)')
              tag.innerText = content;
              element.appendChild(tag);
            }
          }
        }
      }
      return element;
    },
    // need to manually append topics as the content processor doesnt always render until screen changes on vue
    append: function () {
      document.getElementById('vm').width = window.innerWidth;
      if (document.getElementById('bc-content')) {
        document.getElementById('bc-content').width = document.getElementById('vm').width
      }
      if (document.getElementById('toi')) {
        var parent = document.getElementById('toi');
        var newlength = 0;
        // home - desktop
        if (vm.width > 800 && vm.page == 'home') {
          newlength = 5;
        } else
        // home - mobile
        if (vm.width <= 800 && vm.page == 'home') {
          newlength = 3;
        } else {
          // other
          newlength = vm.database.topics.length;
        }
        for (var a = 0; a < newlength; a++) {
          var record = vm.database.topics[a];
          var container = document.createElement('div');
          container.className = 'bc-section';
          if (vm.width <= 800) {
            container.style.width = (vm.width - 40) + 'px';
          }
          container.setAttribute('vm-toggled', false);
          container.setAttribute('onclick', 'vm.toggle(this)');
          var header = document.createElement('h4');
          header.innerText = vm.stripper(record.title);
          if (record.newItem == true) {
            var span = document.createElement('span');
            span.innerText = ' (new)';
            header.appendChild(span);
          }
          var content = document.createElement('p');
          content.appendChild(vm.content(record.content));
          content.appendChild(vm.content(record.content, true));
          container.appendChild(header);
          container.appendChild(content);
          parent.appendChild(container);
        }
        if (document.getElementById('toi')) {
          var fake = document.getElementById('fake');
          document.getElementById('toi').removeChild(fake);
        }
        vm.set_ellipsis();
        vm.loaded = true;
        setTimeout(function () {
          vm.resize();
        }, 500);
      } else {
        if (document.getElementById('toi')) {
          var fake = document.getElementById('fake');
          document.getElementById('toi').removeChild(fake);
        }
        this.loaded = true;
        setTimeout(function () {
          vm.resize();
        }, 500);
      }
    },
    toggle: function (el) {
      var previous = el.className;
      var els = document.getElementsByClassName('bc-section');
      for (var a = 0; a < els.length; a++) {
        els[a].className = 'bc-section'
      }
      el.className = previous == 'bc-section' ? 'bc-section expand' : 'bc-section';
    },
    stripper: function (val) {
      if (val && typeof val !== undefined) {
        var newval = val.replace(/&#39;/g, "'").replace(/<span style="font-family: arial,sans-serif;">/g, '').replace(/<span style="font-size: 10pt;">/g, '').replace(/<\/span>/g, '').replace(/<span style="color: #070809;">/g, '').replace(/<span style="font-size: 9.0pt;">/g, '').replace(/<ul>/g, '').replace(/<li>/g, '').replace(/<\/li>/g, '').replace(/<\/ul>/g, '').replace(/<b>/g, '').replace(/<\/b>/g, '').replace(/<span style="font-size: 10.0pt;">/g, '').replace(/<span>/g, '').replace(/&amp;/g, '&').replace(/<div>/g, '').replace(/<\/div>/g, '');
        return newval;
      } else {
        return '';
      }
    },
    domain: function (url) {
      var href = window.location.href;
      var domain = href.split('.com')[0];
      domain += '.com' + url;
      return domain;
    },
    create_video: function (url) {
      var parent = document.getElementById('video-holder');
      var video = document.createElement('video');
      video.setAttribute('controls', true);
      video.setAttribute('id', 'video-viewer');
      var source = document.createElement('source');
      source.setAttribute('src', url);
      source.setAttribute('type', 'video/mp4');
      var object = document.createElement('object');
      object.setAttribute('data', url);
      video.appendChild(source);
      video.appendChild(object);
      parent.appendChild(video);
      video.play();
      vm.check();
    },
    remove_video: function () {
      var parent = document.getElementById('video-holder');
      var video = document.getElementById('video-viewer');
      video.pause();
      parent.removeChild(video);
    },
    select_abstract: function (record) {
      for (var a = 0; a < vm.database.publishing.length; a++) {
        vm.database.publishing[a].selected = false;
      }
      if (record == 'none') {
        vm.selected_paper = '';
        vm.show_abstract = false;
      } else {
        record.selected = true;
        vm.selected_paper = record;
        vm.show_abstract = true;
      }
    },
    send_search: function () {
      vm.loaded = false;
      vm.database.publishing = [];
      var search = vm.search;
      var keywords = search.split(',');
      console.log(keywords);
      vi.getSearch(keywords).then(function (results) {
        vm.database.publishing = results;
        vm.total = results.length;
        vm.pages = [];
        var def = (results.length - (results.length % 10)) / 10;
        var extra = results.length % 10 == 0 ? 0 : 1;
        for (var a = 1; a <= (def + extra); a++) {
          vm.pages.push(a);
        }
        vm.loaded = true;
      })
    },
    reset_search: function () {
      console.log('called?');
      vi.getPapers(1).then(function (res) {
        vm.database.publishing = res;
        vi.getTotal().then(function (results) {
          vm.total = results;
          vm.pages = [];
          var def = (results - (results % 10)) / 10;
          var extra = results % 10 == 0 ? 0 : 1;
          for (var a = 1; a <= (def + extra); a++) {
            vm.pages.push(a);
          }
        })
      })
    },
    select_page: function (val) {
      if (val == 'next') {
        vm.selected_page = vm.selected_page == vm.pages ? vm.pages : vm.selected_page + 1;
      } else if (val == 'prev') {
        vm.selected_page = vm.selected_page == 1 ? 1 : vm.selected_page - 1;
      } else {
        vm.selected_page = val;
      }
    },
    set_ellipsis: function (el) {
      setTimeout(function () {
        var els = document.getElementsByClassName('content-clone');
        for (var a = 0; a < els.length; a++) {
          var el = els[a];
          var wordArray = el.innerHTML.split(" ");
          while (el.scrollHeight > el.offsetHeight) {
            wordArray.pop();
            el.innerHTML = wordArray.join(" ") + ("...");
          }
        }
      }, 0);
    },
    check_enter: function (ev) {
      if (ev.keyCode == 13) {
        vm.send_search();
      }
    },
    open_pdf: function (url) {
      
      return window.open(url, '_system');
      
      if ((typeof sforce != 'undefined') && (sforce != null)) {
        window.location.href = url;
      } else {
        window.open(url, '_blank');
      }
    }
  },
  // add our body events before starting
  beforeCreate: function () {
    var el = document.getElementsByTagName('body')[0];
    el.setAttribute('onload', 'vm.resize()');
    el.setAttribute('onresize', 'vm.resize()');
    if (document.getElementById('vm')) {
      document.getElementById('vm').width = window.innerWidth;
      this.height = document.getElementById('vm').clientHeight;
    }
    if (document.getElementById('bc-content')) {
      document.getElementById('bc-content').width = document.getElementById('vm').width
    }
    this.width = window.innerWidth;
    console.log(this.width);
  },
  // when ready
  mounted: function () {
    this.database.featured = data.featured;

    if ((typeof sforce != 'undefined') && (sforce != null)) {
      this.sforce = true;
    } else {
      this.sforce = false;
    }

    this.section_width = (document.getElementById('vm').clientWidth / 2) - 30;

    if (typeof vi !== 'undefined') {
      vi.getData().then(function (results) {
        vm.colors = results.colors;
        vm.image = results.image;
        vm.see_internal = results.internal;
        vm.see_pub = results.pub;
        vm.profile = results.profile;
        if (results.topics) {
          vm.database.topics = results.topics
        };
        if (results.marketing) {
          for (var a = 0; a < results.marketing.length; a++) {
            if (!results.marketing[a]['subType']) {
              results.marketing[a]['subType'] = 'Standard'
            }
          }
          vm.database.marketing = results.marketing
        };
        if (results.name) {
          vm.username = results.name;
        }
        if (results.page) {
          vm.page = results.page
        }
        if (results.sales) {
          vm.database.sales = results.sales
        };
        if (results.learning) {
          for (var a = 0; a < results.learning.length; a++) {
            var string = decodeURI(results.learning[a].brainsharkURL);
            results.learning[a].brainsharkURL = string;
          }
          vm.database.learning = results.learning
        };
        if (results.account) {
          for (var a = 0; a < results.account.length; a++) {
            if (results.account[a].subType == 'External Documents') {
              results.account[a].subType = 'Dark';
            }
            if (results.account[a].subType == 'Internal Documents') {
              results.account[a].subType = 'Light';
            }
          }
          vm.database.account = results.account
        };
        if (results.featured) {
          if (results.featured[0].buttonLinkURL) {
            results.featured[0]['LINK'] = vm.domain(results.featured[0].buttonLinkURL);
          } else {
            results.featured[0]['LINK'] = vm.stripper(results.featured[0].brainsharkURL);
          }
          vm.database.featured = results.featured;
        }
        if (results.internals) {
          vm.database.internals = results.internals
        };
        if (results.publishing) {
          for (var a = 0; a < results.publishing.length; a++) {
            results.publishing[a]['selected'] = false
          }
          vm.database.publishing = results.publishing
        }
        if (results.total) {
          vm.total = results.total;
          vm.pages = [];
          var def = (results.total - (results.total % 10)) / 10;
          var extra = results.total % 10 == 0 ? 0 : 1;
          for (var a = 1; a <= (def + extra); a++) {
            vm.pages.push(a);
          }
        }
        if (results.videos) {
          /*for (var a = 0; a < results.videos.length; a++) {
            results.videos[a].videoURL = vm.domain(results.videos[a].videoURL)
          };*/
          vm.database.videos = results.videos
        };
        vm.append();
      });
    } else {
      this.database = data;
      this.append();
    }
  }
});