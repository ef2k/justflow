JustFlow
========

JustFlow is a website scraper that downloads assets, updates the asset urls to local ones, and sorts them into the following folder structure:

```
www.coolestwebpage.com_/
- js/
- img/
- css/
- fonts/
```


**NOTE: JustFlow works on most sites but has trouble on pages that redirect.**

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