# Contributing to this project

Please take a moment to review this document in order to make the contribution
process easy and effective for everyone involved.

Following these guidelines helps to communicate that you respect the time of
the project maintainers who give their time to share this project freely. 
In return, the maintainers will reciprocate that respect in addressing your 
issue or assessing your pull requests.

_**Please Note:** These guidelines are adapted from [@necolas](https://github.com/necolas)'s 
[issue-guidelines](https://github.com/necolas/issue-guidelines) and serve as
an excellent starting point for contributing to any open source project._


## Using the issue tracker

The issue tracker is the preferred channel for [bug reports](#bugs),
[features requests](#features) and [submitting pull
requests](#pull-requests), but please respect the following restrictions:

* Please **do not** use the issue tracker for personal support requests (use
  [Stack Overflow](http://stackoverflow.com) or IRC).

* Please **do not** derail or troll issues. Keep the discussion on topic and
  respect the opinions of others.


<a name="bugs"></a>
## Bug reports

A bug is a _demonstrable problem_ that is caused by the code in the repository.
Good bug reports are extremely helpful - thank you!

Guidelines for bug reports:

1. **Use the GitHub issue search** &mdash; check if the issue has already been
   reported.

2. **Check if the issue has been fixed** &mdash; try to reproduce it using the
   repository's latest `master` changes.

3. **Isolate the problem** &mdash; ideally create a [reduced test
   case](http://css-tricks.com/6263-reduced-test-cases/) and a live example 
   (perhaps a [fiddle](http://jsfiddle.net)).

A good bug report shouldn't leave others needing to chase you up for more
information. Please try to be as detailed as possible in your report. What is
your environment? What steps will reproduce the issue? What browser(s) and OS
experience the problem? What would you expect to be the outcome? All these
details will help people to fix any potential bugs.

Example:

> Short and descriptive example bug report title
>
> A summary of the issue and the browser/OS environment in which it occurs. If
> suitable, include the steps required to reproduce the bug.
>
> 1. This is the first step
> 2. This is the second step
> 3. Further steps, etc.
>
> `<url>` - a link to the reduced test case
>
> Any other information you want to share that is relevant to the issue being
> reported. This might include the lines of code that you have identified as
> causing the bug, and potential solutions (and your opinions on their
> merits).


<a name="features"></a>
## Feature requests

Feature requests are welcome. But take a moment to find out whether your idea
fits with the scope and aims of the project. It's up to *you* to make a strong
case to convince the project's developers of the merits of this feature. Please
provide as much detail and context as possible.

Building something great means choosing features carefully especially because it
is much, much easier to add features than it is to take them away. Additions 
to Chosen will be evaluated on a combination of scope (how well it fits into the 
project), maintenance burden and general usefulness.

Creating something great often means saying no to seemingly good ideas. Don't 
dispair if your feature request isn't accepted, take action! Fork the 
repository, build your idea and share it with others. We released Chosen under
the MIT License for this purpose precisely. Open source works best when smart 
and dedicated people riff off of each others' ideas to make even greater things. 



<a name="pull-requests"></a>
## Pull requests

Good pull requests - patches, improvements, new features - are a fantastic help. 
They should remain focused in scope and avoid containing unrelated commits.

**Please ask first** before embarking on any significant pull request (e.g.
implementing features, refactoring code, porting to a different language),
otherwise you risk spending a lot of time working on something that the
project's developers might not want to merge into the project.

Please use the [git flow for pull requesets](#git-flow) and follow Chosen's 
[code conventions](#code-conventions) bevore submitting your work. Adhering to 
these guidelines is the best way to get your work included in Chosen.

<a name="git-flow"></a>
#### Git Flow for pull requests

1. [Fork](http://help.github.com/fork-a-repo/) the project, clone your fork,
   and configure the remotes:

   ```bash
   # Clone your fork of the repo into the current directory
   git clone https://github.com/<your-username>/<repo-name>
   # Navigate to the newly cloned directory
   cd <repo-name>
   # Assign the original repo to a remote called "upstream"
   git remote add upstream https://github.com/<upstream-owner>/<repo-name>
   ```

2. If you cloned a while ago, get the latest changes from upstream:

   ```bash
   git checkout <dev-branch>
   git pull upstream <dev-branch>
   ```

3. Create a new topic branch (off the main project development branch) to
   contain your feature, change, or fix:

   ```bash
   git checkout -b <topic-branch-name>
   ```

4. Commit your changes in logical chunks. Please adhere to these [git commit
   message guidelines](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)
   or your code is unlikely be merged into the main project. Use Git's
   [interactive rebase](https://help.github.com/articles/interactive-rebase)
   feature to tidy up your commits before making them public.

5. Locally merge (or rebase) the upstream development branch into your topic branch:

   ```bash
   git pull [--rebase] upstream <dev-branch>
   ```

6. Push your topic branch up to your fork:

   ```bash
   git push origin <topic-branch-name>
   ```

7. [Open a Pull Request](https://help.github.com/articles/using-pull-requests/)
    with a clear title and description.

**IMPORTANT**: By submitting a patch, you agree to allow the project owner to
license your work under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).

<a name="code-conventions"></a>
#### Chosen Code Conventions

1. Make all changes in Coffeescript files, **not** JavaScript files.
2. Use [cake](#cake) to build the JavaScript files.
3. For feature changes, update both jQuery *and* Prototype versions
4. Don't touch the `VERSION` file

<a name="cake"></a>
#### Using CoffeeScript and Cake

First, make sure you have the proper CoffeeScript / Cake set-up in place. We have added a package.json that makes this easy:

```
npm install -d
```

This will install `coffee-script` and `uglifyjs`.

Once you're configured, building the JavasScript from the command line is easy:

    cake build                # build Chosen from source
    cake watch                # watch coffee/ for changes and build Chosen
    
If you're interested, you can find the recipes in Cakefile.
