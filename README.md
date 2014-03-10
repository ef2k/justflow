JustFlow
========

JustFlow scrapes pages for assets, updates the asset urls to local ones, and sorts the assets into the following folder structure:

```
www.thetargetsite.io/
- js/
- img/
- css/
- font/
```


**NOTE: Works on most sites but, has trouble on sites that redirect.**

Instructions
------------

`gem build justflow.gemspec`

`gem install justflow-0.0.1.gem`


Usage
-----

`$: justflow https://coolestwebpage.com/`

Issues
------

Aint got no tests