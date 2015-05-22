// injected into the weview as a user script

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
