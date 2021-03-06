

По всей видимости задание даёт волю самому заняться формализацией.

Рассматривая разные варианты работы можно заметить, что есть строгий простой граф состояний:

S -> START STARTED -> START COMPLETE -> STOP STARTED -> STOP COMPLETE -> S

Обработка прерывания этого процесса приведена в примере. Разве что прерывание на переходе "START COMPLETE -> STOP STARTED" заставляет задуматься. На первый взгляд в примере дан случай аварийного завершения процесса инициализации, что однозначно проецируется на процесс финализации. А вот выполнение процесса, здесь вроде бы не так важно и может вообще не имеет отношения к данному логу. Но если рассуждать по-житейски, то завершение процесса во время его выполнения - также опасно как и на других этапах.
*Edit:* Тут была моя ошибка - в примере дан случай того, что процесс может штатно завершиться даже без финализации. Позже я это учел в скрипте.

Следующий случай: повторный запуск. Формат вывода не очень к этому распологает. По идее наша утилита призвана собрать лог и представить интересующую информацию в удобном для чтения виде (было бы несколько странно создавать её в расчёте на дальнейшие трансляторы). 
Читать 

```
A started 3 seconds
A started 34 seconds
A started 29 seconds
A started 13 seconds
```

неудобно. Человек конечно же поймёт, что происходило, но к примеру процесс А его может не интересовать, но будет занимать весь экран. Поэтому напишу последовательность в одну строку через запятую. У такого решения есть недостаток - человек не будет видеть последовательность запусков и остановок. Но выше я остановился на строгом графе, так что ситуаций "start start stop" в выводе недопустима.

Важна ли последовательность вывода? из примера видно, что строки выводятся в зависмости от времени запуска или они просто отсортированны (зависимость от названия процесса). Первое логичней, но  второе тоже может быть удобным. Выберу сортировку, т.к. это банально проще.

Далее ещё нужно разобрать случаи неправильного перехода в графе. Выше я привел граф состояний и он достаточно прост. Запуск процесса после успешного запуска звучит странно, поэтому любое отклонение от указанного порядка буду записывать в stderr.

## выполнение 

В папке tests есть ряд тестов некоторых ситуаций. Они конечно покрывают малую часть ситуаций и к тому же отсутствует композиция всех случаев. По хорошему стоило бы сделать генератор лога, но тут встаёт проблема, что генерируемый тестовый лог необходимо подавать на вход скрипту и ждать от него какой то результат и вот тут задача становится нетривиальной. Можно конечно делать мелкие "безопасные" ошибки, и считать количество строк в stdout и stderr.
