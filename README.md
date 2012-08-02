# Chosen

Chosen is a library for making long, unwieldy select boxes more user friendly.

- jQuery support: 1.4+
- Prototype support: 1.7+

For documentation, usage, and examples, see:
http://harvesthq.github.com/chosen

### Adding a new option on the fly

You can configure it to accept new values on the fly, just typing into the search field.
There is 2 ways to do that:

Add a class "chzn-custom-value" to the original select field:
```
<select id="list" class="chzn-custom-value">...
```

Or add an option "allow_custom_value: true" to the constructor:
```
$(#list).chosen({allow_custom_value: true});
```

### Contributing to Chosen

Contributions and pull requests are very welcome. Please follow these guidelines when submitting new code.

1. Make all changes in Coffeescript files, **not** JavaScript files.
2. For feature changes, update both jQuery *and* Prototype versions
3. Use `npm install -d` to install the correct development dependencies.
4. Use `cake build` or `cake watch` to generate Chosen's JavaScript file and minified version.
5. Don't touch the `VERSION` file
6. Submit a Pull Request using GitHub.

### Using CoffeeScript & Cake

First, make sure you have the proper CoffeeScript / Cake set-up in place. We have added a package.json that makes this easy:

```
npm install -d
```

This will install `coffee-script` and `uglifyjs`.

Once you're configured, building the JavasScript from the command line is easy:

    cake build                # build Chosen from source
    cake watch                # watch coffee/ for changes and build Chosen

If you're interested, you can find the recipes in Cakefile.


### Chosen Credits

- Built by [Harvest](http://www.getharvest.com/). Want to work on projects like this? [We’re hiring](http://www.getharvest.com/careers)!
- Concept and development by [Patrick Filler](http://www.patrickfiller.com/)
- Design and CSS by [Matthew Lettini](http://matthewlettini.com/)
- Add new value just typing by [Anderson Grüdtner Martins](http://about.me/andersonmartins)

### Notable Forks

- [Chosen for MooTools](https://github.com/julesjanssen/chosen), by Jules Janssen
- [Chosen Drupal 7 Module](http://drupal.org/project/chosen), by Pol Dell'Aiera, Arshad Chummun, Bart Feenstra, Kálmán Hosszu, etc.
- [Chosen CakePHP Plugin](https://github.com/paulredmond/chosen-cakephp), by Paul Redmond
