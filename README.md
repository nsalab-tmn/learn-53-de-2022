# Шаблон репозитория лабораторной работы
Данный репозиторий представляет из себя шаблон репозитория лабораторной работы. 
определение лабораторной работы начинается с файла [learn-metadata.json](./learn-metadata.json)

## Формат файла метаданных learn-metadata.json
Файл является конфигурационным json файлом со следующим набором полей:
* `title` - человекочитаемое наименование лабораторной по умолчанию.
* `materialType` - тип учебного материала. для лабораторных работ = "lab"
* `shortName` - короткое наименование. Должно содержать не более 10 символов [a-z_]
* `description` - короткое описание лабораторной
* `assessmentPath` - путь к папке с определением схемы оценки (для компонента LAB-ASSESSMENT)
* `deploymentPath` - путь к папке с определением сценария развертки terraform (для компонента LAB-DEPLOY)
* `assetsPath` - путь к папке с изображениями и прочими материалами, которые необходимо загрузить в объектное хранилище
* `testProjectPath` - путь к файлу с определением текста задания в формате Markdown 
* `answerSchema` - jsonSchema определяющая список и формат полей для ответа. Каждый item в словаре `properties` - идентификатор поля ответа. В дополенение введены следующие поля:
    * `title` - человекочитаемое наименование поля или текст вопроса
    * `placeholder` - плейсхолдер отображаемый в поле ответа
* `credentialsSchema` - словарь полей, котоыре будут отображаться в учетных данных. Ключ каждого объекта - идентификатор поля. Значние - словарь состоящий из следующих полей:
    * `title` - Человекочитаемое название поля
    * `source` - источник значения поля. Должен соответствовать названию **output** из сценария развертки (см [output.tf](./deploy/output.tf))
    * `value` - статаческое значние поля. Является взаимоисключающим с `source`.
* `duration` - продолжительность лабораторной в формате ISO8601 duration
* `difficulty` - сложность от 1 до 10
* `tags` - теги с коотрыми связана лабораторная работа
* `skills` - словарь с охватываемым доменами знаний. (пока никак не реализован)

## Формат файла схемы оценки marking-scheme.json
Файл является json файлом со следующим набором полей:
Словарь критериев:
* `id` - индентификатор критерия. Набор букв. Словарь полей критерия:
   * `name` - название критерия;
   * `max_mark` - баллы за критерий;
   * `subCriterions` - словарь саб критериев:
      * `id` - индентификатор саб критерия. Набор цифр. Словарь полей саб критерия:
         * `name` - название саб критерия;
         * `max_mark` - баллы за саб критерий;
         * `aspects` - словарь аспектов:
            * `id` - индентификатор аспекта. Набор цифр. Словарь полей аспекта:
               * `name` - название аспекта;
               * `max_mark` - баллы за аспект;
               * `type` - тип аспекта; типы могут быть `jmespath`,`webrequest`. `jmespath` -  проверка начилия ресурса или свойства ресурса c помощью jmespath и rest api azure. `jmespath` должен содержать словарь `actions`, которые содержат поле `filterForReseachInResourse`. `webrequest` - проверка, доступен ли веб-сайт по оставленной ссылке. `webrequest` должен содержать поле `nameAnswer`, `allresource` - проверка начилия ресурса или свойства ресурса c помощью jmespath из всех ресурсов группы. `allresource` должен содержать словарь `actions`, которые содержат поле `filterForReseachInResourse` 
               * `filterForReseachInResourse` - словарь полей для типа jmespath для поиска ресурса для запроса url = `f"https://management.azure.com/subscriptions/{__cloud53AzureSubscription}/resourceGroups/{resourseGroupName}/providers/{provider}/{client}?api-version={api_verion}"`:
                  * `api_verion` - версия api management azure. Например: `2021-07-01`
                  * `provider` - provider. Например: `Microsoft.Compute`
                  * `client` - client. Например: `virtualMachines`.
                  * `query` - строка для поиска в формате jmespath. Например: `value[?name=='myVM']`
               * `nameAnswer` - имя ответа студента.
               *  `filterForReseachInResourse` - словарь полей для типа allresource для поиска ресурса для запроса url = `f"https://management.azure.com/subscriptions/{__cloud53AzureSubscription}/resourceGroups/{resourseGroupName}/resourses?api-version={api_verion}"`:
                  * `api_verion` - версия api management azure. Например: `2021-07-01`
                  * `query` - строка для поиска в формате jmespath. Например: `value[?starts_with(name,'my-hub-group') && type == 'Microsoft.Devices/IotHubs'].name`
