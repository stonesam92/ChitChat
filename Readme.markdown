#WhatsMac

A Mac app wrapper around WhatsApp's web client, [WhatsApp Web](https://web.whatsapp.com). 

The latest version is available [here](https://github.com/stonesam92/WhatsMac/releases/latest). Need help? Ask me on Twitter [here](https://twitter.com/cmdshiftn).

Requires OSX 10.10 Yosemite and a WhatsApp Web compatible device (ie. **not** an iPhone unfortunately, [unless you're jailbroken](http://www.igeeksblog.com/how-to-setup-and-use-whatsapp-web-with-iphone/))
  
![WhatsMac Screenshot](http://i.imgur.com/riXrTvx.jpg "WhatsMac Screenshot")

> Disclaimer: This is NOT an official WhatsApp Product, it is only a hobby project created by myself

Allows you to receive notification center notifications for new messages, and adds some useful keyboard shortcuts:

| Feature                                        | Shortcut  |
|------------------------------------------------|-----------|
| Start a new conversation                       | ⌘N        |
| Search past conversations                      | ⌘F        |
| Jump to your 1st .. 9th most recent converation| ⌘1 .. ⌘9  |

Inspired by, and in small part based on, [Messenger for Mac](http://fbmacmessenger.rsms.me/), created by [Rasmus Andersson](https://twitter.com/rsms). WhatsMac uses some code from this project.

##Feature Support

Most features of WhatsApp Web are currently supported, and support for the remainder is being actively developed:

| Feature                                 | Working?  |
|-----------------------------------------|-----------|
| Text chat                               | YES       |
| Attached media viewing                  | YES       |
| Attached media downloading              | YES       |
| Notification center notifications       | YES       |
| Media uploading                         | NO\*       |
| Media recording (using camera + mic.)   | NO        |

\*Media uploading **is** supported when dragging the image/video file into the app's window. Uploading using the upload button is currently not supported, since WKWebView provides no easy mechanism for using `<input type="file">` tags.

**Note**: the app is not signed with an Apple developer cert. If you have Gatekeeper enabled, the first time you run it you must right click the app in Finder and select "Open".

##Note To WhatsApp

Given the [recent situation regarding WhatsAPI](https://github.com/venomous0x/WhatsAPI), I feel obliged to stress that this project does **not** attempt to reverse engineer the WhatsApp API or attempt to reimplement any part of the WhatsApp client's communications with the WhatsApp servers. 

Any communication between the user and WhatsApp servers is handled by WhatsApp Web itself; this is merely a native wrapper for WhatsApp Web, more akin to a clone of Safari than of any WhatsApp software.

Having read the WhatsApp EULA, I believe that, since this project does not make any attempt to reverse engineer or automate any parts of the WhatsApp service, it is compliant with WhatsApp's terms of service.

If this is not the case, please contact me at stonesam92@gmail.com and I will take down the project.

##License
  
  
Copyright (c) 2015 Authors of the source code of this project

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
