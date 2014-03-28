# Chosen

Chosen is a library for making long, unwieldy select boxes more user friendly.

- jQuery support: 1.4+
- Prototype support: 1.7+

For **documentation**, usage, and examples, see:
http://harvesthq.github.io/chosen/

For **downloads**, see:
https://github.com/harvesthq/chosen/releases/

### Bower Installation

Chosen does _**not**_ currently support command-line `bower install chosen` installation. This is because the repo does not contain the compiled sources, and bower does not currently support adding a post-install/build step.

However, you can specify that you'd like to use [the release ZIP](https://github.com/harvesthq/chosen/releases/latest), which includes the compiled and minified sources.

Either install from the command line with

```
$ bower install https://github.com/harvesthq/chosen/releases/download/v1.1.0/chosen_v1.1.0.zip
````

or add Chosen to your own project's `bower.json` file, like:

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "dependencies": {
    "jquery": "1.11.0",
    "chosen": "https://github.com/harvesthq/chosen/releases/download/v1.1.0/chosen_v1.1.0.zip"
  }
}
```

See [#1509](https://github.com/harvesthq/chosen/issues/1509), [#1472](https://github.com/harvesthq/chosen/issues/1472), and [#1333](https://github.com/harvesthq/chosen/issues/1333) for more info.

### Contributing to this project

We welcome all to participate in making Chosen the best software it can be. The repository is maintained by only a few people, but has accepted contributions from over 50 authors after reviewing hundreds of pull requests related to thousands of issues. You can help reduce the maintainers' workload (and increase your chance of having an accepted contribution to Chosen) by following the
[guidelines for contributing](contributing.md).

* [Bug reports](contributing.md#bugs)
* [Feature requests](contributing.md#features)
* [Pull requests](contributing.md#pull-requests)

### Chosen Credits

- Concept and development by [Patrick Filler](http://patrickfiller.com) for [Harvest](http://getharvest.com/).
- Design and CSS by [Matthew Lettini](http://matthewlettini.com/)
- Repository maintained by [@pfiller](http://github.com/pfiller), [@kenearley](http://github.com/kenearley), [@stof](http://github.com/stof), [@koenpunt](http://github.com/koenpunt), and [@tjschuck](http://github.com/tjschuck).
- Chosen includes [contributions by many fine folks](https://github.com/harvesthq/chosen/contributors).
