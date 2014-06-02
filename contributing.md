How We Work Together
==
The CSIRT Gadgets Community uses the [C4 process](https://github.com/csirtgadgets/c4) for it's core projects. If you contribute a nice patch and you have some GitHub reputation we'll invite you to join the Maintainer's team. We strive to adopt most [if not all] of the wonderful outcomes the [ZMQ community](http://zguide.zeromq.org/page:all#toc130) has pionneered. If you're not familar with it, please read up on it's architecture and history, it's a great story!

GitHub also has a [great piece](https://guides.github.com/activities/contributing-to-open-source) on the nuances associated with contributing to opensource projects. If you've never worked within a github project before, this is a great "where do i start?".

Our Process
===

* Log an issue that explains the problem you are solving.
* Provide a test case unless absolutely impossible.
* Get familar with [GitHub](https://help.github.com/articles/set-up-git) and [GitFlow](http://datasift.github.io/gitflow/IntroducingGitFlow.html)
* We always need an issue, test case and [pull-request](https://help.github.com/articles/using-pull-requests).
* Make your change as a pull request (see below).
* Discuss on the mailing list as needed.
* Close the issue when your pull request is merged and the test case passes. 

Separate Your Changes
===
Separate different independent logical changes into separate commits (and thus separate patch submissions) when at all possible. This allows each change to be considered on it's own merits. Also, it is easier to review a batch of independent [smaller] changes rather than one large patch.

Write Good Commit Messages
===
Commit messages become the public record of your changes, as such it's important that they be well-written. The basic format of git commit messages is:

* A single summary line. This should be short — no more than 70 characters or so, since it can be used as the e-mail subject when submitting your patch and also for generating patch file names by 'git format-patch'. If your change only touches a single file or subsystem you may wish to prefix the summary with the file or subsystem name.
* A blank line.
* A detailed description of your change. Where possible, write in the present tense, e.g. "Add assertions to funct_foo()". If your changes have not resulted from previous discussion on the mailing list you may also wish to include brief rationale on your change. Your description should be formatted as plain text with each line not exceeding 80 characters.

Give Yourself Credit
===
Add yourself to the AUTHORS file or other lists of contributors for the project, with your commit. The maintainers won't do this, it's your choice whether you consider your patch worth a mention, or not.

You must make contributions under your real name, associated with your github account. Anonymous contributions may be made via proxies, ask on IRC if someone will help you.

Copyrights and Licenses
===
Make sure your contributions do not include code from projects with incompatible licenses. Our projects mostly use the LGPLv3 with a static linking exception. If your code isn't compatible with this, it will sooner or later be spotted and removed. The best way to avoid any license issues is to write your own code.

Test Cases
===
For stable releases, patches (if they change the behavior of the code) must have issues, and test cases.
