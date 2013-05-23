# Chosen

Chosen is a library for making long, unwieldy select boxes more user friendly.

- jQuery support: 1.4+
- Prototype support: 1.7+

For documentation, usage, and examples, see:  
http://harvesthq.github.io/chosen/

### Contributing to Chosen

Contributions and pull requests are very welcome. Please follow these guidelines when submitting new code.

1. Make all changes in Coffeescript files, **not** JavaScript files.
2. For feature changes, update both jQuery *and* Prototype versions
3. Use `npm install` to install the correct development dependencies.
4. Use `grunt build` or `grunt watch` to generate Chosen's JavaScript file and minified version.
5. Submit a Pull Request using GitHub.

### Using CoffeeScript & Cake

First, make sure you have [grunt-cli](https://github.com/gruntjs/grunt-cli) in place. We have added a package.json that makes this easy:

```
npm install
```

This will install all development dependencies as `node_modules`.

Once you're configured, building the JavasScript from the command line is easy:

    grunt build                # build Chosen from source
    grunt watch                # watch coffee/ for changes and build Chosen
    
### Chosen Credits

- Built by [Harvest](http://www.getharvest.com/). Want to work on projects like this? [We’re hiring](http://www.getharvest.com/careers)!
- Concept and development by [Patrick Filler](http://www.patrickfiller.com/)
- Design and CSS by [Matthew Lettini](http://matthewlettini.com/)

### Notable Forks

- [Chosen for MooTools](https://github.com/julesjanssen/chosen), by Jules Janssen
- [Chosen Drupal 7 Module](http://drupal.org/project/chosen), by Pol Dell'Aiera, Arshad Chummun, Bart Feenstra, Kálmán Hosszu, etc.
- [Chosen CakePHP Plugin](https://github.com/paulredmond/chosen-cakephp), by Paul Redmond
