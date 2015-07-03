// injected into the weview as a user script
jQuery.noConflict();
jQuery(document).on("click", "input[type='file']", function() {
                    alert("To upload media, drag and drop the file into the WhatsApp Web window.");
                    });

this.Notification = function(title, options) {
    n = [title, options];
    console.log(options);
    webkit.messageHandlers.notification.postMessage([title, options.body]);
};
this.Notification.permission = 'granted';
this.Notification.requestPermission = function(callback) {callback('granted');};


var styleAdditions = document.createElement('style');
styleAdditions.textContent = 'div.pane-list-user {opacity:0;} \
div.app-wrapper::before {opacity: 0;} \
div.drawer-title {left:60px; bottom:17px;} \
div.chat.media-chat > div.chat-avatar { opacity: 0; } \
div.app.two { top: 0px; width: 100%; height: 100%; } \
div.app.three { top: 0px; width: 100%; height: 100%; } \
div.pane.pane-chat { width : 100%; } \
div.pane.pane-intro { width : 100%; } \
';
document.documentElement.appendChild(styleAdditions);

function activateSearchField() {
    document.querySelector('input.input-search').focus();
}

function newConversation() {
    document.querySelector('button.icon-chat').click();
    document.querySelector('input.input-search').focus();
    
    var header=document.querySelector('div.drawer-title');
    header.style.left = '0px';
    header.style.bottom = '12px';
}

function setActiveConversationAtIndex(index) {
    //scroll to top of the conversation list
    var conversationList = document.querySelector('div.pane-list-body');
    if (conversationList.scrollTop == 0) {
        document.querySelector('div:nth-child('+index+').infinite-list-item').firstChild.click();
    } else {
        new MutationObserver(function() {
                             document.querySelector('div:nth-child('+index+').infinite-list-item').firstChild.click();
                             this.disconnect();
                             }).observe(conversationList, {attributes: true, childList: true, subtree: true});
    }
    conversationList.scrollTop = 0;
}

jQuery(function () {
    (function ($) {
        $(document).keydown(function (event) {
            var direction = null;
            switch (event.which) {
                case 38:
                    direction = 'UP';
                    break;
                case 40:
                    direction = 'DOWN';
                    break;
                default:
                    break;
            }
            var $input = $('.input');
            var isInputFieldEmpty = $input.contents().length === 0 ||
                                    $input.contents()[0].nodeName === 'BR';
            if (direction && isInputFieldEmpty) {
                var $selectedItem = null;
                $.each($('.infinite-list-viewport .infinite-list-item'), function (index, value) {
                    var $this = $(this);
                    if ($this.children('.chat').hasClass('active')) {
                        $selectedItem = $this;
                        return false;
                    }
                });
                if ($selectedItem) {
                    var $desiredItem = direction === 'UP' ? $selectedItem.prev() : $selectedItem.next();
                    if ($desiredItem.length > 0) {
                        $desiredItem[0].firstChild.click();
                    }
                }
            }
        });
    })(jQuery);
});
