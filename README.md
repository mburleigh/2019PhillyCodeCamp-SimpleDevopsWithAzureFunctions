# Introduction 

What is the minimum amount of code I can write to stand up an Azure Function (complete with build & release pipeline, unit tests, and integration tests).

# Author

Matt Burleigh
Senior Developer, Pandora Jewelry

Email: mburleigh@outlook.com
Twitter: @svdreamline
GitHub: https://github.com/mburleigh/

# Getting Started


### 1. Create boiler plate function
* Create repo (GH or AZDO)
* Clone repo locally
* cd to local folder
* In VS Code Azure hub (in sidebar):
  * Login
  * Initialize everything (function runtime, etc)
  * Create New Project (click button)
  * Create Function (click button)
* _Test locally (F5 in VS Code)_
* Create `\Src` folder:
  * Move function folder (ex `\HttpTrigger`)
  * Move `local.settings.json` from root folder
  * _Test locally (F5 in VS Code)_ ==> error: no functions found
  * Specify the current working directory (cwd) in tasks|options node in `tasks.json` (in the `.vscode` folder)
    * Full path: `"cwd": "<full path to \Src folder>"`
    * Relative path: `"cwd": "./Src"`
  * _Test locally (F5 in VS Code)_ ==> success!


### 2. Commit to source control
* Add `.gitignore` file
  *	Make sure Source Control hub looks ok
    * Not including local (`\bin`, `\obj`, `local.settings.json`, etc) files
  * **_Optional_**: add `file.excludes` to `settings.json` (in `.vscode` folder) file (so they will not show up in the VS Code file browser)
* Copy deployment & AZDO files to function root:
  * `\Deploy` folder
    * To use ARM template deployment:
      * `deploy.sh` (bash script for Azure CLI)
      * `template.json` ([ARM template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authoring-templates))
    * To use AZ CLI only deployment:
      * `all-cli-deploy (consumption).sh`
  * In root folder:
    * `azure-pipelines.yml` (defines CD build pipeline)
    * `.gitattributes` (sets line endings for bash on Ubuntu host)
* Commit & push


### 3. Set up DevOps pipelines in AZDO:
* Create service connection (if necessary)
* **_Optional_**: if all you need is a Release pipeline you can create one and source the code directly from your Git repository (a build pipeline is only required if you want to add unit tests)
* Create **build** pipeline (use `azure-pipelines.yml` file)
  * _Queue test build_
  * Examine artifacts
    * code (all `\Src` code files)
    * ARM (all files in the `\Deploy` [needed for [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest) task])
* Create **release** pipeline
  * **Important**: must use _Ubuntu_ host (in order to run bash script properly) [Hosted Ubuntu 1604 as of 20190412]
  * Optional: set artifact alias
  * Add an `Azure CLI` task
    * Link to bash script from `\Deploy` folder (`deploy.sh` or `all-cli-deploy (consumption).sh`)
    * deployment name argument (no special characters)
    * Azure region argument (ex: EastUS)
  * Add an `Azure App Service Deploy` task
    * App Service Name = $(serviceName)
    * Set release folder
  * _Queue test release_
  * Check release in [Azure Portal](http;//portal.azure.com)
  * Test using web browser/Postman/etc


### 4. **_Optional_**: Add Unit Tests
* Install [mocha](https://mochajs.org/)
  * `npm install --global mocha`
  * Make sure `package.json` exists in project root and contains mocha references
```json
{
    "scripts": {
        "test": "mocha"
    },
    "dependencies": {
        "mocha": "^5.2.0"
    }
}

```
* Create `\Test` folder
  * This is the default folder where mocha will look for tests
  * **_Optional_**: add `mocha.opts` file (tells mocha to look in other folders for tests)
* Create `\<other>` folder(s) as needed (ex. `\Tests.Unit`)
  * Add new folder to `mocha.opts` so the mocha test runner will find it
  * Create unit test(s) as needed
* Run tests manually by executing `npm test` in terminal
* **_Optional_**: add test task to `tasks.json` (in `.vscode` folder) to run tests automatically on local build:
```json
{
    "label": "mocha",
    "command": "npm test",
    "type": "shell"
}
```
* **_Optional_**: edit `azure-pipelines.yml` to include test tasks in AZDO build:

```yml
- task: Npm@1
  displayName: 'npm custom'
  inputs:
    command: custom
    verbose: false
    customCommand: 'install mocha'

- task: Npm@1
  displayName: 'npm test'
  inputs:
    command: custom
    verbose: false
    customCommand: test
```

### 5. **_Optional_**: Add Integration Tests
* Copy `templatewithslot.json` to `\Deploy` folder (ARM template that includes a deployment slot for integration testing)
* Uncomment lines is `deploy.sh`
* Create folder for integration tests (ex. `\Tests.Integration`)
* Edit `azure-pipelines.yml` to publish integration tests as a build artifact:
```yml
- task: PublishBuildArtifacts@1
  displayName: 'Publish Artifact: Tests'
  inputs:
    PathtoPublish: Tests.Integration
    ArtifactName: tests
```
* Install [Postman](https://www.getpostman.com/)
  * Use Postman to create integration tests
  * Export tests to appropriate folder (ex: `Tests.Integration`)
* Add 3rd argument to Azure CLI task (the slot name)
* Edit App Service Deploy task to deploy to a slot
  * Resource group = $(resourceGroup)
  * Slot name = $(slotname)
* Add an `NPM` task to install [Newman](https://github.com/postmanlabs/newman) to the release pipeline
  * Command = custom
  * Arguments = `install newman`
* Add a `Command Line` task to release pipeline to run Newman
  * Script = `/home/vsts/work/node_modules/.bin/newman run "$(System.DefaultWorkingDirectory)/<build artifact name>/tests/<tests file name>" --global-var "url=$(testurl)"` (ex: `/home/vsts/work/node_modules/.bin/newman run "$(System.DefaultWorkingDirectory)/Sandbox - MattB-CI/tests/Newman Test.json" --global-var "url=$(testurl)"`)
* **_Optional_**: to get the test results added to the `Tests` tab of the release pipeline in AZDO:
  * add `--reporters junit --reporter-junit-export outputfile.xml` parameters to the Newman commandline
  * add a `Publish Test Results` task
    * JUnit format
    * results file = export file specified on commandline (ex. outputfile.xml)
* **_Optional_**: add a task to the release pipeline to swap the slot if the tests succeed or extend the release pipeline to add approvals and a new swap stage


### 6. **_Optional_**: Add TypeScript function
* Copy & edit js fn
* Add `tsconfig.json`
* cd \src & tsc
* check generated .js files
