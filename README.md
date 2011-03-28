# Rima: A Tool for Math Modelling

Rima is a tool for formulating and solving mathematical modelling and optimization problems.
Rima's primary design goal is that models should be easy to re-use.

Rima allows you to build models flexibly and interact with your data freely,
allowing you to focus on the problem at hand and obtain solutions more quickly.

In a hurry?  [http://rima.incremental.co.nz/knapsack.html](Have a look at a Rima model),
or [http://rima.incremental.co.nz/install.html](read the installation instructions).

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

+ [https://projects.coin-or.org/Clp](Coin CLP) for linear problems
+ [https://projects.coin-or.org/Cbc](Coin CBC) for mixed-integer linear problems
+ [http://sourceforge.net/projects/lpsolve](lpsolve) for mixed-integer linear problems
+ [https://projects.coin-or.org/Ipopt](Coin IPOPT) for nonlinear problems


## Find out More

If Rima has got your attention,
you can [http://rima.incremental.co.nz/knapsack.html](have a look at a Rima model),
read the [http://rima.incremental.co.nz/contents.html])[Rima user guide] (including example models),
starting with how to [http://rima.incremental.co.nz/expressions.html](build expressions).

Rima is developed by [http://www.incremental.co.nz/](Incremental).
You can contact us at <rima@incremental.co.nz>.
Rima is available under the [MIT Licence](http://www.opensource.org/licenses/mit-license.php).