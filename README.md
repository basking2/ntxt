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

