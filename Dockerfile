FROM perl:5.34
RUN cpanm Curses Term::Size
COPY . /usr/src/myapp
WORKDIR /usr/src/myapp
CMD [ "perl", "./GameOfLife.pl" ]