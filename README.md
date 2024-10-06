# HW1: Genome Assembly

### Иллерицкий Павел БИТ221

## Описание проекта
Этот проект посвящен сборке генома бактерии, выделенной из образца воды с нефтью, на основе paired-end (PE) и mate-pair (MP) чтений. Проект выполнен в рамках домашнего задания №1 по курсу биоинформатики.

## Шаги выполнения

### 1. Выбор случайных подмножеств чтений
Скрипт автоматически создает поддиректорию `sub`, где хранятся случайно отобранные подмножества чтений. Для выборки используется команда `seqtk`, которая выбирает 5 миллионов чтений типа paired-end и 1,5 миллиона чтений типа mate-pair. Это реализовано через функцию `process()` с параметрами для количества PE и MP чтений.

```bash
seqtk sample -s "$SEED" $HOME/src/pe1.fq $PE_NUM > sub/pe1_sub.fq
seqtk sample -s "$SEED" $HOME/src/pe2.fq $PE_NUM > sub/pe2_sub.fq
seqtk sample -s "$SEED" $HOME/src/mp1.fq $MP_NUM > sub/mp1_sub.fq
seqtk sample -s "$SEED" $HOME/src/mp2.fq $MP_NUM > sub/mp2_sub.fq
```

### 2. Оценка качества исходных чтений
После выборки данных, скрипт создает отчеты по качеству чтений с помощью `FastQC` и `MultiQC`, которые сохраняются в соответствующих поддиректориях (`fastqc` и `multiqc`). Это выполняется через функцию `report()`, которая запускает оценку качества для файлов в директории `sub`.

```bash
fastqc ../$1/* -o fastqc -t $THREADS
multiqc fastqc --filename "multiqc_report_$1" --outdir "multiqc"
```

### 3. Подрезка чтений и удаление адаптеров
Далее происходит подрезка чтений с помощью `platanus_trim` для paired-end данных и `platanus_internal_trim` для mate-pair данных. Результаты подрезки сохраняются в директории `trimmed`.

```bash
platanus_trim -i trimmed/pe.fofn -t $THREADS
platanus_internal_trim -i trimmed/mp.fofn -t $THREADS
mv sub/*trimmed trimmed/
```

После подрезки скрипт выполняет повторную оценку качества подрезанных данных, создавая аналогичные отчеты FastQC и MultiQC для директории `trimmed`.

### 4. Сборка контигов
Скрипт автоматически собирает контиги с помощью программы `platanus assemble` и сохраняет результаты в директории `assemble`. Контиги собираются на основе подрезанных paired-end и mate-pair чтений.

```bash
platanus assemble -o platanus -f trimmed/*trimmed -t $THREADS
```

### 5. Сборка скаффолдов
Далее происходит сборка скаффолдов с помощью команды `platanus scaffold`, которая использует контиги и подрезанные чтения для получения более длинных последовательностей. Результаты сохраняются в директории `scaffold`.

```bash
platanus scaffold \
         -o platanus \
         -c assemble/platanus_contig.fa \
  -b assemble/platanus_contigBubble.fa \
  -IP1 trimmed/*.trimmed \
  -OP2 trimmed/*.int_trimmed \
  -t $THREADS
```

### 6. Закрытие гэпов
С помощью программы `platanus gap_close` происходит закрытие гэпов в скаффолдах, что улучшает качество сборки. Результаты сохраняются в директории `gap_close`.

```bash
platanus gap_close \
  -o platanus \
  -c scaffold/platanus_scaffold.fa \
  -IP1 trimmed/*.trimmed \
  -OP2 trimmed/*.int_trimmed \
  -t $THREADS
```

### 7. Итоговые результаты работы на сервере
Скрипт автоматически собирает все финальные файлы в директорию `data`. В нее копируются файлы с контигами и скаффолдами как для полного набора данных, так и для уменьшенного набора. 

```bash
cp default/assemble/platanus_contig.fa data/contigs.fasta
cat lessy/assemble/platanus_contig.fa >> data/contigs.fasta
cp default/scaffold/platanus_scaffold.fa data/scaffolds.fasta
cat lessy/scaffold/platanus_scaffold.fa >> data/scaffolds.fasta
```

## Код
Для подсчета количества контигов и скаффолдов а также других параметров сделаем простую тетрадку

### Анализ контигов
![contigs](https://github.com/user-attachments/assets/58161f98-e00d-4077-9343-034b78352b28)
### Анализ скаффолдов
![scaffolds](https://github.com/user-attachments/assets/b8fb650a-96ca-418b-846e-22f388db4934)

Далее посчитаем количество гепов до и после gap_close
![gap_close](https://github.com/user-attachments/assets/0dc2b500-8528-4a59-9a98-79dc9c0d2b88)

Как можно видеть Количество гепов было успешно сокращено

## MultiQC
Далее будут приведене Фотографии отчетов MultiQC

### Для изначальных данных
![image](https://github.com/user-attachments/assets/f2120397-c5b5-4f8c-ae47-d1edf5ef730d)
![image](https://github.com/user-attachments/assets/5a105633-b284-497e-95be-deaf7940ba12)
![image](https://github.com/user-attachments/assets/457da4e3-2457-4446-80b7-3a2c4aca1a2e)

### Для подрезанных данных
![image](https://github.com/user-attachments/assets/640d0f76-a591-496d-8032-a2c189011ed5)

![image](https://github.com/user-attachments/assets/d111501b-8ec5-4891-be87-088b53786ff6)

![image](https://github.com/user-attachments/assets/09e7f952-48b3-4525-a92a-cc7f7766458e)


## БОНУС
Выполнение бонусной части абсолютно аналогично отличающееся только количеством выбранных изначальных чтений. В моем случае количество чтений состовляеет 10% от изначальных. В bash скрипте автоматически создаются и выполняются аналогичные команды для меньшего количества чтений с тем различием что все теперь обрабатывается в папке lessy
Код также аналогичен, далее будут фотографии данных с меньшим количеством чтений
### Анализ контигов
![less_contigs](https://github.com/user-attachments/assets/c1a6426d-6e5f-4f46-902f-102eb97644ca)
### Анализ скаффолдов
![less_scaffolds](https://github.com/user-attachments/assets/7a8ec9ca-ea6e-4375-bfce-41abcf218d4d)

### Gap_close
![less_gap_close](https://github.com/user-attachments/assets/6be51b11-ee28-4eb4-9df9-c40a2bb89592)

## MultiQC Бонус
### Изначальные чтения
![image](https://github.com/user-attachments/assets/a60b9e20-5838-4fa0-a499-c2f3805d98d9)
![image](https://github.com/user-attachments/assets/3c97152c-d83e-4f20-a29d-61abb040ce56)
![image](https://github.com/user-attachments/assets/be38a770-1c46-4284-96bb-c43c6d70de8e)
### Подрезанные
![image](https://github.com/user-attachments/assets/d5c5fdc1-6524-4632-bf21-e1688cb291f3)
![image](https://github.com/user-attachments/assets/6c5fe0e8-5567-4f62-8e5a-4cbd947ed817)
![image](https://github.com/user-attachments/assets/88730d06-0986-4cc2-8899-4def824a7492)

## Выводы
Как можно заметить количество гепов в меньшей выборке сильно возросло что свидетельствует о некачественной сборке и о коротких полученных чтений в итоге. Следовательно величина изначачальной выборки напрямую влияет на качество сборки чтд.


