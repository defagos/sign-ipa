### What is sign-ipa?

sign-ipa is a shell script with which you can sign an existing ipa using another provisioning profile, without having to build the application again. The Info.plist can be edited at the same time if needed.

For example, you can use this tool to:

* sign an application with several different provisioning profiles. This is for example useful if you sign your application both for ad-hoc and enterprise distribution
* update bundle information, e.g. the bundle version number. This is especially useful if you distribute your application using an integrated updater (e.g. Hockey Updater) which checks the version number against some (private) application store your company may provide. If all the changes are located in the Info.plist file or in the provisioning profile, you can therefore create a new version without having to rebuild the application, for the sole purpose of deploying it to your customers

### How should I use sign-ipa?

Simply save the sign-ipa.sh Bash script somewhere (ideally in your PATH) and give it execution permissions if needed (chmod +x sign-ipa.sh). Execute it with the -h parameter for help.

### Acknowledgements
Thanks to Pierre-Yves Bertholon (https://github.com/pyby) for his suggestions and explanations

### Release notes

#### Version 1.0
Initial release

### Contact
Feel free to contact me if you have any questions or suggestions:

* mail: defagos ((at)) gmail ((dot)) com
* Twitter: @defagos

Thanks for your feedback!

### Licence

Copyright (c) 2012 hortis le studio, Samuel Défago

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
