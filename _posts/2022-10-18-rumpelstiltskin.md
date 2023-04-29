---
layout: post
title: Rumpelstiltskin (the vim plugin)
permalink: blog/rumpelstiltskin
tags: ["software projects", "unicode"]
---


_TL;DR, I made a [plugin](https://github.com/izzergh/rumpelstiltskin) for vim.
It lets you fuzzy search Unicode code points and some combining character
sequences._

## 1. Some Background
During my first and last[^1-1] job as a web developer I worked with some people
who, instead of editing text with a text editor[^1-2], would dazzle me by
simply not leaving their terminal.
Forgoing the modern GUIs to which I had become accustomed, these tricksters,
these _impossibly_ capable developers, would never lift their fingers from
their keyboards[^1-3].
Further, what was on their screens was nigh inscrutable to me.
Solid lines would zoom across the terminal, the cursor would teleport seemingly
at will, and then the user would patiently point with their finger to the
correct square I should focus my inferior eyes upon[^1-4].

These people were using [neovim](https://neovim.io/)[^1-5]
and [tmux](https://github.com/tmux/tmux/wiki).

Partly to live up to my newly heightened standards and partly because I really
liked the prospect not having to `ALT+Tab` every like 5 seconds, I joined
them.
It was surprisingly quick to grasp, and I got hooked on customizing it and
learning little tricks and shortcuts I could show off.
<!-- TODO: write something about the "types" of people who use text editors
I've talked about this with bug - there is a breed of incurious person who
does not want to solve every tiny inconvenience, and they seem to learn
new technologies slower... -->

## 2. Motivation
This job had us using Macbooks, and I found one feature indispensable:
[the character viewer][osx char viewer link].
With a simple key combination, I could search (by vague description) for any
character my computer could make, and put it where my cursor was.

After leaving this job, I found myself trying to do this on my entirely
non-apple machines.
The best I could do was visit some online Unicode database or just google what
I would type into the character viewer and hope it knew what I meant.

Both Windows[^2-1] and Linux[^2-2] have various insufficient simulacra of the
OS X character viewer.
Each has their own issues and inefficiencies, and none of it was as seamless
as `⌘+⌴`.

I decided there _must_ be a vim plugin for this, right?
The venn diagram of vim users and odd-Unicode-placers must have a significant
overlap, right?
And there are!

### 2.1. Other plugins
- **[chrisbra/unicode.vim](https://github.com/chrisbra/unicode.vim)**
    This one has close to the features I want, but it's not really geared
    for the specific use case I was missing from OS X.
    Instead of whimsically keymashing at a text box to yield what I kind of
    remember is the name of a code point I think exists, you need to know
    what you're doing.
    The reading and digraph support is really neat though.
    Just not what I was looking for.
- **[yazgoo/unicodemoji](https://github.com/yazgoo/unicodemoji)**
    This is more like it!
    It uses [the fuzzy finder I have installed](https://github.com/junegunn/fzf.vim)
    to do the vague searching when it's invoked.
    The issue is it's missing the rest of the unicode!
    "Emoji" is in the name.
    It's not built to be extendable, and a pull request to add _the entire
    set of Unicode characters_ would likely not be approved.

The latter of these plugins was really close.
Importantly, however, I could sort of understand the source code, and I now had
a sort of template for what the plugin I'm looking for consists of.

## 3. How It Works
Rumpelstiltskin does one thing that is actually two things.
The one thing is "let the user fuzzy search Unicode"[^3-1].
The second thing that the one thing requires is "have some Unicode to fuzzy
search" since _apparently_ that's not trivial[^3-2].

### 3.1. The One Thing
The main engine is FZF; it's required to be installed for Rumpelstiltskin to
work.
All the vim script lives in `autoload/` and `plugin/`.

`plugin/rumpelstiltskin.vim` is where the public API lives - the commands are
defined and the default mappings are set. EZ PZ. Here's a snippet.

```vim
" All unicode
" Normal mode
command! RumpelBase :call rumpelstiltskin#base()

" Insert mode
imap <expr> <C-X>u rumpelstiltskin#base_complete()
```

`autoload/rumpelstiltskin.vim` is where the functions' functionality lives.
The core functions simply delegate to FZF functions, with some helper functions
and trial-and-error to get the parameters right.
Here's what that looks like:

```vim
" Normal mode search
function! rumpelstiltskin#base()
  call fzf#run(
        \ fzf#wrap({
          \ 'source': 'cat ' . g:rumpelstiltskin_base_source,
          \ 'sink*': function('<SID>insert_sink'),
          \ 'options': '--no-hscroll'
          \ })
        \ )
endfunction
```

Calling this goes immediately into `fzf#run`, which takes several wrapped
parameters:
- `source` is the source file that's fuzzy searched
- `sink` is what happens with the result of the search.
In this case, that's `insert_sink`, a helper function that takes the
result and puts it where the cursor originally was
- `options` is "the rest of the options"[^3-3].
`--no-hscroll` means you can always see the code point (if it renders)
regardless of the window size - small windows may scroll away from it to show
you what part of the file your search term matched.

All this amounts to the desired 🌟UX✨:
![screenshot of Rumpelstiltskin in action](/assets/rumpel_blog_demo.png)

Pressing enter on the line you highlight will place the character displayed on
the left where your cursor was when you invoked the function!

As a side effect of implementing the same thing in insert mode, it was really
easy to implement _completion_ as well!
![screenshot of Rumpelstiltskin completion](/assets/rumpel_blog_completion_demo.png)

Not easy to come up with use cases for that one!

### 3.2. The Other Thing
FZF is built to search for lines in a file, not individual characters or
objects with hidden metadata.
So, what we feed FZF is a source file - a plain text file where "what to insert"
is on the left, then all its names are to the right.

Here's a short line, a code point with just a name and an id:
```
5 ... digit five | U+0035
```

And here's a long line - this is a combining character sequence with CLDR
translation data (and its id):
```
🏴‍☠ ... Jolly Roger | pirate | pirate flag | plunder | treasure
```
as an aside, most terminal emulators don't render ZWJ sequences[^3-4], so that
looks gnarly in source code: `🏴<200d>☠`. Plus the emoji tend to be _slightly_
wider than one character width, so there's some overlap sometimes. Say La V.

These are compiled into the "base source", which is _every_ Unicode code point
and supported ZWJ sequence, followed by its names.
Here's the format[^3-5]:

```
(data) ... (default name) | (CLDR English nicknames) | (id)
```
- `data` is the thing that gets inserted when you press enter
- ` ... ` is the separator that the plugin uses to separate the data from the
search terms
- `(default name)` is the name of the character in the Unicode standard, e.g.
"latin capital letter a" for `A`
- `(CLDR English nicknames)` is all of the CLDR names in English
- `(id)` is the id of the code point in the format `U+id#`

A final snag is, to keep things hard for me, there are some _ranges_ that
Unicode has in its Big List Of Characters.
Instead of chasing down everything in that range and adding it to the task,
I just had Ruby loop through the range and spit out the Unicode for that
code point.
There are no ranges in the final output! Every character is there!

This is all scraped from the various public Unicode standard repositories, then
parsed and saved. The rake task that does this is idempotent and tested with
MY OWN TWO EYEBALLS and `git diff`, and stored in source control.
That comes with the side effect that I wanted to avoid, which is twofold:
1. Acting as a source of truth for Unicode, meaning having to keep it up to
date and being responsible for inaccurate or incomplete data
1. Bloating the size of the plugin by a ton

The first is _just how it is_, and the second is _acceptable with modern
internet connections_. They are both definitely concessions though.

There is also the emoji set with its own corresponding functions, for emoji
(just what Unicode calls emoji, includes CLDR names too).
That's just to keep it un-cluttered if you want to slap an emoji in there,
and to act as a proof-of concept for one of my big planned features...

## 4. Customization
Currently, all the user can customize is the shortcuts for the functions
accessing.

However, I want to document the format of the source file and an example script
for making one, and allow people to add custom sets to fuzzy search through.
The framework is not limited to single characters or combining character
sequences; you can have anything in the data field.
The completion function works in a way that you could, for example, type in an
ambiguous acronym, whip up Rumpelstiltskin, and replace it from the list of
the matching definitions you've provided.

You could also use it to store some "favorites" - a subset of the "base" set
provided, just with commonly used lines to keep things clean.
Or, for people who do not only speak English, they can set up their own names in
their own language without waiting for me to figure out the best way to
configure language at a plugin level[^4-1].

Finally, if I stop maintaining this plugin for whatever reason (_after_
implementing this feature!), it becomes resistant to future Unicode updates,
since motivated users can customize their lists with the latest data, without
having to rewrite the entire plugin (or even fork it).

## 5. Conclusion
Those that know me in person know Rumpelstiltskin, but few of them have all the
context that I've laid out here.
In one sense, this has been an advertisement.
In another, it's a placeholder (this is the first post I published!).
In a third, more sexy sense, it's a look into how I approach problem solving,
and what problems I choose to solve.

I hope this explains what I've been going on about in vague terms in person,
reader I already knew.
To the reader I don't know (may there be many of you, eventually. Hello!),
I hope this was a good time or helpful or both.

Here's what I learned in broad strokes:

- How to make a vim plugin!
- If the license allows it, absolutely steal others' code patterns
- Chronological narrative is not a great way to convey the development process
- I have a lot more to say about Unicode than I initially thought

---

{% comment %} Footnotes {% endcomment %}
[^1-1]:
    Most recent or final? Who knows!

[^1-2]:
    In my day, I used Atom
    ([RIP](https://github.blog/2022-06-08-sunsetting-atom/))
    and some of my peers did too, if they didn't use
    [Sublime](https://www.sublimetext.com/) or
    [Rubymine](https://www.jetbrains.com/ruby/).

[^1-3]:
    It's fun to personify these keyboards as finally being used correctly.
    If I were a keyboard, I know I would jealously resent other pieces of human
    interface hardware whenever they prevented my use.
    After all, I (the keyboard) was _designed_ to be modulated and poked and
    tapped upon.
    For a user to spend most of their time on the computer with all ten fingers
    working cooperatively and independently and quickly all at once, this must
    be the euphoria of truly fulfilling the task my creators so lovingly expect
    of me (again, the keyboard! I am writing this footnote).

[^1-4]:
    I want to make it abundantly clear that this imbalance I'm implying is
    completely in my own head at this time.
    I've since been on the other side of this interaction, and it is not nearly
    as trying on my patience as I assumed it would be.

[^1-5]:
    I use `vim` for simplicity's sake here and elsewhere, but I'll specify
    `neovim` when the distinction is important or when I get into the mood.

[^2-1]:
    Windows machines are little boxes of fun, full of video games and browsers
    and chat clients and audiovisual editing programs and the like. FYI.

[^2-2]:
    I use Manjaro because my husband said it was good and I look up to him,
    but I've used Ubuntu before.
    These machines are little boxes of fun in a different way, full of source
    code and slightly worse versions of Windows applications and the like.
    Also it's much easier to crack open a terminal and do some codin' on one
    of these puppies than on Windows or indeed Mac.
    In my experience anyway!

[^3-1]:
    This one thing is already several things!
    It allows searching in multiple modes, and each of those allows searching
    through a number of subsets of unicode with different properites.
    In a marketing sense, however, it's "one thing".

[^3-2]:
    Yes!
    Yes I am taking it personally that I have to use the Internet to get the
    names of the characters my computer puts on the screen.
    Yes I am taking it as a personal attack that I need to make everyone who
    uses my plugin _download that same data again so they have their own copy_.
    No I will not make an operating system that has the table I'm looking for.

[^3-3]:
    This is mainly why I'm using `fzf#wrap`. Default display options for the
    fuzzy-find window can be set globally by a user - using `fzf#wrap` won't
    get rid of those options.

[^3-4]:
    "ZWJ" stands for "Zero Width Joiner", which is a special invisible character
    (`U+200D`) that tells the program not to render it, and instead try and
    combine what's on either side using a separate table of possible
    combinations.
    A common example of these in the wild is the gendered emoji, like
    👱‍♂ (blond man)
    and
    👱‍♀ (blond**e** **wo**man).
    As a side note (yes this is a footnote shush), Unicode has interestingly
    chosen to avoid bioessentialism by defining all these sequences, resulting
    in pregnant man (🫃) and bearded woman (🧔‍♀).
    I think that's the right way to do it from a consistency standpoint and
    because of my political beliefs!

    If there is no combination defined in the standard, or the rendering program
    does not conform fully to the standard, the ZWJ is still invisible (and
    takes up _zero space_ 😜), like if you try and assign petty human gender to
    a snail (there's a ZWJ in the middle I promise) 🐌‍♀ .

    Another side note (shuuuuuuuush omg), these character sequences are _not_
    how skin color is done! That's just a diagraph - 🦶🏻 is a foot with a light
    skintone instead of yellow. But instead of `🦶 + (ZWJ) + 🏻`, it's a simple
    digraph: `🦶 + 🏻`! Isn't that odd! Adding the ZWJ still works though.

    Different programs that render text have different levels of compliance with
    the Unicode standard, but what _should_ render for certain sequences is all
    laid out explicitly in the standard.

    Maybe I should write a blog post about ZWJ and digraphs.
    Did you know 🧑‍🎄 is `🧑 + (ZWJ) + 🌲` (gender neutral adult + evergreen
    tree), and cannot be gendered further?
    They're called "Mx Claus" in the CLDR (among other aliases).
    And it's not because you can only join two things! "people holding hands"
    (🧑‍🤝‍🧑) is `🧑 + (ZWJ) + 🤝 + (ZWJ) + 🧑`! Wild!

[^3-5]:
    Any of these can be missing and that's fine.
    There are no lines with _no_ search terms, though, which is nice.

[^4-1]:
    On the roadmap!
    Behind customization though, so the users aren't limited by my timeline

{% comment %} URLs {% endcomment %}
[osx char viewer link]: https://support.apple.com/guide/mac-help/use-emoji-and-symbols-on-mac-mchlp1560/mac
