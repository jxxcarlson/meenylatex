/Users/carlson/Downloads/2/elm make --optimize src/Main.elm --output=Main.js
uglifyjs Main.js -mc 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9"' -o ./dist/Main.min.js
cp ./dist/Main.min.js /Users/carlson/dev/github_pages/app/meenylatexdemo2
