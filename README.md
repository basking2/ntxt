NTxt
====

About
-----

NTxt is a text file query and formatting tool. If you provide NTxt with
a well formatted text document it will parse that document into a tree
of text blocks which you can then search by text or by tag, and then
display the results by block.

Block have parent blocks, so that your document is parsed into a tree of text
blocks. Querying and printing the document then becomes an exercise in walking
the document tree. This is not unlike an HTML DOM, but much much smaller
and targeted at plain text files.

Words surrounded by [square brackets] form tags that are associated with the
text block they are found in. Finding a block with a tag and printing it
often serves as an easy way to query the text file for the snippet of
information you were looking for.

Tags of a block of text are also associated with that block's parent block.
The root block, therefore, has all tags in the document tree. This
has the happy side-effect that if you print all blocks with tag `[foo]` you 
will have a valid NTxt sub-document. Thus you can split up your
big text files into smaller ones, forming almost a mini adhoc database
collection of information.

Syntax
------

### Headers

These are like HTML headers. There are 6 levels and they are 
denoted by 1 to 6 equals (`=`) signs surrounding some text on a line
by itself. For instance

>     = Header 1 =
>     == Header 2 ==
>     === Header 3 ===
>     ==== Header 4 ====
>     ===== Header 5 =====
>     ====== Header 6 ======

Each header begins or ends a block depending on the preceding header level.

### Indentation

Text that is indented is a block. This block will go "below" any
preceding header block. That is, plain text always goes inside header blocks.
It's what you think.

An empty line will end a paragraph, and thus a block of text.

Shortcomings
------------

Call these bugs, if you will, but they are parts of the syntax that
I'm not convinced I like.

1. Header syntax isn't compatible with Markdown.\n
   Mixing NTxt with Markdown to make a better web presentation
   using something like [Pagedown](https://code.google.com/p/pagedown/)
   seems like an obvious benefit, but the header syntax isn't compatible.
2. Tags should be able to appear anywhere in a line, not just the start.\n
   Putting tags in the front of lines has proven too cumbersome. Allowing
   them to appear anywhere in a line will create the potential 
   for unintentional tags, but that seems better than
   tagging syntax being annoying.

Intentional Shortcomings
------------------------

These are not bugs, but you might be tempted to think they are.

1. There is not auto-formatting. This is intentional. I didn't want
   to reinvent Markdown (though I may make the header syntax compatible).
