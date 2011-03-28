# Rima: A Tool for Math Modelling

Rima is a tool for formulating and solving mathematical modelling and optimization problems.
Rima's primary design goal is that models should be easy to re-use.

Rima allows you to build models flexibly and interact with your data freely,
allowing you to focus on the problem at hand and obtain solutions more quickly.

In a hurry?  [Have a look at a Rima model](http://rima.incremental.co.nz/knapsack.html),
or [read the installation instructions](http://rima.incremental.co.nz/install.html).

## Features

If you:

+ wish your modelling language had stronger support for general programming features (functions, data structures, more than one model...)
+ really like your optimization package for a mainstream language but miss defining your model symbolically
+ wish your purpose-designed modelling language wouldn't make you to treat your data like FORTRAN 66 arrays
+ wonder why your optimization package for a modern, dynamic language still makes you treat your data like FORTRAN 66 arrays
+ find that your modelling system imposes too many dependencies between equations and data
+ just wish you could write a model and then make a subclass of it, or use it as part of another model

Then Rima might be for you.  With Rima you can:

+ specify your model symbolically
+ define your model *before* any data, and define your data for as many instances of your model as you like after the model is defined
+ compose models from parts in the manner that suits you
+ work with your data in the structures that you wish to use
+ access all the features of Lua, a fast, small, widely deployed scripting language that's easy to both embed and extend

Rima binds to well-known optimisation packages to solve problems.
Currently bindings are available for:

+ [Coin CLP](https://projects.coin-or.org/Clp) for linear problems
+ [Coin CBC](https://projects.coin-or.org/Cbc) for mixed-integer linear problems
+ [lpsolve](http://sourceforge.net/projects/lpsolve) for mixed-integer linear problems
+ [Coin IPOPT](https://projects.coin-or.org/Ipopt) for nonlinear problems


## Find out More

If Rima has got your attention,
you could [have a look at a Rima model](http://rima.incremental.co.nz/knapsack.html),
read the [Rima user guide](http://rima.incremental.co.nz/contents.html) (including example models),
starting with how to [build expressions](http://rima.incremental.co.nz/expressions.html).
You could also [read the installation instructions](http://rima.incremental.co.nz/install.html).

Rima is developed by [Incremental](http://www.incremental.co.nz/).
You can contact us at <rima@incremental.co.nz>.
Rima is available under the [MIT Licence](http://www.opensource.org/licenses/mit-license.php).