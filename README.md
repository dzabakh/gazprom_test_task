16385.zip - это моя Postgres база данных, которую я заполнял из лога;
index.html - это страница, которая обращается к search.cgi и ищет совпадения по базе данных;
parse_log.pl - это скрипт, который парсит лог.

index.html надо расположить в дефолтную директорию для документов у веб-сервера,
search.cgi - в дефолтную директорию для cgi скриптов у веб-сервера.
Запускал на встроенном в Mac Apache и базе Postgres.
