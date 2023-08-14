# CodeLint
CodeLint is a actually an embbed xcode build target for linting your code,  whether Objective-C or Swift.
Here is a convenient script to help you set up a codeLint target into your  project.

#### Info
* Version：v0.1
* Date：2023_06_19
* Function：Auto set up a codeLint target into Xcode-based project

#### How to use
* Copy the whole `CodeLint` directory into the root path of your project
* Modify the `code_lint.yml` fiel, fields are listed:
	* xcodeproj: The path of the `.xcodeproj` file relative to `code_lint.yml`
	* target: The target you want to lint
	* tools: The tool you need, set 1 to activate
	* reporter: Report type, could be reported as html or simply show in Xcode
* Run `Setup_CodeLint`
