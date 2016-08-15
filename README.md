# config-file-generator
A simple tool to parse ERB-templated files and generate your text from them.

## Usage
The tool supports standard [ERB templates](http://www.stuartellis.eu/articles/erb/). At its simplest, you can replace pieces of your config's text with variables wrapped like so: `<%= variable %>` to templatize values that should be different between environments.

To generate your rendered files from your templates, you need to call the following two lines of code (from a Rake task, for example):

```
deployment_config = ConfigFileGenerator.new(**new_args)
deployment_config.generate(environment, **generate_args)
```

Passing any `**new_args` or `**generate_args` are optional. Either will allow for you to modify the default behavior of the tool as described below.

#### The default behaviour of the tool is to:

- Look for template files within `deployment/templates/` named `*.*.erb`
- Look for a variables file named `vars.yml` within the same folder.
- Load the variables under the key within `vars.yml` named after your supplied `environment`.
  - Example:

```
staging:
    environment: staging
    registry: hub.docker.com
```

  - Process your `.erb` files and write them to `$environment/*.*`.
    - So if your environment were "staging" and your template file were "config.yml.erb", then the generated file would be created at: `staging/config.yml`.

## Supported Features

- Find all templates within the `template_path` (default: `deployment/templates/`) and generate their output files.
  - Can pass in a single template file, or a directory. Directories are search recursively.
- Raise an error informing the user of any variables required by the template that are missing from within the loaded vars file.
- If `dry_run: true` is passed to the `generate()` method, the generated template files will be printed to stdout instead of written to a file.

## Overriding Defaults
### Input
Both of the below options are optional keyword-arguments to the `ConfigFileGenerator` constructor.

##### Template Path
Providing a `template_path` overrides where the tool will look for your template files. You can provide either a file or a directory. If a directory is given, it is recursively searched for any `.erb` files. This allows you to organize your templates however you choose.

Example:

```
deployment_config = ConfigFileGenerator.new(template_path: 'templates/')
```
##### Variables File
Providing a `vars` parameter overrides where the tool looks for its variables file. By default, it reads them from `template_path/vars.yml`. You can however provide a different file path to a YAML file or a Hash directly.

When reading vars, the tool looks for a key named the same as the first parameter passed to the `generate()` method. Example Vars File:

```
staging:
    environment: staging
    registry: us.gcr.io/wp-engine-development
```

Example:

```
deployment_config = ConfigFileGenerator.new(vars: 'templates/variables.yml')
```

### Output
Both of the below options are optional keyword-arguments to the `ConfigFileGenerator.generate()` method.

##### Output Directory
Providing an `output_directory` parameter allows for you to specify where your generated files are written to. The directory structure within and the file naming scheme ([as described above](#usage)) are not currently modifiable.

Example:

```
deployment_config.generate(environment, output_directory: 'deployment-files/')
```

##### Dry Run
Providing a `dry_run` parameter causes the tool to print the results of the generated templates to stdout instead of writing them to a file. Particularly useful for debugging your templates.

Example \*:

```
deployment_config.generate(environment, dry_run: true)
```
\* *this parameter can also accept the String "true", which can make life easier sometimes ¯\\\_(ツ)_/¯*

## Todo:

  - Add tests :(
