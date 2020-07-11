    ## How to use the `syntax` tool

The `syntax` tool is useful for experimenting
with MiniLaTeX.  Here is a sample session:

```
$ npm run syntax
> "This is \strong{stuff}"
[
  'EQ: ',
  '(False,True)',
  '',
  'SOURCE1: ',
  '"This is \\strong{stuff}"',
  'SOURCE2: ',
  '"This  is  \\strong{stuff}"\n\n\n\n',
  '',
  'AST: ',
  'LXString "\\"This  is "',
  'Macro "strong" [] [LatexList [LXString "stuff"]]',
  'LXString "\\""',
  '',
  'DIFF: ',
  'Removed "\\"This is \\\\strong{stuff}\\""',
  'Added "\\"This  is  \\\\strong{stuff}\\""',
  'Added ""',
  'Added ""',
  'Added ""',
  'Added ""'
]
```

## Loading files

```
> .load ex1
\section{Intro}

This \strong{is} a test: $a^2 + b^2 = c^2$


[
  'EQ: ',
  '(False,True)',
  '',
  'SOURCE1: ',
  '\\section{Intro}\n\nThis \\strong{is} a test: $a^2 + b^2 = c^2$',
  'SOURCE2: ',
  ' \\section{Intro}\n\nThis  \\strong{is}a  test:  $a^2 + b^2 = c^2$\n\n',
  '',
  'AST: ',
  'Macro "section" [] [LatexList [LXString "Intro"]]',
  'LXString "This "',
  'Macro "strong" [] [LatexList [LXString "is"]]',
  'LXString "a  test: "',
  'InlineMath "a^2 + b^2 = c^2"',
  '',
  'DIFF: ',
  'Removed "\\\\section{Intro}"',
  'Added " \\\\section{Intro}"',
  'NoChange ""',
  'Removed "This \\\\strong{is} a test: $a^2 + b^2 = c^2$"',
  'Added "This  \\\\strong{is}a  test:  $a^2 + b^2 = c^2$"',
  'Added ""',
  'Added ""'
]
```